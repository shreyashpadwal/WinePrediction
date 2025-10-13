#!/bin/bash
set -e

# Azure Performance Optimization Script
# This script optimizes the Wine Quality Prediction application for performance and scalability

echo "🍷 Wine Quality Prediction - Performance Optimization"
echo "==================================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if .env.azure exists
check_env_file() {
    if [ ! -f "azure/.env.azure" ]; then
        print_error "azure/.env.azure not found. Please run ./azure/acr-setup.sh first"
        exit 1
    fi
    
    # Source the environment file
    source azure/.env.azure
    print_success "Loaded Azure configuration from azure/.env.azure"
}

# Function to check if Azure CLI is logged in
check_azure_login() {
    print_status "Checking Azure CLI login..."
    
    if ! az account show &> /dev/null; then
        print_error "Not logged into Azure CLI. Please run 'az login' first"
        exit 1
    fi
    
    print_success "Logged into Azure CLI"
}

# Function to set up Azure CDN
setup_cdn() {
    print_status "Setting up Azure CDN..."
    
    CDN_PROFILE_NAME="wine-quality-cdn"
    
    # Create CDN profile
    if ! az cdn profile show --name "$CDN_PROFILE_NAME" --resource-group "$AZURE_RESOURCE_GROUP" &> /dev/null; then
        az cdn profile create \
            --name "$CDN_PROFILE_NAME" \
            --resource-group "$AZURE_RESOURCE_GROUP" \
            --location "$AZURE_LOCATION" \
            --sku Standard_Microsoft
        print_success "CDN profile created: $CDN_PROFILE_NAME"
    else
        print_warning "CDN profile $CDN_PROFILE_NAME already exists"
    fi
    
    # Create CDN endpoint for frontend
    CDN_ENDPOINT_NAME="wine-quality-frontend-cdn"
    FRONTEND_URL="https://$FRONTEND_APP_NAME.azurestaticapps.net"
    
    if ! az cdn endpoint show --name "$CDN_ENDPOINT_NAME" --profile-name "$CDN_PROFILE_NAME" --resource-group "$AZURE_RESOURCE_GROUP" &> /dev/null; then
        az cdn endpoint create \
            --name "$CDN_ENDPOINT_NAME" \
            --profile-name "$CDN_PROFILE_NAME" \
            --resource-group "$AZURE_RESOURCE_GROUP" \
            --origin "$FRONTEND_URL" \
            --origin-host-header "$FRONTEND_URL"
        print_success "CDN endpoint created: $CDN_ENDPOINT_NAME"
    else
        print_warning "CDN endpoint $CDN_ENDPOINT_NAME already exists"
    fi
    
    # Configure caching rules
    az cdn endpoint update \
        --name "$CDN_ENDPOINT_NAME" \
        --profile-name "$CDN_PROFILE_NAME" \
        --resource-group "$AZURE_RESOURCE_GROUP" \
        --query-string-caching-behavior IgnoreQueryString
    
    print_success "CDN configured with caching rules"
}

# Function to set up Azure Cache for Redis
setup_redis_cache() {
    print_status "Setting up Azure Cache for Redis..."
    
    REDIS_CACHE_NAME="wine-quality-cache"
    
    # Create Redis cache
    if ! az redis show --name "$REDIS_CACHE_NAME" --resource-group "$AZURE_RESOURCE_GROUP" &> /dev/null; then
        az redis create \
            --name "$REDIS_CACHE_NAME" \
            --resource-group "$AZURE_RESOURCE_GROUP" \
            --location "$AZURE_LOCATION" \
            --sku Basic \
            --vm-size c0
        print_success "Redis cache created: $REDIS_CACHE_NAME"
    else
        print_warning "Redis cache $REDIS_CACHE_NAME already exists"
    fi
    
    # Get Redis connection details
    REDIS_HOSTNAME=$(az redis show --name "$REDIS_CACHE_NAME" --resource-group "$AZURE_RESOURCE_GROUP" --query hostName -o tsv)
    REDIS_PORT=$(az redis show --name "$REDIS_CACHE_NAME" --resource-group "$AZURE_RESOURCE_GROUP" --query port -o tsv)
    REDIS_SSL_PORT=$(az redis show --name "$REDIS_CACHE_NAME" --resource-group "$AZURE_RESOURCE_GROUP" --query sslPort -o tsv)
    
    print_success "Redis cache details:"
    echo "  Hostname: $REDIS_HOSTNAME"
    echo "  Port: $REDIS_PORT"
    echo "  SSL Port: $REDIS_SSL_PORT"
}

# Function to configure autoscaling
configure_autoscaling() {
    print_status "Configuring autoscaling..."
    
    # Configure autoscaling for App Service
    az monitor autoscale create \
        --resource "$BACKEND_APP_NAME" \
        --resource-group "$AZURE_RESOURCE_GROUP" \
        --resource-type "Microsoft.Web/sites" \
        --name "wine-quality-autoscale" \
        --min-count 1 \
        --max-count 3 \
        --count 1
    
    # Scale out rule (CPU > 70% for 5 minutes)
    az monitor autoscale rule create \
        --resource-group "$AZURE_RESOURCE_GROUP" \
        --autoscale-name "wine-quality-autoscale" \
        --condition "Percentage CPU > 70 avg 5m" \
        --scale out 1
    
    # Scale in rule (CPU < 30% for 10 minutes)
    az monitor autoscale rule create \
        --resource-group "$AZURE_RESOURCE_GROUP" \
        --autoscale-name "wine-quality-autoscale" \
        --condition "Percentage CPU < 30 avg 10m" \
        --scale in 1
    
    print_success "Autoscaling configured"
}

# Function to optimize App Service configuration
optimize_app_service() {
    print_status "Optimizing App Service configuration..."
    
    # Enable Always On
    az webapp config set \
        --name "$BACKEND_APP_NAME" \
        --resource-group "$AZURE_RESOURCE_GROUP" \
        --always-on true
    
    # Configure connection limits
    az webapp config appsettings set \
        --name "$BACKEND_APP_NAME" \
        --resource-group "$AZURE_RESOURCE_GROUP" \
        --settings \
            WEBSITE_LOAD_CERTIFICATES="*" \
            WEBSITE_LOAD_USER_PROFILE="1" \
            WEBSITE_RUN_FROM_PACKAGE="1" \
            WEBSITE_ENABLE_SYNC_UPDATE_SITE="true"
    
    # Configure startup command for better performance
    az webapp config set \
        --name "$BACKEND_APP_NAME" \
        --resource-group "$AZURE_RESOURCE_GROUP" \
        --startup-file "gunicorn app.main:app --workers 4 --worker-class uvicorn.workers.UvicornWorker --bind 0.0.0.0:8000 --timeout 120 --keep-alive 2 --max-requests 1000 --max-requests-jitter 100"
    
    print_success "App Service optimized"
}

# Function to optimize Docker images
optimize_docker_images() {
    print_status "Optimizing Docker images..."
    
    # Create optimized backend Dockerfile
    cat > backend/Dockerfile.optimized << EOF
# Multi-stage build for production optimization
FROM python:3.10-slim as builder

WORKDIR /app

# Install build dependencies
RUN apt-get update && apt-get install -y \
    gcc \
    g++ \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements and install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir --user -r requirements.txt

# Production stage
FROM python:3.10-slim as production

WORKDIR /app

# Install runtime dependencies only
RUN apt-get update && apt-get install -y \
    curl \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Copy Python packages from builder
COPY --from=builder /root/.local /root/.local

# Create non-root user
RUN useradd --create-home --shell /bin/bash --uid 1000 app

# Copy application code
COPY --chown=app:app . .

# Create necessary directories
RUN mkdir -p logs saved_models && \
    chown -R app:app logs saved_models

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PATH="/root/.local/bin:$PATH"

# Switch to non-root user
USER app

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl --fail http://localhost:8000/api/v1/prediction/health || exit 1

# Expose port
EXPOSE 8000

# Start command
CMD ["gunicorn", "app.main:app", "--workers", "4", "--worker-class", "uvicorn.workers.UvicornWorker", "--bind", "0.0.0.0:8000", "--timeout", "120", "--keep-alive", "2", "--max-requests", "1000", "--max-requests-jitter", "100"]
EOF
    
    # Create optimized frontend Dockerfile
    cat > frontend/Dockerfile.optimized << EOF
# Multi-stage build for React app
FROM node:18-alpine AS builder

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci --only=production --silent

# Copy source code
COPY . .

# Build application
RUN npm run build

# Production stage
FROM nginx:alpine AS production

# Install curl for health checks
RUN apk add --no-cache curl

# Copy built application
COPY --from=builder /app/dist /usr/share/nginx/html

# Copy optimized nginx configuration
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Create non-root user
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nextjs -u 1001

# Set ownership
RUN chown -R nextjs:nodejs /usr/share/nginx/html && \
    chown -R nextjs:nodejs /var/cache/nginx && \
    chown -R nextjs:nodejs /var/log/nginx && \
    chown -R nextjs:nodejs /etc/nginx/conf.d

# Create nginx runtime directory
RUN mkdir -p /var/run/nginx && \
    chown -R nextjs:nodejs /var/run/nginx

# Switch to non-root user
USER nextjs

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl --fail http://localhost/ || exit 1

# Expose port
EXPOSE 80

# Start nginx
CMD ["nginx", "-g", "daemon off;"]
EOF
    
    print_success "Optimized Dockerfiles created"
}

# Function to create performance monitoring
create_performance_monitoring() {
    print_status "Creating performance monitoring..."
    
    # Create performance test script
    cat > azure/performance-test.sh << EOF
#!/bin/bash
set -e

echo "🍷 Wine Quality Prediction - Performance Testing"
echo "==============================================="

BACKEND_URL="https://$BACKEND_APP_NAME.azurewebsites.net"
FRONTEND_URL="https://$FRONTEND_APP_NAME.azurestaticapps.net"

# Test backend performance
echo "Testing backend performance..."
ab -n 1000 -c 10 "$BACKEND_URL/api/v1/prediction/health"

# Test frontend performance
echo "Testing frontend performance..."
ab -n 1000 -c 10 "$FRONTEND_URL"

# Test prediction endpoint
echo "Testing prediction endpoint..."
SAMPLE_DATA='{
    "fixed_acidity": 7.4,
    "volatile_acidity": 0.7,
    "citric_acid": 0.0,
    "residual_sugar": 1.9,
    "chlorides": 0.076,
    "free_sulfur_dioxide": 11.0,
    "total_sulfur_dioxide": 34.0,
    "density": 0.9978,
    "ph": 3.51,
    "sulphates": 0.56,
    "alcohol": 9.4
}'

for i in {1..100}; do
    curl -X POST "$BACKEND_URL/api/v1/prediction/predict" \
        -H "Content-Type: application/json" \
        -d "$SAMPLE_DATA" \
        -w "Time: %{time_total}s\n" \
        -o /dev/null -s
done

echo "Performance testing completed"
EOF
    
    chmod +x azure/performance-test.sh
    
    # Create performance monitoring alerts
    az monitor metrics alert create \
        --name "slow-response-time" \
        --resource-group "$AZURE_RESOURCE_GROUP" \
        --scopes "/subscriptions/$AZURE_SUBSCRIPTION_ID/resourceGroups/$AZURE_RESOURCE_GROUP/providers/Microsoft.Web/sites/$BACKEND_APP_NAME" \
        --condition "avg 'HttpResponseTime' > 2000" \
        --description "Slow response time detected" \
        --evaluation-frequency 5m \
        --window-size 15m \
        --severity 2
    
    az monitor metrics alert create \
        --name "high-cpu-usage" \
        --resource-group "$AZURE_RESOURCE_GROUP" \
        --scopes "/subscriptions/$AZURE_SUBSCRIPTION_ID/resourceGroups/$AZURE_RESOURCE_GROUP/providers/Microsoft.Web/sites/$BACKEND_APP_NAME" \
        --condition "avg 'CpuPercentage' > 80" \
        --description "High CPU usage detected" \
        --evaluation-frequency 5m \
        --window-size 15m \
        --severity 2
    
    print_success "Performance monitoring created"
}

# Function to optimize frontend
optimize_frontend() {
    print_status "Optimizing frontend..."
    
    # Create optimized nginx configuration
    cat > frontend/nginx.optimized.conf << EOF
server {
    listen 80;
    server_name localhost;
    root /usr/share/nginx/html;
    index index.html;

    # Security headers
    add_header X-Frame-Options "DENY" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval'; style-src 'self' 'unsafe-inline'; img-src 'self' data: https:; font-src 'self' data:; connect-src 'self' https:;" always;

    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_comp_level 6;
    gzip_types
        text/plain
        text/css
        text/xml
        text/javascript
        application/javascript
        application/xml+rss
        application/json
        application/xml
        image/svg+xml;

    # Brotli compression (if available)
    brotli on;
    brotli_comp_level 6;
    brotli_types
        text/plain
        text/css
        application/json
        application/javascript
        text/xml
        application/xml
        application/xml+rss
        text/javascript;

    # Handle client-side routing (SPA)
    location / {
        try_files \$uri \$uri/ /index.html;
        
        # Cache HTML files for short time
        location ~* \.html\$ {
            expires 1h;
            add_header Cache-Control "public, must-revalidate";
        }
    }

    # Cache static assets aggressively
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot|webp|avif)\$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
        
        # Enable CORS for fonts
        location ~* \.(woff|woff2|ttf|eot)\$ {
            add_header Access-Control-Allow-Origin "*";
            expires 1y;
            add_header Cache-Control "public, immutable";
        }
    }

    # API proxy to backend
    location /api/ {
        proxy_pass http://backend:8000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        # Timeouts
        proxy_connect_timeout 30s;
        proxy_send_timeout 30s;
        proxy_read_timeout 30s;
        
        # Buffer settings
        proxy_buffering on;
        proxy_buffer_size 4k;
        proxy_buffers 8 4k;
    }

    # Health check endpoint
    location /health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }
}
EOF
    
    print_success "Frontend optimization completed"
}

# Function to create performance benchmarks
create_performance_benchmarks() {
    print_status "Creating performance benchmarks..."
    
    cat > azure/benchmarks.md << EOF
# 🚀 Performance Benchmarks

## Target Performance Metrics

### Backend API
- **Response Time**: < 500ms (95th percentile)
- **Throughput**: > 1000 requests/minute
- **Availability**: > 99.9%
- **Error Rate**: < 0.1%

### Frontend
- **Lighthouse Score**: > 90
- **First Contentful Paint**: < 1.5s
- **Largest Contentful Paint**: < 2.5s
- **Cumulative Layout Shift**: < 0.1

### Infrastructure
- **CPU Usage**: < 70% (average)
- **Memory Usage**: < 80% (average)
- **Network Latency**: < 100ms
- **Storage IOPS**: Optimized

## Performance Testing Results

### Load Testing
\`\`\`bash
# Run performance tests
./azure/performance-test.sh
\`\`\`

### Monitoring
- Application Insights metrics
- Azure Monitor alerts
- Custom performance dashboards
- Real-time performance tracking

## Optimization Strategies

### 1. Caching
- Redis cache for API responses
- CDN for static assets
- Browser caching optimization
- Application-level caching

### 2. Database Optimization
- Connection pooling
- Query optimization
- Index optimization
- Read replicas (if applicable)

### 3. Application Optimization
- Code optimization
- Memory management
- Async processing
- Resource pooling

### 4. Infrastructure Optimization
- Auto-scaling
- Load balancing
- Resource optimization
- Network optimization
EOF
    
    print_success "Performance benchmarks created"
}

# Function to display performance summary
display_summary() {
    echo ""
    echo "🚀 Performance Optimization Complete!"
    echo "===================================="
    echo ""
    echo "📋 Performance Features Implemented:"
    echo "  ✅ Azure CDN for static assets"
    echo "  ✅ Redis cache for API responses"
    echo "  ✅ Autoscaling configuration"
    echo "  ✅ Optimized Docker images"
    echo "  ✅ Performance monitoring"
    echo "  ✅ Frontend optimization"
    echo "  ✅ Performance benchmarks"
    echo ""
    echo "🔍 Performance Resources:"
    echo "  CDN Profile: wine-quality-cdn"
    echo "  Redis Cache: wine-quality-cache"
    echo "  Autoscaling: wine-quality-autoscale"
    echo ""
    echo "📊 Performance Targets:"
    echo "  API Response Time: < 500ms"
    echo "  Frontend Lighthouse Score: > 90"
    echo "  Availability: > 99.9%"
    echo "  Throughput: > 1000 req/min"
    echo ""
    echo "📚 Documentation:"
    echo "  Performance Guide: azure/benchmarks.md"
    echo "  Performance Tests: azure/performance-test.sh"
    echo ""
    echo "🚀 Next Steps:"
    echo "  1. Run performance tests"
    echo "  2. Monitor performance metrics"
    echo "  3. Optimize based on results"
    echo "  4. Set up performance alerts"
    echo "  5. Regular performance reviews"
}

# Function to save performance info
save_performance_info() {
    print_status "Saving performance information..."
    
    cat >> azure/.env.azure << EOF

# Performance Configuration
CDN_PROFILE_NAME=wine-quality-cdn
CDN_ENDPOINT_NAME=wine-quality-frontend-cdn
REDIS_CACHE_NAME=wine-quality-cache
AUTOSCALE_NAME=wine-quality-autoscale
EOF
    
    print_success "Performance information saved to azure/.env.azure"
}

# Main execution
main() {
    echo "Starting performance optimization..."
    echo ""
    
    # Check prerequisites
    check_env_file
    check_azure_login
    
    # Implement performance optimizations
    setup_cdn
    setup_redis_cache
    configure_autoscaling
    optimize_app_service
    optimize_docker_images
    create_performance_monitoring
    optimize_frontend
    create_performance_benchmarks
    
    # Save information and display summary
    save_performance_info
    display_summary
}

# Run main function
main "$@"

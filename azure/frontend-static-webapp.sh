#!/bin/bash
set -e

# Azure Static Web Apps Deployment Script for Frontend
# This script deploys the Wine Quality Prediction frontend to Azure Static Web Apps

echo "🍷 Wine Quality Prediction - Frontend Static Web Apps Deployment"
echo "==============================================================="

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

# Function to check if GitHub repository is connected
check_github_repo() {
    print_status "Checking GitHub repository connection..."
    
    # Check if we're in a git repository
    if [ ! -d ".git" ]; then
        print_error "Not in a git repository. Please initialize git first:"
        echo "  git init"
        echo "  git add ."
        echo "  git commit -m 'Initial commit'"
        echo "  git remote add origin <your-github-repo-url>"
        echo "  git push -u origin main"
        exit 1
    fi
    
    # Check if remote origin is set
    if ! git remote get-url origin &> /dev/null; then
        print_error "Git remote origin not set. Please add your GitHub repository:"
        echo "  git remote add origin <your-github-repo-url>"
        exit 1
    fi
    
    GITHUB_REPO_URL=$(git remote get-url origin)
    print_success "GitHub repository: $GITHUB_REPO_URL"
}

# Function to create Static Web App
create_static_webapp() {
    print_status "Creating Azure Static Web App: $FRONTEND_APP_NAME"
    
    # Check if Static Web App already exists
    if az staticwebapp show --name "$FRONTEND_APP_NAME" --resource-group "$AZURE_RESOURCE_GROUP" &> /dev/null; then
        print_warning "Static Web App $FRONTUB_APP_NAME already exists"
    else
        # Extract GitHub info from repository URL
        if [[ $GITHUB_REPO_URL =~ github\.com[:/]([^/]+)/([^/]+) ]]; then
            GITHUB_USERNAME="${BASH_REMATCH[1]}"
            GITHUB_REPO_NAME="${BASH_REMATCH[2]}"
            GITHUB_REPO_NAME="${GITHUB_REPO_NAME%.git}"  # Remove .git suffix if present
        else
            print_error "Could not parse GitHub repository URL: $GITHUB_REPO_URL"
            exit 1
        fi
        
        print_status "GitHub repository: $GITHUB_USERNAME/$GITHUB_REPO_NAME"
        
        # Create Static Web App
        az staticwebapp create \
            --name "$FRONTEND_APP_NAME" \
            --resource-group "$AZURE_RESOURCE_GROUP" \
            --source "$GITHUB_REPO_URL" \
            --location "$AZURE_LOCATION" \
            --branch main \
            --app-location "/frontend" \
            --output-location "dist" \
            --login-with-github
        
        print_success "Static Web App created: $FRONTEND_APP_NAME"
    fi
}

# Function to configure build settings
configure_build_settings() {
    print_status "Configuring build settings..."
    
    # Get Static Web App details
    SWA_DETAILS=$(az staticwebapp show --name "$FRONTEND_APP_NAME" --resource-group "$AZURE_RESOURCE_GROUP" --query "buildProperties" -o json)
    
    # Configure build settings
    az staticwebapp appsettings set \
        --name "$FRONTEND_APP_NAME" \
        --resource-group "$AZURE_RESOURCE_GROUP" \
        --setting-names \
            VITE_API_URL="https://$BACKEND_APP_NAME.azurewebsites.net/api/v1" \
            NODE_ENV="production"
    
    print_success "Build settings configured"
}

# Function to configure routing rules
configure_routing() {
    print_status "Configuring routing rules..."
    
    # Create staticwebapp.config.json
    cat > frontend/public/staticwebapp.config.json << EOF
{
  "navigationFallback": {
    "rewrite": "/index.html",
    "exclude": ["/api/*", "/health", "*.{css,scss,js,png,gif,ico,jpg,svg}"]
  },
  "mimeTypes": {
    ".json": "application/json"
  },
  "globalHeaders": {
    "X-Frame-Options": "DENY",
    "X-Content-Type-Options": "nosniff",
    "X-XSS-Protection": "1; mode=block",
    "Strict-Transport-Security": "max-age=31536000; includeSubDomains",
    "Content-Security-Policy": "default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval'; style-src 'self' 'unsafe-inline'; img-src 'self' data: https:; font-src 'self' data:; connect-src 'self' https:;"
  },
  "routes": [
    {
      "route": "/api/*",
      "allowedRoles": ["anonymous"]
    },
    {
      "route": "/health",
      "allowedRoles": ["anonymous"]
    },
    {
      "route": "/*",
      "serve": "/index.html",
      "statusCode": 200
    }
  ],
  "responseOverrides": {
    "404": {
      "rewrite": "/index.html"
    }
  }
}
EOF
    
    print_success "Routing rules configured"
}

# Function to configure custom domain (optional)
configure_custom_domain() {
    read -p "Do you want to configure a custom domain? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        read -p "Enter custom domain (e.g., yourdomain.com): " CUSTOM_DOMAIN
        
        if [ ! -z "$CUSTOM_DOMAIN" ]; then
            print_status "Adding custom domain: $CUSTOM_DOMAIN"
            
            az staticwebapp hostname set \
                --name "$FRONTEND_APP_NAME" \
                --resource-group "$AZURE_RESOURCE_GROUP" \
                --hostname "$CUSTOM_DOMAIN"
            
            print_success "Custom domain added: $CUSTOM_DOMAIN"
            print_warning "Please configure DNS records for $CUSTOM_DOMAIN"
        fi
    fi
}

# Function to enable CDN
enable_cdn() {
    print_status "Enabling CDN for static assets..."
    
    # Static Web Apps automatically includes CDN
    print_success "CDN enabled (included with Static Web Apps)"
}

# Function to configure SSL certificate
configure_ssl() {
    print_status "Configuring SSL certificate..."
    
    # Static Web Apps automatically provisions SSL certificates
    print_success "SSL certificate auto-provisioned"
}

# Function to test deployment
test_deployment() {
    print_status "Testing deployment..."
    
    # Get Static Web App URL
    SWA_URL=$(az staticwebapp show --name "$FRONTEND_APP_NAME" --resource-group "$AZURE_RESOURCE_GROUP" --query "defaultHostname" -o tsv)
    SWA_URL="https://$SWA_URL"
    
    # Wait for deployment to complete
    print_status "Waiting for deployment to complete..."
    sleep 60
    
    # Test frontend
    print_status "Testing frontend..."
    if curl -f "$SWA_URL" &> /dev/null; then
        print_success "Frontend accessible: $SWA_URL"
    else
        print_warning "Frontend may not be ready yet. Check deployment status."
    fi
    
    # Test API proxy (if configured)
    print_status "Testing API proxy..."
    if curl -f "$SWA_URL/api/v1/prediction/health" &> /dev/null; then
        print_success "API proxy working: $SWA_URL/api/v1/prediction/health"
    else
        print_warning "API proxy not working. Check backend deployment."
    fi
}

# Function to create GitHub Actions workflow
create_github_workflow() {
    print_status "Creating GitHub Actions workflow..."
    
    # Create .github/workflows directory if it doesn't exist
    mkdir -p .github/workflows
    
    # Create GitHub Actions workflow
    cat > .github/workflows/azure-static-web-apps.yml << EOF
name: Azure Static Web Apps CI/CD

on:
  push:
    branches:
      - main
  pull_request:
    types: [opened, synchronize, reopened, closed]
    branches:
      - main

jobs:
  build_and_deploy_job:
    if: github.event_name == 'push' || (github.event_name == 'pull_request' && github.event.action != 'closed')
    runs-on: ubuntu-latest
    name: Build and Deploy Job
    steps:
      - uses: actions/checkout@v3
        with:
          submodules: true
          
      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '18'
          cache: 'npm'
          cache-dependency-path: frontend/package-lock.json
          
      - name: Install dependencies
        run: |
          cd frontend
          npm ci
          
      - name: Build
        run: |
          cd frontend
          npm run build
        env:
          VITE_API_URL: https://$BACKEND_APP_NAME.azurewebsites.net/api/v1
          
      - name: Build And Deploy
        id: builddeploy
        uses: Azure/static-web-apps-deploy@v1
        with:
          azure_static_web_apps_api_token: \${{ secrets.AZURE_STATIC_WEB_APPS_API_TOKEN }}
          repo_token: \${{ secrets.GITHUB_TOKEN }}
          action: "upload"
          app_location: "/frontend"
          output_location: "dist"
          
  close_pull_request_job:
    if: github.event_name == 'pull_request' && github.event.action == 'closed'
    runs-on: ubuntu-latest
    name: Close Pull Request Job
    steps:
      - name: Close Pull Request
        id: closepullrequest
        uses: Azure/static-web-apps-deploy@v1
        with:
          azure_static_web_apps_api_token: \${{ secrets.AZURE_STATIC_WEB_APPS_API_TOKEN }}
          action: "close"
EOF
    
    print_success "GitHub Actions workflow created"
    print_warning "Please add AZURE_STATIC_WEB_APPS_API_TOKEN to your GitHub repository secrets"
}

# Function to get deployment token
get_deployment_token() {
    print_status "Getting deployment token..."
    
    DEPLOYMENT_TOKEN=$(az staticwebapp secrets list --name "$FRONTEND_APP_NAME" --resource-group "$AZURE_RESOURCE_GROUP" --query "properties.apiKey" -o tsv)
    
    if [ ! -z "$DEPLOYMENT_TOKEN" ]; then
        print_success "Deployment token obtained"
        print_warning "Add this token to your GitHub repository secrets as AZURE_STATIC_WEB_APPS_API_TOKEN:"
        echo "  $DEPLOYMENT_TOKEN"
    else
        print_error "Failed to get deployment token"
    fi
}

# Function to display deployment summary
display_summary() {
    echo ""
    echo "🍷 Frontend Deployment Complete!"
    echo "==============================="
    echo ""
    echo "📋 Summary:"
    echo "  Static Web App: $FRONTEND_APP_NAME"
    echo "  Resource Group: $AZURE_RESOURCE_GROUP"
    echo "  GitHub Repository: $GITHUB_REPO_URL"
    echo ""
    echo "🌐 URLs:"
    echo "  Frontend: https://$FRONTEND_APP_NAME.azurestaticapps.net"
    echo "  API Proxy: https://$FRONTEND_APP_NAME.azurestaticapps.net/api/v1"
    echo ""
    echo "🔧 Configuration:"
    echo "  Build Location: /frontend"
    echo "  Output Location: dist"
    echo "  Branch: main"
    echo ""
    echo "🚀 Next steps:"
    echo "  1. Add AZURE_STATIC_WEB_APPS_API_TOKEN to GitHub secrets"
    echo "  2. Push changes to trigger deployment"
    echo "  3. Set up CI/CD: ./azure/setup-pipeline.sh"
    echo "  4. Configure monitoring: ./azure/monitoring-setup.sh"
    echo ""
    echo "📚 Documentation:"
    echo "  Static Web Apps: https://docs.microsoft.com/en-us/azure/static-web-apps/"
    echo "  GitHub Actions: https://docs.github.com/en/actions"
}

# Function to save deployment info
save_deployment_info() {
    print_status "Saving deployment information..."
    
    # Get Static Web App URL
    SWA_URL=$(az staticwebapp show --name "$FRONTEND_APP_NAME" --resource-group "$AZURE_RESOURCE_GROUP" --query "defaultHostname" -o tsv)
    
    cat >> azure/.env.azure << EOF

# Frontend Deployment Information
FRONTEND_STATIC_WEBAPP_NAME=$FRONTEND_APP_NAME
FRONTEND_URL=https://$SWA_URL
GITHUB_REPO_URL=$GITHUB_REPO_URL
EOF
    
    print_success "Deployment information saved to azure/.env.azure"
}

# Main execution
main() {
    echo "Starting frontend deployment to Azure Static Web Apps..."
    echo ""
    
    # Check prerequisites
    check_env_file
    check_azure_login
    check_github_repo
    
    # Deploy frontend
    create_static_webapp
    configure_build_settings
    configure_routing
    enable_cdn
    configure_ssl
    
    # Optional configurations
    configure_custom_domain
    
    # Create GitHub Actions workflow
    create_github_workflow
    get_deployment_token
    
    # Test deployment
    test_deployment
    
    # Save information and display summary
    save_deployment_info
    display_summary
}

# Run main function
main "$@"

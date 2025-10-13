#!/bin/sh
set -e

echo "🍷 Starting Wine Quality Prediction Frontend..."

# Function to replace API URL in built files
replace_api_url() {
    echo "🔧 Configuring API URL..."
    
    # Get API URL from environment variable or use default
    API_URL=${VITE_API_URL:-"http://localhost:8000/api/v1"}
    
    echo "   API URL: $API_URL"
    
    # Replace placeholder in built files
    find /usr/share/nginx/html -name "*.js" -exec sed -i "s|__API_URL__|$API_URL|g" {} \;
    find /usr/share/nginx/html -name "*.html" -exec sed -i "s|__API_URL__|$API_URL|g" {} \;
    
    echo "✅ API URL configured"
}

# Function to check if build files exist
check_build_files() {
    echo "📁 Checking build files..."
    
    if [ ! -f "/usr/share/nginx/html/index.html" ]; then
        echo "❌ Error: index.html not found in build directory"
        echo "   Please ensure the React app was built successfully"
        exit 1
    fi
    
    if [ ! -d "/usr/share/nginx/html/assets" ]; then
        echo "⚠️  Warning: assets directory not found"
        echo "   The app may not load correctly"
    fi
    
    echo "✅ Build files found"
}

# Function to set proper permissions
set_permissions() {
    echo "🔐 Setting proper permissions..."
    
    # Ensure nginx can read the files
    chmod -R 755 /usr/share/nginx/html
    
    echo "✅ Permissions set"
}

# Function to start nginx
start_nginx() {
    echo "🚀 Starting Nginx..."
    echo "   Frontend will be available on port 80"
    echo "   API proxy configured for /api/* requests"
    echo ""
    
    # Start nginx in foreground
    exec nginx -g "daemon off;"
}

# Main execution
main() {
    echo "=========================================="
    echo "🍷 Wine Quality Prediction Frontend"
    echo "=========================================="
    
    check_build_files
    set_permissions
    replace_api_url
    
    echo "=========================================="
    echo "🚀 All checks passed! Starting Nginx..."
    echo "=========================================="
    
    start_nginx
}

# Run main function
main "$@"

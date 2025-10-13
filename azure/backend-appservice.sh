#!/bin/bash
set -e

# Azure App Service Deployment Script for Backend
# This script deploys the Wine Quality Prediction backend to Azure App Service

echo "🍷 Wine Quality Prediction - Backend App Service Deployment"
echo "=========================================================="

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
    
    CURRENT_USER=$(az account show --query user.name -o tsv)
    print_success "Logged into Azure as: $CURRENT_USER"
}

# Function to verify ACR images exist
verify_acr_images() {
    print_status "Verifying ACR images..."
    
    # Check if backend image exists in ACR
    if ! az acr repository show --name "$ACR_NAME" --image wine-backend:latest &> /dev/null; then
        print_error "Backend image not found in ACR. Please run ./azure/push-to-acr.sh first"
        exit 1
    fi
    
    print_success "Backend image found in ACR: $ACR_LOGIN_SERVER/wine-backend:latest"
}

# Function to create Web App for Containers
create_webapp() {
    print_status "Creating Web App for Containers: $BACKEND_APP_NAME"
    
    # Check if Web App already exists
    if az webapp show --name "$BACKEND_APP_NAME" --resource-group "$AZURE_RESOURCE_GROUP" &> /dev/null; then
        print_warning "Web App $BACKEND_APP_NAME already exists"
    else
        az webapp create \
            --resource-group "$AZURE_RESOURCE_GROUP" \
            --plan "$APP_SERVICE_PLAN" \
            --name "$BACKEND_APP_NAME" \
            --deployment-container-image-name "$ACR_LOGIN_SERVER/wine-backend:latest"
        print_success "Web App created: $BACKEND_APP_NAME"
    fi
}

# Function to configure Web App settings
configure_webapp() {
    print_status "Configuring Web App settings..."
    
    # Configure container settings
    az webapp config container set \
        --name "$BACKEND_APP_NAME" \
        --resource-group "$AZURE_RESOURCE_GROUP" \
        --docker-custom-image-name "$ACR_LOGIN_SERVER/wine-backend:latest" \
        --docker-registry-server-url "https://$ACR_LOGIN_SERVER" \
        --docker-registry-server-user "$ACR_USERNAME" \
        --docker-registry-server-password "$ACR_PASSWORD"
    
    print_success "Container configuration updated"
    
    # Configure app settings
    az webapp config appsettings set \
        --name "$BACKEND_APP_NAME" \
        --resource-group "$AZURE_RESOURCE_GROUP" \
        --settings \
            WEBSITES_PORT=8000 \
            ENVIRONMENT=production \
            LOG_LEVEL=INFO \
            PYTHONUNBUFFERED=1 \
            GEMINI_API_KEY="$GEMINI_API_KEY"
    
    print_success "App settings configured"
}

# Function to enable continuous deployment
enable_continuous_deployment() {
    print_status "Enabling continuous deployment from ACR..."
    
    # Configure continuous deployment
    az webapp deployment container config \
        --enable-cd \
        --name "$BACKEND_APP_NAME" \
        --resource-group "$AZURE_RESOURCE_GROUP"
    
    print_success "Continuous deployment enabled"
}

# Function to configure health check
configure_health_check() {
    print_status "Configuring health check..."
    
    # Set health check path
    az webapp config set \
        --name "$BACKEND_APP_NAME" \
        --resource-group "$AZURE_RESOURCE_GROUP" \
        --startup-file "python -m uvicorn app.main:app --host 0.0.0.0 --port 8000"
    
    print_success "Health check configured"
}

# Function to enable Application Insights
enable_application_insights() {
    print_status "Enabling Application Insights..."
    
    # Create Application Insights component
    APP_INSIGHTS_NAME="${BACKEND_APP_NAME}-insights"
    
    if ! az monitor app-insights component show --app "$APP_INSIGHTS_NAME" --resource-group "$AZURE_RESOURCE_GROUP" &> /dev/null; then
        az monitor app-insights component create \
            --app "$APP_INSIGHTS_NAME" \
            --location "$AZURE_LOCATION" \
            --resource-group "$AZURE_RESOURCE_GROUP" \
            --application-type web
        print_success "Application Insights created: $APP_INSIGHTS_NAME"
    else
        print_warning "Application Insights $APP_INSIGHTS_NAME already exists"
    fi
    
    # Get Application Insights key
    APP_INSIGHTS_KEY=$(az monitor app-insights component show --app "$APP_INSIGHTS_NAME" --resource-group "$AZURE_RESOURCE_GROUP" --query instrumentationKey -o tsv)
    
    # Configure Application Insights in Web App
    az webapp config appsettings set \
        --name "$BACKEND_APP_NAME" \
        --resource-group "$AZURE_RESOURCE_GROUP" \
        --settings \
            APPINSIGHTS_INSTRUMENTATIONKEY="$APP_INSIGHTS_KEY" \
            APPLICATIONINSIGHTS_CONNECTION_STRING="InstrumentationKey=$APP_INSIGHTS_KEY"
    
    print_success "Application Insights configured"
}

# Function to configure custom domain (optional)
configure_custom_domain() {
    read -p "Do you want to configure a custom domain? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        read -p "Enter custom domain (e.g., api.yourdomain.com): " CUSTOM_DOMAIN
        
        if [ ! -z "$CUSTOM_DOMAIN" ]; then
            print_status "Adding custom domain: $CUSTOM_DOMAIN"
            
            az webapp config hostname add \
                --webapp-name "$BACKEND_APP_NAME" \
                --resource-group "$AZURE_RESOURCE_GROUP" \
                --hostname "$CUSTOM_DOMAIN"
            
            print_success "Custom domain added: $CUSTOM_DOMAIN"
            print_warning "Please configure DNS records for $CUSTOM_DOMAIN to point to $BACKEND_APP_NAME.azurewebsites.net"
        fi
    fi
}

# Function to enable HTTPS only
enable_https_only() {
    print_status "Enabling HTTPS only..."
    
    az webapp update \
        --name "$BACKEND_APP_NAME" \
        --resource-group "$AZURE_RESOURCE_GROUP" \
        --https-only true
    
    print_success "HTTPS only enabled"
}

# Function to configure auto-restart
configure_auto_restart() {
    print_status "Configuring auto-restart on failure..."
    
    # Set restart policy
    az webapp config set \
        --name "$BACKEND_APP_NAME" \
        --resource-group "$AZURE_RESOURCE_GROUP" \
        --always-on true
    
    print_success "Auto-restart configured"
}

# Function to test deployment
test_deployment() {
    print_status "Testing deployment..."
    
    # Get Web App URL
    WEBAPP_URL="https://$BACKEND_APP_NAME.azurewebsites.net"
    
    # Wait for deployment to complete
    print_status "Waiting for deployment to complete..."
    sleep 30
    
    # Test health endpoint
    print_status "Testing health endpoint..."
    if curl -f "$WEBAPP_URL/api/v1/prediction/health" &> /dev/null; then
        print_success "Health check passed: $WEBAPP_URL/api/v1/prediction/health"
    else
        print_warning "Health check failed. Checking logs..."
        az webapp log tail --name "$BACKEND_APP_NAME" --resource-group "$AZURE_RESOURCE_GROUP" --timeout 10
    fi
    
    # Test API documentation
    print_status "Testing API documentation..."
    if curl -f "$WEBAPP_URL/docs" &> /dev/null; then
        print_success "API documentation accessible: $WEBAPP_URL/docs"
    else
        print_warning "API documentation not accessible"
    fi
}

# Function to display deployment summary
display_summary() {
    echo ""
    echo "🍷 Backend Deployment Complete!"
    echo "==============================="
    echo ""
    echo "📋 Summary:"
    echo "  Web App Name: $BACKEND_APP_NAME"
    echo "  Resource Group: $AZURE_RESOURCE_GROUP"
    echo "  App Service Plan: $APP_SERVICE_PLAN"
    echo "  Container Image: $ACR_LOGIN_SERVER/wine-backend:latest"
    echo ""
    echo "🌐 URLs:"
    echo "  Backend API: https://$BACKEND_APP_NAME.azurewebsites.net"
    echo "  API Docs: https://$BACKEND_APP_NAME.azurewebsites.net/docs"
    echo "  Health Check: https://$BACKEND_APP_NAME.azurewebsites.net/api/v1/prediction/health"
    echo ""
    echo "🔍 Monitoring:"
    echo "  Application Insights: https://portal.azure.com/#@/resource/subscriptions/$AZURE_SUBSCRIPTION_ID/resourceGroups/$AZURE_RESOURCE_GROUP/providers/microsoft.insights/components/${BACKEND_APP_NAME}-insights"
    echo ""
    echo "📊 Logs:"
    echo "  az webapp log tail --name $BACKEND_APP_NAME --resource-group $AZURE_RESOURCE_GROUP"
    echo ""
    echo "🚀 Next steps:"
    echo "  1. Deploy frontend: ./azure/frontend-static-webapp.sh"
    echo "  2. Set up CI/CD: ./azure/setup-pipeline.sh"
    echo "  3. Configure monitoring: ./azure/monitoring-setup.sh"
}

# Function to save deployment info
save_deployment_info() {
    print_status "Saving deployment information..."
    
    cat >> azure/.env.azure << EOF

# Backend Deployment Information
BACKEND_WEBAPP_NAME=$BACKEND_APP_NAME
BACKEND_URL=https://$BACKEND_APP_NAME.azurewebsites.net
APP_INSIGHTS_NAME=${BACKEND_APP_NAME}-insights
EOF
    
    print_success "Deployment information saved to azure/.env.azure"
}

# Main execution
main() {
    echo "Starting backend deployment to Azure App Service..."
    echo ""
    
    # Check prerequisites
    check_env_file
    check_azure_login
    verify_acr_images
    
    # Deploy backend
    create_webapp
    configure_webapp
    enable_continuous_deployment
    configure_health_check
    enable_application_insights
    configure_auto_restart
    enable_https_only
    
    # Optional configurations
    configure_custom_domain
    
    # Test deployment
    test_deployment
    
    # Save information and display summary
    save_deployment_info
    display_summary
}

# Run main function
main "$@"

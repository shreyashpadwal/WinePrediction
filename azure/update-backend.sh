#!/bin/bash
set -e

# Update Backend Deployment Script
# This script updates the Wine Quality Prediction backend deployment

echo "🍷 Wine Quality Prediction - Backend Update"
echo "==========================================="

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

# Function to build new backend image
build_backend_image() {
    print_status "Building new backend image..."
    
    # Build the image
    docker build -t wine-backend:latest ./backend
    print_success "Backend image built"
    
    # Tag with timestamp
    TIMESTAMP=$(date +%Y%m%d-%H%M%S)
    docker tag wine-backend:latest "$ACR_LOGIN_SERVER/wine-backend:$TIMESTAMP"
    docker tag wine-backend:latest "$ACR_LOGIN_SERVER/wine-backend:latest"
    
    print_success "Backend image tagged with timestamp: $TIMESTAMP"
}

# Function to push new image to ACR
push_to_acr() {
    print_status "Pushing new image to ACR..."
    
    # Login to ACR
    az acr login --name "$ACR_NAME"
    
    # Push images
    TIMESTAMP=$(date +%Y%m%d-%H%M%S)
    docker push "$ACR_LOGIN_SERVER/wine-backend:$TIMESTAMP"
    docker push "$ACR_LOGIN_SERVER/wine-backend:latest"
    
    print_success "New image pushed to ACR"
}

# Function to update Web App container
update_webapp_container() {
    print_status "Updating Web App container..."
    
    # Update container image
    az webapp config container set \
        --name "$BACKEND_APP_NAME" \
        --resource-group "$AZURE_RESOURCE_GROUP" \
        --docker-custom-image-name "$ACR_LOGIN_SERVER/wine-backend:latest"
    
    print_success "Web App container updated"
}

# Function to restart Web App
restart_webapp() {
    print_status "Restarting Web App..."
    
    az webapp restart \
        --name "$BACKEND_APP_NAME" \
        --resource-group "$AZURE_RESOURCE_GROUP"
    
    print_success "Web App restarted"
}

# Function to wait for deployment
wait_for_deployment() {
    print_status "Waiting for deployment to complete..."
    
    # Wait for the app to be ready
    for i in {1..30}; do
        if curl -f "https://$BACKEND_APP_NAME.azurewebsites.net/api/v1/prediction/health" &> /dev/null; then
            print_success "Deployment completed successfully"
            return 0
        fi
        echo "Waiting... ($i/30)"
        sleep 10
    done
    
    print_warning "Deployment may not be complete. Check logs for details."
}

# Function to verify deployment
verify_deployment() {
    print_status "Verifying deployment..."
    
    WEBAPP_URL="https://$BACKEND_APP_NAME.azurewebsites.net"
    
    # Test health endpoint
    if curl -f "$WEBAPP_URL/api/v1/prediction/health" &> /dev/null; then
        print_success "Health check passed: $WEBAPP_URL/api/v1/prediction/health"
    else
        print_error "Health check failed"
        return 1
    fi
    
    # Test API documentation
    if curl -f "$WEBAPP_URL/docs" &> /dev/null; then
        print_success "API documentation accessible: $WEBAPP_URL/docs"
    else
        print_warning "API documentation not accessible"
    fi
    
    # Test prediction endpoint (with sample data)
    print_status "Testing prediction endpoint..."
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
    
    if curl -X POST "$WEBAPP_URL/api/v1/prediction/predict" \
        -H "Content-Type: application/json" \
        -d "$SAMPLE_DATA" &> /dev/null; then
        print_success "Prediction endpoint working"
    else
        print_warning "Prediction endpoint may have issues"
    fi
}

# Function to show deployment logs
show_logs() {
    print_status "Recent deployment logs:"
    
    az webapp log tail \
        --name "$BACKEND_APP_NAME" \
        --resource-group "$AZURE_RESOURCE_GROUP" \
        --timeout 30
}

# Function to rollback if needed
rollback() {
    print_status "Rolling back to previous version..."
    
    # Get previous image tag
    PREVIOUS_TAG=$(az acr repository show-tags --name "$ACR_NAME" --repository wine-backend --orderby time_desc --query '[1].name' -o tsv)
    
    if [ ! -z "$PREVIOUS_TAG" ]; then
        print_status "Rolling back to: $PREVIOUS_TAG"
        
        az webapp config container set \
            --name "$BACKEND_APP_NAME" \
            --resource-group "$AZURE_RESOURCE_GROUP" \
            --docker-custom-image-name "$ACR_LOGIN_SERVER/wine-backend:$PREVIOUS_TAG"
        
        az webapp restart \
            --name "$BACKEND_APP_NAME" \
            --resource-group "$AZURE_RESOURCE_GROUP"
        
        print_success "Rolled back to: $PREVIOUS_TAG"
    else
        print_error "No previous version found for rollback"
    fi
}

# Function to display update summary
display_summary() {
    echo ""
    echo "🍷 Backend Update Complete!"
    echo "========================="
    echo ""
    echo "📋 Summary:"
    echo "  Web App: $BACKEND_APP_NAME"
    echo "  Resource Group: $AZURE_RESOURCE_GROUP"
    echo "  New Image: $ACR_LOGIN_SERVER/wine-backend:latest"
    echo ""
    echo "🌐 URLs:"
    echo "  Backend API: https://$BACKEND_APP_NAME.azurewebsites.net"
    echo "  API Docs: https://$BACKEND_APP_NAME.azurewebsites.net/docs"
    echo "  Health Check: https://$BACKEND_APP_NAME.azurewebsites.net/api/v1/prediction/health"
    echo ""
    echo "📊 Monitoring:"
    echo "  Logs: az webapp log tail --name $BACKEND_APP_NAME --resource-group $AZURE_RESOURCE_GROUP"
    echo "  Metrics: https://portal.azure.com/#@/resource/subscriptions/$AZURE_SUBSCRIPTION_ID/resourceGroups/$AZURE_RESOURCE_GROUP/providers/Microsoft.Web/sites/$BACKEND_APP_NAME"
}

# Main execution
main() {
    echo "Starting backend update..."
    echo ""
    
    # Check prerequisites
    check_env_file
    check_azure_login
    
    # Update process
    build_backend_image
    push_to_acr
    update_webapp_container
    restart_webapp
    wait_for_deployment
    
    # Verify deployment
    if verify_deployment; then
        print_success "Backend update completed successfully!"
        display_summary
    else
        print_error "Backend update failed verification"
        print_status "Showing logs..."
        show_logs
        
        read -p "Do you want to rollback to the previous version? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rollback
        fi
        
        exit 1
    fi
}

# Run main function
main "$@"

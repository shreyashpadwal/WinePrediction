#!/bin/bash
set -e

# Azure Container Registry Setup Script
# This script creates Azure resources for Wine Quality Prediction deployment

echo "🍷 Wine Quality Prediction - Azure Container Registry Setup"
echo "=========================================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration variables
RESOURCE_GROUP="wine-quality-rg"
LOCATION="eastus"
ACR_NAME="winequalityacr"
APP_SERVICE_PLAN="wine-quality-plan"
BACKEND_APP_NAME="wine-quality-backend"
FRONTEND_APP_NAME="wine-quality-frontend"

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

# Function to check if Azure CLI is installed
check_azure_cli() {
    print_status "Checking Azure CLI installation..."
    
    if ! command -v az &> /dev/null; then
        print_error "Azure CLI is not installed. Please install it first:"
        echo "curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash"
        exit 1
    fi
    
    print_success "Azure CLI is installed"
}

# Function to login to Azure
login_to_azure() {
    print_status "Logging into Azure..."
    
    # Check if already logged in
    if az account show &> /dev/null; then
        print_success "Already logged into Azure"
        CURRENT_USER=$(az account show --query user.name -o tsv)
        print_status "Logged in as: $CURRENT_USER"
    else
        print_status "Please log in to Azure..."
        az login
        print_success "Successfully logged into Azure"
    fi
}

# Function to set subscription
set_subscription() {
    print_status "Setting Azure subscription..."
    
    # List available subscriptions
    echo "Available subscriptions:"
    az account list --output table
    
    # Get current subscription
    CURRENT_SUBSCRIPTION=$(az account show --query id -o tsv)
    print_status "Current subscription: $CURRENT_SUBSCRIPTION"
    
    # Optionally set a specific subscription
    read -p "Do you want to use a different subscription? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        read -p "Enter subscription ID: " SUBSCRIPTION_ID
        az account set --subscription "$SUBSCRIPTION_ID"
        print_success "Subscription set to: $SUBSCRIPTION_ID"
    fi
}

# Function to create resource group
create_resource_group() {
    print_status "Creating resource group: $RESOURCE_GROUP"
    
    # Check if resource group already exists
    if az group show --name "$RESOURCE_GROUP" &> /dev/null; then
        print_warning "Resource group $RESOURCE_GROUP already exists"
    else
        az group create \
            --name "$RESOURCE_GROUP" \
            --location "$LOCATION" \
            --tags "project=wine-quality-prediction" "environment=production"
        print_success "Resource group created: $RESOURCE_GROUP"
    fi
}

# Function to create Azure Container Registry
create_acr() {
    print_status "Creating Azure Container Registry: $ACR_NAME"
    
    # Check if ACR already exists
    if az acr show --name "$ACR_NAME" --resource-group "$RESOURCE_GROUP" &> /dev/null; then
        print_warning "ACR $ACR_NAME already exists"
    else
        az acr create \
            --resource-group "$RESOURCE_GROUP" \
            --name "$ACR_NAME" \
            --sku Basic \
            --admin-enabled true \
            --location "$LOCATION"
        print_success "ACR created: $ACR_NAME"
    fi
    
    # Get ACR login server
    ACR_LOGIN_SERVER=$(az acr show --name "$ACR_NAME" --resource-group "$RESOURCE_GROUP" --query loginServer -o tsv)
    print_success "ACR login server: $ACR_LOGIN_SERVER"
}

# Function to get ACR credentials
get_acr_credentials() {
    print_status "Getting ACR credentials..."
    
    # Get admin credentials
    ACR_USERNAME=$(az acr credential show --name "$ACR_NAME" --query username -o tsv)
    ACR_PASSWORD=$(az acr credential show --name "$ACR_NAME" --query passwords[0].value -o tsv)
    
    print_success "ACR Username: $ACR_USERNAME"
    print_success "ACR Password: [HIDDEN]"
    
    # Save credentials to file
    cat > azure/.env.azure << EOF
# Azure Container Registry Credentials
ACR_NAME=$ACR_NAME
ACR_LOGIN_SERVER=$ACR_LOGIN_SERVER
ACR_USERNAME=$ACR_USERNAME
ACR_PASSWORD=$ACR_PASSWORD

# Azure Resource Configuration
AZURE_RESOURCE_GROUP=$RESOURCE_GROUP
AZURE_LOCATION=$LOCATION
AZURE_SUBSCRIPTION_ID=$(az account show --query id -o tsv)

# Application Configuration
APP_SERVICE_PLAN=$APP_SERVICE_PLAN
BACKEND_APP_NAME=$BACKEND_APP_NAME
FRONTEND_APP_NAME=$FRONTEND_APP_NAME
EOF
    
    print_success "ACR credentials saved to azure/.env.azure"
}

# Function to login to ACR
login_to_acr() {
    print_status "Logging into ACR..."
    
    az acr login --name "$ACR_NAME"
    print_success "Successfully logged into ACR"
}

# Function to tag images for ACR
tag_images() {
    print_status "Tagging Docker images for ACR..."
    
    # Tag backend image
    docker tag wine-backend:latest "$ACR_LOGIN_SERVER/wine-backend:latest"
    docker tag wine-backend:latest "$ACR_LOGIN_SERVER/wine-backend:v1.0.0"
    print_success "Backend image tagged"
    
    # Tag frontend image
    docker tag wine-frontend:latest "$ACR_LOGIN_SERVER/wine-frontend:latest"
    docker tag wine-frontend:latest "$ACR_LOGIN_SERVER/wine-frontend:v1.0.0"
    print_success "Frontend image tagged"
}

# Function to push images to ACR
push_images() {
    print_status "Pushing images to ACR..."
    
    # Push backend image
    print_status "Pushing backend image..."
    docker push "$ACR_LOGIN_SERVER/wine-backend:latest"
    docker push "$ACR_LOGIN_SERVER/wine-backend:v1.0.0"
    print_success "Backend image pushed"
    
    # Push frontend image
    print_status "Pushing frontend image..."
    docker push "$ACR_LOGIN_SERVER/wine-frontend:latest"
    docker push "$ACR_LOGIN_SERVER/wine-frontend:v1.0.0"
    print_success "Frontend image pushed"
}

# Function to list images in ACR
list_acr_images() {
    print_status "Listing images in ACR..."
    
    echo "Images in $ACR_NAME:"
    az acr repository list --name "$ACR_NAME" --output table
    
    echo ""
    echo "Backend image tags:"
    az acr repository show-tags --name "$ACR_NAME" --repository wine-backend --output table
    
    echo ""
    echo "Frontend image tags:"
    az acr repository show-tags --name "$ACR_NAME" --repository wine-frontend --output table
}

# Function to create App Service Plan
create_app_service_plan() {
    print_status "Creating App Service Plan: $APP_SERVICE_PLAN"
    
    # Check if App Service Plan already exists
    if az appservice plan show --name "$APP_SERVICE_PLAN" --resource-group "$RESOURCE_GROUP" &> /dev/null; then
        print_warning "App Service Plan $APP_SERVICE_PLAN already exists"
    else
        az appservice plan create \
            --name "$APP_SERVICE_PLAN" \
            --resource-group "$RESOURCE_GROUP" \
            --location "$LOCATION" \
            --is-linux \
            --sku B1
        print_success "App Service Plan created: $APP_SERVICE_PLAN"
    fi
}

# Function to display summary
display_summary() {
    echo ""
    echo "🍷 Azure Container Registry Setup Complete!"
    echo "=========================================="
    echo ""
    echo "📋 Summary:"
    echo "  Resource Group: $RESOURCE_GROUP"
    echo "  Location: $LOCATION"
    echo "  ACR Name: $ACR_NAME"
    echo "  ACR Login Server: $ACR_LOGIN_SERVER"
    echo "  App Service Plan: $APP_SERVICE_PLAN"
    echo ""
    echo "🔑 Credentials saved to: azure/.env.azure"
    echo ""
    echo "🚀 Next steps:"
    echo "  1. Build Docker images locally"
    echo "  2. Run: ./azure/push-to-acr.sh"
    echo "  3. Deploy backend: ./azure/backend-appservice.sh"
    echo "  4. Deploy frontend: ./azure/frontend-static-webapp.sh"
    echo ""
    echo "📚 Documentation: AZURE_SETUP.md"
}

# Main execution
main() {
    echo "Starting Azure Container Registry setup..."
    echo ""
    
    # Check prerequisites
    check_azure_cli
    
    # Azure setup
    login_to_azure
    set_subscription
    create_resource_group
    create_acr
    get_acr_credentials
    login_to_acr
    create_app_service_plan
    
    # Note: Images need to be built first
    print_warning "Note: Docker images need to be built before pushing to ACR"
    print_status "Run the following commands to build and push images:"
    echo "  make build"
    echo "  ./azure/push-to-acr.sh"
    
    # Display summary
    display_summary
}

# Run main function
main "$@"

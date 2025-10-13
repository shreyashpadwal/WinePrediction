#!/bin/bash
set -e

# Push Docker Images to Azure Container Registry
# This script builds and pushes the Wine Quality Prediction images to ACR

echo "🍷 Wine Quality Prediction - Push to Azure Container Registry"
echo "============================================================="

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

# Function to check if Docker is running
check_docker() {
    print_status "Checking Docker..."
    
    if ! docker info &> /dev/null; then
        print_error "Docker is not running. Please start Docker first"
        exit 1
    fi
    
    print_success "Docker is running"
}

# Function to build Docker images
build_images() {
    print_status "Building Docker images..."
    
    # Build backend image
    print_status "Building backend image..."
    docker build -t wine-backend:latest ./backend
    print_success "Backend image built"
    
    # Build frontend image
    print_status "Building frontend image..."
    docker build -t wine-frontend:latest ./frontend
    print_success "Frontend image built"
    
    # Display image sizes
    print_status "Image sizes:"
    docker images | grep wine
}

# Function to login to ACR
login_to_acr() {
    print_status "Logging into Azure Container Registry..."
    
    az acr login --name "$ACR_NAME"
    print_success "Successfully logged into ACR: $ACR_NAME"
}

# Function to tag images for ACR
tag_images() {
    print_status "Tagging images for ACR..."
    
    # Tag backend image
    docker tag wine-backend:latest "$ACR_LOGIN_SERVER/wine-backend:latest"
    docker tag wine-backend:latest "$ACR_LOGIN_SERVER/wine-backend:v1.0.0"
    docker tag wine-backend:latest "$ACR_LOGIN_SERVER/wine-backend:$(date +%Y%m%d-%H%M%S)"
    print_success "Backend image tagged"
    
    # Tag frontend image
    docker tag wine-frontend:latest "$ACR_LOGIN_SERVER/wine-frontend:latest"
    docker tag wine-frontend:latest "$ACR_LOGIN_SERVER/wine-frontend:v1.0.0"
    docker tag wine-frontend:latest "$ACR_LOGIN_SERVER/wine-frontend:$(date +%Y%m%d-%H%M%S)"
    print_success "Frontend image tagged"
}

# Function to push images to ACR
push_images() {
    print_status "Pushing images to ACR..."
    
    # Push backend image
    print_status "Pushing backend image..."
    docker push "$ACR_LOGIN_SERVER/wine-backend:latest"
    docker push "$ACR_LOGIN_SERVER/wine-backend:v1.0.0"
    docker push "$ACR_LOGIN_SERVER/wine-backend:$(date +%Y%m%d-%H%M%S)"
    print_success "Backend image pushed"
    
    # Push frontend image
    print_status "Pushing frontend image..."
    docker push "$ACR_LOGIN_SERVER/wine-frontend:latest"
    docker push "$ACR_LOGIN_SERVER/wine-frontend:v1.0.0"
    docker push "$ACR_LOGIN_SERVER/wine-frontend:$(date +%Y%m%d-%H%M%S)"
    print_success "Frontend image pushed"
}

# Function to verify images in ACR
verify_images() {
    print_status "Verifying images in ACR..."
    
    echo "Images in $ACR_NAME:"
    az acr repository list --name "$ACR_NAME" --output table
    
    echo ""
    echo "Backend image tags:"
    az acr repository show-tags --name "$ACR_NAME" --repository wine-backend --output table
    
    echo ""
    echo "Frontend image tags:"
    az acr repository show-tags --name "$ACR_NAME" --repository wine-frontend --output table
}

# Function to test image pull
test_image_pull() {
    print_status "Testing image pull from ACR..."
    
    # Test backend image pull
    print_status "Testing backend image pull..."
    docker pull "$ACR_LOGIN_SERVER/wine-backend:latest"
    print_success "Backend image pull successful"
    
    # Test frontend image pull
    print_status "Testing frontend image pull..."
    docker pull "$ACR_LOGIN_SERVER/wine-frontend:latest"
    print_success "Frontend image pull successful"
}

# Function to display summary
display_summary() {
    echo ""
    echo "🍷 Images Successfully Pushed to ACR!"
    echo "====================================="
    echo ""
    echo "📋 Summary:"
    echo "  ACR Name: $ACR_NAME"
    echo "  ACR Login Server: $ACR_LOGIN_SERVER"
    echo "  Backend Image: $ACR_LOGIN_SERVER/wine-backend:latest"
    echo "  Frontend Image: $ACR_LOGIN_SERVER/wine-frontend:latest"
    echo ""
    echo "🚀 Next steps:"
    echo "  1. Deploy backend: ./azure/backend-appservice.sh"
    echo "  2. Deploy frontend: ./azure/frontend-static-webapp.sh"
    echo "  3. Set up CI/CD: ./azure/setup-pipeline.sh"
    echo ""
    echo "🔍 Verify images:"
    echo "  az acr repository list --name $ACR_NAME"
    echo "  az acr repository show-tags --name $ACR_NAME --repository wine-backend"
}

# Function to cleanup local images (optional)
cleanup_local_images() {
    read -p "Do you want to remove local Docker images to save space? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_status "Cleaning up local Docker images..."
        docker rmi wine-backend:latest wine-frontend:latest 2>/dev/null || true
        print_success "Local images cleaned up"
    fi
}

# Main execution
main() {
    echo "Starting image build and push to ACR..."
    echo ""
    
    # Check prerequisites
    check_env_file
    check_docker
    
    # Build and push process
    build_images
    login_to_acr
    tag_images
    push_images
    verify_images
    test_image_pull
    
    # Optional cleanup
    cleanup_local_images
    
    # Display summary
    display_summary
}

# Run main function
main "$@"

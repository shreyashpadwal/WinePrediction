#!/bin/bash
set -e

# Quick Health Check Script for Wine Quality Prediction
# Lightweight version of the comprehensive audit

echo "🍷 Wine Quality Prediction - Quick Health Check"
echo "=============================================="

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

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check Docker services
check_docker_services() {
    print_status "Checking Docker services..."
    
    if ! command_exists docker; then
        print_error "Docker not found"
        return 1
    fi
    
    if ! command_exists docker-compose; then
        print_error "Docker Compose not found"
        return 1
    fi
    
    # Start services
    print_status "Starting Docker services..."
    docker-compose up -d
    
    # Wait for services to start
    print_status "Waiting for services to start..."
    sleep 30
    
    # Check container status
    backend_status=$(docker-compose ps backend --format "table {{.State}}" | tail -n 1)
    frontend_status=$(docker-compose ps frontend --format "table {{.State}}" | tail -n 1)
    
    if [[ "$backend_status" == *"Up"* ]]; then
        print_success "Backend container is running"
    else
        print_error "Backend container is not running"
        return 1
    fi
    
    if [[ "$frontend_status" == *"Up"* ]]; then
        print_success "Frontend container is running"
    else
        print_error "Frontend container is not running"
        return 1
    fi
    
    return 0
}

# Function to test backend health
test_backend_health() {
    print_status "Testing backend health..."
    
    # Test health endpoint
    if command_exists curl; then
        response=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8000/api/v1/prediction/health || echo "000")
        
        if [ "$response" = "200" ]; then
            print_success "Backend health check passed (HTTP 200)"
            return 0
        else
            print_error "Backend health check failed (HTTP $response)"
            return 1
        fi
    else
        print_warning "curl not found, skipping backend health check"
        return 0
    fi
}

# Function to test frontend loading
test_frontend_loading() {
    print_status "Testing frontend loading..."
    
    if command_exists curl; then
        response=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:80 || echo "000")
        
        if [ "$response" = "200" ]; then
            print_success "Frontend is accessible (HTTP 200)"
            return 0
        else
            print_error "Frontend is not accessible (HTTP $response)"
            return 1
        fi
    else
        print_warning "curl not found, skipping frontend test"
        return 0
    fi
}

# Function to test prediction endpoint
test_prediction_endpoint() {
    print_status "Testing prediction endpoint..."
    
    if command_exists curl; then
        # Sample wine data
        sample_data='{
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
        
        # Test prediction endpoint
        start_time=$(date +%s)
        response=$(curl -s -X POST http://localhost:8000/api/v1/prediction/predict \
            -H "Content-Type: application/json" \
            -d "$sample_data" \
            -w "%{http_code}" || echo "000")
        end_time=$(date +%s)
        
        response_time=$((end_time - start_time))
        
        if [[ "$response" == *"200" ]]; then
            print_success "Prediction endpoint working (HTTP 200, ${response_time}s)"
            return 0
        else
            print_error "Prediction endpoint failed (HTTP $response)"
            return 1
        fi
    else
        print_warning "curl not found, skipping prediction test"
        return 0
    fi
}

# Function to check for critical errors in logs
check_critical_errors() {
    print_status "Checking for critical errors in logs..."
    
    error_count=0
    
    # Check backend logs
    if [ -f "backend/logs/error.log" ]; then
        # Count errors from last 24 hours
        recent_errors=$(grep -c "$(date -d '24 hours ago' '+%Y-%m-%d')" backend/logs/error.log 2>/dev/null || echo "0")
        if [ "$recent_errors" -gt 0 ]; then
            print_warning "$recent_errors errors found in backend logs (last 24 hours)"
            error_count=$((error_count + recent_errors))
        fi
    fi
    
    # Check Docker logs
    if command_exists docker; then
        docker_errors=$(docker-compose logs backend 2>&1 | grep -c -i "error\|exception\|failed" || echo "0")
        if [ "$docker_errors" -gt 0 ]; then
            print_warning "$docker_errors errors found in Docker logs"
            error_count=$((error_count + docker_errors))
        fi
    fi
    
    if [ "$error_count" -eq 0 ]; then
        print_success "No critical errors found in logs"
        return 0
    else
        print_warning "$error_count total errors found in logs"
        return 1
    fi
}

# Function to check file integrity
check_file_integrity() {
    print_status "Checking file integrity..."
    
    issues=0
    
    # Check if model file exists
    if [ ! -f "backend/saved_models/best_model.pkl" ]; then
        print_error "Model file missing: backend/saved_models/best_model.pkl"
        issues=$((issues + 1))
    else
        print_success "Model file exists"
    fi
    
    # Check if environment variables are set
    if [ ! -f "backend/.env" ]; then
        print_warning "Environment file missing: backend/.env"
        issues=$((issues + 1))
    else
        print_success "Environment file exists"
    fi
    
    # Check for committed .env files
    if command_exists git; then
        committed_env=$(git ls-files "*.env" 2>/dev/null || echo "")
        if [ -n "$committed_env" ]; then
            print_error "Environment files committed to git: $committed_env"
            issues=$((issues + 1))
        else
            print_success "No environment files committed to git"
        fi
    fi
    
    # Check critical files
    critical_files=(
        "backend/app/main.py"
        "frontend/package.json"
        "docker-compose.yml"
        "README.md"
    )
    
    for file in "${critical_files[@]}"; do
        if [ -f "$file" ]; then
            print_success "Critical file exists: $file"
        else
            print_error "Critical file missing: $file"
            issues=$((issues + 1))
        fi
    done
    
    if [ "$issues" -eq 0 ]; then
        print_success "All files intact"
        return 0
    else
        print_warning "$issues file integrity issues found"
        return 1
    fi
}

# Function to check system resources
check_system_resources() {
    print_status "Checking system resources..."
    
    # Check available disk space
    if command_exists df; then
        disk_usage=$(df -h . | tail -n 1 | awk '{print $5}' | sed 's/%//')
        if [ "$disk_usage" -gt 90 ]; then
            print_warning "Disk usage is high: ${disk_usage}%"
        else
            print_success "Disk usage is acceptable: ${disk_usage}%"
        fi
    fi
    
    # Check memory usage
    if command_exists free; then
        memory_usage=$(free | grep Mem | awk '{printf "%.0f", $3/$2 * 100.0}')
        if [ "$memory_usage" -gt 90 ]; then
            print_warning "Memory usage is high: ${memory_usage}%"
        else
            print_success "Memory usage is acceptable: ${memory_usage}%"
        fi
    fi
    
    return 0
}

# Function to generate health report
generate_health_report() {
    local docker_status=$1
    local backend_status=$2
    local frontend_status=$3
    local prediction_status=$4
    local error_status=$5
    local file_status=$6
    local resource_status=$7
    
    echo ""
    echo "=============================================="
    echo "🏥 HEALTH CHECK REPORT"
    echo "=============================================="
    echo ""
    
    # Overall status
    total_checks=7
    passed_checks=0
    
    if [ "$docker_status" -eq 0 ]; then
        echo "✅ All services running"
        passed_checks=$((passed_checks + 1))
    else
        echo "❌ Services not running"
    fi
    
    if [ "$backend_status" -eq 0 ]; then
        echo "✅ Backend healthy"
        passed_checks=$((passed_checks + 1))
    else
        echo "❌ Backend unhealthy"
    fi
    
    if [ "$frontend_status" -eq 0 ]; then
        echo "✅ Frontend accessible"
        passed_checks=$((passed_checks + 1))
    else
        echo "❌ Frontend not accessible"
    fi
    
    if [ "$prediction_status" -eq 0 ]; then
        echo "✅ Prediction working"
        passed_checks=$((passed_checks + 1))
    else
        echo "❌ Prediction not working"
    fi
    
    if [ "$error_status" -eq 0 ]; then
        echo "✅ No critical errors"
        passed_checks=$((passed_checks + 1))
    else
        echo "⚠️  Errors found in logs"
    fi
    
    if [ "$file_status" -eq 0 ]; then
        echo "✅ Files intact"
        passed_checks=$((passed_checks + 1))
    else
        echo "⚠️  File integrity issues"
    fi
    
    if [ "$resource_status" -eq 0 ]; then
        echo "✅ System resources OK"
        passed_checks=$((passed_checks + 1))
    else
        echo "⚠️  System resource issues"
    fi
    
    echo ""
    echo "=============================================="
    
    # Overall health score
    health_score=$((passed_checks * 100 / total_checks))
    
    if [ "$health_score" -ge 90 ]; then
        echo "🟢 OVERALL: HEALTHY ✅"
        echo "Health Score: $health_score%"
        return 0
    elif [ "$health_score" -ge 70 ]; then
        echo "🟡 OVERALL: MOSTLY HEALTHY ⚠️"
        echo "Health Score: $health_score%"
        return 1
    else
        echo "🔴 OVERALL: NEEDS ATTENTION ❌"
        echo "Health Score: $health_score%"
        return 2
    fi
}

# Main execution
main() {
    echo "Starting quick health check..."
    echo ""
    
    # Check if we're in the right directory
    if [ ! -f "README.md" ] && [ ! -f "docker-compose.yml" ]; then
        print_error "Not in project root directory. Please run from project root."
        exit 1
    fi
    
    # Run health checks
    check_docker_services
    docker_status=$?
    
    test_backend_health
    backend_status=$?
    
    test_frontend_loading
    frontend_status=$?
    
    test_prediction_endpoint
    prediction_status=$?
    
    check_critical_errors
    error_status=$?
    
    check_file_integrity
    file_status=$?
    
    check_system_resources
    resource_status=$?
    
    # Generate report
    generate_health_report $docker_status $backend_status $frontend_status $prediction_status $error_status $file_status $resource_status
    
    # Exit with appropriate code
    if [ "$health_score" -ge 90 ]; then
        exit 0
    elif [ "$health_score" -ge 70 ]; then
        exit 1
    else
        exit 2
    fi
}

# Run main function
main "$@"

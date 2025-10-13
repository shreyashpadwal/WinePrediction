#!/bin/bash
set -e

echo "🍷 Starting Wine Quality Prediction API..."

# Function to check if model files exist
check_models() {
    echo "📊 Checking ML model files..."
    
    if [ ! -f "saved_models/best_model.pkl" ]; then
        echo "⚠️  Warning: best_model.pkl not found in saved_models/"
        echo "   Please ensure you have trained the models using the Jupyter notebooks"
        echo "   The API will start but predictions may fail"
    else
        echo "✅ best_model.pkl found"
    fi
    
    if [ ! -f "saved_models/scaler.pkl" ]; then
        echo "⚠️  Warning: scaler.pkl not found in saved_models/"
    else
        echo "✅ scaler.pkl found"
    fi
    
    if [ ! -f "saved_models/label_encoder.pkl" ]; then
        echo "⚠️  Warning: label_encoder.pkl not found in saved_models/"
    else
        echo "✅ label_encoder.pkl found"
    fi
    
    if [ ! -f "saved_models/model_comparison.json" ]; then
        echo "⚠️  Warning: model_comparison.json not found in saved_models/"
    else
        echo "✅ model_comparison.json found"
    fi
}

# Function to create necessary directories
create_directories() {
    echo "📁 Creating necessary directories..."
    
    # Create logs directory if it doesn't exist
    if [ ! -d "logs" ]; then
        mkdir -p logs
        echo "✅ Created logs directory"
    fi
    
    # Create saved_models directory if it doesn't exist
    if [ ! -d "saved_models" ]; then
        mkdir -p saved_models
        echo "✅ Created saved_models directory"
    fi
    
    # Set proper permissions
    chmod 755 logs saved_models
}

# Function to check environment variables
check_environment() {
    echo "🔧 Checking environment variables..."
    
    if [ -z "$GEMINI_API_KEY" ]; then
        echo "⚠️  Warning: GEMINI_API_KEY not set"
        echo "   AI explanations will not be available"
    else
        echo "✅ GEMINI_API_KEY is set"
    fi
    
    if [ -z "$ENVIRONMENT" ]; then
        export ENVIRONMENT="production"
        echo "✅ ENVIRONMENT set to production"
    else
        echo "✅ ENVIRONMENT is set to $ENVIRONMENT"
    fi
    
    if [ -z "$LOG_LEVEL" ]; then
        export LOG_LEVEL="INFO"
        echo "✅ LOG_LEVEL set to INFO"
    else
        echo "✅ LOG_LEVEL is set to $LOG_LEVEL"
    fi
}

# Function to wait for dependencies (if any)
wait_for_dependencies() {
    echo "⏳ Checking dependencies..."
    
    # Add any dependency checks here
    # For example, if you have a database:
    # echo "Waiting for database..."
    # while ! nc -z $DB_HOST $DB_PORT; do
    #   sleep 1
    # done
    # echo "✅ Database is ready"
}

# Function to run initialization scripts
run_init_scripts() {
    echo "🚀 Running initialization scripts..."
    
    # Add any initialization scripts here
    # For example:
    # python scripts/init_db.py
    # python scripts/load_sample_data.py
    
    echo "✅ Initialization complete"
}

# Function to start the application
start_app() {
    echo "🎯 Starting Wine Quality Prediction API..."
    echo "   Environment: $ENVIRONMENT"
    echo "   Log Level: $LOG_LEVEL"
    echo "   Port: 8000"
    echo ""
    
    # Execute the main command
    exec "$@"
}

# Main execution
main() {
    echo "=========================================="
    echo "🍷 Wine Quality Prediction API"
    echo "=========================================="
    
    create_directories
    check_environment
    check_models
    wait_for_dependencies
    run_init_scripts
    
    echo "=========================================="
    echo "🚀 All checks passed! Starting API..."
    echo "=========================================="
    
    start_app "$@"
}

# Run main function with all arguments
main "$@"

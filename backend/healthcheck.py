#!/usr/bin/env python3
"""
Health check script for Wine Quality Prediction API.
This script verifies that the application is healthy and ready to serve requests.
"""

import sys
import os
import requests
import time
from pathlib import Path

def check_model_files():
    """Check if required model files exist."""
    print("🔍 Checking model files...")
    
    required_files = [
        "saved_models/best_model.pkl",
        "saved_models/scaler.pkl", 
        "saved_models/label_encoder.pkl",
        "saved_models/model_comparison.json"
    ]
    
    missing_files = []
    for file_path in required_files:
        if not Path(file_path).exists():
            missing_files.append(file_path)
        else:
            print(f"✅ {file_path}")
    
    if missing_files:
        print(f"❌ Missing files: {', '.join(missing_files)}")
        return False
    
    print("✅ All model files present")
    return True

def check_api_health():
    """Check if the API is responding to health checks."""
    print("🔍 Checking API health...")
    
    try:
        # Try to connect to the health endpoint
        response = requests.get(
            "http://localhost:8000/api/v1/prediction/health",
            timeout=10
        )
        
        if response.status_code == 200:
            print("✅ API health check passed")
            return True
        else:
            print(f"❌ API health check failed: {response.status_code}")
            return False
            
    except requests.exceptions.RequestException as e:
        print(f"❌ API health check failed: {e}")
        return False

def check_environment():
    """Check if required environment variables are set."""
    print("🔍 Checking environment variables...")
    
    required_vars = ["ENVIRONMENT", "LOG_LEVEL"]
    optional_vars = ["AIzaSyBO2yC20Mki7TzuLki6IvlxcJeTWX7-SG8"]
    
    all_good = True
    
    for var in required_vars:
        if var in os.environ:
            print(f"✅ {var}={os.environ[var]}")
        else:
            print(f"❌ Required environment variable {var} not set")
            all_good = False
    
    for var in optional_vars:
        if var in os.environ:
            print(f"✅ {var} is set")
        else:
            print(f"⚠️  Optional environment variable {var} not set")
    
    return all_good

def check_directories():
    """Check if required directories exist and are writable."""
    print("🔍 Checking directories...")
    
    required_dirs = ["logs", "saved_models"]
    
    for dir_path in required_dirs:
        path = Path(dir_path)
        if path.exists() and path.is_dir():
            if os.access(dir_path, os.W_OK):
                print(f"✅ {dir_path} exists and is writable")
            else:
                print(f"❌ {dir_path} exists but is not writable")
                return False
        else:
            print(f"❌ {dir_path} does not exist")
            return False
    
    return True

def check_dependencies():
    """Check if required Python packages are available."""
    print("🔍 Checking Python dependencies...")
    
    required_packages = [
        "fastapi",
        "uvicorn", 
        "pandas",
        "numpy",
        "sklearn",
        "xgboost",
        "google.generativeai",
        "pydantic"
    ]
    
    missing_packages = []
    for package in required_packages:
        try:
            __import__(package)
            print(f"✅ {package}")
        except ImportError:
            missing_packages.append(package)
            print(f"❌ {package}")
    
    if missing_packages:
        print(f"❌ Missing packages: {', '.join(missing_packages)}")
        return False
    
    return True

def main():
    """Main health check function."""
    print("🍷 Wine Quality Prediction API - Health Check")
    print("=" * 50)
    
    checks = [
        ("Environment Variables", check_environment),
        ("Directories", check_directories),
        ("Dependencies", check_dependencies),
        ("Model Files", check_model_files),
        ("API Health", check_api_health)
    ]
    
    all_passed = True
    
    for check_name, check_func in checks:
        print(f"\n📋 {check_name}")
        print("-" * 30)
        
        try:
            if check_func():
                print(f"✅ {check_name} check passed")
            else:
                print(f"❌ {check_name} check failed")
                all_passed = False
        except Exception as e:
            print(f"❌ {check_name} check error: {e}")
            all_passed = False
    
    print("\n" + "=" * 50)
    if all_passed:
        print("🎉 All health checks passed! API is healthy.")
        sys.exit(0)
    else:
        print("❌ Some health checks failed. API is not healthy.")
        sys.exit(1)

if __name__ == "__main__":
    main()

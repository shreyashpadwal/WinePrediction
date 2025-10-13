#!/usr/bin/env python3
"""
Complete Wine Quality Prediction Project Verification Script
Checks all components are properly set up and integrated.
"""

import os
import sys
import json
import subprocess
from pathlib import Path

def print_header(title):
    """Print a formatted header."""
    print(f"\n{'='*60}")
    print(f"🍷 {title}")
    print(f"{'='*60}")

def print_success(message):
    """Print success message."""
    print(f"✅ {message}")

def print_error(message):
    """Print error message."""
    print(f"❌ {message}")

def print_warning(message):
    """Print warning message."""
    print(f"⚠️  {message}")

def check_file_exists(file_path, description):
    """Check if a file exists."""
    if os.path.exists(file_path):
        print_success(f"{description}: {file_path}")
        return True
    else:
        print_error(f"{description}: {file_path} - MISSING")
        return False

def check_directory_exists(dir_path, description):
    """Check if a directory exists."""
    if os.path.isdir(dir_path):
        print_success(f"{description}: {dir_path}")
        return True
    else:
        print_error(f"{description}: {dir_path} - MISSING")
        return False

def check_python_imports():
    """Check if required Python packages can be imported."""
    print_header("Python Dependencies Check")
    
    required_packages = [
        'fastapi', 'uvicorn', 'pandas', 'numpy', 'sklearn', 
        'xgboost', 'google.generativeai', 'pydantic', 'joblib'
    ]
    
    all_good = True
    for package in required_packages:
        try:
            __import__(package)
            print_success(f"Python package: {package}")
        except ImportError:
            print_error(f"Python package: {package} - NOT INSTALLED")
            all_good = False
    
    return all_good

def check_backend_structure():
    """Check backend directory structure."""
    print_header("Backend Structure Check")
    
    required_files = [
        'backend/app/main.py',
        'backend/app/utils/logger.py',
        'backend/app/utils/validators.py',
        'backend/app/services/ml_service.py',
        'backend/app/services/gemini_service.py',
        'backend/app/routes/prediction.py',
        'backend/requirements.txt',
        'backend/.env.example'
    ]
    
    required_dirs = [
        'backend/app',
        'backend/app/models',
        'backend/app/routes',
        'backend/app/services',
        'backend/app/utils',
        'backend/saved_models',
        'backend/logs',
        'backend/tests'
    ]
    
    all_good = True
    
    for file_path in required_files:
        if not check_file_exists(file_path, "Backend file"):
            all_good = False
    
    for dir_path in required_dirs:
        if not check_directory_exists(dir_path, "Backend directory"):
            all_good = False
    
    return all_good

def check_frontend_structure():
    """Check frontend directory structure."""
    print_header("Frontend Structure Check")
    
    required_files = [
        'frontend/package.json',
        'frontend/vite.config.ts',
        'frontend/tsconfig.json',
        'frontend/tailwind.config.js',
        'frontend/src/App.tsx',
        'frontend/src/main.tsx',
        'frontend/src/components/Layout.tsx',
        'frontend/src/components/WineQualityForm.tsx',
        'frontend/src/components/ResultsDisplay.tsx',
        'frontend/src/services/api.ts',
        'frontend/src/types/wine.ts'
    ]
    
    required_dirs = [
        'frontend/src',
        'frontend/src/components',
        'frontend/src/services',
        'frontend/src/types',
        'frontend/src/styles',
        'frontend/src/utils'
    ]
    
    all_good = True
    
    for file_path in required_files:
        if not check_file_exists(file_path, "Frontend file"):
            all_good = False
    
    for dir_path in required_dirs:
        if not check_directory_exists(dir_path, "Frontend directory"):
            all_good = False
    
    return all_good

def check_notebooks():
    """Check if notebooks exist and have content."""
    print_header("Jupyter Notebooks Check")
    
    notebooks = [
        'notebooks/01_eda_preprocessing.ipynb',
        'notebooks/02_model_training.ipynb'
    ]
    
    all_good = True
    
    for notebook in notebooks:
        if check_file_exists(notebook, "Notebook"):
            # Check if notebook has content
            try:
                with open(notebook, 'r', encoding='utf-8') as f:
                    content = f.read()
                    if len(content) > 1000:  # Basic content check
                        print_success(f"Notebook has content: {notebook}")
                    else:
                        print_warning(f"Notebook may be empty: {notebook}")
            except Exception as e:
                print_error(f"Error reading notebook {notebook}: {e}")
                all_good = False
        else:
            all_good = False
    
    return all_good

def check_docker_setup():
    """Check Docker configuration files."""
    print_header("Docker Configuration Check")
    
    docker_files = [
        'docker-compose.yml',
        'backend/Dockerfile',
        'frontend/Dockerfile',
        'frontend/nginx.conf'
    ]
    
    all_good = True
    
    for file_path in docker_files:
        if not check_file_exists(file_path, "Docker file"):
            all_good = False
    
    return all_good

def check_environment_files():
    """Check environment configuration files."""
    print_header("Environment Configuration Check")
    
    env_files = [
        'backend/.env.example',
        '.gitignore'
    ]
    
    all_good = True
    
    for file_path in env_files:
        if not check_file_exists(file_path, "Environment file"):
            all_good = False
    
    # Check if .env.example has required variables
    if os.path.exists('backend/.env.example'):
        try:
            with open('backend/.env.example', 'r') as f:
                content = f.read()
                required_vars = ['GEMINI_API_KEY', 'ENVIRONMENT', 'LOG_LEVEL']
                for var in required_vars:
                    if var in content:
                        print_success(f"Environment variable defined: {var}")
                    else:
                        print_error(f"Missing environment variable: {var}")
                        all_good = False
        except Exception as e:
            print_error(f"Error reading .env.example: {e}")
            all_good = False
    
    return all_good

def check_test_files():
    """Check test files exist."""
    print_header("Testing Setup Check")
    
    test_files = [
        'backend/tests/test_api.py',
        'backend/tests/test_ml_service.py',
        'backend/tests/test_error_handling.py',
        'frontend/src/__tests__/App.test.tsx',
        'frontend/src/__tests__/WineQualityForm.test.tsx',
        'frontend/vitest.config.ts'
    ]
    
    all_good = True
    
    for file_path in test_files:
        if not check_file_exists(file_path, "Test file"):
            all_good = False
    
    return all_good

def check_documentation():
    """Check documentation files."""
    print_header("Documentation Check")
    
    doc_files = [
        'README.md',
        'frontend/README.md'
    ]
    
    all_good = True
    
    for file_path in doc_files:
        if check_file_exists(file_path, "Documentation file"):
            # Check if README has substantial content
            try:
                with open(file_path, 'r', encoding='utf-8') as f:
                    content = f.read()
                    if len(content) > 5000:  # Substantial content check
                        print_success(f"Documentation has substantial content: {file_path}")
                    else:
                        print_warning(f"Documentation may need more content: {file_path}")
            except Exception as e:
                print_error(f"Error reading documentation {file_path}: {e}")
                all_good = False
        else:
            all_good = False
    
    return all_good

def main():
    """Main verification function."""
    print_header("Wine Quality Prediction Project - Complete Verification")
    
    checks = [
        ("Backend Structure", check_backend_structure),
        ("Frontend Structure", check_frontend_structure),
        ("Jupyter Notebooks", check_notebooks),
        ("Docker Configuration", check_docker_setup),
        ("Environment Setup", check_environment_files),
        ("Testing Setup", check_test_files),
        ("Documentation", check_documentation),
        ("Python Dependencies", check_python_imports)
    ]
    
    results = {}
    
    for check_name, check_func in checks:
        try:
            results[check_name] = check_func()
        except Exception as e:
            print_error(f"Error during {check_name}: {e}")
            results[check_name] = False
    
    # Summary
    print_header("VERIFICATION SUMMARY")
    
    passed = sum(results.values())
    total = len(results)
    
    for check_name, result in results.items():
        status = "✅ PASSED" if result else "❌ FAILED"
        print(f"{check_name}: {status}")
    
    print(f"\nOverall: {passed}/{total} checks passed")
    
    if passed == total:
        print_success("🎉 ALL CHECKS PASSED! Your Wine Quality Prediction project is complete!")
        print("\n🚀 Next steps:")
        print("1. Set up your Gemini API key in backend/.env")
        print("2. Run the Jupyter notebooks to train models")
        print("3. Start the backend: cd backend && uvicorn app.main:app --reload")
        print("4. Start the frontend: cd frontend && npm run dev")
        print("5. Open http://localhost:3000 in your browser")
        print("\n🍷 Cheers to great wine predictions!")
    else:
        print_error(f"❌ {total - passed} checks failed. Please fix the issues above.")
        return 1
    
    return 0

if __name__ == "__main__":
    sys.exit(main())

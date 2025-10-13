#!/usr/bin/env python3
"""
Docker Setup Verification Script
Checks if all Docker configuration files are properly set up.
"""

import os
import sys
from pathlib import Path

def print_header(title):
    """Print a formatted header."""
    print(f"\n{'='*60}")
    print(f"🐳 {title}")
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

def check_docker_files():
    """Check Docker configuration files."""
    print_header("Docker Configuration Files")
    
    required_files = [
        'docker-compose.yml',
        'docker-compose.dev.yml',
        'Makefile',
        'env.docker.example',
        'DOCKER.md',
        'backend/Dockerfile',
        'backend/.dockerignore',
        'backend/docker-entrypoint.sh',
        'backend/healthcheck.py',
        'frontend/Dockerfile',
        'frontend/.dockerignore',
        'frontend/docker-entrypoint.sh',
        'frontend/nginx.conf'
    ]
    
    all_good = True
    
    for file_path in required_files:
        if not check_file_exists(file_path, "Docker file"):
            all_good = False
    
    return all_good

def check_dockerfile_content():
    """Check Dockerfile content for best practices."""
    print_header("Dockerfile Content Analysis")
    
    all_good = True
    
    # Check backend Dockerfile
    if os.path.exists('backend/Dockerfile'):
        with open('backend/Dockerfile', 'r') as f:
            content = f.read()
            
        checks = [
            ('Multi-stage build', 'FROM.*as builder' in content),
            ('Non-root user', 'USER app' in content),
            ('Health check', 'HEALTHCHECK' in content),
            ('Security labels', 'LABEL maintainer' in content),
            ('Entrypoint script', 'ENTRYPOINT' in content)
        ]
        
        for check_name, passed in checks:
            if passed:
                print_success(f"Backend Dockerfile: {check_name}")
            else:
                print_error(f"Backend Dockerfile: {check_name} - MISSING")
                all_good = False
    
    # Check frontend Dockerfile
    if os.path.exists('frontend/Dockerfile'):
        with open('frontend/Dockerfile', 'r') as f:
            content = f.read()
            
        checks = [
            ('Multi-stage build', 'FROM.*AS builder' in content),
            ('Non-root user', 'USER nextjs' in content),
            ('Health check', 'HEALTHCHECK' in content),
            ('Security labels', 'LABEL maintainer' in content),
            ('Nginx config', 'nginx.conf' in content)
        ]
        
        for check_name, passed in checks:
            if passed:
                print_success(f"Frontend Dockerfile: {check_name}")
            else:
                print_error(f"Frontend Dockerfile: {check_name} - MISSING")
                all_good = False
    
    return all_good

def check_docker_compose():
    """Check docker-compose.yml configuration."""
    print_header("Docker Compose Configuration")
    
    if not os.path.exists('docker-compose.yml'):
        print_error("docker-compose.yml not found")
        return False
    
    with open('docker-compose.yml', 'r') as f:
        content = f.read()
    
    checks = [
        ('Backend service', 'backend:' in content),
        ('Frontend service', 'frontend:' in content),
        ('Redis service', 'redis:' in content),
        ('Health checks', 'healthcheck:' in content),
        ('Resource limits', 'deploy:' in content),
        ('Named volumes', 'volumes:' in content),
        ('Custom network', 'networks:' in content),
        ('Logging config', 'logging:' in content)
    ]
    
    all_good = True
    for check_name, passed in checks:
        if passed:
            print_success(f"Docker Compose: {check_name}")
        else:
            print_error(f"Docker Compose: {check_name} - MISSING")
            all_good = False
    
    return all_good

def check_makefile():
    """Check Makefile commands."""
    print_header("Makefile Commands")
    
    if not os.path.exists('Makefile'):
        print_error("Makefile not found")
        return False
    
    with open('Makefile', 'r') as f:
        content = f.read()
    
    required_commands = [
        'build:',
        'up:',
        'down:',
        'logs:',
        'test:',
        'clean:',
        'health:',
        'status:'
    ]
    
    all_good = True
    for command in required_commands:
        if command in content:
            print_success(f"Makefile command: {command}")
        else:
            print_error(f"Makefile command: {command} - MISSING")
            all_good = False
    
    return all_good

def check_environment_template():
    """Check environment template file."""
    print_header("Environment Configuration")
    
    if not os.path.exists('env.docker.example'):
        print_error("env.docker.example not found")
        return False
    
    with open('env.docker.example', 'r') as f:
        content = f.read()
    
    required_vars = [
        'GEMINI_API_KEY',
        'ENVIRONMENT',
        'LOG_LEVEL',
        'VITE_API_URL'
    ]
    
    all_good = True
    for var in required_vars:
        if var in content:
            print_success(f"Environment variable: {var}")
        else:
            print_error(f"Environment variable: {var} - MISSING")
            all_good = False
    
    return all_good

def check_security_features():
    """Check security features in configuration."""
    print_header("Security Features")
    
    all_good = True
    
    # Check nginx security headers
    if os.path.exists('frontend/nginx.conf'):
        with open('frontend/nginx.conf', 'r') as f:
            nginx_content = f.read()
        
        security_headers = [
            'X-Frame-Options',
            'X-Content-Type-Options',
            'X-XSS-Protection',
            'Strict-Transport-Security',
            'Content-Security-Policy'
        ]
        
        for header in security_headers:
            if header in nginx_content:
                print_success(f"Nginx security header: {header}")
            else:
                print_error(f"Nginx security header: {header} - MISSING")
                all_good = False
    
    # Check Dockerfile security
    dockerfiles = ['backend/Dockerfile', 'frontend/Dockerfile']
    for dockerfile in dockerfiles:
        if os.path.exists(dockerfile):
            with open(dockerfile, 'r') as f:
                content = f.read()
            
            if 'USER ' in content and 'USER root' not in content:
                print_success(f"{dockerfile}: Non-root user configured")
            else:
                print_error(f"{dockerfile}: Non-root user not configured")
                all_good = False
    
    return all_good

def main():
    """Main verification function."""
    print_header("Wine Quality Prediction - Docker Setup Verification")
    
    checks = [
        ("Docker Files", check_docker_files),
        ("Dockerfile Content", check_dockerfile_content),
        ("Docker Compose", check_docker_compose),
        ("Makefile Commands", check_makefile),
        ("Environment Template", check_environment_template),
        ("Security Features", check_security_features)
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
        print_success("🎉 ALL DOCKER CHECKS PASSED! Your Docker setup is complete!")
        print("\n🚀 Next steps:")
        print("1. Copy env.docker.example to .env and update values")
        print("2. Install Docker and Docker Compose")
        print("3. Run: make build")
        print("4. Run: make up")
        print("5. Visit: http://localhost:80")
        print("\n🐳 Your Wine Quality Prediction app is ready for containerization!")
    else:
        print_error(f"❌ {total - passed} checks failed. Please fix the issues above.")
        return 1
    
    return 0

if __name__ == "__main__":
    sys.exit(main())

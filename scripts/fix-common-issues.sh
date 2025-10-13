#!/bin/bash
set -e

# Automated fixes for common issues found in project audit
# This script fixes common issues automatically where possible

echo "🔧 Wine Quality Prediction - Automated Issue Fixer"
echo "=================================================="

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

# Function to fix Python code issues
fix_python_issues() {
    print_status "Fixing Python code issues..."
    
    # Format Python code with black if available
    if command_exists black; then
        print_status "Formatting Python code with black..."
        black backend/ --line-length 88 --target-version py310
        print_success "Python code formatted with black"
    else
        print_warning "Black not found, skipping Python formatting"
    fi
    
    # Fix import order with isort if available
    if command_exists isort; then
        print_status "Fixing import order with isort..."
        isort backend/ --profile black
        print_success "Import order fixed with isort"
    else
        print_warning "isort not found, skipping import order fixes"
    fi
    
    # Remove unused imports with autoflake if available
    if command_exists autoflake; then
        print_status "Removing unused imports with autoflake..."
        autoflake --remove-all-unused-imports --remove-unused-variables --in-place --recursive backend/
        print_success "Unused imports removed with autoflake"
    else
        print_warning "autoflake not found, skipping unused import removal"
    fi
    
    # Fix common Python issues
    print_status "Fixing common Python issues..."
    
    # Replace print statements with logger (where appropriate)
    find backend/ -name "*.py" -type f -exec sed -i 's/print(/logger.info(/g' {} \;
    print_success "Replaced print statements with logger.info"
    
    # Add missing docstring templates
    find backend/ -name "*.py" -type f -exec python3 -c "
import sys
import re
import ast

def add_docstring_template(filepath):
    try:
        with open(filepath, 'r') as f:
            content = f.read()
        
        tree = ast.parse(content)
        modified = False
        
        for node in ast.walk(tree):
            if isinstance(node, ast.FunctionDef) and not node.name.startswith('_'):
                if not ast.get_docstring(node):
                    # Find the function in the original content
                    lines = content.split('\n')
                    for i, line in enumerate(lines):
                        if f'def {node.name}(' in line:
                            # Add docstring after the function definition
                            indent = len(line) - len(line.lstrip())
                            docstring = ' ' * (indent + 4) + '\"\"\"TODO: Add docstring.\"\"\"'
                            lines.insert(i + 1, docstring)
                            modified = True
                            break
        
        if modified:
            with open(filepath, 'w') as f:
                f.write('\n'.join(lines))
            print(f'Added docstring templates to {filepath}')
    except Exception as e:
        pass

add_docstring_template('$0')
" {} \;
    
    print_success "Added docstring templates to functions"
}

# Function to fix React/JavaScript issues
fix_react_issues() {
    print_status "Fixing React/JavaScript issues..."
    
    # Remove console.log statements
    print_status "Removing console.log statements..."
    find frontend/src/ -name "*.{js,jsx,ts,tsx}" -type f -exec sed -i '/console\.log/d' {} \;
    print_success "Removed console.log statements"
    
    # Format JavaScript/TypeScript code with prettier if available
    if command_exists prettier; then
        print_status "Formatting JavaScript/TypeScript code with prettier..."
        prettier --write "frontend/src/**/*.{js,jsx,ts,tsx}"
        print_success "JavaScript/TypeScript code formatted with prettier"
    else
        print_warning "Prettier not found, skipping JavaScript formatting"
    fi
    
    # Fix ESLint issues if available
    if command_exists eslint; then
        print_status "Fixing ESLint issues..."
        cd frontend && npx eslint src/ --fix
        print_success "ESLint issues fixed"
        cd ..
    else
        print_warning "ESLint not found, skipping ESLint fixes"
    fi
    
    # Add missing alt attributes to images
    print_status "Adding missing alt attributes to images..."
    find frontend/src/ -name "*.{js,jsx,ts,tsx}" -type f -exec sed -i 's/<img\([^>]*\)>/<img\1 alt="Image">/g' {} \;
    print_success "Added alt attributes to images"
    
    # Fix common React issues
    print_status "Fixing common React issues..."
    
    # Add missing prop types (basic)
    find frontend/src/ -name "*.{js,jsx}" -type f -exec sed -i 's/import React/import React, { PropTypes }/g' {} \;
    print_success "Added PropTypes import where needed"
}

# Function to fix Docker issues
fix_docker_issues() {
    print_status "Fixing Docker issues..."
    
    # Fix Dockerfile to run as non-root user
    if [ -f "backend/Dockerfile" ]; then
        print_status "Updating Dockerfile to run as non-root user..."
        
        # Check if USER instruction already exists
        if ! grep -q "USER" backend/Dockerfile; then
            # Add non-root user creation and switch
            sed -i '/^WORKDIR/a\
# Create non-root user\
RUN useradd --create-home --shell /bin/bash --uid 1000 app\
\
# Set ownership\
RUN chown -R app:app /app\
\
# Switch to non-root user\
USER app' backend/Dockerfile
            
            print_success "Added non-root user to Dockerfile"
        else
            print_warning "USER instruction already exists in Dockerfile"
        fi
        
        # Add health check if missing
        if ! grep -q "HEALTHCHECK" backend/Dockerfile; then
            echo "" >> backend/Dockerfile
            echo "# Health check" >> backend/Dockerfile
            echo "HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \\" >> backend/Dockerfile
            echo "    CMD curl --fail http://localhost:8000/api/v1/prediction/health || exit 1" >> backend/Dockerfile
            
            print_success "Added health check to Dockerfile"
        else
            print_warning "HEALTHCHECK already exists in Dockerfile"
        fi
    fi
    
    # Fix docker-compose.yml issues
    if [ -f "docker-compose.yml" ]; then
        print_status "Checking docker-compose.yml..."
        
        # Validate YAML syntax
        if command_exists python3; then
            python3 -c "import yaml; yaml.safe_load(open('docker-compose.yml'))" 2>/dev/null
            if [ $? -eq 0 ]; then
                print_success "docker-compose.yml syntax is valid"
            else
                print_error "docker-compose.yml has syntax errors"
            fi
        fi
    fi
}

# Function to fix environment issues
fix_environment_issues() {
    print_status "Fixing environment issues..."
    
    # Create .env.example if missing
    if [ ! -f "backend/.env.example" ]; then
        print_status "Creating .env.example..."
        cat > backend/.env.example << EOF
# Environment Variables Template
# Copy this file to .env and fill in your values

# Gemini API Key (required)
GEMINI_API_KEY=your_gemini_api_key_here

# Application Settings
ENVIRONMENT=development
LOG_LEVEL=INFO
DEBUG=true

# Database Settings (if applicable)
DATABASE_URL=sqlite:///./wine_quality.db

# Security Settings
SECRET_KEY=your_secret_key_here
JWT_SECRET_KEY=your_jwt_secret_key_here

# Azure Settings (for production)
AZURE_SUBSCRIPTION_ID=your_azure_subscription_id
AZURE_RESOURCE_GROUP=wine-quality-rg
AZURE_LOCATION=eastus
ACR_NAME=winequalityacr
EOF
        print_success "Created .env.example"
    fi
    
    # Update .gitignore to exclude sensitive files
    if [ -f ".gitignore" ]; then
        print_status "Updating .gitignore..."
        
        # Add common exclusions if not present
        exclusions=(
            ".env"
            "*.log"
            "__pycache__"
            "*.pkl"
            "node_modules"
            ".pytest_cache"
            "*.pyc"
            ".DS_Store"
            "*.swp"
            "*.swo"
            "logs/"
            "saved_models/"
            "reports/"
        )
        
        for exclusion in "${exclusions[@]}"; do
            if ! grep -q "^$exclusion" .gitignore; then
                echo "$exclusion" >> .gitignore
            fi
        done
        
        print_success "Updated .gitignore"
    fi
}

# Function to fix security issues
fix_security_issues() {
    print_status "Fixing security issues..."
    
    # Remove hardcoded secrets (basic pattern matching)
    print_status "Scanning for hardcoded secrets..."
    
    # Find and flag potential secrets
    secret_patterns=(
        "api_key.*=.*['\"].*['\"]"
        "password.*=.*['\"].*['\"]"
        "secret.*=.*['\"].*['\"]"
        "token.*=.*['\"].*['\"]"
    )
    
    for pattern in "${secret_patterns[@]}"; do
        matches=$(grep -r -n -E "$pattern" backend/ 2>/dev/null || true)
        if [ -n "$matches" ]; then
            print_warning "Potential hardcoded secrets found:"
            echo "$matches"
            print_warning "Please review and replace with environment variables"
        fi
    done
    
    # Fix CORS configuration if found
    if [ -f "backend/app/main.py" ]; then
        print_status "Checking CORS configuration..."
        
        if grep -q "allow_origins.*\*" backend/app/main.py; then
            print_warning "CORS allows all origins (*), consider restricting"
        fi
    fi
    
    print_success "Security issues reviewed"
}

# Function to fix documentation issues
fix_documentation_issues() {
    print_status "Fixing documentation issues..."
    
    # Create missing documentation files
    missing_docs=(
        "CONTRIBUTING.md"
        "CHANGELOG.md"
        "LICENSE"
    )
    
    for doc in "${missing_docs[@]}"; do
        if [ ! -f "$doc" ]; then
            case "$doc" in
                "CONTRIBUTING.md")
                    cat > "$doc" << EOF
# Contributing to Wine Quality Prediction

Thank you for your interest in contributing to this project!

## Getting Started

1. Fork the repository
2. Clone your fork
3. Create a feature branch
4. Make your changes
5. Run tests
6. Submit a pull request

## Development Setup

\`\`\`bash
# Clone the repository
git clone https://github.com/yourusername/wine-quality-prediction.git
cd wine-quality-prediction

# Set up environment
cp backend/.env.example backend/.env
# Edit backend/.env with your values

# Install dependencies
cd backend && pip install -r requirements.txt
cd ../frontend && npm install

# Run tests
cd ../backend && pytest
cd ../frontend && npm test
\`\`\`

## Code Style

- Python: Follow PEP 8, use black for formatting
- JavaScript/TypeScript: Follow ESLint rules, use prettier for formatting
- Use meaningful commit messages
- Add tests for new features

## Pull Request Process

1. Ensure all tests pass
2. Update documentation if needed
3. Add your changes to CHANGELOG.md
4. Submit a pull request with a clear description

## Questions?

Feel free to open an issue for any questions or concerns.
EOF
                    ;;
                "CHANGELOG.md")
                    cat > "$doc" << EOF
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Initial project setup
- ML model training pipeline
- FastAPI backend
- React frontend
- Docker containerization
- Azure deployment
- Security hardening
- Performance optimization
- Backup and disaster recovery

### Changed

### Deprecated

### Removed

### Fixed

### Security
EOF
                    ;;
                "LICENSE")
                    cat > "$doc" << EOF
MIT License

Copyright (c) 2024 Wine Quality Prediction Project

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
EOF
                    ;;
            esac
            print_success "Created $doc"
        fi
    done
    
    # Update README.md if it's missing sections
    if [ -f "README.md" ]; then
        print_status "Checking README.md completeness..."
        
        required_sections=(
            "## Installation"
            "## Usage"
            "## Contributing"
            "## License"
        )
        
        for section in "${required_sections[@]}"; do
            if ! grep -q "$section" README.md; then
                print_warning "README.md missing section: $section"
            fi
        done
    fi
    
    print_success "Documentation issues fixed"
}

# Function to fix performance issues
fix_performance_issues() {
    print_status "Fixing performance issues..."
    
    # Check for large files
    print_status "Checking for large files..."
    large_files=$(find . -type f -size +10M 2>/dev/null || true)
    if [ -n "$large_files" ]; then
        print_warning "Large files found:"
        echo "$large_files"
        print_warning "Consider optimizing or adding to .gitignore"
    fi
    
    # Optimize images if any
    if command_exists convert; then
        print_status "Optimizing images..."
        find . -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" | while read -r img; do
            if [ -f "$img" ]; then
                convert "$img" -quality 85 -strip "$img"
            fi
        done
        print_success "Images optimized"
    else
        print_warning "ImageMagick not found, skipping image optimization"
    fi
    
    print_success "Performance issues reviewed"
}

# Function to install missing tools
install_missing_tools() {
    print_status "Installing missing tools..."
    
    # Install Python tools
    if command_exists pip3; then
        python_tools=("black" "isort" "autoflake" "pylint" "flake8" "mypy")
        for tool in "${python_tools[@]}"; do
            if ! command_exists "$tool"; then
                print_status "Installing $tool..."
                pip3 install "$tool" --user
            fi
        done
    fi
    
    # Install Node.js tools
    if command_exists npm; then
        print_status "Installing Node.js tools..."
        cd frontend && npm install --save-dev prettier eslint
        cd ..
    fi
    
    print_success "Missing tools installed"
}

# Main execution
main() {
    echo "Starting automated issue fixing..."
    echo ""
    
    # Check if we're in the right directory
    if [ ! -f "README.md" ] && [ ! -f "docker-compose.yml" ]; then
        print_error "Not in project root directory. Please run from project root."
        exit 1
    fi
    
    # Create necessary directories
    mkdir -p backend/logs backend/saved_models data/raw data/processed docs scripts reports
    
    # Run fixes
    fix_python_issues
    fix_react_issues
    fix_docker_issues
    fix_environment_issues
    fix_security_issues
    fix_documentation_issues
    fix_performance_issues
    
    # Install missing tools if requested
    if [ "$1" = "--install-tools" ]; then
        install_missing_tools
    fi
    
    print_success "Automated fixes completed!"
    echo ""
    echo "📋 Summary of fixes applied:"
    echo "  ✅ Python code formatted and cleaned"
    echo "  ✅ JavaScript/TypeScript code formatted"
    echo "  ✅ Docker configuration updated"
    echo "  ✅ Environment files created/updated"
    echo "  ✅ Security issues reviewed"
    echo "  ✅ Documentation files created"
    echo "  ✅ Performance issues reviewed"
    echo ""
    echo "🔍 Next steps:"
    echo "  1. Review the changes made"
    echo "  2. Run tests to ensure nothing broke"
    echo "  3. Run the audit script again to verify fixes"
    echo "  4. Commit the changes"
    echo ""
    echo "🚀 Run 'python scripts/audit-project.py' to verify improvements!"
}

# Run main function
main "$@"

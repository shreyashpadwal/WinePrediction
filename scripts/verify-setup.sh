#!/bin/bash
# Wine Quality Prediction - Setup Verification Script
# Checks if all prerequisites and dependencies are properly installed

echo "=========================================="
echo "WINE QUALITY PREDICTION - SETUP VERIFICATION"
echo "=========================================="
echo

allChecksPassed=1
totalChecks=0

echo "Starting setup verification..."
echo

# Check Python installation
echo "[1/10] Checking Python installation..."
if command -v python3 &> /dev/null; then
    pythonVersion=$(python3 --version 2>&1 | cut -d' ' -f2)
    echo "  ✓ Python $pythonVersion found"
elif command -v python &> /dev/null; then
    pythonVersion=$(python --version 2>&1 | cut -d' ' -f2)
    echo "  ✓ Python $pythonVersion found"
else
    echo "  ❌ Python not found or not in PATH"
    echo "  ⚠ Please install Python 3.10+ from https://www.python.org/downloads/"
    allChecksPassed=0
fi
((totalChecks++))

# Check pip installation
echo "[2/10] Checking pip installation..."
if command -v pip3 &> /dev/null; then
    echo "  ✓ pip3 is available"
elif command -v pip &> /dev/null; then
    echo "  ✓ pip is available"
else
    echo "  ❌ pip not found"
    echo "  ⚠ Please install pip or run: python -m ensurepip --upgrade"
    allChecksPassed=0
fi
((totalChecks++))

# Check Node.js installation
echo "[3/10] Checking Node.js installation..."
if command -v node &> /dev/null; then
    nodeVersion=$(node --version 2>&1 | cut -d'v' -f2)
    echo "  ✓ Node.js v$nodeVersion found"
else
    echo "  ❌ Node.js not found or not in PATH"
    echo "  ⚠ Please install Node.js 18+ from https://nodejs.org/"
    allChecksPassed=0
fi
((totalChecks++))

# Check npm installation
echo "[4/10] Checking npm installation..."
if command -v npm &> /dev/null; then
    npmVersion=$(npm --version 2>&1)
    echo "  ✓ npm $npmVersion found"
else
    echo "  ❌ npm not found"
    echo "  ⚠ npm should be included with Node.js installation"
    allChecksPassed=0
fi
((totalChecks++))

# Check Docker installation
echo "[5/10] Checking Docker installation..."
if command -v docker &> /dev/null; then
    echo "  ✓ Docker is available"
else
    echo "  ❌ Docker not found or not in PATH"
    echo "  ⚠ Please install Docker from https://www.docker.com/products/docker-desktop/"
    allChecksPassed=0
fi
((totalChecks++))

# Check Docker Compose installation
echo "[6/10] Checking Docker Compose installation..."
if command -v docker-compose &> /dev/null; then
    echo "  ✓ Docker Compose is available"
elif docker compose version &> /dev/null; then
    echo "  ✓ Docker Compose (plugin) is available"
else
    echo "  ❌ Docker Compose not found"
    echo "  ⚠ Docker Compose should be included with Docker installation"
    allChecksPassed=0
fi
((totalChecks++))

# Check Git installation
echo "[7/10] Checking Git installation..."
if command -v git &> /dev/null; then
    gitVersion=$(git --version 2>&1 | cut -d' ' -f3)
    echo "  ✓ Git $gitVersion found"
else
    echo "  ❌ Git not found or not in PATH"
    echo "  ⚠ Please install Git from https://git-scm.com/downloads"
    allChecksPassed=0
fi
((totalChecks++))

# Check project structure
echo "[8/10] Checking project structure..."
if [ ! -d "backend" ]; then
    echo "  ❌ backend directory not found"
    allChecksPassed=0
else
    echo "  ✓ backend directory exists"
fi

if [ ! -d "frontend" ]; then
    echo "  ❌ frontend directory not found"
    allChecksPassed=0
else
    echo "  ✓ frontend directory exists"
fi

if [ ! -f "docker-compose.yml" ]; then
    echo "  ❌ docker-compose.yml not found"
    allChecksPassed=0
else
    echo "  ✓ docker-compose.yml exists"
fi

if [ ! -f "Makefile" ]; then
    echo "  ❌ Makefile not found"
    allChecksPassed=0
else
    echo "  ✓ Makefile exists"
fi
((totalChecks++))

# Check backend requirements
echo "[9/10] Checking backend requirements..."
if [ ! -f "backend/requirements.txt" ]; then
    echo "  ❌ backend/requirements.txt not found"
    allChecksPassed=0
else
    echo "  ✓ backend/requirements.txt exists"
fi

if [ ! -f "backend/env.example" ]; then
    echo "  ❌ backend/env.example not found"
    allChecksPassed=0
else
    echo "  ✓ backend/env.example exists"
fi

if [ ! -d "backend/app" ]; then
    echo "  ❌ backend/app directory not found"
    allChecksPassed=0
else
    echo "  ✓ backend/app directory exists"
fi

if [ ! -d "backend/saved_models" ]; then
    echo "  ⚠ backend/saved_models directory not found (will be created)"
    mkdir -p "backend/saved_models"
    echo "  ✓ Created backend/saved_models directory"
else
    echo "  ✓ backend/saved_models directory exists"
fi
((totalChecks++))

# Check frontend requirements
echo "[10/10] Checking frontend requirements..."
if [ ! -f "frontend/package.json" ]; then
    echo "  ❌ frontend/package.json not found"
    allChecksPassed=0
else
    echo "  ✓ frontend/package.json exists"
fi

if [ ! -f "frontend/env.example" ]; then
    echo "  ❌ frontend/env.example not found"
    allChecksPassed=0
else
    echo "  ✓ frontend/env.example exists"
fi

if [ ! -d "frontend/src" ]; then
    echo "  ❌ frontend/src directory not found"
    allChecksPassed=0
else
    echo "  ✓ frontend/src directory exists"
fi
((totalChecks++))

echo
echo "=========================================="
echo "VERIFICATION SUMMARY"
echo "=========================================="

if [ $allChecksPassed -eq 1 ]; then
    echo "✅ All checks passed! Your system is ready for development."
    echo
    echo "Next steps:"
    echo "1. Copy environment files:"
    echo "   - cp backend/env.example backend/.env"
    echo "   - cp frontend/env.example frontend/.env"
    echo
    echo "2. Set up backend:"
    echo "   - cd backend"
    echo "   - python3 -m venv venv"
    echo "   - source venv/bin/activate"
    echo "   - pip install -r requirements.txt"
    echo
    echo "3. Set up frontend:"
    echo "   - cd frontend"
    echo "   - npm install"
    echo
    echo "4. Train models (if needed):"
    echo "   - Run the Jupyter notebook in notebooks/02_model_training.ipynb"
    echo
    echo "5. Start development:"
    echo "   - Backend: uvicorn app.main:app --reload"
    echo "   - Frontend: npm run dev"
    echo "   - Or use Docker: docker-compose up"
else
    echo "❌ Some checks failed. Please fix the issues above before proceeding."
    echo
    echo "Common solutions:"
    echo "1. Install missing software from the provided links"
    echo "2. Add software to your system PATH"
    echo "3. Restart your terminal after installation"
    echo "4. Ensure you're in the correct project directory"
fi

echo
echo "Verification completed at $(date)"
echo

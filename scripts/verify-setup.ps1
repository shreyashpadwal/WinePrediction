# Wine Quality Prediction - Setup Verification Script (PowerShell)
# Checks if all prerequisites and dependencies are properly installed

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "WINE QUALITY PREDICTION - SETUP VERIFICATION" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

$allChecksPassed = $true
$totalChecks = 0

Write-Host "Starting setup verification..." -ForegroundColor Yellow
Write-Host ""

# Check Python installation
Write-Host "[1/10] Checking Python installation..." -ForegroundColor Yellow
try {
    $pythonVersion = python --version 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✓ Python found: $pythonVersion" -ForegroundColor Green
    } else {
        throw "Python not found"
    }
} catch {
    Write-Host "  ❌ Python not found or not in PATH" -ForegroundColor Red
    Write-Host "  ⚠ Please install Python 3.10+ from https://www.python.org/downloads/" -ForegroundColor Yellow
    $allChecksPassed = $false
}
$totalChecks++

# Check pip installation
Write-Host "[2/10] Checking pip installation..." -ForegroundColor Yellow
try {
    $pipVersion = pip --version 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✓ pip is available" -ForegroundColor Green
    } else {
        throw "pip not found"
    }
} catch {
    Write-Host "  ❌ pip not found" -ForegroundColor Red
    Write-Host "  ⚠ Please install pip or run: python -m ensurepip --upgrade" -ForegroundColor Yellow
    $allChecksPassed = $false
}
$totalChecks++

# Check Node.js installation
Write-Host "[3/10] Checking Node.js installation..." -ForegroundColor Yellow
try {
    $nodeVersion = node --version 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✓ Node.js found: $nodeVersion" -ForegroundColor Green
    } else {
        throw "Node.js not found"
    }
} catch {
    Write-Host "  ❌ Node.js not found or not in PATH" -ForegroundColor Red
    Write-Host "  ⚠ Please install Node.js 18+ from https://nodejs.org/" -ForegroundColor Yellow
    $allChecksPassed = $false
}
$totalChecks++

# Check npm installation
Write-Host "[4/10] Checking npm installation..." -ForegroundColor Yellow
try {
    $npmVersion = npm --version 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✓ npm found: v$npmVersion" -ForegroundColor Green
    } else {
        throw "npm not found"
    }
} catch {
    Write-Host "  ❌ npm not found" -ForegroundColor Red
    Write-Host "  ⚠ npm should be included with Node.js installation" -ForegroundColor Yellow
    $allChecksPassed = $false
}
$totalChecks++

# Check Docker installation
Write-Host "[5/10] Checking Docker installation..." -ForegroundColor Yellow
try {
    $dockerVersion = docker --version 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✓ Docker is available" -ForegroundColor Green
    } else {
        throw "Docker not found"
    }
} catch {
    Write-Host "  ❌ Docker not found or not in PATH" -ForegroundColor Red
    Write-Host "  ⚠ Please install Docker Desktop from https://www.docker.com/products/docker-desktop/" -ForegroundColor Yellow
    $allChecksPassed = $false
}
$totalChecks++

# Check Docker Compose installation
Write-Host "[6/10] Checking Docker Compose installation..." -ForegroundColor Yellow
try {
    $composeVersion = docker-compose --version 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✓ Docker Compose is available" -ForegroundColor Green
    } else {
        throw "Docker Compose not found"
    }
} catch {
    Write-Host "  ❌ Docker Compose not found" -ForegroundColor Red
    Write-Host "  ⚠ Docker Compose should be included with Docker Desktop" -ForegroundColor Yellow
    $allChecksPassed = $false
}
$totalChecks++

# Check Git installation
Write-Host "[7/10] Checking Git installation..." -ForegroundColor Yellow
try {
    $gitVersion = git --version 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✓ Git found: $gitVersion" -ForegroundColor Green
    } else {
        throw "Git not found"
    }
} catch {
    Write-Host "  ❌ Git not found or not in PATH" -ForegroundColor Red
    Write-Host "  ⚠ Please install Git from https://git-scm.com/downloads" -ForegroundColor Yellow
    $allChecksPassed = $false
}
$totalChecks++

# Check project structure
Write-Host "[8/10] Checking project structure..." -ForegroundColor Yellow
if (Test-Path "backend") {
    Write-Host "  ✓ backend directory exists" -ForegroundColor Green
} else {
    Write-Host "  ❌ backend directory not found" -ForegroundColor Red
    $allChecksPassed = $false
}

if (Test-Path "frontend") {
    Write-Host "  ✓ frontend directory exists" -ForegroundColor Green
} else {
    Write-Host "  ❌ frontend directory not found" -ForegroundColor Red
    $allChecksPassed = $false
}

if (Test-Path "docker-compose.yml") {
    Write-Host "  ✓ docker-compose.yml exists" -ForegroundColor Green
} else {
    Write-Host "  ❌ docker-compose.yml not found" -ForegroundColor Red
    $allChecksPassed = $false
}

if (Test-Path "Makefile") {
    Write-Host "  ✓ Makefile exists" -ForegroundColor Green
} else {
    Write-Host "  ❌ Makefile not found" -ForegroundColor Red
    $allChecksPassed = $false
}
$totalChecks++

# Check backend requirements
Write-Host "[9/10] Checking backend requirements..." -ForegroundColor Yellow
if (Test-Path "backend\requirements.txt") {
    Write-Host "  ✓ backend\requirements.txt exists" -ForegroundColor Green
} else {
    Write-Host "  ❌ backend\requirements.txt not found" -ForegroundColor Red
    $allChecksPassed = $false
}

if (Test-Path "backend\env.example") {
    Write-Host "  ✓ backend\env.example exists" -ForegroundColor Green
} else {
    Write-Host "  ❌ backend\env.example not found" -ForegroundColor Red
    $allChecksPassed = $false
}

if (Test-Path "backend\app") {
    Write-Host "  ✓ backend\app directory exists" -ForegroundColor Green
} else {
    Write-Host "  ❌ backend\app directory not found" -ForegroundColor Red
    $allChecksPassed = $false
}

if (Test-Path "backend\saved_models") {
    Write-Host "  ✓ backend\saved_models directory exists" -ForegroundColor Green
} else {
    Write-Host "  ⚠ backend\saved_models directory not found (will be created)" -ForegroundColor Yellow
    New-Item -ItemType Directory -Path "backend\saved_models" -Force | Out-Null
    Write-Host "  ✓ Created backend\saved_models directory" -ForegroundColor Green
}
$totalChecks++

# Check frontend requirements
Write-Host "[10/10] Checking frontend requirements..." -ForegroundColor Yellow
if (Test-Path "frontend\package.json") {
    Write-Host "  ✓ frontend\package.json exists" -ForegroundColor Green
} else {
    Write-Host "  ❌ frontend\package.json not found" -ForegroundColor Red
    $allChecksPassed = $false
}

if (Test-Path "frontend\env.example") {
    Write-Host "  ✓ frontend\env.example exists" -ForegroundColor Green
} else {
    Write-Host "  ❌ frontend\env.example not found" -ForegroundColor Red
    $allChecksPassed = $false
}

if (Test-Path "frontend\src") {
    Write-Host "  ✓ frontend\src directory exists" -ForegroundColor Green
} else {
    Write-Host "  ❌ frontend\src directory not found" -ForegroundColor Red
    $allChecksPassed = $false
}
$totalChecks++

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "VERIFICATION SUMMARY" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

if ($allChecksPassed) {
    Write-Host "✅ All checks passed! Your system is ready for development." -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Yellow
    Write-Host "1. Copy environment files:" -ForegroundColor White
    Write-Host "   - Copy backend\env.example to backend\.env" -ForegroundColor Gray
    Write-Host "   - Copy frontend\env.example to frontend\.env" -ForegroundColor Gray
    Write-Host ""
    Write-Host "2. Set up backend:" -ForegroundColor White
    Write-Host "   - cd backend" -ForegroundColor Gray
    Write-Host "   - python -m venv venv" -ForegroundColor Gray
    Write-Host "   - venv\Scripts\activate" -ForegroundColor Gray
    Write-Host "   - pip install -r requirements.txt" -ForegroundColor Gray
    Write-Host ""
    Write-Host "3. Set up frontend:" -ForegroundColor White
    Write-Host "   - cd frontend" -ForegroundColor Gray
    Write-Host "   - npm install" -ForegroundColor Gray
    Write-Host ""
    Write-Host "4. Train models (if needed):" -ForegroundColor White
    Write-Host "   - Run the Jupyter notebook in notebooks\02_model_training.ipynb" -ForegroundColor Gray
    Write-Host ""
    Write-Host "5. Start development:" -ForegroundColor White
    Write-Host "   - Backend: uvicorn app.main:app --reload" -ForegroundColor Gray
    Write-Host "   - Frontend: npm run dev" -ForegroundColor Gray
    Write-Host "   - Or use Docker: docker-compose up" -ForegroundColor Gray
} else {
    Write-Host "❌ Some checks failed. Please fix the issues above before proceeding." -ForegroundColor Red
    Write-Host ""
    Write-Host "Common solutions:" -ForegroundColor Yellow
    Write-Host "1. Install missing software from the provided links" -ForegroundColor White
    Write-Host "2. Add software to your system PATH" -ForegroundColor White
    Write-Host "3. Restart your terminal/command prompt after installation" -ForegroundColor White
    Write-Host "4. Ensure you are in the correct project directory" -ForegroundColor White
}

Write-Host ""
$currentDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
Write-Host "Verification completed at $currentDate" -ForegroundColor Cyan
Write-Host ""
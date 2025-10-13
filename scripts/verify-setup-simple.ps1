# Wine Quality Prediction - Simple Setup Verification Script
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "WINE QUALITY PREDICTION - SETUP VERIFICATION" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

$allChecksPassed = $true

Write-Host "Starting setup verification..." -ForegroundColor Yellow
Write-Host ""

# Check Python
Write-Host "[1/8] Checking Python..." -ForegroundColor Yellow
python --version 2>$null
if ($LASTEXITCODE -eq 0) {
    Write-Host "  ✓ Python found" -ForegroundColor Green
} else {
    Write-Host "  ❌ Python not found" -ForegroundColor Red
    $allChecksPassed = $false
}

# Check pip
Write-Host "[2/8] Checking pip..." -ForegroundColor Yellow
pip --version 2>$null
if ($LASTEXITCODE -eq 0) {
    Write-Host "  ✓ pip found" -ForegroundColor Green
} else {
    Write-Host "  ❌ pip not found" -ForegroundColor Red
    $allChecksPassed = $false
}

# Check Node.js
Write-Host "[3/8] Checking Node.js..." -ForegroundColor Yellow
node --version 2>$null
if ($LASTEXITCODE -eq 0) {
    Write-Host "  ✓ Node.js found" -ForegroundColor Green
} else {
    Write-Host "  ❌ Node.js not found" -ForegroundColor Red
    $allChecksPassed = $false
}

# Check npm
Write-Host "[4/8] Checking npm..." -ForegroundColor Yellow
npm --version 2>$null
if ($LASTEXITCODE -eq 0) {
    Write-Host "  ✓ npm found" -ForegroundColor Green
} else {
    Write-Host "  ❌ npm not found" -ForegroundColor Red
    $allChecksPassed = $false
}

# Check Docker
Write-Host "[5/8] Checking Docker..." -ForegroundColor Yellow
docker --version 2>$null
if ($LASTEXITCODE -eq 0) {
    Write-Host "  ✓ Docker found" -ForegroundColor Green
} else {
    Write-Host "  ❌ Docker not found" -ForegroundColor Red
    $allChecksPassed = $false
}

# Check Git
Write-Host "[6/8] Checking Git..." -ForegroundColor Yellow
git --version 2>$null
if ($LASTEXITCODE -eq 0) {
    Write-Host "  ✓ Git found" -ForegroundColor Green
} else {
    Write-Host "  ❌ Git not found" -ForegroundColor Red
    $allChecksPassed = $false
}

# Check project structure
Write-Host "[7/8] Checking project structure..." -ForegroundColor Yellow
if (Test-Path "backend") {
    Write-Host "  ✓ backend directory" -ForegroundColor Green
} else {
    Write-Host "  ❌ backend directory missing" -ForegroundColor Red
    $allChecksPassed = $false
}

if (Test-Path "frontend") {
    Write-Host "  ✓ frontend directory" -ForegroundColor Green
} else {
    Write-Host "  ❌ frontend directory missing" -ForegroundColor Red
    $allChecksPassed = $false
}

# Check required files
Write-Host "[8/8] Checking required files..." -ForegroundColor Yellow
if (Test-Path "backend\requirements.txt") {
    Write-Host "  ✓ backend\requirements.txt" -ForegroundColor Green
} else {
    Write-Host "  ❌ backend\requirements.txt missing" -ForegroundColor Red
    $allChecksPassed = $false
}

if (Test-Path "frontend\package.json") {
    Write-Host "  ✓ frontend\package.json" -ForegroundColor Green
} else {
    Write-Host "  ❌ frontend\package.json missing" -ForegroundColor Red
    $allChecksPassed = $false
}

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "VERIFICATION SUMMARY" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

if ($allChecksPassed) {
    Write-Host "✅ All checks passed! System ready for development." -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Yellow
    Write-Host "1. Copy env.example files to .env" -ForegroundColor White
    Write-Host "2. Set up backend: cd backend && python -m venv venv && venv\Scripts\activate && pip install -r requirements.txt" -ForegroundColor White
    Write-Host "3. Set up frontend: cd frontend && npm install" -ForegroundColor White
    Write-Host "4. Start development: uvicorn app.main:app --reload (backend) and npm run dev (frontend)" -ForegroundColor White
} else {
    Write-Host "❌ Some checks failed. Please install missing software." -ForegroundColor Red
    Write-Host ""
    Write-Host "Required software:" -ForegroundColor Yellow
    Write-Host "- Python 3.10+: https://www.python.org/downloads/" -ForegroundColor White
    Write-Host "- Node.js 18+: https://nodejs.org/" -ForegroundColor White
    Write-Host "- Docker Desktop: https://www.docker.com/products/docker-desktop/" -ForegroundColor White
    Write-Host "- Git: https://git-scm.com/downloads" -ForegroundColor White
}

Write-Host ""
Write-Host "Verification completed successfully!" -ForegroundColor Cyan

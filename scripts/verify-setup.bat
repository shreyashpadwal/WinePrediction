@echo off
REM Wine Quality Prediction - Setup Verification Script
REM Checks if all prerequisites and dependencies are properly installed

echo ==========================================
echo WINE QUALITY PREDICTION - SETUP VERIFICATION
echo ==========================================
echo.

set "allChecksPassed=1"
set "totalChecks=0"

echo Starting setup verification...
echo.

REM Check Python installation
echo [1/10] Checking Python installation...
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo   ❌ Python not found or not in PATH
    echo   ⚠ Please install Python 3.10+ from https://www.python.org/downloads/
    set "allChecksPassed=0"
) else (
    for /f "tokens=2" %%i in ('python --version 2^>^&1') do set "pythonVersion=%%i"
    echo   ✓ Python %pythonVersion% found
)
set /a totalChecks+=1

REM Check pip installation
echo [2/10] Checking pip installation...
pip --version >nul 2>&1
if %errorlevel% neq 0 (
    echo   ❌ pip not found
    echo   ⚠ Please install pip or run: python -m ensurepip --upgrade
    set "allChecksPassed=0"
) else (
    echo   ✓ pip is available
)
set /a totalChecks+=1

REM Check Node.js installation
echo [3/10] Checking Node.js installation...
node --version >nul 2>&1
if %errorlevel% neq 0 (
    echo   ❌ Node.js not found or not in PATH
    echo   ⚠ Please install Node.js 18+ from https://nodejs.org/
    set "allChecksPassed=0"
) else (
    for /f "tokens=1" %%i in ('node --version 2^>^&1') do set "nodeVersion=%%i"
    echo   ✓ Node.js %nodeVersion% found
)
set /a totalChecks+=1

REM Check npm installation
echo [4/10] Checking npm installation...
npm --version >nul 2>&1
if %errorlevel% neq 0 (
    echo   ❌ npm not found
    echo   ⚠ npm should be included with Node.js installation
    set "allChecksPassed=0"
) else (
    for /f "tokens=1" %%i in ('npm --version 2^>^&1') do set "npmVersion=%%i"
    echo   ✓ npm %npmVersion% found
)
set /a totalChecks+=1

REM Check Docker installation
echo [5/10] Checking Docker installation...
docker --version >nul 2>&1
if %errorlevel% neq 0 (
    echo   ❌ Docker not found or not in PATH
    echo   ⚠ Please install Docker Desktop from https://www.docker.com/products/docker-desktop/
    set "allChecksPassed=0"
) else (
    echo   ✓ Docker is available
)
set /a totalChecks+=1

REM Check Docker Compose installation
echo [6/10] Checking Docker Compose installation...
docker-compose --version >nul 2>&1
if %errorlevel% neq 0 (
    echo   ❌ Docker Compose not found
    echo   ⚠ Docker Compose should be included with Docker Desktop
    set "allChecksPassed=0"
) else (
    echo   ✓ Docker Compose is available
)
set /a totalChecks+=1

REM Check Git installation
echo [7/10] Checking Git installation...
git --version >nul 2>&1
if %errorlevel% neq 0 (
    echo   ❌ Git not found or not in PATH
    echo   ⚠ Please install Git from https://git-scm.com/downloads
    set "allChecksPassed=0"
) else (
    echo   ✓ Git is available
)
set /a totalChecks+=1

REM Check project structure
echo [8/10] Checking project structure...
if not exist "backend" (
    echo   ❌ backend directory not found
    set "allChecksPassed=0"
) else (
    echo   ✓ backend directory exists
)

if not exist "frontend" (
    echo   ❌ frontend directory not found
    set "allChecksPassed=0"
) else (
    echo   ✓ frontend directory exists
)

if not exist "docker-compose.yml" (
    echo   ❌ docker-compose.yml not found
    set "allChecksPassed=0"
) else (
    echo   ✓ docker-compose.yml exists
)

if not exist "Makefile" (
    echo   ❌ Makefile not found
    set "allChecksPassed=0"
) else (
    echo   ✓ Makefile exists
)
set /a totalChecks+=1

REM Check backend requirements
echo [9/10] Checking backend requirements...
if not exist "backend\requirements.txt" (
    echo   ❌ backend\requirements.txt not found
    set "allChecksPassed=0"
) else (
    echo   ✓ backend\requirements.txt exists
)

if not exist "backend\env.example" (
    echo   ❌ backend\env.example not found
    set "allChecksPassed=0"
) else (
    echo   ✓ backend\env.example exists
)

if not exist "backend\app" (
    echo   ❌ backend\app directory not found
    set "allChecksPassed=0"
) else (
    echo   ✓ backend\app directory exists
)

if not exist "backend\saved_models" (
    echo   ⚠ backend\saved_models directory not found (will be created)
    mkdir "backend\saved_models" 2>nul
    echo   ✓ Created backend\saved_models directory
) else (
    echo   ✓ backend\saved_models directory exists
)
set /a totalChecks+=1

REM Check frontend requirements
echo [10/10] Checking frontend requirements...
if not exist "frontend\package.json" (
    echo   ❌ frontend\package.json not found
    set "allChecksPassed=0"
) else (
    echo   ✓ frontend\package.json exists
)

if not exist "frontend\env.example" (
    echo   ❌ frontend\env.example not found
    set "allChecksPassed=0"
) else (
    echo   ✓ frontend\env.example exists
)

if not exist "frontend\src" (
    echo   ❌ frontend\src directory not found
    set "allChecksPassed=0"
) else (
    echo   ✓ frontend\src directory exists
)
set /a totalChecks+=1

echo.
echo ==========================================
echo VERIFICATION SUMMARY
echo ==========================================

if %allChecksPassed% equ 1 (
    echo ✅ All checks passed! Your system is ready for development.
    echo.
    echo Next steps:
    echo 1. Copy environment files:
    echo    - Copy backend\env.example to backend\.env
    echo    - Copy frontend\env.example to frontend\.env
    echo.
    echo 2. Set up backend:
    echo    - cd backend
    echo    - python -m venv venv
    echo    - venv\Scripts\activate
    echo    - pip install -r requirements.txt
    echo.
    echo 3. Set up frontend:
    echo    - cd frontend
    echo    - npm install
    echo.
    echo 4. Train models (if needed):
    echo    - Run the Jupyter notebook in notebooks\02_model_training.ipynb
    echo.
    echo 5. Start development:
    echo    - Backend: uvicorn app.main:app --reload
    echo    - Frontend: npm run dev
    echo    - Or use Docker: docker-compose up
) else (
    echo ❌ Some checks failed. Please fix the issues above before proceeding.
    echo.
    echo Common solutions:
    echo 1. Install missing software from the provided links
    echo 2. Add software to your system PATH
    echo 3. Restart your terminal/command prompt after installation
    echo 4. Ensure you're in the correct project directory
)

echo.
echo Verification completed at %date% %time%
echo.
pause

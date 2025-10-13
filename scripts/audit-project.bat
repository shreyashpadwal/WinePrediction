@echo off
REM Wine Quality Prediction - Project Audit Script (Windows Batch)
REM Comprehensive project audit and error detection system

echo 🍷 Wine Quality Prediction - Project Audit
echo ==========================================

REM Check if Python is available
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Python not found. Please install Python 3.8+ and add to PATH.
    echo Download from: https://www.python.org/downloads/
    pause
    exit /b 1
)

REM Check if we're in the right directory
if not exist "README.md" (
    if not exist "docker-compose.yml" (
        echo ❌ Not in project root directory. Please run from project root.
        pause
        exit /b 1
    )
)

REM Create reports directory
if not exist "reports" mkdir reports

echo 📁 Checking file structure...
set issues=0

REM Check required directories
for %%d in (backend\app backend\saved_models backend\logs frontend\src frontend\public data\raw data\processed notebooks docs scripts) do (
    if not exist "%%d" (
        echo ❌ Missing directory: %%d
        set /a issues+=1
    ) else (
        echo ✅ Directory exists: %%d
    )
)

REM Check required files
for %%f in (backend\app\main.py backend\requirements.txt backend\Dockerfile backend\.env.example frontend\package.json frontend\vite.config.ts frontend\Dockerfile docker-compose.yml README.md .gitignore) do (
    if not exist "%%f" (
        echo ❌ Missing file: %%f
        set /a issues+=1
    ) else (
        echo ✅ File exists: %%f
    )
)

echo.
echo 🔍 Checking Python code...
for /r backend %%f in (*.py) do (
    echo Checking: %%f
    python -m py_compile "%%f" >nul 2>&1
    if %errorlevel% neq 0 (
        echo ❌ Syntax error in: %%f
        set /a issues+=1
    ) else (
        echo ✅ Syntax OK: %%f
    )
)

echo.
echo ⚛️  Checking React code...
if exist "frontend\src" (
    for /r frontend\src %%f in (*.js *.jsx *.ts *.tsx) do (
        echo Checking: %%f
        REM Basic check for console.log
        findstr /i "console\.log" "%%f" >nul 2>&1
        if %errorlevel% equ 0 (
            echo ⚠️  Console.log found in: %%f
        ) else (
            echo ✅ No console.log in: %%f
        )
    )
) else (
    echo ❌ Frontend src directory not found
    set /a issues+=1
)

echo.
echo 🐳 Checking Docker configuration...
if exist "backend\Dockerfile" (
    echo ✅ Backend Dockerfile exists
    findstr /i "USER root" "backend\Dockerfile" >nul 2>&1
    if %errorlevel% equ 0 (
        echo ⚠️  Dockerfile runs as root user
    ) else (
        echo ✅ Dockerfile uses non-root user
    )
) else (
    echo ❌ Backend Dockerfile missing
    set /a issues+=1
)

if exist "docker-compose.yml" (
    echo ✅ Docker Compose file exists
) else (
    echo ❌ Docker Compose file missing
    set /a issues+=1
)

echo.
echo 📦 Checking dependencies...
if exist "backend\requirements.txt" (
    echo ✅ Python requirements file exists
) else (
    echo ❌ Python requirements file missing
    set /a issues+=1
)

if exist "frontend\package.json" (
    echo ✅ Node.js package file exists
) else (
    echo ❌ Node.js package file missing
    set /a issues+=1
)

echo.
echo 🌍 Checking environment variables...
if exist "backend\.env.example" (
    echo ✅ Environment example file exists
) else (
    echo ❌ Environment example file missing
    set /a issues+=1
)

if exist "backend\.env" (
    echo ⚠️  .env file exists (check if committed to git)
) else (
    echo ⚠️  .env file missing (create from .env.example)
)

echo.
echo 🤖 Checking ML models...
if exist "backend\saved_models" (
    echo ✅ Models directory exists
    if exist "backend\saved_models\*.pkl" (
        echo ✅ Model files exist
    ) else (
        echo ❌ No model files found
        set /a issues+=1
    )
) else (
    echo ❌ Models directory missing
    set /a issues+=1
)

echo.
echo 🔒 Checking security...
REM Check for hardcoded secrets
for /r backend %%f in (*.py) do (
    findstr /i "api_key.*=.*[\"'][^\"']*[\"']" "%%f" >nul 2>&1
    if %errorlevel% equ 0 (
        echo ❌ Potential hardcoded API key in: %%f
        set /a issues+=1
    )
    
    findstr /i "password.*=.*[\"'][^\"']*[\"']" "%%f" >nul 2>&1
    if %errorlevel% equ 0 (
        echo ❌ Potential hardcoded password in: %%f
        set /a issues+=1
    )
)

REM Check .gitignore
if exist ".gitignore" (
    findstr /i ".env" ".gitignore" >nul 2>&1
    if %errorlevel% neq 0 (
        echo ⚠️  .env not in .gitignore
    ) else (
        echo ✅ .env in .gitignore
    )
) else (
    echo ❌ .gitignore missing
    set /a issues+=1
)

echo.
echo 📚 Checking documentation...
for %%f in (README.md SECURITY.md PERFORMANCE.md BACKUP_DISASTER_RECOVERY.md DOCKER.md) do (
    if exist "%%f" (
        echo ✅ Documentation exists: %%f
    ) else (
        echo ⚠️  Documentation missing: %%f
    )
)

echo.
echo ==========================================
echo 📊 AUDIT SUMMARY
echo ==========================================
echo Total Issues Found: %issues%

if %issues% equ 0 (
    echo 🟢 OVERALL: EXCELLENT ✅
    echo Health Score: 100/100
) else if %issues% leq 3 (
    echo 🟡 OVERALL: GOOD ⚠️
    echo Health Score: 85/100
) else if %issues% leq 7 (
    echo 🟠 OVERALL: FAIR ⚠️
    echo Health Score: 70/100
) else (
    echo 🔴 OVERALL: NEEDS IMPROVEMENT ❌
    echo Health Score: 50/100
)

echo.
echo 🎯 RECOMMENDATIONS:
if %issues% gtr 0 (
    echo 1. Fix missing files and directories
    echo 2. Remove console.log statements from frontend
    echo 3. Fix Python syntax errors
    echo 4. Add missing documentation
    echo 5. Run 'make fix' to auto-fix common issues
) else (
    echo ✅ No issues found! Project is in excellent condition.
)

echo.
echo 📝 Next Steps:
echo 1. Review the issues above
echo 2. Run 'make fix' to auto-fix common issues
echo 3. Run 'make test' to verify everything works
echo 4. Run 'make audit' for comprehensive analysis

echo.
echo Report saved to: reports\audit-%date:~-4,4%-%date:~-10,2%-%date:~-7,2%.txt
echo %date% %time% > reports\audit-%date:~-4,4%-%date:~-10,2%-%date:~-7,2%.txt
echo Total Issues: %issues% >> reports\audit-%date:~-4,4%-%date:~-10,2%-%date:~-7,2%.txt

pause

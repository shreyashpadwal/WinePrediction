@echo off
REM Quick Health Check Script for Wine Quality Prediction Project
REM Performs basic checks to verify system health

echo ==========================================
echo WINE QUALITY PREDICTION - QUICK HEALTH CHECK
echo ==========================================
echo.

set "score=0"
set "maxScore=7"
set "issues=0"

echo Starting quick health check...
echo.

REM Check if Docker is running
echo [1/7] Checking Docker services...
docker --version >nul 2>&1
if %errorlevel% neq 0 (
    echo   ❌ Docker not installed or not running
    set /a issues+=1
) else (
    echo   ✓ Docker is available
    set /a score+=1
)

REM Check if containers are running
echo [2/7] Checking container status...
docker-compose ps >nul 2>&1
if %errorlevel% neq 0 (
    echo   ⚠ Docker Compose not available or no containers running
    echo   ⚠ Run 'docker-compose up -d' to start services
) else (
    echo   ✓ Docker Compose is available
    set /a score+=1
)

REM Test backend health endpoint
echo [3/7] Testing backend health...
curl -s -o nul -w "%%{http_code}" http://localhost:8000/api/v1/health 2>nul | findstr "200" >nul
if %errorlevel% neq 0 (
    echo   ❌ Backend health check failed
    echo   ⚠ Backend may not be running on port 8000
    set /a issues+=1
) else (
    echo   ✓ Backend health check passed
    set /a score+=1
)

REM Test frontend accessibility
echo [4/7] Testing frontend accessibility...
curl -s -o nul -w "%%{http_code}" http://localhost:80 2>nul | findstr "200" >nul
if %errorlevel% neq 0 (
    echo   ❌ Frontend not accessible
    echo   ⚠ Frontend may not be running on port 80
    set /a issues+=1
) else (
    echo   ✓ Frontend is accessible
    set /a score+=1
)

REM Test prediction endpoint
echo [5/7] Testing prediction endpoint...
echo Testing with sample wine data...
curl -s -X POST "http://localhost:8000/api/v1/predict" ^
     -H "Content-Type: application/json" ^
     -d "{\"fixed_acidity\":7.4,\"volatile_acidity\":0.7,\"citric_acid\":0.0,\"residual_sugar\":1.9,\"chlorides\":0.076,\"free_sulfur_dioxide\":11.0,\"total_sulfur_dioxide\":34.0,\"density\":0.9978,\"pH\":3.51,\"sulphates\":0.56,\"alcohol\":9.4}" ^
     -o temp_response.json 2>nul
if %errorlevel% neq 0 (
    echo   ❌ Prediction endpoint test failed
    set /a issues+=1
) else (
    findstr "prediction" temp_response.json >nul 2>&1
    if !errorlevel! equ 0 (
        echo   ✓ Prediction endpoint working
        set /a score+=1
    ) else (
        echo   ⚠ Prediction endpoint responded but format unexpected
    )
    del temp_response.json 2>nul
)

REM Check for critical errors in logs
echo [6/7] Checking for critical errors...
if exist "logs\error.log" (
    findstr /i "CRITICAL\|ERROR" "logs\error.log" >nul 2>&1
    if !errorlevel! equ 0 (
        echo   ⚠ Critical errors found in logs
        echo   ⚠ Review logs\error.log for details
    ) else (
        echo   ✓ No critical errors in logs
        set /a score+=1
    )
) else (
    echo   ⚠ No error log file found
    echo   ⚠ Consider setting up logging
)

REM Check file integrity
echo [7/7] Checking file integrity...
set "fileIssues=0"

REM Check if model files exist
if not exist "backend\saved_models\*.pkl" (
    echo   ⚠ No model files found
    set /a fileIssues+=1
) else (
    echo   ✓ Model files exist
)

REM Check if .env file exists
if not exist "backend\.env" (
    echo   ⚠ .env file missing
    set /a fileIssues+=1
) else (
    echo   ✓ .env file exists
)

REM Check if .env is committed to git
if exist ".git" (
    git check-ignore "backend\.env" >nul 2>&1
    if !errorlevel! neq 0 (
        echo   ⚠ .env file may be committed to git
        set /a fileIssues+=1
    ) else (
        echo   ✓ .env file properly ignored
    )
)

if %fileIssues% equ 0 (
    set /a score+=1
) else (
    set /a issues+=%fileIssues%
)

echo.
echo ==========================================
echo HEALTH CHECK SUMMARY
echo ==========================================

set /a healthPercentage=(%score% * 100) / %maxScore%

echo Score: %score%/%maxScore% (%healthPercentage%%%)
echo Issues found: %issues%

if %healthPercentage% geq 90 (
    echo.
    echo 🟢 OVERALL: EXCELLENT ✅
    echo All systems are running perfectly!
) else if %healthPercentage% geq 80 (
    echo.
    echo 🟡 OVERALL: GOOD ⚠️
    echo Most systems are working well with minor issues.
) else if %healthPercentage% geq 70 (
    echo.
    echo 🟠 OVERALL: FAIR ⚠️
    echo Some systems need attention.
) else (
    echo.
    echo 🔴 OVERALL: NEEDS IMPROVEMENT ❌
    echo Multiple issues detected that need immediate attention.
)

echo.
if %issues% gtr 0 (
    echo Issues to address:
    echo 1. Check Docker container status
    echo 2. Verify backend is running on port 8000
    echo 3. Verify frontend is running on port 80
    echo 4. Review error logs for critical issues
    echo 5. Ensure model files are present
    echo 6. Verify .env file configuration
    echo.
    echo Run 'make fix' to auto-fix common issues
    echo Run 'make audit' for comprehensive analysis
) else (
    echo ✅ No issues detected! System is healthy.
)

echo.
echo Health check completed at %date% %time%
echo.
pause
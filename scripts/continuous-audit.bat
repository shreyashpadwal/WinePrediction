@echo off
REM Continuous Audit Script for Wine Quality Prediction Project
REM Runs daily audits and compares with previous runs

echo ==========================================
echo WINE QUALITY PREDICTION - CONTINUOUS AUDIT
echo ==========================================
echo.

set "currentDate=%date:~-4,4%-%date:~-10,2%-%date:~-7,2%"
set "auditDir=reports\continuous"
set "currentReport=%auditDir%\audit-%currentDate%.txt"
set "previousReport="

REM Create continuous audit directory
if not exist "%auditDir%" (
    mkdir "%auditDir%"
    echo Created continuous audit directory: %auditDir%
)

echo Starting continuous audit for %currentDate%...
echo.

REM Find the most recent previous audit report
for /f "delims=" %%i in ('dir /b /o-d "%auditDir%\audit-*.txt" 2^>nul') do (
    if not defined previousReport (
        set "previousReport=%auditDir%\%%i"
        goto :found_previous
    )
)

:found_previous
if defined previousReport (
    echo Previous audit found: %previousReport%
) else (
    echo No previous audit found - this is the first run
)

echo.

REM Run the audit and capture output
echo Running comprehensive audit...
powershell -ExecutionPolicy Bypass -File scripts\simple-audit.ps1 > "%currentReport%" 2>&1

if %errorlevel% neq 0 (
    echo ❌ Audit failed with error code: %errorlevel%
    echo Check the audit script for issues
    goto :end
)

echo ✓ Audit completed successfully
echo.

REM Extract key metrics from current report
for /f "tokens=*" %%a in ('findstr "Total Issues Found:" "%currentReport%"') do (
    for /f "tokens=4" %%b in ("%%a") do set "currentIssues=%%b"
)

for /f "tokens=*" %%a in ('findstr "Health Score:" "%currentReport%"') do (
    for /f "tokens=3" %%b in ("%%a") do (
        for /f "tokens=1 delims=/" %%c in ("%%b") do set "currentScore=%%c"
    )
)

echo Current audit results:
echo - Issues found: %currentIssues%
echo - Health score: %currentScore%/100
echo.

REM Compare with previous audit if available
if defined previousReport (
    echo Comparing with previous audit...
    
    REM Extract previous metrics
    for /f "tokens=*" %%a in ('findstr "Total Issues Found:" "%previousReport%"') do (
        for /f "tokens=4" %%b in ("%%a") do set "previousIssues=%%b"
    )
    
    for /f "tokens=*" %%a in ('findstr "Health Score:" "%previousReport%"') do (
        for /f "tokens=3" %%b in ("%%a") do (
            for /f "tokens=1 delims=/" %%c in ("%%b") do set "previousScore=%%c"
        )
    )
    
    if defined previousIssues (
        echo Previous audit results:
        echo - Issues found: %previousIssues%
        echo - Health score: %previousScore%/100
        echo.
        
        REM Calculate changes
        set /a issueChange=%currentIssues%-%previousIssues%
        set /a scoreChange=%currentScore%-%previousScore%
        
        echo Changes since last audit:
        if %issueChange% gtr 0 (
            echo ⚠ Issues increased by %issueChange%
        ) else if %issueChange% lss 0 (
            echo ✓ Issues decreased by %issueChange%
        ) else (
            echo → Issues unchanged
        )
        
        if %scoreChange% gtr 0 (
            echo ✓ Health score improved by %scoreChange%
        ) else if %scoreChange% lss 0 (
            echo ⚠ Health score decreased by %scoreChange%
        ) else (
            echo → Health score unchanged
        )
        
        REM Check for critical issues
        if %currentIssues% gtr 5 (
            echo.
            echo 🚨 ALERT: High number of issues detected (%currentIssues%)
            echo Consider running 'make fix' to address common issues
        )
        
        if %currentScore% lss 70 (
            echo.
            echo 🚨 ALERT: Low health score detected (%currentScore%)
            echo Immediate attention required
        )
        
    ) else (
        echo ⚠ Could not extract metrics from previous report
    )
) else (
    echo This is the first audit - no comparison available
)

echo.

REM Generate summary report
set "summaryReport=%auditDir%\summary-%currentDate%.txt"
(
    echo Wine Quality Prediction - Continuous Audit Summary
    echo ================================================
    echo Date: %currentDate%
    echo Time: %time%
    echo.
    echo Current Status:
    echo - Issues found: %currentIssues%
    echo - Health score: %currentScore%/100
    echo.
    if defined previousReport (
        echo Comparison with previous audit:
        echo - Issue change: %issueChange%
        echo - Score change: %scoreChange%
        echo.
    )
    echo Overall Status: 
    if %currentScore% geq 90 (
        echo EXCELLENT - All systems running perfectly
    ) else if %currentScore% geq 80 (
        echo GOOD - Minor issues detected
    ) else if %currentScore% geq 70 (
        echo FAIR - Some attention needed
    ) else (
        echo NEEDS IMPROVEMENT - Multiple issues detected
    )
    echo.
    echo Next Steps:
    if %currentIssues% gtr 0 (
        echo 1. Run 'make fix' to auto-fix common issues
        echo 2. Review detailed report: %currentReport%
        echo 3. Address remaining issues manually
    ) else (
        echo 1. Continue monitoring
        echo 2. Schedule next audit
    )
    echo.
    echo Full report available at: %currentReport%
) > "%summaryReport%"

echo Summary report saved: %summaryReport%

REM Clean up old reports (keep last 30 days)
echo.
echo Cleaning up old reports...
forfiles /p "%auditDir%" /m "audit-*.txt" /d -30 /c "cmd /c del @path" 2>nul
forfiles /p "%auditDir%" /m "summary-*.txt" /d -30 /c "cmd /c del @path" 2>nul
echo ✓ Old reports cleaned up

REM Schedule next audit (Windows Task Scheduler)
echo.
echo Scheduling next audit...
schtasks /create /tn "WinePredictionAudit" /tr "%~dp0continuous-audit.bat" /sc daily /st 09:00 /f >nul 2>&1
if %errorlevel% equ 0 (
    echo ✓ Next audit scheduled for daily at 9:00 AM
) else (
    echo ⚠ Could not schedule next audit automatically
    echo Manual scheduling required or run this script daily
)

REM Email notification (if configured)
if defined EMAIL_RECIPIENT (
    echo.
    echo Sending email notification...
    powershell -Command "Send-MailMessage -To '%EMAIL_RECIPIENT%' -Subject 'Wine Prediction Audit Report - %currentDate%' -Body 'Health Score: %currentScore%/100, Issues: %currentIssues%' -SmtpServer '%SMTP_SERVER%' -Port 587 -UseSsl -Credential (Get-Credential)" 2>nul
    if %errorlevel% equ 0 (
        echo ✓ Email notification sent
    ) else (
        echo ⚠ Email notification failed
    )
)

:end
echo.
echo ==========================================
echo CONTINUOUS AUDIT COMPLETED
echo ==========================================
echo.
echo Reports generated:
echo - Detailed report: %currentReport%
echo - Summary report: %summaryReport%
echo.
echo Next audit scheduled for tomorrow at 9:00 AM
echo.
echo To view reports:
echo - Open: %currentReport%
echo - Or run: type "%currentReport%"
echo.
pause

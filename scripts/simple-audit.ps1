# Simple Project Audit Script for Windows
# Wine Quality Prediction Project

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "WINE QUALITY PREDICTION - PROJECT AUDIT" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

$issues = 0
$totalFiles = 0
$totalLines = 0

# Check file structure
Write-Host "Checking file structure..." -ForegroundColor Yellow

$requiredDirs = @("backend", "frontend", "scripts", "docs", "logs")
foreach ($dir in $requiredDirs) {
    if (Test-Path $dir) {
        Write-Host "OK: Directory exists: $dir" -ForegroundColor Green
    } else {
        Write-Host "ERROR: Missing directory: $dir" -ForegroundColor Red
        $issues++
    }
}

# Check critical files
$criticalFiles = @(
    "backend\main.py",
    "backend\requirements.txt",
    "frontend\package.json",
    "docker-compose.yml",
    "README.md"
)

foreach ($file in $criticalFiles) {
    if (Test-Path $file) {
        Write-Host "OK: File exists: $file" -ForegroundColor Green
        $totalFiles++
        $content = Get-Content $file -ErrorAction SilentlyContinue
        if ($content) {
            $totalLines += $content.Count
        }
    } else {
        Write-Host "ERROR: Missing file: $file" -ForegroundColor Red
        $issues++
    }
}

Write-Host ""
Write-Host "Checking Python files..." -ForegroundColor Yellow

# Check Python files
$pythonFiles = Get-ChildItem -Path "backend" -Filter "*.py" -Recurse -ErrorAction SilentlyContinue
foreach ($file in $pythonFiles) {
    $totalFiles++
    $content = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
    if ($content) {
        $totalLines += ($content -split "`n").Count
        
        # Check for issues
        if ($content -match "print\s*\(") {
            Write-Host "WARNING: Print statement in: $($file.Name)" -ForegroundColor Yellow
        }
        
        if ($content -match "(api_key|password|secret|token)\s*=\s*['`"][^'`"]+['`"]") {
            Write-Host "ERROR: Potential hardcoded secret in: $($file.Name)" -ForegroundColor Red
            $issues++
        }
    }
}

Write-Host ""
Write-Host "Checking React files..." -ForegroundColor Yellow

# Check React files
$reactFiles = Get-ChildItem -Path "frontend\src" -Filter "*.{js,jsx,ts,tsx}" -Recurse -ErrorAction SilentlyContinue
foreach ($file in $reactFiles) {
    $totalFiles++
    $content = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
    if ($content) {
        $totalLines += ($content -split "`n").Count
        
        # Check for console.log
        if ($content -match "console\.log") {
            Write-Host "WARNING: Console.log in: $($file.Name)" -ForegroundColor Yellow
        }
        
        # Check for hardcoded URLs
        if ($content -match "http[s]?://[^'`"]+['`"]" -and $content -notmatch "localhost") {
            Write-Host "WARNING: Hardcoded URL in: $($file.Name)" -ForegroundColor Yellow
        }
    }
}

Write-Host ""
Write-Host "Checking Docker configuration..." -ForegroundColor Yellow

# Check Docker files
if (Test-Path "backend\Dockerfile") {
    Write-Host "OK: Backend Dockerfile exists" -ForegroundColor Green
    $dockerContent = Get-Content "backend\Dockerfile" -Raw -ErrorAction SilentlyContinue
    if ($dockerContent -match "USER\s+root") {
        Write-Host "WARNING: Dockerfile runs as root user" -ForegroundColor Yellow
    } else {
        Write-Host "OK: Dockerfile uses non-root user" -ForegroundColor Green
    }
} else {
    Write-Host "ERROR: Backend Dockerfile missing" -ForegroundColor Red
    $issues++
}

if (Test-Path "docker-compose.yml") {
    Write-Host "OK: Docker Compose file exists" -ForegroundColor Green
} else {
    Write-Host "ERROR: Docker Compose file missing" -ForegroundColor Red
    $issues++
}

Write-Host ""
Write-Host "Checking dependencies..." -ForegroundColor Yellow

# Check Python dependencies
if (Test-Path "backend\requirements.txt") {
    Write-Host "OK: Python requirements file exists" -ForegroundColor Green
} else {
    Write-Host "ERROR: Python requirements file missing" -ForegroundColor Red
    $issues++
}

# Check Node.js dependencies
if (Test-Path "frontend\package.json") {
    Write-Host "OK: Node.js package file exists" -ForegroundColor Green
} else {
    Write-Host "ERROR: Node.js package file missing" -ForegroundColor Red
    $issues++
}

Write-Host ""
Write-Host "Checking environment variables..." -ForegroundColor Yellow

# Check environment files
if (Test-Path "backend\.env.example") {
    Write-Host "OK: Environment example file exists" -ForegroundColor Green
} else {
    Write-Host "ERROR: Environment example file missing" -ForegroundColor Red
    $issues++
}

if (Test-Path "backend\.env") {
    Write-Host "WARNING: .env file exists (check if committed to git)" -ForegroundColor Yellow
} else {
    Write-Host "INFO: .env file missing (create from .env.example)" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "Checking ML models..." -ForegroundColor Yellow

# Check models directory
if (Test-Path "backend\saved_models") {
    Write-Host "OK: Models directory exists" -ForegroundColor Green
    $modelFiles = Get-ChildItem "backend\saved_models" -Filter "*.pkl" -ErrorAction SilentlyContinue
    if ($modelFiles) {
        Write-Host "OK: Model files exist ($($modelFiles.Count) files)" -ForegroundColor Green
    } else {
        Write-Host "ERROR: No model files found" -ForegroundColor Red
        $issues++
    }
} else {
    Write-Host "ERROR: Models directory missing" -ForegroundColor Red
    $issues++
}

Write-Host ""
Write-Host "Checking security..." -ForegroundColor Yellow

# Check .gitignore
if (Test-Path ".gitignore") {
    $gitignoreContent = Get-Content ".gitignore" -Raw -ErrorAction SilentlyContinue
    $requiredIgnores = @(".env", "*.log", "__pycache__", "*.pkl")
    foreach ($ignore in $requiredIgnores) {
        if ($gitignoreContent -match [regex]::Escape($ignore)) {
            Write-Host "OK: $ignore in .gitignore" -ForegroundColor Green
        } else {
            Write-Host "WARNING: $ignore not in .gitignore" -ForegroundColor Yellow
        }
    }
} else {
    Write-Host "ERROR: .gitignore missing" -ForegroundColor Red
    $issues++
}

Write-Host ""
Write-Host "Checking documentation..." -ForegroundColor Yellow

# Check documentation files
$docFiles = @("README.md", "SECURITY.md", "PERFORMANCE.md", "BACKUP_DISASTER_RECOVERY.md", "DOCKER.md")
foreach ($doc in $docFiles) {
    if (Test-Path $doc) {
        Write-Host "OK: Documentation exists: $doc" -ForegroundColor Green
    } else {
        Write-Host "WARNING: Documentation missing: $doc" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "Checking tests..." -ForegroundColor Yellow

# Check test directories
if (Test-Path "backend\tests") {
    $testFiles = Get-ChildItem "backend\tests" -Filter "*.py" -ErrorAction SilentlyContinue
    Write-Host "OK: Backend tests directory exists ($($testFiles.Count) test files)" -ForegroundColor Green
} else {
    Write-Host "WARNING: Backend tests directory missing" -ForegroundColor Yellow
}

if (Test-Path "frontend\src\__tests__") {
    $frontendTests = Get-ChildItem "frontend\src\__tests__" -Filter "*.{js,jsx,ts,tsx}" -ErrorAction SilentlyContinue
    Write-Host "OK: Frontend tests directory exists ($($frontendTests.Count) test files)" -ForegroundColor Green
} else {
    Write-Host "WARNING: Frontend tests directory missing" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "AUDIT SUMMARY" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

$healthScore = [math]::Max(0, 100 - ($issues * 10))

Write-Host "Total Files Scanned: $totalFiles"
Write-Host "Total Lines of Code: $totalLines"
Write-Host "Total Issues Found: $issues"
Write-Host "Health Score: $healthScore/100"

if ($healthScore -ge 90) {
    Write-Host "OVERALL: EXCELLENT" -ForegroundColor Green
} elseif ($healthScore -ge 80) {
    Write-Host "OVERALL: GOOD" -ForegroundColor Yellow
} elseif ($healthScore -ge 70) {
    Write-Host "OVERALL: FAIR" -ForegroundColor DarkYellow
} else {
    Write-Host "OVERALL: NEEDS IMPROVEMENT" -ForegroundColor Red
}

Write-Host ""
Write-Host "RECOMMENDATIONS:" -ForegroundColor Yellow
if ($issues -gt 0) {
    Write-Host "1. Fix missing files and directories"
    Write-Host "2. Remove console.log statements from frontend"
    Write-Host "3. Fix Python syntax errors"
    Write-Host "4. Add missing documentation"
    Write-Host "5. Run make fix to auto-fix common issues"
} else {
    Write-Host "No issues found! Project is in excellent condition." -ForegroundColor Green
}

Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host "1. Review the issues above"
Write-Host "2. Run make fix to auto-fix common issues"
Write-Host "3. Run make test to verify everything works"
Write-Host "4. Run make audit for comprehensive analysis"

# Save report
$dateStr = Get-Date -Format "yyyy-MM-dd"
$reportFile = "reports\audit-$dateStr.txt"

# Create reports directory if it doesn't exist
if (-not (Test-Path "reports")) {
    New-Item -ItemType Directory -Path "reports" -Force | Out-Null
}

$reportContent = @"
Wine Quality Prediction - Audit Report
Generated: $(Get-Date)
Total Files Scanned: $totalFiles
Total Lines of Code: $totalLines
Total Issues Found: $issues
Health Score: $healthScore/100
Overall Status: $(if ($healthScore -ge 90) { "EXCELLENT" } elseif ($healthScore -ge 80) { "GOOD" } elseif ($healthScore -ge 70) { "FAIR" } else { "NEEDS IMPROVEMENT" })
"@

$reportContent | Out-File -FilePath $reportFile -Encoding UTF8
Write-Host ""
Write-Host "Report saved to: $reportFile" -ForegroundColor Cyan

Write-Host ""
Write-Host "Audit completed successfully!" -ForegroundColor Green

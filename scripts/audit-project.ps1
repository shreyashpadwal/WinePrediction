# Wine Quality Prediction - Project Audit Script (PowerShell)
# Comprehensive project audit and error detection system

Write-Host "🍷 Wine Quality Prediction - Project Audit" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

# Check if we're in the right directory
if (-not (Test-Path "README.md") -and -not (Test-Path "docker-compose.yml")) {
    Write-Host "❌ Not in project root directory. Please run from project root." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

# Create reports directory
if (-not (Test-Path "reports")) {
    New-Item -ItemType Directory -Path "reports" | Out-Null
}

$issues = 0
$totalFiles = 0
$totalLines = 0

Write-Host ""
Write-Host "📁 Checking file structure..." -ForegroundColor Yellow

# Check required directories
$requiredDirs = @(
    "backend\app", "backend\saved_models", "backend\logs",
    "frontend\src", "frontend\public",
    "data\raw", "data\processed",
    "notebooks", "docs", "scripts"
)

foreach ($dir in $requiredDirs) {
    if (Test-Path $dir) {
        Write-Host "✅ Directory exists: $dir" -ForegroundColor Green
    } else {
        Write-Host "❌ Missing directory: $dir" -ForegroundColor Red
        $issues++
    }
}

# Check required files
$requiredFiles = @(
    "backend\app\main.py", "backend\requirements.txt", "backend\Dockerfile", "backend\.env.example",
    "frontend\package.json", "frontend\vite.config.ts", "frontend\Dockerfile",
    "docker-compose.yml", "README.md", ".gitignore"
)

foreach ($file in $requiredFiles) {
    if (Test-Path $file) {
        Write-Host "✅ File exists: $file" -ForegroundColor Green
    } else {
        Write-Host "❌ Missing file: $file" -ForegroundColor Red
        $issues++
    }
}

Write-Host ""
Write-Host "🐍 Checking Python code..." -ForegroundColor Yellow

# Check Python files
$pythonFiles = Get-ChildItem -Path "backend" -Recurse -Filter "*.py" -ErrorAction SilentlyContinue
foreach ($file in $pythonFiles) {
    $totalFiles++
    $content = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
    if ($content) {
        $lines = ($content -split "`n").Count
        $totalLines += $lines
        
        # Check for syntax errors (basic check)
        try {
            $null = [System.Management.Automation.PSParser]::Tokenize($content, [ref]$null)
            Write-Host "✅ Syntax OK: $($file.Name)" -ForegroundColor Green
        } catch {
            Write-Host "❌ Syntax error in: $($file.Name)" -ForegroundColor Red
            $issues++
        }
        
        # Check for common issues
        if ($content -match "print\s*\(") {
            Write-Host "WARNING: Print statement found in: $($file.Name)" -ForegroundColor Yellow
        }
        
        if ($content -match "(api_key|password|secret|token)\s*=\s*['`"][^'`"]+['`"]") {
            Write-Host "ERROR: Potential hardcoded secret in: $($file.Name)" -ForegroundColor Red
            $issues++
        }
        
        if ($content -match "(TODO|FIXME|HACK|XXX)") {
            Write-Host "INFO: TODO/FIXME comment in: $($file.Name)" -ForegroundColor Cyan
        }
    }
}

Write-Host ""
Write-Host "⚛️  Checking React code..." -ForegroundColor Yellow

# Check JavaScript/TypeScript files
$jsFiles = Get-ChildItem -Path "frontend\src" -Recurse -Filter "*.{js,jsx,ts,tsx}" -ErrorAction SilentlyContinue
foreach ($file in $jsFiles) {
    $totalFiles++
    $content = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
    if ($content) {
        $lines = ($content -split "`n").Count
        $totalLines += $lines
        
        if ($content -match "console\.log") {
            Write-Host "WARNING: Console.log found in: $($file.Name)" -ForegroundColor Yellow
        } else {
            Write-Host "OK: No console.log in: $($file.Name)" -ForegroundColor Green
        }
        
        if ($content -match "http[s]?://[^'`"]+['`"]" -and $content -notmatch "localhost") {
            Write-Host "WARNING: Hardcoded URL in: $($file.Name)" -ForegroundColor Yellow
        }
        
        if ($content -match "<img[^>]*(?!alt=)") {
            Write-Host "WARNING: Image missing alt attribute in: $($file.Name)" -ForegroundColor Yellow
        }
    }
}

Write-Host ""
Write-Host "🐳 Checking Docker configuration..." -ForegroundColor Yellow

# Check Dockerfile
if (Test-Path "backend\Dockerfile") {
    Write-Host "✅ Backend Dockerfile exists" -ForegroundColor Green
    $dockerContent = Get-Content "backend\Dockerfile" -Raw -ErrorAction SilentlyContinue
    if ($dockerContent -match "USER\s+root") {
        Write-Host "WARNING: Dockerfile runs as root user" -ForegroundColor Yellow
    } else {
        Write-Host "OK: Dockerfile uses non-root user" -ForegroundColor Green
    }
    
    if ($dockerContent -notmatch "HEALTHCHECK") {
        Write-Host "WARNING: Missing health check in Dockerfile" -ForegroundColor Yellow
    } else {
        Write-Host "OK: Health check present in Dockerfile" -ForegroundColor Green
    }
} else {
    Write-Host "❌ Backend Dockerfile missing" -ForegroundColor Red
    $issues++
}

# Check docker-compose.yml
if (Test-Path "docker-compose.yml") {
    Write-Host "✅ Docker Compose file exists" -ForegroundColor Green
    try {
        $composeContent = Get-Content "docker-compose.yml" -Raw -ErrorAction SilentlyContinue
        if ($composeContent -match "backend:" -and $composeContent -match "frontend:") {
            Write-Host "OK: Required services defined" -ForegroundColor Green
        } else {
            Write-Host "WARNING: Missing required services" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "WARNING: Could not parse docker-compose.yml" -ForegroundColor Yellow
    }
} else {
    Write-Host "❌ Docker Compose file missing" -ForegroundColor Red
    $issues++
}

Write-Host ""
Write-Host "Checking dependencies..." -ForegroundColor Yellow

# Check Python dependencies
if (Test-Path "backend\requirements.txt") {
    Write-Host "✅ Python requirements file exists" -ForegroundColor Green
    $requirements = Get-Content "backend\requirements.txt" -ErrorAction SilentlyContinue
    if ($requirements) {
        Write-Host "✅ Requirements file has content" -ForegroundColor Green
    } else {
        Write-Host "WARNING: Requirements file is empty" -ForegroundColor Yellow
    }
} else {
    Write-Host "❌ Python requirements file missing" -ForegroundColor Red
    $issues++
}

# Check Node.js dependencies
if (Test-Path "frontend\package.json") {
    Write-Host "✅ Node.js package file exists" -ForegroundColor Green
    try {
        $packageJson = Get-Content "frontend\package.json" -Raw | ConvertFrom-Json
        if ($packageJson.dependencies -or $packageJson.devDependencies) {
            Write-Host "✅ Package.json has dependencies" -ForegroundColor Green
        } else {
            Write-Host "WARNING: Package.json has no dependencies" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "WARNING: Could not parse package.json" -ForegroundColor Yellow
    }
} else {
    Write-Host "❌ Node.js package file missing" -ForegroundColor Red
    $issues++
}

Write-Host ""
Write-Host "Checking environment variables..." -ForegroundColor Yellow

# Check environment files
if (Test-Path "backend\.env.example") {
    Write-Host "✅ Environment example file exists" -ForegroundColor Green
} else {
    Write-Host "❌ Environment example file missing" -ForegroundColor Red
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
    Write-Host "✅ Models directory exists" -ForegroundColor Green
    $modelFiles = Get-ChildItem "backend\saved_models" -Filter "*.pkl" -ErrorAction SilentlyContinue
    if ($modelFiles) {
        Write-Host "✅ Model files exist ($($modelFiles.Count) files)" -ForegroundColor Green
        foreach ($model in $modelFiles) {
            $sizeMB = [math]::Round($model.Length / 1MB, 2)
            if ($sizeMB -gt 100) {
                Write-Host "WARNING: Large model file: $($model.Name) ($sizeMB MB)" -ForegroundColor Yellow
            } else {
                Write-Host "✅ Model file: $($model.Name) ($sizeMB MB)" -ForegroundColor Green
            }
        }
    } else {
        Write-Host "❌ No model files found" -ForegroundColor Red
        $issues++
    }
} else {
    Write-Host "❌ Models directory missing" -ForegroundColor Red
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
            Write-Host "✅ $ignore in .gitignore" -ForegroundColor Green
        } else {
            Write-Host "WARNING: $ignore not in .gitignore" -ForegroundColor Yellow
        }
    }
} else {
    Write-Host "❌ .gitignore missing" -ForegroundColor Red
    $issues++
}

Write-Host ""
Write-Host "Checking documentation..." -ForegroundColor Yellow

# Check documentation files
$docFiles = @("README.md", "SECURITY.md", "PERFORMANCE.md", "BACKUP_DISASTER_RECOVERY.md", "DOCKER.md")
foreach ($doc in $docFiles) {
    if (Test-Path $doc) {
        Write-Host "✅ Documentation exists: $doc" -ForegroundColor Green
    } else {
        Write-Host "WARNING: Documentation missing: $doc" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "Checking tests..." -ForegroundColor Yellow

# Check test directories
if (Test-Path "backend\tests") {
    $testFiles = Get-ChildItem "backend\tests" -Filter "*.py" -ErrorAction SilentlyContinue
    Write-Host "✅ Backend tests directory exists ($($testFiles.Count) test files)" -ForegroundColor Green
} else {
    Write-Host "WARNING: Backend tests directory missing" -ForegroundColor Yellow
}

if (Test-Path "frontend\src\__tests__") {
    $frontendTests = Get-ChildItem "frontend\src\__tests__" -Filter "*.{js,jsx,ts,tsx}" -ErrorAction SilentlyContinue
    Write-Host "✅ Frontend tests directory exists ($($frontendTests.Count) test files)" -ForegroundColor Green
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
    Write-Host "✅ No issues found! Project is in excellent condition." -ForegroundColor Green
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

Read-Host "Press Enter to continue"

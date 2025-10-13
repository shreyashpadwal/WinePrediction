# Wine Quality Prediction - Audit System

This directory contains comprehensive audit and error detection scripts for the Wine Quality Prediction project.

## 📁 Files Overview

### Core Audit Scripts
- **`simple-audit.ps1`** - Main PowerShell audit script (Windows-compatible)
- **`audit-project.py`** - Python audit script (requires Python installation)
- **`audit-project.bat`** - Batch version of audit script
- **`quick-health-check.bat`** - Quick health check script
- **`fix-common-issues.bat`** - Automated fix script

### Reporting & Continuous Monitoring
- **`audit-report.html`** - Beautiful HTML report template
- **`continuous-audit.bat`** - Continuous monitoring script
- **`requirements.txt`** - Python dependencies for audit tools

## 🚀 Quick Start

### 1. Run Quick Health Check
```bash
# Windows
scripts\quick-health-check.bat

# Or via Makefile
make audit-quick
```

### 2. Run Comprehensive Audit
```bash
# Windows PowerShell
powershell -ExecutionPolicy Bypass -File scripts\simple-audit.ps1

# Or via Makefile
make audit
```

### 3. Auto-Fix Common Issues
```bash
# Windows
scripts\fix-common-issues.bat

# Or via Makefile
make fix
```

## 📊 What the Audit System Checks

### File Structure Verification
- ✅ Required directories exist (backend, frontend, scripts, docs, logs)
- ✅ Critical files present (main.py, requirements.txt, package.json, etc.)
- ✅ Proper project organization

### Code Quality Analysis
- **Python Code:**
  - Syntax errors and import issues
  - Print statements (should use logging)
  - Hardcoded secrets and credentials
  - TODO/FIXME comments
  - Type hints and docstrings

- **React/TypeScript Code:**
  - Console.log statements
  - Unused variables and imports
  - Missing prop validation
  - Hardcoded URLs
  - Accessibility issues

### Docker Configuration
- ✅ Dockerfile exists and is properly configured
- ✅ Non-root user usage
- ✅ Health checks present
- ✅ Security best practices
- ✅ docker-compose.yml validation

### Dependencies & Security
- **Python Dependencies:**
  - Vulnerabilities (pip-audit)
  - Outdated packages
  - Version conflicts

- **Node.js Dependencies:**
  - Security vulnerabilities (npm audit)
  - Outdated packages
  - Unused dependencies

### Environment & Configuration
- ✅ Environment variables properly configured
- ✅ .env.example exists
- ✅ .env file not committed to git
- ✅ Proper .gitignore configuration

### ML Models & Data
- ✅ Model files exist and are accessible
- ✅ Model file sizes reasonable
- ✅ Data integrity checks

### Documentation & Testing
- ✅ README.md and other docs present
- ✅ Test files exist
- ✅ API documentation available

## 📈 Audit Output

### Console Output
The audit provides color-coded output:
- 🟢 **Green**: Everything OK
- 🟡 **Yellow**: Warnings (non-critical issues)
- 🔴 **Red**: Errors (critical issues)
- 🔵 **Blue**: Information

### Health Score
The system calculates a health score (0-100):
- **90-100**: Excellent ✅
- **80-89**: Good ⚠️
- **70-79**: Fair ⚠️
- **Below 70**: Needs Improvement ❌

### Report Files
- **Text Report**: `reports/audit-YYYY-MM-DD.txt`
- **HTML Report**: `reports/audit-report.html` (when generated)

## 🔧 Automated Fixes

The `fix-common-issues.bat` script can automatically fix:

### Directory Structure
- Create missing directories (logs, reports)
- Create missing files (main.py, .env)

### Code Issues
- Remove console.log statements (with confirmation)
- Remove print statements (with confirmation)
- Fix import order
- Add missing docstrings

### Configuration
- Update .gitignore with required patterns
- Create .env from .env.example
- Fix common security issues

### Documentation
- Create missing documentation files
- Generate basic test files

## 🔄 Continuous Monitoring

### Daily Audits
The `continuous-audit.bat` script:
- Runs daily audits automatically
- Compares with previous runs
- Alerts on new critical issues
- Generates summary reports
- Cleans up old reports

### Scheduling
```bash
# Schedule daily audit at 9:00 AM
schtasks /create /tn "WinePredictionAudit" /tr "scripts\continuous-audit.bat" /sc daily /st 09:00
```

## 🛠️ Integration with Development Workflow

### Makefile Integration
```bash
# Available audit commands
make audit          # Comprehensive audit
make audit-quick     # Quick health check
make fix            # Auto-fix common issues
make security        # Security-focused audit
make health          # System health check
```

### Frontend Integration
```bash
# Frontend-specific audit commands
cd frontend
npm run audit       # Run npm audit + ESLint
npm run audit:fix   # Fix issues automatically
```

### CI/CD Integration
```bash
# Add to GitHub Actions or Azure DevOps
- name: Run Project Audit
  run: make audit-quick

- name: Fix Common Issues
  run: make fix
```

## 📋 Manual Review Required

Some issues require manual attention:

### Security Issues
- Hardcoded API keys or passwords
- SQL injection vulnerabilities
- XSS vulnerabilities
- CORS misconfigurations

### Performance Issues
- Large files or unoptimized images
- N+1 database queries
- Memory leaks
- Blocking operations

### Code Quality
- Complex functions that need refactoring
- Missing error handling
- Inadequate logging
- Poor documentation

## 🎯 Best Practices

### Running Audits
1. **Before commits**: Run `make audit-quick`
2. **Before releases**: Run `make audit`
3. **Weekly**: Review audit reports
4. **Daily**: Automated continuous audit

### Fixing Issues
1. **Critical issues**: Fix immediately
2. **Warnings**: Address within a week
3. **Info items**: Fix when convenient
4. **Use automation**: Run `make fix` first

### Monitoring
1. **Set up continuous monitoring**: Use `continuous-audit.bat`
2. **Review trends**: Compare health scores over time
3. **Alert on regressions**: New critical issues
4. **Track improvements**: Monitor issue resolution

## 🔍 Troubleshooting

### Common Issues

**PowerShell Execution Policy Error**
```bash
powershell -ExecutionPolicy Bypass -File scripts\simple-audit.ps1
```

**Python Not Found**
- Use the PowerShell or Batch versions instead
- Or install Python and add to PATH

**Docker Not Running**
- Start Docker Desktop
- Run `docker-compose up -d` first

**Permission Errors**
- Run as Administrator
- Check file permissions

### Getting Help
1. Check the audit report for specific issues
2. Run `make help` for available commands
3. Review the generated reports in `reports/` directory
4. Check logs in `logs/` directory

## 📚 Additional Resources

- [Project Documentation](../README.md)
- [Security Guidelines](../SECURITY.md)
- [Performance Tips](../PERFORMANCE.md)
- [Docker Setup](../DOCKER.md)

---

**Last Updated**: $(Get-Date)
**Version**: 1.0.0
**Maintainer**: Wine Quality Prediction Team
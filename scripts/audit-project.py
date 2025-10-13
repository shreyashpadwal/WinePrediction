#!/usr/bin/env python3
"""
Comprehensive Project Audit and Error Detection System
Scans all files and verifies everything is working correctly.
"""

import os
import sys
import json
import subprocess
import ast
import re
import hashlib
import datetime
from pathlib import Path
from typing import Dict, List, Tuple, Any, Optional
from dataclasses import dataclass
from enum import Enum
import argparse
import logging

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

class Severity(Enum):
    CRITICAL = "CRITICAL"
    ERROR = "ERROR"
    WARNING = "WARNING"
    INFO = "INFO"

@dataclass
class AuditIssue:
    severity: Severity
    category: str
    file_path: str
    line_number: Optional[int]
    message: str
    suggestion: Optional[str] = None

@dataclass
class AuditResult:
    category: str
    status: str
    score: int
    issues: List[AuditIssue]
    details: Dict[str, Any]

class ProjectAuditor:
    def __init__(self, project_root: str = "."):
        self.project_root = Path(project_root).resolve()
        self.results: Dict[str, AuditResult] = {}
        self.overall_score = 0
        self.total_issues = 0
        
    def run_full_audit(self) -> Dict[str, Any]:
        """Run complete project audit"""
        logger.info("🔍 Starting comprehensive project audit...")
        
        # Run all audit categories
        self.results['file_structure'] = self.audit_file_structure()
        self.results['python_code'] = self.audit_python_code()
        self.results['react_code'] = self.audit_react_code()
        self.results['docker_config'] = self.audit_docker_config()
        self.results['dependencies'] = self.audit_dependencies()
        self.results['environment'] = self.audit_environment()
        self.results['api_endpoints'] = self.audit_api_endpoints()
        self.results['ml_models'] = self.audit_ml_models()
        self.results['storage'] = self.audit_storage()
        self.results['logging'] = self.audit_logging()
        self.results['testing'] = self.audit_testing()
        self.results['security'] = self.audit_security()
        self.results['performance'] = self.audit_performance()
        self.results['documentation'] = self.audit_documentation()
        
        # Calculate overall score
        self.calculate_overall_score()
        
        return self.generate_report()
    
    def audit_file_structure(self) -> AuditResult:
        """A. File Structure Verification"""
        logger.info("📁 Auditing file structure...")
        issues = []
        
        # Required directories
        required_dirs = [
            "backend/app", "backend/saved_models", "backend/logs",
            "frontend/src", "frontend/public",
            "data/raw", "data/processed",
            "notebooks", "docs", "scripts"
        ]
        
        # Required files
        required_files = [
            "backend/app/main.py", "backend/requirements.txt", "backend/Dockerfile", "backend/.env.example",
            "frontend/package.json", "frontend/vite.config.ts", "frontend/Dockerfile",
            "docker-compose.yml", "README.md", ".gitignore"
        ]
        
        # Check directories
        for dir_path in required_dirs:
            full_path = self.project_root / dir_path
            if not full_path.exists():
                issues.append(AuditIssue(
                    severity=Severity.ERROR,
                    category="file_structure",
                    file_path=dir_path,
                    line_number=None,
                    message=f"Required directory missing: {dir_path}",
                    suggestion=f"Create directory: mkdir -p {dir_path}"
                ))
        
        # Check files
        for file_path in required_files:
            full_path = self.project_root / file_path
            if not full_path.exists():
                issues.append(AuditIssue(
                    severity=Severity.ERROR,
                    category="file_structure",
                    file_path=file_path,
                    line_number=None,
                    message=f"Required file missing: {file_path}",
                    suggestion=f"Create file: touch {file_path}"
                ))
        
        status = "✅ PASS" if not issues else f"❌ FAIL ({len(issues)} issues)"
        score = max(0, 100 - len(issues) * 10)
        
        return AuditResult(
            category="File Structure",
            status=status,
            score=score,
            issues=issues,
            details={"checked_dirs": len(required_dirs), "checked_files": len(required_files)}
        )
    
    def audit_python_code(self) -> AuditResult:
        """B. Python Code Analysis"""
        logger.info("🐍 Auditing Python code...")
        issues = []
        
        python_files = list(self.project_root.glob("backend/**/*.py"))
        
        for py_file in python_files:
            try:
                # Check syntax
                with open(py_file, 'r', encoding='utf-8') as f:
                    content = f.read()
                    try:
                        ast.parse(content)
                    except SyntaxError as e:
                        issues.append(AuditIssue(
                            severity=Severity.ERROR,
                            category="python_code",
                            file_path=str(py_file.relative_to(self.project_root)),
                            line_number=e.lineno,
                            message=f"Syntax error: {e.msg}",
                            suggestion="Fix syntax error"
                        ))
                
                # Check for common issues
                lines = content.split('\n')
                for i, line in enumerate(lines, 1):
                    # Check for print statements
                    if re.search(r'\bprint\s*\(', line) and 'logger' not in line:
                        issues.append(AuditIssue(
                            severity=Severity.WARNING,
                            category="python_code",
                            file_path=str(py_file.relative_to(self.project_root)),
                            line_number=i,
                            message="Print statement found, should use logger",
                            suggestion="Replace with logger.info()"
                        ))
                    
                    # Check for hardcoded secrets
                    if re.search(r'(password|secret|key|token)\s*=\s*["\'][^"\']+["\']', line, re.IGNORECASE):
                        issues.append(AuditIssue(
                            severity=Severity.CRITICAL,
                            category="python_code",
                            file_path=str(py_file.relative_to(self.project_root)),
                            line_number=i,
                            message="Potential hardcoded secret detected",
                            suggestion="Use environment variables or Azure Key Vault"
                        ))
                    
                    # Check for TODO/FIXME
                    if re.search(r'(TODO|FIXME|HACK|XXX)', line, re.IGNORECASE):
                        issues.append(AuditIssue(
                            severity=Severity.INFO,
                            category="python_code",
                            file_path=str(py_file.relative_to(self.project_root)),
                            line_number=i,
                            message=f"TODO/FIXME comment: {line.strip()}",
                            suggestion="Address the TODO/FIXME comment"
                        ))
                
                # Check for missing docstrings in functions
                try:
                    tree = ast.parse(content)
                    for node in ast.walk(tree):
                        if isinstance(node, ast.FunctionDef) and not node.name.startswith('_'):
                            if not ast.get_docstring(node):
                                issues.append(AuditIssue(
                                    severity=Severity.INFO,
                                    category="python_code",
                                    file_path=str(py_file.relative_to(self.project_root)),
                                    line_number=node.lineno,
                                    message=f"Function '{node.name}' missing docstring",
                                    suggestion="Add docstring to function"
                                ))
                except:
                    pass
                    
            except Exception as e:
                issues.append(AuditIssue(
                    severity=Severity.ERROR,
                    category="python_code",
                    file_path=str(py_file.relative_to(self.project_root)),
                    line_number=None,
                    message=f"Error analyzing file: {str(e)}",
                    suggestion="Check file encoding and format"
                ))
        
        # Run pylint if available
        try:
            result = subprocess.run(['pylint', '--output-format=json', 'backend/'], 
                                  capture_output=True, text=True, cwd=self.project_root)
            if result.returncode != 0:
                try:
                    pylint_results = json.loads(result.stdout)
                    for issue in pylint_results:
                        severity_map = {
                            'error': Severity.ERROR,
                            'warning': Severity.WARNING,
                            'info': Severity.INFO
                        }
                        issues.append(AuditIssue(
                            severity=severity_map.get(issue['type'], Severity.INFO),
                            category="python_code",
                            file_path=issue['path'],
                            line_number=issue['line'],
                            message=f"Pylint: {issue['message']}",
                            suggestion="Fix pylint issue"
                        ))
                except:
                    pass
        except FileNotFoundError:
            logger.warning("Pylint not found, skipping pylint analysis")
        
        status = "✅ PASS" if not issues else f"⚠️  WARNING ({len(issues)} issues)"
        score = max(0, 100 - len(issues) * 5)
        
        return AuditResult(
            category="Python Code",
            status=status,
            score=score,
            issues=issues,
            details={"files_analyzed": len(python_files)}
        )
    
    def audit_react_code(self) -> AuditResult:
        """C. JavaScript/React Code Analysis"""
        logger.info("⚛️  Auditing React code...")
        issues = []
        
        js_files = list(self.project_root.glob("frontend/src/**/*.{js,jsx,ts,tsx}"))
        
        for js_file in js_files:
            try:
                with open(js_file, 'r', encoding='utf-8') as f:
                    content = f.read()
                    lines = content.split('\n')
                    
                    for i, line in enumerate(lines, 1):
                        # Check for console.log
                        if re.search(r'console\.log\s*\(', line):
                            issues.append(AuditIssue(
                                severity=Severity.WARNING,
                                category="react_code",
                                file_path=str(js_file.relative_to(self.project_root)),
                                line_number=i,
                                message="Console.log found, should be removed in production",
                                suggestion="Remove console.log or use proper logging"
                            ))
                        
                        # Check for hardcoded API URLs
                        if re.search(r'http[s]?://[^"\']+["\']', line) and 'localhost' not in line:
                            issues.append(AuditIssue(
                                severity=Severity.WARNING,
                                category="react_code",
                                file_path=str(js_file.relative_to(self.project_root)),
                                line_number=i,
                                message="Hardcoded API URL detected",
                                suggestion="Use environment variables for API URLs"
                            ))
                        
                        # Check for TODO/FIXME
                        if re.search(r'(TODO|FIXME|HACK|XXX)', line, re.IGNORECASE):
                            issues.append(AuditIssue(
                                severity=Severity.INFO,
                                category="react_code",
                                file_path=str(js_file.relative_to(self.project_root)),
                                line_number=i,
                                message=f"TODO/FIXME comment: {line.strip()}",
                                suggestion="Address the TODO/FIXME comment"
                            ))
                        
                        # Check for accessibility issues
                        if re.search(r'<img[^>]*(?!alt=)', line):
                            issues.append(AuditIssue(
                                severity=Severity.WARNING,
                                category="react_code",
                                file_path=str(js_file.relative_to(self.project_root)),
                                line_number=i,
                                message="Image missing alt attribute",
                                suggestion="Add alt attribute for accessibility"
                            ))
                        
                        # Check for unhandled promise rejections
                        if re.search(r'\.then\s*\([^)]*\)(?!\s*\.catch)', line):
                            issues.append(AuditIssue(
                                severity=Severity.WARNING,
                                category="react_code",
                                file_path=str(js_file.relative_to(self.project_root)),
                                line_number=i,
                                message="Promise without error handling",
                                suggestion="Add .catch() or use try/catch with async/await"
                            ))
                            
            except Exception as e:
                issues.append(AuditIssue(
                    severity=Severity.ERROR,
                    category="react_code",
                    file_path=str(js_file.relative_to(self.project_root)),
                    line_number=None,
                    message=f"Error analyzing file: {str(e)}",
                    suggestion="Check file encoding and format"
                ))
        
        # Run ESLint if available
        try:
            result = subprocess.run(['npx', 'eslint', 'frontend/src/', '--format=json'], 
                                  capture_output=True, text=True, cwd=self.project_root)
            if result.returncode != 0:
                try:
                    eslint_results = json.loads(result.stdout)
                    for file_result in eslint_results:
                        for message in file_result.get('messages', []):
                            severity_map = {
                                2: Severity.ERROR,
                                1: Severity.WARNING,
                                0: Severity.INFO
                            }
                            issues.append(AuditIssue(
                                severity=severity_map.get(message['severity'], Severity.INFO),
                                category="react_code",
                                file_path=file_result['filePath'],
                                line_number=message['line'],
                                message=f"ESLint: {message['message']}",
                                suggestion="Fix ESLint issue"
                            ))
                except:
                    pass
        except FileNotFoundError:
            logger.warning("ESLint not found, skipping ESLint analysis")
        
        status = "✅ PASS" if not issues else f"⚠️  WARNING ({len(issues)} issues)"
        score = max(0, 100 - len(issues) * 5)
        
        return AuditResult(
            category="React Code",
            status=status,
            score=score,
            issues=issues,
            details={"files_analyzed": len(js_files)}
        )
    
    def audit_docker_config(self) -> AuditResult:
        """D. Docker Configuration Check"""
        logger.info("🐳 Auditing Docker configuration...")
        issues = []
        
        dockerfile_path = self.project_root / "backend" / "Dockerfile"
        if dockerfile_path.exists():
            with open(dockerfile_path, 'r') as f:
                content = f.read()
                lines = content.split('\n')
                
                for i, line in enumerate(lines, 1):
                    # Check for running as root
                    if re.search(r'USER\s+root', line):
                        issues.append(AuditIssue(
                            severity=Severity.WARNING,
                            category="docker_config",
                            file_path="backend/Dockerfile",
                            line_number=i,
                            message="Running as root user",
                            suggestion="Use non-root user for security"
                        ))
                    
                    # Check for missing health check
                    if 'HEALTHCHECK' not in content:
                        issues.append(AuditIssue(
                            severity=Severity.WARNING,
                            category="docker_config",
                            file_path="backend/Dockerfile",
                            line_number=None,
                            message="Missing health check",
                            suggestion="Add HEALTHCHECK instruction"
                        ))
                    
                    # Check for hardcoded secrets
                    if re.search(r'(password|secret|key|token)\s*=\s*["\'][^"\']+["\']', line, re.IGNORECASE):
                        issues.append(AuditIssue(
                            severity=Severity.CRITICAL,
                            category="docker_config",
                            file_path="backend/Dockerfile",
                            line_number=i,
                            message="Potential hardcoded secret in Dockerfile",
                            suggestion="Use environment variables or build args"
                        ))
        
        # Check docker-compose.yml
        compose_path = self.project_root / "docker-compose.yml"
        if compose_path.exists():
            try:
                import yaml
                with open(compose_path, 'r') as f:
                    compose_config = yaml.safe_load(f)
                    
                # Check for required services
                required_services = ['backend', 'frontend']
                for service in required_services:
                    if service not in compose_config.get('services', {}):
                        issues.append(AuditIssue(
                            severity=Severity.ERROR,
                            category="docker_config",
                            file_path="docker-compose.yml",
                            line_number=None,
                            message=f"Missing service: {service}",
                            suggestion=f"Add {service} service to docker-compose.yml"
                        ))
                        
            except Exception as e:
                issues.append(AuditIssue(
                    severity=Severity.ERROR,
                    category="docker_config",
                    file_path="docker-compose.yml",
                    line_number=None,
                    message=f"Invalid YAML syntax: {str(e)}",
                    suggestion="Fix YAML syntax errors"
                ))
        
        status = "✅ PASS" if not issues else f"⚠️  WARNING ({len(issues)} issues)"
        score = max(0, 100 - len(issues) * 10)
        
        return AuditResult(
            category="Docker Configuration",
            status=status,
            score=score,
            issues=issues,
            details={}
        )
    
    def audit_dependencies(self) -> AuditResult:
        """E. Dependencies Audit"""
        logger.info("📦 Auditing dependencies...")
        issues = []
        
        # Check Python dependencies
        requirements_path = self.project_root / "backend" / "requirements.txt"
        if requirements_path.exists():
            try:
                # Check for security vulnerabilities
                result = subprocess.run(['pip-audit', '--format=json'], 
                                      capture_output=True, text=True, cwd=self.project_root)
                if result.returncode != 0:
                    try:
                        audit_results = json.loads(result.stdout)
                        for vuln in audit_results:
                            issues.append(AuditIssue(
                                severity=Severity.CRITICAL,
                                category="dependencies",
                                file_path="backend/requirements.txt",
                                line_number=None,
                                message=f"Security vulnerability: {vuln.get('package', 'Unknown')} - {vuln.get('vulnerability', 'Unknown')}",
                                suggestion="Update package to secure version"
                            ))
                    except:
                        pass
            except FileNotFoundError:
                logger.warning("pip-audit not found, skipping Python security audit")
        
        # Check Node.js dependencies
        package_json_path = self.project_root / "frontend" / "package.json"
        if package_json_path.exists():
            try:
                # Run npm audit
                result = subprocess.run(['npm', 'audit', '--json'], 
                                      capture_output=True, text=True, cwd=self.project_root / "frontend")
                if result.returncode != 0:
                    try:
                        audit_results = json.loads(result.stdout)
                        for vuln in audit_results.get('vulnerabilities', {}).values():
                            issues.append(AuditIssue(
                                severity=Severity.CRITICAL,
                                category="dependencies",
                                file_path="frontend/package.json",
                                line_number=None,
                                message=f"Security vulnerability: {vuln.get('name', 'Unknown')} - {vuln.get('severity', 'Unknown')}",
                                suggestion="Run 'npm audit fix' to update packages"
                            ))
                    except:
                        pass
            except FileNotFoundError:
                logger.warning("npm not found, skipping Node.js security audit")
        
        status = "✅ PASS" if not issues else f"🔴 CRITICAL ({len(issues)} issues)"
        score = max(0, 100 - len(issues) * 20)
        
        return AuditResult(
            category="Dependencies",
            status=status,
            score=score,
            issues=issues,
            details={}
        )
    
    def audit_environment(self) -> AuditResult:
        """F. Environment Variables Check"""
        logger.info("🌍 Auditing environment variables...")
        issues = []
        
        # Scan for environment variable usage
        env_vars = set()
        for py_file in self.project_root.glob("backend/**/*.py"):
            with open(py_file, 'r', encoding='utf-8') as f:
                content = f.read()
                # Find os.environ usage
                matches = re.findall(r'os\.environ\[["\']([^"\']+)["\']\]', content)
                env_vars.update(matches)
                
                # Find os.getenv usage
                matches = re.findall(r'os\.getenv\(["\']([^"\']+)["\']', content)
                env_vars.update(matches)
        
        # Check .env.example
        env_example_path = self.project_root / "backend" / ".env.example"
        if env_example_path.exists():
            with open(env_example_path, 'r') as f:
                example_content = f.read()
                example_vars = set()
                for line in example_content.split('\n'):
                    if '=' in line and not line.strip().startswith('#'):
                        var_name = line.split('=')[0].strip()
                        example_vars.add(var_name)
                
                # Check for missing variables in .env.example
                missing_vars = env_vars - example_vars
                for var in missing_vars:
                    issues.append(AuditIssue(
                        severity=Severity.WARNING,
                        category="environment",
                        file_path="backend/.env.example",
                        line_number=None,
                        message=f"Environment variable '{var}' used in code but not documented in .env.example",
                        suggestion=f"Add {var}=your_value_here to .env.example"
                    ))
        else:
            issues.append(AuditIssue(
                severity=Severity.ERROR,
                category="environment",
                file_path="backend/.env.example",
                line_number=None,
                message=".env.example file missing",
                suggestion="Create .env.example with all required environment variables"
            ))
        
        # Check for .env files in git
        try:
            result = subprocess.run(['git', 'ls-files', '*.env'], 
                                  capture_output=True, text=True, cwd=self.project_root)
            if result.stdout.strip():
                for env_file in result.stdout.strip().split('\n'):
                    issues.append(AuditIssue(
                        severity=Severity.CRITICAL,
                        category="environment",
                        file_path=env_file,
                        line_number=None,
                        message="Environment file committed to git",
                        suggestion="Remove from git and add to .gitignore"
                    ))
        except FileNotFoundError:
            pass
        
        status = "✅ PASS" if not issues else f"⚠️  WARNING ({len(issues)} issues)"
        score = max(0, 100 - len(issues) * 10)
        
        return AuditResult(
            category="Environment Variables",
            status=status,
            score=score,
            issues=issues,
            details={"env_vars_found": len(env_vars)}
        )
    
    def audit_api_endpoints(self) -> AuditResult:
        """G. API Endpoints Validation"""
        logger.info("🔌 Auditing API endpoints...")
        issues = []
        endpoints = []
        
        # Find FastAPI routes
        routes_path = self.project_root / "backend" / "app" / "routes"
        if routes_path.exists():
            for py_file in routes_path.glob("*.py"):
                with open(py_file, 'r', encoding='utf-8') as f:
                    content = f.read()
                    
                    # Find route definitions
                    route_matches = re.findall(r'@router\.(get|post|put|delete|patch)\s*\(\s*["\']([^"\']+)["\']', content)
                    for method, path in route_matches:
                        endpoints.append(f"{method.upper()} {path}")
                        
                        # Check for input validation
                        if method.lower() in ['post', 'put', 'patch']:
                            if 'WineFeatures' not in content and 'BaseModel' not in content:
                                issues.append(AuditIssue(
                                    severity=Severity.WARNING,
                                    category="api_endpoints",
                                    file_path=str(py_file.relative_to(self.project_root)),
                                    line_number=None,
                                    message=f"Endpoint {method.upper()} {path} may be missing input validation",
                                    suggestion="Add Pydantic model for request validation"
                                ))
        
        status = "✅ PASS" if not issues else f"⚠️  WARNING ({len(issues)} issues)"
        score = max(0, 100 - len(issues) * 10)
        
        return AuditResult(
            category="API Endpoints",
            status=status,
            score=score,
            issues=issues,
            details={"endpoints_found": len(endpoints), "endpoints": endpoints}
        )
    
    def audit_ml_models(self) -> AuditResult:
        """H. ML Model Verification"""
        logger.info("🤖 Auditing ML models...")
        issues = []
        
        models_path = self.project_root / "backend" / "saved_models"
        if not models_path.exists():
            issues.append(AuditIssue(
                severity=Severity.ERROR,
                category="ml_models",
                file_path="backend/saved_models",
                line_number=None,
                message="Models directory missing",
                suggestion="Create saved_models directory and train models"
            ))
            return AuditResult(
                category="ML Models",
                status="❌ FAIL",
                score=0,
                issues=issues,
                details={}
            )
        
        # Check for model files
        model_files = list(models_path.glob("*.pkl"))
        if not model_files:
            issues.append(AuditIssue(
                severity=Severity.ERROR,
                category="ml_models",
                file_path="backend/saved_models",
                line_number=None,
                message="No model files found",
                suggestion="Train and save ML models"
            ))
        else:
            # Check model file sizes
            for model_file in model_files:
                size_mb = model_file.stat().st_size / (1024 * 1024)
                if size_mb > 100:
                    issues.append(AuditIssue(
                        severity=Severity.WARNING,
                        category="ml_models",
                        file_path=str(model_file.relative_to(self.project_root)),
                        line_number=None,
                        message=f"Model file is large ({size_mb:.1f}MB)",
                        suggestion="Consider model optimization or compression"
                    ))
                
                # Try to load model
                try:
                    import joblib
                    model = joblib.load(model_file)
                    logger.info(f"Successfully loaded model: {model_file.name}")
                except Exception as e:
                    issues.append(AuditIssue(
                        severity=Severity.ERROR,
                        category="ml_models",
                        file_path=str(model_file.relative_to(self.project_root)),
                        line_number=None,
                        message=f"Model file corrupted or invalid: {str(e)}",
                        suggestion="Retrain and save the model"
                    ))
        
        status = "✅ PASS" if not issues else f"⚠️  WARNING ({len(issues)} issues)"
        score = max(0, 100 - len(issues) * 20)
        
        return AuditResult(
            category="ML Models",
            status=status,
            score=score,
            issues=issues,
            details={"model_files": len(model_files)}
        )
    
    def audit_storage(self) -> AuditResult:
        """I. Database/Storage Check"""
        logger.info("💾 Auditing storage...")
        issues = []
        
        # Check for data directories
        data_dirs = ["data/raw", "data/processed"]
        for data_dir in data_dirs:
            dir_path = self.project_root / data_dir
            if not dir_path.exists():
                issues.append(AuditIssue(
                    severity=Severity.WARNING,
                    category="storage",
                    file_path=data_dir,
                    line_number=None,
                    message=f"Data directory missing: {data_dir}",
                    suggestion=f"Create directory: mkdir -p {data_dir}"
                ))
        
        status = "✅ PASS" if not issues else f"⚠️  WARNING ({len(issues)} issues)"
        score = max(0, 100 - len(issues) * 10)
        
        return AuditResult(
            category="Storage",
            status=status,
            score=score,
            issues=issues,
            details={}
        )
    
    def audit_logging(self) -> AuditResult:
        """J. Logging Configuration"""
        logger.info("📝 Auditing logging...")
        issues = []
        
        # Check logs directory
        logs_path = self.project_root / "backend" / "logs"
        if not logs_path.exists():
            issues.append(AuditIssue(
                severity=Severity.WARNING,
                category="logging",
                file_path="backend/logs",
                line_number=None,
                message="Logs directory missing",
                suggestion="Create logs directory"
            ))
        else:
            # Check log file sizes
            for log_file in logs_path.glob("*.log"):
                size_mb = log_file.stat().st_size / (1024 * 1024)
                if size_mb > 100:
                    issues.append(AuditIssue(
                        severity=Severity.WARNING,
                        category="logging",
                        file_path=str(log_file.relative_to(self.project_root)),
                        line_number=None,
                        message=f"Log file is large ({size_mb:.1f}MB)",
                        suggestion="Implement log rotation"
                    ))
        
        status = "✅ PASS" if not issues else f"⚠️  WARNING ({len(issues)} issues)"
        score = max(0, 100 - len(issues) * 10)
        
        return AuditResult(
            category="Logging",
            status=status,
            score=score,
            issues=issues,
            details={}
        )
    
    def audit_testing(self) -> AuditResult:
        """K. Testing Coverage"""
        logger.info("🧪 Auditing testing...")
        issues = []
        
        # Check for test files
        test_files = list(self.project_root.glob("backend/tests/**/*.py"))
        if not test_files:
            issues.append(AuditIssue(
                severity=Severity.WARNING,
                category="testing",
                file_path="backend/tests",
                line_number=None,
                message="No test files found",
                suggestion="Create test files for backend code"
            ))
        
        # Check frontend tests
        frontend_tests = list(self.project_root.glob("frontend/src/**/*.test.{js,jsx,ts,tsx}"))
        if not frontend_tests:
            issues.append(AuditIssue(
                severity=Severity.WARNING,
                category="testing",
                file_path="frontend/src",
                line_number=None,
                message="No frontend test files found",
                suggestion="Create test files for React components"
            ))
        
        # Try to run tests if available
        try:
            result = subprocess.run(['pytest', '--cov=app', '--cov-report=term-missing'], 
                                  capture_output=True, text=True, cwd=self.project_root / "backend")
            if result.returncode == 0:
                # Parse coverage from output
                coverage_match = re.search(r'TOTAL\s+(\d+)%\s+(\d+)/(\d+)', result.stdout)
                if coverage_match:
                    coverage_percent = int(coverage_match.group(1))
                    if coverage_percent < 80:
                        issues.append(AuditIssue(
                            severity=Severity.WARNING,
                            category="testing",
                            file_path="backend",
                            line_number=None,
                            message=f"Test coverage is {coverage_percent}% (target: 80%)",
                            suggestion="Add more tests to improve coverage"
                        ))
        except FileNotFoundError:
            logger.warning("pytest not found, skipping test coverage analysis")
        
        status = "✅ PASS" if not issues else f"⚠️  WARNING ({len(issues)} issues)"
        score = max(0, 100 - len(issues) * 15)
        
        return AuditResult(
            category="Testing",
            status=status,
            score=score,
            issues=issues,
            details={"test_files": len(test_files) + len(frontend_tests)}
        )
    
    def audit_security(self) -> AuditResult:
        """L. Security Vulnerabilities"""
        logger.info("🔒 Auditing security...")
        issues = []
        
        # Check for hardcoded secrets
        secret_patterns = [
            r'api[_-]?key\s*=\s*["\'][^"\']+["\']',
            r'password\s*=\s*["\'][^"\']+["\']',
            r'secret\s*=\s*["\'][^"\']+["\']',
            r'token\s*=\s*["\'][^"\']+["\']',
            r'private[_-]?key\s*=\s*["\'][^"\']+["\']'
        ]
        
        for pattern in secret_patterns:
            for py_file in self.project_root.glob("backend/**/*.py"):
                with open(py_file, 'r', encoding='utf-8') as f:
                    content = f.read()
                    lines = content.split('\n')
                    for i, line in enumerate(lines, 1):
                        if re.search(pattern, line, re.IGNORECASE):
                            issues.append(AuditIssue(
                                severity=Severity.CRITICAL,
                                category="security",
                                file_path=str(py_file.relative_to(self.project_root)),
                                line_number=i,
                                message="Potential hardcoded secret detected",
                                suggestion="Use environment variables or Azure Key Vault"
                            ))
        
        # Check .gitignore for sensitive files
        gitignore_path = self.project_root / ".gitignore"
        if gitignore_path.exists():
            with open(gitignore_path, 'r') as f:
                gitignore_content = f.read()
                required_ignores = ['.env', '*.log', '__pycache__', '*.pkl']
                for ignore_pattern in required_ignores:
                    if ignore_pattern not in gitignore_content:
                        issues.append(AuditIssue(
                            severity=Severity.WARNING,
                            category="security",
                            file_path=".gitignore",
                            line_number=None,
                            message=f"Missing ignore pattern: {ignore_pattern}",
                            suggestion=f"Add {ignore_pattern} to .gitignore"
                        ))
        
        status = "✅ PASS" if not issues else f"🔴 CRITICAL ({len(issues)} issues)"
        score = max(0, 100 - len(issues) * 25)
        
        return AuditResult(
            category="Security",
            status=status,
            score=score,
            issues=issues,
            details={}
        )
    
    def audit_performance(self) -> AuditResult:
        """M. Performance Issues"""
        logger.info("⚡ Auditing performance...")
        issues = []
        
        # Check for large files
        for file_path in self.project_root.rglob("*"):
            if file_path.is_file():
                size_mb = file_path.stat().st_size / (1024 * 1024)
                if size_mb > 10:
                    issues.append(AuditIssue(
                        severity=Severity.WARNING,
                        category="performance",
                        file_path=str(file_path.relative_to(self.project_root)),
                        line_number=None,
                        message=f"Large file detected ({size_mb:.1f}MB)",
                        suggestion="Consider file optimization or compression"
                    ))
        
        status = "✅ PASS" if not issues else f"⚠️  WARNING ({len(issues)} issues)"
        score = max(0, 100 - len(issues) * 5)
        
        return AuditResult(
            category="Performance",
            status=status,
            score=score,
            issues=issues,
            details={}
        )
    
    def audit_documentation(self) -> AuditResult:
        """N. Documentation Check"""
        logger.info("📚 Auditing documentation...")
        issues = []
        
        # Check for required documentation files
        required_docs = [
            "README.md", "SECURITY.md", "PERFORMANCE.md", 
            "BACKUP_DISASTER_RECOVERY.md", "DOCKER.md"
        ]
        
        for doc_file in required_docs:
            doc_path = self.project_root / doc_file
            if not doc_path.exists():
                issues.append(AuditIssue(
                    severity=Severity.WARNING,
                    category="documentation",
                    file_path=doc_file,
                    line_number=None,
                    message=f"Documentation file missing: {doc_file}",
                    suggestion=f"Create {doc_file} with relevant information"
                ))
        
        status = "✅ PASS" if not issues else f"⚠️  WARNING ({len(issues)} issues)"
        score = max(0, 100 - len(issues) * 10)
        
        return AuditResult(
            category="Documentation",
            status=status,
            score=score,
            issues=issues,
            details={}
        )
    
    def calculate_overall_score(self):
        """Calculate overall project health score"""
        if not self.results:
            self.overall_score = 0
            return
        
        total_score = 0
        total_weight = 0
        
        # Weight different categories
        weights = {
            'file_structure': 10,
            'python_code': 15,
            'react_code': 10,
            'docker_config': 10,
            'dependencies': 20,
            'environment': 10,
            'api_endpoints': 10,
            'ml_models': 15,
            'storage': 5,
            'logging': 5,
            'testing': 10,
            'security': 25,
            'performance': 5,
            'documentation': 5
        }
        
        for category, result in self.results.items():
            weight = weights.get(category, 10)
            total_score += result.score * weight
            total_weight += weight
        
        self.overall_score = total_score / total_weight if total_weight > 0 else 0
        
        # Count total issues
        self.total_issues = sum(len(result.issues) for result in self.results.values())
    
    def generate_report(self) -> Dict[str, Any]:
        """Generate comprehensive audit report"""
        report = {
            'timestamp': datetime.datetime.now().isoformat(),
            'overall_score': round(self.overall_score, 1),
            'total_issues': self.total_issues,
            'results': {},
            'priority_issues': [],
            'statistics': {
                'total_files_scanned': 0,
                'total_lines_of_code': 0,
                'critical_issues': 0,
                'errors': 0,
                'warnings': 0,
                'info': 0
            }
        }
        
        # Process results
        for category, result in self.results.items():
            report['results'][category] = {
                'status': result.status,
                'score': result.score,
                'issues': [
                    {
                        'severity': issue.severity.value,
                        'file_path': issue.file_path,
                        'line_number': issue.line_number,
                        'message': issue.message,
                        'suggestion': issue.suggestion
                    }
                    for issue in result.issues
                ],
                'details': result.details
            }
            
            # Count issues by severity
            for issue in result.issues:
                if issue.severity == Severity.CRITICAL:
                    report['statistics']['critical_issues'] += 1
                elif issue.severity == Severity.ERROR:
                    report['statistics']['errors'] += 1
                elif issue.severity == Severity.WARNING:
                    report['statistics']['warnings'] += 1
                elif issue.severity == Severity.INFO:
                    report['statistics']['info'] += 1
        
        # Generate priority issues list
        all_issues = []
        for result in self.results.values():
            all_issues.extend(result.issues)
        
        # Sort by severity and category
        severity_order = {Severity.CRITICAL: 0, Severity.ERROR: 1, Severity.WARNING: 2, Severity.INFO: 3}
        all_issues.sort(key=lambda x: (severity_order[x.severity], x.category, x.file_path))
        
        report['priority_issues'] = [
            {
                'severity': issue.severity.value,
                'category': issue.category,
                'file_path': issue.file_path,
                'line_number': issue.line_number,
                'message': issue.message,
                'suggestion': issue.suggestion
            }
            for issue in all_issues[:20]  # Top 20 issues
        ]
        
        return report
    
    def print_report(self, report: Dict[str, Any]):
        """Print formatted audit report to console"""
        print("\n" + "="*60)
        print("🔍 PROJECT AUDIT REPORT")
        print("="*60)
        print(f"Generated: {report['timestamp']}")
        print(f"\nOVERALL HEALTH: {report['overall_score']}/100")
        
        if report['overall_score'] >= 90:
            print("🟢 EXCELLENT")
        elif report['overall_score'] >= 80:
            print("🟡 GOOD")
        elif report['overall_score'] >= 70:
            print("🟠 FAIR")
        else:
            print("🔴 NEEDS IMPROVEMENT")
        
        print(f"\nTotal Issues: {report['total_issues']}")
        print(f"Critical: {report['statistics']['critical_issues']}")
        print(f"Errors: {report['statistics']['errors']}")
        print(f"Warnings: {report['statistics']['warnings']}")
        print(f"Info: {report['statistics']['info']}")
        
        print("\n" + "="*60)
        print("📊 CATEGORY BREAKDOWN")
        print("="*60)
        
        for category, result in report['results'].items():
            status_emoji = {
                "✅ PASS": "✅",
                "⚠️  WARNING": "⚠️",
                "🔴 CRITICAL": "🔴",
                "❌ FAIL": "❌"
            }
            emoji = status_emoji.get(result['status'], "❓")
            print(f"{emoji} {result['status']}")
            print(f"   Score: {result['score']}/100")
            if result['issues']:
                print(f"   Issues: {len(result['issues'])}")
                for issue in result['issues'][:3]:  # Show first 3 issues
                    print(f"   - {issue['severity']}: {issue['message']}")
                if len(result['issues']) > 3:
                    print(f"   ... and {len(result['issues']) - 3} more")
            print()
        
        if report['priority_issues']:
            print("="*60)
            print("🎯 PRIORITY ACTION ITEMS")
            print("="*60)
            for i, issue in enumerate(report['priority_issues'][:10], 1):
                print(f"{i}. [{issue['severity']}] {issue['message']}")
                if issue['suggestion']:
                    print(f"   💡 {issue['suggestion']}")
                print(f"   📁 {issue['file_path']}")
                if issue['line_number']:
                    print(f"   📍 Line {issue['line_number']}")
                print()
        
        print("="*60)
        print("📈 STATISTICS")
        print("="*60)
        print(f"Total Files Scanned: {report['statistics']['total_files_scanned']}")
        print(f"Total Lines of Code: {report['statistics']['total_lines_of_code']}")
        print(f"Critical Issues: {report['statistics']['critical_issues']}")
        print(f"Errors: {report['statistics']['errors']}")
        print(f"Warnings: {report['statistics']['warnings']}")
        print(f"Info: {report['statistics']['info']}")
        
        print(f"\nReport saved to: reports/audit-{datetime.datetime.now().strftime('%Y-%m-%d')}.json")

def main():
    parser = argparse.ArgumentParser(description='Comprehensive Project Audit')
    parser.add_argument('--output', choices=['console', 'html', 'json'], default='console',
                       help='Output format')
    parser.add_argument('--category', help='Audit specific category only')
    parser.add_argument('--ci', action='store_true', help='CI mode (exit with error code on critical issues)')
    parser.add_argument('--fail-on-critical', action='store_true', help='Exit with error code on critical issues')
    
    args = parser.parse_args()
    
    # Create reports directory
    reports_dir = Path("reports")
    reports_dir.mkdir(exist_ok=True)
    
    # Run audit
    auditor = ProjectAuditor()
    
    if args.category:
        # Audit specific category
        method_name = f"audit_{args.category}"
        if hasattr(auditor, method_name):
            method = getattr(auditor, method_name)
            result = method()
            auditor.results[args.category] = result
            auditor.calculate_overall_score()
            report = auditor.generate_report()
        else:
            print(f"Unknown category: {args.category}")
            sys.exit(1)
    else:
        # Full audit
        report = auditor.run_full_audit()
    
    # Output results
    if args.output == 'console':
        auditor.print_report(report)
    elif args.output == 'json':
        output_file = reports_dir / f"audit-{datetime.datetime.now().strftime('%Y-%m-%d')}.json"
        with open(output_file, 'w') as f:
            json.dump(report, f, indent=2)
        print(f"Report saved to: {output_file}")
    elif args.output == 'html':
        # Generate HTML report
        html_file = reports_dir / f"audit-{datetime.datetime.now().strftime('%Y-%m-%d')}.html"
        generate_html_report(report, html_file)
        print(f"HTML report saved to: {html_file}")
    
    # Exit with error code if critical issues found
    if args.ci or args.fail_on_critical:
        if report['statistics']['critical_issues'] > 0:
            print(f"\n❌ {report['statistics']['critical_issues']} critical issues found!")
            sys.exit(1)
        else:
            print("\n✅ No critical issues found!")
            sys.exit(0)

def generate_html_report(report: Dict[str, Any], output_file: Path):
    """Generate HTML audit report"""
    html_content = f"""
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Project Audit Report</title>
        <style>
            body {{ font-family: Arial, sans-serif; margin: 20px; background-color: #f5f5f5; }}
            .container {{ max-width: 1200px; margin: 0 auto; background: white; padding: 20px; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }}
            .header {{ text-align: center; margin-bottom: 30px; }}
            .score {{ font-size: 3em; font-weight: bold; margin: 20px 0; }}
            .excellent {{ color: #28a745; }}
            .good {{ color: #ffc107; }}
            .fair {{ color: #fd7e14; }}
            .poor {{ color: #dc3545; }}
            .category {{ margin: 20px 0; padding: 15px; border-left: 4px solid #007bff; background: #f8f9fa; }}
            .issue {{ margin: 10px 0; padding: 10px; border-radius: 4px; }}
            .critical {{ background: #f8d7da; border-left: 4px solid #dc3545; }}
            .error {{ background: #f8d7da; border-left: 4px solid #dc3545; }}
            .warning {{ background: #fff3cd; border-left: 4px solid #ffc107; }}
            .info {{ background: #d1ecf1; border-left: 4px solid #17a2b8; }}
            .stats {{ display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 20px; margin: 20px 0; }}
            .stat-card {{ padding: 15px; background: #e9ecef; border-radius: 4px; text-align: center; }}
            .priority {{ background: #fff3cd; padding: 15px; border-radius: 4px; margin: 20px 0; }}
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <h1>🔍 Project Audit Report</h1>
                <p>Generated: {report['timestamp']}</p>
                <div class="score {'excellent' if report['overall_score'] >= 90 else 'good' if report['overall_score'] >= 80 else 'fair' if report['overall_score'] >= 70 else 'poor'}">
                    {report['overall_score']}/100
                </div>
            </div>
            
            <div class="stats">
                <div class="stat-card">
                    <h3>Total Issues</h3>
                    <p>{report['total_issues']}</p>
                </div>
                <div class="stat-card">
                    <h3>Critical</h3>
                    <p>{report['statistics']['critical_issues']}</p>
                </div>
                <div class="stat-card">
                    <h3>Errors</h3>
                    <p>{report['statistics']['errors']}</p>
                </div>
                <div class="stat-card">
                    <h3>Warnings</h3>
                    <p>{report['statistics']['warnings']}</p>
                </div>
            </div>
            
            <h2>📊 Category Breakdown</h2>
    """
    
    for category, result in report['results'].items():
        html_content += f"""
            <div class="category">
                <h3>{result['status']} {category.replace('_', ' ').title()}</h3>
                <p>Score: {result['score']}/100</p>
        """
        
        if result['issues']:
            html_content += "<h4>Issues:</h4>"
            for issue in result['issues']:
                severity_class = issue['severity'].lower()
                html_content += f"""
                <div class="issue {severity_class}">
                    <strong>{issue['severity']}</strong>: {issue['message']}
                    <br><small>File: {issue['file_path']}</small>
                    {f"<br><small>Line: {issue['line_number']}</small>" if issue['line_number'] else ""}
                    {f"<br><small>💡 {issue['suggestion']}</small>" if issue['suggestion'] else ""}
                </div>
                """
        
        html_content += "</div>"
    
    if report['priority_issues']:
        html_content += """
            <h2>🎯 Priority Action Items</h2>
            <div class="priority">
        """
        for i, issue in enumerate(report['priority_issues'][:10], 1):
            html_content += f"""
                <div class="issue {issue['severity'].lower()}">
                    <strong>{i}. [{issue['severity']}]</strong> {issue['message']}
                    <br><small>File: {issue['file_path']}</small>
                    {f"<br><small>Line: {issue['line_number']}</small>" if issue['line_number'] else ""}
                    {f"<br><small>💡 {issue['suggestion']}</small>" if issue['suggestion'] else ""}
                </div>
            """
        html_content += "</div>"
    
    html_content += """
        </div>
    </body>
    </html>
    """
    
    with open(output_file, 'w') as f:
        f.write(html_content)

if __name__ == "__main__":
    main()

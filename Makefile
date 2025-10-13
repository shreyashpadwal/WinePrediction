# Wine Quality Prediction - Makefile
# Provides convenient commands for development, testing, and deployment

.PHONY: help install build test lint format audit fix clean dev prod deploy

# Default target
help:
	@echo "🍷 Wine Quality Prediction - Available Commands"
	@echo "=============================================="
	@echo ""
	@echo "Development:"
	@echo "  make install     - Install all dependencies"
	@echo "  make dev         - Start development environment"
	@echo "  make build       - Build Docker images"
	@echo "  make test        - Run all tests"
	@echo "  make lint        - Run linting checks"
	@echo "  make format      - Format code"
	@echo ""
	@echo "Audit & Quality:"
	@echo "  make audit       - Run comprehensive project audit"
	@echo "  make audit-quick - Run quick health check"
	@echo "  make fix         - Auto-fix common issues"
	@echo "  make security    - Run security audit"
	@echo ""
	@echo "Deployment:"
	@echo "  make prod        - Start production environment"
	@echo "  make deploy      - Deploy to Azure"
	@echo "  make backup      - Create backup"
	@echo ""
	@echo "Maintenance:"
	@echo "  make clean       - Clean up temporary files"
	@echo "  make logs        - View logs"
	@echo "  make health      - Check system health"
	@echo ""

# Install dependencies
install:
	@echo "📦 Installing dependencies..."
	@echo "Installing Python dependencies..."
	pip install -r backend/requirements.txt
	pip install -r scripts/requirements.txt
	@echo "Installing Node.js dependencies..."
	cd frontend && npm install
	@echo "✅ Dependencies installed"

# Build Docker images
build:
	@echo "🐳 Building Docker images..."
	docker-compose build
	@echo "✅ Docker images built"

# Start development environment
dev:
	@echo "🚀 Starting development environment..."
	docker-compose -f docker-compose.dev.yml up -d
	@echo "✅ Development environment started"
	@echo "Backend: http://localhost:8000"
	@echo "Frontend: http://localhost:3000"
	@echo "API Docs: http://localhost:8000/docs"

# Start production environment
prod:
	@echo "🚀 Starting production environment..."
	docker-compose up -d
	@echo "✅ Production environment started"
	@echo "Backend: http://localhost:8000"
	@echo "Frontend: http://localhost:80"

# Run tests
test:
	@echo "🧪 Running tests..."
	@echo "Running backend tests..."
	cd backend && python -m pytest tests/ -v --cov=app --cov-report=term-missing
	@echo "Running frontend tests..."
	cd frontend && npm test -- --coverage
	@echo "✅ Tests completed"

# Run linting
lint:
	@echo "🔍 Running linting checks..."
	@echo "Linting Python code..."
	cd backend && python -m flake8 app/ --max-line-length=88
	cd backend && python -m pylint app/ --disable=C0114,C0116
	@echo "Linting JavaScript/TypeScript code..."
	cd frontend && npm run lint
	@echo "✅ Linting completed"

# Format code
format:
	@echo "🎨 Formatting code..."
	@echo "Formatting Python code..."
	cd backend && python -m black app/ --line-length=88
	cd backend && python -m isort app/ --profile=black
	@echo "Formatting JavaScript/TypeScript code..."
	cd frontend && npm run format
	@echo "✅ Code formatted"

# Run comprehensive audit
audit:
	@echo "🔍 Running comprehensive project audit..."
	powershell -ExecutionPolicy Bypass -File scripts/simple-audit.ps1
	@echo "✅ Audit completed"
	@echo "Report saved to: reports/audit-$(shell date +%Y-%m-%d).txt"

# Run quick health check
audit-quick:
	@echo "🏥 Running quick health check..."
	scripts/quick-health-check.bat
	@echo "✅ Health check completed"

# Auto-fix common issues
fix:
	@echo "🔧 Auto-fixing common issues..."
	scripts/fix-common-issues.bat
	@echo "✅ Common issues fixed"

# Run security audit
security:
	@echo "🔒 Running security audit..."
	python scripts/audit-project.py --category security --output console
	@echo "✅ Security audit completed"

# Deploy to Azure
deploy:
	@echo "☁️  Deploying to Azure..."
	@echo "Setting up Azure resources..."
	bash azure/acr-setup.sh
	@echo "Building and pushing images..."
	bash azure/push-to-acr.sh
	@echo "Deploying backend..."
	bash azure/backend-appservice.sh
	@echo "Deploying frontend..."
	bash azure/frontend-static-webapp.sh
	@echo "✅ Deployment completed"

# Create backup
backup:
	@echo "💾 Creating backup..."
	bash azure/backup-script.sh
	@echo "✅ Backup completed"

# Clean up temporary files
clean:
	@echo "🧹 Cleaning up temporary files..."
	find . -type f -name "*.pyc" -delete
	find . -type d -name "__pycache__" -delete
	find . -type d -name ".pytest_cache" -delete
	find . -type f -name "*.log" -delete
	docker system prune -f
	@echo "✅ Cleanup completed"

# View logs
logs:
	@echo "📝 Viewing logs..."
	docker-compose logs -f

# Check system health
health:
	@echo "🏥 Checking system health..."
	scripts/quick-health-check.bat

# Continuous audit (for cron)
audit-continuous:
	@echo "🔄 Running continuous audit..."
	scripts/continuous-audit.bat

# Update dependencies
update:
	@echo "📦 Updating dependencies..."
	@echo "Updating Python dependencies..."
	cd backend && pip install --upgrade -r requirements.txt
	@echo "Updating Node.js dependencies..."
	cd frontend && npm update
	@echo "✅ Dependencies updated"

# Generate documentation
docs:
	@echo "📚 Generating documentation..."
	@echo "Generating API documentation..."
	cd backend && python -c "import app.main; print('API docs available at: http://localhost:8000/docs')"
	@echo "✅ Documentation generated"

# Run performance tests
perf:
	@echo "⚡ Running performance tests..."
	@echo "Testing backend performance..."
	ab -n 1000 -c 10 http://localhost:8000/api/v1/prediction/health
	@echo "Testing frontend performance..."
	ab -n 1000 -c 10 http://localhost:80
	@echo "✅ Performance tests completed"

# Setup development environment
setup:
	@echo "🛠️  Setting up development environment..."
	@echo "Creating necessary directories..."
	mkdir -p backend/logs backend/saved_models data/raw data/processed docs scripts reports
	@echo "Copying environment files..."
	cp backend/.env.example backend/.env
	@echo "Installing dependencies..."
	make install
	@echo "Building Docker images..."
	make build
	@echo "✅ Development environment setup completed"

# Reset development environment
reset:
	@echo "🔄 Resetting development environment..."
	docker-compose down -v
	docker system prune -f
	make clean
	make setup
	@echo "✅ Development environment reset"

# Show project status
status:
	@echo "📊 Project Status"
	@echo "================"
	@echo "Docker containers:"
	docker-compose ps
	@echo ""
	@echo "Backend health:"
	curl -s http://localhost:8000/api/v1/prediction/health || echo "Backend not running"
	@echo ""
	@echo "Frontend health:"
	curl -s http://localhost:80 || echo "Frontend not running"
	@echo ""
	@echo "Recent logs:"
	docker-compose logs --tail=10

# Run specific test category
test-backend:
	@echo "🧪 Running backend tests..."
	cd backend && python -m pytest tests/ -v

test-frontend:
	@echo "🧪 Running frontend tests..."
	cd frontend && npm test

test-integration:
	@echo "🧪 Running integration tests..."
	python scripts/test-integration.py

# Run specific audit category
audit-python:
	@echo "🐍 Auditing Python code..."
	python scripts/audit-project.py --category python_code

audit-react:
	@echo "⚛️  Auditing React code..."
	python scripts/audit-project.py --category react_code

audit-docker:
	@echo "🐳 Auditing Docker configuration..."
	python scripts/audit-project.py --category docker_config

audit-deps:
	@echo "📦 Auditing dependencies..."
	python scripts/audit-project.py --category dependencies

# Security specific commands
security-scan:
	@echo "🔒 Running security scan..."
	cd backend && python -m bandit -r app/
	cd frontend && npm audit

security-fix:
	@echo "🔒 Fixing security issues..."
	cd backend && pip install --upgrade -r requirements.txt
	cd frontend && npm audit fix

# Performance specific commands
perf-backend:
	@echo "⚡ Testing backend performance..."
	ab -n 1000 -c 10 http://localhost:8000/api/v1/prediction/health

perf-frontend:
	@echo "⚡ Testing frontend performance..."
	ab -n 1000 -c 10 http://localhost:80

perf-prediction:
	@echo "⚡ Testing prediction endpoint performance..."
	curl -X POST http://localhost:8000/api/v1/prediction/predict \
		-H "Content-Type: application/json" \
		-d '{"fixed_acidity": 7.4, "volatile_acidity": 0.7, "citric_acid": 0.0, "residual_sugar": 1.9, "chlorides": 0.076, "free_sulfur_dioxide": 11.0, "total_sulfur_dioxide": 34.0, "density": 0.9978, "ph": 3.51, "sulphates": 0.56, "alcohol": 9.4}' \
		-w "Time: %{time_total}s\n" -o /dev/null -s

# Database specific commands (if applicable)
db-migrate:
	@echo "🗄️  Running database migrations..."
	cd backend && python -m alembic upgrade head

db-seed:
	@echo "🌱 Seeding database..."
	cd backend && python scripts/seed_database.py

# Monitoring commands
monitor:
	@echo "📊 Starting monitoring..."
	docker-compose logs -f

monitor-backend:
	@echo "📊 Monitoring backend..."
	docker-compose logs -f backend

monitor-frontend:
	@echo "📊 Monitoring frontend..."
	docker-compose logs -f frontend

# Backup and restore commands
backup-full:
	@echo "💾 Creating full backup..."
	bash azure/backup-script.sh
	@echo "Backing up Docker volumes..."
	docker run --rm -v winequality_data:/data -v $(PWD):/backup alpine tar czf /backup/docker-volumes-backup.tar.gz -C /data .

restore:
	@echo "🔄 Restoring from backup..."
	bash azure/restore-script.sh
	@echo "Restoring Docker volumes..."
	docker run --rm -v winequality_data:/data -v $(PWD):/backup alpine tar xzf /backup/docker-volumes-backup.tar.gz -C /data

# Development utilities
shell-backend:
	@echo "🐍 Opening backend shell..."
	docker-compose exec backend bash

shell-frontend:
	@echo "⚛️  Opening frontend shell..."
	docker-compose exec frontend sh

# CI/CD specific commands
ci-test:
	@echo "🔄 Running CI tests..."
	make test
	make lint
	make security-scan
	make audit-quick

ci-deploy:
	@echo "🚀 Running CI deployment..."
	make build
	make test
	make deploy

# Help for specific categories
help-dev:
	@echo "🛠️  Development Commands"
	@echo "======================"
	@echo "  make setup     - Set up development environment"
	@echo "  make dev       - Start development environment"
	@echo "  make test      - Run all tests"
	@echo "  make lint      - Run linting checks"
	@echo "  make format    - Format code"
	@echo "  make clean     - Clean up temporary files"

help-audit:
	@echo "🔍 Audit Commands"
	@echo "================"
	@echo "  make audit     - Run comprehensive audit"
	@echo "  make audit-quick - Run quick health check"
	@echo "  make fix       - Auto-fix common issues"
	@echo "  make security  - Run security audit"

help-deploy:
	@echo "🚀 Deployment Commands"
	@echo "====================="
	@echo "  make build     - Build Docker images"
	@echo "  make prod      - Start production environment"
	@echo "  make deploy    - Deploy to Azure"
	@echo "  make backup    - Create backup"
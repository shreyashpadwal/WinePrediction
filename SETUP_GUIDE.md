# 🍷 Wine Quality Prediction Project - Complete Setup Guide

## 📋 Table of Contents
1. [Prerequisites](#prerequisites)
2. [Project Setup](#project-setup)
3. [Backend Setup](#backend-setup)
4. [Frontend Setup](#frontend-setup)
5. [Docker Setup](#docker-setup)
6. [Model Training](#model-training)
7. [Testing & Verification](#testing--verification)
8. [Troubleshooting](#troubleshooting)
9. [Production Deployment](#production-deployment)

---

## 🛠️ Prerequisites

### Required Software Installation

#### 1. Python 3.10+ 
- **Download**: [Python Official Website](https://www.python.org/downloads/)
- **Installation Steps**:
  1. Download Python 3.10+ for your operating system
  2. Run the installer with "Add Python to PATH" checked
  3. Verify installation: `python --version` or `python3 --version`
  4. Install pip if not included: `python -m ensurepip --upgrade`

#### 2. Node.js 18+
- **Download**: [Node.js Official Website](https://nodejs.org/)
- **Installation Steps**:
  1. Download Node.js 18+ LTS version
  2. Run the installer (includes npm)
  3. Verify installation: `node --version` and `npm --version`

#### 3. Docker Desktop
- **Download**: [Docker Desktop](https://www.docker.com/products/docker-desktop/)
- **Installation Steps**:
  1. Download Docker Desktop for your OS
  2. Install and start Docker Desktop
  3. Verify installation: `docker --version` and `docker-compose --version`
  4. Ensure Docker daemon is running

#### 4. Git
- **Download**: [Git Official Website](https://git-scm.com/downloads)
- **Installation Steps**:
  1. Download Git for your operating system
  2. Run the installer with default settings
  3. Verify installation: `git --version`

#### 5. Visual Studio Code (Recommended)
- **Download**: [VS Code](https://code.visualstudio.com/)
- **Recommended Extensions**:
  - Python
  - TypeScript and JavaScript Language Features
  - Docker
  - GitLens
  - Thunder Client (for API testing)

#### 6. Azure CLI (Optional - for Azure deployment)
- **Download**: [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
- **Installation**: Follow platform-specific instructions

---

## 📁 Project Setup

### 1. Clone/Copy the Project

#### Option A: Git Clone (if repository is available)
```bash
git clone <repository-url>
cd WinePrediction
```

#### Option B: Copy Project Folder
1. Copy the entire `WinePrediction` folder to your desired location
2. Navigate to the project directory:
   ```bash
   cd WinePrediction
   ```

### 2. Verify Project Structure

Ensure the following structure exists:
```
WinePrediction/
├── backend/
│   ├── app/
│   ├── saved_models/
│   ├── requirements.txt
│   ├── Dockerfile
│   └── .env.example
├── frontend/
│   ├── src/
│   ├── package.json
│   ├── Dockerfile
│   └── .env.example
├── scripts/
├── docs/
├── docker-compose.yml
├── Makefile
└── README.md
```

### 3. Check System Requirements

Run the verification script:
```bash
# Windows
scripts\verify-setup.bat

# Linux/Mac
bash scripts/verify-setup.sh
```

---

## 🐍 Backend Setup

### 1. Navigate to Backend Directory
```bash
cd backend
```

### 2. Create Python Virtual Environment

#### Windows:
```bash
python -m venv venv
venv\Scripts\activate
```

#### Mac/Linux:
```bash
python3 -m venv venv
source venv/bin/activate
```

### 3. Install Dependencies
```bash
pip install --upgrade pip
pip install -r requirements.txt
```

### 4. Create Environment Configuration

Copy the example environment file:
```bash
# Windows
copy .env.example .env

# Mac/Linux
cp .env.example .env
```

Edit `.env` file with your configuration:
```env
# Application Configuration
ENVIRONMENT=development
HOST=0.0.0.0
PORT=8000
LOG_LEVEL=INFO

# Google Gemini AI (Optional)
GEMINI_API_KEY=your_gemini_api_key_here

# Model Configuration
MODEL_PATH=./saved_models
MODEL_VERSION=1.0.0

# Database Configuration (if applicable)
DATABASE_URL=sqlite:///./wine_prediction.db

# Security
SECRET_KEY=your-secret-key-here
DEBUG=True

# CORS Configuration
CORS_ORIGINS=["http://localhost:3000", "http://localhost:5173"]

# Logging
LOG_FILE=./logs/app.log
LOG_MAX_SIZE=10MB
LOG_BACKUP_COUNT=5
```

### 5. Verify Model Files

Check if model files exist in `saved_models/`:
```bash
ls saved_models/
```

If no model files exist, you'll need to train models (see [Model Training](#model-training) section).

### 6. Run Backend Server

#### Development Mode:
```bash
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

#### Production Mode:
```bash
uvicorn app.main:app --host 0.0.0.0 --port 8000
```

### 7. Test Backend

Open your browser and visit:
- **API Documentation**: http://localhost:8000/docs
- **Health Check**: http://localhost:8000/api/v1/prediction/health
- **Root Endpoint**: http://localhost:8000/

---

## ⚛️ Frontend Setup

### 1. Navigate to Frontend Directory
```bash
cd ../frontend
```

### 2. Install Dependencies
```bash
npm install
```

### 3. Create Environment Configuration

Create `.env` file:
```bash
# Windows
echo VITE_API_URL=http://localhost:8000/api/v1 > .env

# Mac/Linux
echo "VITE_API_URL=http://localhost:8000/api/v1" > .env
```

Or manually create `.env` file with:
```env
# API Configuration
VITE_API_URL=http://localhost:8000/api/v1

# Environment
VITE_ENVIRONMENT=development

# Debug Mode
VITE_DEBUG=true
```

### 4. Run Frontend Development Server
```bash
npm run dev
```

### 5. Test Frontend

Open your browser and visit:
- **Frontend Application**: http://localhost:5173
- **Health Check**: http://localhost:5173/health

---

## 🐳 Docker Setup

### 1. Build Docker Images
```bash
# From project root
docker-compose build
```

### 2. Run All Services
```bash
docker-compose up -d
```

### 3. Check Container Status
```bash
docker-compose ps
```

### 4. View Logs
```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f backend
docker-compose logs -f frontend
```

### 5. Test Docker Setup

Open your browser and visit:
- **Frontend**: http://localhost:80
- **Backend API**: http://localhost:8000
- **API Documentation**: http://localhost:8000/docs

### 6. Stop Services
```bash
docker-compose down
```

---

## 🤖 Model Training

If model files are missing, train them using the Jupyter notebook:

### 1. Install Jupyter (if not already installed)
```bash
pip install jupyter
```

### 2. Start Jupyter Notebook
```bash
cd notebooks
jupyter notebook
```

### 3. Run Model Training
1. Open `02_model_training.ipynb`
2. Run all cells to train models
3. Models will be saved to `backend/saved_models/`

### 4. Verify Model Files
```bash
ls backend/saved_models/
```

Expected files:
- `best_model.pkl`
- `scaler.pkl`
- `label_encoder.pkl`
- `model_info.json`

---

## ✅ Testing & Verification

### 1. Backend API Tests
```bash
cd backend
python -m pytest tests/ -v
```

### 2. Frontend Tests
```bash
cd frontend
npm test
```

### 3. Integration Tests
```bash
# From project root
python scripts/test-integration.py
```

### 4. Manual API Testing

#### Test Health Endpoint:
```bash
curl http://localhost:8000/api/v1/prediction/health
```

#### Test Prediction Endpoint:
```bash
curl -X POST "http://localhost:8000/api/v1/prediction/predict" \
     -H "Content-Type: application/json" \
     -d '{
       "fixed_acidity": 7.4,
       "volatile_acidity": 0.7,
       "citric_acid": 0.0,
       "residual_sugar": 1.9,
       "chlorides": 0.076,
       "free_sulfur_dioxide": 11.0,
       "total_sulfur_dioxide": 34.0,
       "density": 0.9978,
       "ph": 3.51,
       "sulphates": 0.56,
       "alcohol": 9.4
     }'
```

### 5. Frontend Testing
1. Open http://localhost:5173
2. Fill out the wine quality form
3. Submit and verify prediction results
4. Test model comparison feature

---

## 🔧 Troubleshooting

### Common Issues and Solutions

#### 1. Port Already in Use
**Error**: `Port 8000 is already in use`

**Solutions**:
```bash
# Find process using port 8000
# Windows
netstat -ano | findstr :8000

# Mac/Linux
lsof -i :8000

# Kill the process or use different port
# Windows
taskkill /PID <process_id> /F

# Mac/Linux
kill -9 <process_id>
```

#### 2. Python Version Mismatch
**Error**: `Python version not found` or `Module not found`

**Solutions**:
```bash
# Check Python version
python --version

# Use python3 if needed
python3 --version

# Update PATH or use full path
# Windows: Add Python to PATH in system settings
# Mac/Linux: Add to ~/.bashrc or ~/.zshrc
export PATH="/usr/local/bin/python3:$PATH"
```

#### 3. Missing Environment Variables
**Error**: `Environment variable not set`

**Solutions**:
1. Check `.env` file exists in backend directory
2. Verify all required variables are set
3. Restart the application after changes
4. Check variable names match exactly

#### 4. Module Not Found Errors
**Error**: `ModuleNotFoundError: No module named 'xyz'`

**Solutions**:
```bash
# Ensure virtual environment is activated
# Windows
venv\Scripts\activate

# Mac/Linux
source venv/bin/activate

# Reinstall dependencies
pip install -r requirements.txt

# Check if module is in requirements.txt
pip list | grep module_name
```

#### 5. Docker Daemon Not Running
**Error**: `Cannot connect to the Docker daemon`

**Solutions**:
1. Start Docker Desktop application
2. Wait for Docker to fully start
3. Verify Docker is running: `docker --version`
4. Restart Docker Desktop if needed

#### 6. Permission Denied Errors
**Error**: `Permission denied` or `Access denied`

**Solutions**:
```bash
# Windows: Run as Administrator
# Mac/Linux: Use sudo for system operations
sudo chmod +x scripts/*.sh

# Fix file permissions
chmod 755 backend/
chmod 644 backend/*.py
```

#### 7. Model Files Missing
**Error**: `Model file not found`

**Solutions**:
1. Check if `saved_models/` directory exists
2. Run model training notebook
3. Verify model files are generated
4. Check file permissions

#### 8. Frontend Build Errors
**Error**: `Module not found` in frontend

**Solutions**:
```bash
# Clear node_modules and reinstall
rm -rf node_modules package-lock.json
npm install

# Check Node.js version
node --version

# Update dependencies
npm update
```

#### 9. CORS Errors
**Error**: `CORS policy` errors in browser

**Solutions**:
1. Check backend CORS configuration
2. Verify frontend URL matches CORS origins
3. Use correct API URL in frontend
4. Check if backend is running

#### 10. Database Connection Issues
**Error**: `Database connection failed`

**Solutions**:
1. Check database URL in `.env`
2. Verify database service is running
3. Check network connectivity
4. Verify credentials

### Debug Mode

Enable debug mode for detailed error information:

#### Backend Debug:
```bash
# Set debug environment variable
export DEBUG=True
# or add to .env file
DEBUG=True

# Run with debug logging
uvicorn app.main:app --reload --log-level debug
```

#### Frontend Debug:
```bash
# Enable debug mode
export VITE_DEBUG=true

# Check browser console for errors
# Use browser developer tools
```

---

## 🚀 Production Deployment

### 1. Environment Configuration

Update `.env` for production:
```env
ENVIRONMENT=production
DEBUG=False
LOG_LEVEL=WARNING
HOST=0.0.0.0
PORT=8000
```

### 2. Build for Production

#### Backend:
```bash
cd backend
pip install -r requirements.txt
```

#### Frontend:
```bash
cd frontend
npm run build
```

### 3. Docker Production

```bash
# Build production images
docker-compose -f docker-compose.prod.yml build

# Run production containers
docker-compose -f docker-compose.prod.yml up -d
```

### 4. Azure Deployment

If deploying to Azure:

```bash
# Install Azure CLI
# Login to Azure
az login

# Deploy using provided scripts
bash azure/deploy.sh
```

### 5. Health Monitoring

Set up monitoring:
```bash
# Use provided health check scripts
scripts/quick-health-check.bat

# Set up continuous monitoring
scripts/continuous-audit.bat
```

---

## 📚 Additional Resources

### Documentation
- [API Documentation](http://localhost:8000/docs) - Interactive API docs
- [Project README](README.md) - Project overview
- [Security Guidelines](SECURITY.md) - Security best practices
- [Performance Tips](PERFORMANCE.md) - Optimization guide

### Useful Commands

#### Development:
```bash
# Start development environment
make dev

# Run tests
make test

# Format code
make format

# Run linting
make lint
```

#### Audit & Quality:
```bash
# Run project audit
make audit

# Quick health check
make audit-quick

# Auto-fix issues
make fix
```

#### Docker:
```bash
# Build and start
docker-compose up --build

# View logs
docker-compose logs -f

# Stop services
docker-compose down

# Clean up
docker system prune -a
```

### Support

If you encounter issues:
1. Check this troubleshooting guide
2. Review error logs in `backend/logs/`
3. Run the audit system: `make audit`
4. Check project documentation
5. Verify all prerequisites are installed

---

## ✅ Setup Verification Checklist

- [ ] Python 3.10+ installed and working
- [ ] Node.js 18+ installed and working
- [ ] Docker Desktop installed and running
- [ ] Git installed and working
- [ ] Project folder copied/cloned
- [ ] Backend virtual environment created
- [ ] Backend dependencies installed
- [ ] Backend `.env` file configured
- [ ] Model files present in `saved_models/`
- [ ] Backend server running on port 8000
- [ ] Frontend dependencies installed
- [ ] Frontend `.env` file configured
- [ ] Frontend server running on port 5173
- [ ] API documentation accessible
- [ ] Health endpoints responding
- [ ] Prediction endpoint working
- [ ] Frontend form submitting successfully
- [ ] Docker containers building and running
- [ ] All tests passing
- [ ] Audit system working

---

**🎉 Congratulations!** Your Wine Quality Prediction project is now set up and ready to use!

**Last Updated**: October 12, 2025  
**Version**: 1.0.0  
**Maintainer**: Wine Quality Prediction Team

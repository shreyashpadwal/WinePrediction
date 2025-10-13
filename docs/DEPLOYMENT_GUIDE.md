# 🚀 Complete Deployment Guide

This comprehensive guide covers deploying the Wine Quality Prediction application from development to production on Azure.

## 📋 Prerequisites

### Required Tools
- **Azure CLI**: Command-line interface for Azure
- **Docker**: For building and managing containers
- **Git**: For version control
- **Node.js**: For frontend development
- **Python**: For backend development
- **Azure Account**: Free tier available

### Installation

#### Azure CLI Installation
```bash
# Windows
Invoke-WebRequest -Uri https://aka.ms/installazurecliwindows -OutFile .\AzureCLI.msi
Start-Process msiexec.exe -Wait -ArgumentList '/I AzureCLI.msi /quiet'

# macOS
brew install azure-cli

# Linux
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
```

#### Docker Installation
```bash
# Windows/macOS: Download Docker Desktop
# Linux
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
```

#### Node.js Installation
```bash
# Using Node Version Manager (recommended)
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
nvm install 18
nvm use 18
```

#### Python Installation
```bash
# Using pyenv (recommended)
curl https://pyenv.run | bash
pyenv install 3.10.0
pyenv global 3.10.0
```

## 🏗️ Architecture Overview

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Frontend      │    │   Backend       │    │   ML Models     │
│   (React SPA)   │◄──►│   (FastAPI)     │◄──►│   (Scikit-learn)│
│   Static Web    │    │   App Service    │    │   Container     │
│   Apps          │    │   Linux         │    │   Registry      │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Azure CDN     │    │   Redis Cache   │    │   Key Vault     │
│   (Global)      │    │   (Performance) │    │   (Secrets)     │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## 🚀 Quick Start Deployment

### 1. Clone Repository
```bash
git clone https://github.com/yourusername/wine-quality-prediction.git
cd wine-quality-prediction
```

### 2. Set Up Environment
```bash
# Copy environment template
cp backend/.env.example backend/.env
cp azure/env.docker.example azure/.env.azure

# Edit environment files with your values
# backend/.env - Add your GEMINI_API_KEY
# azure/.env.azure - Will be populated by setup scripts
```

### 3. Build and Test Locally
```bash
# Build Docker images
make build

# Start services locally
make up

# Test the application
curl http://localhost:8000/api/v1/prediction/health
curl http://localhost:80
```

### 4. Deploy to Azure
```bash
# Set up Azure resources
./azure/acr-setup.sh

# Build and push images
./azure/push-to-acr.sh

# Deploy backend
./azure/backend-appservice.sh

# Deploy frontend
./azure/frontend-static-webapp.sh
```

## 📁 Project Structure

```
wine-quality-prediction/
├── backend/                    # FastAPI backend
│   ├── app/                    # Application code
│   │   ├── main.py            # FastAPI app
│   │   ├── models/            # Pydantic models
│   │   ├── routes/            # API routes
│   │   ├── services/          # Business logic
│   │   └── utils/             # Utilities
│   ├── tests/                 # Backend tests
│   ├── Dockerfile             # Backend container
│   ├── requirements.txt       # Python dependencies
│   └── .env.example           # Environment template
├── frontend/                   # React frontend
│   ├── src/                   # Source code
│   │   ├── components/        # React components
│   │   ├── services/          # API services
│   │   ├── styles/            # CSS styles
│   │   └── types/             # TypeScript types
│   ├── public/                # Static assets
│   ├── Dockerfile             # Frontend container
│   ├── package.json           # Node dependencies
│   └── vite.config.ts        # Vite configuration
├── notebooks/                  # Jupyter notebooks
│   ├── 01_eda_preprocessing.ipynb
│   └── 02_model_training.ipynb
├── azure/                      # Azure deployment scripts
│   ├── acr-setup.sh           # Container registry setup
│   ├── backend-appservice.sh  # Backend deployment
│   ├── frontend-static-webapp.sh # Frontend deployment
│   ├── security-setup.sh      # Security configuration
│   ├── performance-setup.sh   # Performance optimization
│   └── backup-setup.sh        # Backup configuration
├── docs/                       # Documentation
│   ├── DEPLOYMENT_GUIDE.md    # This file
│   ├── AZURE_ARCHITECTURE.md  # Architecture documentation
│   └── RUNBOOK.md             # Operations runbook
├── docker-compose.yml          # Local development
├── docker-compose.dev.yml      # Development configuration
├── Makefile                    # Build automation
├── README.md                   # Project overview
├── SECURITY.md                 # Security documentation
├── PERFORMANCE.md              # Performance documentation
└── BACKUP_DISASTER_RECOVERY.md # Backup documentation
```

## 🔧 Step-by-Step Deployment

### Phase 1: Local Development Setup

#### 1.1 Backend Setup
```bash
cd backend

# Create virtual environment
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Set up environment variables
cp .env.example .env
# Edit .env with your GEMINI_API_KEY

# Run tests
pytest tests/

# Start development server
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

#### 1.2 Frontend Setup
```bash
cd frontend

# Install dependencies
npm install

# Set up environment variables
cp .env.example .env.local
# Edit .env.local with your API URL

# Run tests
npm test

# Start development server
npm run dev
```

#### 1.3 ML Model Training
```bash
# Start Jupyter notebook
jupyter notebook notebooks/

# Run notebooks in order:
# 1. 01_eda_preprocessing.ipynb
# 2. 02_model_training.ipynb

# Verify models are created
ls backend/saved_models/
```

### Phase 2: Docker Containerization

#### 2.1 Build Docker Images
```bash
# Build backend image
docker build -t wine-backend:latest ./backend

# Build frontend image
docker build -t wine-frontend:latest ./frontend

# Verify images
docker images | grep wine
```

#### 2.2 Test Docker Images
```bash
# Test backend
docker run -p 8000:8000 --env-file backend/.env wine-backend:latest

# Test frontend
docker run -p 3000:80 wine-frontend:latest

# Test with Docker Compose
docker-compose up --build
```

### Phase 3: Azure Infrastructure Setup

#### 3.1 Azure CLI Login
```bash
# Login to Azure
az login

# Set subscription
az account set --subscription "Your Subscription ID"

# Verify login
az account show
```

#### 3.2 Container Registry Setup
```bash
# Run ACR setup script
./azure/acr-setup.sh

# Verify ACR creation
az acr list --resource-group wine-quality-rg
```

#### 3.3 Push Images to ACR
```bash
# Build and push images
./azure/push-to-acr.sh

# Verify images in ACR
az acr repository list --name winequalityacr
```

### Phase 4: Backend Deployment

#### 4.1 App Service Deployment
```bash
# Deploy backend to App Service
./azure/backend-appservice.sh

# Verify deployment
az webapp show --name wine-quality-backend --resource-group wine-quality-rg
```

#### 4.2 Backend Configuration
```bash
# Set environment variables
az webapp config appsettings set \
  --name wine-quality-backend \
  --resource-group wine-quality-rg \
  --settings \
    GEMINI_API_KEY="your-api-key" \
    ENVIRONMENT="production" \
    LOG_LEVEL="INFO"

# Configure custom domain (optional)
az webapp config hostname add \
  --webapp-name wine-quality-backend \
  --resource-group wine-quality-rg \
  --hostname api.yourdomain.com
```

#### 4.3 Backend Testing
```bash
# Test health endpoint
curl https://wine-quality-backend.azurewebsites.net/api/v1/prediction/health

# Test API documentation
curl https://wine-quality-backend.azurewebsites.net/docs

# Test prediction endpoint
curl -X POST https://wine-quality-backend.azurewebsites.net/api/v1/prediction/predict \
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

### Phase 5: Frontend Deployment

#### 5.1 Static Web App Deployment
```bash
# Deploy frontend to Static Web Apps
./azure/frontend-static-webapp.sh

# Verify deployment
az staticwebapp show --name wine-quality-frontend --resource-group wine-quality-rg
```

#### 5.2 Frontend Configuration
```bash
# Set environment variables
az staticwebapp appsettings set \
  --name wine-quality-frontend \
  --resource-group wine-quality-rg \
  --setting-names \
    VITE_API_URL="https://wine-quality-backend.azurewebsites.net/api/v1"

# Configure custom domain (optional)
az staticwebapp hostname set \
  --name wine-quality-frontend \
  --resource-group wine-quality-rg \
  --hostname yourdomain.com
```

#### 5.3 Frontend Testing
```bash
# Test frontend
curl https://wine-quality-frontend.azurestaticapps.net

# Test API proxy
curl https://wine-quality-frontend.azurestaticapps.net/api/v1/prediction/health
```

### Phase 6: Security Configuration

#### 6.1 Security Setup
```bash
# Run security setup script
./azure/security-setup.sh

# Verify security configuration
az keyvault show --name wine-quality-vault --resource-group wine-quality-rg
```

#### 6.2 Security Testing
```bash
# Test SSL/TLS
openssl s_client -connect wine-quality-backend.azurewebsites.net:443

# Test security headers
curl -I https://wine-quality-backend.azurewebsites.net

# Test vulnerability scanning
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  aquasec/trivy image winequalityacr.azurecr.io/wine-backend:latest
```

### Phase 7: Performance Optimization

#### 7.1 Performance Setup
```bash
# Run performance setup script
./azure/performance-setup.sh

# Verify CDN configuration
az cdn profile show --name wine-quality-cdn --resource-group wine-quality-rg
```

#### 7.2 Performance Testing
```bash
# Run performance tests
./azure/performance-test.sh

# Test CDN
curl -I https://wine-quality-cdn.azureedge.net

# Test Redis cache
redis-cli -h wine-quality-cache.redis.cache.windows.net -p 6380 -a "your-key" ping
```

### Phase 8: Backup and Disaster Recovery

#### 8.1 Backup Setup
```bash
# Run backup setup script
./azure/backup-setup.sh

# Verify backup configuration
az backup vault show --name wine-quality-backup-vault --resource-group wine-quality-rg
```

#### 8.2 Backup Testing
```bash
# Test manual backup
./azure/backup-script.sh

# Test restore
./azure/restore-script.sh

# Test disaster recovery
./azure/disaster-recovery-plan.sh
```

## 🔍 Verification and Testing

### Health Checks
```bash
# Backend health
curl https://wine-quality-backend.azurewebsites.net/api/v1/prediction/health

# Frontend health
curl https://wine-quality-frontend.azurestaticapps.net/health

# Database health (if applicable)
curl https://wine-quality-backend.azurewebsites.net/api/v1/prediction/health
```

### Load Testing
```bash
# Install Apache Bench
# Ubuntu/Debian: sudo apt-get install apache2-utils
# macOS: brew install httpd
# Windows: Download from Apache website

# Test backend performance
ab -n 1000 -c 10 https://wine-quality-backend.azurewebsites.net/api/v1/prediction/health

# Test frontend performance
ab -n 1000 -c 10 https://wine-quality-frontend.azurestaticapps.net
```

### Security Testing
```bash
# SSL/TLS testing
sslscan wine-quality-backend.azurewebsites.net

# Security headers testing
curl -I https://wine-quality-backend.azurewebsites.net

# Vulnerability scanning
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  aquasec/trivy image winequalityacr.azurecr.io/wine-backend:latest
```

## 📊 Monitoring and Alerting

### Application Insights
```bash
# View Application Insights
az monitor app-insights component show \
  --app wine-quality-backend-insights \
  --resource-group wine-quality-rg
```

### Log Analytics
```bash
# Query logs
az monitor log-analytics query \
  --workspace wine-quality-logs \
  --analytics-query "requests | where timestamp > ago(1h) | limit 10"
```

### Alerts
```bash
# List alerts
az monitor metrics alert list --resource-group wine-quality-rg

# Test alert
az monitor metrics alert create \
  --name test-alert \
  --resource-group wine-quality-rg \
  --scopes /subscriptions/.../sites/wine-quality-backend \
  --condition "count 'HttpRequests' > 0" \
  --description "Test alert"
```

## 🚨 Troubleshooting

### Common Issues

#### 1. Azure CLI Not Found
```bash
# Install Azure CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Verify installation
az --version
```

#### 2. Docker Not Running
```bash
# Start Docker service
sudo systemctl start docker

# Verify Docker is running
docker info
```

#### 3. ACR Login Failed
```bash
# Re-login to ACR
az acr login --name winequalityacr

# Check ACR credentials
az acr credential show --name winequalityacr
```

#### 4. App Service Deployment Failed
```bash
# Check App Service logs
az webapp log tail --name wine-quality-backend --resource-group wine-quality-rg

# Check App Service status
az webapp show --name wine-quality-backend --resource-group wine-quality-rg --query "state"
```

#### 5. Static Web App Deployment Failed
```bash
# Check Static Web App status
az staticwebapp show --name wine-quality-frontend --resource-group wine-quality-rg --query "buildProperties"

# Check GitHub Actions workflow
# Go to GitHub repository > Actions tab
```

### Debug Commands
```bash
# Check Azure CLI version
az --version

# Check Docker version
docker --version

# Check ACR connectivity
az acr check-health --name winequalityacr

# Check App Service status
az webapp show --name wine-quality-backend --resource-group wine-quality-rg --query "state"

# Check Static Web App status
az staticwebapp show --name wine-quality-frontend --resource-group wine-quality-rg --query "buildProperties"
```

## 💰 Cost Optimization

### Free Tier Resources
- **Azure Container Registry**: 1GB storage free
- **App Service**: F1 tier (free) available
- **Static Web Apps**: Free tier available
- **Application Insights**: 5GB data free per month

### Estimated Monthly Costs
| Service | Tier | Monthly Cost |
|---------|------|--------------|
| App Service | B1 | $13.14 |
| Static Web Apps | Free | $0 |
| Container Registry | Basic | $5 |
| Application Insights | Pay-as-you-go | $2-5 |
| **Total** | | **$20-25** |

### Cost Optimization Tips
1. **Use Free Tier**: Start with free tier resources
2. **Set Budget Alerts**: Configure spending limits
3. **Monitor Usage**: Regular cost reviews
4. **Reserved Instances**: For predictable workloads
5. **Auto-scaling**: Scale down during low usage

## 🔄 CI/CD Pipeline

### GitHub Actions Workflow
```yaml
name: Deploy to Azure

on:
  push:
    branches: [ main ]

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v2
    
    - name: Azure Login
      uses: azure/login@v1
      with:
        creds: ${{ secrets.AZURE_CREDENTIALS }}
    
    - name: Build and Push to ACR
      run: |
        az acr build --registry winequalityacr --image wine-backend:latest ./backend
        az acr build --registry winequalityacr --image wine-frontend:latest ./frontend
    
    - name: Deploy to App Service
      run: |
        az webapp config container set --name wine-quality-backend --resource-group wine-quality-rg --docker-custom-image-name winequalityacr.azurecr.io/wine-backend:latest
```

### Azure DevOps Pipeline
```yaml
trigger:
  branches:
    include:
      - main

stages:
- stage: Build
  jobs:
  - job: BuildImages
    steps:
    - task: Docker@2
      displayName: 'Build backend image'
      inputs:
        command: 'build'
        dockerfile: 'backend/Dockerfile'
        tags: 'wine-backend:latest'

- stage: Deploy
  jobs:
  - deployment: DeployBackend
    steps:
    - task: AzureWebAppContainer@1
      displayName: 'Deploy Backend'
      inputs:
        azureSubscription: 'Azure Service Connection'
        appName: 'wine-quality-backend'
        containers: 'winequalityacr.azurecr.io/wine-backend:latest'
```

## 📚 Additional Resources

### Documentation
- [Azure Container Registry Documentation](https://docs.microsoft.com/en-us/azure/container-registry/)
- [Azure App Service Documentation](https://docs.microsoft.com/en-us/azure/app-service/)
- [Azure Static Web Apps Documentation](https://docs.microsoft.com/en-us/azure/static-web-apps/)
- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [React Documentation](https://reactjs.org/docs/)

### Tools and Utilities
- [Azure CLI Reference](https://docs.microsoft.com/en-us/cli/azure/)
- [Docker Documentation](https://docs.docker.com/)
- [Node.js Documentation](https://nodejs.org/docs/)
- [Python Documentation](https://docs.python.org/)

### Community Resources
- [Azure Community](https://azure.microsoft.com/en-us/community/)
- [FastAPI Community](https://fastapi.tiangolo.com/community/)
- [React Community](https://reactjs.org/community/support.html)

## 🆘 Support

### Internal Support
- **Development Team**: dev@yourdomain.com
- **DevOps Team**: devops@yourdomain.com
- **Security Team**: security@yourdomain.com
- **Management**: management@yourdomain.com

### External Support
- **Azure Support**: Azure portal support
- **GitHub Support**: GitHub support
- **Docker Support**: Docker support
- **Community Forums**: Stack Overflow, Reddit

## 🎯 Next Steps

### Post-Deployment
1. **Monitor Performance**: Set up monitoring and alerting
2. **Security Review**: Conduct security assessment
3. **Performance Testing**: Run load tests
4. **Backup Testing**: Test backup and recovery procedures
5. **Documentation Update**: Keep documentation current

### Continuous Improvement
1. **Regular Updates**: Keep dependencies updated
2. **Security Patches**: Apply security updates
3. **Performance Optimization**: Monitor and optimize
4. **Feature Development**: Add new features
5. **Scaling**: Scale as needed

---

**Document Version**: 1.0  
**Last Updated**: 2024-01-01  
**Next Review**: 2024-04-01  
**Approved By**: DevOps Team  
**Distribution**: Internal Use Only

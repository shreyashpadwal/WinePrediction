# 🐳 Docker Setup Guide

This guide covers the Docker containerization setup for the Wine Quality Prediction project.

## 📋 Overview

The project uses Docker Compose to orchestrate multiple services:
- **Backend**: FastAPI application with ML models
- **Frontend**: React SPA with Nginx
- **Redis**: Caching layer (for future use)

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Frontend      │    │    Backend      │    │     Redis       │
│   (Nginx)       │    │   (FastAPI)     │    │    (Cache)      │
│   Port: 80      │◄──►│   Port: 8000    │◄──►│   Port: 6379    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## 🚀 Quick Start

### Prerequisites

- Docker 20.10+
- Docker Compose 2.0+
- 2GB+ RAM available
- 5GB+ disk space

### 1. Clone and Setup

```bash
# Clone the repository
git clone <repository-url>
cd wine-quality-prediction

# Copy environment file
cp env.docker.example .env

# Edit .env with your values
nano .env
```

### 2. Build and Run

```bash
# Build all containers
make build

# Start all services
make up

# Or use docker-compose directly
docker-compose up --build
```

### 3. Access the Application

- **Frontend**: http://localhost:80
- **Backend API**: http://localhost:8000
- **API Documentation**: http://localhost:8000/docs

## 📁 File Structure

```
├── docker-compose.yml          # Main compose file
├── docker-compose.dev.yml      # Development overrides
├── Makefile                    # Common commands
├── env.docker.example          # Environment template
├── backend/
│   ├── Dockerfile              # Backend container
│   ├── .dockerignore           # Backend ignore rules
│   ├── docker-entrypoint.sh    # Backend startup script
│   └── healthcheck.py          # Health check script
└── frontend/
    ├── Dockerfile              # Frontend container
    ├── .dockerignore           # Frontend ignore rules
    ├── docker-entrypoint.sh    # Frontend startup script
    └── nginx.conf              # Nginx configuration
```

## 🔧 Configuration

### Environment Variables

Key environment variables in `.env`:

```bash
# Required
GEMINI_API_KEY=your_api_key_here
ENVIRONMENT=production
LOG_LEVEL=INFO

# Optional
VITE_API_URL=http://localhost:8000/api/v1
REDIS_HOST=redis
REDIS_PORT=6379
```

### Docker Compose Services

#### Backend Service

- **Image**: Built from `./backend/Dockerfile`
- **Port**: 8000
- **Health Check**: `/api/v1/prediction/health`
- **Volumes**: 
  - `backend-logs:/app/logs`
  - `backend-models:/app/saved_models`
- **Resources**: 1GB RAM, 0.5 CPU

#### Frontend Service

- **Image**: Built from `./frontend/Dockerfile`
- **Port**: 80
- **Health Check**: `/health`
- **Resources**: 256MB RAM, 0.25 CPU

#### Redis Service

- **Image**: `redis:7-alpine`
- **Port**: 6379
- **Health Check**: `redis-cli ping`
- **Resources**: 128MB RAM, 0.1 CPU

## 🛠️ Development

### Development Mode

For development with hot reload:

```bash
# Start in development mode
make dev

# Or manually
docker-compose -f docker-compose.yml -f docker-compose.dev.yml up
```

### Useful Commands

```bash
# View logs
make logs
make logs-backend
make logs-frontend

# Run tests
make test
make test-backend
make test-frontend

# Access container shells
make shell-backend
make shell-frontend

# Check status
make status
make health
```

## 🔒 Security Features

### Container Security

- **Non-root users**: Both containers run as non-root
- **Minimal base images**: Alpine Linux for smaller attack surface
- **Security headers**: Nginx configured with security headers
- **Resource limits**: CPU and memory limits set

### Network Security

- **Custom network**: Isolated `wine-network`
- **Internal communication**: Services communicate via internal network
- **Port exposure**: Only necessary ports exposed

### Image Security

- **Multi-stage builds**: Separate build and runtime stages
- **Layer optimization**: Minimal layers for faster builds
- **Dependency scanning**: Regular security updates

## 📊 Monitoring

### Health Checks

Each service has health checks:

```bash
# Check all services
make health

# Individual checks
curl http://localhost:8000/api/v1/prediction/health  # Backend
curl http://localhost/health                         # Frontend
```

### Logging

Structured logging with rotation:

```bash
# View logs
make logs

# Follow specific service
docker-compose logs -f backend
```

### Resource Monitoring

```bash
# View resource usage
make stats

# View image sizes
make images
```

## 🚀 Production Deployment

### Production Optimizations

1. **Multi-stage builds**: Reduced image sizes
2. **Resource limits**: Prevent resource exhaustion
3. **Health checks**: Automatic restart on failure
4. **Log rotation**: Prevent disk space issues
5. **Security headers**: Enhanced security

### Scaling

```bash
# Scale backend service
docker-compose up -d --scale backend=3

# Scale with load balancer (requires additional config)
```

### Backup

```bash
# Backup volumes
make backup

# Restore from backup
docker run --rm -v wine-prediction_backend-models:/data -v $(pwd)/backup:/backup alpine tar xzf /backup/backend-models-YYYYMMDD-HHMMSS.tar.gz -C /data
```

## 🐛 Troubleshooting

### Common Issues

#### Container Won't Start

```bash
# Check logs
make logs

# Check health
make health

# Restart services
make restart
```

#### Model Files Missing

```bash
# Ensure models are trained
cd notebooks
jupyter notebook 01_eda_preprocessing.ipynb
jupyter notebook 02_model_training.ipynb

# Copy models to backend
cp -r ../backend/saved_models/* ./backend/saved_models/
```

#### Port Conflicts

```bash
# Check port usage
netstat -tulpn | grep :8000
netstat -tulpn | grep :80

# Change ports in docker-compose.yml
```

#### Memory Issues

```bash
# Check resource usage
make stats

# Increase memory limits in docker-compose.yml
```

### Debug Mode

```bash
# Run with debug logging
ENVIRONMENT=development LOG_LEVEL=DEBUG docker-compose up

# Access container for debugging
make shell-backend
```

## 📈 Performance

### Optimization Tips

1. **Use .dockerignore**: Exclude unnecessary files
2. **Layer caching**: Order Dockerfile commands by change frequency
3. **Multi-stage builds**: Separate build and runtime
4. **Resource limits**: Set appropriate limits
5. **Health checks**: Quick startup verification

### Benchmarks

Expected performance:
- **Startup time**: < 30 seconds
- **API response**: < 200ms
- **Frontend load**: < 2 seconds
- **Memory usage**: < 1.5GB total

## 🔄 Updates

### Updating Images

```bash
# Pull latest images
make update

# Rebuild with latest code
make build-up
```

### Rolling Updates

```bash
# Update backend only
docker-compose up -d --no-deps backend

# Update frontend only
docker-compose up -d --no-deps frontend
```

## 📚 Additional Resources

- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Reference](https://docs.docker.com/compose/)
- [FastAPI Docker Guide](https://fastapi.tiangolo.com/deployment/docker/)
- [React Docker Guide](https://create-react-app.dev/docs/deployment/#docker)

## 🆘 Support

For issues with Docker setup:

1. Check the logs: `make logs`
2. Verify health: `make health`
3. Check resources: `make stats`
4. Review configuration: `.env` file
5. Create an issue with logs and configuration

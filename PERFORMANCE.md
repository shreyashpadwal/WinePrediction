# 🚀 Performance Optimization Guide

This guide covers comprehensive performance optimization strategies for the Wine Quality Prediction application deployed on Azure.

## 🏗️ Performance Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Azure CDN     │    │   Redis Cache   │    │   Auto-scaling   │
│   (Static)      │◄──►│   (API)         │◄──►│   (Dynamic)     │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Frontend      │    │   Backend API   │    │   Load Balancer  │
│   (React)       │    │   (FastAPI)     │    │   (Azure)       │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## 🎯 Performance Targets

### Backend API Performance
- **Response Time**: < 500ms (95th percentile)
- **Throughput**: > 1000 requests/minute
- **Availability**: > 99.9%
- **Error Rate**: < 0.1%
- **Concurrent Users**: > 100

### Frontend Performance
- **Lighthouse Score**: > 90
- **First Contentful Paint**: < 1.5s
- **Largest Contentful Paint**: < 2.5s
- **Cumulative Layout Shift**: < 0.1
- **Time to Interactive**: < 3s

### Infrastructure Performance
- **CPU Usage**: < 70% (average)
- **Memory Usage**: < 80% (average)
- **Network Latency**: < 100ms
- **Storage IOPS**: Optimized
- **Database Response**: < 50ms

## 🔧 Performance Optimization Strategies

### 1. Caching Strategy

#### Azure CDN
**Purpose**: Accelerate static asset delivery

**Configuration**:
```bash
# Create CDN profile
az cdn profile create \
  --name wine-quality-cdn \
  --resource-group wine-quality-rg \
  --sku Standard_Microsoft

# Create CDN endpoint
az cdn endpoint create \
  --name wine-quality-frontend-cdn \
  --profile-name wine-quality-cdn \
  --resource-group wine-quality-rg \
  --origin https://wine-quality-frontend.azurestaticapps.net
```

**Caching Rules**:
- **Static Assets**: 1 year cache
- **HTML Files**: 1 hour cache
- **API Responses**: No cache
- **Images**: 1 year cache with compression

#### Redis Cache
**Purpose**: Cache API responses and session data

**Configuration**:
```bash
# Create Redis cache
az redis create \
  --name wine-quality-cache \
  --resource-group wine-quality-rg \
  --sku Basic \
  --vm-size c0
```

**Caching Strategy**:
- **Prediction Results**: 1 hour TTL
- **Model Metadata**: 24 hours TTL
- **User Sessions**: 30 minutes TTL
- **API Rate Limits**: 1 minute TTL

#### Application-Level Caching
**Backend Implementation**:
```python
from functools import lru_cache
import redis
import json

# Redis connection
redis_client = redis.Redis(host='wine-quality-cache.redis.cache.windows.net', port=6380, ssl=True)

@lru_cache(maxsize=128)
def get_model_metadata():
    """Cache model metadata"""
    return load_model_metadata()

def cache_prediction_result(input_hash, result):
    """Cache prediction results"""
    redis_client.setex(f"prediction:{input_hash}", 3600, json.dumps(result))

def get_cached_prediction(input_hash):
    """Get cached prediction result"""
    cached = redis_client.get(f"prediction:{input_hash}")
    return json.loads(cached) if cached else None
```

### 2. Auto-scaling Configuration

#### App Service Auto-scaling
**Configuration**:
```bash
# Create autoscaling profile
az monitor autoscale create \
  --resource wine-quality-backend \
  --resource-group wine-quality-rg \
  --resource-type "Microsoft.Web/sites" \
  --name wine-quality-autoscale \
  --min-count 1 \
  --max-count 3 \
  --count 1

# Scale out rule (CPU > 70% for 5 minutes)
az monitor autoscale rule create \
  --resource-group wine-quality-rg \
  --autoscale-name wine-quality-autoscale \
  --condition "Percentage CPU > 70 avg 5m" \
  --scale out 1

# Scale in rule (CPU < 30% for 10 minutes)
az monitor autoscale rule create \
  --resource-group wine-quality-rg \
  --autoscale-name wine-quality-autoscale \
  --condition "Percentage CPU < 30 avg 10m" \
  --scale in 1
```

**Scaling Metrics**:
- **CPU Usage**: Primary scaling metric
- **Memory Usage**: Secondary scaling metric
- **Request Count**: Tertiary scaling metric
- **Response Time**: Alert threshold

#### Container Instances Auto-scaling
**Configuration**:
```bash
# Create container group with autoscaling
az container create \
  --resource-group wine-quality-rg \
  --name wine-quality-containers \
  --image winequalityacr.azurecr.io/wine-backend:latest \
  --cpu 1 \
  --memory 1.5 \
  --ports 8000 \
  --restart-policy Always
```

### 3. Database Optimization

#### Connection Pooling
**Backend Implementation**:
```python
from sqlalchemy import create_engine
from sqlalchemy.pool import QueuePool

# Optimized database connection
engine = create_engine(
    DATABASE_URL,
    poolclass=QueuePool,
    pool_size=20,
    max_overflow=30,
    pool_pre_ping=True,
    pool_recycle=3600
)
```

#### Query Optimization
**Best Practices**:
- Use indexes on frequently queried columns
- Implement query result caching
- Use prepared statements
- Optimize JOIN operations
- Implement pagination for large datasets

### 4. Application Optimization

#### Backend Optimization
**FastAPI Optimizations**:
```python
from fastapi import FastAPI
from fastapi.middleware.gzip import GZipMiddleware
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI(
    title="Wine Quality Prediction API",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc"
)

# Add compression middleware
app.add_middleware(GZipMiddleware, minimum_size=1000)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Optimize response models
from pydantic import BaseModel
from typing import Optional

class PredictionResponse(BaseModel):
    prediction: int
    confidence: float
    insight: str
    timestamp: str
    
    class Config:
        # Enable faster JSON serialization
        json_encoders = {
            datetime: lambda v: v.isoformat()
        }
```

**Gunicorn Configuration**:
```bash
# Optimized Gunicorn settings
gunicorn app.main:app \
  --workers 4 \
  --worker-class uvicorn.workers.UvicornWorker \
  --bind 0.0.0.0:8000 \
  --timeout 120 \
  --keep-alive 2 \
  --max-requests 1000 \
  --max-requests-jitter 100 \
  --preload
```

#### Frontend Optimization
**React Optimizations**:
```typescript
// Code splitting
import { lazy, Suspense } from 'react';

const WineQualityForm = lazy(() => import('./components/WineQualityForm'));
const ResultsDisplay = lazy(() => import('./components/ResultsDisplay'));

// Memoization
import { memo, useMemo, useCallback } from 'react';

const OptimizedComponent = memo(({ data }) => {
  const processedData = useMemo(() => {
    return data.map(item => processItem(item));
  }, [data]);

  const handleClick = useCallback((id) => {
    // Handle click
  }, []);

  return (
    <div>
      {processedData.map(item => (
        <div key={item.id} onClick={() => handleClick(item.id)}>
          {item.name}
        </div>
      ))}
    </div>
  );
});

// Service Worker for caching
if ('serviceWorker' in navigator) {
  navigator.serviceWorker.register('/sw.js');
}
```

**Vite Configuration**:
```typescript
// vite.config.ts
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

export default defineConfig({
  plugins: [react()],
  build: {
    rollupOptions: {
      output: {
        manualChunks: {
          vendor: ['react', 'react-dom'],
          ui: ['framer-motion', 'lucide-react'],
          utils: ['axios', 'react-hot-toast']
        }
      }
    },
    chunkSizeWarningLimit: 1000,
    minify: 'terser',
    terserOptions: {
      compress: {
        drop_console: true,
        drop_debugger: true
      }
    }
  },
  server: {
    hmr: {
      overlay: false
    }
  }
});
```

### 5. Infrastructure Optimization

#### Load Balancing
**Azure Application Gateway**:
```bash
# Create Application Gateway
az network application-gateway create \
  --name wine-quality-agw \
  --resource-group wine-quality-rg \
  --location eastus \
  --sku Standard_v2 \
  --capacity 2 \
  --public-ip-address wine-quality-pip
```

**Load Balancing Rules**:
- **Round Robin**: Default distribution
- **Least Connections**: For persistent sessions
- **IP Hash**: For session affinity
- **Weighted Round Robin**: For different server capacities

#### Network Optimization
**CDN Configuration**:
- **Edge Locations**: Global distribution
- **Compression**: Gzip and Brotli
- **HTTP/2**: Modern protocol support
- **TLS 1.3**: Latest encryption
- **Keep-Alive**: Persistent connections

### 6. Monitoring and Alerting

#### Performance Monitoring
**Application Insights**:
```python
from opencensus.ext.azure.log_exporter import AzureLogHandler
from opencensus.ext.azure.metrics_exporter import AzureMetricsExporter
from opencensus.stats import stats
from opencensus.tags import tag_map

# Custom metrics
stats_recorder = stats.stats_recorder
measure = stats.stats.stats_recorder.new_measure_int("prediction_duration")
view = stats.stats.stats_recorder.new_view(measure, "Prediction Duration", [])
stats.stats.stats_recorder.register_view(view)

# Track performance metrics
def track_prediction_duration(duration):
    mmap = tag_map.TagMap()
    stats_recorder.record_int(measure, duration, mmap)
```

**Custom Dashboards**:
- **Response Time Trends**: Real-time monitoring
- **Throughput Metrics**: Request rate tracking
- **Error Rate Monitoring**: Failure tracking
- **Resource Utilization**: CPU, memory, disk
- **Cache Hit Rates**: Caching effectiveness

#### Performance Alerts
**Alert Rules**:
```bash
# Slow response time alert
az monitor metrics alert create \
  --name slow-response-time \
  --resource-group wine-quality-rg \
  --scopes /subscriptions/.../sites/wine-quality-backend \
  --condition "avg 'HttpResponseTime' > 2000" \
  --description "Slow response time detected" \
  --severity 2

# High CPU usage alert
az monitor metrics alert create \
  --name high-cpu-usage \
  --resource-group wine-quality-rg \
  --scopes /subscriptions/.../sites/wine-quality-backend \
  --condition "avg 'CpuPercentage' > 80" \
  --description "High CPU usage detected" \
  --severity 2
```

## 📊 Performance Testing

### Load Testing
**Apache Bench (ab)**:
```bash
# Test backend performance
ab -n 1000 -c 10 https://wine-quality-backend.azurewebsites.net/api/v1/prediction/health

# Test frontend performance
ab -n 1000 -c 10 https://wine-quality-frontend.azurestaticapps.net

# Test prediction endpoint
ab -n 100 -c 5 -p sample_data.json -T application/json \
  https://wine-quality-backend.azurewebsites.net/api/v1/prediction/predict
```

**Sample Data File (sample_data.json)**:
```json
{
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
}
```

### Performance Testing Script
**Automated Testing**:
```bash
#!/bin/bash
# performance-test.sh

BACKEND_URL="https://wine-quality-backend.azurewebsites.net"
FRONTEND_URL="https://wine-quality-frontend.azurestaticapps.net"

echo "🍷 Wine Quality Prediction - Performance Testing"
echo "==============================================="

# Test backend health endpoint
echo "Testing backend health endpoint..."
ab -n 1000 -c 10 "$BACKEND_URL/api/v1/prediction/health"

# Test frontend
echo "Testing frontend..."
ab -n 1000 -c 10 "$FRONTEND_URL"

# Test prediction endpoint
echo "Testing prediction endpoint..."
SAMPLE_DATA='{
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

for i in {1..100}; do
    curl -X POST "$BACKEND_URL/api/v1/prediction/predict" \
        -H "Content-Type: application/json" \
        -d "$SAMPLE_DATA" \
        -w "Time: %{time_total}s\n" \
        -o /dev/null -s
done

echo "Performance testing completed"
```

### Frontend Performance Testing
**Lighthouse CI**:
```bash
# Install Lighthouse CI
npm install -g @lhci/cli

# Run Lighthouse tests
lhci autorun

# Lighthouse configuration (lighthouserc.js)
module.exports = {
  ci: {
    collect: {
      url: ['https://wine-quality-frontend.azurestaticapps.net'],
      numberOfRuns: 3
    },
    assert: {
      assertions: {
        'categories:performance': ['error', { minScore: 0.9 }],
        'categories:accessibility': ['error', { minScore: 0.9 }],
        'categories:best-practices': ['error', { minScore: 0.9 }],
        'categories:seo': ['error', { minScore: 0.9 }]
      }
    },
    upload: {
      target: 'temporary-public-storage'
    }
  }
};
```

## 🔍 Performance Monitoring

### Key Performance Indicators (KPIs)

#### Backend KPIs
- **Response Time**: Average, 95th percentile, 99th percentile
- **Throughput**: Requests per second, requests per minute
- **Error Rate**: 4xx errors, 5xx errors, timeout errors
- **Availability**: Uptime percentage, downtime duration
- **Resource Usage**: CPU, memory, disk, network

#### Frontend KPIs
- **Page Load Time**: First Contentful Paint, Largest Contentful Paint
- **User Experience**: Cumulative Layout Shift, Time to Interactive
- **Core Web Vitals**: LCP, FID, CLS scores
- **Lighthouse Score**: Performance, Accessibility, Best Practices, SEO

#### Infrastructure KPIs
- **Scalability**: Auto-scaling events, instance count
- **Caching**: Cache hit rate, cache miss rate
- **Network**: Latency, bandwidth utilization
- **Storage**: IOPS, throughput, latency

### Performance Dashboards

#### Azure Monitor Dashboard
**Metrics to Track**:
- Application response times
- Request throughput
- Error rates
- Resource utilization
- Cache performance

#### Custom Performance Dashboard
**React Components**:
```typescript
// PerformanceDashboard.tsx
import React, { useState, useEffect } from 'react';
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from 'recharts';

interface PerformanceMetrics {
  timestamp: string;
  responseTime: number;
  throughput: number;
  errorRate: number;
}

const PerformanceDashboard: React.FC = () => {
  const [metrics, setMetrics] = useState<PerformanceMetrics[]>([]);

  useEffect(() => {
    const fetchMetrics = async () => {
      try {
        const response = await fetch('/api/performance-metrics');
        const data = await response.json();
        setMetrics(data);
      } catch (error) {
        console.error('Failed to fetch metrics:', error);
      }
    };

    fetchMetrics();
    const interval = setInterval(fetchMetrics, 30000); // Update every 30 seconds
    return () => clearInterval(interval);
  }, []);

  return (
    <div className="performance-dashboard">
      <h2>Performance Metrics</h2>
      <ResponsiveContainer width="100%" height={400}>
        <LineChart data={metrics}>
          <CartesianGrid strokeDasharray="3 3" />
          <XAxis dataKey="timestamp" />
          <YAxis />
          <Tooltip />
          <Line type="monotone" dataKey="responseTime" stroke="#8884d8" />
          <Line type="monotone" dataKey="throughput" stroke="#82ca9d" />
          <Line type="monotone" dataKey="errorRate" stroke="#ffc658" />
        </LineChart>
      </ResponsiveContainer>
    </div>
  );
};

export default PerformanceDashboard;
```

## 🚀 Performance Optimization Checklist

### Pre-deployment Optimization
- [ ] CDN configured for static assets
- [ ] Redis cache implemented
- [ ] Auto-scaling rules configured
- [ ] Database connection pooling enabled
- [ ] Application code optimized
- [ ] Docker images optimized
- [ ] Performance monitoring enabled
- [ ] Load testing completed
- [ ] Performance benchmarks established
- [ ] Alert thresholds configured

### Post-deployment Optimization
- [ ] Performance metrics monitored
- [ ] Cache hit rates optimized
- [ ] Auto-scaling tested
- [ ] Database queries optimized
- [ ] Application performance reviewed
- [ ] Infrastructure resources optimized
- [ ] Performance alerts tested
- [ ] Regular performance assessments
- [ ] Continuous optimization
- [ ] Performance documentation updated

## 📚 Performance Best Practices

### 1. Caching Best Practices
- **Cache Strategy**: Cache frequently accessed data
- **Cache Invalidation**: Implement proper cache invalidation
- **Cache Warming**: Pre-populate cache with hot data
- **Cache Monitoring**: Monitor cache hit rates and performance

### 2. Database Optimization
- **Indexing**: Create indexes on frequently queried columns
- **Query Optimization**: Use efficient queries and prepared statements
- **Connection Pooling**: Implement proper connection pooling
- **Read Replicas**: Use read replicas for read-heavy workloads

### 3. Application Optimization
- **Code Optimization**: Optimize algorithms and data structures
- **Memory Management**: Implement proper memory management
- **Async Processing**: Use asynchronous processing where appropriate
- **Resource Pooling**: Implement resource pooling for expensive operations

### 4. Infrastructure Optimization
- **Auto-scaling**: Implement proper auto-scaling rules
- **Load Balancing**: Use load balancing for high availability
- **CDN**: Implement CDN for global content delivery
- **Monitoring**: Implement comprehensive monitoring and alerting

## 🎯 Performance Targets and SLAs

### Service Level Agreements (SLAs)
- **Availability**: 99.9% uptime
- **Response Time**: < 500ms (95th percentile)
- **Throughput**: > 1000 requests/minute
- **Error Rate**: < 0.1%
- **Recovery Time**: < 15 minutes

### Performance Targets
- **Frontend Load Time**: < 3 seconds
- **API Response Time**: < 500ms
- **Database Query Time**: < 50ms
- **Cache Hit Rate**: > 90%
- **Resource Utilization**: < 80%

## 🔧 Troubleshooting Performance Issues

### Common Performance Issues

#### 1. Slow Response Times
**Symptoms**: High response times, user complaints
**Causes**: Database bottlenecks, inefficient code, resource constraints
**Solutions**: 
- Optimize database queries
- Implement caching
- Scale resources
- Optimize application code

#### 2. High Error Rates
**Symptoms**: Increased 4xx/5xx errors
**Causes**: Resource exhaustion, application bugs, network issues
**Solutions**:
- Increase resource limits
- Fix application bugs
- Implement circuit breakers
- Add retry logic

#### 3. Resource Exhaustion
**Symptoms**: High CPU/memory usage, timeouts
**Causes**: Memory leaks, inefficient algorithms, insufficient resources
**Solutions**:
- Fix memory leaks
- Optimize algorithms
- Scale resources
- Implement resource monitoring

### Performance Debugging Tools

#### Backend Debugging
```python
# Performance profiling
import cProfile
import pstats
from io import StringIO

def profile_function(func):
    def wrapper(*args, **kwargs):
        pr = cProfile.Profile()
        pr.enable()
        result = func(*args, **kwargs)
        pr.disable()
        
        s = StringIO()
        ps = pstats.Stats(pr, stream=s).sort_stats('cumulative')
        ps.print_stats()
        print(s.getvalue())
        
        return result
    return wrapper

# Memory profiling
import tracemalloc

def memory_profile(func):
    def wrapper(*args, **kwargs):
        tracemalloc.start()
        result = func(*args, **kwargs)
        current, peak = tracemalloc.get_traced_memory()
        print(f"Current memory usage: {current / 1024 / 1024:.2f} MB")
        print(f"Peak memory usage: {peak / 1024 / 1024:.2f} MB")
        tracemalloc.stop()
        return result
    return wrapper
```

#### Frontend Debugging
```typescript
// Performance monitoring
const performanceObserver = new PerformanceObserver((list) => {
  for (const entry of list.getEntries()) {
    console.log('Performance entry:', entry);
  }
});

performanceObserver.observe({ entryTypes: ['measure', 'navigation', 'resource'] });

// Memory usage monitoring
if ('memory' in performance) {
  setInterval(() => {
    const memory = (performance as any).memory;
    console.log('Memory usage:', {
      used: memory.usedJSHeapSize / 1024 / 1024,
      total: memory.totalJSHeapSize / 1024 / 1024,
      limit: memory.jsHeapSizeLimit / 1024 / 1024
    });
  }, 5000);
}
```

## 📞 Performance Support

### Performance Team Contacts
- **Performance Engineer**: performance@yourdomain.com
- **DevOps Team**: devops@yourdomain.com
- **Backend Team**: backend@yourdomain.com
- **Frontend Team**: frontend@yourdomain.com

### Performance Resources
- **Azure Performance Documentation**: https://docs.microsoft.com/en-us/azure/performance/
- **FastAPI Performance Guide**: https://fastapi.tiangolo.com/benchmarks/
- **React Performance Guide**: https://reactjs.org/docs/optimizing-performance.html
- **Azure Monitor Documentation**: https://docs.microsoft.com/en-us/azure/azure-monitor/

---

**Document Version**: 1.0  
**Last Updated**: 2024-01-01  
**Next Review**: 2024-04-01  
**Approved By**: Performance Team  
**Distribution**: Internal Use Only

# 📋 Operations Runbook

This runbook provides step-by-step procedures for operating and maintaining the Wine Quality Prediction application in production.

## 🎯 Overview

### Purpose
This runbook serves as a comprehensive guide for:
- Daily operations and maintenance
- Incident response and troubleshooting
- Performance monitoring and optimization
- Security monitoring and response
- Backup and disaster recovery procedures

### Scope
- Production environment operations
- Development environment maintenance
- Monitoring and alerting
- Security operations
- Backup and recovery procedures

## 📊 Daily Operations

### Morning Checklist
```bash
# 1. Check system health
az webapp show --name wine-quality-backend --resource-group wine-quality-rg --query "state"
az staticwebapp show --name wine-quality-frontend --resource-group wine-quality-rg --query "buildProperties"

# 2. Check application logs
az webapp log tail --name wine-quality-backend --resource-group wine-quality-rg --timeout 30

# 3. Check performance metrics
az monitor metrics list --resource wine-quality-backend --resource-group wine-quality-rg --metric "HttpRequests"

# 4. Check security alerts
az security alert list --resource-group wine-quality-rg

# 5. Check backup status
az backup job list --vault-name wine-quality-backup-vault --resource-group wine-quality-rg
```

### Health Check Procedures
```bash
# Backend health check
curl -f https://wine-quality-backend.azurewebsites.net/api/v1/prediction/health

# Frontend health check
curl -f https://wine-quality-frontend.azurestaticapps.net/health

# API functionality test
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

### Performance Monitoring
```bash
# Check response times
az monitor metrics list \
  --resource wine-quality-backend \
  --resource-group wine-quality-rg \
  --metric "HttpResponseTime" \
  --aggregation Average \
  --interval PT1H

# Check throughput
az monitor metrics list \
  --resource wine-quality-backend \
  --resource-group wine-quality-rg \
  --metric "HttpRequests" \
  --aggregation Count \
  --interval PT1H

# Check error rates
az monitor metrics list \
  --resource wine-quality-backend \
  --resource-group wine-quality-rg \
  --metric "Http4xx" \
  --aggregation Count \
  --interval PT1H
```

## 🚨 Incident Response

### Incident Classification
- **Critical**: System down, data breach, security incident
- **High**: Performance degradation, partial outage
- **Medium**: Minor issues, non-critical bugs
- **Low**: Cosmetic issues, minor improvements

### Incident Response Procedures

#### 1. Detection and Assessment
```bash
# Check system status
az webapp show --name wine-quality-backend --resource-group wine-quality-rg --query "state"
az staticwebapp show --name wine-quality-frontend --resource-group wine-quality-rg --query "buildProperties"

# Check recent logs
az webapp log tail --name wine-quality-backend --resource-group wine-quality-rg --timeout 60

# Check alerts
az monitor activity-log list --resource-group wine-quality-rg --start-time 2024-01-01T00:00:00Z
```

#### 2. Initial Response
```bash
# Restart backend if needed
az webapp restart --name wine-quality-backend --resource-group wine-quality-rg

# Check backend status after restart
sleep 30
curl -f https://wine-quality-backend.azurewebsites.net/api/v1/prediction/health

# Check frontend status
curl -f https://wine-quality-frontend.azurestaticapps.net/health
```

#### 3. Escalation Procedures
- **Level 1**: On-call engineer (0-15 minutes)
- **Level 2**: Senior engineer (15-60 minutes)
- **Level 3**: Architecture team (60+ minutes)
- **Level 4**: Management escalation (2+ hours)

#### 4. Communication Plan
- **Internal**: Slack channel, email notifications
- **External**: Status page, customer notifications
- **Management**: Executive briefings, stakeholder updates

### Common Incident Scenarios

#### Backend Service Down
```bash
# 1. Check service status
az webapp show --name wine-quality-backend --resource-group wine-quality-rg --query "state"

# 2. Check logs for errors
az webapp log tail --name wine-quality-backend --resource-group wine-quality-rg --timeout 60

# 3. Restart service
az webapp restart --name wine-quality-backend --resource-group wine-quality-rg

# 4. Verify recovery
sleep 30
curl -f https://wine-quality-backend.azurewebsites.net/api/v1/prediction/health

# 5. Check performance
az monitor metrics list --resource wine-quality-backend --resource-group wine-quality-rg --metric "HttpRequests"
```

#### Frontend Service Down
```bash
# 1. Check service status
az staticwebapp show --name wine-quality-frontend --resource-group wine-quality-rg --query "buildProperties"

# 2. Check build status
az staticwebapp environment show --name wine-quality-frontend --resource-group wine-quality-rg

# 3. Trigger rebuild if needed
az staticwebapp environment set --name wine-quality-frontend --resource-group wine-quality-rg

# 4. Verify recovery
curl -f https://wine-quality-frontend.azurestaticapps.net/health
```

#### High Error Rate
```bash
# 1. Check error metrics
az monitor metrics list --resource wine-quality-backend --resource-group wine-quality-rg --metric "Http5xx"

# 2. Check error logs
az webapp log tail --name wine-quality-backend --resource-group wine-quality-rg --timeout 60

# 3. Check application insights
az monitor app-insights query --app wine-quality-backend-insights --analytics-query "exceptions | where timestamp > ago(1h)"

# 4. Implement fixes
# Update application code
# Deploy fixes
# Verify resolution
```

#### Performance Degradation
```bash
# 1. Check response times
az monitor metrics list --resource wine-quality-backend --resource-group wine-quality-rg --metric "HttpResponseTime"

# 2. Check resource usage
az monitor metrics list --resource wine-quality-backend --resource-group wine-quality-rg --metric "CpuPercentage"
az monitor metrics list --resource wine-quality-backend --resource-group wine-quality-rg --metric "MemoryPercentage"

# 3. Check scaling status
az monitor autoscale list --resource-group wine-quality-rg

# 4. Scale up if needed
az monitor autoscale rule create --resource-group wine-quality-rg --autoscale-name wine-quality-autoscale --condition "Percentage CPU > 70 avg 5m" --scale out 1

# 5. Monitor improvement
az monitor metrics list --resource wine-quality-backend --resource-group wine-quality-rg --metric "HttpResponseTime"
```

## 🔒 Security Operations

### Security Monitoring
```bash
# Check security alerts
az security alert list --resource-group wine-quality-rg

# Check key vault access
az keyvault show --name wine-quality-vault --resource-group wine-quality-rg --query "properties.accessPolicies"

# Check network security groups
az network nsg show --name wine-quality-nsg --resource-group wine-quality-rg --query "securityRules"

# Check application insights security
az monitor app-insights query --app wine-quality-backend-insights --analytics-query "requests | where resultCode >= 400 | where timestamp > ago(24h)"
```

### Security Incident Response
```bash
# 1. Assess security incident
az security alert list --resource-group wine-quality-rg --filter "severity eq 'High'"

# 2. Check affected resources
az monitor activity-log list --resource-group wine-quality-rg --start-time 2024-01-01T00:00:00Z

# 3. Implement containment
# Disable affected resources
# Block malicious IPs
# Update security rules

# 4. Investigate and remediate
# Analyze logs
# Identify root cause
# Implement fixes

# 5. Restore services
# Verify security
# Re-enable resources
# Monitor for recurrence
```

### Vulnerability Management
```bash
# Scan container images
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  aquasec/trivy image winequalityacr.azurecr.io/wine-backend:latest

# Check for security updates
az acr task list --registry winequalityacr --resource-group wine-quality-rg

# Update base images
az acr build --registry winequalityacr --image wine-backend:latest ./backend
```

## ⚡ Performance Operations

### Performance Monitoring
```bash
# Check response times
az monitor metrics list --resource wine-quality-backend --resource-group wine-quality-rg --metric "HttpResponseTime" --aggregation Average

# Check throughput
az monitor metrics list --resource wine-quality-backend --resource-group wine-quality-rg --metric "HttpRequests" --aggregation Count

# Check error rates
az monitor metrics list --resource wine-quality-backend --resource-group wine-quality-rg --metric "Http5xx" --aggregation Count

# Check resource usage
az monitor metrics list --resource wine-quality-backend --resource-group wine-quality-rg --metric "CpuPercentage" --aggregation Average
az monitor metrics list --resource wine-quality-backend --resource-group wine-quality-rg --metric "MemoryPercentage" --aggregation Average
```

### Performance Optimization
```bash
# Check cache hit rates
az monitor metrics list --resource wine-quality-cache --resource-group wine-quality-rg --metric "CacheHits" --aggregation Count
az monitor metrics list --resource wine-quality-cache --resource-group wine-quality-rg --metric "CacheMisses" --aggregation Count

# Check CDN performance
az cdn endpoint show --name wine-quality-frontend-cdn --profile-name wine-quality-cdn --resource-group wine-quality-rg --query "resourceState"

# Check auto-scaling
az monitor autoscale list --resource-group wine-quality-rg
```

### Load Testing
```bash
# Run load tests
ab -n 1000 -c 10 https://wine-quality-backend.azurewebsites.net/api/v1/prediction/health

# Monitor during load test
az monitor metrics list --resource wine-quality-backend --resource-group wine-quality-rg --metric "HttpResponseTime" --aggregation Average

# Check scaling behavior
az monitor autoscale list --resource-group wine-quality-rg
```

## 💾 Backup Operations

### Backup Verification
```bash
# Check backup status
az backup job list --vault-name wine-quality-backup-vault --resource-group wine-quality-rg

# Verify backup integrity
az storage blob list --account-name winequalitybackup --container-name ml-models --auth-mode login

# Check backup age
az storage blob show --account-name winequalitybackup --container-name ml-models --name "ml-models-20240101_120000.tar.gz" --auth-mode login
```

### Manual Backup
```bash
# Create manual backup
./azure/backup-script.sh

# Verify backup creation
az storage blob list --account-name winequalitybackup --container-name ml-models --auth-mode login

# Test backup integrity
az storage blob download --account-name winequalitybackup --container-name ml-models --name "ml-models-20240101_120000.tar.gz" --file test-backup.tar.gz --auth-mode login
```

### Restore Procedures
```bash
# List available backups
./azure/restore-script.sh

# Restore specific backup
az storage blob download --account-name winequalitybackup --container-name ml-models --name "ml-models-20240101_120000.tar.gz" --file restore-backup.tar.gz --auth-mode login

# Extract and restore
tar -xzf restore-backup.tar.gz
cp -r saved_models backend/
```

## 🔄 Disaster Recovery Operations

### DR Testing
```bash
# Test failover
./azure/disaster-recovery-plan.sh

# Verify secondary region
az webapp show --name wine-quality-dr-backend --resource-group wine-quality-dr-rg --query "state"

# Test traffic manager
az network traffic-manager profile show --name wine-quality-tm --resource-group wine-quality-rg --query "trafficRoutingMethod"
```

### Failover Procedures
```bash
# Disable primary endpoint
az network traffic-manager endpoint update --name primary-backend --profile-name wine-quality-tm --resource-group wine-quality-rg --endpoint-status Disabled

# Verify failover
sleep 30
curl -f https://wine-quality-dr-backend.azurewebsites.net/api/v1/prediction/health

# Re-enable primary endpoint
az network traffic-manager endpoint update --name primary-backend --profile-name wine-quality-tm --resource-group wine-quality-rg --endpoint-status Enabled
```

## 📊 Monitoring Operations

### Application Monitoring
```bash
# Check application insights
az monitor app-insights component show --app wine-quality-backend-insights --resource-group wine-quality-rg

# Query application logs
az monitor log-analytics query --workspace wine-quality-logs --analytics-query "requests | where timestamp > ago(1h) | limit 10"

# Check custom metrics
az monitor metrics list --resource wine-quality-backend --resource-group wine-quality-rg --metric "CustomMetrics"
```

### Infrastructure Monitoring
```bash
# Check resource health
az resource list --resource-group wine-quality-rg --query "[].{Name:name, Type:type, Location:location}"

# Check service health
az monitor activity-log list --resource-group wine-quality-rg --start-time 2024-01-01T00:00:00Z

# Check alert rules
az monitor metrics alert list --resource-group wine-quality-rg
```

### Dashboard Management
```bash
# Check dashboard status
az portal dashboard show --name wine-quality-dashboard --resource-group wine-quality-rg

# Update dashboard
az portal dashboard update --name wine-quality-dashboard --resource-group wine-quality-rg --input-path azure/dashboard.json
```

## 🔧 Maintenance Operations

### Regular Maintenance
```bash
# Update dependencies
cd backend
pip install -r requirements.txt --upgrade

cd frontend
npm update

# Update base images
az acr build --registry winequalityacr --image wine-backend:latest ./backend
az acr build --registry winequalityacr --image wine-frontend:latest ./frontend

# Deploy updates
az webapp config container set --name wine-quality-backend --resource-group wine-quality-rg --docker-custom-image-name winequalityacr.azurecr.io/wine-backend:latest
```

### Configuration Management
```bash
# Update environment variables
az webapp config appsettings set --name wine-quality-backend --resource-group wine-quality-rg --settings "LOG_LEVEL=INFO"

# Update SSL certificates
az webapp config ssl upload --name wine-quality-backend --resource-group wine-quality-rg --certificate-file certificate.pfx --certificate-password password

# Update custom domains
az webapp config hostname add --webapp-name wine-quality-backend --resource-group wine-quality-rg --hostname api.yourdomain.com
```

### Log Management
```bash
# Clean up old logs
az webapp log deployment list --name wine-quality-backend --resource-group wine-quality-rg

# Archive logs
az storage blob upload --account-name winequalitybackup --container-name application-logs --name "logs-$(date +%Y%m%d).tar.gz" --file logs.tar.gz --auth-mode login

# Monitor log size
az monitor metrics list --resource wine-quality-backend --resource-group wine-quality-rg --metric "LogSize"
```

## 📞 Emergency Contacts

### Internal Contacts
- **On-call Engineer**: +1-XXX-XXX-XXXX
- **Senior Engineer**: +1-XXX-XXX-XXXX
- **Architecture Team**: +1-XXX-XXX-XXXX
- **Management**: +1-XXX-XXX-XXXX

### External Contacts
- **Azure Support**: Azure portal support
- **GitHub Support**: GitHub support
- **Docker Support**: Docker support
- **Security Vendor**: vendor@securitycompany.com

### Escalation Matrix
- **Level 1**: On-call engineer (0-15 minutes)
- **Level 2**: Senior engineer (15-60 minutes)
- **Level 3**: Architecture team (60+ minutes)
- **Level 4**: Management (2+ hours)

## 📋 Operational Checklists

### Daily Checklist
- [ ] Check system health
- [ ] Review application logs
- [ ] Check performance metrics
- [ ] Review security alerts
- [ ] Verify backup status
- [ ] Check monitoring dashboards
- [ ] Review error rates
- [ ] Check resource usage
- [ ] Verify SSL certificates
- [ ] Check custom domains

### Weekly Checklist
- [ ] Review performance trends
- [ ] Check security scan results
- [ ] Verify backup integrity
- [ ] Review capacity planning
- [ ] Check dependency updates
- [ ] Review monitoring alerts
- [ ] Check cost optimization
- [ ] Verify disaster recovery
- [ ] Review documentation
- [ ] Plan maintenance windows

### Monthly Checklist
- [ ] Conduct disaster recovery test
- [ ] Review security policies
- [ ] Update dependencies
- [ ] Review performance optimization
- [ ] Check compliance status
- [ ] Review backup procedures
- [ ] Update documentation
- [ ] Conduct team training
- [ ] Review incident reports
- [ ] Plan capacity upgrades

## 🎯 Performance Targets

### Service Level Objectives (SLOs)
- **Availability**: 99.9% uptime
- **Response Time**: < 500ms (95th percentile)
- **Throughput**: > 1000 requests/minute
- **Error Rate**: < 0.1%
- **Recovery Time**: < 15 minutes

### Key Performance Indicators (KPIs)
- **Mean Time to Detection (MTTD)**: < 5 minutes
- **Mean Time to Response (MTTR)**: < 15 minutes
- **Mean Time to Recovery (MTTR)**: < 30 minutes
- **Change Success Rate**: > 95%
- **Incident Rate**: < 1 per month

## 📚 Documentation Updates

### Regular Updates
- **Daily**: Operational logs and incident reports
- **Weekly**: Performance reports and metrics
- **Monthly**: Architecture reviews and updates
- **Quarterly**: Comprehensive documentation review

### Documentation Standards
- **Accuracy**: All information must be current and accurate
- **Completeness**: All procedures must be documented
- **Clarity**: Instructions must be clear and unambiguous
- **Accessibility**: Documentation must be easily accessible
- **Version Control**: All changes must be tracked

## 🔄 Continuous Improvement

### Process Improvement
- **Regular Reviews**: Monthly process reviews
- **Incident Analysis**: Post-incident reviews and improvements
- **Performance Analysis**: Regular performance reviews
- **Security Reviews**: Quarterly security assessments
- **Training Updates**: Regular team training updates

### Technology Updates
- **Dependency Updates**: Regular dependency updates
- **Security Patches**: Immediate security patch application
- **Feature Updates**: Regular feature and capability updates
- **Performance Optimization**: Continuous performance optimization
- **Cost Optimization**: Regular cost optimization reviews

---

**Document Version**: 1.0  
**Last Updated**: 2024-01-01  
**Next Review**: 2024-04-01  
**Approved By**: Operations Team  
**Distribution**: Internal Use Only

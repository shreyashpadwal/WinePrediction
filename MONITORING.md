# 📊 Azure Monitoring Guide

This guide covers the comprehensive monitoring setup for the Wine Quality Prediction application deployed on Azure.

## 🏗️ Monitoring Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Application   │    │   Application   │    │   Log Analytics │
│   Insights      │◄──►│   Service       │◄──►│   Workspace     │
│                 │    │                 │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Alerts        │    │   Dashboard      │    │   Cost Monitor   │
│   & Actions     │    │   & Reports      │    │   & Budgets      │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## 🔧 Setup

### Prerequisites

- Azure CLI installed and configured
- Wine Quality Prediction application deployed
- Azure subscription with appropriate permissions

### Quick Setup

```bash
# Run monitoring setup
./azure/monitoring-setup.sh
```

## 📊 Monitoring Components

### 1. Application Insights

**Purpose**: Application performance monitoring and telemetry collection

**Features**:
- Request tracking
- Exception monitoring
- Performance counters
- Custom events
- Dependency tracking

**Configuration**:
```bash
# Enable Application Insights
az monitor app-insights component create \
  --app wine-quality-backend-insights \
  --location eastus \
  --resource-group wine-quality-rg \
  --application-type web
```

**Key Metrics**:
- HTTP requests per minute
- Response time
- Error rate
- Availability
- Custom wine prediction events

### 2. Log Analytics Workspace

**Purpose**: Centralized logging and log analysis

**Features**:
- Centralized log collection
- Advanced querying with Kusto
- Log retention policies
- Integration with other Azure services

**Configuration**:
```bash
# Create Log Analytics workspace
az monitor log-analytics workspace create \
  --workspace-name wine-quality-logs \
  --resource-group wine-quality-rg \
  --location eastus
```

**Log Sources**:
- Application logs
- System logs
- Security logs
- Performance logs

### 3. Diagnostic Settings

**Purpose**: Automatic log and metric collection

**Configuration**:
```bash
# Configure diagnostic settings
az monitor diagnostic-settings create \
  --name wine-quality-backend-diagnostics \
  --resource wine-quality-backend \
  --resource-group wine-quality-rg \
  --workspace wine-quality-logs \
  --logs '[{"category": "AppServiceHTTPLogs", "enabled": true}]'
```

**Collected Data**:
- HTTP logs
- Console logs
- Application logs
- Performance metrics

## 🚨 Alerts and Notifications

### Alert Rules

#### 1. High Error Rate Alert
```bash
az monitor metrics alert create \
  --name high-error-rate \
  --resource-group wine-quality-rg \
  --scopes /subscriptions/.../sites/wine-quality-backend \
  --condition "avg 'Http5xx' > 5" \
  --description "High error rate detected" \
  --severity 1
```

#### 2. Slow Response Time Alert
```bash
az monitor metrics alert create \
  --name slow-response-time \
  --resource-group wine-quality-rg \
  --scopes /subscriptions/.../sites/wine-quality-backend \
  --condition "avg 'HttpResponseTime' > 2000" \
  --description "Slow response time detected" \
  --severity 2
```

#### 3. Application Down Alert
```bash
az monitor metrics alert create \
  --name app-down \
  --resource-group wine-quality-rg \
  --scopes /subscriptions/.../sites/wine-quality-backend \
  --condition "count 'HttpRequests' == 0" \
  --description "Application appears to be down" \
  --severity 0
```

#### 4. Resource Usage Alerts
```bash
# High memory usage
az monitor metrics alert create \
  --name high-memory-usage \
  --resource-group wine-quality-rg \
  --scopes /subscriptions/.../sites/wine-quality-backend \
  --condition "avg 'MemoryPercentage' > 80" \
  --description "High memory usage detected" \
  --severity 2

# High CPU usage
az monitor metrics alert create \
  --name high-cpu-usage \
  --resource-group wine-quality-rg \
  --scopes /subscriptions/.../sites/wine-quality-backend \
  --condition "avg 'CpuPercentage' > 80" \
  --description "High CPU usage detected" \
  --severity 2
```

### Action Groups

**Purpose**: Define notification channels for alerts

**Configuration**:
```bash
# Create action group
az monitor action-group create \
  --name wine-quality-alerts \
  --resource-group wine-quality-rg \
  --short-name wine-alerts \
  --email-receivers name="admin" email="admin@yourdomain.com" \
  --sms-receivers name="admin" country-code="1" phone-number="1234567890"
```

**Notification Channels**:
- Email notifications
- SMS alerts
- Webhook integrations
- Azure Functions

## 📈 Dashboards and Reports

### Azure Dashboard

**Purpose**: Visual monitoring and reporting

**Features**:
- Real-time metrics
- Custom visualizations
- Multiple data sources
- Interactive charts

**Access**: Azure Portal → Dashboards → Wine Quality Prediction Dashboard

### Custom Metrics

**Wine Prediction Metrics**:
- Prediction count per hour
- Average prediction time
- Model accuracy trends
- User engagement metrics

**Configuration**:
```bash
# Create custom metric
az monitor metrics alert create \
  --name wine-prediction-count \
  --resource-group wine-quality-rg \
  --scopes /subscriptions/.../sites/wine-quality-backend \
  --condition "count 'HttpRequests' > 0" \
  --description "Track wine prediction requests"
```

## 🔍 Log Analysis with Kusto

### Useful Queries

#### 1. Top Errors
```kusto
requests
| where timestamp > ago(24h)
| where success == false
| summarize count() by name, resultCode
| order by count_ desc
```

#### 2. Slow Requests
```kusto
requests
| where timestamp > ago(24h)
| where duration > 2000
| order by duration desc
| project timestamp, name, duration, url, resultCode
```

#### 3. Failed Predictions
```kusto
requests
| where timestamp > ago(24h)
| where name contains "predict"
| where success == false
| project timestamp, name, duration, url, resultCode, customDimensions
```

#### 4. API Usage Patterns
```kusto
requests
| where timestamp > ago(24h)
| where name contains "api"
| summarize count() by bin(timestamp, 1h)
| render timechart
```

#### 5. User Traffic Patterns
```kusto
requests
| where timestamp > ago(24h)
| summarize count() by client_City, client_CountryOrRegion
| order by count_ desc
```

#### 6. Performance Trends
```kusto
requests
| where timestamp > ago(24h)
| summarize avg(duration), max(duration), min(duration) by bin(timestamp, 1h)
| render timechart
```

#### 7. Exception Analysis
```kusto
exceptions
| where timestamp > ago(24h)
| project timestamp, type, method, outerMessage
| order by timestamp desc
```

#### 8. Dependency Failures
```kusto
dependencies
| where timestamp > ago(24h)
| where success == false
| project timestamp, name, duration, target, resultCode
| order by timestamp desc
```

## 💰 Cost Monitoring

### Budget Alerts

**Purpose**: Monitor and control Azure spending

**Configuration**:
```bash
# Create budget alert
az consumption budget create \
  --budget-name wine-quality-budget \
  --resource-group wine-quality-rg \
  --amount 100 \
  --time-grain "Monthly" \
  --notifications amount=80 operator="GreaterThan" contact-emails="admin@yourdomain.com"
```

### Cost Analysis

**Key Metrics**:
- Monthly spending trends
- Resource cost breakdown
- Cost per prediction
- Optimization opportunities

**Reports**:
- Daily cost reports
- Monthly budget summaries
- Cost optimization recommendations

## 🔧 Troubleshooting

### Common Issues

#### 1. Alerts Not Firing
```bash
# Check alert rule status
az monitor metrics alert show --name high-error-rate --resource-group wine-quality-rg

# Test alert condition
az monitor metrics alert create --test
```

#### 2. Missing Logs
```bash
# Check diagnostic settings
az monitor diagnostic-settings list --resource wine-quality-backend --resource-group wine-quality-rg

# Verify log collection
az monitor log-analytics workspace show --workspace-name wine-quality-logs --resource-group wine-quality-rg
```

#### 3. Dashboard Not Loading
```bash
# Check dashboard permissions
az portal dashboard show --name wine-quality-dashboard --resource-group wine-quality-rg

# Verify data sources
az monitor metrics list --resource wine-quality-backend --resource-group wine-quality-rg
```

### Debug Commands

```bash
# Check Application Insights status
az monitor app-insights component show --app wine-quality-backend-insights --resource-group wine-quality-rg

# View recent logs
az monitor log-analytics query --workspace wine-quality-logs --analytics-query "requests | where timestamp > ago(1h) | limit 10"

# Check alert history
az monitor activity-log list --resource-group wine-quality-rg --start-time 2024-01-01T00:00:00Z
```

## 📚 Best Practices

### 1. Alert Tuning
- Set appropriate thresholds
- Use multiple alert conditions
- Implement alert fatigue prevention
- Regular alert review and optimization

### 2. Log Management
- Implement log retention policies
- Use structured logging
- Monitor log volume
- Regular log analysis

### 3. Performance Monitoring
- Track key performance indicators
- Monitor resource utilization
- Set up capacity planning
- Regular performance reviews

### 4. Security Monitoring
- Monitor authentication events
- Track security-related logs
- Implement threat detection
- Regular security assessments

## 🚀 Advanced Features

### 1. Custom Dashboards
- Create specialized dashboards
- Implement real-time monitoring
- Add custom visualizations
- Share dashboards with teams

### 2. Automated Reports
- Schedule regular reports
- Email report distribution
- Custom report templates
- Trend analysis

### 3. Integration with External Tools
- Slack notifications
- Microsoft Teams integration
- Webhook endpoints
- API integrations

### 4. Machine Learning Insights
- Anomaly detection
- Predictive analytics
- Trend forecasting
- Automated insights

## 📞 Support

For monitoring issues:

1. Check the troubleshooting section
2. Review Azure service health
3. Consult Azure documentation
4. Contact Azure support
5. Create an issue with monitoring details

## 🎯 Next Steps

After monitoring setup:

1. **Configure notifications**: Set up email/SMS alerts
2. **Create custom dashboards**: Build specialized views
3. **Set up automated reports**: Schedule regular reports
4. **Implement log analysis**: Use Kusto queries
5. **Monitor costs**: Track spending and optimize
6. **Review and optimize**: Regular monitoring review

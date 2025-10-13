#!/bin/bash
set -e

# Azure Monitoring Setup Script
# This script sets up comprehensive monitoring and alerting for the Wine Quality Prediction application

echo "🍷 Wine Quality Prediction - Azure Monitoring Setup"
echo "==================================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if .env.azure exists
check_env_file() {
    if [ ! -f "azure/.env.azure" ]; then
        print_error "azure/.env.azure not found. Please run ./azure/acr-setup.sh first"
        exit 1
    fi
    
    # Source the environment file
    source azure/.env.azure
    print_success "Loaded Azure configuration from azure/.env.azure"
}

# Function to check if Azure CLI is logged in
check_azure_login() {
    print_status "Checking Azure CLI login..."
    
    if ! az account show &> /dev/null; then
        print_error "Not logged into Azure CLI. Please run 'az login' first"
        exit 1
    fi
    
    print_success "Logged into Azure CLI"
}

# Function to create Log Analytics workspace
create_log_analytics_workspace() {
    print_status "Creating Log Analytics workspace..."
    
    WORKSPACE_NAME="wine-quality-logs"
    
    # Check if workspace already exists
    if az monitor log-analytics workspace show --workspace-name "$WORKSPACE_NAME" --resource-group "$AZURE_RESOURCE_GROUP" &> /dev/null; then
        print_warning "Log Analytics workspace $WORKSPACE_NAME already exists"
    else
        az monitor log-analytics workspace create \
            --workspace-name "$WORKSPACE_NAME" \
            --resource-group "$AZURE_RESOURCE_GROUP" \
            --location "$AZURE_LOCATION"
        print_success "Log Analytics workspace created: $WORKSPACE_NAME"
    fi
    
    # Get workspace ID
    WORKSPACE_ID=$(az monitor log-analytics workspace show --workspace-name "$WORKSPACE_NAME" --resource-group "$AZURE_RESOURCE_GROUP" --query customerId -o tsv)
    print_success "Workspace ID: $WORKSPACE_ID"
}

# Function to enable Application Insights
enable_application_insights() {
    print_status "Enabling Application Insights..."
    
    APP_INSIGHTS_NAME="${BACKEND_APP_NAME}-insights"
    
    # Check if Application Insights already exists
    if az monitor app-insights component show --app "$APP_INSIGHTS_NAME" --resource-group "$AZURE_RESOURCE_GROUP" &> /dev/null; then
        print_warning "Application Insights $APP_INSIGHTS_NAME already exists"
    else
        az monitor app-insights component create \
            --app "$APP_INSIGHTS_NAME" \
            --location "$AZURE_LOCATION" \
            --resource-group "$AZURE_RESOURCE_GROUP" \
            --application-type web
        print_success "Application Insights created: $APP_INSIGHTS_NAME"
    fi
    
    # Get Application Insights key
    APP_INSIGHTS_KEY=$(az monitor app-insights component show --app "$APP_INSIGHTS_NAME" --resource-group "$AZURE_RESOURCE_GROUP" --query instrumentationKey -o tsv)
    print_success "Application Insights key: $APP_INSIGHTS_KEY"
}

# Function to configure diagnostic settings
configure_diagnostic_settings() {
    print_status "Configuring diagnostic settings..."
    
    WORKSPACE_NAME="wine-quality-logs"
    WORKSPACE_ID=$(az monitor log-analytics workspace show --workspace-name "$WORKSPACE_NAME" --resource-group "$AZURE_RESOURCE_GROUP" --query id -o tsv)
    
    # Configure App Service diagnostic settings
    az monitor diagnostic-settings create \
        --name "wine-quality-backend-diagnostics" \
        --resource "$BACKEND_APP_NAME" \
        --resource-group "$AZURE_RESOURCE_GROUP" \
        --resource-type "Microsoft.Web/sites" \
        --workspace "$WORKSPACE_ID" \
        --logs '[
            {
                "category": "AppServiceHTTPLogs",
                "enabled": true,
                "retentionPolicy": {
                    "enabled": true,
                    "days": 30
                }
            },
            {
                "category": "AppServiceConsoleLogs",
                "enabled": true,
                "retentionPolicy": {
                    "enabled": true,
                    "days": 30
                }
            },
            {
                "category": "AppServiceAppLogs",
                "enabled": true,
                "retentionPolicy": {
                    "enabled": true,
                    "days": 30
                }
            }
        ]' \
        --metrics '[
            {
                "category": "AllMetrics",
                "enabled": true,
                "retentionPolicy": {
                    "enabled": true,
                    "days": 30
                }
            }
        ]'
    
    print_success "Diagnostic settings configured"
}

# Function to create custom metrics
create_custom_metrics() {
    print_status "Creating custom metrics..."
    
    # Create custom metrics for wine predictions
    az monitor metrics alert create \
        --name "wine-prediction-count" \
        --resource-group "$AZURE_RESOURCE_GROUP" \
        --scopes "/subscriptions/$AZURE_SUBSCRIPTION_ID/resourceGroups/$AZURE_RESOURCE_GROUP/providers/Microsoft.Web/sites/$BACKEND_APP_NAME" \
        --condition "count 'HttpRequests' > 0" \
        --description "Track wine prediction requests" \
        --evaluation-frequency 5m \
        --window-size 15m \
        --severity 2
    
    print_success "Custom metrics created"
}

# Function to create availability tests
create_availability_tests() {
    print_status "Creating availability tests..."
    
    # Create availability test for backend
    az monitor app-insights web-test create \
        --name "wine-backend-availability" \
        --location "$AZURE_LOCATION" \
        --resource-group "$AZURE_RESOURCE_GROUP" \
        --app-insights "$APP_INSIGHTS_NAME" \
        --web-test-kind "ping" \
        --request-url "https://$BACKEND_APP_NAME.azurewebsites.net/api/v1/prediction/health" \
        --frequency 300 \
        --timeout 30 \
        --retry-enabled true \
        --retry-count 3 \
        --locations "us-ca-sjc-azr" "us-tx-sn1-azr" "us-il-ch1-azr"
    
    print_success "Availability tests created"
}

# Function to create action groups
create_action_groups() {
    print_status "Creating action groups..."
    
    # Create action group for alerts
    az monitor action-group create \
        --name "wine-quality-alerts" \
        --resource-group "$AZURE_RESOURCE_GROUP" \
        --short-name "wine-alerts" \
        --email-receivers name="admin" email="admin@yourdomain.com" \
        --sms-receivers name="admin" country-code="1" phone-number="1234567890"
    
    print_success "Action groups created"
}

# Function to create alerts
create_alerts() {
    print_status "Creating alerts..."
    
    ACTION_GROUP_ID="/subscriptions/$AZURE_SUBSCRIPTION_ID/resourceGroups/$AZURE_RESOURCE_GROUP/providers/microsoft.insights/actionGroups/wine-quality-alerts"
    
    # Alert 1: High error rate
    az monitor metrics alert create \
        --name "high-error-rate" \
        --resource-group "$AZURE_RESOURCE_GROUP" \
        --scopes "/subscriptions/$AZURE_SUBSCRIPTION_ID/resourceGroups/$AZURE_RESOURCE_GROUP/providers/Microsoft.Web/sites/$BACKEND_APP_NAME" \
        --condition "avg 'Http5xx' > 5" \
        --description "High error rate detected" \
        --evaluation-frequency 5m \
        --window-size 15m \
        --severity 1 \
        --action "$ACTION_GROUP_ID"
    
    # Alert 2: Slow response time
    az monitor metrics alert create \
        --name "slow-response-time" \
        --resource-group "$AZURE_RESOURCE_GROUP" \
        --scopes "/subscriptions/$AZURE_SUBSCRIPTION_ID/resourceGroups/$AZURE_RESOURCE_GROUP/providers/Microsoft.Web/sites/$BACKEND_APP_NAME" \
        --condition "avg 'HttpResponseTime' > 2000" \
        --description "Slow response time detected" \
        --evaluation-frequency 5m \
        --window-size 15m \
        --severity 2 \
        --action "$ACTION_GROUP_ID"
    
    # Alert 3: App down
    az monitor metrics alert create \
        --name "app-down" \
        --resource-group "$AZURE_RESOURCE_GROUP" \
        --scopes "/subscriptions/$AZURE_SUBSCRIPTION_ID/resourceGroups/$AZURE_RESOURCE_GROUP/providers/Microsoft.Web/sites/$BACKEND_APP_NAME" \
        --condition "count 'HttpRequests' == 0" \
        --description "Application appears to be down" \
        --evaluation-frequency 5m \
        --window-size 15m \
        --severity 0 \
        --action "$ACTION_GROUP_ID"
    
    # Alert 4: High memory usage
    az monitor metrics alert create \
        --name "high-memory-usage" \
        --resource-group "$AZURE_RESOURCE_GROUP" \
        --scopes "/subscriptions/$AZURE_SUBSCRIPTION_ID/resourceGroups/$AZURE_RESOURCE_GROUP/providers/Microsoft.Web/sites/$BACKEND_APP_NAME" \
        --condition "avg 'MemoryPercentage' > 80" \
        --description "High memory usage detected" \
        --evaluation-frequency 5m \
        --window-size 15m \
        --severity 2 \
        --action "$ACTION_GROUP_ID"
    
    # Alert 5: High CPU usage
    az monitor metrics alert create \
        --name "high-cpu-usage" \
        --resource-group "$AZURE_RESOURCE_GROUP" \
        --scopes "/subscriptions/$AZURE_SUBSCRIPTION_ID/resourceGroups/$AZURE_RESOURCE_GROUP/providers/Microsoft.Web/sites/$BACKEND_APP_NAME" \
        --condition "avg 'CpuPercentage' > 80" \
        --description "High CPU usage detected" \
        --evaluation-frequency 5m \
        --window-size 15m \
        --severity 2 \
        --action "$ACTION_GROUP_ID"
    
    print_success "Alerts created"
}

# Function to create dashboard
create_dashboard() {
    print_status "Creating Azure dashboard..."
    
    # Create dashboard JSON
    cat > azure/dashboard.json << EOF
{
  "properties": {
    "lenses": {
      "0": {
        "order": 0,
        "parts": {
          "0": {
            "position": {
              "x": 0,
              "y": 0,
              "colSpan": 6,
              "rowSpan": 4
            },
            "metadata": {
              "inputs": [
                {
                  "name": "options",
                  "value": {
                    "chart": {
                      "metrics": [
                        {
                          "resourceMetadata": {
                            "id": "/subscriptions/$AZURE_SUBSCRIPTION_ID/resourceGroups/$AZURE_RESOURCE_GROUP/providers/Microsoft.Web/sites/$BACKEND_APP_NAME"
                          },
                          "name": "HttpRequests",
                          "aggregationType": 1,
                          "namespace": "microsoft.web/sites",
                          "metricVisualization": {
                            "displayName": "Http Requests"
                          }
                        }
                      ],
                      "title": "HTTP Requests",
                      "titleKind": 1,
                      "visualization": {
                        "chartType": 2,
                        "legendVisualization": {
                          "isVisible": true,
                          "position": 2,
                          "hideSubtitle": false
                        },
                        "axisVisualization": {
                          "x": {
                            "isVisible": true,
                            "axisType": 2
                          },
                          "y": {
                            "isVisible": true,
                            "axisType": 1
                          }
                        }
                      }
                    }
                  }
                }
              ],
              "type": "Extension/Microsoft_OperationsManagementSuite_Workspace/PartType/LogsDashboardPart",
              "settings": {}
            }
          }
        }
      }
    }
  },
  "name": "Wine Quality Prediction Dashboard",
  "type": "Microsoft.Portal/dashboards",
  "location": "$AZURE_LOCATION",
  "tags": {
    "hidden-title": "Wine Quality Prediction Dashboard"
  }
}
EOF
    
    # Create dashboard
    az portal dashboard create \
        --resource-group "$AZURE_RESOURCE_GROUP" \
        --name "wine-quality-dashboard" \
        --input-path azure/dashboard.json
    
    print_success "Dashboard created"
}

# Function to create Kusto queries
create_kusto_queries() {
    print_status "Creating Kusto queries..."
    
    cat > azure/kusto-queries.txt << EOF
# Wine Quality Prediction - Useful Kusto Queries

# 1. Top errors in the last 24 hours
requests
| where timestamp > ago(24h)
| where success == false
| summarize count() by name, resultCode
| order by count_ desc

# 2. Slow requests in the last 24 hours
requests
| where timestamp > ago(24h)
| where duration > 2000
| order by duration desc
| project timestamp, name, duration, url, resultCode

# 3. Failed predictions
requests
| where timestamp > ago(24h)
| where name contains "predict"
| where success == false
| project timestamp, name, duration, url, resultCode, customDimensions

# 4. API usage patterns
requests
| where timestamp > ago(24h)
| where name contains "api"
| summarize count() by bin(timestamp, 1h)
| render timechart

# 5. User traffic patterns
requests
| where timestamp > ago(24h)
| summarize count() by client_City, client_CountryOrRegion
| order by count_ desc

# 6. Memory usage trends
performanceCounters
| where timestamp > ago(24h)
| where counter == "Available Memory"
| render timechart

# 7. CPU usage trends
performanceCounters
| where timestamp > ago(24h)
| where counter == "% Processor Time"
| render timechart

# 8. Exception details
exceptions
| where timestamp > ago(24h)
| project timestamp, type, method, outerMessage
| order by timestamp desc

# 9. Custom events
customEvents
| where timestamp > ago(24h)
| summarize count() by name
| order by count_ desc

# 10. Dependency failures
dependencies
| where timestamp > ago(24h)
| where success == false
| project timestamp, name, duration, target, resultCode
| order by timestamp desc
EOF
    
    print_success "Kusto queries created"
}

# Function to set up cost monitoring
setup_cost_monitoring() {
    print_status "Setting up cost monitoring..."
    
    # Create budget alert
    az consumption budget create \
        --budget-name "wine-quality-budget" \
        --resource-group "$AZURE_RESOURCE_GROUP" \
        --amount 100 \
        --time-grain "Monthly" \
        --start-date "2024-01-01" \
        --end-date "2024-12-31" \
        --category "Cost" \
        --notifications amount=80 operator="GreaterThan" contact-emails="admin@yourdomain.com" \
        --notifications amount=100 operator="GreaterThan" contact-emails="admin@yourdomain.com"
    
    print_success "Cost monitoring configured"
}

# Function to display monitoring summary
display_summary() {
    echo ""
    echo "🍷 Azure Monitoring Setup Complete!"
    echo "==================================="
    echo ""
    echo "📋 Summary:"
    echo "  Log Analytics Workspace: wine-quality-logs"
    echo "  Application Insights: ${BACKEND_APP_NAME}-insights"
    echo "  Action Group: wine-quality-alerts"
    echo "  Dashboard: wine-quality-dashboard"
    echo ""
    echo "🔍 Monitoring Features:"
    echo "  ✅ Application Insights enabled"
    echo "  ✅ Log Analytics workspace created"
    echo "  ✅ Diagnostic settings configured"
    echo "  ✅ Availability tests set up"
    echo "  ✅ Custom metrics created"
    echo "  ✅ Alerts configured"
    echo "  ✅ Dashboard created"
    echo "  ✅ Cost monitoring enabled"
    echo ""
    echo "🌐 URLs:"
    echo "  Application Insights: https://portal.azure.com/#@/resource/subscriptions/$AZURE_SUBSCRIPTION_ID/resourceGroups/$AZURE_RESOURCE_GROUP/providers/microsoft.insights/components/${BACKEND_APP_NAME}-insights"
    echo "  Log Analytics: https://portal.azure.com/#@/resource/subscriptions/$AZURE_SUBSCRIPTION_ID/resourceGroups/$AZURE_RESOURCE_GROUP/providers/Microsoft.OperationalInsights/workspaces/wine-quality-logs"
    echo "  Dashboard: https://portal.azure.com/#@/resource/subscriptions/$AZURE_SUBSCRIPTION_ID/resourceGroups/$AZURE_RESOURCE_GROUP/providers/Microsoft.Portal/dashboards/wine-quality-dashboard"
    echo ""
    echo "📊 Alerts Created:"
    echo "  • High error rate (>5%)"
    echo "  • Slow response time (>2s)"
    echo "  • Application down"
    echo "  • High memory usage (>80%)"
    echo "  • High CPU usage (>80%)"
    echo ""
    echo "📚 Documentation:"
    echo "  Kusto queries: azure/kusto-queries.txt"
    echo "  Dashboard config: azure/dashboard.json"
    echo ""
    echo "🚀 Next steps:"
    echo "  1. Configure notification recipients"
    echo "  2. Set up additional custom metrics"
    echo "  3. Create custom dashboards"
    echo "  4. Set up automated reports"
}

# Function to save monitoring info
save_monitoring_info() {
    print_status "Saving monitoring information..."
    
    cat >> azure/.env.azure << EOF

# Monitoring Configuration
LOG_ANALYTICS_WORKSPACE=wine-quality-logs
APP_INSIGHTS_NAME=${BACKEND_APP_NAME}-insights
DASHBOARD_NAME=wine-quality-dashboard
ACTION_GROUP_NAME=wine-quality-alerts
EOF
    
    print_success "Monitoring information saved to azure/.env.azure"
}

# Main execution
main() {
    echo "Starting Azure monitoring setup..."
    echo ""
    
    # Check prerequisites
    check_env_file
    check_azure_login
    
    # Set up monitoring
    create_log_analytics_workspace
    enable_application_insights
    configure_diagnostic_settings
    create_custom_metrics
    create_availability_tests
    create_action_groups
    create_alerts
    create_dashboard
    create_kusto_queries
    setup_cost_monitoring
    
    # Save information and display summary
    save_monitoring_info
    display_summary
}

# Run main function
main "$@"

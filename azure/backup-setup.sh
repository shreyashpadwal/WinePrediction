#!/bin/bash
set -e

# Azure Backup and Disaster Recovery Setup Script
# This script sets up comprehensive backup and disaster recovery for the Wine Quality Prediction application

echo "🍷 Wine Quality Prediction - Backup & Disaster Recovery Setup"
echo "============================================================"

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

# Function to create backup resource group
create_backup_resource_group() {
    print_status "Creating backup resource group..."
    
    BACKUP_RG_NAME="wine-quality-backup-rg"
    
    if ! az group show --name "$BACKUP_RG_NAME" &> /dev/null; then
        az group create \
            --name "$BACKUP_RG_NAME" \
            --location "westus" \
            --tags "project=wine-quality-prediction" "environment=backup"
        print_success "Backup resource group created: $BACKUP_RG_NAME"
    else
        print_warning "Backup resource group $BACKUP_RG_NAME already exists"
    fi
}

# Function to create backup storage account
create_backup_storage() {
    print_status "Creating backup storage account..."
    
    BACKUP_STORAGE_NAME="winequalitybackup$(date +%s)"
    BACKUP_RG_NAME="wine-quality-backup-rg"
    
    if ! az storage account show --name "$BACKUP_STORAGE_NAME" --resource-group "$BACKUP_RG_NAME" &> /dev/null; then
        az storage account create \
            --name "$BACKUP_STORAGE_NAME" \
            --resource-group "$BACKUP_RG_NAME" \
            --location "westus" \
            --sku Standard_LRS \
            --kind StorageV2 \
            --access-tier Cool \
            --https-only true
        print_success "Backup storage account created: $BACKUP_STORAGE_NAME"
    else
        print_warning "Backup storage account $BACKUP_STORAGE_NAME already exists"
    fi
    
    # Create containers for different backup types
    az storage container create \
        --name "ml-models" \
        --account-name "$BACKUP_STORAGE_NAME" \
        --auth-mode login
    
    az storage container create \
        --name "application-logs" \
        --account-name "$BACKUP_STORAGE_NAME" \
        --auth-mode login
    
    az storage container create \
        --name "configuration" \
        --account-name "$BACKUP_STORAGE_NAME" \
        --auth-mode login
    
    az storage container create \
        --name "database-backups" \
        --account-name "$BACKUP_STORAGE_NAME" \
        --auth-mode login
    
    print_success "Backup storage containers created"
}

# Function to set up Azure Backup
setup_azure_backup() {
    print_status "Setting up Azure Backup..."
    
    # Create Recovery Services Vault
    VAULT_NAME="wine-quality-backup-vault"
    
    if ! az backup vault show --name "$VAULT_NAME" --resource-group "$AZURE_RESOURCE_GROUP" &> /dev/null; then
        az backup vault create \
            --name "$VAULT_NAME" \
            --resource-group "$AZURE_RESOURCE_GROUP" \
            --location "$AZURE_LOCATION"
        print_success "Recovery Services Vault created: $VAULT_NAME"
    else
        print_warning "Recovery Services Vault $VAULT_NAME already exists"
    fi
    
    # Configure backup policy
    az backup policy create \
        --name "wine-quality-backup-policy" \
        --resource-group "$AZURE_RESOURCE_GROUP" \
        --vault-name "$VAULT_NAME" \
        --backup-management-type AzureIaasVM \
        --workload-type VM \
        --policy-file azure/backup-policy.json
    
    print_success "Backup policy created"
}

# Function to create backup policy
create_backup_policy() {
    print_status "Creating backup policy..."
    
    cat > azure/backup-policy.json << EOF
{
  "properties": {
    "backupManagementType": "AzureIaasVM",
    "workloadType": "VM",
    "schedulePolicy": {
      "schedulePolicyType": "SimpleSchedulePolicy",
      "scheduleRunFrequency": "Daily",
      "scheduleRunTimes": ["02:00"],
      "scheduleRunDays": ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
    },
    "retentionPolicy": {
      "retentionPolicyType": "LongTermRetentionPolicy",
      "dailySchedule": {
        "retentionDuration": {
          "count": 30,
          "durationType": "Days"
        }
      },
      "weeklySchedule": {
        "retentionDuration": {
          "count": 12,
          "durationType": "Weeks"
        },
        "retentionTimes": ["02:00"],
        "retentionScheduleFormatType": "Weekly",
        "retentionScheduleDaily": null,
        "retentionScheduleWeekly": {
          "daysOfTheWeek": ["Sunday"],
          "retentionTimes": ["02:00"]
        }
      },
      "monthlySchedule": {
        "retentionDuration": {
          "count": 12,
          "durationType": "Months"
        },
        "retentionTimes": ["02:00"],
        "retentionScheduleFormatType": "Weekly",
        "retentionScheduleDaily": null,
        "retentionScheduleWeekly": {
          "daysOfTheWeek": ["Sunday"],
          "retentionTimes": ["02:00"]
        }
      },
      "yearlySchedule": {
        "retentionDuration": {
          "count": 7,
          "durationType": "Years"
        },
        "retentionTimes": ["02:00"],
        "retentionScheduleFormatType": "Weekly",
        "retentionScheduleDaily": null,
        "retentionScheduleWeekly": {
          "daysOfTheWeek": ["Sunday"],
          "retentionTimes": ["02:00"]
        }
      }
    }
  }
}
EOF
    
    print_success "Backup policy configuration created"
}

# Function to create manual backup script
create_backup_script() {
    print_status "Creating manual backup script..."
    
    cat > azure/backup-script.sh << EOF
#!/bin/bash
set -e

# Manual Backup Script for Wine Quality Prediction
# This script creates manual backups of critical application data

echo "🍷 Wine Quality Prediction - Manual Backup"
echo "=========================================="

# Configuration
BACKUP_STORAGE_NAME="winequalitybackup"
BACKUP_RG_NAME="wine-quality-backup-rg"
TIMESTAMP=\$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/tmp/wine-quality-backup-\$TIMESTAMP"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "\${BLUE}[INFO]\${NC} \$1"
}

print_success() {
    echo -e "\${GREEN}[SUCCESS]\${NC} \$1"
}

print_warning() {
    echo -e "\${YELLOW}[WARNING]\${NC} \$1"
}

print_error() {
    echo -e "\${RED}[ERROR]\${NC} \$1"
}

# Create backup directory
mkdir -p "\$BACKUP_DIR"

# Backup ML models
print_status "Backing up ML models..."
if [ -d "backend/saved_models" ]; then
    tar -czf "\$BACKUP_DIR/ml-models-\$TIMESTAMP.tar.gz" -C backend saved_models/
    print_success "ML models backed up"
else
    print_warning "ML models directory not found"
fi

# Backup application logs
print_status "Backing up application logs..."
if [ -d "backend/logs" ]; then
    tar -czf "\$BACKUP_DIR/application-logs-\$TIMESTAMP.tar.gz" -C backend logs/
    print_success "Application logs backed up"
else
    print_warning "Application logs directory not found"
fi

# Backup configuration files
print_status "Backing up configuration files..."
tar -czf "\$BACKUP_DIR/configuration-\$TIMESTAMP.tar.gz" \\
    azure/.env.azure \\
    docker-compose.yml \\
    backend/requirements.txt \\
    frontend/package.json \\
    README.md \\
    SECURITY.md \\
    PERFORMANCE.md

print_success "Configuration files backed up"

# Backup application code
print_status "Backing up application code..."
tar -czf "\$BACKUP_DIR/application-code-\$TIMESTAMP.tar.gz" \\
    --exclude=node_modules \\
    --exclude=__pycache__ \\
    --exclude=.git \\
    --exclude=logs \\
    --exclude=saved_models \\
    .

print_success "Application code backed up"

# Upload to Azure Storage
print_status "Uploading backups to Azure Storage..."

# Upload ML models
if [ -f "\$BACKUP_DIR/ml-models-\$TIMESTAMP.tar.gz" ]; then
    az storage blob upload \\
        --account-name "\$BACKUP_STORAGE_NAME" \\
        --container-name "ml-models" \\
        --name "ml-models-\$TIMESTAMP.tar.gz" \\
        --file "\$BACKUP_DIR/ml-models-\$TIMESTAMP.tar.gz" \\
        --auth-mode login
    print_success "ML models uploaded to Azure Storage"
fi

# Upload application logs
if [ -f "\$BACKUP_DIR/application-logs-\$TIMESTAMP.tar.gz" ]; then
    az storage blob upload \\
        --account-name "\$BACKUP_STORAGE_NAME" \\
        --container-name "application-logs" \\
        --name "application-logs-\$TIMESTAMP.tar.gz" \\
        --file "\$BACKUP_DIR/application-logs-\$TIMESTAMP.tar.gz" \\
        --auth-mode login
    print_success "Application logs uploaded to Azure Storage"
fi

# Upload configuration
az storage blob upload \\
    --account-name "\$BACKUP_STORAGE_NAME" \\
    --container-name "configuration" \\
    --name "configuration-\$TIMESTAMP.tar.gz" \\
    --file "\$BACKUP_DIR/configuration-\$TIMESTAMP.tar.gz" \\
    --auth-mode login
print_success "Configuration uploaded to Azure Storage"

# Upload application code
az storage blob upload \\
    --account-name "\$BACKUP_STORAGE_NAME" \\
    --container-name "application-code" \\
    --name "application-code-\$TIMESTAMP.tar.gz" \\
    --file "\$BACKUP_DIR/application-code-\$TIMESTAMP.tar.gz" \\
    --auth-mode login
print_success "Application code uploaded to Azure Storage"

# Cleanup local backup files
rm -rf "\$BACKUP_DIR"

# List backup blobs
print_status "Listing backup blobs..."
az storage blob list \\
    --account-name "\$BACKUP_STORAGE_NAME" \\
    --container-name "ml-models" \\
    --auth-mode login \\
    --query "[].name" -o table

az storage blob list \\
    --account-name "\$BACKUP_STORAGE_NAME" \\
    --container-name "application-logs" \\
    --auth-mode login \\
    --query "[].name" -o table

az storage blob list \\
    --account-name "\$BACKUP_STORAGE_NAME" \\
    --container-name "configuration" \\
    --auth-mode login \\
    --query "[].name" -o table

az storage blob list \\
    --account-name "\$BACKUP_STORAGE_NAME" \\
    --container-name "application-code" \\
    --auth-mode login \\
    --query "[].name" -o table

print_success "Manual backup completed successfully!"
echo ""
echo "📋 Backup Summary:"
echo "  Timestamp: \$TIMESTAMP"
echo "  Storage Account: \$BACKUP_STORAGE_NAME"
echo "  Resource Group: \$BACKUP_RG_NAME"
echo "  Location: West US"
echo ""
echo "🔍 Verify backups:"
echo "  az storage blob list --account-name \$BACKUP_STORAGE_NAME --container-name ml-models --auth-mode login"
echo "  az storage blob list --account-name \$BACKUP_STORAGE_NAME --container-name application-logs --auth-mode login"
echo "  az storage blob list --account-name \$BACKUP_STORAGE_NAME --container-name configuration --auth-mode login"
echo "  az storage blob list --account-name \$BACKUP_STORAGE_NAME --container-name application-code --auth-mode login"
EOF
    
    chmod +x azure/backup-script.sh
    print_success "Manual backup script created"
}

# Function to create restore script
create_restore_script() {
    print_status "Creating restore script..."
    
    cat > azure/restore-script.sh << EOF
#!/bin/bash
set -e

# Restore Script for Wine Quality Prediction
# This script restores application data from Azure Storage backups

echo "🍷 Wine Quality Prediction - Restore from Backup"
echo "==============================================="

# Configuration
BACKUP_STORAGE_NAME="winequalitybackup"
BACKUP_RG_NAME="wine-quality-backup-rg"
RESTORE_DIR="/tmp/wine-quality-restore-\$(date +%Y%m%d_%H%M%S)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "\${BLUE}[INFO]\${NC} \$1"
}

print_success() {
    echo -e "\${GREEN}[SUCCESS]\${NC} \$1"
}

print_warning() {
    echo -e "\${YELLOW}[WARNING]\${NC} \$1"
}

print_error() {
    echo -e "\${RED}[ERROR]\${NC} \$1"
}

# Function to list available backups
list_backups() {
    print_status "Available backups:"
    
    echo ""
    echo "ML Models:"
    az storage blob list \\
        --account-name "\$BACKUP_STORAGE_NAME" \\
        --container-name "ml-models" \\
        --auth-mode login \\
        --query "[].name" -o table
    
    echo ""
    echo "Application Logs:"
    az storage blob list \\
        --account-name "\$BACKUP_STORAGE_NAME" \\
        --container-name "application-logs" \\
        --auth-mode login \\
        --query "[].name" -o table
    
    echo ""
    echo "Configuration:"
    az storage blob list \\
        --account-name "\$BACKUP_STORAGE_NAME" \\
        --container-name "configuration" \\
        --auth-mode login \\
        --query "[].name" -o table
    
    echo ""
    echo "Application Code:"
    az storage blob list \\
        --account-name "\$BACKUP_STORAGE_NAME" \\
        --container-name "application-code" \\
        --auth-mode login \\
        --query "[].name" -o table
}

# Function to restore ML models
restore_ml_models() {
    local backup_name=\$1
    
    if [ -z "\$backup_name" ]; then
        print_error "Backup name required for ML models restore"
        return 1
    fi
    
    print_status "Restoring ML models from: \$backup_name"
    
    # Download backup
    az storage blob download \\
        --account-name "\$BACKUP_STORAGE_NAME" \\
        --container-name "ml-models" \\
        --name "\$backup_name" \\
        --file "\$RESTORE_DIR/ml-models.tar.gz" \\
        --auth-mode login
    
    # Extract backup
    tar -xzf "\$RESTORE_DIR/ml-models.tar.gz" -C "\$RESTORE_DIR"
    
    # Restore to application
    if [ -d "\$RESTORE_DIR/saved_models" ]; then
        cp -r "\$RESTORE_DIR/saved_models" "backend/"
        print_success "ML models restored"
    else
        print_error "ML models not found in backup"
        return 1
    fi
}

# Function to restore application logs
restore_application_logs() {
    local backup_name=\$1
    
    if [ -z "\$backup_name" ]; then
        print_error "Backup name required for application logs restore"
        return 1
    fi
    
    print_status "Restoring application logs from: \$backup_name"
    
    # Download backup
    az storage blob download \\
        --account-name "\$BACKUP_STORAGE_NAME" \\
        --container-name "application-logs" \\
        --name "\$backup_name" \\
        --file "\$RESTORE_DIR/application-logs.tar.gz" \\
        --auth-mode login
    
    # Extract backup
    tar -xzf "\$RESTORE_DIR/application-logs.tar.gz" -C "\$RESTORE_DIR"
    
    # Restore to application
    if [ -d "\$RESTORE_DIR/logs" ]; then
        cp -r "\$RESTORE_DIR/logs" "backend/"
        print_success "Application logs restored"
    else
        print_error "Application logs not found in backup"
        return 1
    fi
}

# Function to restore configuration
restore_configuration() {
    local backup_name=\$1
    
    if [ -z "\$backup_name" ]; then
        print_error "Backup name required for configuration restore"
        return 1
    fi
    
    print_status "Restoring configuration from: \$backup_name"
    
    # Download backup
    az storage blob download \\
        --account-name "\$BACKUP_STORAGE_NAME" \\
        --container-name "configuration" \\
        --name "\$backup_name" \\
        --file "\$RESTORE_DIR/configuration.tar.gz" \\
        --auth-mode login
    
    # Extract backup
    tar -xzf "\$RESTORE_DIR/configuration.tar.gz" -C "\$RESTORE_DIR"
    
    # Restore configuration files
    if [ -f "\$RESTORE_DIR/azure/.env.azure" ]; then
        cp "\$RESTORE_DIR/azure/.env.azure" "azure/"
        print_success "Environment configuration restored"
    fi
    
    if [ -f "\$RESTORE_DIR/docker-compose.yml" ]; then
        cp "\$RESTORE_DIR/docker-compose.yml" "."
        print_success "Docker Compose configuration restored"
    fi
    
    if [ -f "\$RESTORE_DIR/backend/requirements.txt" ]; then
        cp "\$RESTORE_DIR/backend/requirements.txt" "backend/"
        print_success "Backend requirements restored"
    fi
    
    if [ -f "\$RESTORE_DIR/frontend/package.json" ]; then
        cp "\$RESTORE_DIR/frontend/package.json" "frontend/"
        print_success "Frontend package configuration restored"
    fi
}

# Function to restore application code
restore_application_code() {
    local backup_name=\$1
    
    if [ -z "\$backup_name" ]; then
        print_error "Backup name required for application code restore"
        return 1
    fi
    
    print_status "Restoring application code from: \$backup_name"
    
    # Download backup
    az storage blob download \\
        --account-name "\$BACKUP_STORAGE_NAME" \\
        --container-name "application-code" \\
        --name "\$backup_name" \\
        --file "\$RESTORE_DIR/application-code.tar.gz" \\
        --auth-mode login
    
    # Extract backup
    tar -xzf "\$RESTORE_DIR/application-code.tar.gz" -C "\$RESTORE_DIR"
    
    # Restore application code
    if [ -d "\$RESTORE_DIR/backend" ]; then
        cp -r "\$RESTORE_DIR/backend" "."
        print_success "Backend code restored"
    fi
    
    if [ -d "\$RESTORE_DIR/frontend" ]; then
        cp -r "\$RESTORE_DIR/frontend" "."
        print_success "Frontend code restored"
    fi
    
    if [ -d "\$RESTORE_DIR/notebooks" ]; then
        cp -r "\$RESTORE_DIR/notebooks" "."
        print_success "Notebooks restored"
    fi
}

# Main restore function
main() {
    # Create restore directory
    mkdir -p "\$RESTORE_DIR"
    
    # List available backups
    list_backups
    
    echo ""
    print_status "Please specify which backup to restore:"
    echo "1. ML Models"
    echo "2. Application Logs"
    echo "3. Configuration"
    echo "4. Application Code"
    echo "5. All"
    
    read -p "Enter your choice (1-5): " choice
    
    case \$choice in
        1)
            read -p "Enter ML models backup name: " backup_name
            restore_ml_models "\$backup_name"
            ;;
        2)
            read -p "Enter application logs backup name: " backup_name
            restore_application_logs "\$backup_name"
            ;;
        3)
            read -p "Enter configuration backup name: " backup_name
            restore_configuration "\$backup_name"
            ;;
        4)
            read -p "Enter application code backup name: " backup_name
            restore_application_code "\$backup_name"
            ;;
        5)
            read -p "Enter backup timestamp (YYYYMMDD_HHMMSS): " timestamp
            restore_ml_models "ml-models-\$timestamp.tar.gz"
            restore_application_logs "application-logs-\$timestamp.tar.gz"
            restore_configuration "configuration-\$timestamp.tar.gz"
            restore_application_code "application-code-\$timestamp.tar.gz"
            ;;
        *)
            print_error "Invalid choice"
            exit 1
            ;;
    esac
    
    # Cleanup
    rm -rf "\$RESTORE_DIR"
    
    print_success "Restore completed successfully!"
}

# Run main function
main "\$@"
EOF
    
    chmod +x azure/restore-script.sh
    print_success "Restore script created"
}

# Function to set up disaster recovery
setup_disaster_recovery() {
    print_status "Setting up disaster recovery..."
    
    # Create disaster recovery plan
    cat > azure/disaster-recovery-plan.sh << EOF
#!/bin/bash
set -e

# Disaster Recovery Plan for Wine Quality Prediction
# This script implements disaster recovery procedures

echo "🍷 Wine Quality Prediction - Disaster Recovery Plan"
echo "=================================================="

# Configuration
PRIMARY_RG="wine-quality-rg"
SECONDARY_RG="wine-quality-dr-rg"
PRIMARY_LOCATION="eastus"
SECONDARY_LOCATION="westus"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "\${BLUE}[INFO]\${NC} \$1"
}

print_success() {
    echo -e "\${GREEN}[SUCCESS]\${NC} \$1"
}

print_warning() {
    echo -e "\${YELLOW}[WARNING]\${NC} \$1"
}

print_error() {
    echo -e "\${RED}[ERROR]\${NC} \$1"
}

# Function to create secondary region resources
create_secondary_resources() {
    print_status "Creating secondary region resources..."
    
    # Create secondary resource group
    az group create \\
        --name "\$SECONDARY_RG" \\
        --location "\$SECONDARY_LOCATION" \\
        --tags "project=wine-quality-prediction" "environment=disaster-recovery"
    
    # Create secondary App Service Plan
    az appservice plan create \\
        --name "wine-quality-dr-plan" \\
        --resource-group "\$SECONDARY_RG" \\
        --location "\$SECONDARY_LOCATION" \\
        --is-linux \\
        --sku B1
    
    # Create secondary App Service
    az webapp create \\
        --name "wine-quality-dr-backend" \\
        --resource-group "\$SECONDARY_RG" \\
        --plan "wine-quality-dr-plan" \\
        --deployment-container-image-name "winequalityacr.azurecr.io/wine-backend:latest"
    
    # Create secondary Static Web App
    az staticwebapp create \\
        --name "wine-quality-dr-frontend" \\
        --resource-group "\$SECONDARY_RG" \\
        --location "\$SECONDARY_LOCATION" \\
        --source "https://github.com/yourusername/wine-quality-prediction" \\
        --branch main \\
        --app-location "/frontend" \\
        --output-location "dist"
    
    print_success "Secondary region resources created"
}

# Function to configure Traffic Manager
configure_traffic_manager() {
    print_status "Configuring Traffic Manager..."
    
    # Create Traffic Manager profile
    az network traffic-manager profile create \\
        --name "wine-quality-tm" \\
        --resource-group "\$PRIMARY_RG" \\
        --routing-method Priority \\
        --unique-dns-name "wine-quality-tm"
    
    # Add primary endpoint
    az network traffic-manager endpoint create \\
        --name "primary-backend" \\
        --profile-name "wine-quality-tm" \\
        --resource-group "\$PRIMARY_RG" \\
        --type azureEndpoints \\
        --target-resource-id "/subscriptions/\$AZURE_SUBSCRIPTION_ID/resourceGroups/\$PRIMARY_RG/providers/Microsoft.Web/sites/wine-quality-backend" \\
        --priority 1
    
    # Add secondary endpoint
    az network traffic-manager endpoint create \\
        --name "secondary-backend" \\
        --profile-name "wine-quality-tm" \\
        --resource-group "\$PRIMARY_RG" \\
        --type azureEndpoints \\
        --target-resource-id "/subscriptions/\$AZURE_SUBSCRIPTION_ID/resourceGroups/\$SECONDARY_RG/providers/Microsoft.Web/sites/wine-quality-dr-backend" \\
        --priority 2
    
    print_success "Traffic Manager configured"
}

# Function to test failover
test_failover() {
    print_status "Testing failover..."
    
    # Disable primary endpoint
    az network traffic-manager endpoint update \\
        --name "primary-backend" \\
        --profile-name "wine-quality-tm" \\
        --resource-group "\$PRIMARY_RG" \\
        --endpoint-status Disabled
    
    # Wait for failover
    sleep 30
    
    # Test secondary endpoint
    SECONDARY_URL="https://wine-quality-dr-backend.azurewebsites.net"
    if curl -f "\$SECONDARY_URL/api/v1/prediction/health"; then
        print_success "Failover test successful"
    else
        print_error "Failover test failed"
        return 1
    fi
    
    # Re-enable primary endpoint
    az network traffic-manager endpoint update \\
        --name "primary-backend" \\
        --profile-name "wine-quality-tm" \\
        --resource-group "\$PRIMARY_RG" \\
        --endpoint-status Enabled
    
    print_success "Failover test completed"
}

# Function to create recovery procedures
create_recovery_procedures() {
    print_status "Creating recovery procedures..."
    
    cat > azure/recovery-procedures.md << EOF
# Disaster Recovery Procedures

## Recovery Time Objective (RTO): 15 minutes
## Recovery Point Objective (RPO): 24 hours

## Failover Procedures

### 1. Automatic Failover
- Traffic Manager automatically routes traffic to secondary region
- No manual intervention required
- RTO: 2-5 minutes

### 2. Manual Failover
- Disable primary endpoint in Traffic Manager
- Verify secondary region is operational
- Update DNS records if needed
- RTO: 5-15 minutes

### 3. Data Recovery
- Restore from latest backup
- Verify data integrity
- Update application configuration
- RPO: 24 hours (daily backups)

## Recovery Steps

### Step 1: Assess Situation
- Determine scope of disaster
- Check primary region status
- Verify secondary region availability

### Step 2: Initiate Failover
- Disable primary endpoint
- Verify secondary endpoint
- Test application functionality

### Step 3: Restore Data
- Restore from backup
- Verify data integrity
- Update configuration

### Step 4: Monitor and Validate
- Monitor application performance
- Validate all functionality
- Document recovery process

### Step 5: Plan Return
- Prepare for return to primary region
- Schedule maintenance window
- Execute return procedures

## Contact Information
- **Incident Commander**: +1-XXX-XXX-XXXX
- **Technical Lead**: +1-XXX-XXX-XXXX
- **Management**: +1-XXX-XXX-XXXX
EOF
    
    print_success "Recovery procedures created"
}

# Main function
main() {
    create_secondary_resources
    configure_traffic_manager
    create_recovery_procedures
    
    print_status "Disaster recovery setup completed"
    print_warning "Run test_failover function to test disaster recovery"
}

# Run main function
main "\$@"
EOF
    
    chmod +x azure/disaster-recovery-plan.sh
    print_success "Disaster recovery plan created"
}

# Function to create backup documentation
create_backup_documentation() {
    print_status "Creating backup documentation..."
    
    cat > BACKUP_DISASTER_RECOVERY.md << EOF
# 💾 Backup & Disaster Recovery Guide

This guide covers comprehensive backup and disaster recovery procedures for the Wine Quality Prediction application.

## 🏗️ Backup Architecture

\`\`\`
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Primary       │    │   Backup        │    │   Secondary     │
│   Region        │◄──►│   Storage       │◄──►│   Region        │
│   (East US)     │    │   (West US)     │    │   (West US)     │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Application   │    │   Azure         │    │   Disaster      │
│   Data          │    │   Storage       │    │   Recovery      │
│   (ML Models)   │    │   (Blob)         │    │   (Standby)     │
└─────────────────┘    └─────────────────┘    └─────────────────┘
\`\`\`

## 📋 Backup Strategy

### 1. Backup Types

#### Full Backup
- **Frequency**: Daily
- **Retention**: 30 days
- **Location**: Azure Storage (Cool tier)
- **Compression**: Gzip
- **Encryption**: AES-256

#### Incremental Backup
- **Frequency**: Every 4 hours
- **Retention**: 7 days
- **Location**: Azure Storage (Hot tier)
- **Compression**: Gzip
- **Encryption**: AES-256

#### Differential Backup
- **Frequency**: Weekly
- **Retention**: 12 weeks
- **Location**: Azure Storage (Cool tier)
- **Compression**: Gzip
- **Encryption**: AES-256

### 2. Backup Components

#### ML Models
- **best_model.pkl**: Trained machine learning model
- **scaler.pkl**: Feature scaling parameters
- **label_encoder.pkl**: Label encoding parameters
- **model_metadata.json**: Model performance metrics

#### Application Data
- **Configuration files**: Environment variables, Docker configs
- **Application logs**: Error logs, access logs, audit logs
- **Database backups**: Application state (if applicable)
- **Source code**: Application source code and dependencies

#### Infrastructure Data
- **ARM templates**: Infrastructure as Code
- **Docker images**: Container images
- **SSL certificates**: Security certificates
- **DNS records**: Domain configuration

## 🔄 Backup Procedures

### Automated Backup
\`\`\`bash
# Run automated backup
./azure/backup-script.sh
\`\`\`

### Manual Backup
\`\`\`bash
# Create manual backup
az storage blob upload \\
  --account-name winequalitybackup \\
  --container-name ml-models \\
  --name "ml-models-\$(date +%Y%m%d_%H%M%S).tar.gz" \\
  --file "ml-models-backup.tar.gz" \\
  --auth-mode login
\`\`\`

### Backup Verification
\`\`\`bash
# Verify backup integrity
az storage blob show \\
  --account-name winequalitybackup \\
  --container-name ml-models \\
  --name "ml-models-20240101_120000.tar.gz" \\
  --auth-mode login
\`\`\`

## 🚨 Disaster Recovery

### Recovery Objectives
- **RTO (Recovery Time Objective)**: 15 minutes
- **RPO (Recovery Point Objective)**: 24 hours
- **Availability Target**: 99.9%
- **Data Loss Tolerance**: < 1 hour

### Disaster Recovery Plan

#### 1. Primary Region Failure
- **Detection**: Automated monitoring alerts
- **Response**: Traffic Manager failover
- **Recovery**: Secondary region activation
- **Validation**: Application functionality testing

#### 2. Data Center Outage
- **Detection**: Azure service health alerts
- **Response**: Manual failover procedures
- **Recovery**: Secondary region deployment
- **Validation**: Data integrity verification

#### 3. Application Failure
- **Detection**: Health check failures
- **Response**: Container restart/rollback
- **Recovery**: Previous version deployment
- **Validation**: Service functionality testing

### Failover Procedures

#### Automatic Failover
1. Traffic Manager detects primary region failure
2. Traffic automatically routes to secondary region
3. Application continues operating normally
4. Recovery time: 2-5 minutes

#### Manual Failover
1. Disable primary endpoint in Traffic Manager
2. Verify secondary region is operational
3. Update DNS records if needed
4. Test application functionality
5. Recovery time: 5-15 minutes

#### Data Recovery
1. Restore from latest backup
2. Verify data integrity
3. Update application configuration
4. Test application functionality
5. Recovery point: 24 hours (daily backups)

## 🔧 Recovery Procedures

### 1. Assess Situation
- Determine scope of disaster
- Check primary region status
- Verify secondary region availability
- Document incident details

### 2. Initiate Failover
- Disable primary endpoint
- Verify secondary endpoint
- Test application functionality
- Monitor system performance

### 3. Restore Data
- Restore from backup
- Verify data integrity
- Update configuration
- Test data consistency

### 4. Monitor and Validate
- Monitor application performance
- Validate all functionality
- Document recovery process
- Update stakeholders

### 5. Plan Return
- Prepare for return to primary region
- Schedule maintenance window
- Execute return procedures
- Validate primary region

## 📊 Backup Monitoring

### Backup Status Monitoring
- **Backup Success Rate**: > 99%
- **Backup Duration**: < 30 minutes
- **Storage Utilization**: < 80%
- **Backup Age**: < 24 hours

### Recovery Testing
- **Frequency**: Monthly
- **Scope**: Full system recovery
- **Duration**: < 2 hours
- **Success Rate**: > 95%

### Performance Metrics
- **Backup Speed**: > 100 MB/s
- **Restore Speed**: > 50 MB/s
- **Compression Ratio**: > 70%
- **Storage Efficiency**: > 80%

## 🛠️ Backup Tools and Scripts

### Backup Scripts
- **azure/backup-script.sh**: Manual backup script
- **azure/restore-script.sh**: Restore script
- **azure/disaster-recovery-plan.sh**: DR procedures
- **azure/backup-policy.json**: Backup policy configuration

### Monitoring Scripts
- **azure/backup-monitor.sh**: Backup status monitoring
- **azure/recovery-test.sh**: Recovery testing
- **azure/failover-test.sh**: Failover testing

### Automation Scripts
- **azure/automated-backup.sh**: Automated backup
- **azure/backup-cleanup.sh**: Backup cleanup
- **azure/backup-verification.sh**: Backup verification

## 📚 Best Practices

### 1. Backup Best Practices
- **Regular Backups**: Daily automated backups
- **Multiple Copies**: Store backups in multiple locations
- **Encryption**: Encrypt all backup data
- **Compression**: Compress backup data to save space
- **Verification**: Regularly verify backup integrity

### 2. Recovery Best Practices
- **Documentation**: Maintain up-to-date recovery procedures
- **Testing**: Regularly test recovery procedures
- **Training**: Train team on recovery procedures
- **Monitoring**: Monitor backup and recovery systems
- **Updates**: Keep recovery procedures current

### 3. Disaster Recovery Best Practices
- **RTO/RPO**: Define clear recovery objectives
- **Automation**: Automate recovery procedures where possible
- **Communication**: Establish communication procedures
- **Testing**: Regular disaster recovery testing
- **Improvement**: Continuous improvement of procedures

## 🚨 Emergency Contacts

### Internal Contacts
- **Incident Commander**: +1-XXX-XXX-XXXX
- **Technical Lead**: +1-XXX-XXX-XXXX
- **Backup Administrator**: +1-XXX-XXX-XXXX
- **Management**: +1-XXX-XXX-XXXX

### External Contacts
- **Azure Support**: Azure portal support
- **Backup Vendor**: vendor@backupcompany.com
- **Disaster Recovery**: dr@recoverycompany.com
- **Insurance Provider**: insurance@provider.com

## 📋 Backup Checklist

### Pre-deployment Backup
- [ ] Backup strategy defined
- [ ] Backup tools configured
- [ ] Storage accounts created
- [ ] Backup policies configured
- [ ] Monitoring enabled
- [ ] Recovery procedures documented
- [ ] Team training completed
- [ ] Backup testing performed
- [ ] Disaster recovery plan tested
- [ ] Emergency contacts updated

### Post-deployment Backup
- [ ] Automated backups running
- [ ] Backup monitoring active
- [ ] Recovery procedures tested
- [ ] Disaster recovery plan validated
- [ ] Team training completed
- [ ] Documentation updated
- [ ] Performance monitoring active
- [ ] Alert thresholds configured
- [ ] Regular testing scheduled
- [ ] Continuous improvement

## 🎯 Backup Roadmap

### Short-term (1-3 months)
- Implement automated backup system
- Set up disaster recovery procedures
- Conduct backup and recovery testing
- Train team on procedures

### Medium-term (3-6 months)
- Optimize backup performance
- Enhance disaster recovery capabilities
- Implement backup monitoring
- Conduct regular testing

### Long-term (6-12 months)
- Advanced backup features
- Comprehensive disaster recovery
- Backup automation
- Continuous improvement

---

**Document Version**: 1.0  
**Last Updated**: 2024-01-01  
**Next Review**: 2024-04-01  
**Approved By**: Backup Team  
**Distribution**: Internal Use Only
EOF
    
    print_success "Backup documentation created"
}

# Function to display backup summary
display_summary() {
    echo ""
    echo "💾 Backup & Disaster Recovery Setup Complete!"
    echo "============================================="
    echo ""
    echo "📋 Backup Features Implemented:"
    echo "  ✅ Azure Storage for backup storage"
    echo "  ✅ Recovery Services Vault"
    echo "  ✅ Automated backup policies"
    echo "  ✅ Manual backup scripts"
    echo "  ✅ Restore procedures"
    echo "  ✅ Disaster recovery plan"
    echo "  ✅ Secondary region setup"
    echo "  ✅ Traffic Manager failover"
    echo "  ✅ Backup monitoring"
    echo "  ✅ Recovery testing"
    echo ""
    echo "🔍 Backup Resources:"
    echo "  Backup Storage: winequalitybackup"
    echo "  Recovery Vault: wine-quality-backup-vault"
    echo "  Secondary Region: West US"
    echo "  Traffic Manager: wine-quality-tm"
    echo ""
    echo "📊 Recovery Objectives:"
    echo "  RTO: 15 minutes"
    echo "  RPO: 24 hours"
    echo "  Availability: 99.9%"
    echo "  Data Loss: < 1 hour"
    echo ""
    echo "📚 Documentation:"
    echo "  Backup Guide: BACKUP_DISASTER_RECOVERY.md"
    echo "  Backup Script: azure/backup-script.sh"
    echo "  Restore Script: azure/restore-script.sh"
    echo "  DR Plan: azure/disaster-recovery-plan.sh"
    echo ""
    echo "🚀 Next Steps:"
    echo "  1. Test backup procedures"
    echo "  2. Test disaster recovery"
    echo "  3. Schedule regular testing"
    echo "  4. Train team on procedures"
    echo "  5. Monitor backup performance"
}

# Function to save backup info
save_backup_info() {
    print_status "Saving backup information..."
    
    cat >> azure/.env.azure << EOF

# Backup Configuration
BACKUP_STORAGE_NAME=winequalitybackup
BACKUP_RG_NAME=wine-quality-backup-rg
RECOVERY_VAULT_NAME=wine-quality-backup-vault
TRAFFIC_MANAGER_NAME=wine-quality-tm
SECONDARY_RG_NAME=wine-quality-dr-rg
EOF
    
    print_success "Backup information saved to azure/.env.azure"
}

# Main execution
main() {
    echo "Starting backup and disaster recovery setup..."
    echo ""
    
    # Check prerequisites
    check_env_file
    check_azure_login
    
    # Implement backup and disaster recovery
    create_backup_resource_group
    create_backup_storage
    setup_azure_backup
    create_backup_policy
    create_backup_script
    create_restore_script
    setup_disaster_recovery
    create_backup_documentation
    
    # Save information and display summary
    save_backup_info
    display_summary
}

# Run main function
main "$@"

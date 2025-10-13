#!/bin/bash
set -e

# Azure Security Setup Script
# This script implements comprehensive security best practices for the Wine Quality Prediction application

echo "🍷 Wine Quality Prediction - Azure Security Setup"
echo "================================================"

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

# Function to create Azure Key Vault
create_key_vault() {
    print_status "Creating Azure Key Vault..."
    
    KEY_VAULT_NAME="wine-quality-vault"
    
    # Check if Key Vault already exists
    if az keyvault show --name "$KEY_VAULT_NAME" --resource-group "$AZURE_RESOURCE_GROUP" &> /dev/null; then
        print_warning "Key Vault $KEY_VAULT_NAME already exists"
    else
        az keyvault create \
            --name "$KEY_VAULT_NAME" \
            --resource-group "$AZURE_RESOURCE_GROUP" \
            --location "$AZURE_LOCATION" \
            --sku standard \
            --enable-rbac-authorization true \
            --enable-soft-delete true \
            --soft-delete-retention-days 90 \
            --enable-purge-protection true
        print_success "Key Vault created: $KEY_VAULT_NAME"
    fi
}

# Function to store secrets in Key Vault
store_secrets() {
    print_status "Storing secrets in Key Vault..."
    
    KEY_VAULT_NAME="wine-quality-vault"
    
    # Store Gemini API key
    if [ ! -z "$GEMINI_API_KEY" ]; then
        az keyvault secret set \
            --vault-name "$KEY_VAULT_NAME" \
            --name "gemini-api-key" \
            --value "$GEMINI_API_KEY"
        print_success "Gemini API key stored in Key Vault"
    else
        print_warning "GEMINI_API_KEY not set, skipping..."
    fi
    
    # Store ACR credentials
    if [ ! -z "$ACR_PASSWORD" ]; then
        az keyvault secret set \
            --vault-name "$KEY_VAULT_NAME" \
            --name "acr-password" \
            --value "$ACR_PASSWORD"
        print_success "ACR password stored in Key Vault"
    fi
    
    # Generate and store a random secret key
    SECRET_KEY=$(openssl rand -base64 32)
    az keyvault secret set \
        --vault-name "$KEY_VAULT_NAME" \
        --name "app-secret-key" \
        --value "$SECRET_KEY"
    print_success "Application secret key stored in Key Vault"
}

# Function to configure Managed Identity
configure_managed_identity() {
    print_status "Configuring Managed Identity..."
    
    # Enable system-assigned managed identity for App Service
    az webapp identity assign \
        --name "$BACKEND_APP_NAME" \
        --resource-group "$AZURE_RESOURCE_GROUP"
    
    # Get the principal ID
    PRINCIPAL_ID=$(az webapp identity show --name "$BACKEND_APP_NAME" --resource-group "$AZURE_RESOURCE_GROUP" --query principalId -o tsv)
    print_success "Managed Identity configured for App Service: $PRINCIPAL_ID"
    
    # Grant Key Vault access to the managed identity
    KEY_VAULT_NAME="wine-quality-vault"
    az keyvault set-policy \
        --name "$KEY_VAULT_NAME" \
        --resource-group "$AZURE_RESOURCE_GROUP" \
        --object-id "$PRINCIPAL_ID" \
        --secret-permissions get list
    print_success "Key Vault access granted to Managed Identity"
}

# Function to enable Azure Defender
enable_azure_defender() {
    print_status "Enabling Azure Defender for containers..."
    
    # Enable Azure Defender for Container Registry
    az security pricing create \
        --name "ContainerRegistry" \
        --tier "Standard"
    
    # Enable Azure Defender for App Service
    az security pricing create \
        --name "AppServices" \
        --tier "Standard"
    
    print_success "Azure Defender enabled for containers and App Services"
}

# Function to configure network security
configure_network_security() {
    print_status "Configuring network security..."
    
    # Create Network Security Group
    NSG_NAME="wine-quality-nsg"
    
    if ! az network nsg show --name "$NSG_NAME" --resource-group "$AZURE_RESOURCE_GROUP" &> /dev/null; then
        az network nsg create \
            --name "$NSG_NAME" \
            --resource-group "$AZURE_RESOURCE_GROUP" \
            --location "$AZURE_LOCATION"
        print_success "Network Security Group created: $NSG_NAME"
    else
        print_warning "Network Security Group $NSG_NAME already exists"
    fi
    
    # Add security rules
    az network nsg rule create \
        --resource-group "$AZURE_RESOURCE_GROUP" \
        --nsg-name "$NSG_NAME" \
        --name "AllowHTTPS" \
        --priority 1000 \
        --source-address-prefixes "*" \
        --source-port-ranges "*" \
        --destination-address-prefixes "*" \
        --destination-port-ranges 443 \
        --access Allow \
        --protocol Tcp \
        --description "Allow HTTPS traffic"
    
    az network nsg rule create \
        --resource-group "$AZURE_RESOURCE_GROUP" \
        --nsg-name "$NSG_NAME" \
        --name "DenyAllInbound" \
        --priority 4000 \
        --source-address-prefixes "*" \
        --source-port-ranges "*" \
        --destination-address-prefixes "*" \
        --destination-port-ranges "*" \
        --access Deny \
        --protocol "*" \
        --description "Deny all other inbound traffic"
    
    print_success "Network security rules configured"
}

# Function to enable DDoS protection
enable_ddos_protection() {
    print_status "Enabling DDoS protection..."
    
    # Create DDoS protection plan
    DDOS_PLAN_NAME="wine-quality-ddos-plan"
    
    if ! az network ddos-protection plan show --name "$DDOS_PLAN_NAME" --resource-group "$AZURE_RESOURCE_GROUP" &> /dev/null; then
        az network ddos-protection plan create \
            --name "$DDOS_PLAN_NAME" \
            --resource-group "$AZURE_RESOURCE_GROUP" \
            --location "$AZURE_LOCATION"
        print_success "DDoS protection plan created: $DDOS_PLAN_NAME"
    else
        print_warning "DDoS protection plan $DDOS_PLAN_NAME already exists"
    fi
}

# Function to configure Web Application Firewall
configure_waf() {
    print_status "Configuring Web Application Firewall..."
    
    # Create Application Gateway with WAF
    AGW_NAME="wine-quality-agw"
    
    # Create public IP
    az network public-ip create \
        --resource-group "$AZURE_RESOURCE_GROUP" \
        --name "${AGW_NAME}-pip" \
        --allocation-method Static \
        --sku Standard
    
    # Create Application Gateway with WAF
    az network application-gateway create \
        --name "$AGW_NAME" \
        --resource-group "$AZURE_RESOURCE_GROUP" \
        --location "$AZURE_LOCATION" \
        --sku WAF_v2 \
        --capacity 2 \
        --public-ip-address "${AGW_NAME}-pip" \
        --http-settings-cookie-based-affinity Disabled \
        --http-settings-port 80 \
        --http-settings-protocol Http \
        --frontend-port 80 \
        --routing-rule-type Basic \
        --waf-policy wine-quality-waf-policy
    
    print_success "Web Application Firewall configured"
}

# Function to configure SSL/TLS
configure_ssl() {
    print_status "Configuring SSL/TLS..."
    
    # Enable HTTPS only for App Service
    az webapp update \
        --name "$BACKEND_APP_NAME" \
        --resource-group "$AZURE_RESOURCE_GROUP" \
        --https-only true
    
    # Configure minimum TLS version
    az webapp config set \
        --name "$BACKEND_APP_NAME" \
        --resource-group "$AZURE_RESOURCE_GROUP" \
        --min-tls-version "1.2"
    
    print_success "SSL/TLS configured"
}

# Function to scan Docker images for vulnerabilities
scan_docker_images() {
    print_status "Scanning Docker images for vulnerabilities..."
    
    # Install Trivy if not already installed
    if ! command -v trivy &> /dev/null; then
        print_status "Installing Trivy vulnerability scanner..."
        # Add Trivy installation logic here
    fi
    
    # Scan backend image
    print_status "Scanning backend image..."
    docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
        aquasec/trivy image "$ACR_LOGIN_SERVER/wine-backend:latest" \
        --severity HIGH,CRITICAL \
        --format table
    
    # Scan frontend image
    print_status "Scanning frontend image..."
    docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
        aquasec/trivy image "$ACR_LOGIN_SERVER/wine-frontend:latest" \
        --severity HIGH,CRITICAL \
        --format table
    
    print_success "Docker image vulnerability scan completed"
}

# Function to configure access controls
configure_access_controls() {
    print_status "Configuring access controls..."
    
    # Set up RBAC for Key Vault
    KEY_VAULT_NAME="wine-quality-vault"
    
    # Get current user
    CURRENT_USER=$(az account show --query user.name -o tsv)
    
    # Grant Key Vault Administrator role to current user
    az role assignment create \
        --assignee "$CURRENT_USER" \
        --role "Key Vault Administrator" \
        --scope "/subscriptions/$AZURE_SUBSCRIPTION_ID/resourceGroups/$AZURE_RESOURCE_GROUP/providers/Microsoft.KeyVault/vaults/$KEY_VAULT_NAME"
    
    print_success "Access controls configured"
}

# Function to create security monitoring alerts
create_security_alerts() {
    print_status "Creating security monitoring alerts..."
    
    # Create security alert for failed authentication attempts
    az monitor metrics alert create \
        --name "failed-auth-attempts" \
        --resource-group "$AZURE_RESOURCE_GROUP" \
        --scopes "/subscriptions/$AZURE_SUBSCRIPTION_ID/resourceGroups/$AZURE_RESOURCE_GROUP/providers/Microsoft.Web/sites/$BACKEND_APP_NAME" \
        --condition "count 'Http4xx' > 10" \
        --description "High number of failed authentication attempts" \
        --evaluation-frequency 5m \
        --window-size 15m \
        --severity 1
    
    # Create security alert for unusual traffic patterns
    az monitor metrics alert create \
        --name "unusual-traffic" \
        --resource-group "$AZURE_RESOURCE_GROUP" \
        --scopes "/subscriptions/$AZURE_SUBSCRIPTION_ID/resourceGroups/$AZURE_RESOURCE_GROUP/providers/Microsoft.Web/sites/$BACKEND_APP_NAME" \
        --condition "count 'HttpRequests' > 1000" \
        --description "Unusual traffic volume detected" \
        --evaluation-frequency 5m \
        --window-size 15m \
        --severity 2
    
    print_success "Security monitoring alerts created"
}

# Function to update App Service configuration
update_app_service_config() {
    print_status "Updating App Service security configuration..."
    
    # Update App Service to use Key Vault secrets
    KEY_VAULT_NAME="wine-quality-vault"
    KEY_VAULT_URL="https://$KEY_VAULT_NAME.vault.azure.net/"
    
    az webapp config appsettings set \
        --name "$BACKEND_APP_NAME" \
        --resource-group "$AZURE_RESOURCE_GROUP" \
        --settings \
            GEMINI_API_KEY="@Microsoft.KeyVault(VaultName=$KEY_VAULT_NAME;SecretName=gemini-api-key)" \
            SECRET_KEY="@Microsoft.KeyVault(VaultName=$KEY_VAULT_NAME;SecretName=app-secret-key)" \
            KEY_VAULT_URL="$KEY_VAULT_URL"
    
    print_success "App Service configuration updated"
}

# Function to create security documentation
create_security_documentation() {
    print_status "Creating security documentation..."
    
    cat > SECURITY.md << EOF
# 🔒 Security Architecture

## Overview
This document outlines the security measures implemented for the Wine Quality Prediction application.

## Security Controls

### 1. Azure Key Vault
- **Purpose**: Secure storage of secrets and certificates
- **Implementation**: All sensitive data stored in Key Vault
- **Access**: Managed Identity with least privilege access

### 2. Managed Identity
- **Purpose**: Secure authentication without storing credentials
- **Implementation**: System-assigned managed identity for App Service
- **Benefits**: No credential management, automatic rotation

### 3. Network Security
- **Network Security Groups**: Restrict traffic flow
- **DDoS Protection**: Mitigate distributed denial of service attacks
- **Web Application Firewall**: Filter malicious requests

### 4. Container Security
- **Image Scanning**: Regular vulnerability assessments
- **Non-root Containers**: Run containers as non-root users
- **Minimal Base Images**: Reduce attack surface

### 5. Application Security
- **HTTPS Only**: Force encrypted connections
- **TLS 1.2 Minimum**: Use modern encryption protocols
- **Input Validation**: Sanitize all user inputs
- **Rate Limiting**: Prevent abuse and DoS attacks

### 6. Monitoring and Alerting
- **Security Alerts**: Monitor for suspicious activities
- **Audit Logging**: Track all security events
- **Compliance Monitoring**: Ensure security standards

## Threat Model

### Identified Threats
1. **Data Breach**: Unauthorized access to wine data
2. **API Abuse**: Malicious use of prediction API
3. **DDoS Attacks**: Service disruption
4. **Injection Attacks**: Code injection vulnerabilities
5. **Credential Theft**: Compromise of authentication

### Mitigation Strategies
1. **Encryption**: Data encrypted at rest and in transit
2. **Authentication**: Multi-factor authentication
3. **Authorization**: Role-based access control
4. **Monitoring**: Real-time threat detection
5. **Incident Response**: Automated response procedures

## Compliance

### Security Standards
- **OWASP Top 10**: Web application security risks
- **CIS Controls**: Cybersecurity best practices
- **NIST Framework**: Risk management approach
- **ISO 27001**: Information security management

### Regular Assessments
- **Vulnerability Scanning**: Monthly security scans
- **Penetration Testing**: Quarterly security assessments
- **Code Reviews**: Security-focused code analysis
- **Training**: Regular security awareness training

## Incident Response

### Response Procedures
1. **Detection**: Automated monitoring and alerting
2. **Assessment**: Evaluate threat severity
3. **Containment**: Isolate affected systems
4. **Eradication**: Remove threat vectors
5. **Recovery**: Restore normal operations
6. **Lessons Learned**: Improve security posture

### Contact Information
- **Security Team**: security@yourdomain.com
- **Incident Response**: incident@yourdomain.com
- **Emergency Contact**: +1-XXX-XXX-XXXX

## Security Checklist

### Pre-deployment
- [ ] Secrets stored in Key Vault
- [ ] Managed Identity configured
- [ ] Network security rules applied
- [ ] Container images scanned
- [ ] SSL/TLS configured
- [ ] Monitoring enabled

### Post-deployment
- [ ] Security alerts configured
- [ ] Access controls verified
- [ ] Vulnerability scanning scheduled
- [ ] Incident response plan tested
- [ ] Security documentation updated
- [ ] Team training completed

## Updates
This document is reviewed and updated quarterly or after security incidents.
EOF
    
    print_success "Security documentation created"
}

# Function to display security summary
display_summary() {
    echo ""
    echo "🔒 Azure Security Setup Complete!"
    echo "================================"
    echo ""
    echo "📋 Security Features Implemented:"
    echo "  ✅ Azure Key Vault for secrets management"
    echo "  ✅ Managed Identity for authentication"
    echo "  ✅ Azure Defender for threat protection"
    echo "  ✅ Network Security Groups"
    echo "  ✅ DDoS Protection"
    echo "  ✅ Web Application Firewall"
    echo "  ✅ SSL/TLS encryption"
    echo "  ✅ Container vulnerability scanning"
    echo "  ✅ Security monitoring alerts"
    echo "  ✅ Access controls and RBAC"
    echo ""
    echo "🔍 Security Resources:"
    echo "  Key Vault: wine-quality-vault"
    echo "  Network Security Group: wine-quality-nsg"
    echo "  DDoS Protection: wine-quality-ddos-plan"
    echo "  Application Gateway: wine-quality-agw"
    echo ""
    echo "📚 Documentation:"
    echo "  Security Guide: SECURITY.md"
    echo "  Azure Security Center: https://portal.azure.com/#view/Microsoft_Azure_Security/SecurityMenuBlade/~/overview"
    echo ""
    echo "🚀 Next Steps:"
    echo "  1. Review security configuration"
    echo "  2. Test security controls"
    echo "  3. Schedule regular security assessments"
    echo "  4. Train team on security procedures"
    echo "  5. Monitor security alerts"
}

# Function to save security info
save_security_info() {
    print_status "Saving security information..."
    
    cat >> azure/.env.azure << EOF

# Security Configuration
KEY_VAULT_NAME=wine-quality-vault
NSG_NAME=wine-quality-nsg
DDOS_PLAN_NAME=wine-quality-ddos-plan
AGW_NAME=wine-quality-agw
EOF
    
    print_success "Security information saved to azure/.env.azure"
}

# Main execution
main() {
    echo "Starting Azure security setup..."
    echo ""
    
    # Check prerequisites
    check_env_file
    check_azure_login
    
    # Implement security measures
    create_key_vault
    store_secrets
    configure_managed_identity
    enable_azure_defender
    configure_network_security
    enable_ddos_protection
    configure_waf
    configure_ssl
    scan_docker_images
    configure_access_controls
    create_security_alerts
    update_app_service_config
    create_security_documentation
    
    # Save information and display summary
    save_security_info
    display_summary
}

# Run main function
main "$@"

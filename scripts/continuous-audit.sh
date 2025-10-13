#!/bin/bash
set -e

# Continuous Audit Script for Wine Quality Prediction
# Runs daily audits and compares with previous runs

echo "🔄 Wine Quality Prediction - Continuous Audit"
echo "============================================="

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

# Configuration
AUDIT_DIR="reports"
CURRENT_DATE=$(date +%Y-%m-%d)
PREVIOUS_DATE=$(date -d '1 day ago' +%Y-%m-%d)
EMAIL_RECIPIENT="${AUDIT_EMAIL:-admin@yourdomain.com}"
SLACK_WEBHOOK="${SLACK_WEBHOOK_URL:-}"

# Function to create audit directory
create_audit_directory() {
    if [ ! -d "$AUDIT_DIR" ]; then
        mkdir -p "$AUDIT_DIR"
        print_success "Created audit directory: $AUDIT_DIR"
    fi
}

# Function to run audit
run_audit() {
    print_status "Running comprehensive audit..."
    
    if [ -f "scripts/audit-project.py" ]; then
        python3 scripts/audit-project.py --output json > "$AUDIT_DIR/audit-$CURRENT_DATE.json"
        if [ $? -eq 0 ]; then
            print_success "Audit completed successfully"
            return 0
        else
            print_error "Audit failed"
            return 1
        fi
    else
        print_error "Audit script not found: scripts/audit-project.py"
        return 1
    fi
}

# Function to compare with previous audit
compare_audits() {
    local current_file="$AUDIT_DIR/audit-$CURRENT_DATE.json"
    local previous_file="$AUDIT_DIR/audit-$PREVIOUS_DATE.json"
    
    if [ ! -f "$current_file" ]; then
        print_error "Current audit file not found: $current_file"
        return 1
    fi
    
    if [ ! -f "$previous_file" ]; then
        print_warning "Previous audit file not found: $previous_file"
        print_status "This is the first audit run"
        return 0
    fi
    
    print_status "Comparing with previous audit..."
    
    # Extract key metrics using jq if available
    if command -v jq >/dev/null 2>&1; then
        current_score=$(jq -r '.overall_score' "$current_file")
        previous_score=$(jq -r '.overall_score' "$previous_file")
        
        current_critical=$(jq -r '.statistics.critical_issues' "$current_file")
        previous_critical=$(jq -r '.statistics.critical_issues' "$previous_file")
        
        current_errors=$(jq -r '.statistics.errors' "$current_file")
        previous_errors=$(jq -r '.statistics.errors' "$previous_file")
        
        current_warnings=$(jq -r '.statistics.warnings' "$current_file")
        previous_warnings=$(jq -r '.statistics.warnings' "$previous_file")
        
        # Calculate changes
        score_change=$(echo "$current_score - $previous_score" | bc)
        critical_change=$((current_critical - previous_critical))
        error_change=$((current_errors - previous_errors))
        warning_change=$((current_warnings - previous_warnings))
        
        print_status "Audit comparison results:"
        echo "  Overall Score: $previous_score → $current_score ($score_change)"
        echo "  Critical Issues: $previous_critical → $current_critical ($critical_change)"
        echo "  Errors: $previous_errors → $current_errors ($error_change)"
        echo "  Warnings: $previous_warnings → $current_warnings ($warning_change)"
        
        # Check for critical changes
        if [ "$critical_change" -gt 0 ]; then
            print_error "NEW CRITICAL ISSUES DETECTED: $critical_change"
            return 2
        elif [ "$critical_change" -lt 0 ]; then
            print_success "Critical issues reduced by: $((-critical_change))"
        fi
        
        if [ "$error_change" -gt 0 ]; then
            print_warning "New errors detected: $error_change"
        elif [ "$error_change" -lt 0 ]; then
            print_success "Errors reduced by: $((-error_change))"
        fi
        
        if [ "$score_change" -lt -10 ]; then
            print_warning "Significant score decrease: $score_change"
        elif [ "$score_change" -gt 10 ]; then
            print_success "Significant score improvement: $score_change"
        fi
        
    else
        print_warning "jq not found, skipping detailed comparison"
    fi
    
    return 0
}

# Function to check for new critical issues
check_critical_issues() {
    local audit_file="$AUDIT_DIR/audit-$CURRENT_DATE.json"
    
    if [ ! -f "$audit_file" ]; then
        print_error "Audit file not found: $audit_file"
        return 1
    fi
    
    if command -v jq >/dev/null 2>&1; then
        critical_count=$(jq -r '.statistics.critical_issues' "$audit_file")
        
        if [ "$critical_count" -gt 0 ]; then
            print_error "CRITICAL ISSUES FOUND: $critical_count"
            
            # Extract critical issues
            jq -r '.priority_issues[] | select(.severity == "CRITICAL") | "\(.file_path):\(.line_number // "N/A"): \(.message)"' "$audit_file"
            
            return 2
        else
            print_success "No critical issues found"
            return 0
        fi
    else
        print_warning "jq not found, cannot check critical issues"
        return 0
    fi
}

# Function to send email notification
send_email_notification() {
    local subject="$1"
    local body="$2"
    
    if [ -z "$EMAIL_RECIPIENT" ] || [ "$EMAIL_RECIPIENT" = "admin@yourdomain.com" ]; then
        print_warning "Email recipient not configured, skipping email notification"
        return 0
    fi
    
    if command -v mail >/dev/null 2>&1; then
        echo "$body" | mail -s "$subject" "$EMAIL_RECIPIENT"
        print_success "Email notification sent to: $EMAIL_RECIPIENT"
    elif command -v sendmail >/dev/null 2>&1; then
        echo "$body" | sendmail "$EMAIL_RECIPIENT"
        print_success "Email notification sent to: $EMAIL_RECIPIENT"
    else
        print_warning "No email client found, skipping email notification"
    fi
}

# Function to send Slack notification
send_slack_notification() {
    local message="$1"
    local color="$2"
    
    if [ -z "$SLACK_WEBHOOK" ]; then
        print_warning "Slack webhook not configured, skipping Slack notification"
        return 0
    fi
    
    if command -v curl >/dev/null 2>&1; then
        payload=$(cat <<EOF
{
    "text": "Wine Quality Prediction Audit",
    "attachments": [
        {
            "color": "$color",
            "text": "$message"
        }
    ]
}
EOF
        )
        
        curl -X POST -H 'Content-type: application/json' \
            --data "$payload" \
            "$SLACK_WEBHOOK"
        
        print_success "Slack notification sent"
    else
        print_warning "curl not found, skipping Slack notification"
    fi
}

# Function to generate audit summary
generate_audit_summary() {
    local audit_file="$AUDIT_DIR/audit-$CURRENT_DATE.json"
    
    if [ ! -f "$audit_file" ]; then
        print_error "Audit file not found: $audit_file"
        return 1
    fi
    
    if command -v jq >/dev/null 2>&1; then
        local overall_score=$(jq -r '.overall_score' "$audit_file")
        local total_issues=$(jq -r '.total_issues' "$audit_file")
        local critical_issues=$(jq -r '.statistics.critical_issues' "$audit_file")
        local errors=$(jq -r '.statistics.errors' "$audit_file")
        local warnings=$(jq -r '.statistics.warnings' "$audit_file")
        
        local summary="
🍷 Wine Quality Prediction - Daily Audit Summary
===============================================
Date: $CURRENT_DATE
Overall Score: $overall_score/100
Total Issues: $total_issues
Critical: $critical_issues
Errors: $errors
Warnings: $warnings

Status: $([ "$overall_score" -ge 90 ] && echo "🟢 EXCELLENT" || [ "$overall_score" -ge 80 ] && echo "🟡 GOOD" || [ "$overall_score" -ge 70 ] && echo "🟠 FAIR" || echo "🔴 NEEDS IMPROVEMENT")

Full report: $audit_file
"
        
        echo "$summary"
        return 0
    else
        print_warning "jq not found, cannot generate summary"
        return 1
    fi
}

# Function to cleanup old reports
cleanup_old_reports() {
    local days_to_keep="${AUDIT_RETENTION_DAYS:-30}"
    
    print_status "Cleaning up old reports (keeping last $days_to_keep days)..."
    
    find "$AUDIT_DIR" -name "audit-*.json" -type f -mtime +$days_to_keep -delete
    
    print_success "Old reports cleaned up"
}

# Function to run quick health check
run_quick_health_check() {
    print_status "Running quick health check..."
    
    if [ -f "scripts/quick-health-check.sh" ]; then
        bash scripts/quick-health-check.sh
        local health_status=$?
        
        if [ $health_status -eq 0 ]; then
            print_success "Quick health check passed"
            return 0
        elif [ $health_status -eq 1 ]; then
            print_warning "Quick health check passed with warnings"
            return 1
        else
            print_error "Quick health check failed"
            return 2
        fi
    else
        print_warning "Quick health check script not found"
        return 0
    fi
}

# Function to schedule next audit
schedule_next_audit() {
    local cron_entry="0 2 * * * cd $(pwd) && bash scripts/continuous-audit.sh >> logs/audit.log 2>&1"
    
    print_status "To schedule daily audits, add this to crontab:"
    echo "$cron_entry"
    echo ""
    print_status "Run: crontab -e"
    print_status "Then add the line above"
}

# Main execution
main() {
    echo "Starting continuous audit process..."
    echo ""
    
    # Check if we're in the right directory
    if [ ! -f "README.md" ] && [ ! -f "docker-compose.yml" ]; then
        print_error "Not in project root directory. Please run from project root."
        exit 1
    fi
    
    # Create necessary directories
    create_audit_directory
    mkdir -p logs
    
    # Run quick health check first
    run_quick_health_check
    local health_status=$?
    
    # Run comprehensive audit
    run_audit
    local audit_status=$?
    
    if [ $audit_status -ne 0 ]; then
        print_error "Audit failed, exiting"
        exit 1
    fi
    
    # Compare with previous audit
    compare_audits
    local compare_status=$?
    
    # Check for critical issues
    check_critical_issues
    local critical_status=$?
    
    # Generate summary
    local summary=$(generate_audit_summary)
    echo "$summary"
    
    # Send notifications based on status
    if [ $critical_status -eq 2 ]; then
        # Critical issues found
        send_email_notification "🚨 CRITICAL: Wine Quality Prediction Audit Issues" "$summary"
        send_slack_notification "🚨 CRITICAL ISSUES DETECTED in Wine Quality Prediction audit!" "danger"
    elif [ $compare_status -eq 2 ]; then
        # New critical issues
        send_email_notification "⚠️ WARNING: New Critical Issues in Wine Quality Prediction" "$summary"
        send_slack_notification "⚠️ New critical issues detected in Wine Quality Prediction audit" "warning"
    elif [ $health_status -eq 2 ]; then
        # Health check failed
        send_email_notification "⚠️ WARNING: Wine Quality Prediction Health Check Failed" "$summary"
        send_slack_notification "⚠️ Health check failed for Wine Quality Prediction" "warning"
    else
        # All good
        send_email_notification "✅ Wine Quality Prediction Audit - All Good" "$summary"
        send_slack_notification "✅ Wine Quality Prediction audit completed successfully" "good"
    fi
    
    # Cleanup old reports
    cleanup_old_reports
    
    # Show scheduling info
    schedule_next_audit
    
    print_success "Continuous audit process completed!"
    
    # Exit with appropriate code
    if [ $critical_status -eq 2 ]; then
        exit 2
    elif [ $compare_status -eq 2 ] || [ $health_status -eq 2 ]; then
        exit 1
    else
        exit 0
    fi
}

# Run main function
main "$@"

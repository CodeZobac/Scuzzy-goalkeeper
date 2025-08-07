#!/bin/bash

# Email Service Maintenance and Monitoring Script
# This script provides utilities for maintaining and monitoring the email service

set -e

APP_DIR="/opt/email-service"
SERVICE_NAME="email-service"
LOG_DIR="/var/log/email-service"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}=== $1 ===${NC}"
}

# Function to check service status
check_service_status() {
    print_header "Service Status Check"
    
    if systemctl is-active --quiet $SERVICE_NAME; then
        print_status "✓ Email service is running"
        
        # Check if service is responding
        if curl -f -s http://localhost:8000/health > /dev/null; then
            print_status "✓ Health check passed"
        else
            print_warning "✗ Health check failed - service may be unresponsive"
        fi
    else
        print_error "✗ Email service is not running"
        echo "Status: $(systemctl is-active $SERVICE_NAME)"
        return 1
    fi
    
    echo "Service uptime: $(systemctl show $SERVICE_NAME --property=ActiveEnterTimestamp | cut -d'=' -f2)"
    echo "Process ID: $(systemctl show $SERVICE_NAME --property=MainPID | cut -d'=' -f2)"
}

# Function to show service logs
show_logs() {
    local lines=${1:-50}
    print_header "Recent Service Logs (last $lines lines)"
    
    if command -v journalctl > /dev/null; then
        journalctl -u $SERVICE_NAME -n $lines --no-pager
    else
        print_error "journalctl not available"
        return 1
    fi
}

# Function to follow logs in real-time
follow_logs() {
    print_header "Following Service Logs (press Ctrl+C to stop)"
    journalctl -u $SERVICE_NAME -f
}

# Function to restart service
restart_service() {
    print_header "Restarting Email Service"
    
    print_status "Stopping service..."
    sudo systemctl stop $SERVICE_NAME
    
    sleep 2
    
    print_status "Starting service..."
    sudo systemctl start $SERVICE_NAME
    
    sleep 3
    
    if systemctl is-active --quiet $SERVICE_NAME; then
        print_status "✓ Service restarted successfully"
        check_service_status
    else
        print_error "✗ Failed to restart service"
        show_logs 20
        return 1
    fi
}

# Function to update application
update_application() {
    print_header "Updating Application"
    
    print_status "Stopping service..."
    sudo systemctl stop $SERVICE_NAME
    
    cd $APP_DIR
    
    print_status "Backing up current version..."
    sudo -u emailservice cp -r .venv .venv.backup.$(date +%Y%m%d_%H%M%S) || true
    
    print_status "Updating dependencies..."
    sudo -u emailservice bash -c "source .venv/bin/activate && uv pip install --upgrade -r pyproject.toml"
    
    print_status "Running tests..."
    if sudo -u emailservice bash -c "source .venv/bin/activate && python -m pytest tests/ -v"; then
        print_status "✓ All tests passed"
    else
        print_error "✗ Tests failed - rolling back"
        # Restore backup if tests fail
        sudo -u emailservice rm -rf .venv
        sudo -u emailservice mv .venv.backup.* .venv
        sudo systemctl start $SERVICE_NAME
        return 1
    fi
    
    print_status "Starting service..."
    sudo systemctl start $SERVICE_NAME
    
    sleep 5
    
    if check_service_status; then
        print_status "✓ Application updated successfully"
        # Clean up old backup
        sudo -u emailservice find . -name '.venv.backup.*' -mtime +7 -exec rm -rf {} \; || true
    else
        print_error "✗ Service failed to start after update"
        return 1
    fi
}

# Function to check disk space and logs
check_system_resources() {
    print_header "System Resources Check"
    
    # Check disk space
    echo "Disk Usage:"
    df -h / $APP_DIR $LOG_DIR 2>/dev/null || df -h /
    echo
    
    # Check memory usage
    echo "Memory Usage:"
    free -h
    echo
    
    # Check service memory usage
    if systemctl is-active --quiet $SERVICE_NAME; then
        local pid=$(systemctl show $SERVICE_NAME --property=MainPID | cut -d'=' -f2)
        if [[ $pid != "0" ]]; then
            echo "Service Memory Usage:"
            ps -p $pid -o pid,ppid,%mem,rss,cmd 2>/dev/null || echo "Could not get process info"
        fi
    fi
    echo
    
    # Check log sizes
    echo "Log Directory Size:"
    du -sh $LOG_DIR 2>/dev/null || echo "Log directory not accessible"
    
    echo "Journal Size:"
    journalctl --disk-usage | head -1
}

# Function to clean up old logs
cleanup_logs() {
    local days=${1:-7}
    print_header "Cleaning Up Logs (older than $days days)"
    
    # Clean application logs
    if [[ -d $LOG_DIR ]]; then
        find $LOG_DIR -name "*.log*" -mtime +$days -delete 2>/dev/null || true
        print_status "Cleaned application logs"
    fi
    
    # Clean journal logs
    print_status "Cleaning journal logs..."
    journalctl --vacuum-time=${days}d || print_warning "Could not clean journal logs"
    
    print_status "Log cleanup completed"
}

# Function to run health checks
run_health_checks() {
    print_header "Comprehensive Health Checks"
    
    local all_good=true
    
    # Service status
    if ! check_service_status > /dev/null 2>&1; then
        all_good=false
    fi
    
    # API endpoints
    print_status "Testing API endpoints..."
    
    local endpoints=("/health" "/api/v1/docs" "/")
    for endpoint in "${endpoints[@]}"; do
        if curl -f -s "http://localhost:8000$endpoint" > /dev/null; then
            print_status "✓ $endpoint is accessible"
        else
            print_error "✗ $endpoint is not accessible"
            all_good=false
        fi
    done
    
    # Check configuration
    print_status "Validating configuration..."
    cd $APP_DIR
    if sudo -u emailservice bash -c "source .venv/bin/activate && python -c 'from app.config import Settings; Settings()'"; then
        print_status "✓ Configuration is valid"
    else
        print_error "✗ Configuration validation failed"
        all_good=false
    fi
    
    # Check external dependencies
    print_status "Checking external dependencies..."
    
    # Check Supabase connectivity (basic)
    if sudo -u emailservice bash -c "source .venv/bin/activate && python -c 'from app.repositories.auth_code_repository import AuthCodeRepository; repo = AuthCodeRepository(); print(\"Supabase connection OK\")'"; then
        print_status "✓ Database connection OK"
    else
        print_error "✗ Database connection failed"
        all_good=false
    fi
    
    if $all_good; then
        print_status "✓ All health checks passed"
        return 0
    else
        print_error "✗ Some health checks failed"
        return 1
    fi
}

# Function to show usage
show_usage() {
    echo "Email Service Maintenance Script"
    echo
    echo "Usage: $0 <command> [options]"
    echo
    echo "Commands:"
    echo "  status                    - Check service status and health"
    echo "  logs [lines]             - Show recent logs (default: 50 lines)"
    echo "  follow                   - Follow logs in real-time"
    echo "  restart                  - Restart the service"
    echo "  update                   - Update application and dependencies"
    echo "  resources                - Check system resources and usage"
    echo "  cleanup [days]           - Clean up logs older than N days (default: 7)"
    echo "  health                   - Run comprehensive health checks"
    echo "  help                     - Show this help message"
    echo
    echo "Examples:"
    echo "  $0 status"
    echo "  $0 logs 100"
    echo "  $0 cleanup 14"
}

# Main script logic
case "${1:-}" in
    "status")
        check_service_status
        ;;
    "logs")
        show_logs "${2:-50}"
        ;;
    "follow")
        follow_logs
        ;;
    "restart")
        restart_service
        ;;
    "update")
        update_application
        ;;
    "resources")
        check_system_resources
        ;;
    "cleanup")
        cleanup_logs "${2:-7}"
        ;;
    "health")
        run_health_checks
        ;;
    "help"|"--help"|"-h")
        show_usage
        ;;
    "")
        print_error "No command specified"
        show_usage
        exit 1
        ;;
    *)
        print_error "Unknown command: $1"
        show_usage
        exit 1
        ;;
esac

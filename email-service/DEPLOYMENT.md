# Email Service Deployment Guide

This guide provides comprehensive instructions for deploying the Python Email Service to an Azure Virtual Machine with production-ready configuration.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Azure VM Setup](#azure-vm-setup)
3. [Application Deployment](#application-deployment)
4. [Nginx Configuration](#nginx-configuration)
5. [SSL Certificate Setup](#ssl-certificate-setup)
6. [Service Management](#service-management)
7. [Monitoring and Maintenance](#monitoring-and-maintenance)
8. [Troubleshooting](#troubleshooting)
9. [Security Considerations](#security-considerations)

## Prerequisites

### Required Information

Before starting deployment, ensure you have:

- **Azure Communication Services** details:
  - Service endpoint URL
  - API key
  - Connection string
- **Supabase** project details:
  - Project URL
  - Anonymous key
- **Domain name** for the service
- **Flutter app domain** for CORS configuration

### Azure VM Requirements

- **Operating System**: Ubuntu 22.04 LTS or later
- **Instance Size**: Standard B2s (2 vCPUs, 4GB RAM) minimum
- **Storage**: 30GB Premium SSD minimum
- **Network**: Public IP with HTTP/HTTPS access allowed

## Azure VM Setup

### 1. Initial VM Preparation

Connect to your Azure VM and run the setup script:

```bash
# Clone the repository
git clone https://github.com/your-repo/email-service.git
cd email-service

# Make scripts executable
chmod +x deploy/*.sh

# Run VM setup script
sudo ./deploy/setup_vm.sh
```

This script will:
- Install Python 3.11 and system dependencies
- Install uv package manager
- Create the `emailservice` user
- Set up directories and permissions
- Configure the firewall
- Install Nginx and SSL certificate tools

### 2. Configure Application Directory

Copy your application code to the deployment location:

```bash
# Copy application files to deployment directory
sudo cp -r . /opt/email-service/
sudo chown -R emailservice:emailservice /opt/email-service/
```

## Application Deployment

### 1. Environment Configuration

Create the production environment file:

```bash
# Copy the production environment template
sudo cp /opt/email-service/deploy/.env.production /etc/email-service/.env
sudo chown emailservice:emailservice /etc/email-service/.env
sudo chmod 600 /etc/email-service/.env

# Edit the environment file with your actual values
sudo nano /etc/email-service/.env
```

**Required environment variables:**

```env
# Azure Communication Services
EMAIL_SERVICE=https://your-service.communication.azure.com/
AZURE_KEY=your-actual-azure-key
AZURE_CONNECTION_STRING=endpoint=https://your-service.communication.azure.com/;accesskey=your-key
EMAIL_FROM_ADDRESS=noreply@your-domain.com
EMAIL_FROM_NAME=Your-App-Name

# Supabase Configuration
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-actual-anon-key

# Application URLs
APP_BASE_URL=https://your-flutter-app-domain.com
```

### 2. Deploy Application

Run the deployment script:

```bash
cd /opt/email-service
sudo ./deploy/deploy_app.sh
```

This script will:
- Install Python dependencies with uv
- Run application tests
- Validate configuration
- Create and start the systemd service
- Verify the service is running

### 3. Verify Deployment

Check that the service is running:

```bash
# Check service status
sudo systemctl status email-service

# Test health endpoint
curl http://localhost:8000/health

# View service logs
sudo journalctl -u email-service -f
```

## Nginx Configuration

### 1. Configure Reverse Proxy

Set up Nginx to proxy requests to your application:

```bash
# Copy Nginx configuration
sudo cp /opt/email-service/deploy/nginx.conf /etc/nginx/sites-available/email-service

# Update domain name in the configuration
sudo sed -i 's/your-domain.com/your-actual-domain.com/g' /etc/nginx/sites-available/email-service

# Enable the site
sudo ln -s /etc/nginx/sites-available/email-service /etc/nginx/sites-enabled/

# Test configuration
sudo nginx -t

# Reload Nginx
sudo systemctl reload nginx
```

### 2. Configure Firewall

Update firewall rules for web traffic:

```bash
# Remove direct API access (optional, for security)
sudo ufw delete allow 8000

# Ensure HTTP/HTTPS are allowed
sudo ufw allow 'Nginx Full'
sudo ufw reload
```

## SSL Certificate Setup

### 1. Install Let's Encrypt Certificate

Use Certbot to obtain and configure SSL certificates:

```bash
# Obtain SSL certificate
sudo certbot --nginx -d your-domain.com

# Verify certificate renewal
sudo certbot renew --dry-run
```

### 2. Set Up Automatic Renewal

The SSL certificate will automatically renew. Verify the renewal timer:

```bash
# Check renewal timer status
sudo systemctl status snap.certbot.renew.timer

# Test renewal
sudo certbot renew --dry-run
```

## Service Management

### 1. Systemd Service Commands

```bash
# Start/stop/restart service
sudo systemctl start email-service
sudo systemctl stop email-service
sudo systemctl restart email-service

# Enable/disable service (auto-start)
sudo systemctl enable email-service
sudo systemctl disable email-service

# Check service status
sudo systemctl status email-service

# View service logs
sudo journalctl -u email-service -f
sudo journalctl -u email-service --since "1 hour ago"
```

### 2. Configuration Reload

To reload configuration without downtime:

```bash
# Reload environment variables
sudo systemctl reload email-service

# Or restart if reload doesn't work
sudo systemctl restart email-service
```

## Monitoring and Maintenance

### 1. Using the Maintenance Script

The deployment includes a comprehensive maintenance script:

```bash
cd /opt/email-service

# Check service status and health
sudo ./deploy/maintenance.sh status

# View recent logs
sudo ./deploy/maintenance.sh logs 100

# Follow logs in real-time
sudo ./deploy/maintenance.sh follow

# Restart service
sudo ./deploy/maintenance.sh restart

# Check system resources
sudo ./deploy/maintenance.sh resources

# Run comprehensive health checks
sudo ./deploy/maintenance.sh health

# Clean up old logs
sudo ./deploy/maintenance.sh cleanup 7

# Update application
sudo ./deploy/maintenance.sh update
```

### 2. Monitoring Endpoints

The service provides several monitoring endpoints:

- **Health Check**: `GET /health`
- **API Documentation**: `GET /docs`
- **OpenAPI Schema**: `GET /openapi.json`

### 3. Log Files

Key log locations:

- **Application Logs**: `journalctl -u email-service`
- **Nginx Access Logs**: `/var/log/nginx/email-service.access.log`
- **Nginx Error Logs**: `/var/log/nginx/email-service.error.log`
- **System Logs**: `/var/log/syslog`

### 4. Performance Monitoring

Monitor key metrics:

```bash
# CPU and memory usage
top
htop

# Disk usage
df -h

# Network connections
netstat -tulpn | grep :8000
netstat -tulpn | grep :443

# Service response time
curl -w "@/dev/stdin" -o /dev/null -s "https://your-domain.com/health" <<< 'time_total: %{time_total}\n'
```

## Troubleshooting

### Common Issues

#### 1. Service Won't Start

```bash
# Check service status and logs
sudo systemctl status email-service
sudo journalctl -u email-service -n 50

# Common causes:
# - Invalid environment file
# - Missing dependencies
# - Port already in use
# - Permission issues
```

#### 2. Environment Configuration Issues

```bash
# Validate environment file
sudo -u emailservice bash -c "cd /opt/email-service && source .venv/bin/activate && python -c 'from app.config import Settings; Settings()'"

# Check file permissions
ls -la /etc/email-service/.env
```

#### 3. Database Connection Issues

```bash
# Test Supabase connection
sudo -u emailservice bash -c "cd /opt/email-service && source .venv/bin/activate && python -c 'from app.repositories.auth_code_repository import AuthCodeRepository; AuthCodeRepository()'"
```

#### 4. Azure Communication Services Issues

```bash
# Check Azure configuration
curl -X POST "https://your-service.communication.azure.com/emails:send" \
  -H "Authorization: Bearer YOUR_KEY" \
  -H "Content-Type: application/json" \
  -d '{"test": "connection"}'
```

#### 5. Nginx Configuration Issues

```bash
# Test Nginx configuration
sudo nginx -t

# Check Nginx logs
sudo tail -f /var/log/nginx/error.log

# Verify upstream is accessible
curl -I http://localhost:8000/health
```

### Performance Issues

#### High Memory Usage

```bash
# Check memory usage
free -h
ps aux | grep python | head -10

# Reduce worker count in systemd service if needed
sudo systemctl edit email-service
# Add:
# [Service]
# ExecStart=
# ExecStart=/opt/email-service/.venv/bin/python -m uvicorn main:app --host 0.0.0.0 --port 8000 --workers 1
```

#### High CPU Usage

```bash
# Monitor CPU usage
top
htop

# Check for infinite loops in logs
sudo journalctl -u email-service | grep -i error

# Enable debug logging temporarily
# Edit /etc/email-service/.env and set LOG_LEVEL=DEBUG
```

## Security Considerations

### 1. Environment Variables

- Store sensitive configuration in `/etc/email-service/.env`
- Set proper file permissions (600)
- Never commit production credentials to version control

### 2. Network Security

- Use HTTPS only (HTTP redirects to HTTPS)
- Implement rate limiting in Nginx
- Regularly update SSL certificates
- Monitor for suspicious activity

### 3. System Security

- Keep Ubuntu and packages updated
- Use non-root user for application
- Enable UFW firewall
- Regular security audits

### 4. Application Security

- Validate all input
- Use secure authentication codes
- Implement proper error handling
- Log security events

## Backup and Recovery

### 1. Configuration Backup

```bash
# Backup environment configuration
sudo cp /etc/email-service/.env /etc/email-service/.env.backup.$(date +%Y%m%d)

# Backup Nginx configuration
sudo cp /etc/nginx/sites-available/email-service /etc/nginx/sites-available/email-service.backup.$(date +%Y%m%d)
```

### 2. Application Backup

```bash
# Create application backup
sudo tar -czf /opt/email-service-backup-$(date +%Y%m%d).tar.gz /opt/email-service/
```

### 3. Recovery Procedures

```bash
# Stop service
sudo systemctl stop email-service

# Restore application
sudo tar -xzf /opt/email-service-backup-YYYYMMDD.tar.gz -C /

# Restore configuration
sudo cp /etc/email-service/.env.backup.YYYYMMDD /etc/email-service/.env

# Start service
sudo systemctl start email-service
```

## Updates and Maintenance

### 1. Regular Updates

```bash
# Update system packages
sudo apt update && sudo apt upgrade -y

# Update application dependencies
sudo ./deploy/maintenance.sh update

# Restart services after updates
sudo systemctl restart email-service
sudo systemctl reload nginx
```

### 2. Monitoring Schedule

- **Daily**: Check service status and logs
- **Weekly**: Review system resources and clean logs
- **Monthly**: Update system packages and dependencies
- **Quarterly**: Review and update security configurations

This deployment guide provides a comprehensive foundation for running the Python Email Service in production. Follow the maintenance procedures regularly to ensure optimal performance and security.

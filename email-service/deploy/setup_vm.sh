#!/bin/bash

# Azure VM Setup Script for Python Email Service
# This script sets up an Azure VM for running the Python FastAPI email backend

set -e

echo "Starting Azure VM setup for Python Email Service..."

# Update system packages
echo "Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install system dependencies
echo "Installing system dependencies..."
sudo apt install -y \
    python3.11 \
    python3.11-venv \
    python3.11-dev \
    python3-pip \
    nginx \
    git \
    curl \
    unzip \
    systemd \
    ufw \
    certbot \
    python3-certbot-nginx

# Install uv package manager
echo "Installing uv package manager..."
curl -LsSf https://astral.sh/uv/install.sh | sh
source $HOME/.cargo/env

# Create application user
echo "Creating application user..."
sudo useradd -m -s /bin/bash emailservice || true
sudo usermod -aG sudo emailservice

# Create application directory
echo "Setting up application directory..."
sudo mkdir -p /opt/email-service
sudo chown emailservice:emailservice /opt/email-service

# Configure firewall
echo "Configuring firewall..."
sudo ufw allow OpenSSH
sudo ufw allow 'Nginx Full'
sudo ufw allow 8000  # For direct API access during setup
sudo ufw --force enable

# Create log directory
echo "Setting up logging..."
sudo mkdir -p /var/log/email-service
sudo chown emailservice:emailservice /var/log/email-service

# Create environment file directory
echo "Setting up configuration..."
sudo mkdir -p /etc/email-service
sudo chown emailservice:emailservice /etc/email-service

echo "Azure VM setup completed!"
echo ""
echo "Next steps:"
echo "1. Copy your application code to /opt/email-service/"
echo "2. Create environment file at /etc/email-service/.env"
echo "3. Run the application deployment script: ./deploy_app.sh"
echo "4. Configure SSL certificates with: sudo certbot --nginx -d your-domain.com"

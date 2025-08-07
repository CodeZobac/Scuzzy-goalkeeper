#!/bin/bash

# Application Deployment Script for Python Email Service
# This script deploys the email service application to the Azure VM

set -e

APP_DIR="/opt/email-service"
SERVICE_USER="emailservice"
ENV_FILE="/etc/email-service/.env"

echo "Starting application deployment..."

# Ensure we're running as the service user or have proper permissions
if [[ $EUID -eq 0 ]]; then
    echo "Running as root, switching to service user for deployment..."
    sudo -u $SERVICE_USER bash "$0" "$@"
    exit $?
fi

# Change to application directory
cd $APP_DIR

# Verify environment file exists
if [[ ! -f $ENV_FILE ]]; then
    echo "Error: Environment file not found at $ENV_FILE"
    echo "Please create the environment file with required configuration."
    exit 1
fi

# Install dependencies using uv
echo "Installing Python dependencies with uv..."
uv venv .venv
source .venv/bin/activate
uv pip install -r pyproject.toml

# Run application tests
echo "Running application tests..."
python -m pytest tests/ -v

# Validate configuration
echo "Validating application configuration..."
python -c "from app.config import Settings; settings = Settings(_env_file='$ENV_FILE'); print('Configuration validated successfully')"

# Create systemd service file
echo "Creating systemd service file..."
sudo tee /etc/systemd/system/email-service.service > /dev/null << EOF
[Unit]
Description=Python Email Service API
After=network.target

[Service]
Type=simple
User=$SERVICE_USER
Group=$SERVICE_USER
WorkingDirectory=$APP_DIR
Environment=PATH=$APP_DIR/.venv/bin
EnvironmentFile=$ENV_FILE
ExecStart=$APP_DIR/.venv/bin/python -m uvicorn main:app --host 0.0.0.0 --port 8000 --workers 2
ExecReload=/bin/kill -HUP \$MAINPID
Restart=always
RestartSec=3
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=email-service

[Install]
WantedBy=multi-user.target
EOF

# Enable and start the service
echo "Enabling and starting email service..."
sudo systemctl daemon-reload
sudo systemctl enable email-service
sudo systemctl start email-service

# Wait for service to start
echo "Waiting for service to start..."
sleep 5

# Check service status
if sudo systemctl is-active --quiet email-service; then
    echo "Email service started successfully!"
else
    echo "Error: Email service failed to start"
    sudo systemctl status email-service
    exit 1
fi

# Test health endpoint
echo "Testing health endpoint..."
if curl -f http://localhost:8000/health > /dev/null 2>&1; then
    echo "Health check passed!"
else
    echo "Warning: Health check failed. Check service logs."
fi

echo ""
echo "Application deployment completed!"
echo ""
echo "Service commands:"
echo "  Status: sudo systemctl status email-service"
echo "  Logs:   sudo journalctl -u email-service -f"
echo "  Stop:   sudo systemctl stop email-service"
echo "  Start:  sudo systemctl start email-service"
echo ""
echo "Next steps:"
echo "1. Configure Nginx reverse proxy with: sudo cp deploy/nginx.conf /etc/nginx/sites-available/email-service"
echo "2. Enable Nginx site: sudo ln -s /etc/nginx/sites-available/email-service /etc/nginx/sites-enabled/"
echo "3. Test Nginx config: sudo nginx -t"
echo "4. Reload Nginx: sudo systemctl reload nginx"
echo "5. Set up SSL: sudo certbot --nginx -d your-domain.com"

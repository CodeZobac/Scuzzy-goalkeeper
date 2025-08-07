# Goalkeeper Email Service

A Python backend service for handling email operations via Azure Communication Services. This service provides a clean separation between the Flutter mobile application and email infrastructure.

## Features

- Send confirmation emails for user registration
- Send password reset emails
- Validate authentication codes
- Integration with Azure Communication Services
- Supabase database integration for authentication codes
- FastAPI-based REST API
- Modern Python tooling with uv package manager

## Project Structure

```
email-service/
├── pyproject.toml          # Project configuration and dependencies
├── main.py                 # FastAPI application entry point
├── .env                    # Environment variables (not in version control)
├── .env.example           # Example environment configuration
├── README.md              # This file
├── app/                   # Main application package
│   ├── __init__.py
│   ├── models/            # Pydantic data models
│   ├── services/          # Business logic services
│   ├── repositories/      # Database access layer
│   ├── clients/           # External service clients
│   └── utils/             # Utility functions
├── templates/             # Email HTML templates
│   ├── confirm_signup_template.html
│   └── reset_password_template.html
└── tests/                 # Test suite
    └── __init__.py
```

## Setup

1. Install uv package manager (if not already installed):

   ```bash
   curl -LsSf https://astral.sh/uv/install.sh | sh
   ```

2. Install dependencies:

   ```bash
   cd email-service
   uv sync
   ```

3. Copy environment configuration:

   ```bash
   cp .env.example .env
   # Edit .env with your actual configuration values
   ```

4. Run the development server:
   ```bash
   uv run uvicorn main:app --reload
   ```

## Environment Variables

See `.env.example` for all required environment variables. Key variables include:

- `SUPABASE_URL`: Your Supabase project URL
- `SUPABASE_ANON_KEY`: Supabase anonymous key
- `EMAIL_SERVICE`: Azure Communication Services endpoint
- `AZURE_KEY`: Azure Communication Services access key
- `EMAIL_FROM_ADDRESS`: Sender email address
- `APP_BASE_URL`: Base URL for generating email links

## API Documentation

The service provides a RESTful API with automatic OpenAPI documentation.

### Interactive Documentation

- **Swagger UI**: `http://localhost:8000/docs`
- **ReDoc**: `http://localhost:8000/redoc`
- **OpenAPI Schema**: `http://localhost:8000/openapi.json`

### API Endpoints

#### Root and Health Endpoints

- `GET /`: Root endpoint with service information
  ```json
  {
    "service": "Goalkeeper Email Service",
    "version": "1.0.0",
    "status": "running",
    "documentation": "/docs"
  }
  ```

- `GET /health`: Health check endpoint
  ```json
  {
    "status": "healthy",
    "timestamp": "2024-01-15T10:30:00Z",
    "version": "1.0.0"
  }
  ```

#### Email Operations

- `POST /api/v1/send-confirmation`: Send confirmation email
  
  **Request Body:**
  ```json
  {
    "email": "user@example.com",
    "user_id": "uuid-string"
  }
  ```
  
  **Response:**
  ```json
  {
    "success": true,
    "message": "Confirmation email sent successfully",
    "message_id": "azure-message-id"
  }
  ```

- `POST /api/v1/send-password-reset`: Send password reset email
  
  **Request Body:**
  ```json
  {
    "email": "user@example.com",
    "user_id": "uuid-string"
  }
  ```
  
  **Response:**
  ```json
  {
    "success": true,
    "message": "Password reset email sent successfully",
    "message_id": "azure-message-id"
  }
  ```

- `POST /api/v1/validate-code`: Validate authentication code
  
  **Request Body:**
  ```json
  {
    "code": "authentication-code",
    "code_type": "email_confirmation" // or "password_reset"
  }
  ```
  
  **Success Response:**
  ```json
  {
    "valid": true,
    "user_id": "uuid-string",
    "message": "Code validated successfully"
  }
  ```
  
  **Error Response:**
  ```json
  {
    "valid": false,
    "user_id": null,
    "message": "Invalid or expired code"
  }
  ```

### Error Responses

All endpoints return structured error responses:

```json
{
  "error": true,
  "error_type": "validation_error",
  "message": "Invalid email address format",
  "details": {
    "field": "email",
    "code": "INVALID_EMAIL"
  },
  "timestamp": "2024-01-15T10:30:00Z"
}
```

### HTTP Status Codes

- `200 OK`: Successful operation
- `400 Bad Request`: Invalid request data
- `422 Unprocessable Entity`: Validation errors
- `429 Too Many Requests`: Rate limiting (when deployed with Nginx)
- `500 Internal Server Error`: Server errors
- `503 Service Unavailable`: External service failures

## Development

This project uses modern Python tooling:

- **uv**: Fast Python package manager
- **FastAPI**: High-performance web framework
- **Pydantic**: Data validation and serialization
- **Ruff**: Fast Python linter and formatter

## Testing

Run tests with:

```bash
uv run pytest
```

## Deployment

The service is designed to run on Azure Virtual Machines with production-ready configuration including:

- Systemd service management
- Nginx reverse proxy with HTTPS
- SSL certificate automation with Let's Encrypt
- Comprehensive monitoring and maintenance tools
- Security hardening and rate limiting

### Quick Deployment

For development or testing:

```bash
# Run locally
uv run uvicorn main:app --host 0.0.0.0 --port 8000
```

### Production Deployment

For production deployment on Azure VM, see the comprehensive deployment guide:

**📖 [DEPLOYMENT.md](DEPLOYMENT.md)**

The deployment guide includes:

- Azure VM setup and configuration
- Application deployment automation
- Nginx reverse proxy setup
- SSL certificate configuration
- Service monitoring and maintenance
- Troubleshooting guides
- Security considerations

### Deployment Files

The `deploy/` directory contains all deployment configuration:

```
deploy/
├── setup_vm.sh              # Azure VM setup script
├── deploy_app.sh            # Application deployment script
├── nginx.conf               # Nginx reverse proxy configuration
├── email-service.service    # Systemd service template
├── .env.production         # Production environment template
└── maintenance.sh          # Maintenance and monitoring script
```

### Using the Maintenance Script

Once deployed, use the maintenance script for common operations:

```bash
# Check service status
sudo ./deploy/maintenance.sh status

# View logs
sudo ./deploy/maintenance.sh logs

# Restart service
sudo ./deploy/maintenance.sh restart

# Run health checks
sudo ./deploy/maintenance.sh health

# Update application
sudo ./deploy/maintenance.sh update
```

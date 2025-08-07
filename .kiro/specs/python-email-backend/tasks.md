# Implementation Plan

- [x] 1. Set up Python project structure and dependencies

  - Create email-service directory with proper Python project structure
  - Initialize pyproject.toml with uv package manager configuration
  - Add FastAPI, httpx, supabase, pydantic, and other required dependencies
  - Copy environment variables from .env to new email-service/.env file
  - Create .env.example file with placeholder values for deployment
  - Set up basic project structure with app/, templates/, and tests/ directories
  - _Requirements: 5.1, 5.2, 4.4_

- [x] 2. Implement core data models and configuration

  - Create Pydantic models for API requests and responses (EmailRequest, EmailResponse, etc.)
  - Implement AuthCode data model matching the existing Supabase schema
  - Create configuration management system using environment variables
  - Implement AuthCodeType enum for email_confirmation and password_reset types
  - Add validation and serialization methods for all data models
  - _Requirements: 4.1, 4.2, 4.3, 5.4_

- [x] 3. Create database repository for authentication codes

  - Implement AuthCodeRepository class with Supabase client integration
  - Add methods for storing, retrieving, and updating authentication codes
  - Implement secure code hashing using bcrypt before database storage
  - Add methods for cleaning up expired codes and marking codes as used
  - Include proper error handling and logging for database operations
  - _Requirements: 3.2, 3.3, 3.4, 4.3_

- [x] 4. Implement Azure Communication Services client

  - Create AzureClient class for handling Azure Communication Services API calls
  - Implement email sending functionality with proper request formatting
  - Add retry logic and comprehensive error handling for Azure API failures
  - Include authentication using Azure credentials from environment variables
  - Add logging for all Azure API interactions for debugging purposes
  - _Requirements: 4.1, 4.2, 8.3_

- [x] 5. Build authentication code service layer

  - Implement AuthCodeService with secure code generation using Python secrets module
  - Add code validation logic with expiration and one-time use enforcement
  - Create methods for generating, validating, and invalidating authentication codes
  - Integrate with database repository for code persistence
  - Include comprehensive logging for all authentication code operations
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 8.2_

- [x] 6. Create email template management system

  - Copy existing HTML email templates to templates/ directory
  - Implement TemplateManager class using Jinja2 for template rendering
  - Add methods for loading and processing confirmation and password reset templates
  - Create URL generation functions for confirmation and reset links with authentication codes
  - Include template validation and error handling for missing or invalid templates
  - Use uv to run scripts
  - _Requirements: 1.3, 2.3, 5.3_

- [x] 7. Implement core email service orchestration

  - Create EmailService class that orchestrates the complete email sending process
  - Integrate authentication code service, template manager, and Azure client
  - Implement send_confirmation_email and send_password_reset_email methods
  - Add proper error handling and logging for the complete email workflow
  - Include email composition logic that combines templates with authentication codes
  - Use uv to run scripts
  - _Requirements: 1.1, 1.2, 1.4, 2.1, 2.2, 2.4, 8.1_

- [x] 8. Build FastAPI application and API endpoints

  - Create main FastAPI application with proper configuration and middleware
  - Implement POST /api/v1/send-confirmation endpoint for confirmation emails
  - Implement POST /api/v1/send-password-reset endpoint for password reset emails
  - Implement POST /api/v1/validate-code endpoint for authentication code validation
  - Add GET /health endpoint for service health monitoring
  - Include proper request validation, error handling, and response formatting
  - Use uv to run scripts
  - _Requirements: 1.1, 1.5, 2.1, 2.5, 3.1, 3.5, 5.3, 5.5_

- [-] 9. Add comprehensive logging and monitoring

  - Implement structured logging system with configurable log levels
  - Add logging for all email operations, authentication code operations, and API requests
  - Create logging utilities for consistent log formatting and context
  - Add performance monitoring and timing for critical operations
  - Include error logging with appropriate detail levels for debugging
  - Use uv to run scripts
  - _Requirements: 8.1, 8.2, 8.3, 8.4, 8.5_

- [ ] 10. Create deployment configuration and documentation

  - Create deployment scripts and configuration for Azure VM setup
  - Add systemd service configuration for automatic startup and management
  - Create nginx configuration for reverse proxy and HTTPS termination
  - Write comprehensive README with setup, deployment, and maintenance instructions
  - Add API documentation using FastAPI's automatic OpenAPI generation
  - Use uv to run scripts
  - _Requirements: 7.1, 7.2, 7.3, 7.4, 7.5_

- [ ] 11. Refactor Flutter application to use Python backend

  - Remove all Azure Communication Services related code and dependencies from Dart app
  - Create HTTP client service for communicating with Python backend
  - Update email confirmation service to make HTTP requests instead of Azure calls
  - Update password reset service to make HTTP requests instead of Azure calls
  - Replace authentication code generation with HTTP requests to Python backend
  - Update error handling to process HTTP responses from Python backend
  - Use uv to run scripts
  - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5_

- [ ] 12. Update Flutter dependency injection and service registration

  - Remove Azure-specific service registrations from dependency injection system
  - Register new HTTP-based email service in Flutter app's service locator
  - Update service factory methods to create HTTP client instead of Azure client
  - Remove authentication code service and template manager from Flutter app
  - Update service lifecycle management for new HTTP-based architecture
  - Use uv to run scripts
  - _Requirements: 6.1, 6.2, 6.5_

- [ ] 13. Test end-to-end email functionality

  - Verify Python backend can successfully send confirmation emails via Azure
  - Verify Python backend can successfully send password reset emails via Azure
  - Test authentication code validation through Python backend API
  - Verify Flutter app can successfully communicate with Python backend
  - Test complete email confirmation flow from Flutter app through Python backend
  - Test complete password reset flow from Flutter app through Python backend
  - Verify error handling works correctly for various failure scenarios
  - _Requirements: 1.1-1.5, 2.1-2.5, 3.1-3.5_

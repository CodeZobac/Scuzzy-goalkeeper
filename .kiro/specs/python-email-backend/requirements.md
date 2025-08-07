# Requirements Document

## Introduction

This feature refactors the existing Azure email service implementation from the Flutter/Dart application into a standalone Python backend service. The Python service will handle all email communication with Azure Communication Services, while the Dart app will communicate with this Python backend via HTTP API calls. The Python backend will run on an Azure VM and use FastAPI for the API framework and uv for package management.

## Requirements

### Requirement 1

**User Story:** As a Flutter application, I want to send confirmation emails through a Python backend service, so that email functionality is separated from the mobile app and can be managed independently.

#### Acceptance Criteria

1. WHEN the Flutter app needs to send a confirmation email THEN it SHALL make an HTTP POST request to the Python backend service
2. WHEN the Python backend receives a confirmation email request THEN it SHALL generate a secure authentication code and store it in the auth_codes table
3. WHEN the authentication code is generated THEN the Python backend SHALL use the existing HTML template to compose the email
4. WHEN the email is composed THEN the Python backend SHALL send it via Azure Communication Services
5. WHEN the email is sent successfully THEN the Python backend SHALL return a success response to the Flutter app

### Requirement 2

**User Story:** As a Flutter application, I want to send password reset emails through a Python backend service, so that password reset functionality is handled consistently and securely.

#### Acceptance Criteria

1. WHEN the Flutter app needs to send a password reset email THEN it SHALL make an HTTP POST request to the Python backend service
2. WHEN the Python backend receives a password reset email request THEN it SHALL generate a secure authentication code and store it in the auth_codes table
3. WHEN the authentication code is generated THEN the Python backend SHALL use the existing HTML template to compose the email
4. WHEN the email is composed THEN the Python backend SHALL send it via Azure Communication Services
5. WHEN the email is sent successfully THEN the Python backend SHALL return a success response to the Flutter app

### Requirement 3

**User Story:** As a Flutter application, I want to validate authentication codes through the Python backend service, so that email verification and password reset flows can be completed securely.

#### Acceptance Criteria

1. WHEN the Flutter app needs to validate an authentication code THEN it SHALL make an HTTP POST request to the Python backend service with the code
2. WHEN the Python backend receives a code validation request THEN it SHALL check the code against the auth_codes table
3. WHEN validating the code THEN the Python backend SHALL verify it is not expired, not already used, and matches the expected type
4. WHEN the code is valid THEN the Python backend SHALL mark it as used and return success with user information
5. WHEN the code is invalid, expired, or already used THEN the Python backend SHALL return an appropriate error response

### Requirement 4

**User Story:** As a system administrator, I want the Python backend to securely connect to Azure Communication Services and the Supabase database, so that email functionality works reliably in the Azure VM environment.

#### Acceptance Criteria

1. WHEN the Python backend starts THEN it SHALL load configuration from environment variables including Azure credentials and Supabase connection details
2. WHEN connecting to Azure Communication Services THEN the Python backend SHALL use the EMAIL_SERVICE endpoint, AZURE_KEY, and AZURE_CONNECTION_STRING
3. WHEN connecting to Supabase THEN the Python backend SHALL use the SUPABASE_URL and SUPABASE_ANON_KEY for database operations
4. WHEN database operations are performed THEN the Python backend SHALL only interact with the auth_codes table
5. WHEN configuration is missing or invalid THEN the Python backend SHALL fail to start with clear error messages

### Requirement 5

**User Story:** As a developer, I want the Python backend to be built with modern Python tools and best practices, so that it is maintainable, performant, and easy to deploy.

#### Acceptance Criteria

1. WHEN setting up the project THEN it SHALL use uv for package management and dependency resolution
2. WHEN building the API THEN it SHALL use FastAPI framework for high performance and automatic documentation
3. WHEN handling HTTP requests THEN the Python backend SHALL provide proper error handling, logging, and response formatting
4. WHEN deployed to Azure VM THEN the Python backend SHALL be easily configurable through environment variables
5. WHEN running THEN the Python backend SHALL provide health check endpoints and proper startup/shutdown handling

### Requirement 6

**User Story:** As a Flutter developer, I want to update the Dart application to use the Python backend, so that email functionality is cleanly separated and the app no longer contains Azure-specific code.

#### Acceptance Criteria

1. WHEN refactoring the Dart app THEN it SHALL remove all Azure Communication Services related code and dependencies
2. WHEN sending emails THEN the Dart app SHALL make HTTP requests to the Python backend instead of calling Azure directly
3. WHEN handling email responses THEN the Dart app SHALL process HTTP responses from the Python backend
4. WHEN errors occur THEN the Dart app SHALL handle HTTP errors from the Python backend appropriately
5. WHEN the refactoring is complete THEN the Dart app SHALL have no direct dependencies on Azure services for email functionality

### Requirement 7

**User Story:** As a cloud engineer, I want the Python service to be deployed to Azure, so that it runs in a reliable cloud environment with proper scalability and availability.

#### Acceptance Criteria

1. WHEN deploying the Python backend THEN it SHALL be configured to run on an Azure Virtual Machine
2. WHEN setting up the Azure VM THEN it SHALL have the necessary Python runtime and dependencies installed
3. WHEN configuring the deployment THEN it SHALL use environment variables for all configuration including Azure and Supabase credentials
4. WHEN the service starts THEN it SHALL bind to the appropriate network interface and port for external access
5. WHEN deployed THEN the Python backend SHALL be accessible from the Flutter application over HTTPS

### Requirement 8

**User Story:** As a system operator, I want the Python backend to provide comprehensive logging and monitoring capabilities, so that email operations can be tracked and debugged effectively.

#### Acceptance Criteria

1. WHEN email operations are performed THEN the Python backend SHALL log all significant events including requests, responses, and errors
2. WHEN authentication codes are generated or validated THEN the Python backend SHALL log these operations with appropriate detail levels
3. WHEN Azure Communication Services calls are made THEN the Python backend SHALL log request/response information for debugging
4. WHEN errors occur THEN the Python backend SHALL log detailed error information including stack traces where appropriate
5. WHEN running in production THEN the Python backend SHALL support configurable log levels and structured logging formats

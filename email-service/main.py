"""
Main entry point for the Goalkeeper Email Service.

This module provides the FastAPI application for handling email operations
via Azure Communication Services with comprehensive logging and monitoring.
"""

import logging
from datetime import datetime
from typing import Dict, Any

from fastapi import FastAPI, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse, PlainTextResponse

from app.config import settings
from app.models.requests import EmailRequest, CodeValidationRequest
from app.models.responses import EmailResponse, CodeValidationResponse, HealthResponse, ErrorResponse
from app.services.email_service import EmailService, EmailServiceError
from app.services.auth_code_service import AuthCodeService, AuthCodeServiceError
from app.utils.logging import configure_logging, get_service_logger, OperationContext
from app.utils.middleware import LoggingMiddleware, HealthCheckMiddleware, ErrorTrackingMiddleware
from app.utils.metrics import get_service_metrics, get_health_metrics, reset_all_metrics, MetricsReporter

# Configure comprehensive logging system
configure_logging()
logger = get_service_logger("main")

# Initialize services
email_service = EmailService()
auth_code_service = AuthCodeService()

app = FastAPI(
    title="Goalkeeper Email Service",
    description="Python backend service for handling email operations via Azure Communication Services",
    version="0.1.0",
    docs_url="/docs" if not settings.is_production else None,
    redoc_url="/redoc" if not settings.is_production else None,
)

# Add comprehensive logging and monitoring middleware
app.add_middleware(ErrorTrackingMiddleware)
app.add_middleware(LoggingMiddleware)
app.add_middleware(HealthCheckMiddleware)

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Configure appropriately for production
    allow_credentials=True,
    allow_methods=["GET", "POST"],
    allow_headers=["*"],
)


@app.exception_handler(EmailServiceError)
async def email_service_exception_handler(request, exc: EmailServiceError):
    """Handle EmailService exceptions."""
    logger.error(f"EmailService error: {exc}")
    return JSONResponse(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        content=ErrorResponse(
            error_type="email_service_error",
            message=str(exc),
            timestamp=datetime.utcnow()
        ).dict()
    )


@app.exception_handler(AuthCodeServiceError)
async def auth_code_service_exception_handler(request, exc: AuthCodeServiceError):
    """Handle AuthCodeService exceptions."""
    logger.error(f"AuthCodeService error: {exc}")
    return JSONResponse(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        content=ErrorResponse(
            error_type="auth_code_service_error",
            message=str(exc),
            timestamp=datetime.utcnow()
        ).dict()
    )


@app.exception_handler(ValueError)
async def validation_exception_handler(request, exc: ValueError):
    """Handle validation errors."""
    logger.warning(f"Validation error: {exc}")
    return JSONResponse(
        status_code=status.HTTP_400_BAD_REQUEST,
        content=ErrorResponse(
            error_type="validation_error",
            message=str(exc),
            timestamp=datetime.utcnow()
        ).dict()
    )


@app.get("/")
async def root() -> Dict[str, Any]:
    """Root endpoint providing API information."""
    return {
        "message": "Goalkeeper Email Service",
        "version": "0.1.0",
        "status": "running",
        "environment": settings.environment,
        "endpoints": {
            "health": "/health",
            "metrics": "/metrics",
            "metrics_text": "/metrics/text",
            "send_confirmation": "/api/v1/send-confirmation",
            "send_password_reset": "/api/v1/send-password-reset",
            "validate_code": "/api/v1/validate-code"
        }
    }


@app.get("/health", response_model=HealthResponse)
async def health_check() -> HealthResponse:
    """Health check endpoint for service monitoring."""
    with OperationContext("health_check", logger.logger) as context:
        try:
            # Get health metrics from our metrics system
            health_metrics = get_health_metrics()
            
            # Perform email service health check
            service_health = await email_service.health_check()
            
            # Combine both health indicators
            metrics_status = health_metrics.get("health_status", "unknown")
            service_status = service_health.get("overall", "unknown")
            
            # Determine overall status (most pessimistic wins)
            if metrics_status == "unhealthy" or service_status == "unhealthy":
                status_text = "unhealthy"
            elif metrics_status == "degraded" or service_status == "degraded":
                status_text = "degraded"
            elif metrics_status == "healthy" and service_status == "healthy":
                status_text = "healthy"
            else:
                status_text = "unknown"
            
            context.log_checkpoint("health_determined", 
                                 metrics_status=metrics_status,
                                 service_status=service_status,
                                 overall_status=status_text)
            
            logger.log_email_operation(
                level=20,  # INFO
                operation="health_check_completed",
                health_status=status_text,
                error_rate=health_metrics.get("error_rate_5min", 0),
                uptime_minutes=health_metrics.get("uptime_minutes", 0)
            )
            
            response = HealthResponse(
                status=status_text,
                timestamp=datetime.utcnow(),
                version="0.1.0",
                environment=settings.environment
            )
            
            # Add health details to response if not production
            if not settings.is_production:
                response_dict = response.dict()
                response_dict["details"] = {
                    "metrics_health": health_metrics,
                    "service_health": service_health
                }
                return response_dict
            
            return response
            
        except Exception as e:
            context.update_context(error=str(e))
            logger.log_email_operation(
                level=40,  # ERROR
                operation="health_check_failed",
                error=str(e)
            )
            
            return HealthResponse(
                status="unhealthy",
                timestamp=datetime.utcnow(),
                version="0.1.0",
                environment=settings.environment
            )


@app.post("/api/v1/send-confirmation", response_model=EmailResponse)
async def send_confirmation_email(request: EmailRequest) -> EmailResponse:
    """
    Send a confirmation email to the specified user.
    
    Args:
        request: EmailRequest containing email and user_id
        
    Returns:
        EmailResponse indicating success or failure
        
    Raises:
        HTTPException: If email sending fails
    """
    logger.info(
        f"Confirmation email request received for user {request.user_id} at {request.email}"
    )
    
    try:
        response = await email_service.send_confirmation_email(
            email=request.email,
            user_id=request.user_id
        )
        
        if response.success:
            logger.info(
                f"Confirmation email sent successfully to {request.email} "
                f"with message ID: {response.message_id}"
            )
        else:
            logger.warning(
                f"Confirmation email failed for {request.email}: {response.message}"
            )
        
        return response
        
    except EmailServiceError as e:
        logger.error(f"EmailService error sending confirmation email: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to send confirmation email: {e}"
        )
    except Exception as e:
        logger.error(f"Unexpected error sending confirmation email: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Internal server error"
        )


@app.post("/api/v1/send-password-reset", response_model=EmailResponse)
async def send_password_reset_email(request: EmailRequest) -> EmailResponse:
    """
    Send a password reset email to the specified user.
    
    Args:
        request: EmailRequest containing email and user_id
        
    Returns:
        EmailResponse indicating success or failure
        
    Raises:
        HTTPException: If email sending fails
    """
    logger.info(
        f"Password reset email request received for user {request.user_id} at {request.email}"
    )
    
    try:
        response = await email_service.send_password_reset_email(
            email=request.email,
            user_id=request.user_id
        )
        
        if response.success:
            logger.info(
                f"Password reset email sent successfully to {request.email} "
                f"with message ID: {response.message_id}"
            )
        else:
            logger.warning(
                f"Password reset email failed for {request.email}: {response.message}"
            )
        
        return response
        
    except EmailServiceError as e:
        logger.error(f"EmailService error sending password reset email: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to send password reset email: {e}"
        )
    except Exception as e:
        logger.error(f"Unexpected error sending password reset email: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Internal server error"
        )


@app.post("/api/v1/validate-code", response_model=CodeValidationResponse)
async def validate_authentication_code(request: CodeValidationRequest) -> CodeValidationResponse:
    """
    Validate an authentication code.
    
    Args:
        request: CodeValidationRequest containing code and code_type
        
    Returns:
        CodeValidationResponse indicating validation result
        
    Raises:
        HTTPException: If validation process fails
    """
    logger.info(
        f"Code validation request received for code type: {request.code_type}"
    )
    
    try:
        # Validate the authentication code
        auth_code = auth_code_service.validate_code(
            code=request.code,
            code_type=request.code_type
        )
        
        if auth_code:
            # Code is valid, mark it as used
            success = auth_code_service.invalidate_code(
                code=request.code,
                code_type=request.code_type
            )
            
            if success:
                logger.info(
                    f"Authentication code validated and invalidated for user {auth_code.user_id}"
                )
                return CodeValidationResponse(
                    valid=True,
                    user_id=auth_code.user_id,
                    message="Authentication code is valid"
                )
            else:
                logger.error(
                    f"Failed to invalidate authentication code for user {auth_code.user_id}"
                )
                return CodeValidationResponse(
                    valid=False,
                    message="Code validation failed during invalidation"
                )
        else:
            logger.info("Authentication code validation failed - code not found or invalid")
            return CodeValidationResponse(
                valid=False,
                message="Authentication code is invalid, expired, or already used"
            )
            
    except AuthCodeServiceError as e:
        logger.error(f"AuthCodeService error validating code: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to validate authentication code: {e}"
        )
    except Exception as e:
        logger.error(f"Unexpected error validating authentication code: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Internal server error"
        )


@app.get("/metrics")
async def get_metrics() -> Dict[str, Any]:
    """
    Get comprehensive service metrics in JSON format.
    
    Returns:
        Dict containing detailed service metrics and performance data
    """
    with OperationContext("get_metrics", logger.logger) as context:
        try:
            metrics_data = get_service_metrics()
            health_data = get_health_metrics()
            
            context.log_checkpoint("metrics_collected", 
                                 metrics_count=len(metrics_data),
                                 health_status=health_data.get("health_status"))
            
            return {
                "service_metrics": metrics_data,
                "health_metrics": health_data,
                "generated_at": datetime.utcnow().isoformat()
            }
        except Exception as e:
            context.update_context(error=str(e))
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to retrieve metrics"
            )


@app.get("/metrics/text", response_class=PlainTextResponse)
async def get_metrics_text() -> str:
    """
    Get service metrics in human-readable text format.
    
    Returns:
        Plain text formatted metrics report
    """
    with OperationContext("get_metrics_text", logger.logger):
        try:
            return MetricsReporter.generate_text_report()
        except Exception as e:
            logger.error(f"Failed to generate text metrics report: {e}")
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to generate metrics report"
            )


@app.post("/metrics/reset")
async def reset_metrics() -> Dict[str, str]:
    """
    Reset all collected metrics data.
    
    Note: This endpoint is only available in development mode.
    
    Returns:
        Confirmation message
    """
    if settings.is_production:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Metrics reset is not allowed in production"
        )
    
    with OperationContext("reset_metrics", logger.logger):
        try:
            reset_all_metrics()
            logger.info("All metrics have been reset")
            return {"message": "All metrics have been reset successfully"}
        except Exception as e:
            logger.error(f"Failed to reset metrics: {e}")
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to reset metrics"
            )


@app.on_event("startup")
async def startup_event():
    """Application startup event handler."""
    logger.info("Starting Goalkeeper Email Service")
    logger.info(f"Environment: {settings.environment}")
    logger.info(f"Host: {settings.host}:{settings.port}")
    logger.info(f"Log level: {settings.log_level}")
    
    # Log service configuration (without sensitive data)
    service_info = email_service.get_service_info()
    logger.info(f"Email service configured: {service_info}")


@app.on_event("shutdown")
async def shutdown_event():
    """Application shutdown event handler."""
    logger.info("Shutting down Goalkeeper Email Service")


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        app, 
        host=settings.host, 
        port=settings.port,
        log_level=settings.log_level.lower()
    )
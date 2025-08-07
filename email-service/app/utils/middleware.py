"""
Middleware for comprehensive logging and monitoring of API requests and responses.

This module provides FastAPI middleware for automatic logging of all API operations,
performance monitoring, and error tracking.
"""

import json
import time
from typing import Callable
from uuid import uuid4

from fastapi import Request, Response
from starlette.middleware.base import BaseHTTPMiddleware

from app.utils.logging import get_service_logger, performance_metrics


class LoggingMiddleware(BaseHTTPMiddleware):
    """
    Middleware for comprehensive request/response logging and performance monitoring.
    
    This middleware automatically logs:
    - All incoming API requests with timing
    - Response status codes and sizes
    - Request/response timing metrics
    - Error details for failed requests
    """
    
    def __init__(self, app, logger_name: str = "api"):
        super().__init__(app)
        self.logger = get_service_logger(logger_name)
    
    async def dispatch(self, request: Request, call_next: Callable) -> Response:
        """Process request and response with comprehensive logging."""
        # Generate unique request ID for tracing
        request_id = str(uuid4())[:8]
        
        # Start timing
        start_time = time.time()
        
        # Extract request details
        method = request.method
        url = str(request.url)
        path = request.url.path
        user_agent = request.headers.get("user-agent", "")
        content_type = request.headers.get("content-type", "")
        content_length = request.headers.get("content-length", 0)
        
        # Log incoming request
        self.logger.log_api_request(
            level=20,  # INFO
            method=method,
            path=path,
            user_agent=user_agent,
            request_id=request_id,
            content_type=content_type,
            content_length=content_length,
            request_stage="started"
        )
        
        try:
            # Process the request
            response = await call_next(request)
            
            # Calculate timing
            end_time = time.time()
            duration_ms = (end_time - start_time) * 1000
            
            # Extract response details
            status_code = response.status_code
            response_size = response.headers.get("content-length", 0)
            
            # Record performance metrics
            performance_metrics.record_timing(
                f"api_request_{method.lower()}",
                duration_ms,
                tags={
                    "method": method,
                    "status_code": str(status_code),
                    "path": path
                }
            )
            
            performance_metrics.record_counter(
                f"api_requests_total",
                tags={
                    "method": method,
                    "status_code": str(status_code),
                    "path": path
                }
            )
            
            # Determine log level based on status code
            if 200 <= status_code < 300:
                log_level = 20  # INFO
            elif 400 <= status_code < 500:
                log_level = 30  # WARNING
            else:
                log_level = 40  # ERROR
            
            # Log response
            self.logger.log_api_request(
                level=log_level,
                method=method,
                path=path,
                status_code=status_code,
                response_time_ms=round(duration_ms, 2),
                user_agent=user_agent,
                request_id=request_id,
                response_size=response_size,
                request_stage="completed"
            )
            
            # Add request ID to response headers for tracing
            response.headers["X-Request-ID"] = request_id
            
            return response
            
        except Exception as e:
            # Calculate timing for failed requests
            end_time = time.time()
            duration_ms = (end_time - start_time) * 1000
            
            # Record failure metrics
            performance_metrics.record_timing(
                f"api_request_{method.lower()}_failed",
                duration_ms,
                tags={
                    "method": method,
                    "error_type": type(e).__name__,
                    "path": path
                }
            )
            
            performance_metrics.record_counter(
                f"api_requests_errors",
                tags={
                    "method": method,
                    "error_type": type(e).__name__,
                    "path": path
                }
            )
            
            # Log the error
            self.logger.error(
                f"Request failed: {method} {path}",
                extra={
                    "request_id": request_id,
                    "method": method,
                    "path": path,
                    "user_agent": user_agent,
                    "duration_ms": round(duration_ms, 2),
                    "error_type": type(e).__name__,
                    "error_message": str(e),
                    "request_stage": "failed"
                },
                exc_info=True
            )
            
            # Re-raise the exception
            raise


class HealthCheckMiddleware(BaseHTTPMiddleware):
    """
    Middleware for enhanced health check monitoring.
    
    This middleware provides detailed health check logging and metrics collection
    for monitoring service availability and performance.
    """
    
    def __init__(self, app):
        super().__init__(app)
        self.logger = get_service_logger("health")
        self.health_check_paths = {"/health", "/health/", "/healthz", "/"}
    
    async def dispatch(self, request: Request, call_next: Callable) -> Response:
        """Process health check requests with enhanced monitoring."""
        if request.url.path in self.health_check_paths:
            start_time = time.time()
            
            try:
                response = await call_next(request)
                
                end_time = time.time()
                duration_ms = (end_time - start_time) * 1000
                
                # Record health check metrics
                performance_metrics.record_timing("health_check", duration_ms)
                
                if response.status_code == 200:
                    performance_metrics.record_counter("health_check_success")
                else:
                    performance_metrics.record_counter("health_check_failure")
                
                # Log health check result
                self.logger.debug(
                    f"Health check completed",
                    extra={
                        "path": request.url.path,
                        "status_code": response.status_code,
                        "duration_ms": round(duration_ms, 2),
                        "health_status": "healthy" if response.status_code == 200 else "unhealthy"
                    }
                )
                
                return response
                
            except Exception as e:
                end_time = time.time()
                duration_ms = (end_time - start_time) * 1000
                
                performance_metrics.record_timing("health_check_failed", duration_ms)
                performance_metrics.record_counter("health_check_error")
                
                self.logger.error(
                    "Health check failed",
                    extra={
                        "path": request.url.path,
                        "duration_ms": round(duration_ms, 2),
                        "error_type": type(e).__name__,
                        "error_message": str(e),
                        "health_status": "error"
                    },
                    exc_info=True
                )
                
                raise
        else:
            # Not a health check, pass through normally
            return await call_next(request)


class ErrorTrackingMiddleware(BaseHTTPMiddleware):
    """
    Middleware for comprehensive error tracking and analysis.
    
    This middleware captures and logs detailed information about all errors
    occurring in the application, including stack traces and context.
    """
    
    def __init__(self, app):
        super().__init__(app)
        self.logger = get_service_logger("errors")
    
    async def dispatch(self, request: Request, call_next: Callable) -> Response:
        """Track and log errors with detailed context."""
        try:
            response = await call_next(request)
            return response
            
        except Exception as e:
            # Generate error ID for tracking
            error_id = str(uuid4())[:8]
            
            # Extract request context
            request_context = {
                "error_id": error_id,
                "method": request.method,
                "path": request.url.path,
                "query_params": dict(request.query_params) if request.query_params else None,
                "user_agent": request.headers.get("user-agent"),
                "content_type": request.headers.get("content-type"),
                "error_type": type(e).__name__,
                "error_message": str(e)
            }
            
            # Try to get request body for non-GET requests (with size limit)
            if request.method not in ["GET", "HEAD"] and hasattr(request, "_body"):
                try:
                    body = request._body
                    if body and len(body) < 1024:  # Only log small request bodies
                        if request.headers.get("content-type", "").startswith("application/json"):
                            try:
                                request_context["request_body"] = json.loads(body)
                            except (json.JSONDecodeError, UnicodeDecodeError):
                                request_context["request_body"] = "<invalid_json>"
                        else:
                            request_context["request_body"] = f"<{len(body)} bytes>"
                    elif body:
                        request_context["request_body"] = f"<{len(body)} bytes (too large to log)>"
                except Exception:
                    request_context["request_body"] = "<error reading body>"
            
            # Record error metrics
            performance_metrics.record_counter(
                "application_errors",
                tags={
                    "error_type": type(e).__name__,
                    "method": request.method,
                    "path": request.url.path
                }
            )
            
            # Log the error with full context
            self.logger.error(
                f"Application error [{error_id}]: {type(e).__name__}",
                extra=request_context,
                exc_info=True
            )
            
            # Re-raise the exception to be handled by FastAPI's exception handlers
            raise

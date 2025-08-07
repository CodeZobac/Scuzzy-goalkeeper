"""
Comprehensive logging utilities for the email service.

This module provides structured logging with context management, performance monitoring,
and consistent formatting across the application.
"""

import logging
import time
from contextlib import contextmanager
from datetime import datetime
from functools import wraps
from typing import Any, Dict, Optional, Union
from uuid import uuid4

import structlog
from pythonjsonlogger import jsonlogger

from app.config import settings


class OperationContext:
    """Context manager for tracking operations with consistent logging."""
    
    def __init__(
        self,
        operation_name: str,
        logger: logging.Logger,
        **context_data: Any
    ):
        self.operation_name = operation_name
        self.logger = logger
        self.context_data = context_data
        self.operation_id = str(uuid4())[:8]
        self.start_time: Optional[float] = None
        self.end_time: Optional[float] = None
    
    def __enter__(self):
        self.start_time = time.time()
        self.logger.info(
            f"Starting operation: {self.operation_name}",
            extra={
                "operation_id": self.operation_id,
                "operation_name": self.operation_name,
                "operation_status": "started",
                **self.context_data
            }
        )
        return self
    
    def __exit__(self, exc_type, exc_val, exc_tb):
        self.end_time = time.time()
        duration_ms = (self.end_time - self.start_time) * 1000 if self.start_time else 0
        
        if exc_type is None:
            # Operation completed successfully
            self.logger.info(
                f"Operation completed: {self.operation_name}",
                extra={
                    "operation_id": self.operation_id,
                    "operation_name": self.operation_name,
                    "operation_status": "completed",
                    "duration_ms": round(duration_ms, 2),
                    **self.context_data
                }
            )
        else:
            # Operation failed with exception
            self.logger.error(
                f"Operation failed: {self.operation_name}",
                extra={
                    "operation_id": self.operation_id,
                    "operation_name": self.operation_name,
                    "operation_status": "failed",
                    "duration_ms": round(duration_ms, 2),
                    "error_type": exc_type.__name__ if exc_type else None,
                    "error_message": str(exc_val) if exc_val else None,
                    **self.context_data
                },
                exc_info=True
            )
    
    def log_checkpoint(self, checkpoint_name: str, **checkpoint_data: Any):
        """Log a checkpoint within the operation."""
        current_time = time.time()
        duration_ms = (current_time - self.start_time) * 1000 if self.start_time else 0
        
        self.logger.debug(
            f"Operation checkpoint: {checkpoint_name}",
            extra={
                "operation_id": self.operation_id,
                "operation_name": self.operation_name,
                "checkpoint_name": checkpoint_name,
                "checkpoint_duration_ms": round(duration_ms, 2),
                **checkpoint_data,
                **self.context_data
            }
        )
    
    def update_context(self, **new_context: Any):
        """Update the operation context with additional data."""
        self.context_data.update(new_context)


def performance_monitor(operation_name: str):
    """Decorator for monitoring operation performance."""
    def decorator(func):
        @wraps(func)
        async def async_wrapper(*args, **kwargs):
            logger = logging.getLogger(func.__module__)
            
            with OperationContext(
                operation_name=operation_name,
                logger=logger,
                function_name=func.__name__,
                module=func.__module__
            ) as context:
                try:
                    result = await func(*args, **kwargs)
                    context.update_context(success=True)
                    return result
                except Exception as e:
                    context.update_context(
                        success=False,
                        error_type=type(e).__name__,
                        error_message=str(e)
                    )
                    raise
        
        @wraps(func)
        def sync_wrapper(*args, **kwargs):
            logger = logging.getLogger(func.__module__)
            
            with OperationContext(
                operation_name=operation_name,
                logger=logger,
                function_name=func.__name__,
                module=func.__module__
            ) as context:
                try:
                    result = func(*args, **kwargs)
                    context.update_context(success=True)
                    return result
                except Exception as e:
                    context.update_context(
                        success=False,
                        error_type=type(e).__name__,
                        error_message=str(e)
                    )
                    raise
        
        # Return appropriate wrapper based on whether function is async
        import inspect
        if inspect.iscoroutinefunction(func):
            return async_wrapper
        else:
            return sync_wrapper
    
    return decorator


class EmailServiceLoggerAdapter(logging.LoggerAdapter):
    """Custom logger adapter for email service with consistent context."""
    
    def __init__(self, logger: logging.Logger, service_name: str):
        self.service_name = service_name
        super().__init__(logger, {})
    
    def process(self, msg: str, kwargs: Dict[str, Any]) -> tuple[str, Dict[str, Any]]:
        """Process log record to add consistent context."""
        extra = kwargs.get('extra', {})
        extra.update({
            'service': self.service_name,
            'timestamp': datetime.utcnow().isoformat(),
            'environment': settings.environment
        })
        kwargs['extra'] = extra
        return msg, kwargs
    
    def log_email_operation(
        self,
        level: int,
        operation: str,
        email: Optional[str] = None,
        user_id: Optional[str] = None,
        message_id: Optional[str] = None,
        error: Optional[str] = None,
        **kwargs: Any
    ):
        """Log email operation with standardized fields."""
        extra = {
            'operation_type': 'email_operation',
            'email_operation': operation,
        }
        
        if email:
            extra['email'] = email
        if user_id:
            extra['user_id'] = user_id
        if message_id:
            extra['message_id'] = message_id
        if error:
            extra['error'] = error
        
        extra.update(kwargs)
        
        self.log(level, f"Email operation: {operation}", extra=extra)
    
    def log_auth_code_operation(
        self,
        level: int,
        operation: str,
        user_id: Optional[str] = None,
        code_type: Optional[str] = None,
        code_preview: Optional[str] = None,
        error: Optional[str] = None,
        **kwargs: Any
    ):
        """Log authentication code operation with standardized fields."""
        extra = {
            'operation_type': 'auth_code_operation',
            'auth_code_operation': operation,
        }
        
        if user_id:
            extra['user_id'] = user_id
        if code_type:
            extra['code_type'] = code_type
        if code_preview:
            extra['code_preview'] = code_preview
        if error:
            extra['error'] = error
        
        extra.update(kwargs)
        
        self.log(level, f"Auth code operation: {operation}", extra=extra)
    
    def log_azure_operation(
        self,
        level: int,
        operation: str,
        status_code: Optional[int] = None,
        response_time_ms: Optional[float] = None,
        error: Optional[str] = None,
        **kwargs: Any
    ):
        """Log Azure Communication Services operation with standardized fields."""
        extra = {
            'operation_type': 'azure_operation',
            'azure_operation': operation,
        }
        
        if status_code:
            extra['status_code'] = status_code
        if response_time_ms:
            extra['response_time_ms'] = response_time_ms
        if error:
            extra['error'] = error
        
        extra.update(kwargs)
        
        self.log(level, f"Azure operation: {operation}", extra=extra)
    
    def log_database_operation(
        self,
        level: int,
        operation: str,
        table: Optional[str] = None,
        query_time_ms: Optional[float] = None,
        rows_affected: Optional[int] = None,
        error: Optional[str] = None,
        **kwargs: Any
    ):
        """Log database operation with standardized fields."""
        extra = {
            'operation_type': 'database_operation',
            'database_operation': operation,
        }
        
        if table:
            extra['table'] = table
        if query_time_ms:
            extra['query_time_ms'] = query_time_ms
        if rows_affected:
            extra['rows_affected'] = rows_affected
        if error:
            extra['error'] = error
        
        extra.update(kwargs)
        
        self.log(level, f"Database operation: {operation}", extra=extra)
    
    def log_api_request(
        self,
        level: int,
        method: str,
        path: str,
        status_code: Optional[int] = None,
        response_time_ms: Optional[float] = None,
        user_agent: Optional[str] = None,
        **kwargs: Any
    ):
        """Log API request with standardized fields."""
        extra = {
            'operation_type': 'api_request',
            'http_method': method,
            'http_path': path,
        }
        
        if status_code:
            extra['http_status_code'] = status_code
        if response_time_ms:
            extra['response_time_ms'] = response_time_ms
        if user_agent:
            extra['user_agent'] = user_agent
        
        extra.update(kwargs)
        
        self.log(level, f"API {method} {path}", extra=extra)


class PerformanceMetrics:
    """Simple performance metrics collection."""
    
    def __init__(self):
        self._metrics = {}
    
    def record_timing(self, metric_name: str, duration_ms: float, tags: Optional[Dict[str, str]] = None):
        """Record a timing metric."""
        if metric_name not in self._metrics:
            self._metrics[metric_name] = {
                'count': 0,
                'total_time': 0.0,
                'min_time': float('inf'),
                'max_time': 0.0,
                'tags': tags or {}
            }
        
        metric = self._metrics[metric_name]
        metric['count'] += 1
        metric['total_time'] += duration_ms
        metric['min_time'] = min(metric['min_time'], duration_ms)
        metric['max_time'] = max(metric['max_time'], duration_ms)
    
    def record_counter(self, metric_name: str, count: int = 1, tags: Optional[Dict[str, str]] = None):
        """Record a counter metric."""
        key = f"{metric_name}_counter"
        if key not in self._metrics:
            self._metrics[key] = {
                'value': 0,
                'tags': tags or {}
            }
        
        self._metrics[key]['value'] += count
    
    def get_metrics(self) -> Dict[str, Any]:
        """Get all recorded metrics."""
        result = {}
        
        for name, data in self._metrics.items():
            if 'count' in data:  # Timing metric
                result[name] = {
                    'count': data['count'],
                    'avg_time_ms': data['total_time'] / data['count'] if data['count'] > 0 else 0,
                    'min_time_ms': data['min_time'] if data['min_time'] != float('inf') else 0,
                    'max_time_ms': data['max_time'],
                    'total_time_ms': data['total_time'],
                    'tags': data['tags']
                }
            else:  # Counter metric
                result[name] = {
                    'value': data['value'],
                    'tags': data['tags']
                }
        
        return result
    
    def reset(self):
        """Reset all metrics."""
        self._metrics.clear()


# Global metrics instance
performance_metrics = PerformanceMetrics()


def configure_logging():
    """Configure structured logging for the application."""
    # Configure structlog
    structlog.configure(
        processors=[
            structlog.stdlib.filter_by_level,
            structlog.stdlib.add_logger_name,
            structlog.stdlib.add_log_level,
            structlog.stdlib.PositionalArgumentsFormatter(),
            structlog.processors.TimeStamper(fmt="iso"),
            structlog.processors.StackInfoRenderer(),
            structlog.processors.format_exc_info,
            structlog.processors.UnicodeDecoder(),
            structlog.processors.JSONRenderer() if settings.log_format == "json" else structlog.dev.ConsoleRenderer(),
        ],
        context_class=dict,
        logger_factory=structlog.stdlib.LoggerFactory(),
        wrapper_class=structlog.stdlib.BoundLogger,
        cache_logger_on_first_use=True,
    )
    
    # Configure root logger
    root_logger = logging.getLogger()
    
    # Remove default handlers
    for handler in root_logger.handlers[:]:
        root_logger.removeHandler(handler)
    
    # Create handler
    handler = logging.StreamHandler()
    
    if settings.log_format == "json":
        # Use JSON formatter for structured logging
        formatter = jsonlogger.JsonFormatter(
            fmt='%(asctime)s %(name)s %(levelname)s %(message)s',
            datefmt='%Y-%m-%dT%H:%M:%S'
        )
    else:
        # Use standard formatter for development
        formatter = logging.Formatter(
            fmt='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
            datefmt='%Y-%m-%d %H:%M:%S'
        )
    
    handler.setFormatter(formatter)
    root_logger.addHandler(handler)
    root_logger.setLevel(getattr(logging, settings.log_level.upper()))
    
    # Configure specific loggers
    logging.getLogger("uvicorn.access").setLevel(logging.INFO)
    logging.getLogger("httpx").setLevel(logging.WARNING)  # Reduce noise from HTTP client
    
    return root_logger


def get_service_logger(service_name: str) -> EmailServiceLoggerAdapter:
    """Get a configured logger adapter for a service."""
    logger = logging.getLogger(f"email_service.{service_name}")
    return EmailServiceLoggerAdapter(logger, service_name)


@contextmanager
def timed_operation(operation_name: str, logger: logging.Logger, **context: Any):
    """Context manager for timing operations and logging performance."""
    start_time = time.time()
    operation_id = str(uuid4())[:8]
    
    logger.info(
        f"Starting timed operation: {operation_name}",
        extra={
            "operation_id": operation_id,
            "operation_name": operation_name,
            **context
        }
    )
    
    try:
        yield operation_id
        
        end_time = time.time()
        duration_ms = (end_time - start_time) * 1000
        
        # Record performance metric
        performance_metrics.record_timing(operation_name, duration_ms)
        
        logger.info(
            f"Completed timed operation: {operation_name}",
            extra={
                "operation_id": operation_id,
                "operation_name": operation_name,
                "duration_ms": round(duration_ms, 2),
                "success": True,
                **context
            }
        )
        
    except Exception as e:
        end_time = time.time()
        duration_ms = (end_time - start_time) * 1000
        
        # Record performance metric even for failed operations
        performance_metrics.record_timing(f"{operation_name}_failed", duration_ms)
        
        logger.error(
            f"Failed timed operation: {operation_name}",
            extra={
                "operation_id": operation_id,
                "operation_name": operation_name,
                "duration_ms": round(duration_ms, 2),
                "success": False,
                "error_type": type(e).__name__,
                "error_message": str(e),
                **context
            },
            exc_info=True
        )
        
        raise


def log_sensitive_operation(
    logger: logging.Logger,
    operation: str,
    sensitive_data: Dict[str, Any],
    safe_data: Optional[Dict[str, Any]] = None
):
    """
    Log operations involving sensitive data with appropriate masking.
    
    Args:
        logger: Logger instance
        operation: Operation description
        sensitive_data: Data that should be masked/truncated
        safe_data: Data that can be logged as-is
    """
    masked_data = {}
    
    for key, value in sensitive_data.items():
        if isinstance(value, str):
            if len(value) > 8:
                # Show first 4 and last 4 characters with masking in between
                masked_data[key] = f"{value[:4]}{'*' * (len(value) - 8)}{value[-4:]}"
            else:
                # For short strings, just show length
                masked_data[key] = f"<{len(value)} chars>"
        else:
            masked_data[key] = f"<{type(value).__name__}>"
    
    log_data = masked_data.copy()
    if safe_data:
        log_data.update(safe_data)
    
    logger.info(f"Sensitive operation: {operation}", extra=log_data)

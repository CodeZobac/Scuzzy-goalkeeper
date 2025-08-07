"""Utility functions and helpers."""

from .logging import (
    configure_logging,
    get_service_logger,
    OperationContext,
    performance_monitor,
    EmailServiceLoggerAdapter,
    performance_metrics,
    timed_operation,
    log_sensitive_operation
)

from .middleware import (
    LoggingMiddleware,
    HealthCheckMiddleware,
    ErrorTrackingMiddleware
)

from .metrics import (
    get_service_metrics,
    get_health_metrics,
    reset_all_metrics,
    MetricsReporter,
    metrics_collector
)

__all__ = [
    # Logging utilities
    "configure_logging",
    "get_service_logger",
    "OperationContext",
    "performance_monitor",
    "EmailServiceLoggerAdapter",
    "performance_metrics",
    "timed_operation",
    "log_sensitive_operation",
    
    # Middleware
    "LoggingMiddleware",
    "HealthCheckMiddleware",
    "ErrorTrackingMiddleware",
    
    # Metrics
    "get_service_metrics",
    "get_health_metrics",
    "reset_all_metrics",
    "MetricsReporter",
    "metrics_collector"
]

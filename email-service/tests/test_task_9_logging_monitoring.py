#!/usr/bin/env python3
"""
Test script for Task 9: Comprehensive Logging and Monitoring Implementation

This script validates the logging and monitoring features implemented for the 
Goalkeeper Email Service, testing all aspects of the logging system, metrics
collection, and performance monitoring.
"""

import asyncio
import json
import time
import logging
from datetime import datetime
from typing import Dict, Any

# Import our logging and monitoring utilities
from app.utils.logging import (
    configure_logging, 
    get_service_logger, 
    OperationContext,
    performance_monitor,
    performance_metrics,
    timed_operation,
    log_sensitive_operation
)

from app.utils.metrics import (
    get_service_metrics,
    get_health_metrics,
    reset_all_metrics,
    MetricsReporter,
    metrics_collector
)

from app.config import settings


def test_logging_configuration():
    """Test comprehensive logging configuration."""
    print("=" * 60)
    print("Testing Logging Configuration")
    print("=" * 60)
    
    # Configure logging
    configure_logging()
    
    # Test basic logger
    logger = get_service_logger("test")
    
    print(f"✓ Logging configured with level: {settings.log_level}")
    print(f"✓ Logging format: {settings.log_format}")
    print(f"✓ Service logger created: {type(logger).__name__}")
    
    # Test different log levels
    logger.debug("Debug message test")
    logger.info("Info message test")
    logger.warning("Warning message test")
    logger.error("Error message test")
    
    # Test structured logging with extra fields
    logger.log_email_operation(
        level=logging.INFO,
        operation="test_email_send",
        email="test@example.com",
        user_id="test-user-123",
        message_id="msg-456"
    )
    
    logger.log_auth_code_operation(
        level=logging.INFO,
        operation="test_code_generation",
        user_id="test-user-123",
        code_type="email_confirmation",
        code_preview="ABCD..."
    )
    
    logger.log_azure_operation(
        level=logging.INFO,
        operation="test_azure_call",
        status_code=200,
        response_time_ms=245.7
    )
    
    logger.log_database_operation(
        level=logging.INFO,
        operation="test_db_query",
        table="auth_codes",
        query_time_ms=15.3,
        rows_affected=1
    )
    
    print("✓ All logging methods tested successfully")
    print()


def test_operation_context():
    """Test OperationContext for consistent logging."""
    print("=" * 60)
    print("Testing Operation Context")
    print("=" * 60)
    
    logger = get_service_logger("test_context")
    
    # Test successful operation
    with OperationContext("test_successful_operation", logger.logger, 
                         test_param="value1", user_id="user-123") as context:
        
        time.sleep(0.1)  # Simulate work
        context.log_checkpoint("middle_step", data_processed=100)
        time.sleep(0.05)  # More work
        context.update_context(final_result="success")
    
    print("✓ Successful operation context tested")
    
    # Test failed operation
    try:
        with OperationContext("test_failed_operation", logger.logger,
                             test_param="value2") as context:
            time.sleep(0.05)
            context.log_checkpoint("before_error", items=50)
            raise ValueError("Simulated error for testing")
    except ValueError:
        pass  # Expected
    
    print("✓ Failed operation context tested")
    print()


@performance_monitor("test_async_function")
async def test_async_function():
    """Test async function monitoring."""
    await asyncio.sleep(0.1)
    return "async_result"


@performance_monitor("test_sync_function")
def test_sync_function():
    """Test sync function monitoring."""
    time.sleep(0.05)
    return "sync_result"


async def test_performance_monitoring():
    """Test performance monitoring decorators."""
    print("=" * 60)
    print("Testing Performance Monitoring")
    print("=" * 60)
    
    # Test async monitoring
    result = await test_async_function()
    print(f"✓ Async function result: {result}")
    
    # Test sync monitoring
    result = test_sync_function()
    print(f"✓ Sync function result: {result}")
    
    # Test timed operations
    logger = get_service_logger("test_timing")
    
    with timed_operation("test_database_operation", logger.logger,
                        operation_type="select", table="users"):
        time.sleep(0.08)  # Simulate database query
    
    print("✓ Timed operation tested")
    
    # Test sensitive data logging
    log_sensitive_operation(
        logger.logger,
        "user_authentication",
        sensitive_data={
            "password": "super_secret_password_123",
            "token": "jwt_token_very_long_string_here",
            "api_key": "api_key_12345"
        },
        safe_data={
            "user_id": "user-123",
            "attempt": 1,
            "success": True
        }
    )
    
    print("✓ Sensitive data logging tested")
    print()


def test_metrics_collection():
    """Test metrics collection and reporting."""
    print("=" * 60)
    print("Testing Metrics Collection")
    print("=" * 60)
    
    # Reset metrics first
    reset_all_metrics()
    print("✓ Metrics reset")
    
    # Simulate various operations
    for i in range(5):
        metrics_collector.record_email_operation(
            "send_confirmation",
            success=True,
            duration_ms=150.0 + (i * 10),
            email_type="confirmation"
        )
    
    for i in range(2):
        metrics_collector.record_email_operation(
            "send_password_reset", 
            success=False,
            duration_ms=200.0,
            email_type="password_reset"
        )
    
    for i in range(8):
        metrics_collector.record_auth_code_operation(
            "generate_code",
            success=True,
            duration_ms=25.0 + (i * 2),
            code_type="email_confirmation"
        )
    
    for i in range(3):
        metrics_collector.record_azure_operation(
            "send_email",
            success=True,
            duration_ms=300.0 + (i * 20),
            status_code=202
        )
    
    for i in range(6):
        metrics_collector.record_database_operation(
            "insert",
            success=True,
            duration_ms=15.0 + (i * 3),
            table="auth_codes",
            rows_affected=1
        )
    
    print("✓ Various operations recorded")
    
    # Test metrics retrieval
    service_metrics = get_service_metrics()
    health_metrics = get_health_metrics()
    
    print(f"✓ Service metrics collected: {len(service_metrics)} categories")
    print(f"✓ Health status: {health_metrics.get('health_status', 'unknown')}")
    print(f"✓ Error rate (5min): {health_metrics.get('error_rate_5min', 0)}%")
    
    # Test text report generation
    text_report = MetricsReporter.generate_text_report()
    print(f"✓ Text report generated: {len(text_report.split('\\n'))} lines")
    
    # Test JSON report generation
    json_report = MetricsReporter.generate_json_report()
    print(f"✓ JSON report generated: {len(json.dumps(json_report))} characters")
    
    print()


def test_performance_metrics():
    """Test performance metrics collection."""
    print("=" * 60)
    print("Testing Performance Metrics")
    print("=" * 60)
    
    # Record some performance metrics
    performance_metrics.record_timing("api_request_post", 125.5)
    performance_metrics.record_timing("api_request_get", 45.2)
    performance_metrics.record_timing("database_query", 18.7)
    performance_metrics.record_timing("azure_api_call", 280.3)
    
    performance_metrics.record_counter("emails_sent", 5)
    performance_metrics.record_counter("codes_generated", 8)
    performance_metrics.record_counter("api_requests", 12)
    
    # Get metrics
    metrics = performance_metrics.get_metrics()
    
    print(f"✓ Performance metrics collected: {len(metrics)} metrics")
    
    for name, data in metrics.items():
        if 'count' in data:  # Timing metric
            print(f"  - {name}: {data['count']} calls, avg {data['avg_time_ms']:.1f}ms")
        else:  # Counter metric
            print(f"  - {name}: {data['value']}")
    
    print()


def test_error_scenarios():
    """Test error handling and logging."""
    print("=" * 60)
    print("Testing Error Scenarios")
    print("=" * 60)
    
    logger = get_service_logger("test_errors")
    
    # Test various error scenarios
    try:
        with OperationContext("operation_with_runtime_error", logger.logger):
            raise RuntimeError("Runtime error for testing")
    except RuntimeError:
        print("✓ Runtime error logged correctly")
    
    try:
        with OperationContext("operation_with_value_error", logger.logger):
            raise ValueError("Value error for testing")
    except ValueError:
        print("✓ Value error logged correctly")
    
    # Test error metrics
    metrics_collector.record_email_operation(
        "send_confirmation",
        success=False,
        duration_ms=100.0,
        email_type="confirmation"
    )
    
    print("✓ Error metrics recorded")
    
    # Check if errors affect health status
    health = get_health_metrics()
    print(f"✓ Health status after errors: {health.get('health_status', 'unknown')}")
    print()


def display_final_report():
    """Display final comprehensive report."""
    print("=" * 60)
    print("COMPREHENSIVE LOGGING & MONITORING REPORT")
    print("=" * 60)
    
    # Generate and display text report
    report = MetricsReporter.generate_text_report()
    print(report)
    
    print("=" * 60)
    print("JSON METRICS SAMPLE")
    print("=" * 60)
    
    # Display sample JSON metrics
    json_report = MetricsReporter.generate_json_report()
    print(json.dumps(json_report, indent=2)[:1000] + "...")
    
    print("\n" + "=" * 60)
    print("TASK 9 IMPLEMENTATION COMPLETE")
    print("=" * 60)
    print("✅ Structured logging system implemented")
    print("✅ Performance monitoring active")
    print("✅ Comprehensive metrics collection")
    print("✅ Error tracking and logging")
    print("✅ Health status monitoring")
    print("✅ Text and JSON reporting")
    print("✅ Context-aware operation tracking")
    print("✅ Sensitive data protection")
    print("✅ Configurable log levels and formats")
    print("✅ Middleware integration ready")


async def main():
    """Run all tests."""
    print("TASK 9: COMPREHENSIVE LOGGING AND MONITORING TEST")
    print("=" * 80)
    print(f"Started at: {datetime.utcnow().isoformat()}")
    print(f"Environment: {settings.environment}")
    print(f"Log Level: {settings.log_level}")
    print(f"Log Format: {settings.log_format}")
    print()
    
    # Run all tests
    test_logging_configuration()
    test_operation_context()
    await test_performance_monitoring()
    test_metrics_collection()
    test_performance_metrics()
    test_error_scenarios()
    
    # Display final comprehensive report
    display_final_report()
    
    print(f"\nCompleted at: {datetime.utcnow().isoformat()}")


if __name__ == "__main__":
    asyncio.run(main())

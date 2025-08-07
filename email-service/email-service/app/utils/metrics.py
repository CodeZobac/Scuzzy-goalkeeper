"""
Performance metrics collection and reporting utilities.

This module provides functionality for collecting, aggregating, and exposing
performance metrics for monitoring and observability.
"""

import time
from datetime import datetime, timedelta
from typing import Any, Dict, List, Optional
from collections import defaultdict, deque

from app.utils.logging import performance_metrics


class MetricsCollector:
    """Enhanced metrics collector with time-series data and aggregations."""
    
    def __init__(self, retention_minutes: int = 60):
        """
        Initialize metrics collector.
        
        Args:
            retention_minutes: How long to keep detailed metrics data
        """
        self.retention_minutes = retention_minutes
        self.time_series_data = defaultdict(lambda: deque(maxlen=1000))
        self.aggregated_metrics = {}
        self.start_time = datetime.utcnow()
    
    def record_email_operation(
        self,
        operation_type: str,
        success: bool,
        duration_ms: float,
        email_type: Optional[str] = None
    ):
        """Record email operation metrics."""
        timestamp = time.time()
        
        metric_data = {
            'timestamp': timestamp,
            'operation_type': operation_type,
            'success': success,
            'duration_ms': duration_ms,
            'email_type': email_type
        }
        
        self.time_series_data['email_operations'].append(metric_data)
        
        # Update aggregated metrics
        key = f"email_{operation_type}_{'success' if success else 'failure'}"
        if key not in self.aggregated_metrics:
            self.aggregated_metrics[key] = {
                'count': 0,
                'total_duration_ms': 0,
                'avg_duration_ms': 0,
                'min_duration_ms': float('inf'),
                'max_duration_ms': 0
            }
        
        metrics = self.aggregated_metrics[key]
        metrics['count'] += 1
        metrics['total_duration_ms'] += duration_ms
        metrics['avg_duration_ms'] = metrics['total_duration_ms'] / metrics['count']
        metrics['min_duration_ms'] = min(metrics['min_duration_ms'], duration_ms)
        metrics['max_duration_ms'] = max(metrics['max_duration_ms'], duration_ms)
    
    def record_auth_code_operation(
        self,
        operation_type: str,
        success: bool,
        duration_ms: float,
        code_type: Optional[str] = None
    ):
        """Record authentication code operation metrics."""
        timestamp = time.time()
        
        metric_data = {
            'timestamp': timestamp,
            'operation_type': operation_type,
            'success': success,
            'duration_ms': duration_ms,
            'code_type': code_type
        }
        
        self.time_series_data['auth_code_operations'].append(metric_data)
        
        # Update aggregated metrics
        key = f"auth_code_{operation_type}_{'success' if success else 'failure'}"
        if key not in self.aggregated_metrics:
            self.aggregated_metrics[key] = {
                'count': 0,
                'total_duration_ms': 0,
                'avg_duration_ms': 0,
                'min_duration_ms': float('inf'),
                'max_duration_ms': 0
            }
        
        metrics = self.aggregated_metrics[key]
        metrics['count'] += 1
        metrics['total_duration_ms'] += duration_ms
        metrics['avg_duration_ms'] = metrics['total_duration_ms'] / metrics['count']
        metrics['min_duration_ms'] = min(metrics['min_duration_ms'], duration_ms)
        metrics['max_duration_ms'] = max(metrics['max_duration_ms'], duration_ms)
    
    def record_azure_operation(
        self,
        operation_type: str,
        success: bool,
        duration_ms: float,
        status_code: Optional[int] = None
    ):
        """Record Azure Communication Services operation metrics."""
        timestamp = time.time()
        
        metric_data = {
            'timestamp': timestamp,
            'operation_type': operation_type,
            'success': success,
            'duration_ms': duration_ms,
            'status_code': status_code
        }
        
        self.time_series_data['azure_operations'].append(metric_data)
        
        # Update aggregated metrics
        key = f"azure_{operation_type}_{'success' if success else 'failure'}"
        if key not in self.aggregated_metrics:
            self.aggregated_metrics[key] = {
                'count': 0,
                'total_duration_ms': 0,
                'avg_duration_ms': 0,
                'min_duration_ms': float('inf'),
                'max_duration_ms': 0
            }
        
        metrics = self.aggregated_metrics[key]
        metrics['count'] += 1
        metrics['total_duration_ms'] += duration_ms
        metrics['avg_duration_ms'] = metrics['total_duration_ms'] / metrics['count']
        metrics['min_duration_ms'] = min(metrics['min_duration_ms'], duration_ms)
        metrics['max_duration_ms'] = max(metrics['max_duration_ms'], duration_ms)
    
    def record_database_operation(
        self,
        operation_type: str,
        success: bool,
        duration_ms: float,
        table: Optional[str] = None,
        rows_affected: Optional[int] = None
    ):
        """Record database operation metrics."""
        timestamp = time.time()
        
        metric_data = {
            'timestamp': timestamp,
            'operation_type': operation_type,
            'success': success,
            'duration_ms': duration_ms,
            'table': table,
            'rows_affected': rows_affected
        }
        
        self.time_series_data['database_operations'].append(metric_data)
        
        # Update aggregated metrics
        key = f"database_{operation_type}_{'success' if success else 'failure'}"
        if key not in self.aggregated_metrics:
            self.aggregated_metrics[key] = {
                'count': 0,
                'total_duration_ms': 0,
                'avg_duration_ms': 0,
                'min_duration_ms': float('inf'),
                'max_duration_ms': 0
            }
        
        metrics = self.aggregated_metrics[key]
        metrics['count'] += 1
        metrics['total_duration_ms'] += duration_ms
        metrics['avg_duration_ms'] = metrics['total_duration_ms'] / metrics['count']
        metrics['min_duration_ms'] = min(metrics['min_duration_ms'], duration_ms)
        metrics['max_duration_ms'] = max(metrics['max_duration_ms'], duration_ms)
    
    def get_summary_metrics(self) -> Dict[str, Any]:
        """Get summary metrics for the last hour."""
        now = time.time()
        cutoff_time = now - (self.retention_minutes * 60)
        
        summary = {
            'collection_start_time': self.start_time.isoformat(),
            'collection_duration_minutes': (datetime.utcnow() - self.start_time).total_seconds() / 60,
            'retention_minutes': self.retention_minutes,
            'email_operations': self._summarize_operations('email_operations', cutoff_time),
            'auth_code_operations': self._summarize_operations('auth_code_operations', cutoff_time),
            'azure_operations': self._summarize_operations('azure_operations', cutoff_time),
            'database_operations': self._summarize_operations('database_operations', cutoff_time),
            'aggregated_metrics': self.aggregated_metrics,
            'performance_metrics': performance_metrics.get_metrics()
        }
        
        return summary
    
    def _summarize_operations(self, operation_category: str, cutoff_time: float) -> Dict[str, Any]:
        """Summarize operations for a specific category within the retention window."""
        operations = [
            op for op in self.time_series_data[operation_category]
            if op['timestamp'] >= cutoff_time
        ]
        
        if not operations:
            return {
                'total_count': 0,
                'success_count': 0,
                'failure_count': 0,
                'success_rate': 0.0,
                'avg_duration_ms': 0.0,
                'min_duration_ms': 0.0,
                'max_duration_ms': 0.0
            }
        
        success_ops = [op for op in operations if op['success']]
        failure_ops = [op for op in operations if not op['success']]
        durations = [op['duration_ms'] for op in operations]
        
        return {
            'total_count': len(operations),
            'success_count': len(success_ops),
            'failure_count': len(failure_ops),
            'success_rate': len(success_ops) / len(operations) * 100 if operations else 0,
            'avg_duration_ms': sum(durations) / len(durations) if durations else 0,
            'min_duration_ms': min(durations) if durations else 0,
            'max_duration_ms': max(durations) if durations else 0,
            'recent_operations': operations[-10:]  # Last 10 operations
        }
    
    def get_health_metrics(self) -> Dict[str, Any]:
        """Get health-related metrics for monitoring."""
        now = time.time()
        cutoff_time = now - (5 * 60)  # Last 5 minutes
        
        # Get recent failures
        recent_failures = []
        for category in self.time_series_data:
            failures = [
                op for op in self.time_series_data[category]
                if op['timestamp'] >= cutoff_time and not op['success']
            ]
            recent_failures.extend(failures)
        
        # Calculate error rates
        total_recent_ops = 0
        total_recent_failures = len(recent_failures)
        
        for category in self.time_series_data:
            total_recent_ops += len([
                op for op in self.time_series_data[category]
                if op['timestamp'] >= cutoff_time
            ])
        
        error_rate = (total_recent_failures / total_recent_ops * 100) if total_recent_ops > 0 else 0
        
        # Determine health status
        if error_rate > 10:
            health_status = "unhealthy"
        elif error_rate > 5:
            health_status = "degraded"
        else:
            health_status = "healthy"
        
        return {
            'health_status': health_status,
            'error_rate_5min': round(error_rate, 2),
            'total_operations_5min': total_recent_ops,
            'total_failures_5min': total_recent_failures,
            'recent_failures': recent_failures[-5:],  # Last 5 failures
            'uptime_minutes': (datetime.utcnow() - self.start_time).total_seconds() / 60
        }
    
    def cleanup_old_data(self):
        """Clean up old time-series data to prevent memory growth."""
        now = time.time()
        cutoff_time = now - (self.retention_minutes * 60)
        
        for category in self.time_series_data:
            # Remove old entries
            while (self.time_series_data[category] and 
                   self.time_series_data[category][0]['timestamp'] < cutoff_time):
                self.time_series_data[category].popleft()
    
    def reset_metrics(self):
        """Reset all metrics data."""
        self.time_series_data.clear()
        self.aggregated_metrics.clear()
        self.start_time = datetime.utcnow()
        performance_metrics.reset()


# Global metrics collector instance
metrics_collector = MetricsCollector()


def get_service_metrics() -> Dict[str, Any]:
    """Get comprehensive service metrics."""
    # Clean up old data before generating report
    metrics_collector.cleanup_old_data()
    
    return metrics_collector.get_summary_metrics()


def get_health_metrics() -> Dict[str, Any]:
    """Get health-specific metrics for monitoring."""
    return metrics_collector.get_health_metrics()


def reset_all_metrics():
    """Reset all collected metrics."""
    metrics_collector.reset_metrics()


class MetricsReporter:
    """Utility for generating formatted metrics reports."""
    
    @staticmethod
    def generate_text_report() -> str:
        """Generate a human-readable text report of current metrics."""
        metrics = get_service_metrics()
        health = get_health_metrics()
        
        report = []
        report.append("=== Goalkeeper Email Service Metrics Report ===")
        report.append(f"Generated at: {datetime.utcnow().isoformat()}")
        report.append(f"Collection started: {metrics['collection_start_time']}")
        report.append(f"Collection duration: {metrics['collection_duration_minutes']:.1f} minutes")
        report.append("")
        
        # Health status
        report.append("=== Health Status ===")
        report.append(f"Status: {health['health_status'].upper()}")
        report.append(f"Error rate (5min): {health['error_rate_5min']}%")
        report.append(f"Total operations (5min): {health['total_operations_5min']}")
        report.append(f"Total failures (5min): {health['total_failures_5min']}")
        report.append(f"Uptime: {health['uptime_minutes']:.1f} minutes")
        report.append("")
        
        # Email operations
        email_ops = metrics['email_operations']
        if email_ops['total_count'] > 0:
            report.append("=== Email Operations ===")
            report.append(f"Total: {email_ops['total_count']}")
            report.append(f"Success: {email_ops['success_count']} ({email_ops['success_rate']:.1f}%)")
            report.append(f"Failures: {email_ops['failure_count']}")
            report.append(f"Avg duration: {email_ops['avg_duration_ms']:.2f}ms")
            report.append(f"Duration range: {email_ops['min_duration_ms']:.2f}ms - {email_ops['max_duration_ms']:.2f}ms")
            report.append("")
        
        # Auth code operations
        auth_ops = metrics['auth_code_operations']
        if auth_ops['total_count'] > 0:
            report.append("=== Authentication Code Operations ===")
            report.append(f"Total: {auth_ops['total_count']}")
            report.append(f"Success: {auth_ops['success_count']} ({auth_ops['success_rate']:.1f}%)")
            report.append(f"Failures: {auth_ops['failure_count']}")
            report.append(f"Avg duration: {auth_ops['avg_duration_ms']:.2f}ms")
            report.append("")
        
        # Azure operations
        azure_ops = metrics['azure_operations']
        if azure_ops['total_count'] > 0:
            report.append("=== Azure Communication Services Operations ===")
            report.append(f"Total: {azure_ops['total_count']}")
            report.append(f"Success: {azure_ops['success_count']} ({azure_ops['success_rate']:.1f}%)")
            report.append(f"Failures: {azure_ops['failure_count']}")
            report.append(f"Avg duration: {azure_ops['avg_duration_ms']:.2f}ms")
            report.append("")
        
        # Database operations
        db_ops = metrics['database_operations']
        if db_ops['total_count'] > 0:
            report.append("=== Database Operations ===")
            report.append(f"Total: {db_ops['total_count']}")
            report.append(f"Success: {db_ops['success_count']} ({db_ops['success_rate']:.1f}%)")
            report.append(f"Failures: {db_ops['failure_count']}")
            report.append(f"Avg duration: {db_ops['avg_duration_ms']:.2f}ms")
            report.append("")
        
        # Recent failures
        if health['recent_failures']:
            report.append("=== Recent Failures ===")
            for failure in health['recent_failures']:
                report.append(f"- {failure['operation_type']} failed ({failure.get('error_type', 'Unknown error')})")
            report.append("")
        
        return "\n".join(report)
    
    @staticmethod
    def generate_json_report() -> Dict[str, Any]:
        """Generate a JSON report of current metrics."""
        return {
            'generated_at': datetime.utcnow().isoformat(),
            'service_metrics': get_service_metrics(),
            'health_metrics': get_health_metrics()
        }

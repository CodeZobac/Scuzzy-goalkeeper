import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../logging/error_logger.dart';

/// Service for monitoring application health and error patterns
class ErrorMonitoringService {
  static final ErrorMonitoringService _instance = ErrorMonitoringService._internal();
  factory ErrorMonitoringService() => _instance;
  ErrorMonitoringService._internal();

  static ErrorMonitoringService get instance => _instance;

  final Map<String, int> _errorCounts = {};
  final Map<String, DateTime> _lastErrorTimes = {};
  final List<String> _criticalErrors = [];
  
  bool _isInitialized = false;
  Timer? _healthCheckTimer;
  
  static const Duration _healthCheckInterval = Duration(minutes: 5);
  static const int _criticalErrorThreshold = 5;
  static const Duration _errorTimeWindow = Duration(minutes: 10);

  /// Initialize the error monitoring service
  Future<void> initialize() async {
    if (_isInitialized) return;

    _isInitialized = true;
    _startHealthChecks();
    
    ErrorLogger.logInfo(
      'Error monitoring service initialized',
      context: 'ERROR_MONITORING',
    );
  }

  /// Dispose of the service
  void dispose() {
    _healthCheckTimer?.cancel();
    _isInitialized = false;
  }

  /// Report an error to the monitoring service
  void reportError(String errorType, {
    String? context,
    Map<String, dynamic>? metadata,
    ErrorSeverity severity = ErrorSeverity.error,
  }) {
    final now = DateTime.now();
    final key = '${context ?? 'unknown'}_$errorType';
    
    // Update error counts
    _errorCounts[key] = (_errorCounts[key] ?? 0) + 1;
    _lastErrorTimes[key] = now;
    
    // Check for critical error patterns
    if (_isCriticalError(key, severity)) {
      _handleCriticalError(key, errorType, context);
    }
    
    // Log the error
    ErrorLogger.logError(
      'Error reported to monitoring: $errorType',
      StackTrace.current,
      context: context ?? 'ERROR_MONITORING',
      additionalData: {
        'error_type': errorType,
        'error_count': _errorCounts[key],
        'severity': severity.toString(),
        ...?metadata,
      },
      severity: severity,
    );
  }

  /// Get current error statistics
  ErrorMonitoringStats getStats() {
    final now = DateTime.now();
    final recentErrors = <String, int>{};
    
    // Filter recent errors (within time window)
    for (final entry in _errorCounts.entries) {
      final lastTime = _lastErrorTimes[entry.key];
      if (lastTime != null && now.difference(lastTime) <= _errorTimeWindow) {
        recentErrors[entry.key] = entry.value;
      }
    }
    
    return ErrorMonitoringStats(
      totalErrors: _errorCounts.values.fold(0, (sum, count) => sum + count),
      recentErrors: recentErrors,
      criticalErrors: List.from(_criticalErrors),
      healthStatus: _getHealthStatus(),
    );
  }

  /// Check if the application is in a healthy state
  ApplicationHealthStatus _getHealthStatus() {
    final stats = ErrorLogger.getStatistics();
    
    // Check for high error rates
    if (stats.errorsLastHour > 20) {
      return ApplicationHealthStatus.critical;
    } else if (stats.errorsLastHour > 10) {
      return ApplicationHealthStatus.warning;
    } else if (_criticalErrors.isNotEmpty) {
      return ApplicationHealthStatus.warning;
    }
    
    return ApplicationHealthStatus.healthy;
  }

  /// Check if an error should be considered critical
  bool _isCriticalError(String key, ErrorSeverity severity) {
    if (severity == ErrorSeverity.error) {
      final count = _errorCounts[key] ?? 0;
      return count >= _criticalErrorThreshold;
    }
    return false;
  }

  /// Handle critical error situations
  void _handleCriticalError(String key, String errorType, String? context) {
    if (!_criticalErrors.contains(key)) {
      _criticalErrors.add(key);
      
      ErrorLogger.logError(
        'Critical error pattern detected: $errorType',
        StackTrace.current,
        context: 'CRITICAL_ERROR_MONITORING',
        additionalData: {
          'error_key': key,
          'error_count': _errorCounts[key],
          'context': context,
        },
      );
      
      // In production, you might want to:
      // - Send alerts to monitoring services
      // - Trigger automatic recovery procedures
      // - Notify development team
    }
  }

  /// Start periodic health checks
  void _startHealthChecks() {
    _healthCheckTimer = Timer.periodic(_healthCheckInterval, (_) {
      _performHealthCheck();
    });
  }

  /// Perform a health check
  void _performHealthCheck() {
    final stats = getStats();
    
    ErrorLogger.logInfo(
      'Health check completed',
      context: 'HEALTH_CHECK',
      additionalData: {
        'total_errors': stats.totalErrors,
        'recent_errors_count': stats.recentErrors.length,
        'critical_errors_count': stats.criticalErrors.length,
        'health_status': stats.healthStatus.toString(),
      },
    );
    
    // Clean up old error data
    _cleanupOldErrors();
  }

  /// Clean up error data older than the time window
  void _cleanupOldErrors() {
    final now = DateTime.now();
    final keysToRemove = <String>[];
    
    for (final entry in _lastErrorTimes.entries) {
      if (now.difference(entry.value) > _errorTimeWindow * 2) {
        keysToRemove.add(entry.key);
      }
    }
    
    for (final key in keysToRemove) {
      _errorCounts.remove(key);
      _lastErrorTimes.remove(key);
      _criticalErrors.remove(key);
    }
  }

  /// Reset all monitoring data
  void reset() {
    _errorCounts.clear();
    _lastErrorTimes.clear();
    _criticalErrors.clear();
    
    ErrorLogger.logInfo(
      'Error monitoring data reset',
      context: 'ERROR_MONITORING',
    );
  }
}

/// Statistics from error monitoring
class ErrorMonitoringStats {
  final int totalErrors;
  final Map<String, int> recentErrors;
  final List<String> criticalErrors;
  final ApplicationHealthStatus healthStatus;

  const ErrorMonitoringStats({
    required this.totalErrors,
    required this.recentErrors,
    required this.criticalErrors,
    required this.healthStatus,
  });

  @override
  String toString() {
    return 'ErrorMonitoringStats(total: $totalErrors, recent: ${recentErrors.length}, critical: ${criticalErrors.length}, health: $healthStatus)';
  }
}

/// Application health status levels
enum ApplicationHealthStatus {
  healthy,
  warning,
  critical,
}

/// Widget that displays error monitoring information (for debugging)
class ErrorMonitoringWidget extends StatefulWidget {
  final bool showInProduction;

  const ErrorMonitoringWidget({
    super.key,
    this.showInProduction = false,
  });

  @override
  State<ErrorMonitoringWidget> createState() => _ErrorMonitoringWidgetState();
}

class _ErrorMonitoringWidgetState extends State<ErrorMonitoringWidget> {
  Timer? _updateTimer;

  @override
  void initState() {
    super.initState();
    if (kDebugMode || widget.showInProduction) {
      _updateTimer = Timer.periodic(const Duration(seconds: 5), (_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (kReleaseMode && !widget.showInProduction) {
      return const SizedBox.shrink();
    }

    final stats = ErrorMonitoringService.instance.getStats();
    
    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _getHealthColor(stats.healthStatus).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _getHealthColor(stats.healthStatus),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                _getHealthIcon(stats.healthStatus),
                color: _getHealthColor(stats.healthStatus),
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                'App Health: ${stats.healthStatus.name.toUpperCase()}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _getHealthColor(stats.healthStatus),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Total Errors: ${stats.totalErrors}',
            style: const TextStyle(fontSize: 10),
          ),
          Text(
            'Recent Errors: ${stats.recentErrors.length}',
            style: const TextStyle(fontSize: 10),
          ),
          Text(
            'Critical Errors: ${stats.criticalErrors.length}',
            style: const TextStyle(fontSize: 10),
          ),
        ],
      ),
    );
  }

  Color _getHealthColor(ApplicationHealthStatus status) {
    switch (status) {
      case ApplicationHealthStatus.healthy:
        return Colors.green;
      case ApplicationHealthStatus.warning:
        return Colors.orange;
      case ApplicationHealthStatus.critical:
        return Colors.red;
    }
  }

  IconData _getHealthIcon(ApplicationHealthStatus status) {
    switch (status) {
      case ApplicationHealthStatus.healthy:
        return Icons.check_circle;
      case ApplicationHealthStatus.warning:
        return Icons.warning;
      case ApplicationHealthStatus.critical:
        return Icons.error;
    }
  }
}
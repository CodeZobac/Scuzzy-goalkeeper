import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Centralized error logging service that handles error reporting
/// without exposing sensitive information
class ErrorLogger {
  static final List<ErrorLogEntry> _errorLog = [];
  static const int _maxLogEntries = 100;

  /// Log an error with context and additional data
  static void logError(
    Object error,
    StackTrace stackTrace, {
    String? context,
    Map<String, dynamic>? additionalData,
    ErrorSeverity severity = ErrorSeverity.error,
  }) {
    final sanitizedError = _sanitizeError(error);
    final sanitizedData = _sanitizeAdditionalData(additionalData);
    
    final logEntry = ErrorLogEntry(
      error: sanitizedError,
      stackTrace: stackTrace,
      context: context,
      additionalData: sanitizedData,
      severity: severity,
      timestamp: DateTime.now(),
    );

    _addToLog(logEntry);
    _printError(logEntry);
    
    // In production, you would send this to your error reporting service
    if (kReleaseMode) {
      _reportToService(logEntry);
    }
  }

  /// Log a warning
  static void logWarning(
    String message, {
    String? context,
    Map<String, dynamic>? additionalData,
  }) {
    logError(
      message,
      StackTrace.current,
      context: context,
      additionalData: additionalData,
      severity: ErrorSeverity.warning,
    );
  }

  /// Log an info message
  static void logInfo(
    String message, {
    String? context,
    Map<String, dynamic>? additionalData,
  }) {
    logError(
      message,
      StackTrace.current,
      context: context,
      additionalData: additionalData,
      severity: ErrorSeverity.info,
    );
  }

  /// Get recent error logs (for debugging purposes)
  static List<ErrorLogEntry> getRecentLogs({int? limit}) {
    final logs = List<ErrorLogEntry>.from(_errorLog);
    if (limit != null && limit < logs.length) {
      return logs.take(limit).toList();
    }
    return logs;
  }

  /// Clear error logs
  static void clearLogs() {
    _errorLog.clear();
  }

  /// Get error statistics
  static ErrorStatistics getStatistics() {
    final now = DateTime.now();
    final last24Hours = now.subtract(const Duration(hours: 24));
    final lastHour = now.subtract(const Duration(hours: 1));

    final last24HoursErrors = _errorLog
        .where((entry) => entry.timestamp.isAfter(last24Hours))
        .length;
    
    final lastHourErrors = _errorLog
        .where((entry) => entry.timestamp.isAfter(lastHour))
        .length;

    final errorsByContext = <String, int>{};
    for (final entry in _errorLog) {
      final context = entry.context ?? 'unknown';
      errorsByContext[context] = (errorsByContext[context] ?? 0) + 1;
    }

    return ErrorStatistics(
      totalErrors: _errorLog.length,
      errorsLast24Hours: last24HoursErrors,
      errorsLastHour: lastHourErrors,
      errorsByContext: errorsByContext,
    );
  }

  static void _addToLog(ErrorLogEntry entry) {
    _errorLog.insert(0, entry); // Add to beginning for chronological order
    
    // Keep only the most recent entries
    if (_errorLog.length > _maxLogEntries) {
      _errorLog.removeRange(_maxLogEntries, _errorLog.length);
    }
  }

  static void _printError(ErrorLogEntry entry) {
    final severityIcon = _getSeverityIcon(entry.severity);
    final contextStr = entry.context != null ? '[${entry.context}] ' : '';
    
    debugPrint('$severityIcon $contextStr${entry.error}');
    
    if (entry.additionalData?.isNotEmpty == true) {
      debugPrint('Additional data: ${entry.additionalData}');
    }
    
    // Only print stack trace for errors and warnings in debug mode
    if (kDebugMode && entry.severity != ErrorSeverity.info) {
      debugPrint('Stack trace: ${entry.stackTrace}');
    }
  }

  static String _getSeverityIcon(ErrorSeverity severity) {
    switch (severity) {
      case ErrorSeverity.error:
        return '❌';
      case ErrorSeverity.warning:
        return '⚠️';
      case ErrorSeverity.info:
        return 'ℹ️';
    }
  }

  /// Sanitize error object to remove sensitive information
  static Object _sanitizeError(Object error) {
    final errorString = error.toString();
    
    // Remove common sensitive patterns
    String sanitized = errorString
        .replaceAll(RegExp(r'password[=:]\s*[^\s,}]+', caseSensitive: false), 'password=***')
        .replaceAll(RegExp(r'token[=:]\s*[^\s,}]+', caseSensitive: false), 'token=***')
        .replaceAll(RegExp(r'key[=:]\s*[^\s,}]+', caseSensitive: false), 'key=***')
        .replaceAll(RegExp(r'secret[=:]\s*[^\s,}]+', caseSensitive: false), 'secret=***')
        .replaceAll(RegExp(r'email[=:]\s*[^\s,}]+@[^\s,}]+', caseSensitive: false), 'email=***@***.***');
    
    return sanitized;
  }

  /// Sanitize additional data to remove sensitive information
  static Map<String, dynamic>? _sanitizeAdditionalData(Map<String, dynamic>? data) {
    if (data == null) return null;
    
    final sanitized = <String, dynamic>{};
    
    for (final entry in data.entries) {
      final key = entry.key.toLowerCase();
      final value = entry.value;
      
      // Skip sensitive keys
      if (_isSensitiveKey(key)) {
        sanitized[entry.key] = '***';
      } else if (value is String && _containsSensitiveData(value)) {
        sanitized[entry.key] = _sanitizeString(value);
      } else {
        sanitized[entry.key] = value;
      }
    }
    
    return sanitized;
  }

  static bool _isSensitiveKey(String key) {
    const sensitiveKeys = [
      'password',
      'token',
      'key',
      'secret',
      'auth',
      'credential',
      'session',
    ];
    
    return sensitiveKeys.any((sensitive) => key.contains(sensitive));
  }

  static bool _containsSensitiveData(String value) {
    // Check for email patterns, tokens, etc.
    return RegExp(r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}').hasMatch(value) ||
           value.length > 50; // Assume very long strings might be tokens
  }

  static String _sanitizeString(String value) {
    return value
        .replaceAll(RegExp(r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}'), '***@***.***')
        .replaceAll(RegExp(r'[a-zA-Z0-9]{20,}'), '***'); // Replace long alphanumeric strings
  }

  /// Report error to external service (placeholder for production implementation)
  static void _reportToService(ErrorLogEntry entry) {
    // In a real app, you would send this to your error reporting service
    // like Sentry, Crashlytics, or a custom service
    debugPrint('Would report to error service: ${entry.error}');
  }
}

/// Represents a logged error entry
class ErrorLogEntry {
  final Object error;
  final StackTrace stackTrace;
  final String? context;
  final Map<String, dynamic>? additionalData;
  final ErrorSeverity severity;
  final DateTime timestamp;

  const ErrorLogEntry({
    required this.error,
    required this.stackTrace,
    this.context,
    this.additionalData,
    required this.severity,
    required this.timestamp,
  });

  @override
  String toString() {
    return 'ErrorLogEntry(error: $error, context: $context, severity: $severity, timestamp: $timestamp)';
  }
}

/// Error severity levels
enum ErrorSeverity {
  error,
  warning,
  info,
}

/// Error statistics for monitoring
class ErrorStatistics {
  final int totalErrors;
  final int errorsLast24Hours;
  final int errorsLastHour;
  final Map<String, int> errorsByContext;

  const ErrorStatistics({
    required this.totalErrors,
    required this.errorsLast24Hours,
    required this.errorsLastHour,
    required this.errorsByContext,
  });

  @override
  String toString() {
    return 'ErrorStatistics(total: $totalErrors, last24h: $errorsLast24Hours, lastHour: $errorsLastHour)';
  }
}
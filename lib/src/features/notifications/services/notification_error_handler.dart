import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/models/notification_error.dart';

/// Centralized error handler for the notifications system
/// Provides error classification, recovery strategies, and logging
class NotificationErrorHandler {
  static NotificationErrorHandler? _instance;
  static NotificationErrorHandler get instance => _instance ??= NotificationErrorHandler._();
  
  NotificationErrorHandler._();

  // Error tracking and statistics
  final List<NotificationError> _errorHistory = [];
  final Map<NotificationErrorType, int> _errorCounts = {};
  final Map<String, int> _operationRetryCount = {};
  
  // Configuration
  static const int maxRetryAttempts = 3;
  static const int maxErrorHistorySize = 100;
  static const Duration errorReportingThrottle = Duration(minutes: 5);
  
  // Error reporting throttling
  final Map<String, DateTime> _lastErrorReported = {};

  /// Handle an exception and convert it to a NotificationError
  NotificationError handleException(
    Exception exception, {
    String? operationId,
    Map<String, dynamic>? context,
    StackTrace? stackTrace,
  }) {
    final error = _classifyException(
      exception,
      operationId: operationId,
      context: context,
      stackTrace: stackTrace,
    );
    
    _recordError(error);
    _logError(error);
    
    return error;
  }

  /// Handle an error and determine recovery strategy
  Future<NotificationResult<T>> handleError<T>(
    NotificationError error, {
    Future<T> Function()? retryOperation,
    T? fallbackValue,
  }) async {
    _recordError(error);
    _logError(error);

    // Check if we should retry
    if (error.shouldRetry && retryOperation != null) {
      final retryCount = _getRetryCount(error.operationId);
      
      if (retryCount < maxRetryAttempts) {
        _incrementRetryCount(error.operationId);
        
        // Wait before retrying if needed
        if (error.recoveryStrategy == NotificationErrorRecoveryStrategy.retryWithDelay) {
          await Future.delayed(error.retryDelay);
        }
        
        try {
          final result = await retryOperation();
          _resetRetryCount(error.operationId);
          return NotificationResult.success(result);
        } catch (e, stackTrace) {
          final retryError = handleException(
            e is Exception ? e : Exception(e.toString()),
            operationId: error.operationId,
            context: error.context,
            stackTrace: stackTrace,
          );
          
          // If max retries reached, escalate
          if (_getRetryCount(error.operationId) >= maxRetryAttempts) {
            return NotificationResult.failure(
              NotificationError(
                type: retryError.type,
                severity: NotificationErrorSeverity.high,
                message: 'Max retry attempts reached: ${retryError.message}',
                userMessage: 'Operação falhou após várias tentativas.',
                technicalDetails: 'Retries: ${_getRetryCount(error.operationId)}',
                context: retryError.context,
                recoveryStrategy: NotificationErrorRecoveryStrategy.escalate,
                operationId: error.operationId,
                originalException: retryError.originalException,
              ),
            );
          }
          
          return NotificationResult.failure(retryError);
        }
      }
    }

    // Use fallback if available
    if (error.recoveryStrategy == NotificationErrorRecoveryStrategy.fallback && fallbackValue != null) {
      return NotificationResult.success(fallbackValue);
    }

    // Escalate critical errors
    if (error.shouldEscalate) {
      _escalateError(error);
    }

    return NotificationResult.failure(error);
  }

  /// Classify an exception into a NotificationError
  NotificationError _classifyException(
    Exception exception, {
    String? operationId,
    Map<String, dynamic>? context,
    StackTrace? stackTrace,
  }) {
    // Firebase exceptions
    if (exception is FirebaseException) {
      return _handleFirebaseException(exception, operationId, context, stackTrace);
    }

    // Supabase exceptions
    if (exception is PostgrestException) {
      return _handleSupabaseException(exception, operationId, context, stackTrace);
    }

    // Socket exceptions (network errors)
    if (exception is SocketException) {
      return NotificationError.network(
        message: 'Network connection failed: ${exception.message}',
        technicalDetails: exception.toString(),
        context: context,
        stackTrace: stackTrace,
        originalException: exception,
      );
    }

    // Timeout exceptions
    if (exception is TimeoutException) {
      return NotificationError(
        type: NotificationErrorType.connectionTimeout,
        severity: NotificationErrorSeverity.medium,
        message: 'Operation timed out: ${exception.message}',
        userMessage: 'Operação demorou muito. Tente novamente.',
        technicalDetails: exception.toString(),
        context: context,
        stackTrace: stackTrace,
        recoveryStrategy: NotificationErrorRecoveryStrategy.retryWithDelay,
        operationId: operationId,
        originalException: exception,
      );
    }

    // Format exceptions (data corruption)
    if (exception is FormatException) {
      return NotificationError(
        type: NotificationErrorType.dataCorruption,
        severity: NotificationErrorSeverity.medium,
        message: 'Data format error: ${exception.message}',
        userMessage: 'Dados corrompidos detectados.',
        technicalDetails: exception.toString(),
        context: context,
        stackTrace: stackTrace,
        recoveryStrategy: NotificationErrorRecoveryStrategy.fallback,
        operationId: operationId,
        originalException: exception,
      );
    }

    // State errors (service not initialized)
    if (exception is StateError) {
      return NotificationError.serviceInitialization(
        message: 'Service state error: ${exception.toString()}',
        technicalDetails: exception.toString(),
        context: context,
        stackTrace: stackTrace,
        originalException: exception,
      );
    }

    // Argument errors (validation)
    if (exception is ArgumentError) {
      return NotificationError.validation(
        message: 'Invalid argument: ${exception.toString()}',
        technicalDetails: exception.toString(),
        context: context,
        stackTrace: stackTrace,
        originalException: exception,
      );
    }

    // Default to unknown error
    return NotificationError.unknown(
      message: 'Unhandled exception: ${exception.toString()}',
      technicalDetails: exception.toString(),
      context: context,
      stackTrace: stackTrace,
      originalException: exception,
    );
  }

  /// Handle Firebase-specific exceptions
  NotificationError _handleFirebaseException(
    FirebaseException exception,
    String? operationId,
    Map<String, dynamic>? context,
    StackTrace? stackTrace,
  ) {
    switch (exception.code) {
      case 'permission-denied':
        return NotificationError.permission(
          message: 'Firebase permission denied: ${exception.message}',
          userMessage: 'Permissão negada para notificações.',
          technicalDetails: exception.toString(),
          context: context,
          stackTrace: stackTrace,
          originalException: exception,
        );
      
      case 'unavailable':
        return NotificationError(
          type: NotificationErrorType.serviceUnavailable,
          severity: NotificationErrorSeverity.high,
          message: 'Firebase service unavailable: ${exception.message}',
          userMessage: 'Serviço temporariamente indisponível.',
          technicalDetails: exception.toString(),
          context: context,
          stackTrace: stackTrace,
          recoveryStrategy: NotificationErrorRecoveryStrategy.retryWithDelay,
          operationId: operationId,
          originalException: exception,
        );
      
      case 'quota-exceeded':
        return NotificationError(
          type: NotificationErrorType.rateLimitExceeded,
          severity: NotificationErrorSeverity.medium,
          message: 'Firebase quota exceeded: ${exception.message}',
          userMessage: 'Limite de uso excedido. Tente mais tarde.',
          technicalDetails: exception.toString(),
          context: context,
          stackTrace: stackTrace,
          recoveryStrategy: NotificationErrorRecoveryStrategy.retryWithDelay,
          operationId: operationId,
          originalException: exception,
        );
      
      default:
        return NotificationError.firebase(
          message: 'Firebase error [${exception.code}]: ${exception.message}',
          technicalDetails: exception.toString(),
          context: context,
          stackTrace: stackTrace,
          originalException: exception,
        );
    }
  }

  /// Handle Supabase-specific exceptions
  NotificationError _handleSupabaseException(
    PostgrestException exception,
    String? operationId,
    Map<String, dynamic>? context,
    StackTrace? stackTrace,
  ) {
    switch (exception.code) {
      case '401':
        return NotificationError(
          type: NotificationErrorType.authenticationError,
          severity: NotificationErrorSeverity.high,
          message: 'Authentication failed: ${exception.message}',
          userMessage: 'Falha na autenticação. Inicie sessão novamente.',
          technicalDetails: exception.toString(),
          context: context,
          stackTrace: stackTrace,
          recoveryStrategy: NotificationErrorRecoveryStrategy.userAction,
          operationId: operationId,
          originalException: exception,
        );
      
      case '403':
        return NotificationError(
          type: NotificationErrorType.authorizationError,
          severity: NotificationErrorSeverity.medium,
          message: 'Authorization failed: ${exception.message}',
          userMessage: 'Acesso negado.',
          technicalDetails: exception.toString(),
          context: context,
          stackTrace: stackTrace,
          recoveryStrategy: NotificationErrorRecoveryStrategy.userAction,
          operationId: operationId,
          originalException: exception,
        );
      
      case '429':
        return NotificationError(
          type: NotificationErrorType.rateLimitExceeded,
          severity: NotificationErrorSeverity.medium,
          message: 'Rate limit exceeded: ${exception.message}',
          userMessage: 'Muitas solicitações. Aguarde um momento.',
          technicalDetails: exception.toString(),
          context: context,
          stackTrace: stackTrace,
          recoveryStrategy: NotificationErrorRecoveryStrategy.retryWithDelay,
          operationId: operationId,
          originalException: exception,
        );
      
      case '500':
      case '502':
      case '503':
        return NotificationError(
          type: NotificationErrorType.serverError,
          severity: NotificationErrorSeverity.high,
          message: 'Server error [${exception.code}]: ${exception.message}',
          userMessage: 'Erro no servidor. Tente novamente.',
          technicalDetails: exception.toString(),
          context: context,
          stackTrace: stackTrace,
          recoveryStrategy: NotificationErrorRecoveryStrategy.retryWithDelay,
          operationId: operationId,
          originalException: exception,
        );
      
      default:
        return NotificationError.supabase(
          message: 'Supabase error [${exception.code}]: ${exception.message}',
          technicalDetails: exception.toString(),
          context: context,
          stackTrace: stackTrace,
          originalException: exception,
        );
    }
  }

  /// Record error for statistics and analysis
  void _recordError(NotificationError error) {
    // Add to history
    _errorHistory.add(error);
    
    // Maintain history size limit
    if (_errorHistory.length > maxErrorHistorySize) {
      _errorHistory.removeAt(0);
    }
    
    // Update error counts
    _errorCounts[error.type] = (_errorCounts[error.type] ?? 0) + 1;
  }

  /// Log error with appropriate level
  void _logError(NotificationError error) {
    final logMessage = '[${error.type.name}] ${error.message}';
    
    switch (error.severity) {
      case NotificationErrorSeverity.low:
        debugPrint('INFO: $logMessage');
        break;
      case NotificationErrorSeverity.medium:
        debugPrint('WARNING: $logMessage');
        break;
      case NotificationErrorSeverity.high:
        debugPrint('ERROR: $logMessage');
        if (error.technicalDetails != null) {
          debugPrint('Details: ${error.technicalDetails}');
        }
        break;
      case NotificationErrorSeverity.critical:
        debugPrint('CRITICAL: $logMessage');
        if (error.technicalDetails != null) {
          debugPrint('Details: ${error.technicalDetails}');
        }
        if (error.stackTrace != null) {
          debugPrint('Stack trace: ${error.stackTrace}');
        }
        break;
    }
  }

  /// Escalate critical errors to error tracking service
  void _escalateError(NotificationError error) {
    final errorKey = '${error.type.name}_${error.message.hashCode}';
    final now = DateTime.now();
    
    // Throttle error reporting
    if (_lastErrorReported.containsKey(errorKey)) {
      final lastReported = _lastErrorReported[errorKey]!;
      if (now.difference(lastReported) < errorReportingThrottle) {
        return; // Skip reporting this error
      }
    }
    
    _lastErrorReported[errorKey] = now;
    
    // In a real app, you would send this to your error tracking service
    // For now, we'll just log it as critical
    debugPrint('ESCALATED ERROR: ${error.toJson()}');
    
    // You could integrate with services like:
    // - Sentry
    // - Crashlytics
    // - Bugsnag
    // - Custom error reporting endpoint
  }

  /// Get retry count for an operation
  int _getRetryCount(String? operationId) {
    if (operationId == null) return 0;
    return _operationRetryCount[operationId] ?? 0;
  }

  /// Increment retry count for an operation
  void _incrementRetryCount(String? operationId) {
    if (operationId == null) return;
    _operationRetryCount[operationId] = _getRetryCount(operationId) + 1;
  }

  /// Reset retry count for an operation
  void _resetRetryCount(String? operationId) {
    if (operationId == null) return;
    _operationRetryCount.remove(operationId);
  }

  /// Get error statistics
  Map<String, dynamic> getErrorStatistics() {
    final totalErrors = _errorHistory.length;
    final errorsByType = Map<String, int>.from(
      _errorCounts.map((key, value) => MapEntry(key.name, value)),
    );
    
    final errorsBySeverity = <String, int>{};
    for (final error in _errorHistory) {
      final severity = error.severity.name;
      errorsBySeverity[severity] = (errorsBySeverity[severity] ?? 0) + 1;
    }
    
    final recentErrors = _errorHistory
        .where((error) => 
            DateTime.now().difference(error.timestamp) < const Duration(hours: 1))
        .length;
    
    return {
      'totalErrors': totalErrors,
      'recentErrors': recentErrors,
      'errorsByType': errorsByType,
      'errorsBySeverity': errorsBySeverity,
      'activeRetries': _operationRetryCount.length,
    };
  }

  /// Get recent errors for debugging
  List<NotificationError> getRecentErrors({int limit = 10}) {
    final sortedErrors = List<NotificationError>.from(_errorHistory)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    
    return sortedErrors.take(limit).toList();
  }

  /// Clear error history (for testing or maintenance)
  void clearErrorHistory() {
    _errorHistory.clear();
    _errorCounts.clear();
    _operationRetryCount.clear();
    _lastErrorReported.clear();
  }

  /// Check if a specific error type is occurring frequently
  bool isErrorTypeFrequent(NotificationErrorType type, {int threshold = 5}) {
    return (_errorCounts[type] ?? 0) >= threshold;
  }

  /// Get health status based on recent errors
  Map<String, dynamic> getHealthStatus() {
    final recentErrors = _errorHistory
        .where((error) => 
            DateTime.now().difference(error.timestamp) < const Duration(minutes: 15))
        .toList();
    
    final criticalErrors = recentErrors
        .where((error) => error.severity == NotificationErrorSeverity.critical)
        .length;
    
    final highErrors = recentErrors
        .where((error) => error.severity == NotificationErrorSeverity.high)
        .length;
    
    String status;
    if (criticalErrors > 0) {
      status = 'critical';
    } else if (highErrors > 3) {
      status = 'degraded';
    } else if (recentErrors.length > 10) {
      status = 'warning';
    } else {
      status = 'healthy';
    }
    
    return {
      'status': status,
      'recentErrors': recentErrors.length,
      'criticalErrors': criticalErrors,
      'highErrors': highErrors,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
}
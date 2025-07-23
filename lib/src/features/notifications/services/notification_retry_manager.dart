import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../data/models/notification_error.dart';
import 'notification_error_handler.dart';

/// Manages retry logic for failed notification operations
/// Implements exponential backoff, circuit breaker pattern, and retry policies
class NotificationRetryManager {
  static NotificationRetryManager? _instance;
  static NotificationRetryManager get instance => _instance ??= NotificationRetryManager._();
  
  NotificationRetryManager._();

  // Active retry operations
  final Map<String, RetryOperation> _activeRetries = {};
  final Map<String, CircuitBreaker> _circuitBreakers = {};
  
  // Configuration
  static const int defaultMaxRetries = 3;
  static const Duration defaultInitialDelay = Duration(seconds: 1);
  static const double defaultBackoffMultiplier = 2.0;
  static const Duration defaultMaxDelay = Duration(minutes: 5);

  /// Execute an operation with retry logic
  Future<NotificationResult<T>> executeWithRetry<T>(
    String operationId,
    Future<T> Function() operation, {
    int maxRetries = defaultMaxRetries,
    Duration initialDelay = defaultInitialDelay,
    double backoffMultiplier = defaultBackoffMultiplier,
    Duration maxDelay = defaultMaxDelay,
    bool Function(NotificationError)? shouldRetry,
    Map<String, dynamic>? context,
  }) async {
    // Check circuit breaker
    final circuitBreaker = _getCircuitBreaker(operationId);
    if (!circuitBreaker.canExecute()) {
      return NotificationResult.failure(
        NotificationError(
          type: NotificationErrorType.serviceUnavailable,
          severity: NotificationErrorSeverity.high,
          message: 'Circuit breaker is open for operation: $operationId',
          userMessage: 'Serviço temporariamente indisponível.',
          context: context,
          recoveryStrategy: NotificationErrorRecoveryStrategy.retryWithDelay,
          operationId: operationId,
        ),
      );
    }

    final retryOperation = RetryOperation(
      operationId: operationId,
      maxRetries: maxRetries,
      initialDelay: initialDelay,
      backoffMultiplier: backoffMultiplier,
      maxDelay: maxDelay,
      shouldRetry: shouldRetry,
      context: context,
    );

    _activeRetries[operationId] = retryOperation;

    try {
      final result = await _executeWithRetryLogic(operation, retryOperation, circuitBreaker);
      
      // Record success in circuit breaker
      if (result.isSuccess) {
        circuitBreaker.recordSuccess();
      }
      
      return result;
    } finally {
      _activeRetries.remove(operationId);
    }
  }

  /// Execute operation with retry logic
  Future<NotificationResult<T>> _executeWithRetryLogic<T>(
    Future<T> Function() operation,
    RetryOperation retryOperation,
    CircuitBreaker circuitBreaker,
  ) async {
    NotificationError? lastError;

    for (int attempt = 0; attempt <= retryOperation.maxRetries; attempt++) {
      try {
        // Add jitter to prevent thundering herd
        if (attempt > 0) {
          final delay = retryOperation.getDelayForAttempt(attempt);
          await Future.delayed(delay);
        }

        debugPrint('Executing ${retryOperation.operationId}, attempt ${attempt + 1}/${retryOperation.maxRetries + 1}');
        
        final result = await operation();
        
        debugPrint('Operation ${retryOperation.operationId} succeeded on attempt ${attempt + 1}');
        return NotificationResult.success(result);
        
      } catch (e, stackTrace) {
        final error = NotificationErrorHandler.instance.handleException(
          e is Exception ? e : Exception(e.toString()),
          operationId: retryOperation.operationId,
          context: retryOperation.context,
          stackTrace: stackTrace,
        );

        lastError = error;
        
        // Record failure in circuit breaker
        circuitBreaker.recordFailure();
        
        debugPrint('Operation ${retryOperation.operationId} failed on attempt ${attempt + 1}: ${error.message}');

        // Check if we should retry this error
        final shouldRetry = retryOperation.shouldRetry?.call(error) ?? _defaultShouldRetry(error);
        
        if (!shouldRetry || attempt >= retryOperation.maxRetries) {
          debugPrint('Not retrying ${retryOperation.operationId}. ShouldRetry: $shouldRetry, Attempt: $attempt, MaxRetries: ${retryOperation.maxRetries}');
          break;
        }
      }
    }

    return NotificationResult.failure(
      lastError ?? NotificationError.unknown(
        message: 'Operation failed without specific error',
        context: retryOperation.context,
      ),
    );
  }

  /// Default retry policy
  bool _defaultShouldRetry(NotificationError error) {
    switch (error.type) {
      // Always retry network and connection errors
      case NotificationErrorType.networkError:
      case NotificationErrorType.connectionTimeout:
      case NotificationErrorType.serverError:
      case NotificationErrorType.realtimeConnectionError:
        return true;
      
      // Retry service unavailable and temporary errors
      case NotificationErrorType.serviceUnavailable:
      case NotificationErrorType.supabaseError:
      case NotificationErrorType.firebaseError:
        return true;
      
      // Don't retry authentication and validation errors
      case NotificationErrorType.authenticationError:
      case NotificationErrorType.authorizationError:
      case NotificationErrorType.validationError:
      case NotificationErrorType.permissionDenied:
        return false;
      
      // Don't retry rate limiting immediately
      case NotificationErrorType.rateLimitExceeded:
        return false;
      
      // Retry unknown errors cautiously
      case NotificationErrorType.unknownError:
      case NotificationErrorType.unexpectedError:
        return true;
      
      default:
        return false;
    }
  }

  /// Get or create circuit breaker for operation
  CircuitBreaker _getCircuitBreaker(String operationId) {
    return _circuitBreakers.putIfAbsent(
      operationId,
      () => CircuitBreaker(operationId),
    );
  }

  /// Cancel a retry operation
  void cancelRetry(String operationId) {
    final retryOperation = _activeRetries[operationId];
    if (retryOperation != null) {
      retryOperation.cancel();
      _activeRetries.remove(operationId);
      debugPrint('Cancelled retry operation: $operationId');
    }
  }

  /// Cancel all active retries
  void cancelAllRetries() {
    for (final operationId in _activeRetries.keys.toList()) {
      cancelRetry(operationId);
    }
  }

  /// Get active retry operations
  List<String> getActiveRetries() {
    return _activeRetries.keys.toList();
  }

  /// Get retry statistics
  Map<String, dynamic> getRetryStatistics() {
    final circuitBreakerStats = <String, Map<String, dynamic>>{};
    
    for (final entry in _circuitBreakers.entries) {
      circuitBreakerStats[entry.key] = entry.value.getStatistics();
    }

    return {
      'activeRetries': _activeRetries.length,
      'activeOperations': _activeRetries.keys.toList(),
      'circuitBreakers': circuitBreakerStats,
    };
  }

  /// Reset circuit breaker for operation
  void resetCircuitBreaker(String operationId) {
    _circuitBreakers[operationId]?.reset();
  }

  /// Reset all circuit breakers
  void resetAllCircuitBreakers() {
    for (final circuitBreaker in _circuitBreakers.values) {
      circuitBreaker.reset();
    }
  }
}

/// Represents a retry operation with its configuration
class RetryOperation {
  final String operationId;
  final int maxRetries;
  final Duration initialDelay;
  final double backoffMultiplier;
  final Duration maxDelay;
  final bool Function(NotificationError)? shouldRetry;
  final Map<String, dynamic>? context;
  final DateTime startTime;
  
  bool _cancelled = false;

  RetryOperation({
    required this.operationId,
    required this.maxRetries,
    required this.initialDelay,
    required this.backoffMultiplier,
    required this.maxDelay,
    this.shouldRetry,
    this.context,
  }) : startTime = DateTime.now();

  /// Calculate delay for a specific attempt with exponential backoff and jitter
  Duration getDelayForAttempt(int attempt) {
    if (attempt <= 0) return Duration.zero;
    
    // Exponential backoff: initialDelay * (backoffMultiplier ^ (attempt - 1))
    final exponentialDelay = initialDelay.inMilliseconds * 
        pow(backoffMultiplier, attempt - 1).toInt();
    
    // Cap at max delay
    final cappedDelay = Duration(
      milliseconds: min(exponentialDelay, maxDelay.inMilliseconds),
    );
    
    // Add jitter (±25% of the delay)
    final jitterRange = (cappedDelay.inMilliseconds * 0.25).toInt();
    final jitter = Random().nextInt(jitterRange * 2) - jitterRange;
    
    final finalDelay = Duration(
      milliseconds: max(0, cappedDelay.inMilliseconds + jitter),
    );
    
    return finalDelay;
  }

  /// Cancel the retry operation
  void cancel() {
    _cancelled = true;
  }

  /// Check if the operation is cancelled
  bool get isCancelled => _cancelled;

  /// Get operation duration
  Duration get duration => DateTime.now().difference(startTime);
}

/// Circuit breaker implementation to prevent cascading failures
class CircuitBreaker {
  final String operationId;
  
  // Configuration
  static const int failureThreshold = 5;
  static const Duration timeout = Duration(minutes: 1);
  static const int successThreshold = 3;
  
  // State
  CircuitBreakerState _state = CircuitBreakerState.closed;
  int _failureCount = 0;
  int _successCount = 0;
  DateTime? _lastFailureTime;
  DateTime? _stateChangeTime;

  CircuitBreaker(this.operationId) : _stateChangeTime = DateTime.now();

  /// Check if the circuit breaker allows execution
  bool canExecute() {
    switch (_state) {
      case CircuitBreakerState.closed:
        return true;
      
      case CircuitBreakerState.open:
        // Check if timeout has passed
        if (_lastFailureTime != null &&
            DateTime.now().difference(_lastFailureTime!) > timeout) {
          _transitionTo(CircuitBreakerState.halfOpen);
          return true;
        }
        return false;
      
      case CircuitBreakerState.halfOpen:
        return true;
    }
  }

  /// Record a successful operation
  void recordSuccess() {
    switch (_state) {
      case CircuitBreakerState.closed:
        _failureCount = 0;
        break;
      
      case CircuitBreakerState.halfOpen:
        _successCount++;
        if (_successCount >= successThreshold) {
          _transitionTo(CircuitBreakerState.closed);
          _failureCount = 0;
          _successCount = 0;
        }
        break;
      
      case CircuitBreakerState.open:
        // Should not happen, but reset if it does
        _transitionTo(CircuitBreakerState.closed);
        _failureCount = 0;
        break;
    }
  }

  /// Record a failed operation
  void recordFailure() {
    _lastFailureTime = DateTime.now();
    
    switch (_state) {
      case CircuitBreakerState.closed:
        _failureCount++;
        if (_failureCount >= failureThreshold) {
          _transitionTo(CircuitBreakerState.open);
        }
        break;
      
      case CircuitBreakerState.halfOpen:
        _transitionTo(CircuitBreakerState.open);
        _successCount = 0;
        break;
      
      case CircuitBreakerState.open:
        // Already open, just update failure time
        break;
    }
  }

  /// Transition to a new state
  void _transitionTo(CircuitBreakerState newState) {
    if (_state != newState) {
      debugPrint('Circuit breaker $operationId: ${_state.name} -> ${newState.name}');
      _state = newState;
      _stateChangeTime = DateTime.now();
    }
  }

  /// Reset the circuit breaker
  void reset() {
    _state = CircuitBreakerState.closed;
    _failureCount = 0;
    _successCount = 0;
    _lastFailureTime = null;
    _stateChangeTime = DateTime.now();
    debugPrint('Circuit breaker $operationId reset');
  }

  /// Get current state
  CircuitBreakerState get state => _state;

  /// Get statistics
  Map<String, dynamic> getStatistics() {
    return {
      'operationId': operationId,
      'state': _state.name,
      'failureCount': _failureCount,
      'successCount': _successCount,
      'lastFailureTime': _lastFailureTime?.toIso8601String(),
      'stateChangeTime': _stateChangeTime?.toIso8601String(),
      'canExecute': canExecute(),
    };
  }
}

/// Circuit breaker states
enum CircuitBreakerState {
  closed,   // Normal operation
  open,     // Failing, blocking requests
  halfOpen, // Testing if service has recovered
}
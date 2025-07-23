# Comprehensive Error Handling for Notifications System

This document describes the comprehensive error handling system implemented for the notifications feature.

## Overview

The error handling system provides:

- Structured error classification and recovery strategies
- Automatic retry mechanisms with exponential backoff
- Circuit breaker pattern to prevent cascading failures
- Centralized error logging and monitoring
- User-friendly error messages in Portuguese
- Error statistics and health monitoring

## Components

### 1. NotificationError Model (`notification_error.dart`)

**Error Types:**

- `networkError` - Network connectivity issues
- `connectionTimeout` - Request timeouts
- `serverError` - Server-side errors (5xx)
- `authenticationError` - Authentication failures
- `authorizationError` - Permission denied
- `tokenExpired` - Expired authentication tokens
- `validationError` - Invalid input data
- `dataCorruption` - Corrupted data format
- `invalidFormat` - Data format errors
- `firebaseError` - Firebase service errors
- `fcmTokenError` - FCM token issues
- `pushNotificationError` - Push notification failures
- `supabaseError` - Supabase database errors
- `databaseError` - General database errors
- `queryError` - SQL query errors
- `realtimeConnectionError` - Real-time connection issues
- `subscriptionError` - Real-time subscription errors
- `channelError` - Real-time channel errors
- `serviceInitializationError` - Service startup failures
- `serviceUnavailable` - Service temporarily down
- `dependencyError` - Dependency failures
- `permissionDenied` - User permission denied
- `operationCancelled` - User cancelled operation
- `rateLimitExceeded` - Rate limiting triggered
- `unknownError` - Unclassified errors
- `unexpectedError` - Unexpected system errors

**Error Severity Levels:**

- `low` - Minor issues, doesn't affect core functionality
- `medium` - Affects some functionality but has workarounds
- `high` - Critical issues that significantly impact UX
- `critical` - System-breaking issues requiring immediate attention

**Recovery Strategies:**

- `retry` - Automatically retry the operation
- `retryWithDelay` - Retry after exponential backoff delay
- `fallback` - Use alternative approach
- `userAction` - Require user intervention
- `ignore` - Log and continue
- `escalate` - Report to error tracking service

**Factory Methods:**

```dart
NotificationError.network()
NotificationError.firebase()
NotificationError.supabase()
NotificationError.realtimeConnection()
NotificationError.validation()
NotificationError.permission()
NotificationError.serviceInitialization()
NotificationError.pushNotificationError()
NotificationError.unknown()
```

### 2. NotificationResult Wrapper

Provides a Result-like pattern for operations that can fail:

```dart
NotificationResult<T>.success(data)
NotificationResult<T>.failure(error)

// Usage
final result = await someOperation();
if (result.isSuccess) {
  final data = result.dataOrThrow;
} else {
  final error = result.error;
}
```

### 3. NotificationErrorHandler (`notification_error_handler.dart`)

**Features:**

- Exception classification into structured errors
- Error statistics and tracking
- Health status monitoring
- Error escalation to tracking services
- Throttled error reporting

**Key Methods:**

```dart
NotificationError handleException(Exception exception)
Future<NotificationResult<T>> handleError<T>(NotificationError error)
Map<String, dynamic> getErrorStatistics()
List<NotificationError> getRecentErrors()
Map<String, dynamic> getHealthStatus()
```

**Exception Classification:**

- Firebase exceptions → Firebase errors with specific codes
- Supabase exceptions → Database errors with HTTP status codes
- Socket exceptions → Network errors
- Timeout exceptions → Connection timeout errors
- Format exceptions → Data corruption errors
- State errors → Service initialization errors
- Argument errors → Validation errors

### 4. NotificationRetryManager (`notification_retry_manager.dart`)

**Features:**

- Exponential backoff with jitter
- Circuit breaker pattern
- Configurable retry policies
- Operation cancellation
- Retry statistics

**Configuration:**

- Default max retries: 3
- Initial delay: 1 second
- Backoff multiplier: 2.0
- Max delay: 5 minutes
- Circuit breaker failure threshold: 5
- Circuit breaker timeout: 1 minute

**Key Methods:**

```dart
Future<NotificationResult<T>> executeWithRetry<T>(
  String operationId,
  Future<T> Function() operation,
)
void cancelRetry(String operationId)
Map<String, dynamic> getRetryStatistics()
```

**Circuit Breaker States:**

- `closed` - Normal operation
- `open` - Failing, blocking requests
- `halfOpen` - Testing if service recovered

### 5. Enhanced Services

All notification services have been enhanced with comprehensive error handling:

#### NotificationService

- Structured error handling for Firebase operations
- FCM token management with retry logic
- Push notification error handling
- Permission request error handling

#### NotificationServiceManager

- Service initialization error handling
- Coordinated error management across services
- Graceful degradation when services fail

#### NotificationRealtimeService

- Real-time connection error handling
- Automatic reconnection with exponential backoff
- Circuit breaker for subscription failures

## Error Handling Patterns

### 1. Service Initialization

```dart
Future<NotificationResult<void>> initialize() async {
  return await _retryManager.executeWithRetry(
    'service_init',
    () async {
      // Initialization logic
      if (someCondition) {
        throw NotificationError.serviceInitialization(
          message: 'Service failed to initialize',
          userMessage: 'Falha ao inicializar serviço.',
        );
      }
    },
    context: {'operation': 'initialize'},
  );
}
```

### 2. Network Operations

```dart
Future<NotificationResult<T>> networkOperation() async {
  return await _retryManager.executeWithRetry(
    'network_op',
    () async {
      try {
        // Network operation
        return await apiCall();
      } catch (e) {
        throw _errorHandler.handleException(e);
      }
    },
    shouldRetry: (error) => error.type == NotificationErrorType.networkError,
  );
}
```

### 3. Database Operations

```dart
try {
  await databaseOperation();
} catch (e) {
  final error = _errorHandler.handleException(
    e is Exception ? e : Exception(e.toString()),
    operationId: 'db_operation',
    context: {'table': 'notifications'},
  );

  if (error.shouldEscalate) {
    // Error will be automatically escalated
  }

  throw error;
}
```

## User Experience

### Error Messages

All errors include user-friendly messages in Portuguese:

- Technical errors → Simple explanations
- Network issues → "Problema de conexão"
- Permission errors → "Permissão negada"
- Service errors → "Serviço temporariamente indisponível"

### Graceful Degradation

- Push notifications fail → Database notifications still work
- Real-time updates fail → Polling fallback
- Service unavailable → Cached data shown

### Retry Behavior

- Automatic retries for transient errors
- Exponential backoff prevents server overload
- Circuit breaker prevents cascading failures
- User can manually retry failed operations

## Monitoring and Debugging

### Error Statistics

```dart
final stats = NotificationErrorHandler.instance.getErrorStatistics();
// Returns:
// {
//   'totalErrors': 42,
//   'recentErrors': 5,
//   'errorsByType': {'networkError': 10, 'firebaseError': 3},
//   'errorsBySeverity': {'high': 2, 'medium': 8, 'low': 32},
//   'activeRetries': 2
// }
```

### Health Status

```dart
final health = NotificationErrorHandler.instance.getHealthStatus();
// Returns:
// {
//   'status': 'healthy', // healthy, warning, degraded, critical
//   'recentErrors': 2,
//   'criticalErrors': 0,
//   'highErrors': 1,
//   'timestamp': '2024-01-15T10:30:00Z'
// }
```

### Recent Errors

```dart
final errors = NotificationErrorHandler.instance.getRecentErrors(limit: 10);
// Returns list of recent NotificationError objects
```

## Integration Points

### Error Callbacks

Services can register error callbacks:

```dart
notificationService.onError = (error) {
  // Handle error in UI
  showErrorSnackbar(error.userMessage ?? 'Erro desconhecido');
};
```

### Error Tracking Services

The system is designed to integrate with:

- Sentry
- Firebase Crashlytics
- Bugsnag
- Custom error reporting endpoints

### Logging

All errors are automatically logged with appropriate levels:

- `INFO` - Low severity errors
- `WARNING` - Medium severity errors
- `ERROR` - High severity errors
- `CRITICAL` - Critical errors with stack traces

## Best Practices

1. **Always use NotificationResult for operations that can fail**
2. **Classify exceptions using NotificationErrorHandler**
3. **Provide user-friendly error messages in Portuguese**
4. **Use retry manager for transient failures**
5. **Monitor error statistics and health status**
6. **Implement graceful degradation for non-critical failures**
7. **Escalate critical errors to monitoring services**

## Testing Error Handling

The error handling system includes utilities for testing:

- Mock error scenarios
- Circuit breaker state manipulation
- Error statistics reset
- Retry operation cancellation

This comprehensive error handling system ensures the notifications feature is robust, user-friendly, and maintainable.

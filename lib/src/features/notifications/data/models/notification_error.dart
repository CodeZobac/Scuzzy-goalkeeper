/// Comprehensive error handling for the notifications system
/// Provides structured error types, recovery strategies, and user-friendly messages

enum NotificationErrorType {
  // Network and connectivity errors
  networkError,
  connectionTimeout,
  serverError,
  
  // Authentication and authorization errors
  authenticationError,
  authorizationError,
  tokenExpired,
  
  // Data and validation errors
  validationError,
  dataCorruption,
  invalidFormat,
  
  // Firebase and push notification errors
  firebaseError,
  fcmTokenError,
  pushNotificationError,
  
  // Supabase and database errors
  supabaseError,
  databaseError,
  queryError,
  
  // Real-time connection errors
  realtimeConnectionError,
  subscriptionError,
  channelError,
  
  // Service and initialization errors
  serviceInitializationError,
  serviceUnavailable,
  dependencyError,
  
  // User action errors
  permissionDenied,
  operationCancelled,
  rateLimitExceeded,
  
  // Unknown and unexpected errors
  unknownError,
  unexpectedError,
}

enum NotificationErrorSeverity {
  low,      // Minor issues that don't affect core functionality
  medium,   // Issues that affect some functionality but have workarounds
  high,     // Critical issues that significantly impact user experience
  critical, // System-breaking issues that require immediate attention
}

enum NotificationErrorRecoveryStrategy {
  retry,           // Automatically retry the operation
  retryWithDelay,  // Retry after a delay
  fallback,        // Use alternative approach
  userAction,      // Require user intervention
  ignore,          // Log and continue
  escalate,        // Report to error tracking service
}

class NotificationError implements Exception {
  final NotificationErrorType type;
  final NotificationErrorSeverity severity;
  final String message;
  final String? userMessage;
  final String? technicalDetails;
  final StackTrace? stackTrace;
  final Map<String, dynamic>? context;
  final NotificationErrorRecoveryStrategy recoveryStrategy;
  final DateTime timestamp;
  final String? operationId;
  final Exception? originalException;

  NotificationError({
    required this.type,
    required this.severity,
    required this.message,
    this.userMessage,
    this.technicalDetails,
    this.stackTrace,
    this.context,
    this.recoveryStrategy = NotificationErrorRecoveryStrategy.retry,
    DateTime? timestamp,
    this.operationId,
    this.originalException,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Create a network error
  factory NotificationError.network({
    String? message,
    String? userMessage,
    String? technicalDetails,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
    Exception? originalException,
  }) {
    return NotificationError(
      type: NotificationErrorType.networkError,
      severity: NotificationErrorSeverity.medium,
      message: message ?? 'Network error occurred',
      userMessage: userMessage ?? 'Problema de conexão. Verifique a sua internet.',
      technicalDetails: technicalDetails,
      stackTrace: stackTrace,
      context: context,
      recoveryStrategy: NotificationErrorRecoveryStrategy.retryWithDelay,
      originalException: originalException,
    );
  }

  /// Create a Firebase error
  factory NotificationError.firebase({
    String? message,
    String? userMessage,
    String? technicalDetails,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
    Exception? originalException,
  }) {
    return NotificationError(
      type: NotificationErrorType.firebaseError,
      severity: NotificationErrorSeverity.high,
      message: message ?? 'Firebase error occurred',
      userMessage: userMessage ?? 'Erro no serviço de notificações.',
      technicalDetails: technicalDetails,
      stackTrace: stackTrace,
      context: context,
      recoveryStrategy: NotificationErrorRecoveryStrategy.fallback,
      originalException: originalException,
    );
  }

  /// Create a Supabase error
  factory NotificationError.supabase({
    String? message,
    String? userMessage,
    String? technicalDetails,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
    Exception? originalException,
  }) {
    return NotificationError(
      type: NotificationErrorType.supabaseError,
      severity: NotificationErrorSeverity.high,
      message: message ?? 'Supabase error occurred',
      userMessage: userMessage ?? 'Erro no banco de dados.',
      technicalDetails: technicalDetails,
      stackTrace: stackTrace,
      context: context,
      recoveryStrategy: NotificationErrorRecoveryStrategy.retry,
      originalException: originalException,
    );
  }

  /// Create a real-time connection error
  factory NotificationError.realtimeConnection({
    String? message,
    String? userMessage,
    String? technicalDetails,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
    Exception? originalException,
  }) {
    return NotificationError(
      type: NotificationErrorType.realtimeConnectionError,
      severity: NotificationErrorSeverity.medium,
      message: message ?? 'Real-time connection error',
      userMessage: userMessage ?? 'Conexão em tempo real perdida.',
      technicalDetails: technicalDetails,
      stackTrace: stackTrace,
      context: context,
      recoveryStrategy: NotificationErrorRecoveryStrategy.retryWithDelay,
      originalException: originalException,
    );
  }

  /// Create a validation error
  factory NotificationError.validation({
    String? message,
    String? userMessage,
    String? technicalDetails,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
    Exception? originalException,
  }) {
    return NotificationError(
      type: NotificationErrorType.validationError,
      severity: NotificationErrorSeverity.low,
      message: message ?? 'Validation error',
      userMessage: userMessage ?? 'Dados inválidos fornecidos.',
      technicalDetails: technicalDetails,
      stackTrace: stackTrace,
      context: context,
      recoveryStrategy: NotificationErrorRecoveryStrategy.userAction,
      originalException: originalException,
    );
  }

  /// Create a permission error
  factory NotificationError.permission({
    String? message,
    String? userMessage,
    String? technicalDetails,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
    Exception? originalException,
  }) {
    return NotificationError(
      type: NotificationErrorType.permissionDenied,
      severity: NotificationErrorSeverity.medium,
      message: message ?? 'Permission denied',
      userMessage: userMessage ?? 'Permissão negada. Verifique as configurações.',
      technicalDetails: technicalDetails,
      stackTrace: stackTrace,
      context: context,
      recoveryStrategy: NotificationErrorRecoveryStrategy.userAction,
      originalException: originalException,
    );
  }

  /// Create a service initialization error
  factory NotificationError.serviceInitialization({
    String? message,
    String? userMessage,
    String? technicalDetails,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
    Exception? originalException,
  }) {
    return NotificationError(
      type: NotificationErrorType.serviceInitializationError,
      severity: NotificationErrorSeverity.critical,
      message: message ?? 'Service initialization failed',
      userMessage: userMessage ?? 'Falha ao inicializar serviço.',
      technicalDetails: technicalDetails,
      stackTrace: stackTrace,
      context: context,
      recoveryStrategy: NotificationErrorRecoveryStrategy.escalate,
      originalException: originalException,
    );
  }

  /// Create a push notification error
  factory NotificationError.pushNotificationError({
    String? message,
    String? userMessage,
    String? technicalDetails,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
    Exception? originalException,
  }) {
    return NotificationError(
      type: NotificationErrorType.pushNotificationError,
      severity: NotificationErrorSeverity.high,
      message: message ?? 'Push notification error occurred',
      userMessage: userMessage ?? 'Erro ao enviar notificação push.',
      technicalDetails: technicalDetails,
      stackTrace: stackTrace,
      context: context,
      recoveryStrategy: NotificationErrorRecoveryStrategy.retry,
      originalException: originalException,
    );
  }

  /// Create an unknown error
  factory NotificationError.unknown({
    String? message,
    String? userMessage,
    String? technicalDetails,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
    Exception? originalException,
  }) {
    return NotificationError(
      type: NotificationErrorType.unknownError,
      severity: NotificationErrorSeverity.medium,
      message: message ?? 'Unknown error occurred',
      userMessage: userMessage ?? 'Erro desconhecido. Tente novamente.',
      technicalDetails: technicalDetails,
      stackTrace: stackTrace,
      context: context,
      recoveryStrategy: NotificationErrorRecoveryStrategy.retry,
      originalException: originalException,
    );
  }

  /// Check if this error should be retried
  bool get shouldRetry {
    return recoveryStrategy == NotificationErrorRecoveryStrategy.retry ||
           recoveryStrategy == NotificationErrorRecoveryStrategy.retryWithDelay;
  }

  /// Check if this error requires user action
  bool get requiresUserAction {
    return recoveryStrategy == NotificationErrorRecoveryStrategy.userAction;
  }

  /// Check if this error should be escalated
  bool get shouldEscalate {
    return recoveryStrategy == NotificationErrorRecoveryStrategy.escalate ||
           severity == NotificationErrorSeverity.critical;
  }

  /// Get retry delay based on error type
  Duration get retryDelay {
    switch (type) {
      case NotificationErrorType.networkError:
      case NotificationErrorType.connectionTimeout:
        return const Duration(seconds: 5);
      case NotificationErrorType.realtimeConnectionError:
        return const Duration(seconds: 2);
      case NotificationErrorType.serverError:
        return const Duration(seconds: 10);
      case NotificationErrorType.rateLimitExceeded:
        return const Duration(minutes: 1);
      default:
        return const Duration(seconds: 3);
    }
  }

  /// Convert to a map for logging
  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'severity': severity.name,
      'message': message,
      'userMessage': userMessage,
      'technicalDetails': technicalDetails,
      'context': context,
      'recoveryStrategy': recoveryStrategy.name,
      'timestamp': timestamp.toIso8601String(),
      'operationId': operationId,
      'originalException': originalException?.toString(),
    };
  }

  /// Convert to JSON string for logging
  String toJson() {
    return toMap().toString();
  }

  @override
  String toString() {
    return 'NotificationError(type: $type, severity: $severity, message: $message)';
  }
}

/// Result wrapper for operations that can fail
class NotificationResult<T> {
  final T? data;
  final NotificationError? error;
  final bool isSuccess;

  const NotificationResult._({
    this.data,
    this.error,
    required this.isSuccess,
  });

  /// Create a successful result
  factory NotificationResult.success(T data) {
    return NotificationResult._(
      data: data,
      isSuccess: true,
    );
  }

  /// Create a failed result
  factory NotificationResult.failure(NotificationError error) {
    return NotificationResult._(
      error: error,
      isSuccess: false,
    );
  }

  /// Check if the result is a failure
  bool get isFailure => !isSuccess;

  /// Get data or throw error
  T get dataOrThrow {
    if (isSuccess && data != null) {
      return data!;
    }
    throw error ?? NotificationError.unknown(message: 'No data available');
  }

  /// Get data or return default value
  T dataOr(T defaultValue) {
    return isSuccess && data != null ? data! : defaultValue;
  }

  /// Transform the data if successful
  NotificationResult<U> map<U>(U Function(T) transform) {
    if (isSuccess && data != null) {
      try {
        return NotificationResult.success(transform(data!));
      } catch (e, stackTrace) {
        return NotificationResult.failure(
          NotificationError.unknown(
            message: 'Error transforming result: $e',
            stackTrace: stackTrace,
            originalException: e is Exception ? e : Exception(e.toString()),
          ),
        );
      }
    }
    return NotificationResult.failure(error!);
  }

  /// Handle the result with callbacks
  U fold<U>(
    U Function(NotificationError) onError,
    U Function(T) onSuccess,
  ) {
    if (isSuccess && data != null) {
      return onSuccess(data!);
    }
    return onError(error!);
  }
}
import '../services/auth_code_validation_service.dart';
import '../services/auth_code_cleanup_service.dart';
import '../data/models/auth_code.dart';
import '../../../core/services/email_logger.dart';

/// Controller for authentication code validation endpoints
/// 
/// This controller provides HTTP-like endpoints for validating authentication codes
/// and managing code cleanup operations. It serves as the main interface for
/// authentication code operations in the application.
class AuthCodeController {
  final AuthCodeValidationService _validationService;
  final AuthCodeCleanupService _cleanupService;

  AuthCodeController({
    AuthCodeValidationService? validationService,
    AuthCodeCleanupService? cleanupService,
  }) : _validationService = validationService ?? AuthCodeValidationService(),
       _cleanupService = cleanupService ?? AuthCodeCleanupService();

  /// Endpoint: POST /auth/codes/validate/email-confirmation
  /// 
  /// Validates an email confirmation authentication code
  /// 
  /// Request body: { "code": "authentication_code" }
  /// 
  /// Response:
  /// - 200: { "success": true, "userId": "user_id", "message": "Code validated successfully" }
  /// - 400: { "success": false, "error": "invalid_code", "message": "Invalid or expired code" }
  /// - 500: { "success": false, "error": "system_error", "message": "Internal server error" }
  Future<AuthCodeEndpointResponse> validateEmailConfirmationCode({
    required String code,
  }) async {
    EmailLogger.info(
      'Email confirmation code validation endpoint called',
      context: {'hasCode': code.isNotEmpty},
    );

    try {
      final result = await _validationService.validateEmailConfirmationCode(code);
      
      if (result.isSuccess && result.authCode != null) {
        return AuthCodeEndpointResponse.success(
          message: 'Código de confirmação validado com sucesso',
          userId: result.authCode!.userId,
          codeType: AuthCodeType.emailConfirmation,
        );
      }
      
      // Handle different error types with appropriate HTTP status codes
      switch (result.errorType) {
        case AuthCodeValidationErrorType.emptyCode:
          return AuthCodeEndpointResponse.badRequest(
            error: 'empty_code',
            message: result.userFriendlyMessage,
          );
        case AuthCodeValidationErrorType.invalidCode:
          return AuthCodeEndpointResponse.badRequest(
            error: 'invalid_code',
            message: result.userFriendlyMessage,
          );
        case AuthCodeValidationErrorType.expired:
          return AuthCodeEndpointResponse.badRequest(
            error: 'expired_code',
            message: result.userFriendlyMessage,
          );
        case AuthCodeValidationErrorType.alreadyUsed:
          return AuthCodeEndpointResponse.badRequest(
            error: 'used_code',
            message: result.userFriendlyMessage,
          );
        case AuthCodeValidationErrorType.systemError:
          return AuthCodeEndpointResponse.internalError(
            error: 'system_error',
            message: 'Erro interno do servidor',
          );
        default:
          return AuthCodeEndpointResponse.badRequest(
            error: 'validation_failed',
            message: result.userFriendlyMessage,
          );
      }
    } catch (e) {
      EmailLogger.error(
        'Unexpected error in email confirmation validation endpoint',
        error: e,
      );
      
      return AuthCodeEndpointResponse.internalError(
        error: 'unexpected_error',
        message: 'Erro inesperado do servidor',
      );
    }
  }

  /// Endpoint: POST /auth/codes/validate/password-reset
  /// 
  /// Validates a password reset authentication code
  /// 
  /// Request body: { "code": "authentication_code" }
  /// 
  /// Response:
  /// - 200: { "success": true, "userId": "user_id", "message": "Code validated successfully" }
  /// - 400: { "success": false, "error": "invalid_code", "message": "Invalid or expired code" }
  /// - 500: { "success": false, "error": "system_error", "message": "Internal server error" }
  Future<AuthCodeEndpointResponse> validatePasswordResetCode({
    required String code,
  }) async {
    EmailLogger.info(
      'Password reset code validation endpoint called',
      context: {'hasCode': code.isNotEmpty},
    );

    try {
      final result = await _validationService.validatePasswordResetCode(code);
      
      if (result.isSuccess && result.authCode != null) {
        return AuthCodeEndpointResponse.success(
          message: 'Código de recuperação validado com sucesso',
          userId: result.authCode!.userId,
          codeType: AuthCodeType.passwordReset,
        );
      }
      
      // Handle different error types with appropriate HTTP status codes
      switch (result.errorType) {
        case AuthCodeValidationErrorType.emptyCode:
          return AuthCodeEndpointResponse.badRequest(
            error: 'empty_code',
            message: result.userFriendlyMessage,
          );
        case AuthCodeValidationErrorType.invalidCode:
          return AuthCodeEndpointResponse.badRequest(
            error: 'invalid_code',
            message: result.userFriendlyMessage,
          );
        case AuthCodeValidationErrorType.expired:
          return AuthCodeEndpointResponse.badRequest(
            error: 'expired_code',
            message: result.userFriendlyMessage,
          );
        case AuthCodeValidationErrorType.alreadyUsed:
          return AuthCodeEndpointResponse.badRequest(
            error: 'used_code',
            message: result.userFriendlyMessage,
          );
        case AuthCodeValidationErrorType.systemError:
          return AuthCodeEndpointResponse.internalError(
            error: 'system_error',
            message: 'Erro interno do servidor',
          );
        default:
          return AuthCodeEndpointResponse.badRequest(
            error: 'validation_failed',
            message: result.userFriendlyMessage,
          );
      }
    } catch (e) {
      EmailLogger.error(
        'Unexpected error in password reset validation endpoint',
        error: e,
      );
      
      return AuthCodeEndpointResponse.internalError(
        error: 'unexpected_error',
        message: 'Erro inesperado do servidor',
      );
    }
  }

  /// Endpoint: POST /auth/codes/validate
  /// 
  /// Validates any authentication code (auto-detects type)
  /// 
  /// Request body: { "code": "authentication_code" }
  /// 
  /// Response:
  /// - 200: { "success": true, "userId": "user_id", "codeType": "email_confirmation|password_reset", "message": "Code validated successfully" }
  /// - 400: { "success": false, "error": "invalid_code", "message": "Invalid or expired code" }
  /// - 500: { "success": false, "error": "system_error", "message": "Internal server error" }
  Future<AuthCodeEndpointResponse> validateAnyAuthCode({
    required String code,
  }) async {
    EmailLogger.info(
      'Generic code validation endpoint called',
      context: {'hasCode': code.isNotEmpty},
    );

    try {
      final result = await _validationService.validateAnyAuthCode(code);
      
      if (result.isSuccess && result.authCode != null) {
        return AuthCodeEndpointResponse.success(
          message: 'Código validado com sucesso',
          userId: result.authCode!.userId,
          codeType: result.authCode!.type,
        );
      }
      
      // Handle different error types with appropriate HTTP status codes
      switch (result.errorType) {
        case AuthCodeValidationErrorType.emptyCode:
          return AuthCodeEndpointResponse.badRequest(
            error: 'empty_code',
            message: result.userFriendlyMessage,
          );
        case AuthCodeValidationErrorType.invalidCode:
          return AuthCodeEndpointResponse.badRequest(
            error: 'invalid_code',
            message: result.userFriendlyMessage,
          );
        case AuthCodeValidationErrorType.expired:
          return AuthCodeEndpointResponse.badRequest(
            error: 'expired_code',
            message: result.userFriendlyMessage,
          );
        case AuthCodeValidationErrorType.alreadyUsed:
          return AuthCodeEndpointResponse.badRequest(
            error: 'used_code',
            message: result.userFriendlyMessage,
          );
        case AuthCodeValidationErrorType.systemError:
          return AuthCodeEndpointResponse.internalError(
            error: 'system_error',
            message: 'Erro interno do servidor',
          );
        default:
          return AuthCodeEndpointResponse.badRequest(
            error: 'validation_failed',
            message: result.userFriendlyMessage,
          );
      }
    } catch (e) {
      EmailLogger.error(
        'Unexpected error in generic validation endpoint',
        error: e,
      );
      
      return AuthCodeEndpointResponse.internalError(
        error: 'unexpected_error',
        message: 'Erro inesperado do servidor',
      );
    }
  }

  /// Endpoint: GET /auth/codes/status
  /// 
  /// Gets the status of an authentication code without consuming it
  /// 
  /// Query parameters: ?code=authentication_code
  /// 
  /// Response:
  /// - 200: { "success": true, "found": true, "isValid": true, "isExpired": false, "isUsed": false, "codeType": "email_confirmation", "message": "Code status retrieved" }
  /// - 404: { "success": false, "found": false, "message": "Code not found" }
  /// - 500: { "success": false, "error": "system_error", "message": "Internal server error" }
  Future<AuthCodeStatusEndpointResponse> getAuthCodeStatus({
    required String code,
  }) async {
    EmailLogger.info(
      'Code status endpoint called',
      context: {'hasCode': code.isNotEmpty},
    );

    try {
      final result = await _validationService.getAuthCodeStatus(code);
      
      if (result.isFound && result.authCode != null) {
        return AuthCodeStatusEndpointResponse.found(
          authCode: result.authCode!,
          isValid: result.isValid ?? false,
          isExpired: result.isExpired ?? false,
          isUsed: result.isUsed ?? false,
          message: result.statusMessage,
        );
      }
      
      return AuthCodeStatusEndpointResponse.notFound(
        message: result.message ?? 'Código não encontrado',
      );
    } catch (e) {
      EmailLogger.error(
        'Unexpected error in code status endpoint',
        error: e,
      );
      
      return AuthCodeStatusEndpointResponse.error(
        message: 'Erro inesperado do servidor',
      );
    }
  }

  /// Endpoint: POST /auth/codes/cleanup
  /// 
  /// Manually triggers cleanup of expired authentication codes
  /// 
  /// Response:
  /// - 200: { "success": true, "cleanedCount": 42, "duration": "150ms", "message": "Cleanup completed successfully" }
  /// - 500: { "success": false, "error": "cleanup_failed", "message": "Cleanup operation failed" }
  Future<AuthCodeCleanupEndpointResponse> performCleanup() async {
    EmailLogger.info('Manual cleanup endpoint called');

    try {
      final result = await _cleanupService.performManualCleanup();
      
      if (result.isSuccess) {
        return AuthCodeCleanupEndpointResponse.success(
          cleanedCount: result.cleanedCount ?? 0,
          duration: result.duration ?? Duration.zero,
          message: result.userFriendlyMessage,
        );
      }
      
      return AuthCodeCleanupEndpointResponse.error(
        error: 'cleanup_failed',
        message: result.userFriendlyMessage,
      );
    } catch (e) {
      EmailLogger.error(
        'Unexpected error in cleanup endpoint',
        error: e,
      );
      
      return AuthCodeCleanupEndpointResponse.error(
        error: 'unexpected_error',
        message: 'Erro inesperado durante limpeza',
      );
    }
  }

  /// Endpoint: GET /auth/codes/cleanup/status
  /// 
  /// Gets the status of the automatic cleanup service
  /// 
  /// Response:
  /// - 200: { "success": true, "isRunning": true, "interval": "3600000ms", "message": "Cleanup service status retrieved" }
  Future<AuthCodeCleanupStatusResponse> getCleanupStatus() async {
    try {
      return AuthCodeCleanupStatusResponse.success(
        isRunning: _cleanupService.isRunning,
        interval: _cleanupService.cleanupInterval,
        message: _cleanupService.isRunning 
            ? 'Serviço de limpeza automática ativo'
            : 'Serviço de limpeza automática inativo',
      );
    } catch (e) {
      EmailLogger.error(
        'Error getting cleanup status',
        error: e,
      );
      
      return AuthCodeCleanupStatusResponse.error(
        message: 'Erro ao obter status do serviço',
      );
    }
  }

  /// Disposes of the controller and its services
  void dispose() {
    _cleanupService.dispose();
    EmailLogger.info('Authentication code controller disposed');
  }
}

/// Response model for authentication code validation endpoints
class AuthCodeEndpointResponse {
  final bool success;
  final int statusCode;
  final String? userId;
  final AuthCodeType? codeType;
  final String message;
  final String? error;

  const AuthCodeEndpointResponse._({
    required this.success,
    required this.statusCode,
    this.userId,
    this.codeType,
    required this.message,
    this.error,
  });

  /// Creates a successful response (200)
  factory AuthCodeEndpointResponse.success({
    required String message,
    required String userId,
    required AuthCodeType codeType,
  }) {
    return AuthCodeEndpointResponse._(
      success: true,
      statusCode: 200,
      userId: userId,
      codeType: codeType,
      message: message,
    );
  }

  /// Creates a bad request response (400)
  factory AuthCodeEndpointResponse.badRequest({
    required String error,
    required String message,
  }) {
    return AuthCodeEndpointResponse._(
      success: false,
      statusCode: 400,
      message: message,
      error: error,
    );
  }

  /// Creates an internal server error response (500)
  factory AuthCodeEndpointResponse.internalError({
    required String error,
    required String message,
  }) {
    return AuthCodeEndpointResponse._(
      success: false,
      statusCode: 500,
      message: message,
      error: error,
    );
  }

  /// Converts to JSON-like map for API responses
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'success': success,
      'message': message,
    };

    if (success) {
      json['userId'] = userId;
      json['codeType'] = codeType?.value;
    } else {
      json['error'] = error;
    }

    return json;
  }
}

/// Response model for authentication code status endpoints
class AuthCodeStatusEndpointResponse {
  final bool success;
  final int statusCode;
  final bool found;
  final AuthCode? authCode;
  final bool? isValid;
  final bool? isExpired;
  final bool? isUsed;
  final String message;
  final String? error;

  const AuthCodeStatusEndpointResponse._({
    required this.success,
    required this.statusCode,
    required this.found,
    this.authCode,
    this.isValid,
    this.isExpired,
    this.isUsed,
    required this.message,
    this.error,
  });

  /// Creates a found response (200)
  factory AuthCodeStatusEndpointResponse.found({
    required AuthCode authCode,
    required bool isValid,
    required bool isExpired,
    required bool isUsed,
    required String message,
  }) {
    return AuthCodeStatusEndpointResponse._(
      success: true,
      statusCode: 200,
      found: true,
      authCode: authCode,
      isValid: isValid,
      isExpired: isExpired,
      isUsed: isUsed,
      message: message,
    );
  }

  /// Creates a not found response (404)
  factory AuthCodeStatusEndpointResponse.notFound({
    required String message,
  }) {
    return AuthCodeStatusEndpointResponse._(
      success: false,
      statusCode: 404,
      found: false,
      message: message,
    );
  }

  /// Creates an error response (500)
  factory AuthCodeStatusEndpointResponse.error({
    required String message,
  }) {
    return AuthCodeStatusEndpointResponse._(
      success: false,
      statusCode: 500,
      found: false,
      message: message,
      error: 'system_error',
    );
  }

  /// Converts to JSON-like map for API responses
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'success': success,
      'found': found,
      'message': message,
    };

    if (found && authCode != null) {
      json['codeType'] = authCode!.type.value;
      json['isValid'] = isValid;
      json['isExpired'] = isExpired;
      json['isUsed'] = isUsed;
      json['createdAt'] = authCode!.createdAt.toIso8601String();
      json['expiresAt'] = authCode!.expiresAt.toIso8601String();
    }

    if (!success && error != null) {
      json['error'] = error;
    }

    return json;
  }
}

/// Response model for cleanup endpoints
class AuthCodeCleanupEndpointResponse {
  final bool success;
  final int statusCode;
  final int? cleanedCount;
  final Duration? duration;
  final String message;
  final String? error;

  const AuthCodeCleanupEndpointResponse._({
    required this.success,
    required this.statusCode,
    this.cleanedCount,
    this.duration,
    required this.message,
    this.error,
  });

  /// Creates a successful cleanup response (200)
  factory AuthCodeCleanupEndpointResponse.success({
    required int cleanedCount,
    required Duration duration,
    required String message,
  }) {
    return AuthCodeCleanupEndpointResponse._(
      success: true,
      statusCode: 200,
      cleanedCount: cleanedCount,
      duration: duration,
      message: message,
    );
  }

  /// Creates an error cleanup response (500)
  factory AuthCodeCleanupEndpointResponse.error({
    required String error,
    required String message,
  }) {
    return AuthCodeCleanupEndpointResponse._(
      success: false,
      statusCode: 500,
      message: message,
      error: error,
    );
  }

  /// Converts to JSON-like map for API responses
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'success': success,
      'message': message,
    };

    if (success) {
      json['cleanedCount'] = cleanedCount;
      json['duration'] = '${duration?.inMilliseconds}ms';
    } else {
      json['error'] = error;
    }

    return json;
  }
}

/// Response model for cleanup status endpoints
class AuthCodeCleanupStatusResponse {
  final bool success;
  final bool? isRunning;
  final Duration? interval;
  final String message;

  const AuthCodeCleanupStatusResponse._({
    required this.success,
    this.isRunning,
    this.interval,
    required this.message,
  });

  /// Creates a successful status response
  factory AuthCodeCleanupStatusResponse.success({
    required bool isRunning,
    Duration? interval,
    required String message,
  }) {
    return AuthCodeCleanupStatusResponse._(
      success: true,
      isRunning: isRunning,
      interval: interval,
      message: message,
    );
  }

  /// Creates an error status response
  factory AuthCodeCleanupStatusResponse.error({
    required String message,
  }) {
    return AuthCodeCleanupStatusResponse._(
      success: false,
      message: message,
    );
  }

  /// Converts to JSON-like map for API responses
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'success': success,
      'message': message,
    };

    if (success) {
      json['isRunning'] = isRunning;
      if (interval != null) {
        json['interval'] = '${interval!.inMilliseconds}ms';
      }
    }

    return json;
  }
}
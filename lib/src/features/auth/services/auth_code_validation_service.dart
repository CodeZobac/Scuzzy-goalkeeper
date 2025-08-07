import '../data/repositories/auth_code_repository.dart';
import '../data/models/auth_code.dart';
import '../../../core/exceptions/email_service_exception.dart';
import '../../../core/services/email_logger.dart';
import '../../../core/services/email_error_handler.dart';

/// Centralized service for authentication code validation endpoints
/// 
/// This service provides validation endpoints for email confirmation and password reset
/// authentication codes with proper error handling and cleanup functionality.
class AuthCodeValidationService {
  final AuthCodeRepository _authCodeRepository;

  AuthCodeValidationService({
    AuthCodeRepository? authCodeRepository,
  }) : _authCodeRepository = authCodeRepository ?? AuthCodeRepository();

  /// Validates an email confirmation code
  /// 
  /// This endpoint validates the authentication code for email confirmation
  /// and provides detailed error responses for different failure scenarios.
  /// 
  /// [code] The authentication code from the email confirmation link
  /// 
  /// Returns [AuthCodeValidationResult] with validation status and details
  Future<AuthCodeValidationResult> validateEmailConfirmationCode(String code) async {
    EmailLogger.logAuthCodeOperation(
      operation: 'validateEmailConfirmationCode',
      codeType: AuthCodeType.emailConfirmation.value,
    );

    try {
      // Validate input
      if (code.isEmpty) {
        final result = AuthCodeValidationResult.invalid(
          'Código de confirmação não pode estar vazio',
          AuthCodeValidationErrorType.emptyCode,
        );
        
        EmailLogger.logAuthCodeOperation(
          operation: 'validateEmailConfirmationCode',
          codeType: AuthCodeType.emailConfirmation.value,
          success: false,
          errorMessage: result.errorMessage,
        );
        
        return result;
      }

      // Validate the authentication code
      final authCode = await _authCodeRepository.validateAuthCode(
        code,
        AuthCodeType.emailConfirmation,
      );

      if (authCode == null) {
        // Check specific failure reasons
        final failureReason = await _determineValidationFailureReason(
          code, 
          AuthCodeType.emailConfirmation,
        );
        
        EmailLogger.logAuthCodeOperation(
          operation: 'validateEmailConfirmationCode',
          codeType: AuthCodeType.emailConfirmation.value,
          success: false,
          errorMessage: failureReason.errorMessage,
        );
        
        return failureReason;
      }

      // Mark the code as used to prevent reuse
      await _authCodeRepository.invalidateAuthCode(code);

      final result = AuthCodeValidationResult.success(authCode);
      
      EmailLogger.logAuthCodeOperation(
        operation: 'validateEmailConfirmationCode',
        codeType: AuthCodeType.emailConfirmation.value,
        userId: authCode.userId,
        success: true,
      );

      EmailLogger.info(
        'Email confirmation code validated successfully',
        context: {
          'userId': authCode.userId,
          'codeId': authCode.id,
        },
      );

      return result;
    } catch (e) {
      final result = AuthCodeValidationResult.error(
        'Erro interno ao validar código de confirmação',
        AuthCodeValidationErrorType.systemError,
        e,
      );
      
      EmailLogger.error(
        'System error during email confirmation code validation',
        error: e,
      );
      
      EmailLogger.logAuthCodeOperation(
        operation: 'validateEmailConfirmationCode',
        codeType: AuthCodeType.emailConfirmation.value,
        success: false,
        errorMessage: result.errorMessage,
      );
      
      return result;
    }
  }

  /// Validates a password reset code
  /// 
  /// This endpoint validates the authentication code for password reset
  /// and provides detailed error responses for different failure scenarios.
  /// 
  /// [code] The authentication code from the password reset email link
  /// 
  /// Returns [AuthCodeValidationResult] with validation status and details
  Future<AuthCodeValidationResult> validatePasswordResetCode(String code) async {
    EmailLogger.logAuthCodeOperation(
      operation: 'validatePasswordResetCode',
      codeType: AuthCodeType.passwordReset.value,
    );

    try {
      // Validate input
      if (code.isEmpty) {
        final result = AuthCodeValidationResult.invalid(
          'Código de recuperação não pode estar vazio',
          AuthCodeValidationErrorType.emptyCode,
        );
        
        EmailLogger.logAuthCodeOperation(
          operation: 'validatePasswordResetCode',
          codeType: AuthCodeType.passwordReset.value,
          success: false,
          errorMessage: result.errorMessage,
        );
        
        return result;
      }

      // Validate the authentication code
      final authCode = await _authCodeRepository.validateAuthCode(
        code,
        AuthCodeType.passwordReset,
      );

      if (authCode == null) {
        // Check specific failure reasons
        final failureReason = await _determineValidationFailureReason(
          code, 
          AuthCodeType.passwordReset,
        );
        
        EmailLogger.logAuthCodeOperation(
          operation: 'validatePasswordResetCode',
          codeType: AuthCodeType.passwordReset.value,
          success: false,
          errorMessage: failureReason.errorMessage,
        );
        
        return failureReason;
      }

      // Mark the code as used to prevent reuse
      await _authCodeRepository.invalidateAuthCode(code);

      final result = AuthCodeValidationResult.success(authCode);
      
      EmailLogger.logAuthCodeOperation(
        operation: 'validatePasswordResetCode',
        codeType: AuthCodeType.passwordReset.value,
        userId: authCode.userId,
        success: true,
      );

      EmailLogger.info(
        'Password reset code validated successfully',
        context: {
          'userId': authCode.userId,
          'codeId': authCode.id,
        },
      );

      return result;
    } catch (e) {
      final result = AuthCodeValidationResult.error(
        'Erro interno ao validar código de recuperação',
        AuthCodeValidationErrorType.systemError,
        e,
      );
      
      EmailLogger.error(
        'System error during password reset code validation',
        error: e,
      );
      
      EmailLogger.logAuthCodeOperation(
        operation: 'validatePasswordResetCode',
        codeType: AuthCodeType.passwordReset.value,
        success: false,
        errorMessage: result.errorMessage,
      );
      
      return result;
    }
  }

  /// Determines the specific reason why code validation failed
  /// 
  /// This method provides detailed error information for failed validations
  /// by checking if the code exists, is expired, or is already used.
  Future<AuthCodeValidationResult> _determineValidationFailureReason(
    String code, 
    AuthCodeType type,
  ) async {
    try {
      // Try to find the code by plain text (this checks all codes, including used/expired ones)
      final authCode = await _authCodeRepository.getAuthCode(code);
      
      if (authCode == null) {
        // Code doesn't exist at all
        return AuthCodeValidationResult.invalid(
          type == AuthCodeType.emailConfirmation
              ? 'Código de confirmação inválido'
              : 'Código de recuperação inválido',
          AuthCodeValidationErrorType.invalidCode,
        );
      }

      // Check if code is for the wrong type
      if (authCode.type != type) {
        return AuthCodeValidationResult.invalid(
          type == AuthCodeType.emailConfirmation
              ? 'Código de confirmação inválido'
              : 'Código de recuperação inválido',
          AuthCodeValidationErrorType.invalidCode,
        );
      }

      // Check if code is already used
      if (authCode.isUsed) {
        return AuthCodeValidationResult.invalid(
          type == AuthCodeType.emailConfirmation
              ? 'Código de confirmação já foi utilizado'
              : 'Código de recuperação já foi utilizado',
          AuthCodeValidationErrorType.alreadyUsed,
        );
      }

      // Check if code is expired
      if (authCode.isExpired) {
        return AuthCodeValidationResult.invalid(
          type == AuthCodeType.emailConfirmation
              ? 'Código de confirmação expirou. Solicite um novo código.'
              : 'Código de recuperação expirou. Solicite um novo código.',
          AuthCodeValidationErrorType.expired,
        );
      }

      // If we get here, there's some other validation issue
      return AuthCodeValidationResult.invalid(
        type == AuthCodeType.emailConfirmation
            ? 'Código de confirmação inválido'
            : 'Código de recuperação inválido',
        AuthCodeValidationErrorType.invalidCode,
      );
    } catch (e) {
      return AuthCodeValidationResult.error(
        'Erro ao verificar código',
        AuthCodeValidationErrorType.systemError,
        e,
      );
    }
  }

  /// Cleanup service for expired authentication codes
  /// 
  /// This service removes expired authentication codes from the database
  /// to maintain database performance and security.
  /// 
  /// Returns [AuthCodeCleanupResult] with cleanup statistics
  Future<AuthCodeCleanupResult> cleanupExpiredCodes() async {
    EmailLogger.logAuthCodeOperation(
      operation: 'cleanupExpiredCodes',
      codeType: 'all',
    );

    try {
      final stopwatch = Stopwatch()..start();
      
      // Perform cleanup
      final cleanedCount = await _authCodeRepository.cleanupExpiredCodes();
      
      stopwatch.stop();
      
      final result = AuthCodeCleanupResult.success(
        cleanedCount,
        stopwatch.elapsed,
      );
      
      EmailLogger.logAuthCodeOperation(
        operation: 'cleanupExpiredCodes',
        codeType: 'all',
        success: true,
      );

      EmailLogger.info(
        'Authentication code cleanup completed',
        context: {
          'cleanedCount': cleanedCount,
          'duration': '${stopwatch.elapsed.inMilliseconds}ms',
        },
      );

      return result;
    } catch (e) {
      final result = AuthCodeCleanupResult.error(
        'Erro ao limpar códigos expirados',
        e,
      );
      
      EmailLogger.error(
        'Error during authentication code cleanup',
        error: e,
      );
      
      EmailLogger.logAuthCodeOperation(
        operation: 'cleanupExpiredCodes',
        codeType: 'all',
        success: false,
        errorMessage: result.errorMessage,
      );
      
      return result;
    }
  }

  /// Validates any authentication code and returns detailed information
  /// 
  /// This is a generic validation endpoint that can handle both email confirmation
  /// and password reset codes, automatically detecting the type.
  /// 
  /// [code] The authentication code to validate
  /// 
  /// Returns [AuthCodeValidationResult] with validation status and details
  Future<AuthCodeValidationResult> validateAnyAuthCode(String code) async {
    EmailLogger.logAuthCodeOperation(
      operation: 'validateAnyAuthCode',
      codeType: 'unknown',
    );

    try {
      // Validate input
      if (code.isEmpty) {
        final result = AuthCodeValidationResult.invalid(
          'Código de autenticação não pode estar vazio',
          AuthCodeValidationErrorType.emptyCode,
        );
        
        EmailLogger.logAuthCodeOperation(
          operation: 'validateAnyAuthCode',
          codeType: 'unknown',
          success: false,
          errorMessage: result.errorMessage,
        );
        
        return result;
      }

      // Try to find the code to determine its type
      final authCode = await _authCodeRepository.getAuthCode(code);
      
      if (authCode == null) {
        final result = AuthCodeValidationResult.invalid(
          'Código de autenticação inválido',
          AuthCodeValidationErrorType.invalidCode,
        );
        
        EmailLogger.logAuthCodeOperation(
          operation: 'validateAnyAuthCode',
          codeType: 'unknown',
          success: false,
          errorMessage: result.errorMessage,
        );
        
        return result;
      }

      // Delegate to the appropriate specific validation method
      switch (authCode.type) {
        case AuthCodeType.emailConfirmation:
          return await validateEmailConfirmationCode(code);
        case AuthCodeType.passwordReset:
          return await validatePasswordResetCode(code);
      }
    } catch (e) {
      final result = AuthCodeValidationResult.error(
        'Erro interno ao validar código',
        AuthCodeValidationErrorType.systemError,
        e,
      );
      
      EmailLogger.error(
        'System error during generic code validation',
        error: e,
      );
      
      EmailLogger.logAuthCodeOperation(
        operation: 'validateAnyAuthCode',
        codeType: 'unknown',
        success: false,
        errorMessage: result.errorMessage,
      );
      
      return result;
    }
  }

  /// Checks if a specific authentication code exists and returns its status
  /// 
  /// This endpoint provides information about a code without validating or consuming it.
  /// Useful for checking code status before attempting validation.
  /// 
  /// [code] The authentication code to check
  /// 
  /// Returns [AuthCodeStatusResult] with code status information
  Future<AuthCodeStatusResult> getAuthCodeStatus(String code) async {
    try {
      // Validate input
      if (code.isEmpty) {
        return AuthCodeStatusResult.notFound('Código não pode estar vazio');
      }

      // Try to find the code
      final authCode = await _authCodeRepository.getAuthCode(code);
      
      if (authCode == null) {
        return AuthCodeStatusResult.notFound('Código não encontrado');
      }

      // Return status information
      return AuthCodeStatusResult.found(
        authCode: authCode,
        isValid: authCode.isValid,
        isExpired: authCode.isExpired,
        isUsed: authCode.isUsed,
      );
    } catch (e) {
      return AuthCodeStatusResult.error('Erro ao verificar status do código', e);
    }
  }
}

/// Result of authentication code validation
class AuthCodeValidationResult {
  final bool isSuccess;
  final AuthCode? authCode;
  final String? errorMessage;
  final AuthCodeValidationErrorType? errorType;
  final dynamic originalError;

  const AuthCodeValidationResult._({
    required this.isSuccess,
    this.authCode,
    this.errorMessage,
    this.errorType,
    this.originalError,
  });

  /// Creates a successful validation result
  factory AuthCodeValidationResult.success(AuthCode authCode) {
    return AuthCodeValidationResult._(
      isSuccess: true,
      authCode: authCode,
    );
  }

  /// Creates an invalid code validation result
  factory AuthCodeValidationResult.invalid(
    String errorMessage,
    AuthCodeValidationErrorType errorType,
  ) {
    return AuthCodeValidationResult._(
      isSuccess: false,
      errorMessage: errorMessage,
      errorType: errorType,
    );
  }

  /// Creates an error validation result
  factory AuthCodeValidationResult.error(
    String errorMessage,
    AuthCodeValidationErrorType errorType,
    dynamic originalError,
  ) {
    return AuthCodeValidationResult._(
      isSuccess: false,
      errorMessage: errorMessage,
      errorType: errorType,
      originalError: originalError,
    );
  }

  /// Gets user-friendly error message for display
  String get userFriendlyMessage {
    if (isSuccess) return 'Código validado com sucesso';
    return errorMessage ?? 'Erro desconhecido';
  }

  /// Checks if the error is retryable
  bool get isRetryable {
    return errorType == AuthCodeValidationErrorType.systemError;
  }
}

/// Types of authentication code validation errors
enum AuthCodeValidationErrorType {
  emptyCode,
  invalidCode,
  expired,
  alreadyUsed,
  systemError,
}

/// Result of authentication code cleanup operation
class AuthCodeCleanupResult {
  final bool isSuccess;
  final int? cleanedCount;
  final Duration? duration;
  final String? errorMessage;
  final dynamic originalError;

  const AuthCodeCleanupResult._({
    required this.isSuccess,
    this.cleanedCount,
    this.duration,
    this.errorMessage,
    this.originalError,
  });

  /// Creates a successful cleanup result
  factory AuthCodeCleanupResult.success(int cleanedCount, Duration duration) {
    return AuthCodeCleanupResult._(
      isSuccess: true,
      cleanedCount: cleanedCount,
      duration: duration,
    );
  }

  /// Creates an error cleanup result
  factory AuthCodeCleanupResult.error(String errorMessage, dynamic originalError) {
    return AuthCodeCleanupResult._(
      isSuccess: false,
      errorMessage: errorMessage,
      originalError: originalError,
    );
  }

  /// Gets user-friendly message for display
  String get userFriendlyMessage {
    if (isSuccess) {
      return 'Limpeza concluída: $cleanedCount códigos removidos';
    }
    return errorMessage ?? 'Erro na limpeza';
  }
}

/// Result of authentication code status check
class AuthCodeStatusResult {
  final bool isFound;
  final AuthCode? authCode;
  final bool? isValid;
  final bool? isExpired;
  final bool? isUsed;
  final String? message;
  final dynamic originalError;

  const AuthCodeStatusResult._({
    required this.isFound,
    this.authCode,
    this.isValid,
    this.isExpired,
    this.isUsed,
    this.message,
    this.originalError,
  });

  /// Creates a found status result
  factory AuthCodeStatusResult.found({
    required AuthCode authCode,
    required bool isValid,
    required bool isExpired,
    required bool isUsed,
  }) {
    return AuthCodeStatusResult._(
      isFound: true,
      authCode: authCode,
      isValid: isValid,
      isExpired: isExpired,
      isUsed: isUsed,
    );
  }

  /// Creates a not found status result
  factory AuthCodeStatusResult.notFound(String message) {
    return AuthCodeStatusResult._(
      isFound: false,
      message: message,
    );
  }

  /// Creates an error status result
  factory AuthCodeStatusResult.error(String message, dynamic originalError) {
    return AuthCodeStatusResult._(
      isFound: false,
      message: message,
      originalError: originalError,
    );
  }

  /// Gets user-friendly status message
  String get statusMessage {
    if (!isFound) return message ?? 'Código não encontrado';
    
    if (isUsed == true) return 'Código já foi utilizado';
    if (isExpired == true) return 'Código expirado';
    if (isValid == true) return 'Código válido';
    
    return 'Status desconhecido';
  }
}
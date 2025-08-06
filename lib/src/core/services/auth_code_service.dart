import '../../../features/auth/data/models/auth_code.dart';
import '../../../features/auth/data/repositories/auth_code_repository.dart';
import 'secure_code_generator.dart';

/// Service for managing authentication codes with security and validation
class AuthCodeService {
  final AuthCodeRepository _repository;
  final SecureCodeGenerator _codeGenerator;

  AuthCodeService({
    AuthCodeRepository? repository,
    SecureCodeGenerator? codeGenerator,
  }) : _repository = repository ?? AuthCodeRepository(),
       _codeGenerator = codeGenerator ?? SecureCodeGenerator();

  /// Generates and stores a new authentication code for a user
  /// 
  /// This method:
  /// 1. Invalidates any existing codes for the user and type
  /// 2. Generates a cryptographically secure 32-character code
  /// 3. Hashes the code before database storage
  /// 4. Sets expiration time (default 5 minutes)
  /// 
  /// [userId] The ID of the user requesting the code
  /// [type] The type of authentication code (email confirmation or password reset)
  /// [expirationDuration] How long the code should be valid (default 5 minutes)
  /// 
  /// Returns the plain text code that should be sent to the user
  Future<String> generateAuthCode(
    String userId,
    AuthCodeType type, {
    Duration? expirationDuration,
  }) async {
    try {
      // Generate and store the code (this automatically invalidates existing codes)
      final plainCode = await _repository.storeUniqueAuthCode(
        userId,
        type,
        expirationDuration: expirationDuration ?? const Duration(minutes: 5),
      );

      return plainCode;
    } catch (e) {
      throw AuthCodeServiceException(
        'Failed to generate authentication code: $e',
        AuthCodeServiceErrorType.generationError,
        e,
      );
    }
  }

  /// Validates an authentication code with comprehensive security checks
  /// 
  /// This method performs the following validations:
  /// 1. Verifies the code exists and matches the stored hash
  /// 2. Checks that the code has not expired
  /// 3. Ensures the code has not been used before
  /// 4. Validates the code type matches the expected type
  /// 
  /// [plainCode] The plain text code provided by the user
  /// [type] The expected type of authentication code
  /// 
  /// Returns the AuthCode if valid, null if invalid/expired/used
  Future<AuthCode?> validateAuthCode(String plainCode, AuthCodeType type) async {
    try {
      // Validate the code through the repository
      final authCode = await _repository.validateAuthCode(plainCode, type);
      
      if (authCode == null) {
        return null; // Code is invalid, expired, or already used
      }

      // Additional validation checks
      if (authCode.isUsed) {
        throw AuthCodeServiceException(
          'Authentication code has already been used',
          AuthCodeServiceErrorType.alreadyUsed,
        );
      }

      if (authCode.isExpired) {
        throw AuthCodeServiceException(
          'Authentication code has expired',
          AuthCodeServiceErrorType.expired,
        );
      }

      if (authCode.type != type) {
        throw AuthCodeServiceException(
          'Authentication code type mismatch',
          AuthCodeServiceErrorType.typeMismatch,
        );
      }

      return authCode;
    } catch (e) {
      if (e is AuthCodeServiceException) {
        rethrow;
      }
      
      throw AuthCodeServiceException(
        'Failed to validate authentication code: $e',
        AuthCodeServiceErrorType.validationError,
        e,
      );
    }
  }

  /// Validates and consumes an authentication code in a single operation
  /// 
  /// This method:
  /// 1. Validates the code using all security checks
  /// 2. If valid, immediately marks it as used to prevent reuse
  /// 3. Returns the validated AuthCode
  /// 
  /// This is the recommended method for code validation as it ensures
  /// one-time use enforcement.
  /// 
  /// [plainCode] The plain text code provided by the user
  /// [type] The expected type of authentication code
  /// 
  /// Returns the AuthCode if valid and successfully consumed, null if invalid
  Future<AuthCode?> validateAndConsumeAuthCode(String plainCode, AuthCodeType type) async {
    try {
      // First validate the code
      final authCode = await validateAuthCode(plainCode, type);
      
      if (authCode == null) {
        return null;
      }

      // Mark the code as used
      await _repository.invalidateAuthCode(plainCode);

      // Return the validated code
      return authCode;
    } catch (e) {
      if (e is AuthCodeServiceException) {
        rethrow;
      }
      
      throw AuthCodeServiceException(
        'Failed to validate and consume authentication code: $e',
        AuthCodeServiceErrorType.validationError,
        e,
      );
    }
  }

  /// Invalidates all unused authentication codes for a specific user and type
  /// 
  /// This is useful when:
  /// - A user requests a new code (invalidate old ones)
  /// - A user successfully completes authentication (cleanup)
  /// - Administrative cleanup is needed
  /// 
  /// [userId] The ID of the user whose codes should be invalidated
  /// [type] The type of codes to invalidate
  Future<void> invalidateUserCodes(String userId, AuthCodeType type) async {
    try {
      await _repository.invalidateUserCodes(userId, type);
    } catch (e) {
      throw AuthCodeServiceException(
        'Failed to invalidate user authentication codes: $e',
        AuthCodeServiceErrorType.invalidationError,
        e,
      );
    }
  }

  /// Retrieves all authentication codes for a user (for debugging/admin purposes)
  /// 
  /// Note: This returns codes with hashed values, not plain text
  /// 
  /// [userId] The ID of the user
  /// [type] The type of codes to retrieve
  Future<List<AuthCode>> getUserCodes(String userId, AuthCodeType type) async {
    try {
      return await _repository.getAuthCodesForUser(userId, type);
    } catch (e) {
      throw AuthCodeServiceException(
        'Failed to retrieve user authentication codes: $e',
        AuthCodeServiceErrorType.retrievalError,
        e,
      );
    }
  }

  /// Cleans up expired authentication codes from the database
  /// 
  /// This should be called periodically to maintain database hygiene.
  /// Returns the number of codes that were cleaned up.
  Future<int> cleanupExpiredCodes() async {
    try {
      return await _repository.cleanupExpiredCodes();
    } catch (e) {
      throw AuthCodeServiceException(
        'Failed to cleanup expired authentication codes: $e',
        AuthCodeServiceErrorType.cleanupError,
        e,
      );
    }
  }

  /// Checks if a plain text code is valid without consuming it
  /// 
  /// This is useful for preview/validation scenarios where you don't
  /// want to consume the code yet.
  /// 
  /// [plainCode] The plain text code to check
  /// [type] The expected type of authentication code
  /// 
  /// Returns true if the code is valid, false otherwise
  Future<bool> isCodeValid(String plainCode, AuthCodeType type) async {
    try {
      final authCode = await validateAuthCode(plainCode, type);
      return authCode != null;
    } catch (e) {
      return false; // Any exception means the code is not valid
    }
  }
}

/// Exception thrown by AuthCodeService operations
class AuthCodeServiceException implements Exception {
  final String message;
  final AuthCodeServiceErrorType type;
  final dynamic originalError;

  const AuthCodeServiceException(
    this.message,
    this.type, [
    this.originalError,
  ]);

  @override
  String toString() => 'AuthCodeServiceException: $message';
}

/// Types of errors that can occur in AuthCodeService
enum AuthCodeServiceErrorType {
  generationError,
  validationError,
  invalidationError,
  retrievalError,
  cleanupError,
  expired,
  alreadyUsed,
  typeMismatch,
  notFound,
}
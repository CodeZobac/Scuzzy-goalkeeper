import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/service_locator.dart';
import '../../../core/services/azure_email_service.dart';
import '../../../core/services/auth_code_service.dart';
import '../../../core/models/email_response.dart';
import '../data/models/auth_code.dart';
import '../../../core/exceptions/email_service_exception.dart';
import '../../../core/services/email_logger.dart';

/// Service for handling password reset using Azure Communication Services
/// 
/// This service integrates with the existing Supabase Auth password reset flow
/// to provide password reset functionality using Azure email service.
class PasswordResetService {
  final AzureEmailService _emailService;
  final AuthCodeService _authCodeService;
  final SupabaseClient _supabase;

  PasswordResetService({
    AzureEmailService? emailService,
    AuthCodeService? authCodeService,
    SupabaseClient? supabase,
  }) : _emailService = emailService ?? ServiceLocator.instance.azureEmailService,
       _authCodeService = authCodeService ?? ServiceLocator.instance.authCodeService,
       _supabase = supabase ?? Supabase.instance.client;

  /// Sends a password reset email
  /// 
  /// This method integrates with the existing password reset flow by:
  /// 1. Generating a secure authentication code
  /// 2. Sending the reset email via Azure Communication Services
  /// 3. Storing the code for later validation
  /// 
  /// [email] The user's email address
  /// [userId] The user's ID from Supabase Auth
  /// 
  /// Returns the email response from Azure Communication Services
  Future<EmailResponse> sendPasswordResetEmail(
    String email,
    String userId,
  ) async {
    final stopwatch = Stopwatch()..start();
    
    EmailLogger.logEmailOperation(
      operation: 'sendPasswordResetEmail',
      emailType: 'password_reset',
      recipientEmail: email,
      userId: userId,
    );

    try {
      EmailLogger.info(
        'Starting password reset process',
        context: {
          'email': email,
          'userId': userId,
        },
      );

      // Generate authentication code
      EmailLogger.debug('Generating authentication code');
      final authCode = await _authCodeService.generateAuthCode(
        userId,
        AuthCodeType.passwordReset,
        expirationDuration: const Duration(minutes: 5),
      );

      EmailLogger.debug(
        'Authentication code generated successfully',
        context: {
          'codeLength': authCode.length,
          'expirationMinutes': 5,
        },
      );

      // Send password reset email
      EmailLogger.debug('Sending password reset email via Azure Communication Services');
      final emailResponse = await _emailService.sendPasswordResetEmail(
        email,
        userId,
        authCode,
      );

      stopwatch.stop();
      
      EmailLogger.logEmailOperation(
        operation: 'sendPasswordResetEmail',
        emailType: 'password_reset',
        recipientEmail: email,
        userId: userId,
        success: true,
        duration: stopwatch.elapsed,
      );

      EmailLogger.info(
        'Password reset email sent successfully',
        context: {
          'messageId': emailResponse.messageId,
          'duration': '${stopwatch.elapsedMilliseconds}ms',
        },
      );

      return emailResponse;
    } catch (e) {
      stopwatch.stop();
      
      final exception = e is EmailServiceException 
          ? e 
          : EmailServiceException(
              'Failed to send password reset email: $e',
              EmailServiceErrorType.unknownError,
              e,
            );

      EmailLogger.error(
        'Password reset email failed',
        error: exception,
        context: {
          'email': email,
          'userId': userId,
          'duration': '${stopwatch.elapsedMilliseconds}ms',
        },
      );

      EmailLogger.logEmailOperation(
        operation: 'sendPasswordResetEmail',
        emailType: 'password_reset',
        recipientEmail: email,
        userId: userId,
        success: false,
        errorMessage: exception.message,
        duration: stopwatch.elapsed,
      );

      throw exception;
    }
  }

  /// Validates a password reset code
  /// 
  /// This method validates the authentication code without consuming it.
  /// Use this to check if a code is valid before allowing password reset.
  /// 
  /// [code] The authentication code from the email
  /// 
  /// Returns the AuthCode if valid, null otherwise
  Future<AuthCode?> validatePasswordResetCode(String code) async {
    final stopwatch = Stopwatch()..start();
    
    EmailLogger.logAuthCodeOperation(
      operation: 'validatePasswordResetCode',
      codeType: AuthCodeType.passwordReset.value,
    );

    try {
      EmailLogger.info(
        'Validating password reset code',
        context: {
          'codeLength': code.length,
        },
      );

      // Validate the authentication code (without consuming it)
      EmailLogger.debug('Validating authentication code');
      final authCode = await _authCodeService.validateAuthCode(
        code,
        AuthCodeType.passwordReset,
      );

      stopwatch.stop();

      if (authCode == null) {
        EmailLogger.warning(
          'Password reset code validation failed: Invalid or expired code',
          context: {
            'codeLength': code.length,
            'duration': '${stopwatch.elapsedMilliseconds}ms',
          },
        );

        EmailLogger.logAuthCodeOperation(
          operation: 'validatePasswordResetCode',
          codeType: AuthCodeType.passwordReset.value,
          success: false,
          errorMessage: 'Invalid or expired code',
        );

        return null;
      }

      EmailLogger.debug(
        'Password reset code validated successfully',
        context: {
          'userId': authCode.userId,
          'codeId': authCode.id,
          'duration': '${stopwatch.elapsedMilliseconds}ms',
        },
      );

      EmailLogger.logAuthCodeOperation(
        operation: 'validatePasswordResetCode',
        codeType: AuthCodeType.passwordReset.value,
        userId: authCode.userId,
        success: true,
      );

      return authCode;
    } catch (e) {
      stopwatch.stop();

      EmailLogger.error(
        'Password reset code validation failed',
        error: e,
        context: {
          'codeLength': code.length,
          'duration': '${stopwatch.elapsedMilliseconds}ms',
        },
      );

      EmailLogger.logAuthCodeOperation(
        operation: 'validatePasswordResetCode',
        codeType: AuthCodeType.passwordReset.value,
        success: false,
        errorMessage: e.toString(),
      );

      return null;
    }
  }

  /// Completes the password reset process
  /// 
  /// This method:
  /// 1. Validates and consumes the authentication code
  /// 2. Updates the user's password in Supabase Auth
  /// 3. Invalidates the code to prevent reuse
  /// 
  /// [code] The authentication code from the email
  /// [newPassword] The new password to set
  /// 
  /// Returns true if password reset was successful, false otherwise
  Future<bool> resetPassword(String code, String newPassword) async {
    final stopwatch = Stopwatch()..start();
    
    EmailLogger.logAuthCodeOperation(
      operation: 'resetPassword',
      codeType: AuthCodeType.passwordReset.value,
    );

    try {
      EmailLogger.info(
        'Starting password reset completion',
        context: {
          'codeLength': code.length,
        },
      );

      // Validate and consume the authentication code
      EmailLogger.debug('Validating and consuming authentication code');
      final authCode = await _authCodeService.validateAndConsumeAuthCode(
        code,
        AuthCodeType.passwordReset,
      );

      if (authCode == null) {
        EmailLogger.warning(
          'Password reset failed: Invalid or expired code',
          context: {
            'codeLength': code.length,
          },
        );

        EmailLogger.logAuthCodeOperation(
          operation: 'resetPassword',
          codeType: AuthCodeType.passwordReset.value,
          success: false,
          errorMessage: 'Invalid or expired code',
        );

        return false;
      }

      EmailLogger.debug(
        'Authentication code validated and consumed successfully',
        context: {
          'userId': authCode.userId,
          'codeId': authCode.id,
        },
      );

      // Update user's password in Supabase Auth
      EmailLogger.debug('Updating user password in Supabase');
      await _updateUserPassword(authCode.userId, newPassword);

      stopwatch.stop();

      EmailLogger.logAuthCodeOperation(
        operation: 'resetPassword',
        codeType: AuthCodeType.passwordReset.value,
        userId: authCode.userId,
        success: true,
      );

      EmailLogger.info(
        'Password reset completed successfully',
        context: {
          'userId': authCode.userId,
          'duration': '${stopwatch.elapsedMilliseconds}ms',
        },
      );

      return true;
    } catch (e) {
      stopwatch.stop();

      EmailLogger.error(
        'Password reset completion failed',
        error: e,
        context: {
          'codeLength': code.length,
          'duration': '${stopwatch.elapsedMilliseconds}ms',
        },
      );

      EmailLogger.logAuthCodeOperation(
        operation: 'resetPassword',
        codeType: AuthCodeType.passwordReset.value,
        success: false,
        errorMessage: e.toString(),
      );

      // Don't throw the exception, just return false
      // This allows the UI to handle the failure gracefully
      return false;
    }
  }

  /// Updates the user's password in Supabase Auth
  Future<void> _updateUserPassword(String userId, String newPassword) async {
    try {
      // Update the user's password via admin API
      await _supabase.auth.admin.updateUserById(
        userId,
        attributes: AdminUserAttributes(
          password: newPassword,
        ),
      );

      EmailLogger.debug(
        'User password updated in Supabase via admin API',
        context: {
          'userId': userId,
        },
      );
    } catch (e) {
      // If we can't update via admin API, try alternative approach
      EmailLogger.warning(
        'Failed to update password via admin API, trying alternative approach',
        context: {
          'userId': userId,
          'error': e.toString(),
        },
      );

      // Alternative: Update password for current user if they match
      final user = await _supabase.auth.getUser();
      if (user.user?.id == userId) {
        await _supabase.auth.updateUser(
          UserAttributes(
            password: newPassword,
          ),
        );

        EmailLogger.debug(
          'User password updated via user update',
          context: {
            'userId': userId,
          },
        );
      } else {
        throw EmailServiceException(
          'Cannot update password: User not authenticated or ID mismatch',
          EmailServiceErrorType.authenticationError,
        );
      }
    }
  }

  /// Resends a password reset email for a user
  /// 
  /// This method invalidates any existing reset codes and sends a new one.
  /// 
  /// [email] The user's email address
  /// [userId] The user's ID from Supabase Auth
  /// 
  /// Returns the email response from Azure Communication Services
  Future<EmailResponse> resendPasswordResetEmail(
    String email,
    String userId,
  ) async {
    EmailLogger.info(
      'Resending password reset email',
      context: {
        'email': email,
        'userId': userId,
      },
    );

    try {
      // Invalidate any existing reset codes for this user
      await _authCodeService.invalidateUserCodes(
        userId,
        AuthCodeType.passwordReset,
      );

      EmailLogger.debug('Existing password reset codes invalidated');

      // Send new password reset email
      return await sendPasswordResetEmail(email, userId);
    } catch (e) {
      EmailLogger.error(
        'Failed to resend password reset email',
        error: e,
        context: {
          'email': email,
          'userId': userId,
        },
      );

      rethrow;
    }
  }

  /// Checks if a user has pending password reset codes
  /// 
  /// [userId] The user's ID from Supabase Auth
  /// 
  /// Returns true if there are valid, unexpired reset codes
  Future<bool> hasPendingPasswordReset(String userId) async {
    try {
      final codes = await _authCodeService.getUserCodes(
        userId,
        AuthCodeType.passwordReset,
      );

      // Check if any codes are still valid (not used and not expired)
      final validCodes = codes.where((code) => !code.isUsed && !code.isExpired);
      
      return validCodes.isNotEmpty;
    } catch (e) {
      EmailLogger.error(
        'Failed to check pending password reset status',
        error: e,
        context: {
          'userId': userId,
        },
      );

      return false;
    }
  }

  /// Initiates password reset by email lookup
  /// 
  /// This method looks up a user by email and initiates the password reset process.
  /// This is useful when you only have the email address and need to find the user.
  /// 
  /// [email] The user's email address
  /// 
  /// Returns the email response if successful, throws exception otherwise
  Future<EmailResponse> initiatePasswordResetByEmail(String email) async {
    try {
      EmailLogger.info(
        'Initiating password reset by email lookup',
        context: {
          'email': email,
        },
      );

      // Look up user by email
      // Note: This requires admin privileges or a custom function
      // For now, we'll assume the caller provides the userId
      throw EmailServiceException(
        'Password reset by email lookup requires user ID. Use sendPasswordResetEmail instead.',
        EmailServiceErrorType.validationError,
      );
    } catch (e) {
      EmailLogger.error(
        'Failed to initiate password reset by email',
        error: e,
        context: {
          'email': email,
        },
      );

      rethrow;
    }
  }

  /// Disposes of resources used by the service
  void dispose() {
    // No resources to dispose in this service
    // The underlying services are managed by the ServiceLocator
  }
}
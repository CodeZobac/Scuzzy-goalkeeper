import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/service_locator.dart';
import '../../../core/services/azure_email_service.dart';
import '../../../core/services/auth_code_service.dart';
import '../../../core/models/email_response.dart';
import '../data/models/auth_code.dart';
import '../../../core/exceptions/email_service_exception.dart';
import '../../../core/services/email_logger.dart';

/// Service for handling email confirmation using Azure Communication Services
/// 
/// This service integrates with the existing Supabase Auth signup flow
/// to provide email confirmation functionality using Azure email service.
class EmailConfirmationService {
  final AzureEmailService _emailService;
  final AuthCodeService _authCodeService;
  final SupabaseClient _supabase;

  EmailConfirmationService({
    AzureEmailService? emailService,
    AuthCodeService? authCodeService,
    SupabaseClient? supabase,
  }) : _emailService = emailService ?? ServiceLocator.instance.azureEmailService,
       _authCodeService = authCodeService ?? ServiceLocator.instance.authCodeService,
       _supabase = supabase ?? Supabase.instance.client;

  /// Sends a confirmation email for user signup
  /// 
  /// This method integrates with the existing signup flow by:
  /// 1. Generating a secure authentication code
  /// 2. Sending the confirmation email via Azure Communication Services
  /// 3. Storing the code for later validation
  /// 
  /// [email] The user's email address
  /// [userId] The user's ID from Supabase Auth
  /// 
  /// Returns the email response from Azure Communication Services
  Future<EmailResponse> sendConfirmationEmail(
    String email,
    String userId,
  ) async {
    final stopwatch = Stopwatch()..start();
    
    EmailLogger.logEmailOperation(
      operation: 'sendConfirmationEmail',
      emailType: 'email_confirmation',
      recipientEmail: email,
      userId: userId,
    );

    try {
      EmailLogger.info(
        'Starting email confirmation process',
        context: {
          'email': email,
          'userId': userId,
        },
      );

      // Generate authentication code
      EmailLogger.debug('Generating authentication code');
      final authCode = await _authCodeService.generateAuthCode(
        userId,
        AuthCodeType.emailConfirmation,
        expirationDuration: const Duration(minutes: 5),
      );

      EmailLogger.debug(
        'Authentication code generated successfully',
        context: {
          'codeLength': authCode.length,
          'expirationMinutes': 5,
        },
      );

      // Send confirmation email
      EmailLogger.debug('Sending confirmation email via Azure Communication Services');
      final emailResponse = await _emailService.sendConfirmationEmail(
        email,
        userId,
        authCode,
      );

      stopwatch.stop();
      
      EmailLogger.logEmailOperation(
        operation: 'sendConfirmationEmail',
        emailType: 'email_confirmation',
        recipientEmail: email,
        userId: userId,
        success: true,
        duration: stopwatch.elapsed,
      );

      EmailLogger.info(
        'Email confirmation sent successfully',
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
              'Failed to send confirmation email: $e',
              EmailServiceErrorType.unknownError,
              e,
            );

      EmailLogger.error(
        'Email confirmation failed',
        error: exception,
        context: {
          'email': email,
          'userId': userId,
          'duration': '${stopwatch.elapsedMilliseconds}ms',
        },
      );

      EmailLogger.logEmailOperation(
        operation: 'sendConfirmationEmail',
        emailType: 'email_confirmation',
        recipientEmail: email,
        userId: userId,
        success: false,
        errorMessage: exception.message,
        duration: stopwatch.elapsed,
      );

      throw exception;
    }
  }

  /// Validates a confirmation code without consuming it
  /// 
  /// This method validates the authentication code and returns the AuthCode
  /// if valid, without marking it as used. This is useful for checking
  /// code validity before processing.
  /// 
  /// [code] The authentication code from the email
  /// 
  /// Returns the AuthCode if valid, null otherwise
  Future<AuthCode?> validateConfirmationCode(String code) async {
    final stopwatch = Stopwatch()..start();
    
    EmailLogger.logAuthCodeOperation(
      operation: 'validateConfirmationCode',
      codeType: AuthCodeType.emailConfirmation.value,
    );

    try {
      EmailLogger.info(
        'Validating confirmation code',
        context: {
          'codeLength': code.length,
        },
      );

      // Validate the authentication code (without consuming it)
      EmailLogger.debug('Validating authentication code');
      final authCode = await _authCodeService.validateAuthCode(
        code,
        AuthCodeType.emailConfirmation,
      );

      stopwatch.stop();

      if (authCode == null) {
        EmailLogger.warning(
          'Confirmation code validation failed: Invalid or expired code',
          context: {
            'codeLength': code.length,
            'duration': '${stopwatch.elapsedMilliseconds}ms',
          },
        );

        EmailLogger.logAuthCodeOperation(
          operation: 'validateConfirmationCode',
          codeType: AuthCodeType.emailConfirmation.value,
          success: false,
          errorMessage: 'Invalid or expired code',
        );

        return null;
      }

      EmailLogger.debug(
        'Confirmation code validated successfully',
        context: {
          'userId': authCode.userId,
          'codeId': authCode.id,
          'duration': '${stopwatch.elapsedMilliseconds}ms',
        },
      );

      EmailLogger.logAuthCodeOperation(
        operation: 'validateConfirmationCode',
        codeType: AuthCodeType.emailConfirmation.value,
        userId: authCode.userId,
        success: true,
      );

      return authCode;
    } catch (e) {
      stopwatch.stop();

      EmailLogger.error(
        'Confirmation code validation failed',
        error: e,
        context: {
          'codeLength': code.length,
          'duration': '${stopwatch.elapsedMilliseconds}ms',
        },
      );

      EmailLogger.logAuthCodeOperation(
        operation: 'validateConfirmationCode',
        codeType: AuthCodeType.emailConfirmation.value,
        success: false,
        errorMessage: e.toString(),
      );

      return null;
    }
  }

  /// Validates and processes an email confirmation code
  /// 
  /// This method:
  /// 1. Validates the authentication code
  /// 2. Marks the user's email as confirmed in Supabase Auth
  /// 3. Invalidates the code to prevent reuse
  /// 
  /// [code] The authentication code from the email
  /// 
  /// Returns true if confirmation was successful, false otherwise
  Future<bool> confirmEmail(String code) async {
    final stopwatch = Stopwatch()..start();
    
    EmailLogger.logAuthCodeOperation(
      operation: 'confirmEmail',
      codeType: AuthCodeType.emailConfirmation.value,
    );

    try {
      EmailLogger.info(
        'Starting email confirmation validation',
        context: {
          'codeLength': code.length,
        },
      );

      // Validate and consume the authentication code
      EmailLogger.debug('Validating authentication code');
      final authCode = await _authCodeService.validateAndConsumeAuthCode(
        code,
        AuthCodeType.emailConfirmation,
      );

      if (authCode == null) {
        EmailLogger.warning(
          'Email confirmation failed: Invalid or expired code',
          context: {
            'codeLength': code.length,
          },
        );

        EmailLogger.logAuthCodeOperation(
          operation: 'confirmEmail',
          codeType: AuthCodeType.emailConfirmation.value,
          success: false,
          errorMessage: 'Invalid or expired code',
        );

        return false;
      }

      EmailLogger.debug(
        'Authentication code validated successfully',
        context: {
          'userId': authCode.userId,
          'codeId': authCode.id,
        },
      );

      // Update user's email confirmation status in Supabase Auth
      EmailLogger.debug('Updating user email confirmation status');
      await _updateUserEmailConfirmation(authCode.userId);

      stopwatch.stop();

      EmailLogger.logAuthCodeOperation(
        operation: 'confirmEmail',
        codeType: AuthCodeType.emailConfirmation.value,
        userId: authCode.userId,
        success: true,
      );

      EmailLogger.info(
        'Email confirmation completed successfully',
        context: {
          'userId': authCode.userId,
          'duration': '${stopwatch.elapsedMilliseconds}ms',
        },
      );

      return true;
    } catch (e) {
      stopwatch.stop();

      EmailLogger.error(
        'Email confirmation validation failed',
        error: e,
        context: {
          'codeLength': code.length,
          'duration': '${stopwatch.elapsedMilliseconds}ms',
        },
      );

      EmailLogger.logAuthCodeOperation(
        operation: 'confirmEmail',
        codeType: AuthCodeType.emailConfirmation.value,
        success: false,
        errorMessage: e.toString(),
      );

      // Don't throw the exception, just return false
      // This allows the UI to handle the failure gracefully
      return false;
    }
  }

  /// Updates the user's email confirmation status in Supabase Auth
  Future<void> _updateUserEmailConfirmation(String userId) async {
    try {
      // Update the user's email_confirmed_at timestamp
      await _supabase.auth.admin.updateUserById(
        userId,
        attributes: AdminUserAttributes(
          emailConfirm: true,
        ),
      );

      EmailLogger.debug(
        'User email confirmation status updated in Supabase',
        context: {
          'userId': userId,
        },
      );
    } catch (e) {
      // If we can't update via admin API, try alternative approach
      EmailLogger.warning(
        'Failed to update email confirmation via admin API, trying alternative approach',
        context: {
          'userId': userId,
          'error': e.toString(),
        },
      );

      // Alternative: Update user metadata
      final user = await _supabase.auth.getUser();
      if (user.user?.id == userId) {
        await _supabase.auth.updateUser(
          UserAttributes(
            data: {
              ...user.user?.userMetadata ?? {},
              'email_confirmed': true,
              'email_confirmed_at': DateTime.now().toIso8601String(),
            },
          ),
        );

        EmailLogger.debug(
          'User email confirmation updated via user metadata',
          context: {
            'userId': userId,
          },
        );
      } else {
        throw EmailServiceException(
          'Cannot update email confirmation: User not authenticated or ID mismatch',
          EmailServiceErrorType.authenticationError,
        );
      }
    }
  }

  /// Resends a confirmation email for a user
  /// 
  /// This method invalidates any existing confirmation codes and sends a new one.
  /// 
  /// [email] The user's email address
  /// [userId] The user's ID from Supabase Auth
  /// 
  /// Returns the email response from Azure Communication Services
  Future<EmailResponse> resendConfirmationEmail(
    String email,
    String userId,
  ) async {
    EmailLogger.info(
      'Resending confirmation email',
      context: {
        'email': email,
        'userId': userId,
      },
    );

    try {
      // Invalidate any existing confirmation codes for this user
      await _authCodeService.invalidateUserCodes(
        userId,
        AuthCodeType.emailConfirmation,
      );

      EmailLogger.debug('Existing confirmation codes invalidated');

      // Send new confirmation email
      return await sendConfirmationEmail(email, userId);
    } catch (e) {
      EmailLogger.error(
        'Failed to resend confirmation email',
        error: e,
        context: {
          'email': email,
          'userId': userId,
        },
      );

      rethrow;
    }
  }

  /// Checks if a user has pending confirmation codes
  /// 
  /// [userId] The user's ID from Supabase Auth
  /// 
  /// Returns true if there are valid, unexpired confirmation codes
  Future<bool> hasPendingConfirmation(String userId) async {
    try {
      final codes = await _authCodeService.getUserCodes(
        userId,
        AuthCodeType.emailConfirmation,
      );

      // Check if any codes are still valid (not used and not expired)
      final validCodes = codes.where((code) => !code.isUsed && !code.isExpired);
      
      return validCodes.isNotEmpty;
    } catch (e) {
      EmailLogger.error(
        'Failed to check pending confirmation status',
        error: e,
        context: {
          'userId': userId,
        },
      );

      return false;
    }
  }

  /// Checks if a user's email has been confirmed
  /// 
  /// This method checks both Supabase Auth confirmation status and our
  /// Azure-based confirmation system to determine if the email is confirmed.
  /// 
  /// [userId] The user's ID from Supabase Auth
  /// 
  /// Returns true if email has been confirmed, false otherwise
  Future<bool> isEmailConfirmed(String userId) async {
    try {
      EmailLogger.debug(
        'Checking email confirmation status',
        context: {
          'userId': userId,
        },
      );

      // First, check if the user exists in Supabase and has email confirmed
      final user = await _supabase.auth.admin.getUserById(userId);
      if (user.user?.emailConfirmedAt != null) {
        EmailLogger.debug(
          'Email confirmed via Supabase Auth',
          context: {
            'userId': userId,
            'emailConfirmedAt': user.user!.emailConfirmedAt.toString(),
          },
        );
        return true;
      }

      // If not confirmed in Supabase, check user metadata for Azure confirmation
      final userMetadata = user.user?.userMetadata;
      if (userMetadata != null) {
        final emailConfirmed = userMetadata['email_confirmed'];
        if (emailConfirmed == true) {
          EmailLogger.debug(
            'Email confirmed via Azure confirmation system (user metadata)',
            context: {
              'userId': userId,
            },
          );
          return true;
        }
      }

      // Check if there are any used confirmation codes (successful confirmations)
      final codes = await _authCodeService.getUserCodes(
        userId,
        AuthCodeType.emailConfirmation,
      );

      final usedCodes = codes.where((code) => code.isUsed);
      if (usedCodes.isNotEmpty) {
        EmailLogger.debug(
          'Email confirmed via Azure confirmation codes',
          context: {
            'userId': userId,
            'usedCodesCount': usedCodes.length,
          },
        );
        return true;
      }

      EmailLogger.debug(
        'Email not confirmed',
        context: {
          'userId': userId,
        },
      );

      return false;
    } catch (e) {
      EmailLogger.error(
        'Failed to check email confirmation status',
        error: e,
        context: {
          'userId': userId,
        },
      );

      // In case of error, be conservative and return false
      return false;
    }
  }

  /// Disposes of resources used by the service
  void dispose() {
    // No resources to dispose in this service
    // The underlying services are managed by the ServiceLocator
  }
}
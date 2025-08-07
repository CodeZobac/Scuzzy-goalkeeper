import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/http_service_locator.dart';
import '../../../core/services/http_email_service.dart';
import '../../../core/services/http_auth_code_service.dart';
import '../../../core/models/email_response.dart';
import '../data/models/auth_code.dart';
import '../../../core/exceptions/email_service_exception.dart';
import '../../../core/services/email_logger.dart';

/// Service for handling email confirmation using HTTP communication with Python backend
/// 
/// This service integrates with the existing Supabase Auth signup flow
/// to provide email confirmation functionality by communicating with the
/// Python FastAPI backend which handles Azure Communication Services.
class HttpEmailConfirmationService {
  final HttpEmailService _httpEmailService;
  final HttpAuthCodeService _httpAuthCodeService;
  final SupabaseClient _supabase;

  HttpEmailConfirmationService({
    HttpEmailService? httpEmailService,
    HttpAuthCodeService? httpAuthCodeService,
    SupabaseClient? supabase,
  }) : _httpEmailService = httpEmailService ?? HttpServiceLocator.instance.httpEmailService,
       _httpAuthCodeService = httpAuthCodeService ?? HttpServiceLocator.instance.httpAuthCodeService,
       _supabase = supabase ?? Supabase.instance.client;

  /// Sends a confirmation email via the Python backend
  /// 
  /// This method integrates with the existing signup flow by:
  /// 1. Making an HTTP request to the Python backend
  /// 2. The backend generates a secure authentication code
  /// 3. The backend sends the confirmation email via Azure Communication Services
  /// 4. The backend stores the code for later validation
  /// 
  /// All the complex orchestration is handled by the Python backend,
  /// making this much simpler than the Azure-based implementation.
  /// 
  /// [email] The user's email address
  /// [userId] The user's ID from Supabase Auth
  /// 
  /// Returns the email response from the Python backend
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
        'Starting email confirmation process via Python backend',
        context: {
          'email': email,
          'userId': userId,
          'backend': 'Python FastAPI',
        },
      );

      // Send confirmation email via Python backend
      // The backend handles all the complex logic:
      // - Code generation
      // - Template processing
      // - Azure Communication Services integration
      // - Database storage
      EmailLogger.debug('Sending confirmation email request to Python backend');
      final emailResponse = await _httpEmailService.sendConfirmationEmail(
        email,
        userId,
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
        'Email confirmation sent successfully via Python backend',
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
              'Failed to send confirmation email via Python backend: $e',
              EmailServiceErrorType.backendError,
              e,
            );

      EmailLogger.error(
        'Email confirmation failed',
        error: exception,
        context: {
          'email': email,
          'userId': userId,
          'duration': '${stopwatch.elapsedMilliseconds}ms',
          'backend': 'Python FastAPI',
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

  /// Validates a confirmation code via the Python backend
  /// 
  /// This method validates the authentication code through the backend:
  /// 1. Makes an HTTP request to validate the code
  /// 2. Backend verifies the code exists and matches the stored hash
  /// 3. Backend checks that the code has not expired
  /// 4. Backend ensures the code has not been used before
  /// 
  /// [code] The authentication code from the email
  /// 
  /// Returns the AuthCode information if valid, null if invalid/expired/used
  Future<AuthCode?> validateConfirmationCode(String code) async {
    final stopwatch = Stopwatch()..start();
    
    EmailLogger.logAuthCodeOperation(
      operation: 'validateConfirmationCode',
      codeType: AuthCodeType.emailConfirmation.value,
    );

    try {
      EmailLogger.info(
        'Validating confirmation code via Python backend',
        context: {
          'codeLength': code.length,
          'backend': 'Python FastAPI',
        },
      );

      // Validate the authentication code via Python backend
      EmailLogger.debug('Validating authentication code via Python backend');
      final authCode = await _httpAuthCodeService.validateAuthCode(
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
            'backend': 'Python FastAPI',
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
        'Confirmation code validated successfully via Python backend',
        context: {
          'userId': authCode.userId,
          'duration': '${stopwatch.elapsedMilliseconds}ms',
          'backend': 'Python FastAPI',
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
        'Confirmation code validation failed via Python backend',
        error: e,
        context: {
          'codeLength': code.length,
          'duration': '${stopwatch.elapsedMilliseconds}ms',
          'backend': 'Python FastAPI',
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

  /// Validates and processes an email confirmation code via the Python backend
  /// 
  /// This method:
  /// 1. Validates the authentication code via Python backend
  /// 2. Backend marks the code as used to prevent reuse
  /// 3. Marks the user's email as confirmed in Supabase Auth
  /// 
  /// The Python backend automatically handles code consumption for security.
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
        'Starting email confirmation validation via Python backend',
        context: {
          'codeLength': code.length,
          'backend': 'Python FastAPI',
        },
      );

      // Validate and consume the authentication code via Python backend
      // The backend automatically marks valid codes as used for security
      EmailLogger.debug('Validating and consuming authentication code via Python backend');
      final authCode = await _httpAuthCodeService.validateAndConsumeAuthCode(
        code,
        AuthCodeType.emailConfirmation,
      );

      if (authCode == null) {
        EmailLogger.warning(
          'Email confirmation failed: Invalid or expired code',
          context: {
            'codeLength': code.length,
            'backend': 'Python FastAPI',
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
        'Authentication code validated and consumed successfully via Python backend',
        context: {
          'userId': authCode.userId,
          'backend': 'Python FastAPI',
        },
      );

      // Update user's email confirmation status in Supabase Auth
      EmailLogger.debug('Updating user email confirmation status in Supabase');
      await _updateUserEmailConfirmation(authCode.userId);

      stopwatch.stop();

      EmailLogger.logAuthCodeOperation(
        operation: 'confirmEmail',
        codeType: AuthCodeType.emailConfirmation.value,
        userId: authCode.userId,
        success: true,
      );

      EmailLogger.info(
        'Email confirmation completed successfully via Python backend',
        context: {
          'userId': authCode.userId,
          'duration': '${stopwatch.elapsedMilliseconds}ms',
          'backend': 'Python FastAPI',
        },
      );

      return true;
    } catch (e) {
      stopwatch.stop();

      EmailLogger.error(
        'Email confirmation validation failed via Python backend',
        error: e,
        context: {
          'codeLength': code.length,
          'duration': '${stopwatch.elapsedMilliseconds}ms',
          'backend': 'Python FastAPI',
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

  /// Resends a confirmation email via the Python backend
  /// 
  /// This method sends a new confirmation email. The Python backend
  /// automatically handles invalidating any existing codes and generating new ones.
  /// 
  /// [email] The user's email address
  /// [userId] The user's ID from Supabase Auth
  /// 
  /// Returns the email response from the Python backend
  Future<EmailResponse> resendConfirmationEmail(
    String email,
    String userId,
  ) async {
    EmailLogger.info(
      'Resending confirmation email via Python backend',
      context: {
        'email': email,
        'userId': userId,
        'backend': 'Python FastAPI',
      },
    );

    try {
      // The Python backend handles invalidating existing codes automatically
      // Just send the new confirmation email
      return await sendConfirmationEmail(email, userId);
    } catch (e) {
      EmailLogger.error(
        'Failed to resend confirmation email via Python backend',
        error: e,
        context: {
          'email': email,
          'userId': userId,
          'backend': 'Python FastAPI',
        },
      );

      rethrow;
    }
  }

  /// Checks if a user's email has been confirmed
  /// 
  /// This method checks both Supabase Auth confirmation status and the
  /// Python backend's confirmation system to determine if the email is confirmed.
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
          'backend': 'Python FastAPI',
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

      // If not confirmed in Supabase, check user metadata for confirmation
      final userMetadata = user.user?.userMetadata;
      if (userMetadata != null) {
        final emailConfirmed = userMetadata['email_confirmed'];
        if (emailConfirmed == true) {
          EmailLogger.debug(
            'Email confirmed via confirmation system (user metadata)',
            context: {
              'userId': userId,
              'backend': 'Python FastAPI',
            },
          );
          return true;
        }
      }

      EmailLogger.debug(
        'Email not confirmed',
        context: {
          'userId': userId,
          'backend': 'Python FastAPI',
        },
      );

      return false;
    } catch (e) {
      EmailLogger.error(
        'Failed to check email confirmation status',
        error: e,
        context: {
          'userId': userId,
          'backend': 'Python FastAPI',
        },
      );

      // In case of error, be conservative and return false
      return false;
    }
  }

  /// Disposes of resources used by the service
  void dispose() {
    // HTTP services are managed by the HttpServiceLocator
    // No additional cleanup needed here
  }
}

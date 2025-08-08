import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/app_config.dart';
import '../../../core/services/http_service_locator.dart';
import '../../../core/services/http_email_service.dart';
import '../../../core/services/http_auth_code_service.dart';
import '../../../core/models/email_response.dart';
import '../data/models/auth_code.dart';
import '../../../core/exceptions/email_service_exception.dart';
import '../../../core/services/email_logger.dart';

/// Service for handling password reset using HTTP communication with Python backend
/// 
/// This service integrates with the existing Supabase Auth password reset flow
/// to provide password reset functionality by communicating with the
/// Python FastAPI backend which handles Azure Communication Services.
class HttpPasswordResetService {
  final HttpEmailService _httpEmailService;
  final HttpAuthCodeService _httpAuthCodeService;
  final SupabaseClient _supabase;

  HttpPasswordResetService({
    HttpEmailService? httpEmailService,
    HttpAuthCodeService? httpAuthCodeService,
    SupabaseClient? supabase,
  }) : _httpEmailService = httpEmailService ?? HttpServiceLocator.instance.httpEmailService,
       _httpAuthCodeService = httpAuthCodeService ?? HttpServiceLocator.instance.httpAuthCodeService,
       _supabase = supabase ?? Supabase.instance.client;

  /// Sends a password reset email via the Python backend
  /// 
  /// This method integrates with the existing password reset flow by:
  /// 1. Making an HTTP request to the Python backend
  /// 2. The backend generates a secure authentication code
  /// 3. The backend sends the reset email via Azure Communication Services
  /// 4. The backend stores the code for later validation
  /// 
  /// All the complex orchestration is handled by the Python backend,
  /// making this much simpler than the Azure-based implementation.
  /// 
  /// [email] The user's email address
  /// [userId] The user's ID from Supabase Auth
  /// 
  /// Returns the email response from the Python backend
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
        'Starting password reset process via Python backend',
        context: {
          'email': email,
          'userId': userId,
          'backend': 'Python FastAPI',
        },
      );

      // Send password reset email via Python backend
      // The backend handles all the complex logic:
      // - Code generation
      // - Template processing
      // - Azure Communication Services integration
      // - Database storage
      EmailLogger.debug('Sending password reset email request to Python backend');
      final emailResponse = await _httpEmailService.sendPasswordResetEmail(
        email,
        userId,
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
        'Password reset email sent successfully via Python backend',
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
              'Failed to send password reset email via Python backend: $e',
              EmailServiceErrorType.backendError,
              e,
            );

      EmailLogger.error(
        'Password reset email failed',
        error: exception,
        context: {
          'email': email,
          'userId': userId,
          'duration': '${stopwatch.elapsedMilliseconds}ms',
          'backend': 'Python FastAPI',
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

  /// Validates a password reset code via the Python backend
  /// 
  /// This method validates the authentication code through the backend:
  /// 1. Makes an HTTP request to validate the code
  /// 2. Backend verifies the code exists and matches the stored hash
  /// 3. Backend checks that the code has not expired
  /// 4. Backend ensures the code has not been used before
  /// 5. Backend validates the code type matches password_reset
  /// 
  /// [code] The authentication code from the email
  /// 
  /// Returns the AuthCode information if valid, null if invalid/expired/used
  Future<AuthCode?> validatePasswordResetCode(String code) async {
    final stopwatch = Stopwatch()..start();
    
    EmailLogger.logAuthCodeOperation(
      operation: 'validatePasswordResetCode',
      codeType: AuthCodeType.passwordReset.value,
    );

    try {
      EmailLogger.info(
        'Validating password reset code via Python backend',
        context: {
          'codeLength': code.length,
          'backend': 'Python FastAPI',
        },
      );

      // Validate the authentication code via Python backend
      EmailLogger.debug('Validating authentication code via Python backend');
      final authCode = await _httpAuthCodeService.validateAuthCode(
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
            'backend': 'Python FastAPI',
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
        'Password reset code validated successfully via Python backend',
        context: {
          'userId': authCode.userId,
          'duration': '${stopwatch.elapsedMilliseconds}ms',
          'backend': 'Python FastAPI',
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
        'Password reset code validation failed via Python backend',
        error: e,
        context: {
          'codeLength': code.length,
          'duration': '${stopwatch.elapsedMilliseconds}ms',
          'backend': 'Python FastAPI',
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

  /// Completes the password reset process via the Python backend
  /// 
  /// This method:
  /// 1. Validates and consumes the authentication code via Python backend
  /// 2. Backend marks the code as used to prevent reuse
  /// 3. Updates the user's password in Supabase Auth
  /// 
  /// The Python backend automatically handles code consumption for security.
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
        'Starting password reset completion via Python backend',
        context: {
          'codeLength': code.length,
          'backend': 'Python FastAPI',
        },
      );

      // Call the backend's reset-password endpoint which handles both
      // code validation and password update with admin privileges
      EmailLogger.debug('Calling backend reset-password endpoint');
      final success = await _callResetPasswordEndpoint(code, newPassword);

      if (!success) {
        EmailLogger.warning(
          'Password reset failed: Backend returned failure',
          context: {
            'codeLength': code.length,
            'backend': 'Python FastAPI',
          },
        );

        EmailLogger.logAuthCodeOperation(
          operation: 'resetPassword',
          codeType: AuthCodeType.passwordReset.value,
          success: false,
          errorMessage: 'Backend reset-password endpoint failed',
        );

        return false;
      }

      EmailLogger.debug(
        'Password reset completed successfully via backend endpoint',
        context: {
          'backend': 'Python FastAPI',
        },
      );

      stopwatch.stop();

      EmailLogger.logAuthCodeOperation(
        operation: 'resetPassword',
        codeType: AuthCodeType.passwordReset.value,
        success: true,
      );

      EmailLogger.info(
        'Password reset completed successfully via Python backend',
        context: {
          'duration': '${stopwatch.elapsedMilliseconds}ms',
          'backend': 'Python FastAPI',
        },
      );

      return true;
    } catch (e) {
      stopwatch.stop();

      EmailLogger.error(
        'Password reset completion failed via Python backend',
        error: e,
        context: {
          'codeLength': code.length,
          'duration': '${stopwatch.elapsedMilliseconds}ms',
          'backend': 'Python FastAPI',
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

  /// Calls the backend's reset-password endpoint
  /// 
  /// This method calls the Python backend's /api/v1/reset-password endpoint
  /// which validates the code and updates the password using admin privileges.
  Future<bool> _callResetPasswordEndpoint(String code, String newPassword) async {
    try {
      final url = Uri.parse('${AppConfig.backendBaseUrl}/api/v1/reset-password');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'code': code,
          'new_password': newPassword,
        }),
      ).timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        final success = responseData['success'] as bool? ?? false;
        
        if (success) {
          final userId = responseData['user_id'] as String?;
          EmailLogger.debug(
            'Backend reset-password endpoint succeeded',
            context: {
              'userId': userId ?? 'unknown',
            },
          );
          return true;
        } else {
          final message = responseData['message'] as String? ?? 'Unknown error';
          EmailLogger.warning(
            'Backend reset-password endpoint returned failure',
            context: {
              'message': message,
            },
          );
          return false;
        }
      } else {
        EmailLogger.error(
          'Backend reset-password endpoint returned error status',
          context: {
            'statusCode': response.statusCode,
            'responseBody': response.body,
          },
        );
        return false;
      }
    } catch (e) {
      EmailLogger.error(
        'Failed to call backend reset-password endpoint',
        error: e,
      );
      return false;
    }
  }

  /// Updates the user's password via the Python backend
  /// 
  /// This method calls the backend's reset-password endpoint which handles
  /// the password update using admin privileges on the server side.
  Future<void> _updateUserPassword(String userId, String newPassword) async {
    // This method is no longer used since we call the backend endpoint directly
    // in the resetPassword method. Keeping it for compatibility but it will
    // throw an error if called.
    throw EmailServiceException(
      'Password update should be handled by backend reset-password endpoint',
      EmailServiceErrorType.validationError,
    );
  }

  /// Resends a password reset email via the Python backend
  /// 
  /// This method sends a new password reset email. The Python backend
  /// automatically handles invalidating any existing codes and generating new ones.
  /// 
  /// [email] The user's email address
  /// [userId] The user's ID from Supabase Auth
  /// 
  /// Returns the email response from the Python backend
  Future<EmailResponse> resendPasswordResetEmail(
    String email,
    String userId,
  ) async {
    EmailLogger.info(
      'Resending password reset email via Python backend',
      context: {
        'email': email,
        'userId': userId,
        'backend': 'Python FastAPI',
      },
    );

    try {
      // The Python backend handles invalidating existing codes automatically
      // Just send the new password reset email
      return await sendPasswordResetEmail(email, userId);
    } catch (e) {
      EmailLogger.error(
        'Failed to resend password reset email via Python backend',
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

  /// Checks if a user has pending password reset codes
  /// 
  /// Note: With the HTTP-based backend, this information is managed
  /// by the Python service, so we can't easily check pending codes locally.
  /// This method is provided for API compatibility but returns false.
  /// 
  /// [userId] The user's ID from Supabase Auth
  /// 
  /// Returns false (not supported with HTTP backend)
  Future<bool> hasPendingPasswordReset(String userId) async {
    EmailLogger.debug(
      'Checking pending password reset status (not supported with HTTP backend)',
      context: {
        'userId': userId,
        'backend': 'Python FastAPI',
      },
    );

    // With HTTP backend, we don't have direct access to check pending codes
    // The Python backend manages this internally
    return false;
  }

  /// Initiates password reset by email lookup
  /// 
  /// This method is not supported with the HTTP backend as the Python backend
  /// requires a user ID for security reasons.
  /// 
  /// [email] The user's email address
  /// 
  /// Throws an exception indicating this method is not supported
  Future<EmailResponse> initiatePasswordResetByEmail(String email) async {
    EmailLogger.warning(
      'Attempted to initiate password reset by email lookup (not supported with HTTP backend)',
      context: {
        'email': email,
        'backend': 'Python FastAPI',
      },
    );

    throw EmailServiceException(
      'Password reset by email lookup requires user ID with HTTP backend. Use sendPasswordResetEmail instead.',
      EmailServiceErrorType.validationError,
    );
  }

  /// Disposes of resources used by the service
  void dispose() {
    // HTTP services are managed by the HttpServiceLocator
    // No additional cleanup needed here
  }
}

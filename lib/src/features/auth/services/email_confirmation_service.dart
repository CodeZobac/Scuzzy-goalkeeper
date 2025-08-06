import '../../../core/services/azure_email_service.dart';
import '../data/repositories/auth_code_repository.dart';
import '../data/models/auth_code.dart';
import '../../../core/exceptions/email_service_exception.dart';
import '../../../core/models/email_response.dart';

/// Service for handling email confirmation during user signup
/// 
/// This service integrates with the existing signup flow to send confirmation
/// emails using Azure Communication Services and manage authentication codes.
class EmailConfirmationService {
  final AzureEmailService _azureEmailService;
  final AuthCodeRepository _authCodeRepository;

  EmailConfirmationService({
    AzureEmailService? azureEmailService,
    AuthCodeRepository? authCodeRepository,
  }) : _azureEmailService = azureEmailService ?? AzureEmailService(),
       _authCodeRepository = authCodeRepository ?? AuthCodeRepository();

  /// Sends a confirmation email to the user after signup
  /// 
  /// This method:
  /// 1. Generates a secure authentication code
  /// 2. Stores the code in the database with 5-minute expiration
  /// 3. Sends the confirmation email using Azure Communication Services
  /// 4. Returns the email response for tracking
  /// 
  /// [email] The user's email address
  /// [userId] The user's ID from Supabase Auth
  /// 
  /// Throws [EmailServiceException] if any step fails
  Future<EmailResponse> sendConfirmationEmail(
    String email,
    String userId,
  ) async {
    try {
      // Validate input parameters
      if (email.isEmpty) {
        throw EmailServiceException(
          'Email address cannot be empty',
          EmailServiceErrorType.validationError,
        );
      }

      if (userId.isEmpty) {
        throw EmailServiceException(
          'User ID cannot be empty',
          EmailServiceErrorType.validationError,
        );
      }

      // Generate and store authentication code with 5-minute expiration
      final authCode = await _authCodeRepository.storeUniqueAuthCode(
        userId,
        AuthCodeType.emailConfirmation,
        expirationDuration: const Duration(minutes: 5),
      );

      // Send the confirmation email using Azure Communication Services
      final emailResponse = await _azureEmailService.sendConfirmationEmail(
        email,
        userId,
        authCode,
      );

      return emailResponse;
    } catch (e) {
      if (e is EmailServiceException) {
        rethrow;
      }
      
      throw EmailServiceException(
        'Failed to send confirmation email: $e',
        EmailServiceErrorType.unknownError,
        e,
      );
    }
  }

  /// Validates a confirmation code and completes the email confirmation process
  /// 
  /// This method:
  /// 1. Validates the authentication code
  /// 2. Checks if the code is not expired and not already used
  /// 3. Marks the code as used to prevent reuse
  /// 4. Returns the validated AuthCode for further processing
  /// 
  /// [code] The authentication code from the email link
  /// 
  /// Returns the validated [AuthCode] if successful, null if invalid
  /// Throws [EmailServiceException] for database or validation errors
  Future<AuthCode?> validateConfirmationCode(String code) async {
    try {
      // Validate input
      if (code.isEmpty) {
        throw EmailServiceException(
          'Confirmation code cannot be empty',
          EmailServiceErrorType.validationError,
        );
      }

      // Validate the authentication code
      final authCode = await _authCodeRepository.validateAuthCode(
        code,
        AuthCodeType.emailConfirmation,
      );

      if (authCode == null) {
        // Code is invalid, expired, or already used
        return null;
      }

      // Mark the code as used to prevent reuse
      await _authCodeRepository.invalidateAuthCode(code);

      return authCode;
    } catch (e) {
      if (e is EmailServiceException) {
        rethrow;
      }
      
      throw EmailServiceException(
        'Failed to validate confirmation code: $e',
        EmailServiceErrorType.authCodeError,
        e,
      );
    }
  }

  /// Resends a confirmation email for a user
  /// 
  /// This method invalidates any existing confirmation codes for the user
  /// and sends a new confirmation email with a fresh authentication code.
  /// 
  /// [email] The user's email address
  /// [userId] The user's ID from Supabase Auth
  /// 
  /// Returns the email response for tracking
  /// Throws [EmailServiceException] if any step fails
  Future<EmailResponse> resendConfirmationEmail(
    String email,
    String userId,
  ) async {
    try {
      // Validate input parameters
      if (email.isEmpty) {
        throw EmailServiceException(
          'Email address cannot be empty',
          EmailServiceErrorType.validationError,
        );
      }

      if (userId.isEmpty) {
        throw EmailServiceException(
          'User ID cannot be empty',
          EmailServiceErrorType.validationError,
        );
      }

      // Invalidate any existing confirmation codes for this user
      await _authCodeRepository.invalidateUserCodes(
        userId,
        AuthCodeType.emailConfirmation,
      );

      // Send a new confirmation email
      return await sendConfirmationEmail(email, userId);
    } catch (e) {
      if (e is EmailServiceException) {
        rethrow;
      }
      
      throw EmailServiceException(
        'Failed to resend confirmation email: $e',
        EmailServiceErrorType.unknownError,
        e,
      );
    }
  }

  /// Checks if a user has any pending (unused and not expired) confirmation codes
  /// 
  /// [userId] The user's ID from Supabase Auth
  /// 
  /// Returns true if there are pending confirmation codes, false otherwise
  Future<bool> hasPendingConfirmation(String userId) async {
    try {
      if (userId.isEmpty) {
        throw EmailServiceException(
          'User ID cannot be empty',
          EmailServiceErrorType.validationError,
        );
      }

      final authCodes = await _authCodeRepository.getAuthCodesForUser(
        userId,
        AuthCodeType.emailConfirmation,
      );

      // Check if any codes are still valid (not used and not expired)
      return authCodes.any((code) => code.isValid);
    } catch (e) {
      if (e is EmailServiceException) {
        rethrow;
      }
      
      throw EmailServiceException(
        'Failed to check pending confirmation: $e',
        EmailServiceErrorType.databaseError,
        e,
      );
    }
  }

  /// Disposes of resources used by the service
  void dispose() {
    _azureEmailService.dispose();
  }
}
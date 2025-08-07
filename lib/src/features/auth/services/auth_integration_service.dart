import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/auth_repository.dart';
import '../../../core/exceptions/email_service_exception.dart';

/// Service that handles integration between Azure email services and Supabase Auth
/// 
/// This service ensures that Azure-based email flows work seamlessly with
/// existing Supabase Auth state management and user sessions.
class AuthIntegrationService {
  final AuthRepository _authRepository;
  final SupabaseClient _supabase;

  AuthIntegrationService({
    AuthRepository? authRepository,
    SupabaseClient? supabaseClient,
  }) : _authRepository = authRepository ?? AuthRepository(),
       _supabase = supabaseClient ?? Supabase.instance.client;

  /// Handles email confirmation from Azure authentication code
  /// 
  /// This method validates the Azure auth code and ensures the user's
  /// email verification status is properly updated in Supabase Auth.
  /// 
  /// [authCode] The authentication code from the email confirmation link
  /// 
  /// Returns true if confirmation was successful, false otherwise
  Future<bool> handleEmailConfirmation(String authCode) async {
    try {
      // Validate the Azure authentication code
      final isConfirmed = await _authRepository.confirmEmailWithCode(authCode);
      
      if (!isConfirmed) {
        return false;
      }

      // The email confirmation is now complete
      // Supabase Auth will handle the email verification status
      // when the user signs in next time
      return true;
    } catch (e) {
      print('Failed to handle email confirmation: $e');
      return false;
    }
  }

  /// Handles password reset from Azure authentication code
  /// 
  /// This method validates the Azure auth code and allows the user
  /// to reset their password through Supabase Auth.
  /// 
  /// [authCode] The authentication code from the password reset email
  /// [newPassword] The new password to set
  /// 
  /// Returns true if password reset was successful, false otherwise
  Future<bool> handlePasswordReset(String authCode, String newPassword) async {
    try {
      // Use the Azure-based password reset method
      await _authRepository.updatePasswordWithCode(authCode, newPassword);
      return true;
    } catch (e) {
      print('Failed to handle password reset: $e');
      return false;
    }
  }

  /// Checks if a user's email is verified
  /// 
  /// This method checks the current user's email verification status
  /// in Supabase Auth.
  /// 
  /// Returns true if email is verified, false otherwise
  bool isEmailVerified() {
    final currentUser = _supabase.auth.currentUser;
    return currentUser?.emailConfirmedAt != null;
  }

  /// Gets the current user's email address
  /// 
  /// Returns the email address if user is signed in, null otherwise
  String? getCurrentUserEmail() {
    return _supabase.auth.currentUser?.email;
  }

  /// Gets the current user's ID
  /// 
  /// Returns the user ID if user is signed in, null otherwise
  String? getCurrentUserId() {
    return _supabase.auth.currentUser?.id;
  }

  /// Resends confirmation email for the current user
  /// 
  /// This method resends the confirmation email using Azure services
  /// for the currently signed-in user.
  /// 
  /// Throws [AuthException] if user is not signed in or email sending fails
  Future<void> resendConfirmationEmailForCurrentUser() async {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null || currentUser.email == null) {
      throw AuthException('Utilizador não está autenticado.');
    }

    await _authRepository.resendConfirmationEmail(currentUser.email!);
  }

  /// Resends password reset email for a specific email address
  /// 
  /// This method sends a password reset email using Azure services.
  /// 
  /// [email] The email address to send the reset email to
  /// 
  /// Throws [AuthException] if email sending fails
  Future<void> resendPasswordResetEmail(String email) async {
    await _authRepository.resetPasswordForEmail(email);
  }

  /// Disposes of resources used by the service
  void dispose() {
    _authRepository.dispose();
  }
}
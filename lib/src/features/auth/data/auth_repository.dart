
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/email_validation_service.dart';
import '../services/http_email_confirmation_service.dart';
import '../services/http_password_reset_service.dart';

class AuthRepository {
  final _supabase = Supabase.instance.client;
  final _emailValidationService = EmailValidationService();
  final HttpEmailConfirmationService _emailConfirmationService = HttpEmailConfirmationService();
  HttpPasswordResetService? _passwordResetService;

  /// Lazily initialize the HttpPasswordResetService to avoid initialization errors
  HttpPasswordResetService get passwordResetService {
    _passwordResetService ??= HttpPasswordResetService();
    return _passwordResetService!;
  }

  Future<void> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    // Check if email already exists
    final emailExists = await _emailValidationService.emailExists(email);
    if (emailExists) {
      throw AuthException('Este email já está registado. Tente fazer login ou use outro email.');
    }

    // 🚫 NUCLEAR OPTION: BYPASS SUPABASE EMAIL SYSTEM COMPLETELY 🚫
    // We'll create user and immediately sign them out to prevent auto-login
    // Then handle ALL email confirmation through our Python backend
    
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {
        'full_name': name,
        'email_confirmed': false,
        'bypass_supabase_emails': true,  // Flag for our tracking
      },
      // This should disable emails, but Supabase is stubborn
      emailRedirectTo: null,
    );
    
    // Immediately sign out user to prevent auto-login without confirmation
    if (response.user != null) {
      await _supabase.auth.signOut();
    }

    // If signup was successful and we have a user, send confirmation email via Python backend
    if (response.user != null) {
      try {
        await _emailConfirmationService.sendConfirmationEmail(
          email,
          response.user!.id,
        );
      } catch (e) {
        // If Python backend email service fails, we should clean up the user account
        // and fail the signup process since email confirmation is required
        try {
          // Sign out the user to prevent them from being logged in without confirmation
          await _supabase.auth.signOut();
        } catch (signOutError) {
          // Log but don't throw - the main error is more important
          print('Failed to sign out user after Python backend failure: $signOutError');
        }
        
        throw AuthException('Falha ao enviar email de confirmação. Tente novamente mais tarde.');
      }
    }
  }

  Future<void> signInWithPassword({required String email, required String password}) async {
    // Check if email exists before attempting sign in
    final emailExists = await _emailValidationService.emailExists(email);
    if (!emailExists) {
      throw AuthException('Este email não está registado. Verifique o email ou crie uma conta.');
    }

    // Sign in with Supabase
    final response = await _supabase.auth.signInWithPassword(email: email, password: password);
    
    // Check if email is confirmed (programmatic enforcement)
    if (response.user != null) {
      final userId = response.user!.id;
      
      // Always check our HTTP-based confirmation system first (via Python backend)
      final hasValidConfirmation = await _emailConfirmationService.isEmailConfirmed(userId);
      
      if (!hasValidConfirmation) {
        // Sign out the user immediately and throw error
        await _supabase.auth.signOut();
        throw AuthException('Email não confirmado. Verifique o seu email e clique no link de confirmação.');
      }
      
      // If confirmed in our system but not in Supabase, update Supabase
      if (response.user!.emailConfirmedAt == null) {
        try {
          await _updateSupabaseEmailConfirmation(userId);
        } catch (e) {
          print('Failed to update Supabase email confirmation status: $e');
      // Continue anyway if this fails - user is confirmed in our HTTP-based system
        }
      }
    }
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  Future<void> resetPasswordForEmail(String email) async {
    // Check if email exists before attempting password reset
    final emailExists = await _emailValidationService.emailExists(email);
    if (!emailExists) {
      throw AuthException('Este email não está registado. Verifique o email ou crie uma conta.');
    }

    // Get the user ID for the email
    final userId = await _emailValidationService.getUserIdByEmail(email);
    if (userId == null) {
      throw AuthException('Não foi possível encontrar o utilizador para este email.');
    }

    try {
      // Send password reset email via Python backend (which handles Azure Communication Services)
      await passwordResetService.sendPasswordResetEmail(email, userId);
    } catch (e) {
      // If Python backend email service fails, throw an error
      // We no longer fall back to Supabase email service
      throw AuthException('Falha ao enviar email de recuperação. Tente novamente mais tarde.');
    }
  }

  Future<void> updatePassword(String newPassword) async {
    await _supabase.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }

  /// Updates password using HTTP-based authentication code (via Python backend)
  /// This method validates the code and updates the password for the associated user
  Future<void> updatePasswordWithCode(String authCode, String newPassword) async {
    try {
      // Validate the authentication code and get the user ID
      final authCodeData = await passwordResetService.validatePasswordResetCode(authCode);
      if (authCodeData == null) {
        throw AuthException('Código de recuperação inválido ou expirado.');
      }

      // For HTTP-based password reset (via Python backend), we need to handle this carefully
      // Since the auth code has been validated and marked as used, we can proceed
      
      // Get the user's email from the user ID for verification
      final userEmail = await _emailValidationService.getEmailByUserId(authCodeData.userId);
      if (userEmail == null) {
        throw AuthException('Não foi possível encontrar o email do utilizador.');
      }

      // For password reset, we use the HTTP password reset service
      // which handles the password update on the backend with proper privileges
      final success = await passwordResetService.resetPassword(authCode, newPassword);
      
      if (!success) {
        throw AuthException('Falha ao atualizar a palavra-passe. O código pode ter expirado.');
      }
      
    } catch (e) {
      if (e is AuthException) {
        rethrow;
      }
      throw AuthException('Falha ao atualizar a palavra-passe. Tente novamente.');
    }
  }

  Session? get currentUserSession => _supabase.auth.currentSession;

  /// Check if email exists for signup validation
  Future<bool> checkEmailExistsForSignup(String email) async {
    return await _emailValidationService.emailExists(email);
  }

  /// Check if email exists for signin validation
  Future<bool> checkEmailExistsForSignin(String email) async {
    return await _emailValidationService.emailExists(email);
  }

  /// Validates a password reset code from email link
  /// Returns the user ID if the code is valid, null otherwise
  Future<String?> validatePasswordResetCode(String code) async {
    try {
      final authCode = await passwordResetService.validatePasswordResetCode(code);
      return authCode?.userId;
    } catch (e) {
      // Log the error but return null to indicate invalid code
      print('Failed to validate password reset code: $e');
      return null;
    }
  }

  /// Resends a password reset email for a user
  Future<void> resendPasswordResetEmail(String email) async {
    // Check if email exists
    final emailExists = await _emailValidationService.emailExists(email);
    if (!emailExists) {
      throw AuthException('Este email não está registado. Verifique o email ou crie uma conta.');
    }

    // Get the user ID for the email
    final userId = await _emailValidationService.getUserIdByEmail(email);
    if (userId == null) {
      throw AuthException('Não foi possível encontrar o utilizador para este email.');
    }

    try {
      // Resend password reset email via Python backend (which handles Azure Communication Services)
      await passwordResetService.sendPasswordResetEmail(email, userId);
    } catch (e) {
      throw AuthException('Falha ao reenviar email de recuperação. Tente novamente mais tarde.');
    }
  }

  /// Confirms email address using HTTP-based authentication code (via Python backend)
  /// This method validates the code and marks the email as confirmed in Supabase Auth
  Future<bool> confirmEmailWithCode(String authCode) async {
    try {
      // Validate the authentication code
      final authCodeData = await _emailConfirmationService.validateConfirmationCode(authCode);
      if (authCodeData == null) {
        return false; // Invalid or expired code
      }

      // Update Supabase user's email confirmation status
      try {
        await _updateSupabaseEmailConfirmation(authCodeData.userId);
      } catch (e) {
        print('Failed to update Supabase email confirmation: $e');
        // Continue anyway - the confirmation is valid in our HTTP-based system
      }

      return true;
    } catch (e) {
      print('Failed to confirm email with code: $e');
      return false;
    }
  }

  /// Resends confirmation email for a user
  Future<void> resendConfirmationEmail(String email) async {
    // Check if email exists
    final emailExists = await _emailValidationService.emailExists(email);
    if (!emailExists) {
      throw AuthException('Este email não está registado. Verifique o email ou crie uma conta.');
    }

    // Get the user ID for the email
    final userId = await _emailValidationService.getUserIdByEmail(email);
    if (userId == null) {
      throw AuthException('Não foi possível encontrar o utilizador para este email.');
    }

    try {
      // Resend confirmation email via Python backend (which handles Azure Communication Services)
      await _emailConfirmationService.resendConfirmationEmail(email, userId);
    } catch (e) {
      throw AuthException('Falha ao reenviar email de confirmação. Tente novamente mais tarde.');
    }
  }

  /// Checks if a user's email is confirmed via HTTP-based services (Python backend)
  Future<bool> isEmailConfirmed(String userId) async {
    return await _emailConfirmationService.isEmailConfirmed(userId);
  }

  /// Updates the Supabase user's email confirmation status
  /// This is needed because we handle email confirmation outside of Supabase
  Future<void> updateSupabaseEmailConfirmation(String userId) async {
    try {
      // We need to update the user's email_confirmed_at field
      // Since we can't directly update this field via the client SDK,
      // we'll use a workaround by updating user metadata
      await _supabase.auth.updateUser(
        UserAttributes(
          data: {
            'email_confirmed': true,
            'email_confirmed_at': DateTime.now().toIso8601String(),
          },
        ),
      );
    } catch (e) {
      throw Exception('Failed to update Supabase email confirmation status: $e');
    }
  }

  /// Updates the Supabase user's email confirmation status (DEPRECATED - for backwards compatibility)
  /// This is needed because we handle email confirmation outside of Supabase
  Future<void> _updateSupabaseEmailConfirmation(String userId) async {
    await updateSupabaseEmailConfirmation(userId);
  }

  /// Disposes of resources used by the repository
  void dispose() {
    _emailConfirmationService.dispose();
    _passwordResetService?.dispose();
  }
}

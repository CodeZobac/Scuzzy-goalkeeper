
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/email_validation_service.dart';
import '../services/email_confirmation_service.dart';

class AuthRepository {
  final _supabase = Supabase.instance.client;
  final _emailValidationService = EmailValidationService();
  final EmailConfirmationService _emailConfirmationService = EmailConfirmationService();

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

    // Sign up the user with Supabase Auth
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': name},
      emailRedirectTo: 'https://goalkeeper-e4b09.web.app/#/email-confirmed',
    );

    // If signup was successful and we have a user, send confirmation email
    if (response.user != null) {
      try {
        await _emailConfirmationService.sendConfirmationEmail(
          email,
          response.user!.id,
        );
      } catch (e) {
        // Log the error but don't fail the signup process
        // The user account was created successfully, just the email failed
        print('Failed to send confirmation email: $e');
        // In a production app, you might want to queue this for retry
      }
    }
  }

  Future<void> signInWithPassword({required String email, required String password}) async {
    // Check if email exists before attempting sign in
    final emailExists = await _emailValidationService.emailExists(email);
    if (!emailExists) {
      throw AuthException('Este email não está registado. Verifique o email ou crie uma conta.');
    }

    await _supabase.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  Future<void> resetPasswordForEmail(String email) async {
    // Configure the redirect URL for password reset
    // Use production URL for deployed app, localhost for development
    const String redirectUrl = 'https://goalkeeper-e4b09.web.app/#/reset-password';
    
    await _supabase.auth.resetPasswordForEmail(
      email,
      redirectTo: redirectUrl,
    );
  }

  Future<void> updatePassword(String newPassword) async {
    await _supabase.auth.updateUser(
      UserAttributes(password: newPassword),
    );
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

  /// Disposes of resources used by the repository
  void dispose() {
    _emailConfirmationService.dispose();
  }
}

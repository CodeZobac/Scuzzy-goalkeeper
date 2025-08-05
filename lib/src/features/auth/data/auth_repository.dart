
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/email_validation_service.dart';

class AuthRepository {
  final _supabase = Supabase.instance.client;
  final _emailValidationService = EmailValidationService();

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

    await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': name},
      emailRedirectTo: 'https://goalkeeper-e4b09.web.app/#/email-confirmed',
    );
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
}


import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  final _supabase = Supabase.instance.client;

  Future<void> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': name},
      emailRedirectTo: 'https://goalkeeper-e4b09.web.app/#/email-confirmed',
    );
  }

  Future<void> signInWithPassword({required String email, required String password}) async {
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
}

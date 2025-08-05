import 'package:supabase_flutter/supabase_flutter.dart';

class EmailValidationService {
  final _supabase = Supabase.instance.client;

  /// Checks if an email exists in the auth.users table
  /// Returns true if email exists, false otherwise
  Future<bool> emailExists(String email) async {
    try {
      // Use RPC function to check if email exists
      final response = await _supabase
          .rpc('check_email_exists', params: {'email_to_check': email.toLowerCase()});
      return response as bool? ?? false;
    } catch (e) {
      // Fallback: try to query auth.users directly (may not work due to RLS)
      try {
        final response = await _supabase
            .from('auth.users')
            .select('email')
            .eq('email', email.toLowerCase())
            .maybeSingle();
        
        return response != null;
      } catch (directQueryError) {
        // Last resort: attempt sign in with dummy password
        try {
          await _supabase.auth.signInWithPassword(
            email: email,
            password: 'dummy_password_that_will_fail_12345',
          );
          return true; // If we get here, email exists but password was wrong
        } on AuthException catch (authError) {
          if (authError.message.toLowerCase().contains('invalid login credentials')) {
            return true; // Email exists but password is wrong
          } else if (authError.message.toLowerCase().contains('email not found') ||
                     authError.message.toLowerCase().contains('user not found')) {
            return false; // Email doesn't exist
          }
          // For other auth errors, assume email doesn't exist
          return false;
        }
      }
    }
  }

  /// Validates email format
  bool isValidEmailFormat(String email) {
    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    return emailRegex.hasMatch(email);
  }
}
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

  /// Gets user ID by email address
  /// Returns the user ID if found, null otherwise
  Future<String?> getUserIdByEmail(String email) async {
    try {
      // Use RPC function to get user ID by email
      final response = await _supabase
          .rpc('get_user_id_by_email', params: {'email_to_check': email.toLowerCase()});
      return response as String?;
    } catch (e) {
      // Fallback: try to query auth.users directly (may not work due to RLS)
      try {
        final response = await _supabase
            .from('auth.users')
            .select('id')
            .eq('email', email.toLowerCase())
            .maybeSingle();
        
        return response?['id'] as String?;
      } catch (directQueryError) {
        // If we can't get the user ID, return null
        return null;
      }
    }
  }

  /// Gets email address by user ID
  /// Returns the email if found, null otherwise
  Future<String?> getEmailByUserId(String userId) async {
    try {
      // Use RPC function to get email by user ID
      final response = await _supabase
          .rpc('get_email_by_user_id', params: {'user_id_to_check': userId});
      return response as String?;
    } catch (e) {
      // Fallback: try to query auth.users directly (may not work due to RLS)
      try {
        final response = await _supabase
            .from('auth.users')
            .select('email')
            .eq('id', userId)
            .maybeSingle();
        
        return response?['email'] as String?;
      } catch (directQueryError) {
        // If we can't get the email, return null
        return null;
      }
    }
  }

  /// Validates email format
  bool isValidEmailFormat(String email) {
    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    return emailRegex.hasMatch(email);
  }
}
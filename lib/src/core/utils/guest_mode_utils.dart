import 'package:supabase_flutter/supabase_flutter.dart';

/// Utility class for guest mode detection and management throughout the app
class GuestModeUtils {
  static SupabaseClient? _testClient;
  
  /// Set a test client for testing purposes
  static void setTestClient(SupabaseClient? client) {
    _testClient = client;
  }
  
  static SupabaseClient get _supabase => _testClient ?? Supabase.instance.client;
  
  /// Check if the current user is in guest mode
  static bool get isGuest => _supabase.auth.currentSession == null;
  
  /// Check if the current user is authenticated
  static bool get isAuthenticated => _supabase.auth.currentSession != null;
  
  /// Get the current user session
  static Session? get currentSession => _supabase.auth.currentSession;
  
  /// Get the current user
  static User? get currentUser => _supabase.auth.currentUser;
  
  /// Check if a specific action requires authentication
  static bool actionRequiresAuth(String action) {
    const authRequiredActions = {
      'join_match',
      'hire_goalkeeper',
      'create_announcement', 
      'edit_profile',
      'manage_notifications',
      'create_booking',
      'rate_goalkeeper',
      'send_message',
    };
    
    return authRequiredActions.contains(action);
  }
  
  /// Check if a route should be accessible to guest users
  static bool isGuestAccessibleRoute(String route) {
    const guestRoutes = {
      '/home',
      '/announcements',
      '/map', 
      '/profile',
      '/signin',
      '/signup',
    };
    
    return guestRoutes.contains(route);
  }
  
  /// Get the appropriate redirect route for guest users attempting restricted actions
  static String getGuestRedirectRoute(String attemptedAction) {
    switch (attemptedAction) {
      case 'join_match':
      case 'hire_goalkeeper':
      case 'create_announcement':
        return '/signup';
      default:
        return '/signin';
    }
  }
  
  /// Check if the current context allows guest access
  static bool canGuestAccess(String feature) {
    const guestAllowedFeatures = {
      'view_announcements',
      'view_map',
      'view_fields',
      'view_goalkeeper_locations',
      'browse_content',
    };
    
    return guestAllowedFeatures.contains(feature);
  }
  
  /// Generate a guest session identifier for analytics
  static String generateGuestSessionId() {
    return 'guest_${DateTime.now().millisecondsSinceEpoch}';
  }
}
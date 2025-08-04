// Web-specific implementation for URL manipulation
import 'dart:html' as html;

/// Web-specific URL utilities using dart:html
class UrlUtilsWeb {
  /// Clear URL parameters and fragments using browser history API
  static void clearUrlParameters() {
    try {
      final currentUrl = html.window.location.href;
      final uri = Uri.parse(currentUrl);
      
      print('🔧 BEFORE URL clear: $currentUrl');
      print('🔧 Query params: ${uri.queryParameters}');
      print('🔧 Fragment: ${uri.fragment}');
      
      // Create clean URL without query parameters and fragments
      final cleanUrl = '${uri.origin}${uri.path}';
      
      // Use replaceState to update URL without page reload
      html.window.history.replaceState(null, '', cleanUrl);
      
      print('✅ URL cleared successfully: $cleanUrl');
      print('🔧 AFTER URL clear: ${html.window.location.href}');
    } catch (e) {
      print('❌ Failed to clear URL parameters: $e');
    }
  }
  
  /// Check if current URL has password reset parameters
  static bool hasPasswordResetParameters() {
    try {
      final currentUrl = html.window.location.href;
      final uri = Uri.parse(currentUrl);
      
      final hasCode = uri.queryParameters.containsKey('code');
      final hasAccessToken = uri.fragment.contains('access_token=');
      final hasResetFragment = uri.fragment.contains('reset-password');
      
      print('🔍 URL parameter check:');
      print('  URL: $currentUrl');
      print('  Has code: $hasCode');
      print('  Has access_token: $hasAccessToken');
      print('  Has reset-password: $hasResetFragment');
      
      return hasCode || hasAccessToken || hasResetFragment;
    } catch (e) {
      print('❌ Failed to check URL parameters: $e');
      return false;
    }
  }
}
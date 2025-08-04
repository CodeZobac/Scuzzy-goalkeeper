import 'package:flutter/foundation.dart';

// Conditional imports for web-specific functionality
import 'url_utils_stub.dart'
    if (dart.library.html) 'url_utils_web.dart';

/// Utility class for URL manipulation, particularly for web platforms
class UrlUtils {
  /// Clears URL parameters and fragments for web platforms
  /// This is essential for password reset flows to prevent eternal recovery mode
  static void clearUrlParameters() {
    if (kIsWeb) {
      try {
        UrlUtilsWeb.clearUrlParameters();
      } catch (e) {
        // Silently handle any errors - URL clearing is not critical
        // but helps improve UX
        debugPrint('Failed to clear URL parameters: $e');
      }
    }
  }
  
  /// Check if current URL contains password reset parameters
  static bool hasPasswordResetParameters() {
    if (!kIsWeb) return false;
    
    try {
      return UrlUtilsWeb.hasPasswordResetParameters();
    } catch (e) {
      debugPrint('Failed to check URL parameters: $e');
      return false;
    }
  }
  
  /// Get clean URL without password reset parameters (fallback method)
  static String getCleanUrl() {
    final currentUrl = Uri.base;
    return currentUrl.replace(
      queryParameters: <String, String>{},
      fragment: '',
    ).toString();
  }
}
// Stub implementation for non-web platforms
class UrlUtilsWeb {
  /// No-op implementation for non-web platforms
  static void clearUrlParameters() {
    // No URL manipulation needed on mobile platforms
  }
  
  /// Always returns false on non-web platforms
  static bool hasPasswordResetParameters() {
    return false;
  }
}
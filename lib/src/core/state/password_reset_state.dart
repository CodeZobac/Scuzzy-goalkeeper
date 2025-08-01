// Global password reset state management
class PasswordResetState {
  static bool _isInProgress = false;
  
  static bool get isInProgress => _isInProgress;
  
  static void setInProgress() {
    _isInProgress = true;
    print('🔒 GLOBAL PASSWORD RESET FLAG SET - ALL REDIRECTS BLOCKED');
  }
  
  static void clear() {
    _isInProgress = false;
    print('🔓 GLOBAL PASSWORD RESET FLAG CLEARED');
  }
  
  /// Debug method to force clear the password reset state
  static void debugForceClear() {
    _isInProgress = false;
    print('🔓 DEBUG: GLOBAL PASSWORD RESET FLAG FORCE CLEARED');
  }
}
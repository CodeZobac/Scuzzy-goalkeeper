import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/guest_user_context.dart';
import '../../data/models/registration_prompt_config.dart';
import '../../data/services/guest_analytics_service.dart';
import '../../data/services/smart_prompt_manager.dart';

/// Provider that manages authentication state and guest mode detection
class AuthStateProvider extends ChangeNotifier {
  final SupabaseClient _supabase;
  final GuestAnalyticsService _analyticsService;
  final SmartPromptManager _promptManager;
  GuestUserContext? _guestContext;
  String? _intendedDestination;
  dynamic _destinationArguments;
  
  AuthStateProvider({
    SupabaseClient? supabaseClient,
    GuestAnalyticsService? analyticsService,
    SmartPromptManager? promptManager,
  }) : _supabase = supabaseClient ?? Supabase.instance.client,
       _analyticsService = analyticsService ?? GuestAnalyticsService.instance,
       _promptManager = promptManager ?? SmartPromptManager.instance;
  
  /// Check if the current user is in guest mode (not authenticated)
  bool get isGuest => _supabase.auth.currentSession == null;
  
  /// Check if the current user is authenticated
  bool get isAuthenticated => _supabase.auth.currentSession != null;
  
  /// Get the current user session
  Session? get currentSession => _supabase.auth.currentSession;
  
  /// Get the current user
  User? get currentUser => _supabase.auth.currentUser;
  
  /// Get the current guest context
  GuestUserContext? get guestContext => _guestContext;
  
  /// Initialize guest context when user enters guest mode
  void initializeGuestContext() {
    if (isGuest && _guestContext == null) {
      _guestContext = GuestUserContext.create();
      _analyticsService.trackGuestSessionStart(_guestContext!);
      notifyListeners();
    }
  }
  
  /// Clear guest context when user authenticates
  void clearGuestContext() {
    if (_guestContext != null) {
      _analyticsService.trackGuestSessionEnd(_guestContext!);
      _guestContext = null;
      notifyListeners();
    }
  }
  
  /// Track content viewed by guest user
  void trackGuestContentView(String content) {
    if (isGuest && _guestContext != null) {
      _guestContext = _guestContext!.addViewedContent(content);
      
      // Parse content to extract type and ID for analytics
      final parts = content.split('_');
      final contentType = parts.isNotEmpty ? parts[0] : 'unknown';
      final contentId = parts.length > 1 ? parts.sublist(1).join('_') : content;
      
      _analyticsService.trackContentView(contentType, contentId, _guestContext!);
      notifyListeners();
    }
  }
  
  /// Navigate to registration with context about the action that triggered it
  Future<void> promptForRegistration(String context) async {
    if (isGuest && _guestContext != null) {
      // Track the action attempt that triggered the prompt
      _guestContext = _guestContext!.trackActionAttempt(context);
      _analyticsService.trackActionAttempt(context, _guestContext!);
      
      // Check if we should show the prompt using smart management
      if (_promptManager.shouldShowPrompt(context, _guestContext!)) {
        _guestContext = _guestContext!.incrementPrompts();
        _promptManager.recordPromptShown(context);
        
        final promptConfig = _promptManager.getOptimalPromptConfig(context, _guestContext!);
        _analyticsService.trackPromptShown(promptConfig, _guestContext!);
        
        notifyListeners();
      }
    }
  }
  
  /// Check if we should show registration prompt to guest user
  bool shouldShowRegistrationPrompt([String? context]) {
    if (!isGuest || _guestContext == null) return false;
    
    if (context != null) {
      return _promptManager.shouldShowPrompt(context, _guestContext!);
    }
    
    return _guestContext!.shouldShowPrompt();
  }
  
  /// Check if a specific feature requires authentication
  bool requiresAuthentication(String feature) {
    // All features that require auth
    const authRequiredFeatures = {
      'join_match',
      'hire_goalkeeper', 
      'create_announcement',
      'profile_management',
      'notifications',
      'booking_management',
    };
    
    return authRequiredFeatures.contains(feature);
  }
  
  /// Check if a route is accessible to guest users
  bool isRouteAccessibleToGuests(String route) {
    const guestAccessibleRoutes = {
      '/home',
      '/announcements', 
      '/map',
      '/profile', // Guest profile screen
      '/signin',
      '/signup',
      '/announcement-detail', // Guest users can view announcement details
    };
    
    return guestAccessibleRoutes.contains(route);
  }
  
  /// Store intended destination for post-registration redirect
  void setIntendedDestination(String destination, [dynamic arguments]) {
    _intendedDestination = destination;
    _destinationArguments = arguments;
    notifyListeners();
  }
  
  /// Get and clear intended destination
  Map<String, dynamic>? getAndClearIntendedDestination() {
    if (_intendedDestination == null) return null;
    
    final result = {
      'destination': _intendedDestination!,
      'arguments': _destinationArguments,
    };
    
    _intendedDestination = null;
    _destinationArguments = null;
    notifyListeners();
    
    return result;
  }
  
  /// Check if there's a pending intended destination
  bool get hasIntendedDestination => _intendedDestination != null;
  
  /// Record prompt response (accepted or dismissed)
  void recordPromptResponse(String context, bool accepted) {
    if (isGuest && _guestContext != null) {
      final promptConfig = RegistrationPromptConfig.forContext(context);
      _analyticsService.trackPromptResponse(promptConfig, accepted, _guestContext!);
      
      if (!accepted) {
        _promptManager.recordPromptDismissed(context);
      }
    }
  }
  
  /// Track successful registration from guest mode
  void trackGuestRegistration(String registrationSource) {
    if (_guestContext != null) {
      _analyticsService.trackGuestRegistration(_guestContext!, registrationSource);
    }
  }
  
  /// Get optimal prompt configuration for a given context
  RegistrationPromptConfig getOptimalPromptConfig(String context) {
    if (isGuest && _guestContext != null) {
      return _promptManager.getOptimalPromptConfig(context, _guestContext!);
    }
    return RegistrationPromptConfig.forContext(context);
  }
  
  /// Get guest analytics summary
  Map<String, dynamic> getGuestAnalyticsSummary() {
    if (_guestContext != null) {
      return _analyticsService.getSessionSummary(_guestContext!.sessionId);
    }
    return {};
  }
  
  /// Get prompt effectiveness metrics
  Map<String, double> getPromptEffectivenessMetrics() {
    return _analyticsService.getPromptEffectivenessMetrics();
  }
  
  /// Get content engagement metrics
  Map<String, int> getContentEngagementMetrics() {
    return _analyticsService.getContentEngagementMetrics();
  }
  
  /// Get prompt statistics
  Map<String, dynamic> getPromptStatistics() {
    return _promptManager.getPromptStatistics();
  }
}
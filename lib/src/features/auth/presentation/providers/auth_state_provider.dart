import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
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
  bool _isInPasswordRecoveryMode = false;
  
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
  
  /// Whether we're currently in password recovery mode
  bool get isInPasswordRecoveryMode => _isInPasswordRecoveryMode;
  
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

  /// Handle password recovery state - clear guest mode when in recovery
  void handlePasswordRecoveryMode() {
    // Set password recovery mode flag to prevent automatic sign-in redirection
    _isInPasswordRecoveryMode = true;
    
    // When in password recovery mode, clear any guest state
    // This ensures the user is in the proper state for password reset
    if (_guestContext != null) {
      clearGuestContext();
    }
    
    notifyListeners();
  }
  
  /// Clear password recovery mode flag
  void clearPasswordRecoveryMode() {
    _isInPasswordRecoveryMode = false;
    notifyListeners();
  }

  /// Track content viewing for guest users
  void trackGuestContentView(String content) {
    if (isGuest && _guestContext != null) {
      _guestContext = _guestContext!.addViewedContent(content);
      
      // Parse content to extract type and ID for analytics
      final parts = content.split('_');
      final contentType = parts.isNotEmpty ? parts[0] : 'unknown';
      final contentId = parts.length > 1 ? parts.sublist(1).join('_') : content;
      
      _analyticsService.trackContentView(contentType, contentId, _guestContext!);
      
      // Defer notification to avoid calling during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    }
  }
  
  /// Navigate to registration with context about the action that triggered it
  Future<void> promptForRegistration(String context) async {
    if (isGuest && _guestContext != null) {
      // Simple tracking for now - just increment action attempts
      final updatedAttempts = Map<String, int>.from(_guestContext!.actionAttempts);
      updatedAttempts[context] = (updatedAttempts[context] ?? 0) + 1;
      _guestContext = GuestUserContext(
        sessionId: _guestContext!.sessionId,
        sessionStart: _guestContext!.sessionStart,
        viewedContent: _guestContext!.viewedContent,
        actionAttempts: updatedAttempts,
        lastActivity: DateTime.now(),
      );
      
      _analyticsService.trackActionAttempt(context, _guestContext!);
      notifyListeners();
    }
  }
  
  /// Record user response to registration prompt
  void recordPromptResponse(String action, bool accepted) {
    if (_guestContext == null) return;
    
    // Get the prompt config for this action and track the response
    final config = getPromptConfig(action);
    _analyticsService.trackPromptResponse(config, accepted, _guestContext!);
  }
  
  /// Get personalized prompt configuration based on guest behavior
  RegistrationPromptConfig getPromptConfig(String action) {
    // Return basic prompt config for now
    return RegistrationPromptConfig(
      context: action,
      title: 'Criar Conta',
      message: 'Para continuar, é necessário criar uma conta.',
      primaryButtonText: 'Criar Conta',
      secondaryButtonText: 'Cancelar',
    );
  }
  
  /// Check if an action should show a registration prompt
  bool shouldShowPrompt(String action) {
    if (!isGuest || _guestContext == null) return false;
    
    // Show prompt if user hasn't attempted this action before
    return !_guestContext!.actionAttempts.containsKey(action);
  }
  
  /// Get analytics summary for the current guest session
  Map<String, dynamic> getGuestAnalyticsSummary() {
    if (_guestContext == null) return {};
    
    return {
      'session_id': _guestContext!.sessionId,
      'start_time': _guestContext!.sessionStart.toIso8601String(),
      'viewed_content_count': _guestContext!.viewedContent.length,
      'action_attempts_count': _guestContext!.actionAttempts.length,
    };
  }
  
  /// Get prompt effectiveness metrics
  Map<String, double> getPromptEffectivenessMetrics() {
    // Basic implementation
    return {
      'total_prompts': 0.0,
      'conversion_rate': 0.0,
    };
  }
  
  /// Get content engagement metrics
  Map<String, dynamic> getContentEngagementMetrics() {
    if (_guestContext == null) return {};
    
    return {
      'content_viewed': _guestContext!.viewedContent.length,
      'session_duration_minutes': DateTime.now().difference(_guestContext!.sessionStart).inMinutes,
    };
  }
  
  /// Check if a specific feature requires authentication
  bool requiresAuthentication(String feature) {
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
  
  /// Check if there's an intended destination stored
  bool get hasIntendedDestination => _intendedDestination != null;
  
  /// Get the stored intended destination without clearing it
  String? get intendedDestination => _intendedDestination;
  
  /// Get the stored destination arguments without clearing them  
  dynamic get destinationArguments => _destinationArguments;
}
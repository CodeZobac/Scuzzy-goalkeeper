import 'package:flutter/foundation.dart';
import '../models/guest_user_context.dart';
import '../models/registration_prompt_config.dart';

/// Service for tracking guest user analytics and behavior
class GuestAnalyticsService {
  static final GuestAnalyticsService _instance = GuestAnalyticsService._internal();
  factory GuestAnalyticsService() => _instance;
  GuestAnalyticsService._internal();

  static GuestAnalyticsService get instance => _instance;

  final List<Map<String, dynamic>> _analyticsEvents = [];
  final Map<String, int> _promptEffectiveness = {};
  final Map<String, int> _contentEngagement = {};

  /// Track guest session start
  void trackGuestSessionStart(GuestUserContext context) {
    _logAnalyticsEvent('guest_session_start', {
      'session_id': context.sessionId,
      'timestamp': DateTime.now().toIso8601String(),
      'platform': defaultTargetPlatform.name,
    });
  }

  /// Track guest session end
  void trackGuestSessionEnd(GuestUserContext context) {
    final sessionData = context.toAnalyticsMap();
    sessionData['event_type'] = 'guest_session_end';
    sessionData['timestamp'] = DateTime.now().toIso8601String();
    
    _logAnalyticsEvent('guest_session_end', sessionData);
  }

  /// Track content viewed by guest user
  void trackContentView(String contentType, String contentId, GuestUserContext context) {
    final key = '${contentType}_$contentId';
    _contentEngagement[key] = (_contentEngagement[key] ?? 0) + 1;
    
    _logAnalyticsEvent('guest_content_view', {
      'session_id': context.sessionId,
      'content_type': contentType,
      'content_id': contentId,
      'session_duration_minutes': context.sessionDuration.inMinutes,
      'total_content_viewed': context.viewedContent.length,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Track registration prompt shown
  void trackPromptShown(RegistrationPromptConfig config, GuestUserContext context) {
    _logAnalyticsEvent('registration_prompt_shown', {
      'session_id': context.sessionId,
      'prompt_context': config.context,
      'prompt_title': config.title,
      'prompts_shown_in_session': context.promptsShown + 1,
      'session_duration_minutes': context.sessionDuration.inMinutes,
      'content_viewed_count': context.viewedContent.length,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Track registration prompt response
  void trackPromptResponse(RegistrationPromptConfig config, bool accepted, GuestUserContext context) {
    final promptKey = config.context;
    if (accepted) {
      _promptEffectiveness[promptKey] = (_promptEffectiveness[promptKey] ?? 0) + 1;
    }
    
    _logAnalyticsEvent('registration_prompt_response', {
      'session_id': context.sessionId,
      'prompt_context': config.context,
      'accepted': accepted,
      'prompts_shown_in_session': context.promptsShown,
      'session_duration_minutes': context.sessionDuration.inMinutes,
      'content_viewed_count': context.viewedContent.length,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Track guest user action attempt (that requires auth)
  void trackActionAttempt(String action, GuestUserContext context) {
    _logAnalyticsEvent('guest_action_attempt', {
      'session_id': context.sessionId,
      'action': action,
      'session_duration_minutes': context.sessionDuration.inMinutes,
      'content_viewed_count': context.viewedContent.length,
      'prompts_shown_in_session': context.promptsShown,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Track successful registration from guest mode
  void trackGuestRegistration(GuestUserContext context, String registrationSource) {
    _logAnalyticsEvent('guest_registration_success', {
      'session_id': context.sessionId,
      'registration_source': registrationSource,
      'session_duration_minutes': context.sessionDuration.inMinutes,
      'content_viewed_count': context.viewedContent.length,
      'prompts_shown_in_session': context.promptsShown,
      'viewed_content': context.viewedContent,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Get prompt effectiveness metrics
  Map<String, double> getPromptEffectivenessMetrics() {
    final metrics = <String, double>{};
    
    for (final entry in _promptEffectiveness.entries) {
      final promptType = entry.key;
      final acceptedCount = entry.value;
      final totalShown = _getPromptShownCount(promptType);
      
      if (totalShown > 0) {
        metrics[promptType] = acceptedCount / totalShown;
      }
    }
    
    return metrics;
  }

  /// Get content engagement metrics
  Map<String, int> getContentEngagementMetrics() {
    return Map.from(_contentEngagement);
  }

  /// Get all analytics events (for debugging or export)
  List<Map<String, dynamic>> getAllAnalyticsEvents() {
    return List.from(_analyticsEvents);
  }

  /// Get analytics summary for a specific session
  Map<String, dynamic> getSessionSummary(String sessionId) {
    final sessionEvents = _analyticsEvents
        .where((event) => event['session_id'] == sessionId)
        .toList();

    if (sessionEvents.isEmpty) {
      return {};
    }

    final startEvent = sessionEvents
        .where((event) => event['event_type'] == 'guest_session_start')
        .firstOrNull;
    final endEvent = sessionEvents
        .where((event) => event['event_type'] == 'guest_session_end')
        .firstOrNull;

    final contentViews = sessionEvents
        .where((event) => event['event_type'] == 'guest_content_view')
        .length;
    final promptsShown = sessionEvents
        .where((event) => event['event_type'] == 'registration_prompt_shown')
        .length;
    final promptsAccepted = sessionEvents
        .where((event) => 
            event['event_type'] == 'registration_prompt_response' && 
            event['accepted'] == true)
        .length;

    return {
      'session_id': sessionId,
      'start_time': startEvent?['timestamp'],
      'end_time': endEvent?['timestamp'],
      'content_views': contentViews,
      'prompts_shown': promptsShown,
      'prompts_accepted': promptsAccepted,
      'conversion_rate': promptsShown > 0 ? promptsAccepted / promptsShown : 0.0,
      'total_events': sessionEvents.length,
    };
  }

  /// Clear analytics data (for testing or privacy)
  void clearAnalyticsData() {
    _analyticsEvents.clear();
    _promptEffectiveness.clear();
    _contentEngagement.clear();
  }

  /// Log analytics event
  void _logAnalyticsEvent(String eventType, Map<String, dynamic> data) {
    final event = {
      'event_type': eventType,
      'timestamp': DateTime.now().toIso8601String(),
      ...data,
    };
    
    _analyticsEvents.add(event);
    
    // In a real app, you would send this to your analytics service
    // For now, we'll just log it for debugging
    if (kDebugMode) {
      debugPrint('Guest Analytics Event: $eventType - ${event.toString()}');
    }
  }

  /// Get count of prompts shown for a specific type
  int _getPromptShownCount(String promptType) {
    return _analyticsEvents
        .where((event) => 
            event['event_type'] == 'registration_prompt_shown' &&
            event['prompt_context'] == promptType)
        .length;
  }
}
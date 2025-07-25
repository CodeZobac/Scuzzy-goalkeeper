import 'package:flutter_test/flutter_test.dart';
import 'package:goalkeeper/src/features/auth/data/services/guest_analytics_service.dart';
import 'package:goalkeeper/src/features/auth/data/services/smart_prompt_manager.dart';
import 'package:goalkeeper/src/features/auth/data/models/guest_user_context.dart';
import 'package:goalkeeper/src/features/auth/data/models/registration_prompt_config.dart';

void main() {
  group('Guest Analytics and Smart Prompt Integration', () {
    late GuestAnalyticsService analyticsService;
    late SmartPromptManager promptManager;
    late GuestUserContext guestContext;

    setUp(() {
      analyticsService = GuestAnalyticsService.instance;
      promptManager = SmartPromptManager.instance;
      
      // Clear any existing data
      analyticsService.clearAnalyticsData();
      promptManager.resetPromptHistory();
      
      guestContext = GuestUserContext.create();
    });

    tearDown(() {
      analyticsService.clearAnalyticsData();
      promptManager.resetPromptHistory();
    });

    test('should integrate analytics and smart prompt management', () {
      // Track session start
      analyticsService.trackGuestSessionStart(guestContext);
      
      // Track content views
      analyticsService.trackContentView('announcement', '123', guestContext);
      analyticsService.trackContentView('map', 'field_456', guestContext);
      
      // Update context with viewed content
      final updatedContext = guestContext
          .addViewedContent('announcement_123')
          .addViewedContent('map_field_456');
      
      // Check if prompt should be shown
      final shouldShow = promptManager.shouldShowPrompt('join_match', updatedContext);
      expect(shouldShow, false); // Should be false due to timing (new session)
      
      // Create context with past start time to pass timing check
      final pastTime = DateTime.now().subtract(const Duration(minutes: 2));
      final timedContext = updatedContext.copyWith(sessionStart: pastTime);
      
      final shouldShowWithTiming = promptManager.shouldShowPrompt('join_match', timedContext);
      expect(shouldShowWithTiming, true);
      
      // Record prompt shown
      promptManager.recordPromptShown('join_match');
      
      // Get optimal prompt config
      final config = promptManager.getOptimalPromptConfig('join_match', timedContext);
      expect(config.context, 'join_match');
      expect(config.metadata['user_engagement'], 'casual');
      
      // Track prompt shown in analytics
      analyticsService.trackPromptShown(config, timedContext);
      
      // Track prompt response
      analyticsService.trackPromptResponse(config, true, timedContext);
      
      // Track session end
      analyticsService.trackGuestSessionEnd(timedContext);
      
      // Verify analytics data
      final events = analyticsService.getAllAnalyticsEvents();
      expect(events.length, 6); // session_start, 2 content_views, prompt_shown, prompt_response, session_end
      
      final sessionSummary = analyticsService.getSessionSummary(guestContext.sessionId);
      expect(sessionSummary['content_views'], 2);
      expect(sessionSummary['prompts_shown'], 1);
      expect(sessionSummary['prompts_accepted'], 1);
      expect(sessionSummary['conversion_rate'], 1.0);
      
      // Verify prompt statistics
      final promptStats = promptManager.getPromptStatistics();
      expect(promptStats['join_match']['total_shown'], 1);
      expect(promptStats['join_match']['total_dismissed'], 0);
    });

    test('should handle highly engaged user flow', () {
      // Create highly engaged context
      final pastTime = DateTime.now().subtract(const Duration(minutes: 2));
      final highlyEngagedContext = guestContext
          .copyWith(sessionStart: pastTime)
          .addViewedContent('announcement_123')
          .addViewedContent('map_field_456')
          .trackActionAttempt('join_match')
          .trackActionAttempt('hire_goalkeeper');
      
      expect(highlyEngagedContext.isHighlyEngaged, true);
      
      // Should allow prompt for highly engaged user
      final shouldShow = promptManager.shouldShowPrompt('join_match', highlyEngagedContext);
      expect(shouldShow, true);
      
      // Get enhanced prompt config
      final config = promptManager.getOptimalPromptConfig('join_match', highlyEngagedContext);
      expect(config.metadata['user_engagement'], 'high');
      expect(config.primaryButtonText, 'Vamos Começar!');
      expect(config.message.contains('interessado em participar'), true);
      
      // Track analytics
      analyticsService.trackGuestSessionStart(highlyEngagedContext);
      analyticsService.trackActionAttempt('join_match', highlyEngagedContext);
      analyticsService.trackPromptShown(config, highlyEngagedContext);
      analyticsService.trackPromptResponse(config, true, highlyEngagedContext);
      analyticsService.trackGuestRegistration(highlyEngagedContext, 'join_match_prompt');
      
      // Verify registration tracking
      final events = analyticsService.getAllAnalyticsEvents();
      final registrationEvents = events.where((e) => e['event_type'] == 'guest_registration_success').toList();
      expect(registrationEvents.length, 1);
      expect(registrationEvents.first['registration_source'], 'join_match_prompt');
    });

    test('should handle prompt fatigue correctly', () {
      final pastTime = DateTime.now().subtract(const Duration(minutes: 2));
      final engagedContext = guestContext
          .copyWith(sessionStart: pastTime)
          .addViewedContent('announcement_123');
      
      // First show some prompts, then dismiss them to trigger fatigue
      promptManager.recordPromptShown('join_match');
      promptManager.recordPromptDismissed('join_match');
      promptManager.recordPromptShown('join_match');
      promptManager.recordPromptDismissed('join_match');
      promptManager.recordPromptShown('join_match');
      promptManager.recordPromptDismissed('join_match');
      
      // Should not show prompt due to fatigue
      final shouldShow = promptManager.shouldShowPrompt('join_match', engagedContext);
      expect(shouldShow, false);
      
      // But should allow different prompt type
      final shouldShowDifferent = promptManager.shouldShowPrompt('hire_goalkeeper', engagedContext);
      expect(shouldShowDifferent, true);
      
      // Verify prompt statistics
      final stats = promptManager.getPromptStatistics();
      expect(stats['join_match']?['total_shown'] ?? 0, 3);
      expect(stats['join_match']?['total_dismissed'] ?? 0, 3);
      expect(stats['join_match']?['dismissal_rate'] ?? 0.0, 1.0);
    });

    test('should track content engagement metrics', () {
      // Track various content views
      analyticsService.trackContentView('announcement', '123', guestContext);
      analyticsService.trackContentView('announcement', '123', guestContext); // Duplicate
      analyticsService.trackContentView('map', 'field_456', guestContext);
      analyticsService.trackContentView('profile', 'guest', guestContext);
      
      final metrics = analyticsService.getContentEngagementMetrics();
      expect(metrics['announcement_123'], 2); // Duplicate views counted
      expect(metrics['map_field_456'], 1);
      expect(metrics['profile_guest'], 1);
    });

    test('should calculate prompt effectiveness across contexts', () {
      const joinMatchConfig = RegistrationPromptConfig.joinMatch;
      const hireGoalkeeperConfig = RegistrationPromptConfig.hireGoalkeeper;
      
      // Simulate multiple prompt interactions
      analyticsService.trackPromptShown(joinMatchConfig, guestContext);
      analyticsService.trackPromptResponse(joinMatchConfig, true, guestContext);
      
      analyticsService.trackPromptShown(joinMatchConfig, guestContext);
      analyticsService.trackPromptResponse(joinMatchConfig, false, guestContext);
      
      analyticsService.trackPromptShown(hireGoalkeeperConfig, guestContext);
      analyticsService.trackPromptResponse(hireGoalkeeperConfig, true, guestContext);
      
      final effectiveness = analyticsService.getPromptEffectivenessMetrics();
      expect(effectiveness['join_match'], 0.5); // 1 out of 2 accepted
      expect(effectiveness['hire_goalkeeper'], 1.0); // 1 out of 1 accepted
    });
  });
}
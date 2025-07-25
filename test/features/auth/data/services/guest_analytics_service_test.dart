import 'package:flutter_test/flutter_test.dart';
import 'package:goalkeeper/src/features/auth/data/services/guest_analytics_service.dart';
import 'package:goalkeeper/src/features/auth/data/models/guest_user_context.dart';
import 'package:goalkeeper/src/features/auth/data/models/registration_prompt_config.dart';

void main() {
  group('GuestAnalyticsService', () {
    late GuestAnalyticsService analyticsService;
    late GuestUserContext guestContext;

    setUp(() {
      analyticsService = GuestAnalyticsService.instance;
      analyticsService.clearAnalyticsData();
      guestContext = GuestUserContext.create();
    });

    tearDown(() {
      analyticsService.clearAnalyticsData();
    });

    group('Session Tracking', () {
      test('should track guest session start', () {
        analyticsService.trackGuestSessionStart(guestContext);
        
        final events = analyticsService.getAllAnalyticsEvents();
        expect(events.length, 1);
        expect(events.first['event_type'], 'guest_session_start');
        expect(events.first['session_id'], guestContext.sessionId);
      });

      test('should track guest session end', () {
        analyticsService.trackGuestSessionEnd(guestContext);
        
        final events = analyticsService.getAllAnalyticsEvents();
        expect(events.length, 1);
        expect(events.first['event_type'], 'guest_session_end');
        expect(events.first['session_id'], guestContext.sessionId);
      });

      test('should include session data in session end event', () {
        final contextWithData = guestContext
            .addViewedContent('announcement_123')
            .incrementPrompts();
        
        analyticsService.trackGuestSessionEnd(contextWithData);
        
        final events = analyticsService.getAllAnalyticsEvents();
        final sessionEndEvent = events.first;
        
        expect(sessionEndEvent['viewed_content_count'], 1);
        expect(sessionEndEvent['prompts_shown'], 1);
        expect(sessionEndEvent['engagement_score'], isA<double>());
      });
    });

    group('Content Tracking', () {
      test('should track content views', () {
        analyticsService.trackContentView('announcement', '123', guestContext);
        
        final events = analyticsService.getAllAnalyticsEvents();
        expect(events.length, 1);
        expect(events.first['event_type'], 'guest_content_view');
        expect(events.first['content_type'], 'announcement');
        expect(events.first['content_id'], '123');
      });

      test('should track multiple content views', () {
        analyticsService.trackContentView('announcement', '123', guestContext);
        analyticsService.trackContentView('map', 'field_456', guestContext);
        
        final events = analyticsService.getAllAnalyticsEvents();
        expect(events.length, 2);
        
        final engagementMetrics = analyticsService.getContentEngagementMetrics();
        expect(engagementMetrics['announcement_123'], 1);
        expect(engagementMetrics['map_field_456'], 1);
      });

      test('should increment engagement count for repeated views', () {
        analyticsService.trackContentView('announcement', '123', guestContext);
        analyticsService.trackContentView('announcement', '123', guestContext);
        
        final engagementMetrics = analyticsService.getContentEngagementMetrics();
        expect(engagementMetrics['announcement_123'], 2);
      });
    });

    group('Prompt Tracking', () {
      test('should track prompt shown', () {
        const config = RegistrationPromptConfig.joinMatch;
        analyticsService.trackPromptShown(config, guestContext);
        
        final events = analyticsService.getAllAnalyticsEvents();
        expect(events.length, 1);
        expect(events.first['event_type'], 'registration_prompt_shown');
        expect(events.first['prompt_context'], 'join_match');
      });

      test('should track prompt response', () {
        const config = RegistrationPromptConfig.joinMatch;
        analyticsService.trackPromptResponse(config, true, guestContext);
        
        final events = analyticsService.getAllAnalyticsEvents();
        expect(events.length, 1);
        expect(events.first['event_type'], 'registration_prompt_response');
        expect(events.first['accepted'], true);
      });

      test('should calculate prompt effectiveness metrics', () {
        const config = RegistrationPromptConfig.joinMatch;
        
        // Show prompt 3 times, accept 2 times
        analyticsService.trackPromptShown(config, guestContext);
        analyticsService.trackPromptResponse(config, true, guestContext);
        
        analyticsService.trackPromptShown(config, guestContext);
        analyticsService.trackPromptResponse(config, false, guestContext);
        
        analyticsService.trackPromptShown(config, guestContext);
        analyticsService.trackPromptResponse(config, true, guestContext);
        
        final metrics = analyticsService.getPromptEffectivenessMetrics();
        expect(metrics['join_match'], closeTo(0.67, 0.01)); // 2/3 = 0.67
      });
    });

    group('Action Tracking', () {
      test('should track guest action attempts', () {
        analyticsService.trackActionAttempt('join_match', guestContext);
        
        final events = analyticsService.getAllAnalyticsEvents();
        expect(events.length, 1);
        expect(events.first['event_type'], 'guest_action_attempt');
        expect(events.first['action'], 'join_match');
      });

      test('should track guest registration success', () {
        analyticsService.trackGuestRegistration(guestContext, 'join_match_prompt');
        
        final events = analyticsService.getAllAnalyticsEvents();
        expect(events.length, 1);
        expect(events.first['event_type'], 'guest_registration_success');
        expect(events.first['registration_source'], 'join_match_prompt');
      });
    });

    group('Session Summary', () {
      test('should generate session summary', () {
        const config = RegistrationPromptConfig.joinMatch;
        
        // Simulate a guest session
        analyticsService.trackGuestSessionStart(guestContext);
        analyticsService.trackContentView('announcement', '123', guestContext);
        analyticsService.trackContentView('map', 'field_456', guestContext);
        analyticsService.trackPromptShown(config, guestContext);
        analyticsService.trackPromptResponse(config, true, guestContext);
        analyticsService.trackGuestSessionEnd(guestContext);
        
        final summary = analyticsService.getSessionSummary(guestContext.sessionId);
        
        expect(summary['session_id'], guestContext.sessionId);
        expect(summary['content_views'], 2);
        expect(summary['prompts_shown'], 1);
        expect(summary['prompts_accepted'], 1);
        expect(summary['conversion_rate'], 1.0);
        expect(summary['total_events'], 6);
      });

      test('should return empty summary for non-existent session', () {
        final summary = analyticsService.getSessionSummary('non_existent_session');
        expect(summary, isEmpty);
      });
    });

    group('Data Management', () {
      test('should clear analytics data', () {
        analyticsService.trackGuestSessionStart(guestContext);
        analyticsService.trackContentView('announcement', '123', guestContext);
        
        expect(analyticsService.getAllAnalyticsEvents().length, 2);
        expect(analyticsService.getContentEngagementMetrics().isNotEmpty, true);
        
        analyticsService.clearAnalyticsData();
        
        expect(analyticsService.getAllAnalyticsEvents().isEmpty, true);
        expect(analyticsService.getContentEngagementMetrics().isEmpty, true);
      });

      test('should handle multiple sessions', () async {
        final context1 = GuestUserContext.create();
        // Add small delay to ensure different session IDs
        await Future.delayed(const Duration(milliseconds: 1));
        final context2 = GuestUserContext.create();
        
        analyticsService.trackGuestSessionStart(context1);
        analyticsService.trackGuestSessionStart(context2);
        
        final events = analyticsService.getAllAnalyticsEvents();
        expect(events.length, 2);
        
        final sessionIds = events.map((e) => e['session_id']).toSet();
        expect(sessionIds.length, 2);
        expect(sessionIds.contains(context1.sessionId), true);
        expect(sessionIds.contains(context2.sessionId), true);
      });
    });
  });
}
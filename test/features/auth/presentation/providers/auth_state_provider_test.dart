import 'package:flutter_test/flutter_test.dart';
import 'package:goalkeeper/src/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:goalkeeper/src/features/auth/data/services/guest_analytics_service.dart';
import 'package:goalkeeper/src/features/auth/data/services/smart_prompt_manager.dart';
import 'package:goalkeeper/src/features/auth/data/models/registration_prompt_config.dart';

void main() {
  group('AuthStateProvider Integration Tests', () {
    late AuthStateProvider authProvider;
    late GuestAnalyticsService analyticsService;
    late SmartPromptManager promptManager;

    setUp(() {
      // Use real instances for integration testing
      analyticsService = GuestAnalyticsService.instance;
      promptManager = SmartPromptManager.instance;
      
      // Clear any existing data
      analyticsService.clearAnalyticsData();
      promptManager.resetPromptHistory();
      
      authProvider = AuthStateProvider(
        analyticsService: analyticsService,
        promptManager: promptManager,
      );
    });

    group('Guest Context Management', () {
      test('should initialize guest context', () {
        authProvider.initializeGuestContext();
        
        expect(authProvider.guestContext, isNotNull);
        expect(authProvider.guestContext!.sessionId.startsWith('guest_'), true);
      });

      test('should clear guest context', () {
        authProvider.initializeGuestContext();
        expect(authProvider.guestContext, isNotNull);
        
        authProvider.clearGuestContext();
        expect(authProvider.guestContext, isNull);
      });
    });

    group('Content Tracking', () {
      setUp(() {
        authProvider.initializeGuestContext();
      });

      test('should track guest content views', () {
        authProvider.trackGuestContentView('announcement_123');
        
        expect(authProvider.guestContext!.viewedContent.contains('announcement_123'), true);
        
        // Check analytics events
        final events = analyticsService.getAllAnalyticsEvents();
        final contentViewEvents = events.where((e) => e['event_type'] == 'guest_content_view').toList();
        expect(contentViewEvents.length, 1);
        expect(contentViewEvents.first['content_type'], 'announcement');
        expect(contentViewEvents.first['content_id'], '123');
      });

      test('should parse complex content identifiers', () {
        authProvider.trackGuestContentView('map_field_456_details');
        
        final events = analyticsService.getAllAnalyticsEvents();
        final contentViewEvents = events.where((e) => e['event_type'] == 'guest_content_view').toList();
        expect(contentViewEvents.first['content_type'], 'map');
        expect(contentViewEvents.first['content_id'], 'field_456_details');
      });
    });

    group('Registration Prompts', () {
      setUp(() {
        authProvider.initializeGuestContext();
      });

      test('should handle prompt for registration with analytics tracking', () {
        authProvider.promptForRegistration('join_match');
        
        // Check that action attempt was tracked
        expect(authProvider.guestContext!.actionAttempts['join_match'], 1);
        
        // Check analytics events
        final events = analyticsService.getAllAnalyticsEvents();
        final actionEvents = events.where((e) => e['event_type'] == 'guest_action_attempt').toList();
        expect(actionEvents.length, 1);
        expect(actionEvents.first['action'], 'join_match');
      });

      test('should get optimal prompt configuration', () {
        final config = authProvider.getOptimalPromptConfig('join_match');
        
        expect(config.context, 'join_match');
        expect(config.title, isNotEmpty);
        expect(config.message, isNotEmpty);
      });
    });

    group('Prompt Response Tracking', () {
      setUp(() {
        authProvider.initializeGuestContext();
      });

      test('should record prompt acceptance', () {
        authProvider.recordPromptResponse('join_match', true);
        
        final events = analyticsService.getAllAnalyticsEvents();
        final responseEvents = events.where((e) => e['event_type'] == 'registration_prompt_response').toList();
        expect(responseEvents.length, 1);
        expect(responseEvents.first['accepted'], true);
        expect(responseEvents.first['prompt_context'], 'join_match');
      });

      test('should record prompt dismissal', () {
        authProvider.recordPromptResponse('join_match', false);
        
        final events = analyticsService.getAllAnalyticsEvents();
        final responseEvents = events.where((e) => e['event_type'] == 'registration_prompt_response').toList();
        expect(responseEvents.length, 1);
        expect(responseEvents.first['accepted'], false);
      });
    });

    group('Route Access Control', () {
      test('should allow guest access to public routes', () {
        expect(authProvider.isRouteAccessibleToGuests('/home'), true);
        expect(authProvider.isRouteAccessibleToGuests('/announcements'), true);
        expect(authProvider.isRouteAccessibleToGuests('/map'), true);
        expect(authProvider.isRouteAccessibleToGuests('/profile'), true);
        expect(authProvider.isRouteAccessibleToGuests('/signin'), true);
        expect(authProvider.isRouteAccessibleToGuests('/signup'), true);
      });

      test('should block guest access to restricted routes', () {
        expect(authProvider.isRouteAccessibleToGuests('/create-announcement'), false);
        expect(authProvider.isRouteAccessibleToGuests('/notification-preferences'), false);
        expect(authProvider.isRouteAccessibleToGuests('/admin'), false);
      });

      test('should identify features requiring authentication', () {
        expect(authProvider.requiresAuthentication('join_match'), true);
        expect(authProvider.requiresAuthentication('hire_goalkeeper'), true);
        expect(authProvider.requiresAuthentication('create_announcement'), true);
        expect(authProvider.requiresAuthentication('profile_management'), true);
        expect(authProvider.requiresAuthentication('notifications'), true);
      });
    });

    group('Analytics Integration', () {
      setUp(() {
        authProvider.initializeGuestContext();
      });

      test('should get analytics summary', () {
        // Add some activity to create analytics data
        authProvider.trackGuestContentView('announcement_123');
        authProvider.recordPromptResponse('join_match', true);
        
        final summary = authProvider.getGuestAnalyticsSummary();
        
        expect(summary['session_id'], isNotNull);
        expect(summary, isA<Map<String, dynamic>>());
      });

      test('should get prompt effectiveness metrics', () {
        final metrics = authProvider.getPromptEffectivenessMetrics();
        expect(metrics, isA<Map<String, double>>());
      });

      test('should get content engagement metrics', () {
        authProvider.trackGuestContentView('announcement_123');
        
        final metrics = authProvider.getContentEngagementMetrics();
        expect(metrics, isA<Map<String, int>>());
        expect(metrics['announcement_123'], 1);
      });
    });
  });
}
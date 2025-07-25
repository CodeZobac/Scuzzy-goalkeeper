import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:goalkeeper/src/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:goalkeeper/src/features/auth/data/models/guest_user_context.dart';
import 'package:goalkeeper/src/features/auth/data/models/registration_prompt_config.dart';
import 'package:goalkeeper/src/core/utils/guest_mode_utils.dart';

// Generate mocks
@GenerateMocks([SupabaseClient, GoTrueClient, Session, User])
import 'guest_mode_integration_test.mocks.dart';

void main() {
  group('Guest Mode Integration Tests', () {
    late AuthStateProvider authStateProvider;
    late MockSupabaseClient mockSupabaseClient;
    late MockGoTrueClient mockGoTrueClient;
    late MockSession mockSession;
    late MockUser mockUser;

    setUp(() {
      mockSupabaseClient = MockSupabaseClient();
      mockGoTrueClient = MockGoTrueClient();
      mockSession = MockSession();
      mockUser = MockUser();
      
      when(mockSupabaseClient.auth).thenReturn(mockGoTrueClient);
      
      authStateProvider = AuthStateProvider(supabaseClient: mockSupabaseClient);
      GuestModeUtils.setTestClient(mockSupabaseClient);
    });

    tearDown(() {
      GuestModeUtils.setTestClient(null);
    });

    group('Complete Guest User Journey', () {
      test('should handle complete guest user flow from entry to registration prompt', () async {
        // Arrange - User starts as guest
        when(mockGoTrueClient.currentSession).thenReturn(null);
        
        // Act & Assert - Initial state
        expect(authStateProvider.isGuest, isTrue);
        expect(GuestModeUtils.isGuest, isTrue);
        expect(authStateProvider.guestContext, isNull);
        
        // Initialize guest context
        authStateProvider.initializeGuestContext();
        expect(authStateProvider.guestContext, isNotNull);
        expect(authStateProvider.guestContext!.viewedContent, isEmpty);
        expect(authStateProvider.guestContext!.promptsShown, equals(0));
        
        // User views content
        authStateProvider.trackGuestContentView('announcement_1');
        authStateProvider.trackGuestContentView('map_view');
        
        expect(authStateProvider.guestContext!.viewedContent.length, equals(2));
        expect(authStateProvider.shouldShowRegistrationPrompt(), isTrue);
        
        // User attempts restricted action - join match
        expect(GuestModeUtils.actionRequiresAuth('join_match'), isTrue);
        expect(GuestModeUtils.getGuestRedirectRoute('join_match'), equals('/signup'));
        
        // Show registration prompt
        await authStateProvider.promptForRegistration('join_match');
        expect(authStateProvider.guestContext!.promptsShown, equals(1));
        
        // Get appropriate prompt configuration
        final promptConfig = RegistrationPromptConfig.forContext('join_match');
        expect(promptConfig.title, equals('Participe da Partida!'));
        expect(promptConfig.context, equals('join_match'));
        
        // User continues as guest and views more content
        authStateProvider.trackGuestContentView('goalkeeper_profile');
        expect(authStateProvider.guestContext!.viewedContent.length, equals(3));
        
        // User attempts another restricted action - hire goalkeeper
        expect(GuestModeUtils.actionRequiresAuth('hire_goalkeeper'), isTrue);
        await authStateProvider.promptForRegistration('hire_goalkeeper');
        expect(authStateProvider.guestContext!.promptsShown, equals(2));
        
        // Still should show prompts (under limit of 3)
        expect(authStateProvider.shouldShowRegistrationPrompt(), isTrue);
        
        // One more prompt
        await authStateProvider.promptForRegistration('create_announcement');
        expect(authStateProvider.guestContext!.promptsShown, equals(3));
        
        // Now should not show more prompts (reached limit)
        expect(authStateProvider.shouldShowRegistrationPrompt(), isFalse);
      });

      test('should handle guest to authenticated user transition', () {
        // Arrange - Start as guest
        when(mockGoTrueClient.currentSession).thenReturn(null);
        authStateProvider.initializeGuestContext();
        authStateProvider.trackGuestContentView('test_content');
        
        expect(authStateProvider.isGuest, isTrue);
        expect(authStateProvider.guestContext, isNotNull);
        
        // Act - User authenticates
        when(mockGoTrueClient.currentSession).thenReturn(mockSession);
        when(mockGoTrueClient.currentUser).thenReturn(mockUser);
        authStateProvider.clearGuestContext();
        
        // Assert - Now authenticated
        expect(authStateProvider.isAuthenticated, isTrue);
        expect(authStateProvider.guestContext, isNull);
        expect(authStateProvider.shouldShowRegistrationPrompt(), isFalse);
      });
    });

    group('Route Access Control Integration', () {
      test('should correctly handle route access for guest users', () {
        // Arrange
        when(mockGoTrueClient.currentSession).thenReturn(null);
        
        // Act & Assert - Guest accessible routes
        expect(authStateProvider.isRouteAccessibleToGuests('/home'), isTrue);
        expect(authStateProvider.isRouteAccessibleToGuests('/announcements'), isTrue);
        expect(authStateProvider.isRouteAccessibleToGuests('/map'), isTrue);
        expect(authStateProvider.isRouteAccessibleToGuests('/profile'), isTrue);
        expect(authStateProvider.isRouteAccessibleToGuests('/signin'), isTrue);
        expect(authStateProvider.isRouteAccessibleToGuests('/signup'), isTrue);
        
        // Verify same routes with GuestModeUtils
        expect(GuestModeUtils.isGuestAccessibleRoute('/home'), isTrue);
        expect(GuestModeUtils.isGuestAccessibleRoute('/announcements'), isTrue);
        expect(GuestModeUtils.isGuestAccessibleRoute('/map'), isTrue);
        
        // Restricted routes
        expect(authStateProvider.isRouteAccessibleToGuests('/create-announcement'), isFalse);
        expect(GuestModeUtils.isGuestAccessibleRoute('/notifications'), isFalse);
      });
    });

    group('Feature Access Control Integration', () {
      test('should correctly identify feature access requirements', () {
        // Auth required features
        expect(authStateProvider.requiresAuthentication('join_match'), isTrue);
        expect(GuestModeUtils.actionRequiresAuth('join_match'), isTrue);
        
        expect(authStateProvider.requiresAuthentication('hire_goalkeeper'), isTrue);
        expect(GuestModeUtils.actionRequiresAuth('hire_goalkeeper'), isTrue);
        
        expect(authStateProvider.requiresAuthentication('create_announcement'), isTrue);
        expect(GuestModeUtils.actionRequiresAuth('create_announcement'), isTrue);
        
        // Guest accessible features
        expect(GuestModeUtils.canGuestAccess('view_announcements'), isTrue);
        expect(GuestModeUtils.canGuestAccess('view_map'), isTrue);
        expect(GuestModeUtils.canGuestAccess('browse_content'), isTrue);
      });
    });

    group('Analytics and Context Integration', () {
      test('should provide comprehensive analytics data for guest sessions', () {
        // Arrange
        when(mockGoTrueClient.currentSession).thenReturn(null);
        authStateProvider.initializeGuestContext();
        
        // Act - Simulate user activity
        authStateProvider.trackGuestContentView('announcement_1');
        authStateProvider.trackGuestContentView('map_view');
        authStateProvider.promptForRegistration('join_match');
        
        // Assert - Analytics data
        final context = authStateProvider.guestContext!;
        final analyticsData = context.toAnalyticsMap();
        
        expect(analyticsData['session_id'], isNotEmpty);
        expect(analyticsData['viewed_content_count'], equals(2));
        expect(analyticsData['prompts_shown'], equals(1));
        expect(analyticsData['session_duration_minutes'], isA<int>());
        
        // Prompt configuration analytics
        final promptConfig = RegistrationPromptConfig.forContext('join_match');
        final promptAnalytics = promptConfig.toAnalyticsMap();
        
        expect(promptAnalytics['context'], equals('join_match'));
        expect(promptAnalytics['title'], contains('Participe'));
      });
    });

    group('Error Handling and Edge Cases', () {
      test('should handle null sessions gracefully', () {
        // Arrange
        when(mockGoTrueClient.currentSession).thenReturn(null);
        when(mockGoTrueClient.currentUser).thenReturn(null);
        
        // Act & Assert
        expect(authStateProvider.isGuest, isTrue);
        expect(authStateProvider.currentSession, isNull);
        expect(authStateProvider.currentUser, isNull);
        expect(GuestModeUtils.currentSession, isNull);
        expect(GuestModeUtils.currentUser, isNull);
      });

      test('should handle context operations when not initialized', () {
        // Arrange - No guest context initialized
        when(mockGoTrueClient.currentSession).thenReturn(null);
        
        // Act & Assert - Should not crash
        authStateProvider.trackGuestContentView('test');
        expect(authStateProvider.guestContext, isNull);
        
        authStateProvider.promptForRegistration('test');
        expect(authStateProvider.guestContext, isNull);
        
        expect(authStateProvider.shouldShowRegistrationPrompt(), isFalse);
      });

      test('should handle authenticated user operations gracefully', () {
        // Arrange - Authenticated user
        when(mockGoTrueClient.currentSession).thenReturn(mockSession);
        
        // Act & Assert - Guest operations should be no-ops
        authStateProvider.initializeGuestContext();
        expect(authStateProvider.guestContext, isNull);
        
        authStateProvider.trackGuestContentView('test');
        expect(authStateProvider.guestContext, isNull);
        
        expect(authStateProvider.shouldShowRegistrationPrompt(), isFalse);
      });
    });
  });
}
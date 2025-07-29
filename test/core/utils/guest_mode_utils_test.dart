import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:goalkeeper/src/core/utils/guest_mode_utils.dart';

// Generate mocks
@GenerateMocks([SupabaseClient, GoTrueClient, Session, User])
import 'guest_mode_utils_test.mocks.dart';

void main() {
  group('GuestModeUtils', () {
    late MockSupabaseClient mockSupabaseClient;
    late MockGoTrueClient mockGoTrueClient;
    late MockSession mockSession;
    late MockUser mockUser;

    setUp(() {
      mockSupabaseClient = MockSupabaseClient();
      mockGoTrueClient = MockGoTrueClient();
      mockSession = MockSession();
      mockUser = MockUser();
      
      // Mock the Supabase instance
      when(mockSupabaseClient.auth).thenReturn(mockGoTrueClient);
      
      // Set the test client
      GuestModeUtils.setTestClient(mockSupabaseClient);
    });
    
    tearDown(() {
      // Clean up test client
      GuestModeUtils.setTestClient(null);
    });

    group('Authentication State Detection', () {
      test('should correctly detect guest mode when no session exists', () {
        // Arrange
        when(mockGoTrueClient.currentSession).thenReturn(null);
        
        // Act & Assert
        expect(GuestModeUtils.isGuest, isTrue);
        expect(GuestModeUtils.isAuthenticated, isFalse);
        expect(GuestModeUtils.currentSession, isNull);
      });

      test('should correctly detect authenticated state when session exists', () {
        // Arrange
        when(mockGoTrueClient.currentSession).thenReturn(mockSession);
        when(mockGoTrueClient.currentUser).thenReturn(mockUser);
        
        // Act & Assert
        expect(GuestModeUtils.isGuest, isFalse);
        expect(GuestModeUtils.isAuthenticated, isTrue);
        expect(GuestModeUtils.currentSession, equals(mockSession));
        expect(GuestModeUtils.currentUser, equals(mockUser));
      });
    });

    group('Action Authentication Requirements', () {
      test('should correctly identify actions that require authentication', () {
        // Auth required actions
        expect(GuestModeUtils.actionRequiresAuth('join_match'), isTrue);
        expect(GuestModeUtils.actionRequiresAuth('hire_goalkeeper'), isTrue);
        expect(GuestModeUtils.actionRequiresAuth('create_announcement'), isTrue);
        expect(GuestModeUtils.actionRequiresAuth('edit_profile'), isTrue);
        expect(GuestModeUtils.actionRequiresAuth('manage_notifications'), isTrue);
        expect(GuestModeUtils.actionRequiresAuth('create_booking'), isTrue);
        expect(GuestModeUtils.actionRequiresAuth('rate_goalkeeper'), isTrue);
        expect(GuestModeUtils.actionRequiresAuth('send_message'), isTrue);
        
        // Actions that don't require auth
        expect(GuestModeUtils.actionRequiresAuth('view_announcements'), isFalse);
        expect(GuestModeUtils.actionRequiresAuth('browse_map'), isFalse);
        expect(GuestModeUtils.actionRequiresAuth('unknown_action'), isFalse);
      });
    });

    group('Route Access Control', () {
      test('should correctly identify guest accessible routes', () {
        // Guest accessible routes
        expect(GuestModeUtils.isGuestAccessibleRoute('/home'), isTrue);
        expect(GuestModeUtils.isGuestAccessibleRoute('/announcements'), isTrue);
        expect(GuestModeUtils.isGuestAccessibleRoute('/map'), isTrue);
        expect(GuestModeUtils.isGuestAccessibleRoute('/profile'), isTrue);
        expect(GuestModeUtils.isGuestAccessibleRoute('/signin'), isTrue);
        expect(GuestModeUtils.isGuestAccessibleRoute('/signup'), isTrue);
        
        // Restricted routes
        expect(GuestModeUtils.isGuestAccessibleRoute('/create-announcement'), isFalse);
        expect(GuestModeUtils.isGuestAccessibleRoute('/notifications'), isFalse);
        expect(GuestModeUtils.isGuestAccessibleRoute('/booking-management'), isFalse);
      });
    });

    group('Guest Redirect Logic', () {
      test('should return correct redirect routes for different actions', () {
        expect(GuestModeUtils.getGuestRedirectRoute('join_match'), equals('/signup'));
        expect(GuestModeUtils.getGuestRedirectRoute('hire_goalkeeper'), equals('/signup'));
        expect(GuestModeUtils.getGuestRedirectRoute('create_announcement'), equals('/signup'));
        expect(GuestModeUtils.getGuestRedirectRoute('unknown_action'), equals('/signin'));
      });
    });

    group('Guest Feature Access', () {
      test('should correctly identify features guests can access', () {
        // Guest allowed features
        expect(GuestModeUtils.canGuestAccess('view_announcements'), isTrue);
        expect(GuestModeUtils.canGuestAccess('view_map'), isTrue);
        expect(GuestModeUtils.canGuestAccess('view_fields'), isTrue);
        expect(GuestModeUtils.canGuestAccess('view_goalkeeper_locations'), isTrue);
        expect(GuestModeUtils.canGuestAccess('browse_content'), isTrue);
        
        // Restricted features
        expect(GuestModeUtils.canGuestAccess('create_content'), isFalse);
        expect(GuestModeUtils.canGuestAccess('manage_profile'), isFalse);
      });
    });

    group('Session Management', () {
      test('should generate unique guest session IDs', () async {
        // Act
        final sessionId1 = GuestModeUtils.generateGuestSessionId();
        await Future.delayed(const Duration(milliseconds: 1)); // Ensure different timestamps
        final sessionId2 = GuestModeUtils.generateGuestSessionId();
        
        // Assert
        expect(sessionId1, isNotEmpty);
        expect(sessionId2, isNotEmpty);
        expect(sessionId1, isNot(equals(sessionId2)));
        expect(sessionId1, startsWith('guest_'));
        expect(sessionId2, startsWith('guest_'));
      });
    });
  });
}
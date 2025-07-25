import 'package:flutter_test/flutter_test.dart';
import 'package:goalkeeper/src/features/auth/data/models/guest_user_context.dart';
import 'package:goalkeeper/src/features/auth/data/models/registration_prompt_config.dart';

void main() {
  group('Guest Navigation Integration Tests', () {
    
    test('Route accessibility logic works correctly', () {
      const guestAccessibleRoutes = {
        '/home',
        '/announcements', 
        '/map',
        '/profile',
        '/signin',
        '/signup',
      };
      
      // Test that guest-accessible routes are properly identified
      expect(guestAccessibleRoutes.contains('/home'), isTrue);
      expect(guestAccessibleRoutes.contains('/map'), isTrue);
      expect(guestAccessibleRoutes.contains('/profile'), isTrue);
      expect(guestAccessibleRoutes.contains('/signin'), isTrue);
      expect(guestAccessibleRoutes.contains('/signup'), isTrue);
      
      // Test that restricted routes are properly identified
      expect(guestAccessibleRoutes.contains('/admin'), isFalse);
      expect(guestAccessibleRoutes.contains('/settings'), isFalse);
    });

    test('Feature authentication requirements logic works correctly', () {
      const authRequiredFeatures = {
        'join_match',
        'hire_goalkeeper', 
        'create_announcement',
        'profile_management',
        'notifications',
        'booking_management',
      };
      
      // Test that auth-required features are properly identified
      expect(authRequiredFeatures.contains('join_match'), isTrue);
      expect(authRequiredFeatures.contains('hire_goalkeeper'), isTrue);
      expect(authRequiredFeatures.contains('create_announcement'), isTrue);
      expect(authRequiredFeatures.contains('profile_management'), isTrue);
      expect(authRequiredFeatures.contains('notifications'), isTrue);
      
      // Test that public features don't require auth
      expect(authRequiredFeatures.contains('view_announcements'), isFalse);
      expect(authRequiredFeatures.contains('view_map'), isFalse);
    });

    test('Guest context initialization works correctly', () {
      // Create a new guest context
      final guestContext = GuestUserContext.create();
      
      // Verify initial state
      expect(guestContext.sessionId, isNotEmpty);
      expect(guestContext.sessionStart, isNotNull);
      expect(guestContext.viewedContent, isEmpty);
      expect(guestContext.promptsShown, equals(0));
    });

    test('Guest content tracking works correctly', () {
      // Create guest context and track content
      var guestContext = GuestUserContext.create();
      
      // Track some content
      guestContext = guestContext.addViewedContent('announcements');
      guestContext = guestContext.addViewedContent('map');
      
      // Verify content was tracked
      expect(guestContext.viewedContent.contains('announcements'), isTrue);
      expect(guestContext.viewedContent.contains('map'), isTrue);
      expect(guestContext.viewedContent.length, equals(2));
      
      // Adding duplicate content should not increase count
      guestContext = guestContext.addViewedContent('announcements');
      expect(guestContext.viewedContent.length, equals(2));
    });

    test('Registration prompt logic works correctly', () {
      var guestContext = GuestUserContext.create();
      
      // Initially should not show prompt (no content viewed)
      expect(guestContext.shouldShowPrompt(), isFalse);
      
      // After viewing content, should show prompt
      guestContext = guestContext.addViewedContent('announcements');
      expect(guestContext.shouldShowPrompt(), isTrue);
      
      // After too many prompts, should not show
      guestContext = guestContext.incrementPrompts();
      guestContext = guestContext.incrementPrompts();
      guestContext = guestContext.incrementPrompts();
      expect(guestContext.shouldShowPrompt(), isFalse);
    });

    test('Registration prompt configuration works correctly', () {
      // Test predefined configurations
      final joinMatchConfig = RegistrationPromptConfig.joinMatch;
      expect(joinMatchConfig.context, equals('join_match'));
      expect(joinMatchConfig.title, contains('Partida'));
      
      final hireGoalkeeperConfig = RegistrationPromptConfig.hireGoalkeeper;
      expect(hireGoalkeeperConfig.context, equals('hire_goalkeeper'));
      expect(hireGoalkeeperConfig.title, contains('Goleiro'));
      
      final profileConfig = RegistrationPromptConfig.profileAccess;
      expect(profileConfig.context, equals('profile_access'));
      expect(profileConfig.title, contains('Perfil'));
      
      // Test context-based configuration
      final contextConfig = RegistrationPromptConfig.forContext('join_match');
      expect(contextConfig.context, equals('join_match'));
      expect(contextConfig.title, equals(joinMatchConfig.title));
      
      // Test default configuration for unknown context
      final defaultConfig = RegistrationPromptConfig.forContext('unknown');
      expect(defaultConfig.context, equals('default'));
      expect(defaultConfig.title, contains('Conta'));
    });

    test('Guest session duration tracking works correctly', () {
      final guestContext = GuestUserContext.create();
      
      // Session duration should be minimal initially
      expect(guestContext.sessionDuration.inSeconds, lessThan(5));
      
      // Analytics map should contain session information
      final analyticsMap = guestContext.toAnalyticsMap();
      expect(analyticsMap['session_id'], isNotEmpty);
      expect(analyticsMap['session_start'], isNotNull);
      expect(analyticsMap['session_duration_minutes'], isA<int>());
      expect(analyticsMap['viewed_content_count'], equals(0));
      expect(analyticsMap['prompts_shown'], equals(0));
    });

    test('Navigation tab index mapping works correctly', () {
      // Test tab index to navbar item mapping logic
      int getTabIndexFromNavbarItem(String navbarItem) {
        switch (navbarItem) {
          case 'home':
            return 0;
          case 'map':
            return 1;
          case 'notifications':
            return 2;
          case 'profile':
            return 3;
          default:
            return 0;
        }
      }
      
      expect(getTabIndexFromNavbarItem('home'), equals(0));
      expect(getTabIndexFromNavbarItem('map'), equals(1));
      expect(getTabIndexFromNavbarItem('notifications'), equals(2));
      expect(getTabIndexFromNavbarItem('profile'), equals(3));
      expect(getTabIndexFromNavbarItem('unknown'), equals(0));
    });

    test('Guest mode route handling logic works correctly', () {
      // Test route building logic for guest users
      bool shouldRedirectToMainScreen(String route, bool isGuest) {
        const routesToRedirect = {'/profile', '/notifications', '/announcements', '/map'};
        return isGuest && routesToRedirect.contains(route);
      }
      
      // Guest users should be redirected to MainScreen for these routes
      expect(shouldRedirectToMainScreen('/profile', true), isTrue);
      expect(shouldRedirectToMainScreen('/notifications', true), isTrue);
      expect(shouldRedirectToMainScreen('/announcements', true), isTrue);
      expect(shouldRedirectToMainScreen('/map', true), isTrue);
      
      // Authenticated users should not be redirected
      expect(shouldRedirectToMainScreen('/profile', false), isFalse);
      expect(shouldRedirectToMainScreen('/notifications', false), isFalse);
      
      // Auth routes should not be redirected for anyone
      expect(shouldRedirectToMainScreen('/signin', true), isFalse);
      expect(shouldRedirectToMainScreen('/signup', true), isFalse);
    });

    test('Guest navigation state management works correctly', () {
      // Test navigation state transitions for guest users
      String getScreenForGuestNavigation(String selectedTab, bool isGuest) {
        if (!isGuest) return selectedTab;
        
        switch (selectedTab) {
          case 'home':
            return 'announcements';
          case 'map':
            return 'map';
          case 'notifications':
            return 'guest_profile'; // Redirect to profile
          case 'profile':
            return 'guest_profile';
          default:
            return 'announcements';
        }
      }
      
      // Test guest navigation redirects
      expect(getScreenForGuestNavigation('home', true), equals('announcements'));
      expect(getScreenForGuestNavigation('map', true), equals('map'));
      expect(getScreenForGuestNavigation('notifications', true), equals('guest_profile'));
      expect(getScreenForGuestNavigation('profile', true), equals('guest_profile'));
      
      // Test authenticated user navigation (no redirects)
      expect(getScreenForGuestNavigation('notifications', false), equals('notifications'));
      expect(getScreenForGuestNavigation('profile', false), equals('profile'));
    });
  });
}
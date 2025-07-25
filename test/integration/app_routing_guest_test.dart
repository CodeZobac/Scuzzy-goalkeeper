import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:goalkeeper/src/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:goalkeeper/src/features/main/presentation/screens/main_screen.dart';
import 'package:goalkeeper/src/features/user_profile/presentation/screens/guest_profile_screen.dart';
import 'package:goalkeeper/src/features/announcements/presentation/screens/announcements_screen.dart';
import 'package:goalkeeper/src/features/map/presentation/screens/map_screen.dart';
import 'package:goalkeeper/src/features/auth/presentation/screens/sign_up_screen.dart';
import 'package:goalkeeper/src/features/auth/presentation/theme/app_theme.dart';

// Generate mocks
@GenerateMocks([SupabaseClient, GoTrueClient, Session, User])
import 'guest_mode_integration_test.mocks.dart';

void main() {
  group('App Routing with Guest Users Integration Tests', () {
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
    });

    Widget createTestAppWithRouting({bool isGuest = true}) {
      // Mock authentication state
      when(mockGoTrueClient.currentSession).thenReturn(isGuest ? null : mockSession);
      when(mockGoTrueClient.currentUser).thenReturn(isGuest ? null : mockUser);
      
      return MaterialApp(
        theme: AppTheme.darkTheme,
        initialRoute: '/home',
        onGenerateRoute: (settings) {
          final authProvider = AuthStateProvider(supabaseClient: mockSupabaseClient);
          
          // Simulate the app's route generation logic
          switch (settings.name) {
            case '/restricted-feature':
              if (authProvider.isGuest) {
                return MaterialPageRoute(
                  builder: (context) => Scaffold(
                    body: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Acesso Restrito'),
                          ElevatedButton(
                            onPressed: () {
                              authProvider.setIntendedDestination('/restricted-feature');
                              Navigator.of(context).pushReplacementNamed('/signup');
                            },
                            child: const Text('Criar Conta'),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }
              return MaterialPageRoute(
                builder: (context) => const Scaffold(
                  body: Center(child: Text('Restricted Feature Content')),
                ),
              );
            default:
              return null;
          }
        },
        routes: {
          '/home': (context) => ChangeNotifierProvider(
            create: (_) => AuthStateProvider(supabaseClient: mockSupabaseClient),
            child: const MainScreen(),
          ),
          '/signup': (context) => const SignUpScreen(),
          '/profile': (context) => ChangeNotifierProvider(
            create: (_) => AuthStateProvider(supabaseClient: mockSupabaseClient),
            child: Consumer<AuthStateProvider>(
              builder: (context, authProvider, child) {
                if (authProvider.isGuest) {
                  return const MainScreen(initialTabIndex: 3);
                }
                return const Scaffold(
                  body: Center(child: Text('Authenticated Profile')),
                );
              },
            ),
          ),
          '/announcements': (context) => ChangeNotifierProvider(
            create: (_) => AuthStateProvider(supabaseClient: mockSupabaseClient),
            child: const MainScreen(initialTabIndex: 0),
          ),
          '/map': (context) => ChangeNotifierProvider(
            create: (_) => AuthStateProvider(supabaseClient: mockSupabaseClient),
            child: const MainScreen(initialTabIndex: 1),
          ),
        },
      );
    }

    group('Initial Route Determination', () {
      testWidgets('should determine correct initial route for guest users', (WidgetTester tester) async {
        // Arrange
        final app = createTestAppWithRouting(isGuest: true);
        
        // Act
        await tester.pumpWidget(app);
        await tester.pumpAndSettle();
        
        // Assert - Should start at home route
        expect(find.byType(MainScreen), findsOneWidget);
        expect(find.byType(AnnouncementsScreen), findsOneWidget);
      });

      testWidgets('should determine correct initial route for authenticated users', (WidgetTester tester) async {
        // Arrange
        final app = createTestAppWithRouting(isGuest: false);
        
        // Act
        await tester.pumpWidget(app);
        await tester.pumpAndSettle();
        
        // Assert - Should start at home route
        expect(find.byType(MainScreen), findsOneWidget);
        expect(find.byType(AnnouncementsScreen), findsOneWidget);
      });

      testWidgets('should handle app restart with consistent routing', (WidgetTester tester) async {
        // Arrange - Start as guest
        when(mockGoTrueClient.currentSession).thenReturn(null);
        final app = createTestAppWithRouting(isGuest: true);
        
        // Act
        await tester.pumpWidget(app);
        await tester.pumpAndSettle();
        
        // Assert - Should be in guest mode
        expect(find.byType(MainScreen), findsOneWidget);
        
        // Simulate app restart with authentication
        when(mockGoTrueClient.currentSession).thenReturn(mockSession);
        await tester.pumpWidget(createTestAppWithRouting(isGuest: false));
        await tester.pumpAndSettle();
        
        // Assert - Should still work correctly
        expect(find.byType(MainScreen), findsOneWidget);
      });
    });

    group('Route Generation for Guest Access', () {
      testWidgets('should allow guest access to allowed screens', (WidgetTester tester) async {
        // Arrange
        final app = createTestAppWithRouting(isGuest: true);
        
        // Act
        await tester.pumpWidget(app);
        await tester.pumpAndSettle();
        
        final navigator = Navigator.of(tester.element(find.byType(MaterialApp)));
        
        // Test announcements access
        navigator.pushNamed('/announcements');
        await tester.pumpAndSettle();
        expect(find.byType(MainScreen), findsOneWidget);
        expect(find.byType(AnnouncementsScreen), findsOneWidget);
        
        // Test map access
        navigator.pushNamed('/map');
        await tester.pumpAndSettle();
        expect(find.byType(MainScreen), findsOneWidget);
        expect(find.byType(MapScreen), findsOneWidget);
        
        // Test profile access (should show guest profile)
        navigator.pushNamed('/profile');
        await tester.pumpAndSettle();
        expect(find.byType(MainScreen), findsOneWidget);
        expect(find.byType(GuestProfileScreen), findsOneWidget);
      });

      testWidgets('should redirect guest users from restricted routes', (WidgetTester tester) async {
        // Arrange
        final app = createTestAppWithRouting(isGuest: true);
        
        // Act
        await tester.pumpWidget(app);
        await tester.pumpAndSettle();
        
        final navigator = Navigator.of(tester.element(find.byType(MaterialApp)));
        navigator.pushNamed('/restricted-feature');
        await tester.pumpAndSettle();
        
        // Assert - Should show restricted access screen
        expect(find.text('Acesso Restrito'), findsOneWidget);
        expect(find.text('Criar Conta'), findsOneWidget);
      });

      testWidgets('should handle route generation errors gracefully', (WidgetTester tester) async {
        // Arrange
        final app = MaterialApp(
          theme: AppTheme.darkTheme,
          initialRoute: '/home',
          onGenerateRoute: (settings) {
            // Simulate route generation error
            if (settings.name == '/error-route') {
              throw Exception('Route generation error');
            }
            return null;
          },
          onUnknownRoute: (settings) {
            return MaterialPageRoute(
              builder: (context) => const Scaffold(
                body: Center(child: Text('Route Not Found')),
              ),
            );
          },
          routes: {
            '/home': (context) => ChangeNotifierProvider(
              create: (_) => AuthStateProvider(supabaseClient: mockSupabaseClient),
              child: const MainScreen(),
            ),
          },
        );
        
        when(mockGoTrueClient.currentSession).thenReturn(null);
        
        // Act
        await tester.pumpWidget(app);
        await tester.pumpAndSettle();
        
        final navigator = Navigator.of(tester.element(find.byType(MaterialApp)));
        navigator.pushNamed('/unknown-route');
        await tester.pumpAndSettle();
        
        // Assert - Should show error handling
        expect(find.text('Route Not Found'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    });

    group('Navigation Flow from Registration Prompts', () {
      testWidgets('should handle navigation flow from registration prompts to signup', (WidgetTester tester) async {
        // Arrange
        final app = createTestAppWithRouting(isGuest: true);
        
        // Act
        await tester.pumpWidget(app);
        await tester.pumpAndSettle();
        
        // Navigate to restricted feature
        final navigator = Navigator.of(tester.element(find.byType(MaterialApp)));
        navigator.pushNamed('/restricted-feature');
        await tester.pumpAndSettle();
        
        // Tap the registration button
        await tester.tap(find.text('Criar Conta'));
        await tester.pumpAndSettle();
        
        // Assert - Should navigate to signup screen
        expect(find.byType(SignUpScreen), findsOneWidget);
      });

      testWidgets('should store intended destination during registration flow', (WidgetTester tester) async {
        // Arrange
        final authProvider = AuthStateProvider(supabaseClient: mockSupabaseClient);
        when(mockGoTrueClient.currentSession).thenReturn(null);
        
        // Act - Set intended destination
        authProvider.setIntendedDestination('/restricted-feature', {'param': 'value'});
        
        // Assert - Should store destination correctly
        expect(authProvider.hasIntendedDestination, isTrue);
        
        final destination = authProvider.getAndClearIntendedDestination();
        expect(destination, isNotNull);
        expect(destination!['destination'], equals('/restricted-feature'));
        expect(destination['arguments'], equals({'param': 'value'}));
        
        // Should clear after retrieval
        expect(authProvider.hasIntendedDestination, isFalse);
      });

      testWidgets('should handle post-registration redirect correctly', (WidgetTester tester) async {
        // Arrange
        final authProvider = AuthStateProvider(supabaseClient: mockSupabaseClient);
        when(mockGoTrueClient.currentSession).thenReturn(null);
        
        // Set intended destination
        authProvider.setIntendedDestination('/restricted-feature');
        
        // Simulate authentication
        when(mockGoTrueClient.currentSession).thenReturn(mockSession);
        when(mockGoTrueClient.currentUser).thenReturn(mockUser);
        
        // Act - Get intended destination
        final destination = authProvider.getAndClearIntendedDestination();
        
        // Assert - Should have correct destination
        expect(destination, isNotNull);
        expect(destination!['destination'], equals('/restricted-feature'));
        expect(authProvider.hasIntendedDestination, isFalse);
      });
    });

    group('Guest Context Management During Routing', () {
      testWidgets('should initialize guest context during route navigation', (WidgetTester tester) async {
        // Arrange
        final app = MaterialApp(
          theme: AppTheme.darkTheme,
          routes: {
            '/home': (context) => ChangeNotifierProvider(
              create: (_) => AuthStateProvider(supabaseClient: mockSupabaseClient),
              child: Consumer<AuthStateProvider>(
                builder: (context, authProvider, child) {
                  if (authProvider.isGuest) {
                    authProvider.initializeGuestContext();
                  }
                  return Scaffold(
                    body: Center(
                      child: Column(
                        children: [
                          Text('Is Guest: ${authProvider.isGuest}'),
                          Text('Has Context: ${authProvider.guestContext != null}'),
                          ElevatedButton(
                            onPressed: () => Navigator.of(context).pushNamed('/profile'),
                            child: const Text('Go to Profile'),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            '/profile': (context) => ChangeNotifierProvider(
              create: (_) => AuthStateProvider(supabaseClient: mockSupabaseClient),
              child: Consumer<AuthStateProvider>(
                builder: (context, authProvider, child) {
                  if (authProvider.isGuest) {
                    authProvider.initializeGuestContext();
                    authProvider.trackGuestContentView('profile');
                  }
                  return Scaffold(
                    body: Center(
                      child: Column(
                        children: [
                          const Text('Profile Screen'),
                          if (authProvider.guestContext != null)
                            Text('Viewed Content: ${authProvider.guestContext!.viewedContent.length}'),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          },
        );
        
        when(mockGoTrueClient.currentSession).thenReturn(null);
        
        // Act
        await tester.pumpWidget(app);
        await tester.pumpAndSettle();
        
        // Verify initial state
        expect(find.text('Is Guest: true'), findsOneWidget);
        expect(find.text('Has Context: true'), findsOneWidget);
        
        // Navigate to profile
        await tester.tap(find.text('Go to Profile'));
        await tester.pumpAndSettle();
        
        // Assert - Should track content viewing
        expect(find.text('Profile Screen'), findsOneWidget);
        expect(find.text('Viewed Content: 1'), findsOneWidget);
      });

      testWidgets('should maintain guest context across route changes', (WidgetTester tester) async {
        // Arrange
        final authProvider = AuthStateProvider(supabaseClient: mockSupabaseClient);
        when(mockGoTrueClient.currentSession).thenReturn(null);
        
        // Initialize guest context
        authProvider.initializeGuestContext();
        authProvider.trackGuestContentView('announcements');
        authProvider.trackGuestContentView('map');
        
        // Act & Assert - Context should persist
        expect(authProvider.guestContext, isNotNull);
        expect(authProvider.guestContext!.viewedContent.length, equals(2));
        expect(authProvider.guestContext!.viewedContent.contains('announcements'), isTrue);
        expect(authProvider.guestContext!.viewedContent.contains('map'), isTrue);
        
        // Simulate route change
        authProvider.trackGuestContentView('profile');
        
        // Assert - Should maintain previous context
        expect(authProvider.guestContext!.viewedContent.length, equals(3));
        expect(authProvider.guestContext!.viewedContent.contains('profile'), isTrue);
      });
    });

    group('Route Access Control', () {
      testWidgets('should properly control route access for guest users', (WidgetTester tester) async {
        // Arrange
        final authProvider = AuthStateProvider(supabaseClient: mockSupabaseClient);
        when(mockGoTrueClient.currentSession).thenReturn(null);
        
        // Act & Assert - Test route accessibility
        expect(authProvider.isRouteAccessibleToGuests('/home'), isTrue);
        expect(authProvider.isRouteAccessibleToGuests('/announcements'), isTrue);
        expect(authProvider.isRouteAccessibleToGuests('/map'), isTrue);
        expect(authProvider.isRouteAccessibleToGuests('/profile'), isTrue);
        expect(authProvider.isRouteAccessibleToGuests('/signin'), isTrue);
        expect(authProvider.isRouteAccessibleToGuests('/signup'), isTrue);
        expect(authProvider.isRouteAccessibleToGuests('/announcement-detail'), isTrue);
        
        // Restricted routes
        expect(authProvider.isRouteAccessibleToGuests('/admin'), isFalse);
        expect(authProvider.isRouteAccessibleToGuests('/settings'), isFalse);
        expect(authProvider.isRouteAccessibleToGuests('/create-announcement'), isFalse);
      });

      testWidgets('should handle authenticated user route access correctly', (WidgetTester tester) async {
        // Arrange
        final authProvider = AuthStateProvider(supabaseClient: mockSupabaseClient);
        when(mockGoTrueClient.currentSession).thenReturn(mockSession);
        when(mockGoTrueClient.currentUser).thenReturn(mockUser);
        
        // Act & Assert - Authenticated users should access all routes
        expect(authProvider.isGuest, isFalse);
        expect(authProvider.isAuthenticated, isTrue);
        
        // All routes should be accessible to authenticated users
        // (This would be handled by the app's route generation logic)
      });
    });

    group('Error Handling in Routing', () {
      testWidgets('should handle routing errors gracefully', (WidgetTester tester) async {
        // Arrange
        final app = MaterialApp(
          theme: AppTheme.darkTheme,
          initialRoute: '/home',
          onGenerateRoute: (settings) {
            // Simulate routing error
            if (settings.name == '/error-route') {
              return null; // This will trigger onUnknownRoute
            }
            return null;
          },
          onUnknownRoute: (settings) {
            return MaterialPageRoute(
              builder: (context) => Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Unknown Route: ${settings.name}'),
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).pushReplacementNamed('/home'),
                        child: const Text('Go Home'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
          routes: {
            '/home': (context) => ChangeNotifierProvider(
              create: (_) => AuthStateProvider(supabaseClient: mockSupabaseClient),
              child: const MainScreen(),
            ),
          },
        );
        
        when(mockGoTrueClient.currentSession).thenReturn(null);
        
        // Act
        await tester.pumpWidget(app);
        await tester.pumpAndSettle();
        
        final navigator = Navigator.of(tester.element(find.byType(MaterialApp)));
        navigator.pushNamed('/error-route');
        await tester.pumpAndSettle();
        
        // Assert - Should handle error gracefully
        expect(find.text('Unknown Route: /error-route'), findsOneWidget);
        expect(find.text('Go Home'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('should handle null route arguments gracefully', (WidgetTester tester) async {
        // Arrange
        final authProvider = AuthStateProvider(supabaseClient: mockSupabaseClient);
        when(mockGoTrueClient.currentSession).thenReturn(null);
        
        // Act - Set intended destination with null arguments
        authProvider.setIntendedDestination('/test-route', null);
        
        // Assert - Should handle null arguments
        final destination = authProvider.getAndClearIntendedDestination();
        expect(destination, isNotNull);
        expect(destination!['destination'], equals('/test-route'));
        expect(destination['arguments'], isNull);
      });
    });
  });
}
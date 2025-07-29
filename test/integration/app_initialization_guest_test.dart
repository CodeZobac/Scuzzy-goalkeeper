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
  group('App Initialization with Guest Users Integration Tests', () {
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

    Widget createTestApp({bool isGuest = true}) {
      // Mock authentication state
      when(mockGoTrueClient.currentSession).thenReturn(isGuest ? null : mockSession);
      when(mockGoTrueClient.currentUser).thenReturn(isGuest ? null : mockUser);
      
      return MaterialApp(
        theme: AppTheme.darkTheme,
        home: ChangeNotifierProvider(
          create: (_) => AuthStateProvider(supabaseClient: mockSupabaseClient),
          child: const MainScreen(),
        ),
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
          '/notifications': (context) => ChangeNotifierProvider(
            create: (_) => AuthStateProvider(supabaseClient: mockSupabaseClient),
            child: Consumer<AuthStateProvider>(
              builder: (context, authProvider, child) {
                if (authProvider.isGuest) {
                  return const MainScreen(initialTabIndex: 3);
                }
                return const Scaffold(
                  body: Center(child: Text('Notifications Screen')),
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
      testWidgets('should start at home route for guest users', (WidgetTester tester) async {
        // Arrange
        final app = createTestApp(isGuest: true);
        
        // Act
        await tester.pumpWidget(app);
        await tester.pumpAndSettle();
        
        // Assert
        expect(find.byType(MainScreen), findsOneWidget);
        expect(find.byType(AnnouncementsScreen), findsOneWidget);
      });

      testWidgets('should start at home route for authenticated users', (WidgetTester tester) async {
        // Arrange
        final app = createTestApp(isGuest: false);
        
        // Act
        await tester.pumpWidget(app);
        await tester.pumpAndSettle();
        
        // Assert
        expect(find.byType(MainScreen), findsOneWidget);
        expect(find.byType(AnnouncementsScreen), findsOneWidget);
      });

      testWidgets('should initialize guest context when guest user accesses app', (WidgetTester tester) async {
        // Arrange
        final app = createTestApp(isGuest: true);
        
        // Act
        await tester.pumpWidget(app);
        await tester.pumpAndSettle();
        
        // Assert - Verify the app loads correctly for guest users
        expect(find.byType(MainScreen), findsOneWidget);
        expect(find.byType(AnnouncementsScreen), findsOneWidget);
        
        // Verify no exceptions were thrown during initialization
        expect(tester.takeException(), isNull);
      });

      testWidgets('should properly initialize guest context on app startup', (WidgetTester tester) async {
        // Arrange
        final app = MaterialApp(
          theme: AppTheme.darkTheme,
          home: ChangeNotifierProvider(
            create: (_) => AuthStateProvider(supabaseClient: mockSupabaseClient),
            child: Consumer<AuthStateProvider>(
              builder: (context, authProvider, child) {
                // Verify guest context initialization
                if (authProvider.isGuest) {
                  authProvider.initializeGuestContext();
                  return Scaffold(
                    body: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Guest Mode: ${authProvider.isGuest}'),
                          Text('Has Context: ${authProvider.guestContext != null}'),
                          if (authProvider.guestContext != null)
                            Text('Session ID: ${authProvider.guestContext!.sessionId}'),
                        ],
                      ),
                    ),
                  );
                }
                return const Scaffold(
                  body: Center(child: Text('Authenticated')),
                );
              },
            ),
          ),
        );
        
        when(mockGoTrueClient.currentSession).thenReturn(null);
        
        // Act
        await tester.pumpWidget(app);
        await tester.pumpAndSettle();
        
        // Assert
        expect(find.text('Guest Mode: true'), findsOneWidget);
        expect(find.text('Has Context: true'), findsOneWidget);
        expect(find.textContaining('Session ID: guest_'), findsOneWidget);
      });
    });

    group('Route Generation for Guest Users', () {
      testWidgets('should redirect guest users from profile route to MainScreen with profile tab', (WidgetTester tester) async {
        // Arrange
        final app = createTestApp(isGuest: true);
        
        // Act
        await tester.pumpWidget(app);
        await tester.pumpAndSettle();
        
        // Navigate to profile route
        final navigator = Navigator.of(tester.element(find.byType(MaterialApp)));
        navigator.pushNamed('/profile');
        await tester.pumpAndSettle();
        
        // Assert
        expect(find.byType(MainScreen), findsOneWidget);
        expect(find.byType(GuestProfileScreen), findsOneWidget);
      });

      testWidgets('should redirect guest users from notifications route to MainScreen with profile tab', (WidgetTester tester) async {
        // Arrange
        final app = createTestApp(isGuest: true);
        
        // Act
        await tester.pumpWidget(app);
        await tester.pumpAndSettle();
        
        // Navigate to notifications route
        final navigator = Navigator.of(tester.element(find.byType(MaterialApp)));
        navigator.pushNamed('/notifications');
        await tester.pumpAndSettle();
        
        // Assert
        expect(find.byType(MainScreen), findsOneWidget);
        expect(find.byType(GuestProfileScreen), findsOneWidget);
      });

      testWidgets('should allow guest users to access announcements route', (WidgetTester tester) async {
        // Arrange
        final app = createTestApp(isGuest: true);
        
        // Act
        await tester.pumpWidget(app);
        await tester.pumpAndSettle();
        
        // Navigate to announcements route
        final navigator = Navigator.of(tester.element(find.byType(MaterialApp)));
        navigator.pushNamed('/announcements');
        await tester.pumpAndSettle();
        
        // Assert
        expect(find.byType(MainScreen), findsOneWidget);
        expect(find.byType(AnnouncementsScreen), findsOneWidget);
      });

      testWidgets('should allow guest users to access map route', (WidgetTester tester) async {
        // Arrange
        final app = createTestApp(isGuest: true);
        
        // Act
        await tester.pumpWidget(app);
        await tester.pumpAndSettle();
        
        // Navigate to map route
        final navigator = Navigator.of(tester.element(find.byType(MaterialApp)));
        navigator.pushNamed('/map');
        await tester.pumpAndSettle();
        
        // Assert
        expect(find.byType(MainScreen), findsOneWidget);
        expect(find.byType(MapScreen), findsOneWidget);
      });
    });

    group('Navigation Flow from Registration Prompts', () {
      testWidgets('should navigate to signup screen when guest accesses restricted content', (WidgetTester tester) async {
        // Arrange
        final app = MaterialApp(
          theme: AppTheme.darkTheme,
          initialRoute: '/home',
          routes: {
            '/home': (context) => ChangeNotifierProvider(
              create: (_) => AuthStateProvider(supabaseClient: mockSupabaseClient),
              child: const MainScreen(),
            ),
            '/signup': (context) => const SignUpScreen(),
            '/create-announcement': (context) => ChangeNotifierProvider(
              create: (_) => AuthStateProvider(supabaseClient: mockSupabaseClient),
              child: Consumer<AuthStateProvider>(
                builder: (context, authProvider, child) {
                  if (authProvider.isGuest) {
                    // Simulate redirect to signup for restricted route
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      authProvider.setIntendedDestination('/create-announcement');
                      Navigator.of(context).pushReplacementNamed('/signup');
                    });
                    return const Scaffold(
                      body: Center(child: CircularProgressIndicator()),
                    );
                  }
                  return const Scaffold(
                    body: Center(child: Text('Create Announcement')),
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
        
        // Navigate to restricted route
        final navigator = Navigator.of(tester.element(find.byType(MaterialApp)));
        navigator.pushNamed('/create-announcement');
        await tester.pumpAndSettle();
        
        // Assert
        expect(find.byType(SignUpScreen), findsOneWidget);
      });

      testWidgets('should maintain navigation state when transitioning from guest to authenticated', (WidgetTester tester) async {
        // Arrange
        final app = createTestApp(isGuest: true);
        
        // Act - Start as guest
        await tester.pumpWidget(app);
        await tester.pumpAndSettle();
        
        // Verify guest state
        expect(find.byType(MainScreen), findsOneWidget);
        
        // Simulate authentication
        when(mockGoTrueClient.currentSession).thenReturn(mockSession);
        when(mockGoTrueClient.currentUser).thenReturn(mockUser);
        
        // Trigger a rebuild to simulate auth state change
        await tester.pumpWidget(createTestApp(isGuest: false));
        await tester.pumpAndSettle();
        
        // Assert - Should still be on MainScreen but now authenticated
        expect(find.byType(MainScreen), findsOneWidget);
      });

      testWidgets('should handle intended destination after registration', (WidgetTester tester) async {
        // Arrange
        final app = MaterialApp(
          theme: AppTheme.darkTheme,
          initialRoute: '/home',
          routes: {
            '/home': (context) => ChangeNotifierProvider(
              create: (_) => AuthStateProvider(supabaseClient: mockSupabaseClient),
              child: const MainScreen(),
            ),
            '/signup': (context) => const SignUpScreen(),
            '/restricted': (context) => ChangeNotifierProvider(
              create: (_) => AuthStateProvider(supabaseClient: mockSupabaseClient),
              child: Consumer<AuthStateProvider>(
                builder: (context, authProvider, child) {
                  if (authProvider.isGuest) {
                    // Store intended destination and redirect to signup
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      authProvider.setIntendedDestination('/restricted');
                      Navigator.of(context).pushReplacementNamed('/signup');
                    });
                    return const Scaffold(
                      body: Center(child: CircularProgressIndicator()),
                    );
                  }
                  return const Scaffold(
                    body: Center(child: Text('Restricted Content')),
                  );
                },
              ),
            ),
          },
        );
        
        when(mockGoTrueClient.currentSession).thenReturn(null);
        
        // Act - Start as guest and navigate to restricted route
        await tester.pumpWidget(app);
        await tester.pumpAndSettle();
        
        final navigator = Navigator.of(tester.element(find.byType(MaterialApp)));
        navigator.pushNamed('/restricted');
        await tester.pumpAndSettle();
        
        // Verify redirect to signup
        expect(find.byType(SignUpScreen), findsOneWidget);
        
        // Simulate successful authentication
        when(mockGoTrueClient.currentSession).thenReturn(mockSession);
        when(mockGoTrueClient.currentUser).thenReturn(mockUser);
        
        // Simulate auth state change with intended destination
        final authProvider = AuthStateProvider(supabaseClient: mockSupabaseClient);
        authProvider.setIntendedDestination('/restricted');
        final intendedDestination = authProvider.getAndClearIntendedDestination();
        
        // Assert intended destination was stored and retrieved correctly
        expect(intendedDestination, isNotNull);
        expect(intendedDestination!['destination'], equals('/restricted'));
        expect(intendedDestination['arguments'], isNull);
      });
    });

    group('Route Access Control', () {
      testWidgets('should handle unknown routes for guest users gracefully', (WidgetTester tester) async {
        // Arrange
        final app = MaterialApp(
          theme: AppTheme.darkTheme,
          initialRoute: '/home',
          onGenerateRoute: (settings) {
            // Simulate the app's route generation logic
            final authProvider = AuthStateProvider(supabaseClient: mockSupabaseClient);
            
            if (settings.name == '/unknown-route') {
              if (authProvider.isGuest && !authProvider.isRouteAccessibleToGuests(settings.name!)) {
                return MaterialPageRoute(
                  builder: (context) => Scaffold(
                    body: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Acesso Restrito'),
                          ElevatedButton(
                            onPressed: () => Navigator.of(context).pushReplacementNamed('/signup'),
                            child: const Text('Criar Conta'),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }
            }
            return null;
          },
          routes: {
            '/home': (context) => ChangeNotifierProvider(
              create: (_) => AuthStateProvider(supabaseClient: mockSupabaseClient),
              child: const MainScreen(),
            ),
            '/signup': (context) => const SignUpScreen(),
          },
        );
        
        when(mockGoTrueClient.currentSession).thenReturn(null);
        
        // Act
        await tester.pumpWidget(app);
        await tester.pumpAndSettle();
        
        // Navigate to unknown route
        final navigator = Navigator.of(tester.element(find.byType(MaterialApp)));
        navigator.pushNamed('/unknown-route');
        await tester.pumpAndSettle();
        
        // Assert
        expect(find.text('Acesso Restrito'), findsOneWidget);
        expect(find.text('Criar Conta'), findsOneWidget);
      });

      testWidgets('should allow authenticated users to access all routes', (WidgetTester tester) async {
        // Arrange
        final app = MaterialApp(
          theme: AppTheme.darkTheme,
          routes: {
            '/home': (context) => ChangeNotifierProvider(
              create: (_) => AuthStateProvider(supabaseClient: mockSupabaseClient),
              child: const MainScreen(),
            ),
            '/profile': (context) => ChangeNotifierProvider(
              create: (_) => AuthStateProvider(supabaseClient: mockSupabaseClient),
              child: const Scaffold(body: Center(child: Text('Authenticated Profile'))),
            ),
            '/notifications': (context) => ChangeNotifierProvider(
              create: (_) => AuthStateProvider(supabaseClient: mockSupabaseClient),
              child: const Scaffold(body: Center(child: Text('Notifications Screen'))),
            ),
          },
        );
        
        when(mockGoTrueClient.currentSession).thenReturn(mockSession);
        when(mockGoTrueClient.currentUser).thenReturn(mockUser);
        
        // Act
        await tester.pumpWidget(app);
        await tester.pumpAndSettle();
        
        // Navigate to profile
        final navigator = Navigator.of(tester.element(find.byType(MaterialApp)));
        navigator.pushNamed('/profile');
        await tester.pumpAndSettle();
        
        // Assert
        expect(find.text('Authenticated Profile'), findsOneWidget);
        
        // Navigate to notifications
        navigator.pushNamed('/notifications');
        await tester.pumpAndSettle();
        
        // Assert
        expect(find.text('Notifications Screen'), findsOneWidget);
      });
    });

    group('App State Transitions', () {
      testWidgets('should handle sign out transition correctly', (WidgetTester tester) async {
        // Arrange - Start as authenticated user
        when(mockGoTrueClient.currentSession).thenReturn(mockSession);
        when(mockGoTrueClient.currentUser).thenReturn(mockUser);
        
        final app = createTestApp(isGuest: false);
        
        // Act
        await tester.pumpWidget(app);
        await tester.pumpAndSettle();
        
        // Simulate sign out
        when(mockGoTrueClient.currentSession).thenReturn(null);
        when(mockGoTrueClient.currentUser).thenReturn(null);
        
        // Rebuild with guest state
        await tester.pumpWidget(createTestApp(isGuest: true));
        await tester.pumpAndSettle();
        
        // Assert - Should be in guest mode
        expect(find.byType(MainScreen), findsOneWidget);
      });

      testWidgets('should handle app restart with guest user', (WidgetTester tester) async {
        // Arrange
        when(mockGoTrueClient.currentSession).thenReturn(null);
        
        final app = createTestApp(isGuest: true);
        
        // Act
        await tester.pumpWidget(app);
        await tester.pumpAndSettle();
        
        // Assert - App should start correctly for guest user
        expect(find.byType(MainScreen), findsOneWidget);
        expect(find.byType(AnnouncementsScreen), findsOneWidget);
      });
    });

    group('Error Handling', () {
      testWidgets('should handle null authentication state gracefully', (WidgetTester tester) async {
        // Arrange
        when(mockGoTrueClient.currentSession).thenReturn(null);
        when(mockGoTrueClient.currentUser).thenReturn(null);
        
        final app = createTestApp(isGuest: true);
        
        // Act
        await tester.pumpWidget(app);
        await tester.pumpAndSettle();
        
        // Assert - Should not crash and should show guest content
        expect(find.byType(MainScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('should handle route navigation errors gracefully', (WidgetTester tester) async {
        // Arrange
        final app = MaterialApp(
          theme: AppTheme.darkTheme,
          home: ChangeNotifierProvider(
            create: (_) => AuthStateProvider(supabaseClient: mockSupabaseClient),
            child: const MainScreen(),
          ),
          onUnknownRoute: (settings) {
            return MaterialPageRoute(
              builder: (context) => const Scaffold(
                body: Center(child: Text('Route Not Found')),
              ),
            );
          },
        );
        
        when(mockGoTrueClient.currentSession).thenReturn(null);
        
        // Act
        await tester.pumpWidget(app);
        await tester.pumpAndSettle();
        
        // Navigate to non-existent route
        final navigator = Navigator.of(tester.element(find.byType(MaterialApp)));
        navigator.pushNamed('/non-existent-route');
        await tester.pumpAndSettle();
        
        // Assert - Should show error page instead of crashing
        expect(find.text('Route Not Found'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    });
  });
}
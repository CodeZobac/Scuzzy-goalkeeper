import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:goalkeeper/src/shared/widgets/guest_mode_wrapper.dart';
import 'package:goalkeeper/src/features/auth/presentation/providers/auth_state_provider.dart';

// Generate mocks
@GenerateMocks([
  SupabaseClient,
  GoTrueClient,
  Session,
  User,
])
import 'guest_mode_wrapper_test.mocks.dart';

void main() {
  group('GuestModeWrapper', () {
    late MockSupabaseClient mockSupabaseClient;
    late MockGoTrueClient mockAuth;
    late MockSession mockSession;
    late MockUser mockUser;
    late AuthStateProvider authProvider;

    setUp(() {
      mockSupabaseClient = MockSupabaseClient();
      mockAuth = MockGoTrueClient();
      mockSession = MockSession();
      mockUser = MockUser();

      when(mockSupabaseClient.auth).thenReturn(mockAuth);
      
      authProvider = AuthStateProvider(supabaseClient: mockSupabaseClient);
    });

    Widget createTestWidget({
      required Widget child,
      bool interceptActions = true,
      Set<String> restrictedActions = const {'join_match', 'hire_goalkeeper'},
      bool showRegistrationPrompts = true,
      VoidCallback? onRestrictedAction,
      Future<bool> Function(String)? onActionIntercept,
      Widget? fallbackWidget,
      bool trackEngagement = true,
      String? analyticsContext,
    }) {
      return MaterialApp(
        home: ChangeNotifierProvider<AuthStateProvider>.value(
          value: authProvider,
          child: GuestModeWrapper(
            interceptActions: interceptActions,
            restrictedActions: restrictedActions,
            showRegistrationPrompts: showRegistrationPrompts,
            onRestrictedAction: onRestrictedAction,
            onActionIntercept: onActionIntercept,
            fallbackWidget: fallbackWidget,
            trackEngagement: trackEngagement,
            analyticsContext: analyticsContext,
            child: child,
          ),
        ),
      );
    }

    group('Guest Mode Detection', () {
      testWidgets('should detect guest mode when no session exists', (tester) async {
        // Arrange
        when(mockAuth.currentSession).thenReturn(null);
        when(mockAuth.currentUser).thenReturn(null);

        // Act
        await tester.pumpWidget(createTestWidget(
          child: Builder(
            builder: (context) {
              return Text('Is Guest: ${context.isGuest}');
            },
          ),
        ));

        // Assert
        expect(find.text('Is Guest: true'), findsOneWidget);
      });

      testWidgets('should detect authenticated mode when session exists', (tester) async {
        // Arrange
        when(mockAuth.currentSession).thenReturn(mockSession);
        when(mockAuth.currentUser).thenReturn(mockUser);

        // Act
        await tester.pumpWidget(createTestWidget(
          child: Builder(
            builder: (context) {
              return Text('Is Guest: ${context.isGuest}');
            },
          ),
        ));

        // Assert
        expect(find.text('Is Guest: false'), findsOneWidget);
      });
    });

    group('Action Restriction', () {
      testWidgets('should restrict actions for guest users', (tester) async {
        // Arrange
        when(mockAuth.currentSession).thenReturn(null);
        when(mockAuth.currentUser).thenReturn(null);

        // Act
        await tester.pumpWidget(createTestWidget(
          restrictedActions: {'join_match'},
          child: Builder(
            builder: (context) {
              return Text('Is Restricted: ${context.isActionRestricted('join_match')}');
            },
          ),
        ));

        // Assert
        expect(find.text('Is Restricted: true'), findsOneWidget);
      });

      testWidgets('should allow actions for authenticated users', (tester) async {
        // Arrange
        when(mockAuth.currentSession).thenReturn(mockSession);
        when(mockAuth.currentUser).thenReturn(mockUser);

        // Act
        await tester.pumpWidget(createTestWidget(
          restrictedActions: {'join_match'},
          child: Builder(
            builder: (context) {
              return Text('Is Restricted: ${context.isActionRestricted('join_match')}');
            },
          ),
        ));

        // Assert
        expect(find.text('Is Restricted: false'), findsOneWidget);
      });

      testWidgets('should not restrict actions when interception is disabled', (tester) async {
        // Arrange
        when(mockAuth.currentSession).thenReturn(null);
        when(mockAuth.currentUser).thenReturn(null);

        // Act
        await tester.pumpWidget(createTestWidget(
          interceptActions: false,
          restrictedActions: {'join_match'},
          child: Builder(
            builder: (context) {
              return Text('Is Restricted: ${context.isActionRestricted('join_match')}');
            },
          ),
        ));

        // Assert
        expect(find.text('Is Restricted: false'), findsOneWidget);
      });
    });

    group('Action Attempts', () {
      testWidgets('should allow action for authenticated users', (tester) async {
        // Arrange
        when(mockAuth.currentSession).thenReturn(mockSession);
        when(mockAuth.currentUser).thenReturn(mockUser);

        bool actionExecuted = false;

        // Act
        await tester.pumpWidget(createTestWidget(
          child: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () async {
                  final canProceed = await context.attemptAction('join_match');
                  if (canProceed) {
                    actionExecuted = true;
                  }
                },
                child: const Text('Join Match'),
              );
            },
          ),
        ));

        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle();

        // Assert
        expect(actionExecuted, isTrue);
      });

      testWidgets('should show registration prompt for guest users', (tester) async {
        // Arrange
        when(mockAuth.currentSession).thenReturn(null);
        when(mockAuth.currentUser).thenReturn(null);

        // Act
        await tester.pumpWidget(createTestWidget(
          child: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () async {
                  await context.attemptAction('join_match');
                },
                child: const Text('Join Match'),
              );
            },
          ),
        ));

        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Participe da Partida!'), findsOneWidget);
        expect(find.text('Criar Conta'), findsOneWidget);
        expect(find.text('Agora Não'), findsOneWidget);
      });

      testWidgets('should call custom restricted action callback', (tester) async {
        // Arrange
        when(mockAuth.currentSession).thenReturn(null);
        when(mockAuth.currentUser).thenReturn(null);

        bool callbackCalled = false;

        // Act
        await tester.pumpWidget(createTestWidget(
          showRegistrationPrompts: false,
          onRestrictedAction: () {
            callbackCalled = true;
          },
          child: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () async {
                  await context.attemptAction('join_match');
                },
                child: const Text('Join Match'),
              );
            },
          ),
        ));

        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle();

        // Assert
        expect(callbackCalled, isTrue);
      });

      testWidgets('should use custom action intercept callback', (tester) async {
        // Arrange
        when(mockAuth.currentSession).thenReturn(null);
        when(mockAuth.currentUser).thenReturn(null);

        bool interceptCalled = false;
        bool actionExecuted = false;

        // Act
        await tester.pumpWidget(createTestWidget(
          onActionIntercept: (action) async {
            interceptCalled = true;
            return true; // Allow action
          },
          child: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () async {
                  final canProceed = await context.attemptAction('join_match');
                  if (canProceed) {
                    actionExecuted = true;
                  }
                },
                child: const Text('Join Match'),
              );
            },
          ),
        ));

        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle();

        // Assert
        expect(interceptCalled, isTrue);
        expect(actionExecuted, isTrue);
      });
    });

    group('Error Handling', () {
      testWidgets('should show fallback widget on error', (tester) async {
        // Arrange
        when(mockAuth.currentSession).thenReturn(null);
        when(mockAuth.currentUser).thenReturn(null);

        const fallbackWidget = Text('Fallback Content');

        // Act
        await tester.pumpWidget(createTestWidget(
          fallbackWidget: fallbackWidget,
          onActionIntercept: (action) async {
            throw Exception('Test error');
          },
          child: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () async {
                  await context.attemptAction('join_match');
                },
                child: const Text('Join Match'),
              );
            },
          ),
        ));

        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Ação Não Disponível'), findsOneWidget);
        expect(find.text('Fallback Content'), findsOneWidget);
      });

      testWidgets('should handle missing provider gracefully', (tester) async {
        // Act
        await tester.pumpWidget(MaterialApp(
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () async {
                  final canProceed = await context.attemptAction('join_match');
                  expect(canProceed, isTrue); // Should allow when no provider
                },
                child: const Text('Join Match'),
              );
            },
          ),
        ));

        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle();
      });
    });

    group('GuestModeActionMixin', () {
      testWidgets('should safely attempt actions with mixin', (tester) async {
        // Arrange
        when(mockAuth.currentSession).thenReturn(mockSession);
        when(mockAuth.currentUser).thenReturn(mockUser);

        bool actionExecuted = false;

        // Act
        await tester.pumpWidget(createTestWidget(
          child: _TestWidgetWithMixin(
            onActionSuccess: () {
              actionExecuted = true;
            },
          ),
        ));

        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle();

        // Assert
        expect(actionExecuted, isTrue);
      });

      testWidgets('should check action permissions with mixin', (tester) async {
        // Arrange
        when(mockAuth.currentSession).thenReturn(null);
        when(mockAuth.currentUser).thenReturn(null);

        // Act
        await tester.pumpWidget(createTestWidget(
          child: const _TestWidgetWithMixin(),
        ));

        // Assert
        expect(find.text('Can Perform: false'), findsOneWidget);
      });
    });

    group('Analytics and Tracking', () {
      testWidgets('should track engagement when enabled', (tester) async {
        // Arrange
        when(mockAuth.currentSession).thenReturn(null);
        when(mockAuth.currentUser).thenReturn(null);

        // Act
        await tester.pumpWidget(createTestWidget(
          trackEngagement: true,
          analyticsContext: 'test_context',
          child: const Text('Test'),
        ));

        await tester.pumpAndSettle();

        // Assert - verify guest context was initialized
        expect(authProvider.guestContext, isNotNull);
      });

      testWidgets('should not track engagement when disabled', (tester) async {
        // Arrange
        when(mockAuth.currentSession).thenReturn(null);
        when(mockAuth.currentUser).thenReturn(null);

        // Act
        await tester.pumpWidget(createTestWidget(
          trackEngagement: false,
          child: const Text('Test'),
        ));

        await tester.pumpAndSettle();

        // Assert - verify guest context was not initialized
        expect(authProvider.guestContext, isNull);
      });
    });
  });
}

/// Test widget that uses the GuestModeActionMixin
class _TestWidgetWithMixin extends StatefulWidget {
  final VoidCallback? onActionSuccess;

  const _TestWidgetWithMixin({this.onActionSuccess});

  @override
  State<_TestWidgetWithMixin> createState() => _TestWidgetWithMixinState();
}

class _TestWidgetWithMixinState extends State<_TestWidgetWithMixin>
    with GuestModeActionMixin {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('Can Perform: ${canPerformAction('join_match')}'),
        ElevatedButton(
          onPressed: () async {
            await safelyAttemptAction('join_match', () {
              widget.onActionSuccess?.call();
            });
          },
          child: const Text('Test Action'),
        ),
      ],
    );
  }
}
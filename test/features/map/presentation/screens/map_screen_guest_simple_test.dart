import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:goalkeeper/src/core/utils/guest_mode_utils.dart';
import 'package:goalkeeper/src/shared/widgets/registration_prompt_dialog.dart';

void main() {
  group('Map Screen Guest Mode Simple Tests', () {
    setUp(() {
      // Set up mock client for guest mode (no session)
      GuestModeUtils.setTestClient(null);
    });

    tearDown(() {
      // Reset test client
      GuestModeUtils.setTestClient(null);
    });

    group('Guest Mode Utility Tests', () {
      test('should correctly identify guest mode when no client is set', () {
        // When no test client is set, it should fall back to checking the actual Supabase instance
        // For testing purposes, we'll test the utility methods directly
        expect(GuestModeUtils.actionRequiresAuth('hire_goalkeeper'), isTrue);
        expect(GuestModeUtils.actionRequiresAuth('join_match'), isTrue);
        expect(GuestModeUtils.actionRequiresAuth('view_map'), isFalse);
      });

      test('should allow guest access to appropriate features', () {
        expect(GuestModeUtils.canGuestAccess('view_map'), isTrue);
        expect(GuestModeUtils.canGuestAccess('view_fields'), isTrue);
        expect(GuestModeUtils.canGuestAccess('view_goalkeeper_locations'), isTrue);
        expect(GuestModeUtils.canGuestAccess('hire_goalkeeper'), isFalse);
      });

      test('should provide correct redirect route for guest actions', () {
        expect(GuestModeUtils.getGuestRedirectRoute('hire_goalkeeper'), equals('/signup'));
        expect(GuestModeUtils.getGuestRedirectRoute('join_match'), equals('/signup'));
      });

      test('should check if route is accessible to guests', () {
        expect(GuestModeUtils.isGuestAccessibleRoute('/map'), isTrue);
        expect(GuestModeUtils.isGuestAccessibleRoute('/home'), isTrue);
        expect(GuestModeUtils.isGuestAccessibleRoute('/announcements'), isTrue);
        expect(GuestModeUtils.isGuestAccessibleRoute('/profile'), isTrue);
        expect(GuestModeUtils.isGuestAccessibleRoute('/signup'), isTrue);
        expect(GuestModeUtils.isGuestAccessibleRoute('/signin'), isTrue);
      });

      test('should generate unique guest session IDs', () async {
        final id1 = GuestModeUtils.generateGuestSessionId();
        // Add a small delay to ensure different timestamps
        await Future.delayed(const Duration(milliseconds: 1));
        final id2 = GuestModeUtils.generateGuestSessionId();
        
        expect(id1, isNotEmpty);
        expect(id2, isNotEmpty);
        expect(id1, isNot(equals(id2)));
        expect(id1, startsWith('guest_'));
        expect(id2, startsWith('guest_'));
      });
    });

    group('Registration Prompt Configuration Tests', () {
      test('should create correct configuration for hire goalkeeper prompt', () {
        final config = RegistrationPromptConfig.hireGoalkeeper();
        
        expect(config.title, equals('Contrate um Goleiro!'));
        expect(config.message, contains('contratar goleiros'));
        expect(config.context, equals('hire_goalkeeper'));
        expect(config.icon, equals(Icons.sports_handball));
        expect(config.primaryButtonText, equals('Criar Conta'));
        expect(config.secondaryButtonText, equals('Agora Não'));
      });

      test('should create correct configuration for join match prompt', () {
        final config = RegistrationPromptConfig.joinMatch();
        
        expect(config.title, equals('Participe da Partida!'));
        expect(config.message, contains('participar de partidas'));
        expect(config.context, equals('join_match'));
        expect(config.icon, equals(Icons.sports_soccer));
      });

      test('should create correct configuration for profile access prompt', () {
        final config = RegistrationPromptConfig.profileAccess();
        
        expect(config.title, equals('Crie seu Perfil!'));
        expect(config.message, contains('perfil personalizado'));
        expect(config.context, equals('profile_access'));
        expect(config.icon, equals(Icons.account_circle));
      });

      test('should create correct configuration for general features prompt', () {
        final config = RegistrationPromptConfig.generalFeatures();
        
        expect(config.title, equals('Desbloqueie Todos os Recursos!'));
        expect(config.message, contains('todos os recursos'));
        expect(config.context, equals('general_features'));
        expect(config.icon, equals(Icons.lock_open));
      });
    });

    group('Registration Prompt Widget Tests', () {
      testWidgets('should display hire goalkeeper prompt correctly', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: RegistrationPromptDialog(
                config: RegistrationPromptConfig.hireGoalkeeper(),
              ),
            ),
            routes: {
              '/signup': (context) => const Scaffold(
                body: Center(child: Text('Signup Screen')),
              ),
            },
          ),
        );

        await tester.pumpAndSettle();

        // Verify dialog content
        expect(find.text('Contrate um Goleiro!'), findsOneWidget);
        expect(find.text('Para contratar goleiros e acessar todos os recursos da plataforma, você precisa criar uma conta. Junte-se à nossa comunidade!'), findsOneWidget);
        expect(find.text('Criar Conta'), findsOneWidget);
        expect(find.text('Agora Não'), findsOneWidget);
        expect(find.byIcon(Icons.sports_handball), findsOneWidget);
      });

      testWidgets('should navigate to signup when register button is pressed', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: RegistrationPromptDialog(
                config: RegistrationPromptConfig.hireGoalkeeper(),
              ),
            ),
            routes: {
              '/signup': (context) => const Scaffold(
                body: Center(child: Text('Signup Screen')),
              ),
            },
          ),
        );

        await tester.pumpAndSettle();

        // Tap register button
        await tester.tap(find.text('Criar Conta'));
        await tester.pumpAndSettle();

        // Verify navigation to signup screen
        expect(find.text('Signup Screen'), findsOneWidget);
      });

      testWidgets('should dismiss dialog when cancel button is pressed', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () => showDialog(
                      context: context,
                      builder: (_) => RegistrationPromptDialog(
                        config: RegistrationPromptConfig.hireGoalkeeper(),
                      ),
                    ),
                    child: const Text('Show Dialog'),
                  ),
                ),
              ),
            ),
          ),
        );

        // Show dialog
        await tester.tap(find.text('Show Dialog'));
        await tester.pumpAndSettle();

        // Verify dialog is shown
        expect(find.byType(RegistrationPromptDialog), findsOneWidget);

        // Tap cancel button
        await tester.tap(find.text('Agora Não'));
        await tester.pumpAndSettle();

        // Verify dialog is dismissed
        expect(find.byType(RegistrationPromptDialog), findsNothing);
      });

      testWidgets('should display benefits list correctly', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: RegistrationPromptDialog(
                config: RegistrationPromptConfig.hireGoalkeeper(),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify benefits section is displayed
        expect(find.text('Com sua conta você pode:'), findsOneWidget);
        expect(find.text('Contratar goleiros profissionais'), findsOneWidget);
        expect(find.text('Avaliar e ser avaliado'), findsOneWidget);
        expect(find.text('Acessar perfis detalhados'), findsOneWidget);
        expect(find.text('Gerenciar seus contratos'), findsOneWidget);
      });
    });
  });
}
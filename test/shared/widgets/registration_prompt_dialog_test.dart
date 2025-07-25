import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:goalkeeper/src/shared/widgets/registration_prompt_dialog.dart';
import 'package:goalkeeper/src/features/auth/data/models/registration_prompt_config.dart';
import 'package:goalkeeper/src/features/auth/presentation/theme/app_theme.dart';

void main() {
  group('RegistrationPromptDialog Tests', () {
    testWidgets('should render dialog with correct content', (tester) async {
      const config = RegistrationPromptConfig(
        title: 'Test Title',
        message: 'Test Message',
        context: 'test_context',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => const RegistrationPromptDialog(
                      config: config,
                    ),
                  );
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pump();

      expect(find.byType(RegistrationPromptDialog), findsOneWidget);
      expect(find.text('Test Title'), findsOneWidget);
      expect(find.text('Test Message'), findsOneWidget);
      expect(find.text('Criar Conta'), findsOneWidget);
      expect(find.text('Agora Não'), findsOneWidget);
    });

    testWidgets('should show correct icon for join match context', (tester) async {
      const config = RegistrationPromptConfig.joinMatch;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => const RegistrationPromptDialog(
                      config: config,
                    ),
                  );
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pump();

      expect(find.byIcon(Icons.sports_soccer), findsOneWidget);
      expect(find.text('Participe da Partida!'), findsOneWidget);
    });

    testWidgets('should show correct icon for hire goalkeeper context', (tester) async {
      const config = RegistrationPromptConfig.hireGoalkeeper;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
      );
    }

    testWidgets('should display dialog with correct title and message', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Participe da Partida!'), findsOneWidget);
      expect(find.text('Para participar de partidas e se conectar com outros jogadores, você precisa criar uma conta. É rápido e gratuito!'), findsOneWidget);
    });

    testWidgets('should display correct icon in header', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.sports_soccer), findsOneWidget);
    });

    testWidgets('should display primary and secondary buttons', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Criar Conta'), findsOneWidget);
      expect(find.text('Agora Não'), findsOneWidget);
    });

    testWidgets('should display benefits list', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Com sua conta você pode:'), findsOneWidget);
      expect(find.text('Participar de partidas e eventos'), findsOneWidget);
      expect(find.text('Conectar-se com outros jogadores'), findsOneWidget);
      expect(find.text('Receber notificações de novas partidas'), findsOneWidget);
      expect(find.text('Acompanhar seu histórico de jogos'), findsOneWidget);
    });

    testWidgets('should call onRegisterPressed when primary button is tapped', (tester) async {
      bool registerPressed = false;
      
      await tester.pumpWidget(createTestWidget(
        onRegisterPressed: () => registerPressed = true,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Criar Conta'));
      await tester.pumpAndSettle();

      expect(registerPressed, isTrue);
    });

    testWidgets('should call onCancelPressed when secondary button is tapped', (tester) async {
      bool cancelPressed = false;
      
      await tester.pumpWidget(createTestWidget(
        onCancelPressed: () => cancelPressed = true,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Agora Não'));
      await tester.pumpAndSettle();

      expect(cancelPressed, isTrue);
    });

    testWidgets('should display different benefits for hire goalkeeper context', (tester) async {
      final config = RegistrationPromptConfig.hireGoalkeeper();
      
      await tester.pumpWidget(createTestWidget(config: config));
      await tester.pumpAndSettle();

      expect(find.text('Contratar goleiros profissionais'), findsOneWidget);
      expect(find.text('Avaliar e ser avaliado'), findsOneWidget);
      expect(find.text('Acessar perfis detalhados'), findsOneWidget);
      expect(find.text('Gerenciar seus contratos'), findsOneWidget);
    });

    testWidgets('should display different benefits for profile access context', (tester) async {
      final config = RegistrationPromptConfig.profileAccess();
      
      await tester.pumpWidget(createTestWidget(config: config));
      await tester.pumpAndSettle();

      expect(find.text('Criar seu perfil personalizado'), findsOneWidget);
      expect(find.text('Gerenciar suas informações'), findsOneWidget);
      expect(find.text('Acompanhar estatísticas'), findsOneWidget);
      expect(find.text('Conectar-se com a comunidade'), findsOneWidget);
    });

    testWidgets('should use app theme colors and styling', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Find the dialog container
      final dialogContainer = tester.widget<Container>(
        find.descendant(
          of: find.byType(Dialog),
          matching: find.byType(Container),
        ).first,
      );

      // Verify the dialog uses the correct background color
      final decoration = dialogContainer.decoration as BoxDecoration;
      expect(decoration.color, AppTheme.secondaryBackground);
      expect(decoration.borderRadius, BorderRadius.circular(AppTheme.borderRadiusLarge));
    });

    testWidgets('should have proper animations', (tester) async {
      await tester.pumpWidget(createTestWidget());
      
      // Verify initial state (should be animating)
      expect(find.byType(AnimatedBuilder), findsAtLeastNWidgets(1));
      expect(find.byType(Transform), findsAtLeastNWidgets(1));
      expect(find.byType(SlideTransition), findsOneWidget);
      
      // Let animations complete
      await tester.pumpAndSettle();
      
      // Dialog should be fully visible after animations
      expect(find.byType(RegistrationPromptDialog), findsOneWidget);
    });

    testWidgets('should display custom button texts when provided', (tester) async {
      const customConfig = RegistrationPromptConfig(
        title: 'Custom Title',
        message: 'Custom message',
        context: 'custom',
        primaryButtonText: 'Join Now',
        secondaryButtonText: 'Maybe Later',
      );
      
      await tester.pumpWidget(createTestWidget(config: customConfig));
      await tester.pumpAndSettle();

      expect(find.text('Join Now'), findsOneWidget);
      expect(find.text('Maybe Later'), findsOneWidget);
    });
  });

  group('RegistrationPromptHelper', () {
    testWidgets('showJoinMatchPrompt should display join match dialog', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () => RegistrationPromptHelper.showJoinMatchPrompt(context),
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Participe da Partida!'), findsOneWidget);
      expect(find.byIcon(Icons.sports_soccer), findsOneWidget);
    });

    testWidgets('showHireGoalkeeperPrompt should display hire goalkeeper dialog', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () => RegistrationPromptHelper.showHireGoalkeeperPrompt(context),
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Contrate um Goleiro!'), findsOneWidget);
      expect(find.byIcon(Icons.sports_handball), findsOneWidget);
    });

    testWidgets('showProfileAccessPrompt should display profile access dialog', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () => RegistrationPromptHelper.showProfileAccessPrompt(context),
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Crie seu Perfil!'), findsOneWidget);
      expect(find.byIcon(Icons.account_circle), findsOneWidget);
    });

    testWidgets('showCustomPrompt should display custom dialog', (tester) async {
      const customConfig = RegistrationPromptConfig(
        title: 'Custom Dialog',
        message: 'Custom message',
        context: 'custom',
        icon: Icons.star,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () => RegistrationPromptHelper.showCustomPrompt(context, customConfig),
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Custom Dialog'), findsOneWidget);
      expect(find.byIcon(Icons.star), findsOneWidget);
    });

    testWidgets('dialogs should be dismissible by default', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () => RegistrationPromptHelper.showJoinMatchPrompt(context),
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Dialog should be visible
      expect(find.byType(RegistrationPromptDialog), findsOneWidget);

      // Tap outside the dialog to dismiss
      await tester.tapAt(const Offset(50, 50));
      await tester.pumpAndSettle();

      // Dialog should be dismissed
      expect(find.byType(RegistrationPromptDialog), findsNothing);
    });
  });
}
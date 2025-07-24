import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goalkeeper/src/features/notifications/presentation/widgets/notification_action_buttons.dart';

void main() {
  group('NotificationActionButtons', () {
    testWidgets('renders single action button correctly', (WidgetTester tester) async {
      bool actionPressed = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NotificationActionButtons(
              actions: [
                NotificationAction(
                  text: 'Ver Detalhes',
                  onPressed: () => actionPressed = true,
                  type: NotificationActionType.viewDetails,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Ver Detalhes'), findsOneWidget);
      
      await tester.tap(find.text('Ver Detalhes'));
      expect(actionPressed, isTrue);
    });

    testWidgets('renders multiple action buttons correctly', (WidgetTester tester) async {
      bool acceptPressed = false;
      bool declinePressed = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NotificationActionButtons(
              actions: [
                NotificationAction(
                  text: 'Recusar',
                  onPressed: () => declinePressed = true,
                  type: NotificationActionType.decline,
                ),
                NotificationAction(
                  text: 'Aceitar',
                  onPressed: () => acceptPressed = true,
                  type: NotificationActionType.accept,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Recusar'), findsOneWidget);
      expect(find.text('Aceitar'), findsOneWidget);
      
      await tester.tap(find.text('Aceitar'));
      expect(acceptPressed, isTrue);
      
      await tester.tap(find.text('Recusar'));
      expect(declinePressed, isTrue);
    });

    testWidgets('shows loading state correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NotificationActionButtons(
              isLoading: true,
              loadingText: 'Processando...',
              actions: [
                NotificationAction(
                  text: 'Aceitar',
                  onPressed: () {},
                  type: NotificationActionType.accept,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Processando...'), findsOneWidget);
    });

    testWidgets('disables buttons when action is not enabled', (WidgetTester tester) async {
      bool actionPressed = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NotificationActionButtons(
              actions: [
                NotificationAction(
                  text: 'Aceitar',
                  onPressed: () => actionPressed = true,
                  type: NotificationActionType.accept,
                  isEnabled: false,
                ),
              ],
            ),
          ),
        ),
      );

      await tester.tap(find.text('Aceitar'));
      expect(actionPressed, isFalse);
    });

    testWidgets('applies correct styling for accept button', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NotificationActionButtons(
              actions: [
                NotificationAction(
                  text: 'Aceitar',
                  onPressed: () {},
                  type: NotificationActionType.accept,
                ),
              ],
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(NotificationActionButtons),
          matching: find.byType(Container),
        ).first,
      );

      expect(container.decoration, isA<BoxDecoration>());
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.gradient, isA<LinearGradient>());
      
      final gradient = decoration.gradient as LinearGradient;
      expect(gradient.colors, contains(const Color(0xFF4CAF50)));
      expect(gradient.colors, contains(const Color(0xFF45A049)));
    });

    testWidgets('applies correct styling for decline button', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NotificationActionButtons(
              actions: [
                NotificationAction(
                  text: 'Recusar',
                  onPressed: () {},
                  type: NotificationActionType.decline,
                ),
              ],
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(NotificationActionButtons),
          matching: find.byType(Container),
        ).first,
      );

      expect(container.decoration, isA<BoxDecoration>());
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.gradient, isA<LinearGradient>());
      
      final gradient = decoration.gradient as LinearGradient;
      expect(gradient.colors, contains(const Color(0xFFFF6B6B)));
      expect(gradient.colors, contains(const Color(0xFFE94560)));
    });

    testWidgets('has proper touch targets for accessibility', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NotificationActionButtons(
              actions: [
                NotificationAction(
                  text: 'Aceitar',
                  onPressed: () {},
                  type: NotificationActionType.accept,
                ),
              ],
            ),
          ),
        ),
      );

      // Check that the button has the correct height by finding the container
      final containerFinder = find.descendant(
        of: find.byType(NotificationActionButtons),
        matching: find.byType(Container),
      );
      
      expect(containerFinder, findsAtLeastNWidgets(1));
      
      // Verify the button is tappable and has proper size
      final buttonSize = tester.getSize(find.byType(InkWell).first);
      expect(buttonSize.height, greaterThanOrEqualTo(44.0)); // Minimum touch target size
    });

    testWidgets('returns empty widget when no actions provided', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NotificationActionButtons(
              actions: [],
            ),
          ),
        ),
      );

      expect(find.byType(SizedBox), findsOneWidget);
      final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox));
      expect(sizedBox.width, equals(0.0));
      expect(sizedBox.height, equals(0.0));
    });
  });
}
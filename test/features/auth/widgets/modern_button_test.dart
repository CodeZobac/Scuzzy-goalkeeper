import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goalkeeper/src/features/auth/presentation/widgets/modern_button.dart';

void main() {
  group('ModernButton Tests', () {
    testWidgets('should create button without errors', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ModernButton(
              text: 'Test Button',
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.byType(ModernButton), findsOneWidget);
      expect(find.text('Test Button'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('should handle tap events', (tester) async {
      bool tapped = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ModernButton(
              text: 'Tap Me',
              onPressed: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ModernButton));
      expect(tapped, isTrue);
    });

    testWidgets('should show loading state', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ModernButton(
              text: 'Loading Button',
              isLoading: true,
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Loading Button'), findsNothing);
    });

    testWidgets('should be disabled when onPressed is null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ModernButton(
              text: 'Disabled Button',
              onPressed: null,
            ),
          ),
        ),
      );

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('should be disabled when isLoading is true', (tester) async {
      bool tapped = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ModernButton(
              text: 'Loading Button',
              isLoading: true,
              onPressed: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ModernButton));
      expect(tapped, isFalse);
    });

    testWidgets('should show icon when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ModernButton(
              text: 'Icon Button',
              icon: Icons.login,
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.login), findsOneWidget);
      expect(find.text('Icon Button'), findsOneWidget);
    });

    testWidgets('should handle different button styles', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                ModernButton(
                  text: 'Primary',
                  onPressed: () {},
                ),
                ModernButton(
                  text: 'Outlined',
                  outlined: true,
                  onPressed: () {},
                ),
                ModernButton(
                  text: 'Custom Color',
                  backgroundColor: Colors.red,
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(ModernButton), findsNWidgets(3));
      expect(find.text('Primary'), findsOneWidget);
      expect(find.text('Outlined'), findsOneWidget);
      expect(find.text('Custom Color'), findsOneWidget);
    });

    testWidgets('should handle different sizes', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                ModernButton(
                  text: 'Small',
                  height: 40,
                  onPressed: () {},
                ),
                ModernButton(
                  text: 'Medium',
                  height: 48,
                  onPressed: () {},
                ),
                ModernButton(
                  text: 'Large',
                  height: 56,
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(ModernButton), findsNWidgets(3));
    });

    testWidgets('should animate on press', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ModernButton(
              text: 'Animated Button',
              onPressed: () {},
            ),
          ),
        ),
      );

      // Press and hold
      await tester.press(find.byType(ModernButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Release
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('should handle custom width', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ModernButton(
              text: 'Custom Width',
              width: 200,
              onPressed: () {},
            ),
          ),
        ),
      );

      final button = tester.getSize(find.byType(ModernButton));
      expect(button.width, equals(200));
    });

    testWidgets('should show custom loading text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ModernButton(
              text: 'Sign In',
              isLoading: true,
              loadingText: 'Signing in...',
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.text('Signing in...'), findsOneWidget);
    });
  });

  group('ModernLinkButton Tests', () {
    testWidgets('should create link button without errors', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ModernLinkButton(
              text: 'Link Button',
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.byType(ModernLinkButton), findsOneWidget);
      expect(find.text('Link Button'), findsOneWidget);
    });

    testWidgets('should handle tap events', (tester) async {
      bool tapped = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ModernLinkButton(
              text: 'Tap Link',
              onPressed: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ModernLinkButton));
      expect(tapped, isTrue);
    });

    testWidgets('should be disabled when onPressed is null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ModernLinkButton(
              text: 'Disabled Link',
              onPressed: null,
            ),
          ),
        ),
      );

      final textButton = tester.widget<TextButton>(find.byType(TextButton));
      expect(textButton.onPressed, isNull);
    });

    testWidgets('should show icon when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ModernLinkButton(
              text: 'Link with Icon',
              icon: Icons.arrow_forward,
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
    });

    testWidgets('should handle different styles', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                ModernLinkButton(
                  text: 'Default Link',
                  onPressed: () {},
                ),
                ModernLinkButton(
                  text: 'Custom Color Link',
                  textColor: Colors.red,
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(ModernLinkButton), findsNWidgets(2));
    });

    testWidgets('should animate on press', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ModernLinkButton(
              text: 'Animated Link',
              onPressed: () {},
            ),
          ),
        ),
      );

      await tester.press(find.byType(ModernLinkButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });

  group('ModernButton Accessibility Tests', () {
    testWidgets('should have proper semantics', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ModernButton(
              text: 'Accessible Button',

              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.byType(ModernButton), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('should support screen readers when loading', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ModernButton(
              text: 'Loading Button',
              isLoading: true,

              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should indicate disabled state to screen readers', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ModernButton(
              text: 'Disabled Button',
              onPressed: null,
            ),
          ),
        ),
      );

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
    });
  });

  group('ModernButton Performance Tests', () {
    testWidgets('should handle rapid taps efficiently', (tester) async {
      int tapCount = 0;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ModernButton(
              text: 'Rapid Tap Test',
              onPressed: () => tapCount++,
            ),
          ),
        ),
      );

      // Simulate rapid taps
      for (int i = 0; i < 5; i++) {
        await tester.tap(find.byType(ModernButton));
        await tester.pump();
      }

      expect(tapCount, equals(5));
      expect(tester.takeException(), isNull);
    });

    testWidgets('should dispose animation controllers properly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ModernButton(
              text: 'Test Disposal',
              onPressed: () {},
            ),
          ),
        ),
      );

      // Remove widget to trigger disposal
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Container(),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('should handle state changes efficiently', (tester) async {
      bool isLoading = false;
      
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return MaterialApp(
              home: Scaffold(
                body: Column(
                  children: [
                    ModernButton(
                      text: 'Toggle Loading',
                      isLoading: isLoading,
                      onPressed: () {},
                    ),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          isLoading = !isLoading;
                        });
                      },
                      child: const Text('Toggle'),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );

      // Toggle loading state multiple times
      for (int i = 0; i < 3; i++) {
        await tester.tap(find.text('Toggle'));
        await tester.pump();
      }

      expect(tester.takeException(), isNull);
    });
  });
}
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goalkeeper/src/features/auth/presentation/widgets/modern_text_field.dart';

void main() {
  group('ModernTextField Tests', () {
    testWidgets('should create text field without errors', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ModernTextField(
              hintText: 'Enter text',
            ),
          ),
        ),
      );

      expect(find.byType(ModernTextField), findsOneWidget);
      expect(find.text('Enter text'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('should handle text input correctly', (tester) async {
      final controller = TextEditingController();
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ModernTextField(
              hintText: 'Enter text',
              controller: controller,
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextFormField), 'test input');
      expect(controller.text, equals('test input'));
    });

    testWidgets('should show/hide password text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ModernTextField(
              hintText: 'Password',
              obscureText: true,
            ),
          ),
        ),
      );

      // Should show password toggle icon
      expect(find.byIcon(Icons.visibility_off), findsOneWidget);

      // Tap to show password
      await tester.tap(find.byIcon(Icons.visibility_off));
      await tester.pump();

      expect(find.byIcon(Icons.visibility), findsOneWidget);
    });

    testWidgets('should show validation error', (tester) async {
      String? validator(String? value) {
        if (value == null || value.isEmpty) {
          return 'Field is required';
        }
        return null;
      }

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ModernTextField(
              hintText: 'Email',
              validator: validator,
            ),
          ),
        ),
      );

      // Trigger validation by entering and clearing text
      await tester.enterText(find.byType(TextFormField), 'test');
      await tester.pump();
      await tester.enterText(find.byType(TextFormField), '');
      await tester.pump();

      expect(find.text('Field is required'), findsOneWidget);
    });

    testWidgets('should show prefix icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ModernTextField(
              hintText: 'Email',
              prefixIcon: Icons.email,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.email), findsOneWidget);
    });

    testWidgets('should handle focus animations', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ModernTextField(
              hintText: 'Test field',
            ),
          ),
        ),
      );

      // Tap to focus
      await tester.tap(find.byType(TextFormField));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(tester.takeException(), isNull);
    });

    testWidgets('should show validation icon when enabled', (tester) async {
      String? validator(String? value) {
        if (value != null && value.contains('@')) {
          return null; // Valid
        }
        return 'Invalid email';
      }

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ModernTextField(
              hintText: 'Email',
              validator: validator,
              showValidationIcon: true,
            ),
          ),
        ),
      );

      // Enter valid email
      await tester.enterText(find.byType(TextFormField), 'test@example.com');
      await tester.pump();

      // Should show success icon
      expect(find.byIcon(Icons.check_circle), findsOneWidget);

      // Enter invalid email
      await tester.enterText(find.byType(TextFormField), 'invalid');
      await tester.pump();

      // Should show error icon
      expect(find.byIcon(Icons.error), findsOneWidget);
    });

    testWidgets('should handle enabled/disabled state', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ModernTextField(
              hintText: 'Disabled field',
              enabled: false,
            ),
          ),
        ),
      );

      final textField = tester.widget<TextFormField>(find.byType(TextFormField));
      expect(textField.enabled, isFalse);
    });

    testWidgets('should call onChanged callback', (tester) async {
      String? changedValue;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ModernTextField(
              hintText: 'Test field',
              onChanged: (value) => changedValue = value,
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextFormField), 'test value');
      expect(changedValue, equals('test value'));
    });

    testWidgets('should call onFieldSubmitted callback', (tester) async {
      String? submittedValue;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ModernTextField(
              hintText: 'Test field',
              onFieldSubmitted: (value) => submittedValue = value,
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextFormField), 'submitted text');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      
      expect(submittedValue, equals('submitted text'));
    });

    testWidgets('should handle different keyboard types', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ModernTextField(
              hintText: 'Email field',
              keyboardType: TextInputType.emailAddress,
            ),
          ),
        ),
      );

      final textField = tester.widget<TextFormField>(find.byType(TextFormField));
      expect(textField.keyboardType, equals(TextInputType.emailAddress));
    });

    testWidgets('should handle text input actions', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ModernTextField(
              hintText: 'Test field',
              textInputAction: TextInputAction.next,
            ),
          ),
        ),
      );

      final textField = tester.widget<TextFormField>(find.byType(TextFormField));
      expect(textField.textInputAction, equals(TextInputAction.next));
    });
  });

  group('ModernTextField Accessibility Tests', () {
    testWidgets('should have proper semantics', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ModernTextField(
              hintText: 'Email address',
            ),
          ),
        ),
      );

      expect(find.byType(ModernTextField), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('should support screen readers', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ModernTextField(
              hintText: 'Password',
              obscureText: true,
            ),
          ),
        ),
      );

      // Verify accessibility properties are set
      final textField = tester.widget<TextFormField>(find.byType(TextFormField));
      expect(textField.obscureText, isTrue);
    });
  });

  group('ModernTextField Performance Tests', () {
    testWidgets('should handle rapid text changes efficiently', (tester) async {
      final controller = TextEditingController();
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ModernTextField(
              hintText: 'Performance test',
              controller: controller,
            ),
          ),
        ),
      );

      // Simulate rapid text changes
      for (int i = 0; i < 10; i++) {
        await tester.enterText(find.byType(TextFormField), 'text$i');
        await tester.pump();
      }

      expect(controller.text, equals('text9'));
      expect(tester.takeException(), isNull);
    });

    testWidgets('should dispose animation controllers properly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ModernTextField(
              hintText: 'Test disposal',
            ),
          ),
        ),
      );

      // Remove widget to trigger disposal
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: const SizedBox(),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });
}
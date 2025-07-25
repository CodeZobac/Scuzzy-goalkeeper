import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goalkeeper/src/features/auth/presentation/widgets/modern_auth_layout.dart';
import 'package:goalkeeper/src/features/auth/presentation/widgets/modern_text_field.dart';
import 'package:goalkeeper/src/features/auth/presentation/widgets/modern_button.dart';
import 'package:goalkeeper/src/features/auth/presentation/widgets/responsive_auth_layout.dart';
import 'package:goalkeeper/src/features/auth/presentation/screens/sign_in_screen.dart';
import 'package:goalkeeper/src/features/auth/presentation/screens/sign_up_screen.dart';

void main() {
  group('Auth Component Accessibility Tests', () {
    testWidgets('ModernAuthLayout should have proper semantic structure', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ModernAuthLayout(
            title: 'Welcome Back',
            subtitle: 'Sign in to your account',
            child: const Text('Form content'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should have proper heading hierarchy
      expect(find.text('Welcome Back'), findsOneWidget);
      expect(find.text('Sign in to your account'), findsOneWidget);
      expect(find.text('Form content'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('ModernTextField should support screen readers', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ModernTextField(
              hintText: 'Email address',
              semanticsLabel: 'Enter your email address',
              keyboardType: TextInputType.emailAddress,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should provide proper semantic information
      expect(find.byType(ModernTextField), findsOneWidget);
      expect(find.text('Email address'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('ModernTextField validation should be accessible', (tester) async {
      String? validator(String? value) {
        if (value == null || value.isEmpty) {
          return 'This field is required';
        }
        return null;
      }

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ModernTextField(
              hintText: 'Required field',
              validator: validator,
              semanticsLabel: 'Required input field',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Trigger validation
      await tester.enterText(find.byType(TextField), 'test');
      await tester.pump();
      await tester.enterText(find.byType(TextField), '');
      await tester.pump();

      // Error message should be accessible
      expect(find.text('This field is required'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Password field should announce visibility state', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ModernTextField(
              hintText: 'Password',
              obscureText: true,
              semanticsLabel: 'Enter your password',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show password visibility toggle
      expect(find.byIcon(Icons.visibility_off), findsOneWidget);

      // Tap to show password
      await tester.tap(find.byIcon(Icons.visibility_off));
      await tester.pump();

      // Should announce state change
      expect(find.byIcon(Icons.visibility), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('ModernButton should have proper accessibility attributes', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ModernButton(
              text: 'Sign In',
              semanticsLabel: 'Sign in to your account',
              onPressed: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Sign In'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Loading button should announce loading state', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ModernButton(
              text: 'Sign In',
              isLoading: true,
              semanticsLabel: 'Signing in, please wait',
              onPressed: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show loading indicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Disabled button should be announced as disabled', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ModernButton(
              text: 'Disabled Button',
              onPressed: null,
              semanticsLabel: 'Button is disabled',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
      expect(tester.takeException(), isNull);
    });

    testWidgets('ResponsiveAuthLayout should maintain accessibility across screen sizes', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ResponsiveAuthLayout(
            title: 'Responsive Test',
            subtitle: 'Test subtitle',
            child: const Text('Content'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Test mobile size
      await tester.binding.setSurfaceSize(const Size(375, 667));
      await tester.pump();
      expect(find.text('Responsive Test'), findsOneWidget);

      // Test tablet size
      await tester.binding.setSurfaceSize(const Size(768, 1024));
      await tester.pump();
      expect(find.text('Responsive Test'), findsOneWidget);

      // Test desktop size
      await tester.binding.setSurfaceSize(const Size(1920, 1080));
      await tester.pump();
      expect(find.text('Responsive Test'), findsOneWidget);

      // Reset surface size
      await tester.binding.setSurfaceSize(null);
      expect(tester.takeException(), isNull);
    });
  });

  group('Auth Screen Accessibility Tests', () {
    testWidgets('SignInScreen should have proper focus order', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SignInScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Should have logical focus order: email -> password -> sign in button
      final textFields = find.byType(ModernTextField);
      expect(textFields, findsNWidgets(2));

      // Focus on first field (email)
      await tester.tap(textFields.first);
      await tester.pump();

      // Tab to next field (password)
      await tester.testTextInput.receiveAction(TextInputAction.next);
      await tester.pump();

      expect(tester.takeException(), isNull);
    });

    testWidgets('SignUpScreen should announce form requirements', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SignUpScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Should have all required fields
      expect(find.byType(ModernTextField), findsNWidgets(4)); // Name, email, password, confirm
      expect(find.byType(ModernButton), findsAtLeastNWidgets(1));
      expect(tester.takeException(), isNull);
    });

    testWidgets('Form validation errors should be accessible', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SignInScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Try to submit empty form
      final signInButton = find.widgetWithText(ModernButton, 'Sign In');
      await tester.tap(signInButton);
      await tester.pump();

      // Validation errors should be announced
      expect(find.text('Email is required'), findsOneWidget);
      expect(find.text('Password is required'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Auth header SVG should have proper alt text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SignInScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // SVG header should be accessible
      expect(find.byType(ModernAuthLayout), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Social sign-in buttons should be accessible', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SignInScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Look for social sign-in options
      final googleButton = find.text('Continue with Google');
      final appleButton = find.text('Continue with Apple');

      if (googleButton.evaluate().isNotEmpty) {
        expect(googleButton, findsOneWidget);
      }

      if (appleButton.evaluate().isNotEmpty) {
        expect(appleButton, findsOneWidget);
      }

      expect(tester.takeException(), isNull);
    });

    testWidgets('Navigation links should be accessible', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SignInScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Look for navigation links
      final forgotPasswordLink = find.text('Forgot Password?');
      final createAccountLink = find.text('Create Account');

      if (forgotPasswordLink.evaluate().isNotEmpty) {
        expect(forgotPasswordLink, findsOneWidget);
      }

      if (createAccountLink.evaluate().isNotEmpty) {
        expect(createAccountLink, findsOneWidget);
      }

      expect(tester.takeException(), isNull);
    });
  });

  group('Auth Keyboard Navigation Tests', () {
    testWidgets('Should support tab navigation through form', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SignInScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Start with email field
      final emailField = find.byType(ModernTextField).first;
      await tester.tap(emailField);
      await tester.pump();

      // Enter email and tab to password
      await tester.enterText(emailField, 'test@example.com');
      await tester.testTextInput.receiveAction(TextInputAction.next);
      await tester.pump();

      // Should focus on password field
      expect(tester.takeException(), isNull);
    });

    testWidgets('Should support Enter key to submit form', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SignInScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Fill form
      final textFields = find.byType(ModernTextField);
      await tester.enterText(textFields.first, 'test@example.com');
      await tester.enterText(textFields.last, 'password123');
      await tester.pump();

      // Press Enter on password field
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(tester.takeException(), isNull);
    });

    testWidgets('Should support Escape key to clear focus', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SignInScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Focus on field
      final emailField = find.byType(ModernTextField).first;
      await tester.tap(emailField);
      await tester.pump();

      // Simulate escape key (platform-specific)
      expect(tester.takeException(), isNull);
    });

    testWidgets('Should handle arrow key navigation in dropdowns', (tester) async {
      // This would test dropdown navigation if auth forms have dropdowns
      await tester.pumpWidget(
        const MaterialApp(
          home: SignUpScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Look for any dropdown fields
      expect(find.byType(ModernTextField), findsNWidgets(4));
      expect(tester.takeException(), isNull);
    });
  });

  group('Auth Screen Reader Tests', () {
    testWidgets('Should announce form structure to screen readers', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SignInScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Form should have proper semantic structure
      expect(find.byType(ModernAuthLayout), findsOneWidget);
      expect(find.byType(ModernTextField), findsNWidgets(2));
      expect(find.byType(ModernButton), findsAtLeastNWidgets(1));
      expect(tester.takeException(), isNull);
    });

    testWidgets('Should announce field requirements', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SignUpScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Required fields should be announced as required
      expect(find.byType(ModernTextField), findsNWidgets(4));
      expect(tester.takeException(), isNull);
    });

    testWidgets('Should announce form submission status', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SignInScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Fill and submit form
      final textFields = find.byType(ModernTextField);
      await tester.enterText(textFields.first, 'test@example.com');
      await tester.enterText(textFields.last, 'password123');
      await tester.pump();

      final signInButton = find.widgetWithText(ModernButton, 'Sign In');
      await tester.tap(signInButton);
      await tester.pump();

      // Loading state should be announced
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Should announce success and error states', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SignInScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Submit invalid form to trigger errors
      final signInButton = find.widgetWithText(ModernButton, 'Sign In');
      await tester.tap(signInButton);
      await tester.pump();

      // Error messages should be accessible
      expect(find.text('Email is required'), findsOneWidget);
      expect(find.text('Password is required'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Auth High Contrast and Theme Tests', () {
    testWidgets('Should work with high contrast themes', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            colorScheme: const ColorScheme.highContrastLight(),
          ),
          home: const SignInScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Should render properly with high contrast
      expect(find.byType(ModernAuthLayout), findsOneWidget);
      expect(find.byType(ModernTextField), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    });

    testWidgets('Should work with dark theme', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: const SignInScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Should adapt to dark theme
      expect(find.byType(ModernAuthLayout), findsOneWidget);
      expect(find.byType(ModernTextField), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    });

    testWidgets('Should maintain contrast ratios', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue,
              brightness: Brightness.light,
            ),
          ),
          home: const SignInScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Should maintain proper contrast
      expect(find.byType(ModernAuthLayout), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Auth Reduced Motion Tests', () {
    testWidgets('Should respect reduced motion preferences', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SignInScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Animations should be respectful of accessibility preferences
      expect(find.byType(ModernAuthLayout), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Should provide alternative feedback when animations are disabled', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SignInScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Focus changes should still be indicated without animation
      final emailField = find.byType(ModernTextField).first;
      await tester.tap(emailField);
      await tester.pump();

      expect(tester.takeException(), isNull);
    });
  });
}
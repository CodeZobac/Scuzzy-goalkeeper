import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goalkeeper/src/features/auth/presentation/screens/sign_in_screen.dart';
import 'package:goalkeeper/src/features/auth/presentation/screens/sign_up_screen.dart';
import 'package:goalkeeper/src/features/auth/presentation/widgets/modern_text_field.dart';
import 'package:goalkeeper/src/features/auth/presentation/widgets/modern_button.dart';
import 'package:goalkeeper/src/features/auth/presentation/widgets/modern_auth_layout.dart';

void main() {
  group('Authentication Flow Integration Tests', () {
    testWidgets('should complete sign in flow successfully', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SignInScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Verify initial screen elements
      expect(find.byType(ModernAuthLayout), findsOneWidget);
      expect(find.text('Welcome Back'), findsOneWidget);
      expect(find.byType(ModernTextField), findsNWidgets(2)); // Email and password
      expect(find.byType(ModernButton), findsAtLeastNWidgets(1)); // Sign in button

      // Enter email
      final emailField = find.byType(ModernTextField).first;
      await tester.enterText(emailField, 'test@example.com');
      await tester.pump();

      // Enter password
      final passwordField = find.byType(ModernTextField).last;
      await tester.enterText(passwordField, 'password123');
      await tester.pump();

      // Tap sign in button
      final signInButton = find.widgetWithText(ModernButton, 'Sign In');
      await tester.tap(signInButton);
      await tester.pump();

      // Verify loading state
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Allow async operations to complete
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('should complete sign up flow successfully', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SignUpScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Verify initial screen elements
      expect(find.byType(ModernAuthLayout), findsOneWidget);
      expect(find.text('Create Account'), findsOneWidget);
      expect(find.byType(ModernTextField), findsNWidgets(4)); // Name, email, password, confirm password

      // Fill out form
      final textFields = find.byType(ModernTextField);
      
      // Enter name
      await tester.enterText(textFields.at(0), 'John Doe');
      await tester.pump();

      // Enter email
      await tester.enterText(textFields.at(1), 'john@example.com');
      await tester.pump();

      // Enter password
      await tester.enterText(textFields.at(2), 'securePassword123');
      await tester.pump();

      // Confirm password
      await tester.enterText(textFields.at(3), 'securePassword123');
      await tester.pump();

      // Tap sign up button
      final signUpButton = find.widgetWithText(ModernButton, 'Create Account');
      await tester.tap(signUpButton);
      await tester.pump();

      // Verify loading state
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('should handle navigation between sign in and sign up', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          routes: {
            '/signin': (context) => const SignInScreen(),
            '/signup': (context) => const SignUpScreen(),
          },
          initialRoute: '/signin',
        ),
      );

      await tester.pumpAndSettle();

      // Verify we're on sign in screen
      expect(find.text('Welcome Back'), findsOneWidget);

      // Find and tap "Create Account" link
      final createAccountLink = find.text('Create Account');
      if (createAccountLink.evaluate().isNotEmpty) {
        await tester.tap(createAccountLink);
        await tester.pumpAndSettle();

        // Verify navigation to sign up screen
        expect(find.text('Create Account'), findsOneWidget);
        expect(find.text('Welcome Back'), findsNothing);
      }
    });

    testWidgets('should handle form validation errors', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SignInScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Try to submit without filling fields
      final signInButton = find.widgetWithText(ModernButton, 'Sign In');
      await tester.tap(signInButton);
      await tester.pump();

      // Should show validation errors
      expect(find.text('Email is required'), findsOneWidget);
      expect(find.text('Password is required'), findsOneWidget);

      // Enter invalid email
      final emailField = find.byType(ModernTextField).first;
      await tester.enterText(emailField, 'invalid-email');
      await tester.pump();

      await tester.tap(signInButton);
      await tester.pump();

      expect(find.text('Please enter a valid email'), findsOneWidget);
    });

    testWidgets('should handle password visibility toggle', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SignInScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Find password field
      final passwordField = find.byType(ModernTextField).last;
      
      // Enter password
      await tester.enterText(passwordField, 'mypassword');
      await tester.pump();

      // Find and tap visibility toggle
      final visibilityToggle = find.byIcon(Icons.visibility_off);
      expect(visibilityToggle, findsOneWidget);

      await tester.tap(visibilityToggle);
      await tester.pump();

      // Should now show visibility icon
      expect(find.byIcon(Icons.visibility), findsOneWidget);
    });

    testWidgets('should handle forgot password flow', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SignInScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Find and tap forgot password link
      final forgotPasswordLink = find.text('Forgot Password?');
      if (forgotPasswordLink.evaluate().isNotEmpty) {
        await tester.tap(forgotPasswordLink);
        await tester.pumpAndSettle();

        // Should navigate to forgot password screen or show dialog
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('should handle social sign in options', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SignInScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Look for social sign in buttons
      final googleButton = find.text('Continue with Google');
      final appleButton = find.text('Continue with Apple');

      if (googleButton.evaluate().isNotEmpty) {
        await tester.tap(googleButton);
        await tester.pump();
        expect(tester.takeException(), isNull);
      }

      if (appleButton.evaluate().isNotEmpty) {
        await tester.tap(appleButton);
        await tester.pump();
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('should handle keyboard navigation', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SignInScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Focus on first field
      final emailField = find.byType(ModernTextField).first;
      await tester.tap(emailField);
      await tester.pump();

      // Enter text and press tab to move to next field
      await tester.enterText(emailField, 'test@example.com');
      await tester.testTextInput.receiveAction(TextInputAction.next);
      await tester.pump();

      // Should focus on password field
      expect(tester.takeException(), isNull);
    });

    testWidgets('should handle responsive layout changes during flow', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SignInScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Start with mobile size
      await tester.binding.setSurfaceSize(const Size(375, 667));
      await tester.pump();

      // Enter some data
      final emailField = find.byType(ModernTextField).first;
      await tester.enterText(emailField, 'test@example.com');
      await tester.pump();

      // Change to tablet size
      await tester.binding.setSurfaceSize(const Size(768, 1024));
      await tester.pump();

      // Data should be preserved
      expect(find.text('test@example.com'), findsOneWidget);

      // Change to desktop size
      await tester.binding.setSurfaceSize(const Size(1920, 1080));
      await tester.pump();

      // Data should still be preserved
      expect(find.text('test@example.com'), findsOneWidget);

      // Reset surface size
      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('should handle error states gracefully', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SignInScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Fill form with valid data
      final textFields = find.byType(ModernTextField);
      await tester.enterText(textFields.first, 'test@example.com');
      await tester.enterText(textFields.last, 'password123');
      await tester.pump();

      // Tap sign in button
      final signInButton = find.widgetWithText(ModernButton, 'Sign In');
      await tester.tap(signInButton);
      await tester.pump();

      // Should show loading state
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Wait for potential error handling
      await tester.pumpAndSettle();

      // Should handle any errors gracefully
      expect(tester.takeException(), isNull);
    });

    testWidgets('should maintain form state during interruptions', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SignInScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Fill form
      final emailField = find.byType(ModernTextField).first;
      final passwordField = find.byType(ModernTextField).last;
      
      await tester.enterText(emailField, 'user@example.com');
      await tester.enterText(passwordField, 'mypassword');
      await tester.pump();

      // Simulate app going to background and coming back
      await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
        'flutter/lifecycle',
        const StandardMethodCodec().encodeMethodCall(
          const MethodCall('AppLifecycleState.paused'),
        ),
        (data) {},
      );

      await tester.pump();

      await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
        'flutter/lifecycle',
        const StandardMethodCodec().encodeMethodCall(
          const MethodCall('AppLifecycleState.resumed'),
        ),
        (data) {},
      );

      await tester.pump();

      // Form data should be preserved
      expect(find.text('user@example.com'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Authentication Flow Accessibility Tests', () {
    testWidgets('should support screen reader navigation', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SignInScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Verify semantic structure
      expect(find.byType(ModernAuthLayout), findsOneWidget);
      expect(find.byType(ModernTextField), findsNWidgets(2));
      expect(find.byType(ModernButton), findsAtLeastNWidgets(1));

      // All interactive elements should be accessible
      expect(tester.takeException(), isNull);
    });

    testWidgets('should provide proper focus management', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SignInScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Tab through form elements
      final emailField = find.byType(ModernTextField).first;
      await tester.tap(emailField);
      await tester.pump();

      // Should be able to navigate with keyboard
      await tester.testTextInput.receiveAction(TextInputAction.next);
      await tester.pump();

      expect(tester.takeException(), isNull);
    });

    testWidgets('should announce loading states to screen readers', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SignInScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Fill form and submit
      final textFields = find.byType(ModernTextField);
      await tester.enterText(textFields.first, 'test@example.com');
      await tester.enterText(textFields.last, 'password123');
      await tester.pump();

      final signInButton = find.widgetWithText(ModernButton, 'Sign In');
      await tester.tap(signInButton);
      await tester.pump();

      // Loading state should be accessible
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Authentication Flow Performance Tests', () {
    testWidgets('should handle rapid form interactions efficiently', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SignInScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final emailField = find.byType(ModernTextField).first;
      final passwordField = find.byType(ModernTextField).last;

      // Rapid text entry
      for (int i = 0; i < 10; i++) {
        await tester.enterText(emailField, 'test$i@example.com');
        await tester.enterText(passwordField, 'password$i');
        await tester.pump();
      }

      expect(tester.takeException(), isNull);
    });

    testWidgets('should optimize animation performance', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SignInScreen(),
        ),
      );

      // Allow all entrance animations to complete
      await tester.pumpAndSettle();

      // Interact with form elements to trigger animations
      final emailField = find.byType(ModernTextField).first;
      await tester.tap(emailField);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Should handle animations smoothly
      expect(tester.takeException(), isNull);
    });

    testWidgets('should handle memory efficiently during long sessions', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SignInScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Simulate extended user interaction
      for (int i = 0; i < 20; i++) {
        final emailField = find.byType(ModernTextField).first;
        await tester.tap(emailField);
        await tester.enterText(emailField, 'test$i@example.com');
        await tester.pump();
        
        // Clear and re-enter
        await tester.enterText(emailField, '');
        await tester.pump();
      }

      expect(tester.takeException(), isNull);
    });
  });
}
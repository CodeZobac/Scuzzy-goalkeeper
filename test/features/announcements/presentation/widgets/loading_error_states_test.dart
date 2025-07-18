import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goalkeeper/src/features/announcements/presentation/widgets/loading_state_widget.dart';
import 'package:goalkeeper/src/features/announcements/presentation/widgets/error_state_widget.dart';

void main() {
  group('LoadingStateWidget Tests', () {
    testWidgets('displays loading indicator with message', (WidgetTester tester) async {
      const testMessage = 'Loading test data...';
      
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadingStateWidget(
              message: testMessage,
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text(testMessage), findsOneWidget);
    });

    testWidgets('displays loading indicator without message', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadingStateWidget(),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(Text), findsNothing);
    });

    testWidgets('displays small loading indicator when isSmall is true', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadingStateWidget(
              isSmall: true,
              message: 'Loading...',
            ),
          ),
        ),
      );

      final progressIndicator = tester.widget<SizedBox>(
        find.ancestor(
          of: find.byType(CircularProgressIndicator),
          matching: find.byType(SizedBox),
        ).first,
      );

      expect(progressIndicator.width, equals(20));
      expect(progressIndicator.height, equals(20));
    });
  });

  group('InlineLoadingWidget Tests', () {
    testWidgets('displays inline loading with message', (WidgetTester tester) async {
      const testMessage = 'Processing...';
      
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InlineLoadingWidget(
              message: testMessage,
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text(testMessage), findsOneWidget);
      expect(find.byType(Row), findsOneWidget);
    });
  });

  group('ErrorStateWidget Tests', () {
    testWidgets('displays error message with retry button', (WidgetTester tester) async {
      const testError = 'Network connection failed';
      bool retryPressed = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorStateWidget(
              errorMessage: testError,
              onRetry: () {
                retryPressed = true;
              },
            ),
          ),
        ),
      );

      expect(find.text(testError), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);

      await tester.tap(find.text('Try Again'));
      expect(retryPressed, isTrue);
    });

    testWidgets('displays network error with appropriate icon and title', (WidgetTester tester) async {
      const networkError = 'Network connection error. Please check your internet connection.';
      
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ErrorStateWidget(
              errorMessage: networkError,
            ),
          ),
        ),
      );

      expect(find.text('Connection Problem'), findsOneWidget);
      expect(find.byIcon(Icons.wifi_off), findsOneWidget);
    });

    testWidgets('displays timeout error with appropriate icon and title', (WidgetTester tester) async {
      const timeoutError = 'timeout occurred';
      
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ErrorStateWidget(
              errorMessage: timeoutError,
            ),
          ),
        ),
      );

      expect(find.text('Request Timed Out'), findsOneWidget);
      expect(find.byIcon(Icons.access_time), findsOneWidget);
    });

    testWidgets('displays loading state when retrying', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorStateWidget(
              errorMessage: 'Test error',
              onRetry: () {},
              isRetrying: true,
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Try Again'), findsNothing);
    });

    testWidgets('displays dismiss button when onDismiss is provided', (WidgetTester tester) async {
      bool dismissPressed = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorStateWidget(
              errorMessage: 'Test error',
              onRetry: () {},
              onDismiss: () {
                dismissPressed = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('Dismiss'), findsOneWidget);
      
      await tester.tap(find.text('Dismiss'));
      expect(dismissPressed, isTrue);
    });
  });

  group('InlineErrorWidget Tests', () {
    testWidgets('displays inline error with retry button', (WidgetTester tester) async {
      const testError = 'Failed to load data';
      bool retryPressed = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InlineErrorWidget(
              errorMessage: testError,
              onRetry: () {
                retryPressed = true;
              },
            ),
          ),
        ),
      );

      expect(find.text(testError), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);

      await tester.tap(find.text('Retry'));
      expect(retryPressed, isTrue);
    });

    testWidgets('displays loading state when retrying', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InlineErrorWidget(
              errorMessage: 'Test error',
              onRetry: () {},
              isRetrying: true,
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Retry'), findsNothing);
    });
  });

  group('ShimmerLoadingWidget Tests', () {
    testWidgets('displays shimmer animation', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ShimmerLoadingWidget(
              width: 200,
              height: 50,
            ),
          ),
        ),
      );

      expect(find.byType(ShimmerLoadingWidget), findsOneWidget);
      
      // Verify the container has the expected dimensions
      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(ShimmerLoadingWidget),
          matching: find.byType(Container),
        ),
      );
      
      expect(container.constraints?.maxWidth, equals(200));
    });
  });
}
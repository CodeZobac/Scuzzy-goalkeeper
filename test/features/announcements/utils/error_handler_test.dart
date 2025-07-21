import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goalkeeper/src/features/announcements/utils/error_handler.dart';

void main() {
  group('AnnouncementErrorHandler Tests', () {
    group('getErrorMessage', () {
      test('handles Exception with custom message', () {
        final exception = Exception('Custom error message');
        final result = AnnouncementErrorHandler.getErrorMessage(exception);
        expect(result, equals('Custom error message'));
      });

      test('handles network errors', () {
        final error = 'Network connection failed';
        final result = AnnouncementErrorHandler.getErrorMessage(error);
        expect(result, equals('Network connection error. Please check your internet connection.'));
      });

      test('handles timeout errors', () {
        final error = 'Request timeout occurred';
        final result = AnnouncementErrorHandler.getErrorMessage(error);
        expect(result, equals('Request timed out. Please try again.'));
      });

      test('handles unauthorized errors', () {
        final error = 'Unauthorized access - 401';
        final result = AnnouncementErrorHandler.getErrorMessage(error);
        expect(result, equals('Authentication required. Please log in again.'));
      });

      test('handles forbidden errors', () {
        final error = 'Forbidden - 403';
        final result = AnnouncementErrorHandler.getErrorMessage(error);
        expect(result, equals('You don\'t have permission to perform this action.'));
      });

      test('handles not found errors', () {
        final error = 'Resource not found - 404';
        final result = AnnouncementErrorHandler.getErrorMessage(error);
        expect(result, equals('The requested resource was not found.'));
      });

      test('handles server errors', () {
        final error = 'Internal server error - 500';
        final result = AnnouncementErrorHandler.getErrorMessage(error);
        expect(result, equals('Server error. Please try again later.'));
      });

      test('handles capacity errors', () {
        final error = 'Event is at full capacity';
        final result = AnnouncementErrorHandler.getErrorMessage(error);
        expect(result, equals('This event is at full capacity.'));
      });

      test('handles participant errors', () {
        final error = 'User already joined this event';
        final result = AnnouncementErrorHandler.getErrorMessage(error);
        expect(result, equals('You are already participating in this event.'));
      });

      test('handles unknown errors', () {
        final error = 'Some unknown error';
        final result = AnnouncementErrorHandler.getErrorMessage(error);
        expect(result, equals('An unexpected error occurred. Please try again.'));
      });
    });

    group('handleAsyncOperation', () {
      testWidgets('handles successful operation', (WidgetTester tester) async {
        bool loadingStarted = false;
        bool loadingEnded = false;
        
        final result = await AnnouncementErrorHandler.handleAsyncOperation<String>(
          () async => 'Success',
          onLoadingStart: () => loadingStarted = true,
          onLoadingEnd: () => loadingEnded = true,
        );

        expect(result, equals('Success'));
        expect(loadingStarted, isTrue);
        expect(loadingEnded, isTrue);
      });

      testWidgets('handles failed operation', (WidgetTester tester) async {
        bool loadingStarted = false;
        bool loadingEnded = false;
        
        final result = await AnnouncementErrorHandler.handleAsyncOperation<String>(
          () async => throw Exception('Test error'),
          onLoadingStart: () => loadingStarted = true,
          onLoadingEnd: () => loadingEnded = true,
        );

        expect(result, isNull);
        expect(loadingStarted, isTrue);
        expect(loadingEnded, isTrue);
      });
    });

    group('handleAsyncOperationWithRetry', () {
      testWidgets('retries failed operations', (WidgetTester tester) async {
        int attemptCount = 0;
        bool loadingStarted = false;
        bool loadingEnded = false;
        
        final result = await AnnouncementErrorHandler.handleAsyncOperationWithRetry<String>(
          () async {
            attemptCount++;
            if (attemptCount < 3) {
              throw Exception('Temporary failure');
            }
            return 'Success after retries';
          },
          onLoadingStart: () => loadingStarted = true,
          onLoadingEnd: () => loadingEnded = true,
          maxRetries: 2,
          initialDelay: const Duration(milliseconds: 1), // Very short delay for testing
        );

        expect(result, equals('Success after retries'));
        expect(attemptCount, equals(3));
        expect(loadingStarted, isTrue);
        expect(loadingEnded, isTrue);
      });

      testWidgets('fails after max retries', (WidgetTester tester) async {
        int attemptCount = 0;
        bool loadingStarted = false;
        bool loadingEnded = false;
        
        final result = await AnnouncementErrorHandler.handleAsyncOperationWithRetry<String>(
          () async {
            attemptCount++;
            throw Exception('Persistent failure');
          },
          onLoadingStart: () => loadingStarted = true,
          onLoadingEnd: () => loadingEnded = true,
          maxRetries: 2,
          initialDelay: const Duration(milliseconds: 1),
        );

        expect(result, isNull);
        expect(attemptCount, equals(3)); // Initial attempt + 2 retries
        expect(loadingStarted, isTrue);
        expect(loadingEnded, isTrue);
      });

      testWidgets('handles timeout', (WidgetTester tester) async {
        bool loadingStarted = false;
        bool loadingEnded = false;
        
        final result = await AnnouncementErrorHandler.handleAsyncOperationWithRetry<String>(
          () async {
            await Future.delayed(const Duration(milliseconds: 200));
            return 'Should timeout';
          },
          onLoadingStart: () => loadingStarted = true,
          onLoadingEnd: () => loadingEnded = true,
          timeout: const Duration(milliseconds: 50),
          maxRetries: 1,
        );

        expect(result, isNull);
        expect(loadingStarted, isTrue);
        expect(loadingEnded, isTrue);
      });
    });

    group('handleNetworkOperation', () {
      testWidgets('uses network-specific retry settings', (WidgetTester tester) async {
        int attemptCount = 0;
        bool loadingStarted = false;
        bool loadingEnded = false;
        
        final result = await AnnouncementErrorHandler.handleNetworkOperation<String>(
          () async {
            attemptCount++;
            if (attemptCount < 2) {
              throw Exception('Network error');
            }
            return 'Network success';
          },
          onLoadingStart: () => loadingStarted = true,
          onLoadingEnd: () => loadingEnded = true,
        );

        expect(result, equals('Network success'));
        expect(attemptCount, equals(2));
        expect(loadingStarted, isTrue);
        expect(loadingEnded, isTrue);
      });
    });

    group('Snackbar methods', () {
      testWidgets('showErrorSnackBar displays error message', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () {
                      AnnouncementErrorHandler.showErrorSnackBar(context, 'Test error');
                    },
                    child: const Text('Show Error'),
                  );
                },
              ),
            ),
          ),
        );

        await tester.tap(find.text('Show Error'));
        await tester.pump();

        expect(find.text('Test error'), findsOneWidget);
        expect(find.byType(SnackBar), findsOneWidget);
      });

      testWidgets('showSuccessSnackBar displays success message', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () {
                      AnnouncementErrorHandler.showSuccessSnackBar(context, 'Success!');
                    },
                    child: const Text('Show Success'),
                  );
                },
              ),
            ),
          ),
        );

        await tester.tap(find.text('Show Success'));
        await tester.pump();

        expect(find.text('Success!'), findsOneWidget);
        expect(find.byType(SnackBar), findsOneWidget);
      });

      testWidgets('showInfoSnackBar displays info message', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () {
                      AnnouncementErrorHandler.showInfoSnackBar(context, 'Info message');
                    },
                    child: const Text('Show Info'),
                  );
                },
              ),
            ),
          ),
        );

        await tester.tap(find.text('Show Info'));
        await tester.pump();

        expect(find.text('Info message'), findsOneWidget);
        expect(find.byType(SnackBar), findsOneWidget);
      });
    });

    group('showLoadingDialog', () {
      testWidgets('displays loading dialog and handles success', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () async {
                      final result = await AnnouncementErrorHandler.showLoadingDialog<String>(
                        context,
                        () async {
                          await Future.delayed(const Duration(milliseconds: 100));
                          return 'Dialog success';
                        },
                        loadingMessage: 'Processing...',
                      );
                      
                      if (result != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Result: $result')),
                        );
                      }
                    },
                    child: const Text('Show Dialog'),
                  );
                },
              ),
            ),
          ),
        );

        await tester.tap(find.text('Show Dialog'));
        await tester.pump();

        // Verify dialog is shown
        expect(find.text('Processing...'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        // Wait for operation to complete
        await tester.pump(const Duration(milliseconds: 150));

        // Verify result is shown
        expect(find.text('Result: Dialog success'), findsOneWidget);
      });

      testWidgets('displays loading dialog and handles error', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () async {
                      await AnnouncementErrorHandler.showLoadingDialog<String>(
                        context,
                        () async {
                          await Future.delayed(const Duration(milliseconds: 50));
                          throw Exception('Dialog error');
                        },
                        loadingMessage: 'Processing...',
                      );
                    },
                    child: const Text('Show Dialog'),
                  );
                },
              ),
            ),
          ),
        );

        await tester.tap(find.text('Show Dialog'));
        await tester.pump();

        // Verify dialog is shown
        expect(find.text('Processing...'), findsOneWidget);

        // Wait for operation to complete
        await tester.pump(const Duration(milliseconds: 100));

        // Verify error is shown
        expect(find.text('Dialog error'), findsOneWidget);
      });
    });
  });
}
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goalkeeper/src/features/auth/presentation/widgets/responsive_auth_layout.dart';

void main() {
  group('ResponsiveAuthLayout Tests', () {
    testWidgets('should create layout without errors', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ResponsiveAuthLayout(
            title: 'Test Title',
            subtitle: 'Test Subtitle',
            child: const Text('Test Content'),
          ),
        ),
      );

      expect(find.byType(ResponsiveAuthLayout), findsOneWidget);
      expect(find.text('Test Title'), findsOneWidget);
      expect(find.text('Test Subtitle'), findsOneWidget);
      expect(find.text('Test Content'), findsOneWidget);
    });

    testWidgets('should adapt to mobile screen size', (tester) async {
      await tester.binding.setSurfaceSize(const Size(375, 667)); // iPhone size
      
      await tester.pumpWidget(
        MaterialApp(
          home: ResponsiveAuthLayout(
            title: 'Mobile Test',
            subtitle: 'Mobile subtitle',
            child: const Text('Mobile Content'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Mobile Test'), findsOneWidget);
      expect(find.text('Mobile Content'), findsOneWidget);
      
      // Reset surface size
      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('should adapt to tablet screen size', (tester) async {
      await tester.binding.setSurfaceSize(const Size(768, 1024)); // iPad size
      
      await tester.pumpWidget(
        MaterialApp(
          home: ResponsiveAuthLayout(
            title: 'Tablet Test',
            subtitle: 'Tablet subtitle',
            child: const Text('Tablet Content'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Tablet Test'), findsOneWidget);
      expect(find.text('Tablet Content'), findsOneWidget);
      
      // Reset surface size
      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('should adapt to desktop screen size', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1920, 1080)); // Desktop size
      
      await tester.pumpWidget(
        MaterialApp(
          home: ResponsiveAuthLayout(
            title: 'Desktop Test',
            subtitle: 'Desktop subtitle',
            child: const Text('Desktop Content'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Desktop Test'), findsOneWidget);
      expect(find.text('Desktop Content'), findsOneWidget);
      
      // Reset surface size
      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('should show back button when requested', (tester) async {
      bool backPressed = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: ResponsiveAuthLayout(
            title: 'Back Button Test',
            subtitle: 'Test subtitle',
            showBackButton: true,
            onBackPressed: () => backPressed = true,
            child: const Text('Content'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.arrow_back_ios_new), findsOneWidget);
      
      await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
      expect(backPressed, isTrue);
    });

    testWidgets('should handle keyboard visibility', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ResponsiveAuthLayout(
            title: 'Keyboard Test',
            subtitle: 'Test subtitle',
            child: const TextField(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap on text field to show keyboard
      await tester.tap(find.byType(TextField));
      await tester.pump();

      expect(tester.takeException(), isNull);
    });

    testWidgets('should animate header on scroll', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ResponsiveAuthLayout(
            title: 'Scroll Test',
            subtitle: 'Test subtitle',
            child: SizedBox(
              height: 1000,
              child: ListView.builder(
                itemCount: 50,
                itemBuilder: (context, index) => ListTile(
                  title: Text('Item $index'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Scroll down
      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(tester.takeException(), isNull);
    });

    testWidgets('should handle safe area properly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              padding: EdgeInsets.only(top: 44, bottom: 34), // iPhone X notch
            ),
            child: ResponsiveAuthLayout(
              title: 'Safe Area Test',
              subtitle: 'Test subtitle',
              child: const Text('Content'),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Safe Area Test'), findsOneWidget);
      expect(find.text('Content'), findsOneWidget);
    });

    testWidgets('should handle different orientations', (tester) async {
      // Portrait
      await tester.binding.setSurfaceSize(const Size(375, 667));
      
      await tester.pumpWidget(
        MaterialApp(
          home: ResponsiveAuthLayout(
            title: 'Orientation Test',
            subtitle: 'Portrait',
            child: const Text('Portrait Content'),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Portrait'), findsOneWidget);

      // Landscape
      await tester.binding.setSurfaceSize(const Size(667, 375));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Portrait'), findsOneWidget);
      
      // Reset surface size
      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('should show loading overlay when specified', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ResponsiveAuthLayout(
            title: 'Loading Test',
            subtitle: 'Test subtitle',
            showLoadingOverlay: true,
            child: const Text('Content'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should handle custom background', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ResponsiveAuthLayout(
            title: 'Background Test',
            subtitle: 'Test subtitle',
            backgroundColor: Colors.red,
            child: const Text('Content'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Background Test'), findsOneWidget);
    });
  });

  group('ResponsiveAuthLayout Animation Tests', () {
    testWidgets('should animate header entrance', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ResponsiveAuthLayout(
            title: 'Animation Test',
            subtitle: 'Test subtitle',
            child: const Text('Content'),
          ),
        ),
      );

      // Initial state
      await tester.pump();
      
      // Allow entrance animation to complete
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();

      expect(find.text('Animation Test'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('should animate content entrance', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ResponsiveAuthLayout(
            title: 'Content Animation',
            subtitle: 'Test subtitle',
            child: const Text('Animated Content'),
          ),
        ),
      );

      // Allow all animations to complete
      await tester.pumpAndSettle();

      expect(find.text('Animated Content'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('should handle animation disposal', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ResponsiveAuthLayout(
            title: 'Disposal Test',
            subtitle: 'Test subtitle',
            child: const Text('Content'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Remove widget to trigger disposal
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Text('New Content'),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });

  group('ResponsiveAuthLayout Accessibility Tests', () {
    testWidgets('should have proper semantics', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ResponsiveAuthLayout(
            title: 'Accessible Layout',
            subtitle: 'Accessible subtitle',
            child: const Text('Accessible content'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Accessible Layout'), findsOneWidget);
      expect(find.text('Accessible subtitle'), findsOneWidget);
      expect(find.text('Accessible content'), findsOneWidget);
    });

    testWidgets('should support screen readers', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ResponsiveAuthLayout(
            title: 'Screen Reader Test',
            subtitle: 'Test subtitle',
            semanticsLabel: 'Authentication screen',
            child: const Text('Content'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Screen Reader Test'), findsOneWidget);
    });

    testWidgets('should handle focus properly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ResponsiveAuthLayout(
            title: 'Focus Test',
            subtitle: 'Test subtitle',
            child: const TextField(
              decoration: InputDecoration(hintText: 'Focusable field'),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap to focus
      await tester.tap(find.byType(TextField));
      await tester.pump();

      expect(tester.takeException(), isNull);
    });
  });

  group('ResponsiveAuthLayout Performance Tests', () {
    testWidgets('should handle rapid screen size changes', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ResponsiveAuthLayout(
            title: 'Performance Test',
            subtitle: 'Test subtitle',
            child: const Text('Content'),
          ),
        ),
      );

      // Rapid size changes
      final sizes = [
        const Size(375, 667),  // Mobile
        const Size(768, 1024), // Tablet
        const Size(1920, 1080), // Desktop
        const Size(320, 568),  // Small mobile
      ];

      for (final size in sizes) {
        await tester.binding.setSurfaceSize(size);
        await tester.pump();
      }

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      
      // Reset surface size
      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('should optimize rebuilds', (tester) async {
      int buildCount = 0;
      
      await tester.pumpWidget(
        MaterialApp(
          home: ResponsiveAuthLayout(
            title: 'Rebuild Test',
            subtitle: 'Test subtitle',
            child: Builder(
              builder: (context) {
                buildCount++;
                return const Text('Content');
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      final initialBuildCount = buildCount;

      // Trigger a rebuild by changing screen size
      await tester.binding.setSurfaceSize(const Size(800, 600));
      await tester.pump();

      // Should not cause excessive rebuilds
      expect(buildCount - initialBuildCount, lessThan(5));
      
      // Reset surface size
      await tester.binding.setSurfaceSize(null);
    });
  });
}
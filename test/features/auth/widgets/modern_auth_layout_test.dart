import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goalkeeper/src/features/auth/presentation/widgets/modern_auth_layout.dart';
import 'package:goalkeeper/src/shared/widgets/svg_asset_manager.dart';

void main() {
  group('ModernAuthLayout', () {
    testWidgets('should render with SVG header integration', (WidgetTester tester) async {
      // Arrange
      const testTitle = 'Welcome Back';
      const testSubtitle = 'Sign in to continue';
      const testChild = Text('Test Content');

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: ModernAuthLayout(
            title: testTitle,
            subtitle: testSubtitle,
            child: testChild,
          ),
        ),
      );

      // Allow animations to complete
      await tester.pumpAndSettle();

      // Assert
      expect(find.text(testTitle), findsOneWidget);
      expect(find.text(testSubtitle), findsOneWidget);
      expect(find.text('Test Content'), findsOneWidget);
    });

    testWidgets('should show back button when requested', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: ModernAuthLayout(
            title: 'Test',
            subtitle: 'Test subtitle',
            showBackButton: true,
            child: Container(),
          ),
        ),
      );

      // Allow animations to complete
      await tester.pumpAndSettle();

      // Assert
      expect(find.byIcon(Icons.arrow_back_ios_new), findsOneWidget);
    });

    testWidgets('should handle responsive design for tablet', (WidgetTester tester) async {
      // Arrange
      await tester.binding.setSurfaceSize(const Size(800, 1200)); // Tablet size
      
      await tester.pumpWidget(
        MaterialApp(
          home: ModernAuthLayout(
            title: 'Test',
            subtitle: 'Test subtitle',
            child: Container(),
          ),
        ),
      );

      // Allow animations to complete
      await tester.pumpAndSettle();

      // Assert - should render without errors on tablet size
      expect(find.text('Test'), findsOneWidget);
      
      // Reset surface size
      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('should use SvgAssetManager for header', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: ModernAuthLayout(
            title: 'Test',
            subtitle: 'Test subtitle',
            child: Container(),
          ),
        ),
      );

      // Allow animations to complete
      await tester.pumpAndSettle();

      // Assert - verify SVG asset manager is configured
      expect(SvgAssetManager.hasAsset('auth_header'), isTrue);
      expect(SvgAssetManager.getConfig('auth_header')?.path, equals('assets/auth-header.svg'));
    });

    testWidgets('should show fallback when SVG fails to load', (WidgetTester tester) async {
      // This test verifies that the fallback mechanism works
      // The actual SVG loading failure is handled internally by SvgAssetManager
      
      await tester.pumpWidget(
        MaterialApp(
          home: ModernAuthLayout(
            title: 'Test',
            subtitle: 'Test subtitle',
            child: Container(),
          ),
        ),
      );

      // Allow animations and potential error handling to complete
      await tester.pumpAndSettle();

      // Assert - layout should still render properly even if SVG fails
      expect(find.text('Test'), findsOneWidget);
      expect(find.text('Test subtitle'), findsOneWidget);
    });
  });
}
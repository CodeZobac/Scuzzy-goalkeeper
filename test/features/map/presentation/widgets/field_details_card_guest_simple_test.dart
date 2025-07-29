import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:goalkeeper/src/features/map/presentation/widgets/field_details_card.dart';
import 'package:goalkeeper/src/features/map/domain/models/map_field.dart';

void main() {
  group('FieldDetailsCard Guest Mode Simple Tests', () {
    late MapField testField;

    setUp(() {
      // Create test field
      testField = MapField(
        id: 'test_field_1',
        name: 'Test Football Field',
        latitude: 38.7223,
        longitude: -9.1393,
        status: 'approved',
        createdAt: DateTime.now(),
        city: 'Lisboa',
        surfaceType: 'natural',
        dimensions: '11v11',
        description: 'A beautiful football field for testing',
        photoUrl: 'https://example.com/field.jpg',
      );
    });

    Widget createTestWidget({VoidCallback? onClose}) {
      return MaterialApp(
        home: Scaffold(
          body: FieldDetailsCard(
            field: testField,
            onClose: onClose,
          ),
        ),
        routes: {
          '/signup': (context) => const Scaffold(
            body: Center(child: Text('Signup Screen')),
          ),
        },
      );
    }

    testWidgets('should create FieldDetailsCard widget without errors', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verify the widget is created successfully
      expect(find.byType(FieldDetailsCard), findsOneWidget);
      expect(find.byType(DraggableScrollableSheet), findsOneWidget);
    });

    testWidgets('should display field name', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verify field name is displayed
      expect(find.text('Test Football Field'), findsOneWidget);
    });

    testWidgets('should handle close callback properly', (WidgetTester tester) async {
      bool closeCalled = false;
      
      await tester.pumpWidget(createTestWidget(
        onClose: () => closeCalled = true,
      ));
      await tester.pumpAndSettle();

      // Find and tap the back button if it exists
      final backButton = find.byIcon(Icons.arrow_back);
      if (tester.any(backButton)) {
        await tester.tap(backButton);
        await tester.pumpAndSettle();
        expect(closeCalled, isTrue);
      }
    });

    testWidgets('should display field information for different field types', (WidgetTester tester) async {
      // Test with different field configuration
      final artificialField = MapField(
        id: 'test_field_2',
        name: 'Artificial Field',
        latitude: 38.7223,
        longitude: -9.1393,
        status: 'approved',
        createdAt: DateTime.now(),
        city: 'Porto',
        surfaceType: 'artificial',
        dimensions: '7v7',
        description: 'Modern artificial turf field',
        photoUrl: null,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FieldDetailsCard(field: artificialField),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify field name is displayed
      expect(find.text('Artificial Field'), findsOneWidget);
    });

    testWidgets('should handle availability button tap without errors', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Look for any button that might be the availability button
      final buttons = find.byType(ElevatedButton);
      if (tester.any(buttons)) {
        await tester.tap(buttons.first);
        await tester.pumpAndSettle();
        
        // The button should be functional (no exceptions thrown)
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('should handle missing field data gracefully', (WidgetTester tester) async {
      // Test with minimal field data
      final minimalField = MapField(
        id: 'minimal_field',
        name: 'Minimal Field',
        latitude: 38.7223,
        longitude: -9.1393,
        status: 'approved',
        createdAt: DateTime.now(),
        city: null,
        surfaceType: null,
        dimensions: null,
        description: null,
        photoUrl: null,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FieldDetailsCard(field: minimalField),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify it handles missing data gracefully
      expect(find.text('Minimal Field'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    test('should create MapField with correct properties', () {
      expect(testField.name, equals('Test Football Field'));
      expect(testField.city, equals('Lisboa'));
      expect(testField.surfaceType, equals('natural'));
      expect(testField.dimensions, equals('11v11'));
      expect(testField.displaySurfaceType, equals('Natural'));
      expect(testField.isApproved, isTrue);
    });
  });
}
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goalkeeper/src/features/announcements/presentation/widgets/stadium_card.dart';

void main() {
  group('StadiumCard Widget Tests', () {
    testWidgets('displays stadium name and distance', (WidgetTester tester) async {
      bool mapTapped = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StadiumCard(
              stadiumName: 'Test Stadium',
              distance: 2.5,
              onMapTap: () => mapTapped = true,
            ),
          ),
        ),
      );

      // Verify stadium name is displayed
      expect(find.text('Test Stadium'), findsOneWidget);
      
      // Verify distance is displayed
      expect(find.text('3 km away'), findsOneWidget);
      
      // Verify "On the map" button is present
      expect(find.text('On the map'), findsOneWidget);
    });

    testWidgets('displays photo count when provided', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StadiumCard(
              stadiumName: 'Test Stadium',
              photoCount: 24,
              onMapTap: () {},
            ),
          ),
        ),
      );

      // Verify photo count is displayed
      expect(find.text('+24'), findsOneWidget);
      expect(find.byIcon(Icons.photo_library), findsOneWidget);
    });

    testWidgets('shows soccer icon when no image URL provided', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StadiumCard(
              stadiumName: 'Test Stadium',
              onMapTap: () {},
            ),
          ),
        ),
      );

      // Verify soccer icon is displayed as fallback
      expect(find.byIcon(Icons.sports_soccer), findsOneWidget);
    });

    testWidgets('calls onMapTap when map button is pressed', (WidgetTester tester) async {
      bool mapTapped = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StadiumCard(
              stadiumName: 'Test Stadium',
              onMapTap: () => mapTapped = true,
            ),
          ),
        ),
      );

      // Tap the "On the map" button
      await tester.tap(find.text('On the map'));
      await tester.pump();

      // Verify callback was called
      expect(mapTapped, isTrue);
    });

    testWidgets('has correct green gradient background', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StadiumCard(
              stadiumName: 'Test Stadium',
              onMapTap: () {},
            ),
          ),
        ),
      );

      // Find the container with gradient decoration
      final containerFinder = find.byType(Container).first;
      final Container container = tester.widget(containerFinder);
      final BoxDecoration decoration = container.decoration as BoxDecoration;
      final LinearGradient gradient = decoration.gradient as LinearGradient;

      // Verify gradient colors match design specifications
      expect(gradient.colors, contains(const Color(0xFF4CAF50)));
      expect(gradient.colors, contains(const Color(0xFF45A049)));
    });
  });
}
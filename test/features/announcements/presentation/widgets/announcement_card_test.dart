import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goalkeeper/src/features/announcements/data/models/announcement.dart';
import 'package:goalkeeper/src/features/announcements/presentation/widgets/announcement_card.dart';

void main() {
  group('AnnouncementCard', () {
    late Announcement testAnnouncement;

    setUp(() {
      testAnnouncement = Announcement(
        id: 1,
        title: 'Friday football with friends',
        description: 'Join us for a fun football match this Friday evening!',
        date: DateTime(2024, 4, 1),
        time: const TimeOfDay(hour: 18, minute: 30),
        price: 25.0,
        stadium: 'Minsk City Stadium',
        createdAt: DateTime.now(),
        organizerName: 'Alex Pesenka',
        organizerRating: 4.5,
        distanceKm: 2.0,
        participantCount: 11,
        maxParticipants: 22,
      );
    });

    testWidgets('displays announcement information correctly', (WidgetTester tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnnouncementCard(
              announcement: testAnnouncement,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      // Verify stadium name is displayed
      expect(find.text('Minsk City Stadium'), findsOneWidget);
      
      // Verify distance is displayed
      expect(find.text('2.0 km away'), findsOneWidget);
      
      // Verify description is displayed
      expect(find.text('Join us for a fun football match this Friday evening!'), findsOneWidget);
      
      // Verify organizer name is displayed
      expect(find.text('Alex Pesenka'), findsOneWidget);
      
      // Verify participant count indicator is displayed
      expect(find.text('+11'), findsOneWidget);
      
      // Verify Solo badge is displayed
      expect(find.text('Solo'), findsOneWidget);

      // Test tap functionality
      await tester.tap(find.byType(AnnouncementCard));
      expect(tapped, isTrue);
    });

    testWidgets('handles missing optional fields gracefully', (WidgetTester tester) async {
      final minimalAnnouncement = Announcement(
        id: 2,
        title: 'Basic announcement',
        date: DateTime(2024, 4, 2),
        time: const TimeOfDay(hour: 20, minute: 0),
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnnouncementCard(
              announcement: minimalAnnouncement,
              onTap: () {},
            ),
          ),
        ),
      );

      // Should display default values
      expect(find.text('Organizer'), findsOneWidget);
      
      // Should display soccer icon when no stadium image
      expect(find.byIcon(Icons.sports_soccer), findsOneWidget);
      
      // Should not crash with missing fields
      expect(tester.takeException(), isNull);
    });
  });
}
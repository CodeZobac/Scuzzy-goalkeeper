import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goalkeeper/src/features/announcements/data/models/announcement.dart';
import 'package:goalkeeper/src/features/announcements/presentation/widgets/participant_avatar_row.dart';

void main() {
  group('ParticipantAvatarRow', () {
    testWidgets('displays empty state when no participants', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ParticipantAvatarRow(
              participants: [],
              participantCount: 0,
              maxParticipants: 22,
            ),
          ),
        ),
      );

      // Should show empty avatar placeholder
      expect(find.byIcon(Icons.person_outline), findsOneWidget);
      expect(find.text('Members'), findsOneWidget);
      expect(find.text('(0/22)'), findsOneWidget);
    });

    testWidgets('displays participant avatars with count', (WidgetTester tester) async {
      final participants = [
        AnnouncementParticipant(
          userId: '1',
          name: 'John Doe',
          joinedAt: DateTime.now(),
        ),
        AnnouncementParticipant(
          userId: '2',
          name: 'Jane Smith',
          joinedAt: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ParticipantAvatarRow(
              participants: participants,
              participantCount: 2,
              maxParticipants: 22,
            ),
          ),
        ),
      );

      expect(find.text('Members'), findsOneWidget);
      expect(find.text('(2/22)'), findsOneWidget);
      
      // Should show avatar fallbacks with initials
      expect(find.text('JD'), findsOneWidget);
      expect(find.text('JS'), findsOneWidget);
    });

    testWidgets('displays +X indicator when more participants than maxVisible', (WidgetTester tester) async {
      final participants = List.generate(6, (index) => 
        AnnouncementParticipant(
          userId: '$index',
          name: 'User $index',
          joinedAt: DateTime.now(),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ParticipantAvatarRow(
              participants: participants,
              participantCount: 6,
              maxParticipants: 22,
              maxVisible: 4,
            ),
          ),
        ),
      );

      expect(find.text('Members'), findsOneWidget);
      expect(find.text('(6/22)'), findsOneWidget);
      expect(find.text('+2'), findsOneWidget); // Should show +2 for remaining participants
    });

    testWidgets('handles tap callback', (WidgetTester tester) async {
      bool tapped = false;
      final participants = [
        AnnouncementParticipant(
          userId: '1',
          name: 'John Doe',
          joinedAt: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: ParticipantAvatarRow(
                participants: participants,
                participantCount: 1,
                maxParticipants: 22,
                onTap: () => tapped = true,
              ),
            ),
          ),
        ),
      );

      // Tap on the "Members" text which should be tappable
      await tester.tap(find.text('Members'));
      expect(tapped, isTrue);
    });
  });
}
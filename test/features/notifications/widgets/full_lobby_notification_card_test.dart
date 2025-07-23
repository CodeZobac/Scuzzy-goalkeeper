import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goalkeeper/src/features/notifications/data/models/models.dart';
import 'package:goalkeeper/src/features/notifications/presentation/widgets/full_lobby_notification_card.dart';

void main() {
  group('FullLobbyNotificationCard', () {
    late AppNotification testNotification;
    late FullLobbyNotificationData testFullLobbyData;

    setUp(() {
      testFullLobbyData = FullLobbyNotificationData(
        announcementId: 'announcement_123',
        announcementTitle: 'Futebol no Estádio Central',
        gameDateTime: DateTime(2024, 12, 25, 14, 30),
        stadium: 'Estádio Central',
        participantCount: 22,
        maxParticipants: 22,
      );

      testNotification = AppNotification(
        id: 'notification_123',
        userId: 'user_123',
        title: 'Lobby Completo!',
        body: 'Seu anúncio atingiu a capacidade máxima',
        type: 'full_lobby',
        data: testFullLobbyData.toMap(),
        sentAt: DateTime.now(),
        createdAt: DateTime.now(),
      );
    });

    testWidgets('renders correctly with full lobby data', (WidgetTester tester) async {
      bool viewDetailsPressed = false;
      bool cardTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FullLobbyNotificationCard(
              notification: testNotification,
              onViewDetails: () => viewDetailsPressed = true,
              onTap: () => cardTapped = true,
            ),
          ),
        ),
      );

      // Verify card structure
      expect(find.byType(Container), findsWidgets);
      expect(find.byType(Material), findsWidgets);
      expect(find.byType(InkWell), findsWidgets);

      // Verify header content
      expect(find.text('Lobby Completo!'), findsOneWidget);
      expect(find.text('Seu anúncio atingiu a capacidade máxima'), findsOneWidget);
      expect(find.byIcon(Icons.celebration), findsOneWidget);

      // Verify announcement title
      expect(find.text('Futebol no Estádio Central'), findsOneWidget);

      // Verify participant count
      expect(find.text('(22/22)'), findsOneWidget);
      expect(find.byIcon(Icons.group), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);

      // Verify game details
      expect(find.text('14:30'), findsOneWidget);
      expect(find.text('25/12'), findsOneWidget);
      expect(find.text('Estádio Central'), findsOneWidget);
      expect(find.byIcon(Icons.access_time), findsOneWidget);
      expect(find.byIcon(Icons.calendar_today), findsOneWidget);
      expect(find.byIcon(Icons.location_on), findsOneWidget);

      // Verify action button
      expect(find.text('Ver Detalhes'), findsOneWidget);
    });

    testWidgets('shows unread indicator for unread notifications', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FullLobbyNotificationCard(
              notification: testNotification, // unread notification
              onViewDetails: () {},
              onTap: () {},
            ),
          ),
        ),
      );

      // Should show unread indicator
      expect(find.byType(Container), findsWidgets);
      
      // Find the unread indicator container
      final unreadIndicators = tester.widgetList<Container>(find.byType(Container))
          .where((container) => 
              container.decoration is BoxDecoration &&
              (container.decoration as BoxDecoration).shape == BoxShape.circle)
          .toList();
      
      expect(unreadIndicators.length, greaterThan(0));
    });

    testWidgets('handles view details button tap', (WidgetTester tester) async {
      bool viewDetailsPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FullLobbyNotificationCard(
              notification: testNotification,
              onViewDetails: () => viewDetailsPressed = true,
              onTap: () {},
            ),
          ),
        ),
      );

      // Tap the view details button
      await tester.tap(find.text('Ver Detalhes'));
      await tester.pump();

      expect(viewDetailsPressed, isTrue);
    });

    testWidgets('handles card tap', (WidgetTester tester) async {
      bool cardTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FullLobbyNotificationCard(
              notification: testNotification,
              onViewDetails: () {},
              onTap: () => cardTapped = true,
            ),
          ),
        ),
      );

      // Tap the card (but not the button)
      await tester.tap(find.text('Lobby Completo!'));
      await tester.pump();

      expect(cardTapped, isTrue);
    });

    testWidgets('shows loading state correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FullLobbyNotificationCard(
              notification: testNotification,
              onViewDetails: () {},
              onTap: () {},
              isLoading: true,
            ),
          ),
        ),
      );

      // Should show loading indicator instead of button text
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Ver Detalhes'), findsNothing);
    });

    testWidgets('returns empty widget when fullLobbyData is null', (WidgetTester tester) async {
      final invalidNotification = AppNotification(
        id: 'notification_123',
        userId: 'user_123',
        title: 'Test',
        body: 'Test',
        type: 'other_type', // Not full_lobby type
        data: null,
        sentAt: DateTime.now(),
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FullLobbyNotificationCard(
              notification: invalidNotification,
              onViewDetails: () {},
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.byType(SizedBox), findsOneWidget);
      expect(find.text('Lobby Completo!'), findsNothing);
    });

    testWidgets('formats date correctly for today', (WidgetTester tester) async {
      final todayNotification = testNotification.copyWith(
        data: testFullLobbyData.copyWith(
          gameDateTime: DateTime.now(),
        ).toMap(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FullLobbyNotificationCard(
              notification: todayNotification,
              onViewDetails: () {},
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Hoje'), findsOneWidget);
    });

    testWidgets('formats date correctly for tomorrow', (WidgetTester tester) async {
      final tomorrowNotification = testNotification.copyWith(
        data: testFullLobbyData.copyWith(
          gameDateTime: DateTime.now().add(const Duration(days: 1)),
        ).toMap(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FullLobbyNotificationCard(
              notification: tomorrowNotification,
              onViewDetails: () {},
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Amanhã'), findsOneWidget);
    });
  });
}
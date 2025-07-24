import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goalkeeper/src/features/notifications/data/models/models.dart';
import 'package:goalkeeper/src/features/notifications/presentation/widgets/contract_notification_card.dart';

void main() {
  group('ContractNotificationCard', () {
    late AppNotification mockNotification;
    late ContractNotificationData mockContractData;

    setUp(() {
      mockContractData = ContractNotificationData(
        contractId: 'contract_123',
        contractorId: 'user_456',
        contractorName: 'João Silva',
        contractorAvatarUrl: null,
        announcementId: 'announcement_789',
        announcementTitle: 'Jogo no Estádio Central',
        gameDateTime: DateTime(2024, 12, 25, 14, 30),
        stadium: 'Estádio Central',
        offeredAmount: 150.0,
        additionalNotes: 'Jogo importante, preciso de um goleiro experiente',
      );

      mockNotification = AppNotification(
        id: 'notification_123',
        userId: 'user_789',
        title: 'Nova Proposta de Contrato',
        body: 'João Silva quer contratá-lo para um jogo',
        type: 'contract_request',
        data: mockContractData.toMap(),
        sentAt: DateTime.now().subtract(const Duration(hours: 1)),
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      );
    });

    testWidgets('renders contract notification card with all elements', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ContractNotificationCard(
              notification: mockNotification,
              onAccept: () {},
              onDecline: () {},
              onTap: () {},
            ),
          ),
        ),
      );

      // Verify contractor name is displayed
      expect(find.text('João Silva'), findsOneWidget);
      
      // Verify contract message is displayed
      expect(find.text('quer contratá-lo para um jogo'), findsOneWidget);
      
      // Verify announcement title is displayed
      expect(find.text('Jogo no Estádio Central'), findsOneWidget);
      
      // Verify stadium is displayed
      expect(find.text('Estádio Central'), findsOneWidget);
      
      // Verify offered amount is displayed
      expect(find.text('R\$ 150'), findsOneWidget);
      
      // Verify additional notes are displayed
      expect(find.text('Jogo importante, preciso de um goleiro experiente'), findsOneWidget);
      
      // Verify action buttons are present
      expect(find.text('Aceitar'), findsOneWidget);
      expect(find.text('Recusar'), findsOneWidget);
      
      // Verify time is displayed (14:30)
      expect(find.text('14:30'), findsOneWidget);
      
      // Verify date is displayed (25/12)
      expect(find.text('25/12'), findsOneWidget);
    });

    testWidgets('handles accept button tap', (WidgetTester tester) async {
      bool acceptPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ContractNotificationCard(
              notification: mockNotification,
              onAccept: () => acceptPressed = true,
              onDecline: () {},
              onTap: () {},
            ),
          ),
        ),
      );

      await tester.tap(find.text('Aceitar'));
      await tester.pump();

      expect(acceptPressed, isTrue);
    });

    testWidgets('handles decline button tap', (WidgetTester tester) async {
      bool declinePressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ContractNotificationCard(
              notification: mockNotification,
              onAccept: () {},
              onDecline: () => declinePressed = true,
              onTap: () {},
            ),
          ),
        ),
      );

      await tester.tap(find.text('Recusar'));
      await tester.pump();

      expect(declinePressed, isTrue);
    });

    testWidgets('shows loading state when isLoading is true', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ContractNotificationCard(
              notification: mockNotification,
              onAccept: () {},
              onDecline: () {},
              onTap: () {},
              isLoading: true,
            ),
          ),
        ),
      );

      // Verify loading indicators are shown
      expect(find.byType(CircularProgressIndicator), findsWidgets);
    });

    testWidgets('returns empty widget for invalid contract data', (WidgetTester tester) async {
      final invalidNotification = mockNotification.copyWith(
        type: 'invalid_type',
        data: {},
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ContractNotificationCard(
              notification: invalidNotification,
              onAccept: () {},
              onDecline: () {},
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.byType(ContractNotificationCard), findsOneWidget);
      expect(find.text('João Silva'), findsNothing);
    });
  });
}
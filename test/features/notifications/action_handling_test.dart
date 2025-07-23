import 'package:flutter_test/flutter_test.dart';
import 'package:goalkeeper/src/features/notifications/data/models/notification.dart';
import 'package:goalkeeper/src/features/notifications/data/models/contract_notification_data.dart';

void main() {
  group('Notification Action Handling', () {
    test('contract notification data parsing works correctly', () {
      final contractData = ContractNotificationData(
        contractId: 'contract-123',
        contractorId: 'user-456',
        contractorName: 'João Silva',
        contractorAvatarUrl: null,
        announcementId: 'announcement-789',
        announcementTitle: 'Jogo de Futebol',
        gameDateTime: DateTime(2024, 12, 25, 14, 30),
        stadium: 'Estádio Municipal',
        offeredAmount: 50.0,
        additionalNotes: 'Jogo importante',
      );

      expect(contractData.contractId, 'contract-123');
      expect(contractData.contractorName, 'João Silva');
      expect(contractData.offeredAmount, 50.0);
      expect(contractData.stadium, 'Estádio Municipal');
    });

    test('notification type checking works correctly', () {
      final now = DateTime.now();
      
      final contractNotification = AppNotification(
        id: 'notification-1',
        userId: 'user-123',
        title: 'Nova Proposta de Contrato',
        body: 'João quer contratá-lo',
        type: 'contract_request',
        data: {'contract_id': 'contract-123'},
        sentAt: now,
        createdAt: now,
        readAt: null,
      );

      final fullLobbyNotification = AppNotification(
        id: 'notification-2',
        userId: 'user-123',
        title: 'Lobby Completo',
        body: 'Seu anúncio está cheio',
        type: 'full_lobby',
        data: {'announcement_id': '456'},
        sentAt: now,
        createdAt: now,
        readAt: null,
      );

      expect(contractNotification.isContractRequest, true);
      expect(contractNotification.isFullLobby, false);
      expect(contractNotification.requiresAction, true);
      expect(fullLobbyNotification.isContractRequest, false);
      expect(fullLobbyNotification.isFullLobby, true);
      expect(fullLobbyNotification.requiresAction, false);
    });

    test('notification data accessors work correctly', () {
      final now = DateTime.now();
      
      final contractNotification = AppNotification(
        id: 'notification-1',
        userId: 'user-123',
        title: 'Nova Proposta de Contrato',
        body: 'João quer contratá-lo',
        type: 'contract_request',
        data: {
          'contract_id': 'contract-123',
          'contractor_name': 'João Silva',
          'offered_amount': 50.0,
          'stadium': 'Estádio Municipal',
        },
        sentAt: now,
        createdAt: now,
        readAt: null,
      );

      expect(contractNotification.contractId, 'contract-123');
      expect(contractNotification.contractorName, 'João Silva');
      expect(contractNotification.offeredAmount, 50.0);
      expect(contractNotification.gameLocation, 'Estádio Municipal');
    });

    test('notification read status works correctly', () {
      final now = DateTime.now();
      
      final unreadNotification = AppNotification(
        id: 'notification-1',
        userId: 'user-123',
        title: 'Test',
        body: 'Test body',
        type: 'contract_request',
        data: {},
        sentAt: now,
        createdAt: now,
        readAt: null,
      );

      final readNotification = unreadNotification.copyWith(readAt: now);

      expect(unreadNotification.isUnread, true);
      expect(unreadNotification.isRead, false);
      expect(readNotification.isUnread, false);
      expect(readNotification.isRead, true);
    });
  });
}
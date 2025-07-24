import 'package:flutter_test/flutter_test.dart';
import 'package:goalkeeper/src/features/notifications/data/models/notification.dart';
import 'package:goalkeeper/src/features/notifications/data/models/notification_category.dart';
import 'package:goalkeeper/src/features/notifications/data/models/contract_notification_data.dart';
import 'package:goalkeeper/src/features/notifications/data/models/full_lobby_notification_data.dart';

void main() {
  group('AppNotification Enhanced Features', () {
    final testDateTime = DateTime(2024, 1, 15, 18, 30);
    final sentAt = DateTime.now().subtract(const Duration(hours: 2));
    final createdAt = DateTime.now().subtract(const Duration(hours: 2, minutes: 5));

    group('New notification type helpers', () {
      test('should identify contract request notifications', () {
        final contractNotification = AppNotification(
          id: '1',
          userId: 'user_123',
          title: 'Nova Proposta de Contrato',
          body: 'João Silva quer contratá-lo',
          type: 'contract_request',
          sentAt: sentAt,
          createdAt: createdAt,
        );

        expect(contractNotification.isContractRequest, true);
        expect(contractNotification.isFullLobby, false);
        expect(contractNotification.requiresAction, true);
      });

      test('should identify full lobby notifications', () {
        final fullLobbyNotification = AppNotification(
          id: '2',
          userId: 'user_123',
          title: 'Lobby Completo',
          body: 'Sua pelada está cheia!',
          type: 'full_lobby',
          sentAt: sentAt,
          createdAt: createdAt,
        );

        expect(fullLobbyNotification.isContractRequest, false);
        expect(fullLobbyNotification.isFullLobby, true);
        expect(fullLobbyNotification.requiresAction, false);
      });

      test('should handle general notifications', () {
        final generalNotification = AppNotification(
          id: '3',
          userId: 'user_123',
          title: 'Notificação Geral',
          body: 'Uma mensagem geral',
          type: 'general',
          sentAt: sentAt,
          createdAt: createdAt,
        );

        expect(generalNotification.isContractRequest, false);
        expect(generalNotification.isFullLobby, false);
        expect(generalNotification.requiresAction, false);
      });
    });

    group('Notification category', () {
      test('should return correct category for contract requests', () {
        final contractNotification = AppNotification(
          id: '1',
          userId: 'user_123',
          title: 'Nova Proposta de Contrato',
          body: 'João Silva quer contratá-lo',
          type: 'contract_request',
          sentAt: sentAt,
          createdAt: createdAt,
        );

        expect(contractNotification.category, NotificationCategory.contracts);
      });

      test('should return correct category for full lobby notifications', () {
        final fullLobbyNotification = AppNotification(
          id: '2',
          userId: 'user_123',
          title: 'Lobby Completo',
          body: 'Sua pelada está cheia!',
          type: 'full_lobby',
          sentAt: sentAt,
          createdAt: createdAt,
        );

        expect(fullLobbyNotification.category, NotificationCategory.fullLobbies);
      });

      test('should return general category for other notifications', () {
        final generalNotification = AppNotification(
          id: '3',
          userId: 'user_123',
          title: 'Notificação Geral',
          body: 'Uma mensagem geral',
          type: 'booking_request',
          sentAt: sentAt,
          createdAt: createdAt,
        );

        expect(generalNotification.category, NotificationCategory.general);
      });
    });

    group('Enhanced data accessors', () {
      test('should extract contract data correctly', () {
        final contractData = {
          'contract_id': 'contract_123',
          'announcement_id': 'announcement_789',
          'contractor_name': 'João Silva',
          'contractor_avatar_url': 'https://example.com/avatar.jpg',
          'offered_amount': 150.0,
          'stadium': 'Estádio do Maracanã',
          'game_date_time': testDateTime.toIso8601String(),
        };

        final notification = AppNotification(
          id: '1',
          userId: 'user_123',
          title: 'Nova Proposta de Contrato',
          body: 'João Silva quer contratá-lo',
          type: 'contract_request',
          data: contractData,
          sentAt: sentAt,
          createdAt: createdAt,
        );

        expect(notification.contractId, 'contract_123');
        expect(notification.announcementId, 'announcement_789');
        expect(notification.contractorName, 'João Silva');
        expect(notification.contractorAvatarUrl, 'https://example.com/avatar.jpg');
        expect(notification.offeredAmount, 150.0);
        expect(notification.gameLocation, 'Estádio do Maracanã');
        expect(notification.gameDateTime, testDateTime);
      });

      test('should handle missing data gracefully', () {
        final notification = AppNotification(
          id: '1',
          userId: 'user_123',
          title: 'Nova Proposta de Contrato',
          body: 'João Silva quer contratá-lo',
          type: 'contract_request',
          data: null,
          sentAt: sentAt,
          createdAt: createdAt,
        );

        expect(notification.contractId, null);
        expect(notification.announcementId, null);
        expect(notification.contractorName, null);
        expect(notification.contractorAvatarUrl, null);
        expect(notification.offeredAmount, null);
        expect(notification.gameLocation, null);
        expect(notification.gameDateTime, null);
      });

      test('should handle invalid date format gracefully', () {
        final contractData = {
          'game_date_time': 'invalid_date',
        };

        final notification = AppNotification(
          id: '1',
          userId: 'user_123',
          title: 'Nova Proposta de Contrato',
          body: 'João Silva quer contratá-lo',
          type: 'contract_request',
          data: contractData,
          sentAt: sentAt,
          createdAt: createdAt,
        );

        expect(() => notification.gameDateTime, throwsA(isA<FormatException>()));
      });
    });

    group('Structured data accessors', () {
      test('should return ContractNotificationData for contract requests', () {
        final contractData = {
          'contract_id': 'contract_123',
          'contractor_id': 'user_456',
          'contractor_name': 'João Silva',
          'contractor_avatar_url': 'https://example.com/avatar.jpg',
          'announcement_id': 'announcement_789',
          'announcement_title': 'Pelada no Maracanã',
          'game_date_time': testDateTime.toIso8601String(),
          'stadium': 'Estádio do Maracanã',
          'offered_amount': 150.0,
          'additional_notes': 'Jogo importante',
        };

        final notification = AppNotification(
          id: '1',
          userId: 'user_123',
          title: 'Nova Proposta de Contrato',
          body: 'João Silva quer contratá-lo',
          type: 'contract_request',
          data: contractData,
          sentAt: sentAt,
          createdAt: createdAt,
        );

        final contractNotificationData = notification.contractData;
        expect(contractNotificationData, isNotNull);
        expect(contractNotificationData!.contractId, 'contract_123');
        expect(contractNotificationData.contractorName, 'João Silva');
        expect(contractNotificationData.offeredAmount, 150.0);
      });

      test('should return null ContractNotificationData for non-contract notifications', () {
        final notification = AppNotification(
          id: '1',
          userId: 'user_123',
          title: 'Lobby Completo',
          body: 'Sua pelada está cheia!',
          type: 'full_lobby',
          sentAt: sentAt,
          createdAt: createdAt,
        );

        expect(notification.contractData, null);
      });

      test('should return FullLobbyNotificationData for full lobby notifications', () {
        final fullLobbyData = {
          'announcement_id': 'announcement_789',
          'announcement_title': 'Pelada no Maracanã',
          'game_date_time': testDateTime.toIso8601String(),
          'stadium': 'Estádio do Maracanã',
          'participant_count': 22,
          'max_participants': 22,
        };

        final notification = AppNotification(
          id: '2',
          userId: 'user_123',
          title: 'Lobby Completo',
          body: 'Sua pelada está cheia!',
          type: 'full_lobby',
          data: fullLobbyData,
          sentAt: sentAt,
          createdAt: createdAt,
        );

        final fullLobbyNotificationData = notification.fullLobbyData;
        expect(fullLobbyNotificationData, isNotNull);
        expect(fullLobbyNotificationData!.announcementId, 'announcement_789');
        expect(fullLobbyNotificationData.participantCount, 22);
        expect(fullLobbyNotificationData.maxParticipants, 22);
      });

      test('should return null FullLobbyNotificationData for non-full-lobby notifications', () {
        final notification = AppNotification(
          id: '1',
          userId: 'user_123',
          title: 'Nova Proposta de Contrato',
          body: 'João Silva quer contratá-lo',
          type: 'contract_request',
          sentAt: sentAt,
          createdAt: createdAt,
        );

        expect(notification.fullLobbyData, null);
      });

      test('should handle invalid structured data gracefully', () {
        final invalidData = {
          'invalid_field': 'invalid_value',
        };

        final contractNotification = AppNotification(
          id: '1',
          userId: 'user_123',
          title: 'Nova Proposta de Contrato',
          body: 'João Silva quer contratá-lo',
          type: 'contract_request',
          data: invalidData,
          sentAt: sentAt,
          createdAt: createdAt,
        );

        final fullLobbyNotification = AppNotification(
          id: '2',
          userId: 'user_123',
          title: 'Lobby Completo',
          body: 'Sua pelada está cheia!',
          type: 'full_lobby',
          data: invalidData,
          sentAt: sentAt,
          createdAt: createdAt,
        );

        expect(contractNotification.contractData, null);
        expect(fullLobbyNotification.fullLobbyData, null);
      });

      test('should handle null data gracefully', () {
        final contractNotification = AppNotification(
          id: '1',
          userId: 'user_123',
          title: 'Nova Proposta de Contrato',
          body: 'João Silva quer contratá-lo',
          type: 'contract_request',
          data: null,
          sentAt: sentAt,
          createdAt: createdAt,
        );

        final fullLobbyNotification = AppNotification(
          id: '2',
          userId: 'user_123',
          title: 'Lobby Completo',
          body: 'Sua pelada está cheia!',
          type: 'full_lobby',
          data: null,
          sentAt: sentAt,
          createdAt: createdAt,
        );

        expect(contractNotification.contractData, null);
        expect(fullLobbyNotification.fullLobbyData, null);
      });
    });

    group('Backward compatibility', () {
      test('should maintain existing functionality', () {
        final bookingNotification = AppNotification(
          id: '1',
          userId: 'user_123',
          bookingId: 'booking_456',
          title: 'Solicitação de Reserva',
          body: 'Nova solicitação de reserva',
          type: 'booking_request',
          sentAt: sentAt,
          createdAt: createdAt,
        );

        expect(bookingNotification.isBookingRequest, true);
        expect(bookingNotification.isBookingConfirmed, false);
        expect(bookingNotification.isBookingCancelled, false);
        expect(bookingNotification.isRead, false);
        expect(bookingNotification.isUnread, true);
      });

      test('should maintain existing serialization', () {
        final notification = AppNotification(
          id: '1',
          userId: 'user_123',
          bookingId: 'booking_456',
          title: 'Solicitação de Reserva',
          body: 'Nova solicitação de reserva',
          type: 'booking_request',
          sentAt: sentAt,
          createdAt: createdAt,
        );

        final map = notification.toMap();
        final fromMap = AppNotification.fromMap(map);

        expect(fromMap.id, notification.id);
        expect(fromMap.userId, notification.userId);
        expect(fromMap.bookingId, notification.bookingId);
        expect(fromMap.title, notification.title);
        expect(fromMap.body, notification.body);
        expect(fromMap.type, notification.type);
      });
    });
  });
}
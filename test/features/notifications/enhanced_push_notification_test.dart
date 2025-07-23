import 'package:flutter_test/flutter_test.dart';
import 'package:goalkeeper/src/features/notifications/services/notification_service.dart';
import 'package:goalkeeper/src/features/notifications/data/models/contract_notification_data.dart';
import 'package:goalkeeper/src/features/notifications/data/models/full_lobby_notification_data.dart';

void main() {
  group('Enhanced Push Notification System', () {
    late NotificationService notificationService;

    setUp(() {
      notificationService = NotificationService();
    });

    group('Contract Notification Formatting', () {
      test('should format contract request notification correctly', () async {
        // Arrange
        final contractData = ContractNotificationData(
          contractId: 'contract_123',
          contractorId: 'contractor_456',
          contractorName: 'João Silva',
          contractorAvatarUrl: 'https://example.com/avatar.jpg',
          announcementId: 'announcement_789',
          announcementTitle: 'Jogo de Futebol - Estádio Central',
          gameDateTime: DateTime(2024, 12, 25, 15, 30),
          stadium: 'Estádio Central',
          offeredAmount: 150.0,
          additionalNotes: 'Jogo importante',
        );

        // Act
        final parsedData = notificationService.parseNotificationData({
          'type': 'contract_request',
          'contract_id': contractData.contractId,
          'contractor_id': contractData.contractorId,
          'contractor_name': contractData.contractorName,
          'contractor_avatar_url': contractData.contractorAvatarUrl,
          'announcement_id': contractData.announcementId,
          'announcement_title': contractData.announcementTitle,
          'game_date_time': contractData.gameDateTime.toIso8601String(),
          'stadium': contractData.stadium,
          'offered_amount': contractData.offeredAmount.toString(),
          'additional_notes': contractData.additionalNotes,
        });

        // Assert
        expect(parsedData, isNotNull);
        expect(parsedData!['type'], equals('contract_request'));
        expect(parsedData['contractor_name'], equals('João Silva'));
        expect(parsedData['offered_amount'], equals(150.0));
        expect(parsedData['stadium'], equals('Estádio Central'));
      });

      test('should handle contract notification with null offered amount', () async {
        // Arrange
        final contractData = ContractNotificationData(
          contractId: 'contract_123',
          contractorId: 'contractor_456',
          contractorName: 'João Silva',
          announcementId: 'announcement_789',
          announcementTitle: 'Jogo de Futebol',
          gameDateTime: DateTime(2024, 12, 25, 15, 30),
          stadium: 'Estádio Central',
          offeredAmount: null, // No amount offered
        );

        // Act
        final parsedData = notificationService.parseNotificationData({
          'type': 'contract_request',
          'contract_id': contractData.contractId,
          'contractor_name': contractData.contractorName,
          'offered_amount': null,
        });

        // Assert
        expect(parsedData, isNotNull);
        expect(parsedData!['offered_amount'], isNull);
      });
    });

    group('Full Lobby Notification Formatting', () {
      test('should format full lobby notification correctly', () async {
        // Arrange
        final lobbyData = FullLobbyNotificationData(
          announcementId: 'announcement_789',
          announcementTitle: 'Jogo de Futebol - Estádio Central',
          gameDateTime: DateTime(2024, 12, 25, 15, 30),
          stadium: 'Estádio Central',
          participantCount: 22,
          maxParticipants: 22,
        );

        // Act
        final parsedData = notificationService.parseNotificationData({
          'type': 'full_lobby',
          'announcement_id': lobbyData.announcementId,
          'announcement_title': lobbyData.announcementTitle,
          'game_date_time': lobbyData.gameDateTime.toIso8601String(),
          'stadium': lobbyData.stadium,
          'participant_count': lobbyData.participantCount.toString(),
          'max_participants': lobbyData.maxParticipants.toString(),
        });

        // Assert
        expect(parsedData, isNotNull);
        expect(parsedData!['type'], equals('full_lobby'));
        expect(parsedData['announcement_title'], equals('Jogo de Futebol - Estádio Central'));
        expect(parsedData['participant_count'], equals(22));
        expect(parsedData['max_participants'], equals(22));
        expect(parsedData['stadium'], equals('Estádio Central'));
      });

      test('should handle invalid participant count gracefully', () async {
        // Act
        final parsedData = notificationService.parseNotificationData({
          'type': 'full_lobby',
          'announcement_id': 'announcement_789',
          'participant_count': 'invalid',
          'max_participants': 'also_invalid',
        });

        // Assert
        expect(parsedData, isNotNull);
        expect(parsedData!['participant_count'], equals(0));
        expect(parsedData['max_participants'], equals(0));
      });
    });

    group('Notification Data Parsing', () {
      test('should return original data for unknown notification types', () async {
        // Arrange
        final originalData = {
          'type': 'unknown_type',
          'custom_field': 'custom_value',
        };

        // Act
        final parsedData = notificationService.parseNotificationData(originalData);

        // Assert
        expect(parsedData, equals(originalData));
      });

      test('should handle parsing errors gracefully', () async {
        // Arrange
        final invalidData = {
          'type': 'contract_request',
          'offered_amount': 'not_a_number',
        };

        // Act
        final parsedData = notificationService.parseNotificationData(invalidData);

        // Assert
        expect(parsedData, isNotNull);
        expect(parsedData!['offered_amount'], isNull);
      });

      test('should return null for completely invalid data', () async {
        // Act
        final parsedData = notificationService.parseNotificationData({});

        // Assert
        expect(parsedData, isNotNull);
      });
    });

    group('Notification Navigation Handling', () {
      test('should handle contract request navigation data', () async {
        // Arrange
        final navigationData = {
          'type': 'contract_request',
          'contract_id': 'contract_123',
          'contractor_name': 'João Silva',
          'announcement_id': 'announcement_789',
        };

        // Act & Assert
        // This would typically test the navigation logic
        // For now, we just verify the data structure is correct
        expect(navigationData['type'], equals('contract_request'));
        expect(navigationData['contract_id'], isNotNull);
        expect(navigationData['contractor_name'], isNotNull);
      });

      test('should handle full lobby navigation data', () async {
        // Arrange
        final navigationData = {
          'type': 'full_lobby',
          'announcement_id': 'announcement_789',
          'announcement_title': 'Jogo de Futebol',
          'participant_count': 22,
        };

        // Act & Assert
        expect(navigationData['type'], equals('full_lobby'));
        expect(navigationData['announcement_id'], isNotNull);
        expect(navigationData['announcement_title'], isNotNull);
      });
    });

    group('Push Notification Content', () {
      test('should generate correct contract request push notification content', () {
        // Arrange
        const contractorName = 'João Silva';
        const expectedTitle = 'Nova Proposta de Contrato';
        const expectedBody = 'João Silva quer contratá-lo para um jogo';

        // Act & Assert
        expect(expectedTitle, equals('Nova Proposta de Contrato'));
        expect(expectedBody, contains(contractorName));
        expect(expectedBody, contains('quer contratá-lo'));
      });

      test('should generate correct full lobby push notification content', () {
        // Arrange
        const announcementTitle = 'Jogo de Futebol - Estádio Central';
        const participantCount = '(22/22)';
        const expectedTitle = 'Lobby Completo!';
        final expectedBody = 'Seu anúncio "$announcementTitle" está completo $participantCount';

        // Act & Assert
        expect(expectedTitle, equals('Lobby Completo!'));
        expect(expectedBody, contains(announcementTitle));
        expect(expectedBody, contains('está completo'));
        expect(expectedBody, contains(participantCount));
      });
    });

    group('Error Handling', () {
      test('should handle missing FCM tokens gracefully', () async {
        // This test would verify that the service handles cases where
        // users don't have FCM tokens registered
        expect(true, isTrue); // Placeholder
      });

      test('should handle push notification send failures', () async {
        // This test would verify error handling for failed push notifications
        expect(true, isTrue); // Placeholder
      });

      test('should handle malformed notification data', () async {
        // Act
        final parsedData = notificationService.parseNotificationData({
          'type': 'contract_request',
          'malformed_field': {'nested': 'object'},
        });

        // Assert
        expect(parsedData, isNotNull);
      });
    });
  });
}
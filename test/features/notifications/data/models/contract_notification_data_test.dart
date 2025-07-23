import 'package:flutter_test/flutter_test.dart';
import 'package:goalkeeper/src/features/notifications/data/models/contract_notification_data.dart';

void main() {
  group('ContractNotificationData', () {
    final testDateTime = DateTime(2024, 1, 15, 18, 30);
    
    final testData = ContractNotificationData(
      contractId: 'contract_123',
      contractorId: 'user_456',
      contractorName: 'João Silva',
      contractorAvatarUrl: 'https://example.com/avatar.jpg',
      announcementId: 'announcement_789',
      announcementTitle: 'Pelada no Maracanã',
      gameDateTime: testDateTime,
      stadium: 'Estádio do Maracanã',
      offeredAmount: 150.0,
      additionalNotes: 'Jogo importante, preciso de um bom goleiro',
    );

    test('should create instance with all required fields', () {
      final data = ContractNotificationData(
        contractId: 'contract_123',
        contractorId: 'user_456',
        contractorName: 'João Silva',
        announcementId: 'announcement_789',
        announcementTitle: 'Pelada no Maracanã',
        gameDateTime: testDateTime,
        stadium: 'Estádio do Maracanã',
      );

      expect(data.contractId, 'contract_123');
      expect(data.contractorId, 'user_456');
      expect(data.contractorName, 'João Silva');
      expect(data.announcementId, 'announcement_789');
      expect(data.announcementTitle, 'Pelada no Maracanã');
      expect(data.gameDateTime, testDateTime);
      expect(data.stadium, 'Estádio do Maracanã');
      expect(data.contractorAvatarUrl, null);
      expect(data.offeredAmount, null);
      expect(data.additionalNotes, null);
    });

    test('should convert to map correctly', () {
      final map = testData.toMap();

      expect(map['contract_id'], 'contract_123');
      expect(map['contractor_id'], 'user_456');
      expect(map['contractor_name'], 'João Silva');
      expect(map['contractor_avatar_url'], 'https://example.com/avatar.jpg');
      expect(map['announcement_id'], 'announcement_789');
      expect(map['announcement_title'], 'Pelada no Maracanã');
      expect(map['game_date_time'], testDateTime.toIso8601String());
      expect(map['stadium'], 'Estádio do Maracanã');
      expect(map['offered_amount'], 150.0);
      expect(map['additional_notes'], 'Jogo importante, preciso de um bom goleiro');
    });

    test('should create from map correctly', () {
      final map = {
        'contract_id': 'contract_123',
        'contractor_id': 'user_456',
        'contractor_name': 'João Silva',
        'contractor_avatar_url': 'https://example.com/avatar.jpg',
        'announcement_id': 'announcement_789',
        'announcement_title': 'Pelada no Maracanã',
        'game_date_time': testDateTime.toIso8601String(),
        'stadium': 'Estádio do Maracanã',
        'offered_amount': 150.0,
        'additional_notes': 'Jogo importante, preciso de um bom goleiro',
      };

      final data = ContractNotificationData.fromMap(map);

      expect(data.contractId, 'contract_123');
      expect(data.contractorId, 'user_456');
      expect(data.contractorName, 'João Silva');
      expect(data.contractorAvatarUrl, 'https://example.com/avatar.jpg');
      expect(data.announcementId, 'announcement_789');
      expect(data.announcementTitle, 'Pelada no Maracanã');
      expect(data.gameDateTime, testDateTime);
      expect(data.stadium, 'Estádio do Maracanã');
      expect(data.offeredAmount, 150.0);
      expect(data.additionalNotes, 'Jogo importante, preciso de um bom goleiro');
    });

    test('should handle missing optional fields in fromMap', () {
      final map = {
        'contract_id': 'contract_123',
        'contractor_id': 'user_456',
        'contractor_name': 'João Silva',
        'announcement_id': 'announcement_789',
        'announcement_title': 'Pelada no Maracanã',
        'game_date_time': testDateTime.toIso8601String(),
        'stadium': 'Estádio do Maracanã',
      };

      final data = ContractNotificationData.fromMap(map);

      expect(data.contractorAvatarUrl, null);
      expect(data.offeredAmount, null);
      expect(data.additionalNotes, null);
    });

    test('should handle empty or null values in fromMap', () {
      final map = {
        'contract_id': '',
        'contractor_id': '',
        'contractor_name': '',
        'announcement_id': '',
        'announcement_title': '',
        'game_date_time': testDateTime.toIso8601String(),
        'stadium': '',
      };

      final data = ContractNotificationData.fromMap(map);

      expect(data.contractId, '');
      expect(data.contractorId, '');
      expect(data.contractorName, '');
      expect(data.announcementId, '');
      expect(data.announcementTitle, '');
      expect(data.stadium, '');
    });

    test('should convert to/from JSON correctly', () {
      final json = testData.toJson();
      final dataFromJson = ContractNotificationData.fromJson(json);

      expect(dataFromJson.contractId, testData.contractId);
      expect(dataFromJson.contractorId, testData.contractorId);
      expect(dataFromJson.contractorName, testData.contractorName);
      expect(dataFromJson.contractorAvatarUrl, testData.contractorAvatarUrl);
      expect(dataFromJson.announcementId, testData.announcementId);
      expect(dataFromJson.announcementTitle, testData.announcementTitle);
      expect(dataFromJson.gameDateTime, testData.gameDateTime);
      expect(dataFromJson.stadium, testData.stadium);
      expect(dataFromJson.offeredAmount, testData.offeredAmount);
      expect(dataFromJson.additionalNotes, testData.additionalNotes);
    });

    test('should create copy with updated fields', () {
      final updatedData = testData.copyWith(
        contractorName: 'Maria Santos',
        offeredAmount: 200.0,
      );

      expect(updatedData.contractId, testData.contractId);
      expect(updatedData.contractorName, 'Maria Santos');
      expect(updatedData.offeredAmount, 200.0);
      expect(updatedData.stadium, testData.stadium);
    });

    test('should implement equality correctly', () {
      final data1 = ContractNotificationData(
        contractId: 'contract_123',
        contractorId: 'user_456',
        contractorName: 'João Silva',
        announcementId: 'announcement_789',
        announcementTitle: 'Pelada no Maracanã',
        gameDateTime: testDateTime,
        stadium: 'Estádio do Maracanã',
      );

      final data2 = ContractNotificationData(
        contractId: 'contract_123',
        contractorId: 'user_456',
        contractorName: 'João Silva',
        announcementId: 'announcement_789',
        announcementTitle: 'Pelada no Maracanã',
        gameDateTime: testDateTime,
        stadium: 'Estádio do Maracanã',
      );

      final data3 = ContractNotificationData(
        contractId: 'contract_456',
        contractorId: 'user_456',
        contractorName: 'João Silva',
        announcementId: 'announcement_789',
        announcementTitle: 'Pelada no Maracanã',
        gameDateTime: testDateTime,
        stadium: 'Estádio do Maracanã',
      );

      expect(data1, equals(data2));
      expect(data1, isNot(equals(data3)));
      expect(data1.hashCode, equals(data2.hashCode));
      expect(data1.hashCode, isNot(equals(data3.hashCode)));
    });
  });
}
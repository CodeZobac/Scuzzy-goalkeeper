import 'package:flutter_test/flutter_test.dart';
import 'package:goalkeeper/src/features/notifications/data/models/full_lobby_notification_data.dart';

void main() {
  group('FullLobbyNotificationData', () {
    final testDateTime = DateTime(2024, 1, 15, 18, 30);
    
    final testData = FullLobbyNotificationData(
      announcementId: 'announcement_789',
      announcementTitle: 'Pelada no Maracanã',
      gameDateTime: testDateTime,
      stadium: 'Estádio do Maracanã',
      participantCount: 22,
      maxParticipants: 22,
    );

    test('should create instance with all required fields', () {
      expect(testData.announcementId, 'announcement_789');
      expect(testData.announcementTitle, 'Pelada no Maracanã');
      expect(testData.gameDateTime, testDateTime);
      expect(testData.stadium, 'Estádio do Maracanã');
      expect(testData.participantCount, 22);
      expect(testData.maxParticipants, 22);
    });

    test('should convert to map correctly', () {
      final map = testData.toMap();

      expect(map['announcement_id'], 'announcement_789');
      expect(map['announcement_title'], 'Pelada no Maracanã');
      expect(map['game_date_time'], testDateTime.toIso8601String());
      expect(map['stadium'], 'Estádio do Maracanã');
      expect(map['participant_count'], 22);
      expect(map['max_participants'], 22);
    });

    test('should create from map correctly', () {
      final map = {
        'announcement_id': 'announcement_789',
        'announcement_title': 'Pelada no Maracanã',
        'game_date_time': testDateTime.toIso8601String(),
        'stadium': 'Estádio do Maracanã',
        'participant_count': 22,
        'max_participants': 22,
      };

      final data = FullLobbyNotificationData.fromMap(map);

      expect(data.announcementId, 'announcement_789');
      expect(data.announcementTitle, 'Pelada no Maracanã');
      expect(data.gameDateTime, testDateTime);
      expect(data.stadium, 'Estádio do Maracanã');
      expect(data.participantCount, 22);
      expect(data.maxParticipants, 22);
    });

    test('should handle missing or null values in fromMap', () {
      final map = {
        'announcement_id': '',
        'announcement_title': '',
        'game_date_time': testDateTime.toIso8601String(),
        'stadium': '',
        'participant_count': null,
        'max_participants': null,
      };

      final data = FullLobbyNotificationData.fromMap(map);

      expect(data.announcementId, '');
      expect(data.announcementTitle, '');
      expect(data.stadium, '');
      expect(data.participantCount, 0);
      expect(data.maxParticipants, 0);
    });

    test('should convert to/from JSON correctly', () {
      final json = testData.toJson();
      final dataFromJson = FullLobbyNotificationData.fromJson(json);

      expect(dataFromJson.announcementId, testData.announcementId);
      expect(dataFromJson.announcementTitle, testData.announcementTitle);
      expect(dataFromJson.gameDateTime, testData.gameDateTime);
      expect(dataFromJson.stadium, testData.stadium);
      expect(dataFromJson.participantCount, testData.participantCount);
      expect(dataFromJson.maxParticipants, testData.maxParticipants);
    });

    test('should create copy with updated fields', () {
      final updatedData = testData.copyWith(
        participantCount: 20,
        announcementTitle: 'Pelada no Morumbi',
      );

      expect(updatedData.announcementId, testData.announcementId);
      expect(updatedData.announcementTitle, 'Pelada no Morumbi');
      expect(updatedData.participantCount, 20);
      expect(updatedData.maxParticipants, testData.maxParticipants);
      expect(updatedData.stadium, testData.stadium);
    });

    test('should format participant count display correctly', () {
      expect(testData.participantCountDisplay, '(22/22)');

      final partialData = testData.copyWith(participantCount: 18);
      expect(partialData.participantCountDisplay, '(18/22)');

      final emptyData = testData.copyWith(participantCount: 0);
      expect(emptyData.participantCountDisplay, '(0/22)');
    });

    test('should determine if lobby is full correctly', () {
      expect(testData.isFull, true);

      final partialData = testData.copyWith(participantCount: 18);
      expect(partialData.isFull, false);

      final overFullData = testData.copyWith(participantCount: 25);
      expect(overFullData.isFull, true);

      final emptyData = testData.copyWith(participantCount: 0);
      expect(emptyData.isFull, false);
    });

    test('should implement equality correctly', () {
      final data1 = FullLobbyNotificationData(
        announcementId: 'announcement_789',
        announcementTitle: 'Pelada no Maracanã',
        gameDateTime: testDateTime,
        stadium: 'Estádio do Maracanã',
        participantCount: 22,
        maxParticipants: 22,
      );

      final data2 = FullLobbyNotificationData(
        announcementId: 'announcement_789',
        announcementTitle: 'Pelada no Maracanã',
        gameDateTime: testDateTime,
        stadium: 'Estádio do Maracanã',
        participantCount: 22,
        maxParticipants: 22,
      );

      final data3 = FullLobbyNotificationData(
        announcementId: 'announcement_456',
        announcementTitle: 'Pelada no Maracanã',
        gameDateTime: testDateTime,
        stadium: 'Estádio do Maracanã',
        participantCount: 22,
        maxParticipants: 22,
      );

      expect(data1, equals(data2));
      expect(data1, isNot(equals(data3)));
      expect(data1.hashCode, equals(data2.hashCode));
      expect(data1.hashCode, isNot(equals(data3.hashCode)));
    });
  });
}
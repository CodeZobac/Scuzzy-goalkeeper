import 'package:flutter_test/flutter_test.dart';
import 'package:goalkeeper/src/features/notifications/data/models/notification.dart';
import 'package:goalkeeper/src/features/notifications/data/models/notification_category.dart';

void main() {
  group('Notification Status Management Tests', () {
    test('should correctly identify read and unread notifications', () {
      // Create unread notification
      final unreadNotification = AppNotification(
        id: '1',
        userId: 'user1',
        title: 'Test Notification',
        body: 'Test body',
        type: 'general',
        sentAt: DateTime.now(),
        createdAt: DateTime.now(),
        readAt: null, // Unread
      );

      // Create read notification
      final readNotification = AppNotification(
        id: '2',
        userId: 'user1',
        title: 'Read Notification',
        body: 'Read body',
        type: 'general',
        sentAt: DateTime.now(),
        createdAt: DateTime.now(),
        readAt: DateTime.now(), // Read
      );

      // Test unread notification
      expect(unreadNotification.isUnread, true);
      expect(unreadNotification.isRead, false);

      // Test read notification
      expect(readNotification.isRead, true);
      expect(readNotification.isUnread, false);
    });

    test('should correctly identify archived notifications', () {
      // Create active notification
      final activeNotification = AppNotification(
        id: '1',
        userId: 'user1',
        title: 'Active Notification',
        body: 'Active body',
        type: 'general',
        sentAt: DateTime.now(),
        createdAt: DateTime.now(),
        archivedAt: null, // Not archived
      );

      // Create archived notification
      final archivedNotification = AppNotification(
        id: '2',
        userId: 'user1',
        title: 'Archived Notification',
        body: 'Archived body',
        type: 'general',
        sentAt: DateTime.now(),
        createdAt: DateTime.now(),
        archivedAt: DateTime.now(), // Archived
      );

      // Test active notification
      expect(activeNotification.isActive, true);
      expect(activeNotification.isArchived, false);

      // Test archived notification
      expect(archivedNotification.isArchived, true);
      expect(archivedNotification.isActive, false);
    });

    test('should correctly categorize notifications', () {
      // Contract notification
      final contractNotification = AppNotification(
        id: '1',
        userId: 'user1',
        title: 'Contract Request',
        body: 'Contract body',
        type: 'contract_request',
        sentAt: DateTime.now(),
        createdAt: DateTime.now(),
      );

      // Full lobby notification
      final fullLobbyNotification = AppNotification(
        id: '2',
        userId: 'user1',
        title: 'Full Lobby',
        body: 'Full lobby body',
        type: 'full_lobby',
        sentAt: DateTime.now(),
        createdAt: DateTime.now(),
      );

      // General notification
      final generalNotification = AppNotification(
        id: '3',
        userId: 'user1',
        title: 'General',
        body: 'General body',
        type: 'general',
        sentAt: DateTime.now(),
        createdAt: DateTime.now(),
      );

      // Test categories
      expect(contractNotification.category, NotificationCategory.contracts);
      expect(contractNotification.isContractRequest, true);
      expect(contractNotification.requiresAction, true);

      expect(fullLobbyNotification.category, NotificationCategory.fullLobbies);
      expect(fullLobbyNotification.isFullLobby, true);
      expect(fullLobbyNotification.requiresAction, false);

      expect(generalNotification.category, NotificationCategory.general);
      expect(generalNotification.requiresAction, false);
    });

    test('should correctly copy notification with updated fields', () {
      final originalNotification = AppNotification(
        id: '1',
        userId: 'user1',
        title: 'Original',
        body: 'Original body',
        type: 'general',
        sentAt: DateTime.now(),
        createdAt: DateTime.now(),
        readAt: null,
        archivedAt: null,
      );

      final readTime = DateTime.now();
      final updatedNotification = originalNotification.copyWith(
        readAt: readTime,
      );

      // Original should remain unchanged
      expect(originalNotification.isUnread, true);
      expect(originalNotification.readAt, null);

      // Updated should have new read status
      expect(updatedNotification.isRead, true);
      expect(updatedNotification.readAt, readTime);

      // Other fields should remain the same
      expect(updatedNotification.id, originalNotification.id);
      expect(updatedNotification.title, originalNotification.title);
      expect(updatedNotification.body, originalNotification.body);
    });

    test('should correctly format display time', () {
      final now = DateTime.now();
      
      // Recent notification (minutes ago)
      final recentNotification = AppNotification(
        id: '1',
        userId: 'user1',
        title: 'Recent',
        body: 'Recent body',
        type: 'general',
        sentAt: now.subtract(const Duration(minutes: 30)),
        createdAt: now.subtract(const Duration(minutes: 30)),
      );

      // Hours ago notification
      final hoursAgoNotification = AppNotification(
        id: '2',
        userId: 'user1',
        title: 'Hours ago',
        body: 'Hours ago body',
        type: 'general',
        sentAt: now.subtract(const Duration(hours: 2)),
        createdAt: now.subtract(const Duration(hours: 2)),
      );

      // Days ago notification
      final daysAgoNotification = AppNotification(
        id: '3',
        userId: 'user1',
        title: 'Days ago',
        body: 'Days ago body',
        type: 'general',
        sentAt: now.subtract(const Duration(days: 3)),
        createdAt: now.subtract(const Duration(days: 3)),
      );

      // Test display time formatting
      expect(recentNotification.displayTime, '30m atrás');
      expect(hoursAgoNotification.displayTime, '2h atrás');
      expect(daysAgoNotification.displayTime, '3d atrás');
    });

    test('should handle notification data serialization', () {
      final testData = {
        'contract_id': 'contract123',
        'contractor_name': 'John Doe',
        'offered_amount': 100.0,
        'stadium': 'Test Stadium',
      };

      final notification = AppNotification(
        id: '1',
        userId: 'user1',
        title: 'Contract Request',
        body: 'Contract body',
        type: 'contract_request',
        data: testData,
        sentAt: DateTime.now(),
        createdAt: DateTime.now(),
      );

      // Test data accessors
      expect(notification.contractId, 'contract123');
      expect(notification.contractorName, 'John Doe');
      expect(notification.offeredAmount, 100.0);
      expect(notification.gameLocation, 'Test Stadium');

      // Test serialization
      final map = notification.toMap();
      expect(map['data'], testData);

      // Test deserialization
      final deserializedNotification = AppNotification.fromMap(map);
      expect(deserializedNotification.contractId, 'contract123');
      expect(deserializedNotification.contractorName, 'John Doe');
      expect(deserializedNotification.offeredAmount, 100.0);
    });
  });
}
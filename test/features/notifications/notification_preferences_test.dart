import 'package:flutter_test/flutter_test.dart';
import 'package:goalkeeper/src/features/notifications/data/models/notification_preferences.dart';

void main() {
  group('NotificationPreferences', () {
    test('should create default preferences correctly', () {
      const userId = 'test-user-id';
      final preferences = NotificationPreferences.defaultPreferences(userId);

      expect(preferences.userId, userId);
      expect(preferences.contractNotifications, true);
      expect(preferences.fullLobbyNotifications, true);
      expect(preferences.generalNotifications, true);
      expect(preferences.pushNotificationsEnabled, true);
    });

    test('should check notification type enabled correctly', () {
      const userId = 'test-user-id';
      final preferences = NotificationPreferences(
        userId: userId,
        contractNotifications: true,
        fullLobbyNotifications: false,
        generalNotifications: true,
        pushNotificationsEnabled: true,
        updatedAt: DateTime.now(),
      );

      expect(preferences.isNotificationTypeEnabled('contract_request'), true);
      expect(preferences.isNotificationTypeEnabled('full_lobby'), false);
      expect(preferences.isNotificationTypeEnabled('general'), true);
    });

    test('should return false when push notifications are disabled', () {
      const userId = 'test-user-id';
      final preferences = NotificationPreferences(
        userId: userId,
        contractNotifications: true,
        fullLobbyNotifications: true,
        generalNotifications: true,
        pushNotificationsEnabled: false,
        updatedAt: DateTime.now(),
      );

      expect(preferences.isNotificationTypeEnabled('contract_request'), false);
      expect(preferences.isNotificationTypeEnabled('full_lobby'), false);
      expect(preferences.isNotificationTypeEnabled('general'), false);
    });

    test('should create copy with updated values', () {
      const userId = 'test-user-id';
      final originalPreferences = NotificationPreferences(
        userId: userId,
        contractNotifications: true,
        fullLobbyNotifications: true,
        generalNotifications: true,
        pushNotificationsEnabled: true,
        updatedAt: DateTime.now(),
      );

      final updatedPreferences = originalPreferences.copyWith(
        contractNotifications: false,
        fullLobbyNotifications: false,
      );

      expect(updatedPreferences.userId, userId);
      expect(updatedPreferences.contractNotifications, false);
      expect(updatedPreferences.fullLobbyNotifications, false);
      expect(updatedPreferences.generalNotifications, true);
      expect(updatedPreferences.pushNotificationsEnabled, true);
    });

    test('should serialize to and from JSON correctly', () {
      const userId = 'test-user-id';
      final originalPreferences = NotificationPreferences(
        userId: userId,
        contractNotifications: false,
        fullLobbyNotifications: true,
        generalNotifications: false,
        pushNotificationsEnabled: true,
        updatedAt: DateTime(2025, 1, 1, 12, 0, 0),
      );

      final json = originalPreferences.toJson();
      final deserializedPreferences = NotificationPreferences.fromJson(json);

      expect(deserializedPreferences.userId, originalPreferences.userId);
      expect(deserializedPreferences.contractNotifications, originalPreferences.contractNotifications);
      expect(deserializedPreferences.fullLobbyNotifications, originalPreferences.fullLobbyNotifications);
      expect(deserializedPreferences.generalNotifications, originalPreferences.generalNotifications);
      expect(deserializedPreferences.pushNotificationsEnabled, originalPreferences.pushNotificationsEnabled);
    });

    test('should serialize to and from Map correctly', () {
      const userId = 'test-user-id';
      final originalPreferences = NotificationPreferences(
        userId: userId,
        contractNotifications: false,
        fullLobbyNotifications: true,
        generalNotifications: false,
        pushNotificationsEnabled: true,
        updatedAt: DateTime(2025, 1, 1, 12, 0, 0),
      );

      final map = originalPreferences.toMap();
      final deserializedPreferences = NotificationPreferences.fromMap(map);

      expect(deserializedPreferences.userId, originalPreferences.userId);
      expect(deserializedPreferences.contractNotifications, originalPreferences.contractNotifications);
      expect(deserializedPreferences.fullLobbyNotifications, originalPreferences.fullLobbyNotifications);
      expect(deserializedPreferences.generalNotifications, originalPreferences.generalNotifications);
      expect(deserializedPreferences.pushNotificationsEnabled, originalPreferences.pushNotificationsEnabled);
    });

    test('should handle equality correctly', () {
      const userId = 'test-user-id';
      final preferences1 = NotificationPreferences(
        userId: userId,
        contractNotifications: true,
        fullLobbyNotifications: false,
        generalNotifications: true,
        pushNotificationsEnabled: true,
        updatedAt: DateTime.now(),
      );

      final preferences2 = NotificationPreferences(
        userId: userId,
        contractNotifications: true,
        fullLobbyNotifications: false,
        generalNotifications: true,
        pushNotificationsEnabled: true,
        updatedAt: DateTime.now().add(const Duration(minutes: 1)), // Different timestamp
      );

      final preferences3 = NotificationPreferences(
        userId: userId,
        contractNotifications: false, // Different value
        fullLobbyNotifications: false,
        generalNotifications: true,
        pushNotificationsEnabled: true,
        updatedAt: DateTime.now(),
      );

      expect(preferences1, equals(preferences2)); // Should be equal despite different timestamps
      expect(preferences1, isNot(equals(preferences3))); // Should not be equal due to different values
    });
  });
}
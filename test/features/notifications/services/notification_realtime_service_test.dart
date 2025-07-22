import 'package:flutter_test/flutter_test.dart';
import 'package:goalkeeper/src/features/notifications/services/notification_realtime_service.dart';
import 'package:goalkeeper/src/features/notifications/data/models/notification.dart';

void main() {
  group('NotificationRealtimeService', () {
    late NotificationRealtimeService service;

    setUp(() {
      service = NotificationRealtimeService();
    });

    tearDown(() {
      service.dispose();
    });

    group('initialization', () {
      test('should create service with initial state', () {
        // Assert
        expect(service.isInitialized, isFalse);
        expect(service.isConnected, isFalse);
        expect(service.currentUserId, isNull);
        expect(service.notificationsReceived, equals(0));
        expect(service.notificationsUpdated, equals(0));
        expect(service.lastNotificationTime, isNull);
      });
    });

    group('connection state', () {
      test('should track connection state correctly', () {
        // Arrange
        bool? connectionState;
        service.onConnectionStateChanged = (isConnected) {
          connectionState = isConnected;
        };

        // Act - simulate connection state change
        service.onConnectionStateChanged?.call(true);

        // Assert
        expect(connectionState, isTrue);
      });

      test('should provide connection statistics', () {
        // Act
        final stats = service.getStatistics();

        // Assert
        expect(stats, isA<Map<String, dynamic>>());
        expect(stats.containsKey('isConnected'), isTrue);
        expect(stats.containsKey('isInitialized'), isTrue);
        expect(stats.containsKey('currentUserId'), isTrue);
        expect(stats.containsKey('notificationsReceived'), isTrue);
        expect(stats.containsKey('notificationsUpdated'), isTrue);
        expect(stats.containsKey('lastNotificationTime'), isTrue);
        expect(stats.containsKey('reconnectionAttempts'), isTrue);
      });
    });

    group('notification handling', () {
      test('should handle notification insertion callback', () {
        // Arrange
        AppNotification? receivedNotification;
        service.onNotificationInserted = (notification) {
          receivedNotification = notification;
        };

        final testNotification = AppNotification(
          id: 'test-id',
          userId: 'user-id',
          title: 'Test Notification',
          body: 'Test body',
          type: 'test',
          sentAt: DateTime.now(),
          createdAt: DateTime.now(),
        );

        // Act
        service.onNotificationInserted?.call(testNotification);

        // Assert
        expect(receivedNotification, equals(testNotification));
      });

      test('should handle notification update callback', () {
        // Arrange
        AppNotification? updatedNotification;
        service.onNotificationUpdated = (notification) {
          updatedNotification = notification;
        };

        final testNotification = AppNotification(
          id: 'test-id',
          userId: 'user-id',
          title: 'Updated Notification',
          body: 'Updated body',
          type: 'test',
          sentAt: DateTime.now(),
          createdAt: DateTime.now(),
          readAt: DateTime.now(),
        );

        // Act
        service.onNotificationUpdated?.call(testNotification);

        // Assert
        expect(updatedNotification, equals(testNotification));
      });

      test('should handle notification deletion callback', () {
        // Arrange
        String? deletedNotificationId;
        service.onNotificationDeleted = (notificationId) {
          deletedNotificationId = notificationId;
        };

        const testId = 'deleted-notification-id';

        // Act
        service.onNotificationDeleted?.call(testId);

        // Assert
        expect(deletedNotificationId, equals(testId));
      });

      test('should handle unread count changes', () {
        // Arrange
        int? newUnreadCount;
        service.onUnreadCountChanged = (count) {
          newUnreadCount = count;
        };

        const testCount = 5;

        // Act
        service.onUnreadCountChanged?.call(testCount);

        // Assert
        expect(newUnreadCount, equals(testCount));
      });
    });

    group('statistics', () {
      test('should reset statistics correctly', () {
        // Act
        service.resetStatistics();
        final stats = service.getStatistics();

        // Assert
        expect(stats['notificationsReceived'], equals(0));
        expect(stats['notificationsUpdated'], equals(0));
        expect(stats['lastNotificationTime'], isNull);
      });

      test('should provide initial statistics', () {
        // Act
        final stats = service.getStatistics();

        // Assert
        expect(stats['isConnected'], isFalse);
        expect(stats['isInitialized'], isFalse);
        expect(stats['currentUserId'], isNull);
        expect(stats['notificationsReceived'], equals(0));
        expect(stats['notificationsUpdated'], equals(0));
        expect(stats['lastNotificationTime'], isNull);
        expect(stats['reconnectionAttempts'], equals(0));
      });
    });

    group('disposal', () {
      test('should dispose cleanly', () async {
        // Act & Assert - should not throw
        expect(() => service.dispose(), returnsNormally);
        expect(service.isInitialized, isFalse);
        expect(service.currentUserId, isNull);
      });

      test('should clear callbacks on dispose', () async {
        // Arrange
        service.onNotificationInserted = (notification) {};
        service.onNotificationUpdated = (notification) {};
        service.onNotificationDeleted = (notificationId) {};
        service.onUnreadCountChanged = (count) {};
        service.onConnectionStateChanged = (isConnected) {};

        // Act
        await service.dispose();

        // Assert - callbacks should be cleared
        expect(service.onNotificationInserted, isNull);
        expect(service.onNotificationUpdated, isNull);
        expect(service.onNotificationDeleted, isNull);
        expect(service.onUnreadCountChanged, isNull);
        expect(service.onConnectionStateChanged, isNull);
      });
    });
  });
}
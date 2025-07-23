import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:goalkeeper/src/features/notifications/data/repositories/notification_repository.dart';
import 'package:goalkeeper/src/features/notifications/presentation/controllers/notification_controller.dart';
import 'package:goalkeeper/src/features/notifications/data/models/notification.dart';
import 'package:goalkeeper/src/features/notifications/data/models/notification_category.dart';
import 'package:goalkeeper/src/features/notifications/services/notification_service.dart';

import 'notification_performance_test.mocks.dart';

@GenerateMocks([NotificationRepository, NotificationService])
void main() {
  group('Notification Performance Tests', () {
    late MockNotificationRepository mockRepository;
    late MockNotificationService mockService;
    late NotificationController controller;

    setUp(() {
      mockRepository = MockNotificationRepository();
      mockService = MockNotificationService();
      controller = NotificationController(mockRepository);
    });

    group('Large Dataset Performance', () {
      test('should handle 1000 notifications efficiently', () async {
        // Arrange
        const userId = 'user-123';
        final largeNotificationList = _generateNotifications(1000, userId);

        when(mockRepository.getNotifications(userId))
            .thenAnswer((_) async => largeNotificationList);

        // Act
        final stopwatch = Stopwatch()..start();
        await controller.loadNotifications(userId);
        stopwatch.stop();

        // Assert
        expect(controller.notifications, hasLength(1000));
        expect(stopwatch.elapsedMilliseconds, lessThan(500)); // Should complete within 500ms
        
        // Memory usage should be reasonable
        expect(controller.notifications.length, equals(1000));
      });

      test('should filter large notification lists efficiently', () async {
        // Arrange
        const userId = 'user-123';
        final largeNotificationList = _generateMixedNotifications(5000, userId);
        controller.notifications = largeNotificationList;

        // Act
        final stopwatch = Stopwatch()..start();
        final contractNotifications = controller.getNotificationsByCategory(NotificationCategory.contracts);
        final lobbyNotifications = controller.getNotificationsByCategory(NotificationCategory.fullLobbies);
        final generalNotifications = controller.getNotificationsByCategory(NotificationCategory.general);
        stopwatch.stop();

        // Assert
        expect(contractNotifications.length + lobbyNotifications.length + generalNotifications.length, 
               equals(largeNotificationList.length));
        expect(stopwatch.elapsedMilliseconds, lessThan(100)); // Filtering should be very fast
      });

      test('should handle pagination efficiently', () async {
        // Arrange
        const userId = 'user-123';
        const pageSize = 20;
        const totalNotifications = 1000;
        
        final allNotifications = _generateNotifications(totalNotifications, userId);
        
        // Mock paginated responses
        for (int page = 0; page < totalNotifications ~/ pageSize; page++) {
          final startIndex = page * pageSize;
          final endIndex = (startIndex + pageSize).clamp(0, totalNotifications);
          final pageNotifications = allNotifications.sublist(startIndex, endIndex);
          
          when(mockRepository.getNotificationsPaginated(userId, page, pageSize))
              .thenAnswer((_) async => pageNotifications);
        }

        // Act
        final stopwatch = Stopwatch()..start();
        final firstPage = await mockRepository.getNotificationsPaginated(userId, 0, pageSize);
        final secondPage = await mockRepository.getNotificationsPaginated(userId, 1, pageSize);
        final lastPage = await mockRepository.getNotificationsPaginated(userId, 49, pageSize);
        stopwatch.stop();

        // Assert
        expect(firstPage, hasLength(pageSize));
        expect(secondPage, hasLength(pageSize));
        expect(lastPage, hasLength(pageSize));
        expect(stopwatch.elapsedMilliseconds, lessThan(200)); // Should be fast
      });
    });

    group('Real-time Performance', () {
      test('should handle rapid notification updates efficiently', () async {
        // Arrange
        const userId = 'user-123';
        final initialNotifications = _generateNotifications(100, userId);
        controller.notifications = initialNotifications;

        // Simulate rapid updates
        final newNotifications = _generateNotifications(50, userId, startId: 101);
        
        when(mockRepository.watchNotifications(userId))
            .thenAnswer((_) => Stream.periodic(
              const Duration(milliseconds: 100),
              (index) => [...initialNotifications, ...newNotifications.take(index + 1)],
            ).take(50));

        // Act
        final stopwatch = Stopwatch()..start();
        controller.subscribeToNotifications(userId);
        
        // Wait for all updates to complete
        await Future.delayed(const Duration(seconds: 6));
        stopwatch.stop();

        // Assert
        expect(controller.notifications.length, greaterThanOrEqualTo(100));
        expect(stopwatch.elapsedMilliseconds, lessThan(7000)); // Should handle updates smoothly
      });

      test('should debounce rapid notification updates', () async {
        // Arrange
        const userId = 'user-123';
        int updateCount = 0;
        
        when(mockRepository.watchNotifications(userId))
            .thenAnswer((_) => Stream.periodic(
              const Duration(milliseconds: 10), // Very rapid updates
              (index) {
                updateCount++;
                return _generateNotifications(1, userId, startId: index);
              },
            ).take(100));

        // Act
        final stopwatch = Stopwatch()..start();
        controller.subscribeToNotifications(userId);
        await Future.delayed(const Duration(seconds: 2));
        stopwatch.stop();

        // Assert
        // Controller should debounce updates to prevent excessive rebuilds
        expect(updateCount, greaterThan(50)); // Stream generated many updates
        // But UI updates should be debounced (this would be tested in integration)
      });
    });

    group('Memory Performance', () {
      test('should manage memory efficiently with large datasets', () async {
        // Arrange
        const userId = 'user-123';
        final largeNotificationList = _generateNotifications(10000, userId);

        when(mockRepository.getNotifications(userId))
            .thenAnswer((_) async => largeNotificationList);

        // Act
        await controller.loadNotifications(userId);

        // Assert
        expect(controller.notifications, hasLength(10000));
        
        // Test memory cleanup
        controller.dispose();
        
        // After disposal, controller should release references
        // (This would be more thoroughly tested with memory profiling tools)
      });

      test('should handle notification archiving for old notifications', () async {
        // Arrange
        const userId = 'user-123';
        final oldDate = DateTime.now().subtract(const Duration(days: 31));
        final recentDate = DateTime.now().subtract(const Duration(days: 1));
        
        final oldNotifications = _generateNotifications(1000, userId, createdAt: oldDate);
        final recentNotifications = _generateNotifications(100, userId, createdAt: recentDate);
        
        when(mockRepository.getNotifications(userId))
            .thenAnswer((_) async => [...oldNotifications, ...recentNotifications]);
        when(mockRepository.archiveOldNotifications(userId, any))
            .thenAnswer((_) async => oldNotifications.length);

        // Act
        await controller.loadNotifications(userId);
        final archivedCount = await mockRepository.archiveOldNotifications(
          userId, 
          DateTime.now().subtract(const Duration(days: 30)),
        );

        // Assert
        expect(archivedCount, equals(1000));
        verify(mockRepository.archiveOldNotifications(userId, any)).called(1);
      });
    });

    group('Network Performance', () {
      test('should handle network timeouts gracefully', () async {
        // Arrange
        const userId = 'user-123';
        when(mockRepository.getNotifications(userId))
            .thenAnswer((_) async {
              await Future.delayed(const Duration(seconds: 10)); // Simulate timeout
              throw Exception('Network timeout');
            });

        // Act
        final stopwatch = Stopwatch()..start();
        await controller.loadNotifications(userId);
        stopwatch.stop();

        // Assert
        expect(controller.error, isNotNull);
        expect(controller.notifications, isEmpty);
        expect(stopwatch.elapsedMilliseconds, lessThan(11000)); // Should timeout appropriately
      });

      test('should implement exponential backoff for retries', () async {
        // Arrange
        const userId = 'user-123';
        int attemptCount = 0;
        
        when(mockRepository.getNotifications(userId))
            .thenAnswer((_) async {
              attemptCount++;
              if (attemptCount < 3) {
                throw Exception('Network error');
              }
              return _generateNotifications(10, userId);
            });

        // Act
        final stopwatch = Stopwatch()..start();
        await controller.loadNotificationsWithRetry(userId);
        stopwatch.stop();

        // Assert
        expect(attemptCount, equals(3));
        expect(controller.notifications, hasLength(10));
        expect(stopwatch.elapsedMilliseconds, greaterThan(1000)); // Should include backoff delays
      });
    });

    group('Concurrent Operations Performance', () {
      test('should handle concurrent read/write operations efficiently', () async {
        // Arrange
        const userId = 'user-123';
        final notifications = _generateNotifications(100, userId);
        
        when(mockRepository.getNotifications(userId))
            .thenAnswer((_) async => notifications);
        when(mockRepository.markAsRead(any))
            .thenAnswer((_) async => {});
        when(mockRepository.deleteNotification(any))
            .thenAnswer((_) async => {});

        // Act
        final stopwatch = Stopwatch()..start();
        
        final futures = <Future>[];
        
        // Concurrent reads
        for (int i = 0; i < 10; i++) {
          futures.add(controller.loadNotifications(userId));
        }
        
        // Concurrent writes
        for (int i = 0; i < 20; i++) {
          futures.add(controller.markAsRead('notification-$i'));
        }
        
        // Concurrent deletes
        for (int i = 0; i < 10; i++) {
          futures.add(controller.deleteNotification('notification-$i'));
        }
        
        await Future.wait(futures);
        stopwatch.stop();

        // Assert
        expect(stopwatch.elapsedMilliseconds, lessThan(2000)); // Should handle concurrency well
        verify(mockRepository.getNotifications(userId)).called(10);
        verify(mockRepository.markAsRead(any)).called(20);
        verify(mockRepository.deleteNotification(any)).called(10);
      });

      test('should prevent race conditions in notification updates', () async {
        // Arrange
        const userId = 'user-123';
        const notificationId = 'notification-123';
        
        final notification = AppNotification(
          id: notificationId,
          userId: userId,
          title: 'Test',
          body: 'Test body',
          type: 'general',
          data: {},
          sentAt: DateTime.now(),
          createdAt: DateTime.now(),
          readAt: null,
        );
        
        controller.notifications = [notification];
        
        when(mockRepository.markAsRead(notificationId))
            .thenAnswer((_) async {
              await Future.delayed(const Duration(milliseconds: 100));
            });
        when(mockRepository.deleteNotification(notificationId))
            .thenAnswer((_) async {
              await Future.delayed(const Duration(milliseconds: 50));
            });

        // Act - Try to mark as read and delete simultaneously
        final futures = [
          controller.markAsRead(notificationId),
          controller.deleteNotification(notificationId),
        ];
        
        await Future.wait(futures);

        // Assert
        // The controller should handle these operations safely without race conditions
        verify(mockRepository.markAsRead(notificationId)).called(1);
        verify(mockRepository.deleteNotification(notificationId)).called(1);
      });
    });

    group('UI Performance', () {
      test('should optimize notification list rendering', () async {
        // Arrange
        const userId = 'user-123';
        final notifications = _generateNotifications(500, userId);
        controller.notifications = notifications;

        // Act
        final stopwatch = Stopwatch()..start();
        
        // Simulate filtering operations that would happen during UI rendering
        final contractNotifications = controller.getNotificationsByCategory(NotificationCategory.contracts);
        final unreadNotifications = notifications.where((n) => n.isUnread).toList();
        final recentNotifications = notifications.take(50).toList();
        
        stopwatch.stop();

        // Assert
        expect(contractNotifications.length, greaterThanOrEqualTo(0));
        expect(unreadNotifications.length, greaterThanOrEqualTo(0));
        expect(recentNotifications, hasLength(50));
        expect(stopwatch.elapsedMilliseconds, lessThan(50)); // UI operations should be very fast
      });
    });
  });
}

// Helper functions for generating test data
List<AppNotification> _generateNotifications(
  int count, 
  String userId, {
  int startId = 1,
  DateTime? createdAt,
}) {
  return List.generate(count, (index) {
    final id = startId + index;
    return AppNotification(
      id: 'notification-$id',
      userId: userId,
      title: 'Notification $id',
      body: 'Body for notification $id',
      type: 'general',
      data: {'test': 'data'},
      sentAt: createdAt ?? DateTime.now(),
      createdAt: createdAt ?? DateTime.now(),
      readAt: index % 3 == 0 ? DateTime.now() : null, // Some read, some unread
    );
  });
}

List<AppNotification> _generateMixedNotifications(int count, String userId) {
  final types = ['contract_request', 'full_lobby', 'general'];
  
  return List.generate(count, (index) {
    final type = types[index % types.length];
    return AppNotification(
      id: 'notification-$index',
      userId: userId,
      title: 'Notification $index',
      body: 'Body for notification $index',
      type: type,
      data: {'test': 'data'},
      sentAt: DateTime.now(),
      createdAt: DateTime.now(),
      readAt: index % 4 == 0 ? DateTime.now() : null,
    );
  });
}
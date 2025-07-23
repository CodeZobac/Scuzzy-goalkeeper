import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:goalkeeper/src/features/notifications/presentation/controllers/notification_controller.dart';
import 'package:goalkeeper/src/features/notifications/data/repositories/notification_repository.dart';
import 'package:goalkeeper/src/features/notifications/data/models/notification.dart';
import 'package:goalkeeper/src/features/notifications/data/models/notification_category.dart';
import 'package:goalkeeper/src/features/notifications/data/models/notification_preferences.dart';

import 'notification_controller_test.mocks.dart';

@GenerateMocks([NotificationRepository])
void main() {
  group('NotificationController', () {
    late NotificationController controller;
    late MockNotificationRepository mockRepository;

    setUp(() {
      mockRepository = MockNotificationRepository();
      controller = NotificationController(mockRepository);
    });

    group('loadNotifications', () {
      test('should load notifications successfully', () async {
        // Arrange
        const userId = 'user-123';
        final mockNotifications = [
          AppNotification(
            id: 'notification-1',
            userId: userId,
            title: 'Contract Request',
            body: 'New contract available',
            type: 'contract_request',
            data: {'contract_id': 'contract-123'},
            sentAt: DateTime.now(),
            createdAt: DateTime.now(),
            readAt: null,
          ),
        ];

        when(mockRepository.getNotifications(userId))
            .thenAnswer((_) async => mockNotifications);

        // Act
        await controller.loadNotifications(userId);

        // Assert
        expect(controller.notifications, equals(mockNotifications));
        expect(controller.isLoading, false);
        verify(mockRepository.getNotifications(userId)).called(1);
      });

      test('should handle loading errors gracefully', () async {
        // Arrange
        const userId = 'user-123';
        when(mockRepository.getNotifications(userId))
            .thenThrow(Exception('Network error'));

        // Act
        await controller.loadNotifications(userId);

        // Assert
        expect(controller.notifications, isEmpty);
        expect(controller.isLoading, false);
        expect(controller.error, isNotNull);
      });

      test('should set loading state correctly', () async {
        // Arrange
        const userId = 'user-123';
        when(mockRepository.getNotifications(userId))
            .thenAnswer((_) async => []);

        // Act
        expect(controller.isLoading, false);
        final future = controller.loadNotifications(userId);
        expect(controller.isLoading, true);
        await future;
        expect(controller.isLoading, false);
      });
    });

    group('loadNotificationsByCategory', () {
      test('should load notifications by category successfully', () async {
        // Arrange
        const userId = 'user-123';
        const category = NotificationCategory.contracts;
        final mockNotifications = [
          AppNotification(
            id: 'notification-1',
            userId: userId,
            title: 'Contract Request',
            body: 'New contract available',
            type: 'contract_request',
            data: {'contract_id': 'contract-123'},
            sentAt: DateTime.now(),
            createdAt: DateTime.now(),
            readAt: null,
          ),
        ];

        when(mockRepository.getNotificationsByCategory(userId, category))
            .thenAnswer((_) async => mockNotifications);

        // Act
        await controller.loadNotificationsByCategory(userId, category);

        // Assert
        expect(controller.getNotificationsByCategory(category), equals(mockNotifications));
        verify(mockRepository.getNotificationsByCategory(userId, category)).called(1);
      });

      test('should filter notifications correctly by category', () async {
        // Arrange
        const userId = 'user-123';
        final contractNotification = AppNotification(
          id: 'notification-1',
          userId: userId,
          title: 'Contract Request',
          body: 'New contract available',
          type: 'contract_request',
          data: {'contract_id': 'contract-123'},
          sentAt: DateTime.now(),
          createdAt: DateTime.now(),
          readAt: null,
        );

        final lobbyNotification = AppNotification(
          id: 'notification-2',
          userId: userId,
          title: 'Lobby Full',
          body: 'Your announcement is full',
          type: 'full_lobby',
          data: {'announcement_id': 'announcement-456'},
          sentAt: DateTime.now(),
          createdAt: DateTime.now(),
          readAt: null,
        );

        controller.notifications = [contractNotification, lobbyNotification];

        // Act
        final contractNotifications = controller.getNotificationsByCategory(NotificationCategory.contracts);
        final lobbyNotifications = controller.getNotificationsByCategory(NotificationCategory.fullLobbies);

        // Assert
        expect(contractNotifications, hasLength(1));
        expect(contractNotifications.first.type, equals('contract_request'));
        expect(lobbyNotifications, hasLength(1));
        expect(lobbyNotifications.first.type, equals('full_lobby'));
      });
    });

    group('handleContractResponse', () {
      test('should handle contract acceptance successfully', () async {
        // Arrange
        const notificationId = 'notification-123';
        const contractId = 'contract-456';
        const accepted = true;

        when(mockRepository.handleContractResponse(
          notificationId: notificationId,
          contractId: contractId,
          accepted: accepted,
        )).thenAnswer((_) async => {});

        // Act
        await controller.handleContractResponse(notificationId, contractId, accepted);

        // Assert
        verify(mockRepository.handleContractResponse(
          notificationId: notificationId,
          contractId: contractId,
          accepted: accepted,
        )).called(1);
      });

      test('should handle contract response errors', () async {
        // Arrange
        const notificationId = 'notification-123';
        const contractId = 'contract-456';
        const accepted = true;

        when(mockRepository.handleContractResponse(
          notificationId: notificationId,
          contractId: contractId,
          accepted: accepted,
        )).thenThrow(Exception('Network error'));

        // Act & Assert
        expect(
          () => controller.handleContractResponse(notificationId, contractId, accepted),
          throwsException,
        );
      });
    });

    group('markAsRead', () {
      test('should mark notification as read successfully', () async {
        // Arrange
        const notificationId = 'notification-123';
        final notification = AppNotification(
          id: notificationId,
          userId: 'user-123',
          title: 'Test',
          body: 'Test body',
          type: 'contract_request',
          data: {},
          sentAt: DateTime.now(),
          createdAt: DateTime.now(),
          readAt: null,
        );

        controller.notifications = [notification];

        when(mockRepository.markAsRead(notificationId))
            .thenAnswer((_) async => {});

        // Act
        await controller.markAsRead(notificationId);

        // Assert
        final updatedNotification = controller.notifications
            .firstWhere((n) => n.id == notificationId);
        expect(updatedNotification.isRead, true);
        verify(mockRepository.markAsRead(notificationId)).called(1);
      });
    });

    group('deleteNotification', () {
      test('should delete notification successfully', () async {
        // Arrange
        const notificationId = 'notification-123';
        final notification = AppNotification(
          id: notificationId,
          userId: 'user-123',
          title: 'Test',
          body: 'Test body',
          type: 'contract_request',
          data: {},
          sentAt: DateTime.now(),
          createdAt: DateTime.now(),
          readAt: null,
        );

        controller.notifications = [notification];

        when(mockRepository.deleteNotification(notificationId))
            .thenAnswer((_) async => {});

        // Act
        await controller.deleteNotification(notificationId);

        // Assert
        expect(controller.notifications, isEmpty);
        verify(mockRepository.deleteNotification(notificationId)).called(1);
      });
    });

    group('getUnreadCount', () {
      test('should return correct unread count', () async {
        // Arrange
        const userId = 'user-123';
        const expectedCount = 3;

        when(mockRepository.getUnreadCount(userId))
            .thenAnswer((_) async => expectedCount);

        // Act
        final result = await controller.getUnreadCount(userId);

        // Assert
        expect(result, equals(expectedCount));
        verify(mockRepository.getUnreadCount(userId)).called(1);
      });
    });

    group('getCategoryCount', () {
      test('should return correct count for each category', () {
        // Arrange
        final contractNotification = AppNotification(
          id: 'notification-1',
          userId: 'user-123',
          title: 'Contract Request',
          body: 'New contract available',
          type: 'contract_request',
          data: {},
          sentAt: DateTime.now(),
          createdAt: DateTime.now(),
          readAt: null,
        );

        final lobbyNotification = AppNotification(
          id: 'notification-2',
          userId: 'user-123',
          title: 'Lobby Full',
          body: 'Your announcement is full',
          type: 'full_lobby',
          data: {},
          sentAt: DateTime.now(),
          createdAt: DateTime.now(),
          readAt: null,
        );

        controller.notifications = [contractNotification, lobbyNotification];

        // Act & Assert
        expect(controller.getCategoryCount(NotificationCategory.contracts), equals(1));
        expect(controller.getCategoryCount(NotificationCategory.fullLobbies), equals(1));
        expect(controller.getCategoryCount(NotificationCategory.general), equals(0));
      });
    });

    group('real-time updates', () {
      test('should handle real-time notification updates', () async {
        // Arrange
        const userId = 'user-123';
        final newNotification = AppNotification(
          id: 'notification-new',
          userId: userId,
          title: 'New Contract',
          body: 'You have a new contract request',
          type: 'contract_request',
          data: {},
          sentAt: DateTime.now(),
          createdAt: DateTime.now(),
          readAt: null,
        );

        when(mockRepository.watchNotifications(userId))
            .thenAnswer((_) => Stream.value([newNotification]));

        // Act
        controller.subscribeToNotifications(userId);
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        expect(controller.notifications, contains(newNotification));
      });
    });

    group('notification preferences', () {
      test('should update notification preferences successfully', () async {
        // Arrange
        const userId = 'user-123';
        final preferences = NotificationPreferences(
          userId: userId,
          contractNotifications: false,
          fullLobbyNotifications: true,
          generalNotifications: true,
          pushNotificationsEnabled: true,
          updatedAt: DateTime.now(),
        );

        when(mockRepository.updateNotificationPreferences(preferences))
            .thenAnswer((_) async => {});

        // Act
        await controller.updateNotificationPreferences(preferences);

        // Assert
        expect(controller.notificationPreferences, equals(preferences));
        verify(mockRepository.updateNotificationPreferences(preferences)).called(1);
      });
    });
  });
}
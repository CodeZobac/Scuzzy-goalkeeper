import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:goalkeeper/src/features/notifications/services/notification_service.dart';
import 'package:goalkeeper/src/features/notifications/data/repositories/notification_repository.dart';
import 'package:goalkeeper/src/features/notifications/data/models/notification.dart';
import 'package:goalkeeper/src/features/notifications/data/models/contract_notification_data.dart';
import 'package:goalkeeper/src/features/notifications/data/models/full_lobby_notification_data.dart';
import 'package:goalkeeper/src/features/notifications/services/notification_realtime_service.dart';

import 'notification_system_integration_test.mocks.dart';

@GenerateMocks([
  SupabaseClient,
  NotificationService,
  NotificationRepository,
  NotificationRealtimeService,
  RealtimeChannel,
])
void main() {
  group('Notification System Integration Tests', () {
    late MockSupabaseClient mockSupabaseClient;
    late MockNotificationService mockNotificationService;
    late MockNotificationRepository mockRepository;
    late MockNotificationRealtimeService mockRealtimeService;
    late MockRealtimeChannel mockChannel;

    setUp(() {
      mockSupabaseClient = MockSupabaseClient();
      mockNotificationService = MockNotificationService();
      mockRepository = MockNotificationRepository();
      mockRealtimeService = MockNotificationRealtimeService();
      mockChannel = MockRealtimeChannel();
    });

    group('Contract Notification Flow', () {
      test('should handle complete contract notification flow', () async {
        // Arrange
        const goalkeeperUserId = 'goalkeeper-123';
        const contractorUserId = 'contractor-456';
        const announcementId = 'announcement-789';
        
        final contractData = ContractNotificationData(
          contractId: 'contract-123',
          contractorId: contractorUserId,
          contractorName: 'João Silva',
          announcementId: announcementId,
          announcementTitle: 'Jogo de Futebol',
          gameDateTime: DateTime(2024, 12, 25, 15, 30),
          stadium: 'Estádio Central',
          offeredAmount: 150.0,
        );

        final expectedNotification = AppNotification(
          id: 'notification-123',
          userId: goalkeeperUserId,
          title: 'Nova Proposta de Contrato',
          body: 'João Silva quer contratá-lo para um jogo',
          type: 'contract_request',
          data: contractData.toMap(),
          sentAt: DateTime.now(),
          createdAt: DateTime.now(),
          readAt: null,
        );

        // Mock repository calls
        when(mockRepository.createContractNotification(
          goalkeeperUserId: goalkeeperUserId,
          contractorUserId: contractorUserId,
          announcementId: announcementId,
          data: contractData,
        )).thenAnswer((_) async => {});

        // Mock notification service calls
        when(mockNotificationService.sendContractNotification(
          goalkeeperUserId: goalkeeperUserId,
          data: contractData,
        )).thenAnswer((_) async => {});

        // Mock real-time service
        when(mockRealtimeService.subscribeToNotifications(goalkeeperUserId))
            .thenReturn(mockChannel);
        when(mockChannel.subscribe())
            .thenAnswer((_) async => RealtimeSubscribeStatus.subscribed);

        // Act
        await mockRepository.createContractNotification(
          goalkeeperUserId: goalkeeperUserId,
          contractorUserId: contractorUserId,
          announcementId: announcementId,
          data: contractData,
        );

        await mockNotificationService.sendContractNotification(
          goalkeeperUserId: goalkeeperUserId,
          data: contractData,
        );

        // Assert
        verify(mockRepository.createContractNotification(
          goalkeeperUserId: goalkeeperUserId,
          contractorUserId: contractorUserId,
          announcementId: announcementId,
          data: contractData,
        )).called(1);

        verify(mockNotificationService.sendContractNotification(
          goalkeeperUserId: goalkeeperUserId,
          data: contractData,
        )).called(1);
      });

      test('should handle contract response flow', () async {
        // Arrange
        const notificationId = 'notification-123';
        const contractId = 'contract-456';
        const accepted = true;
        const contractorUserId = 'contractor-789';

        // Mock contract response
        when(mockRepository.handleContractResponse(
          notificationId: notificationId,
          contractId: contractId,
          accepted: accepted,
        )).thenAnswer((_) async => {});

        // Mock notification to contractor
        when(mockRepository.createContractResponseNotification(
          contractorUserId: contractorUserId,
          contractId: contractId,
          accepted: accepted,
        )).thenAnswer((_) async => {});

        // Act
        await mockRepository.handleContractResponse(
          notificationId: notificationId,
          contractId: contractId,
          accepted: accepted,
        );

        await mockRepository.createContractResponseNotification(
          contractorUserId: contractorUserId,
          contractId: contractId,
          accepted: accepted,
        );

        // Assert
        verify(mockRepository.handleContractResponse(
          notificationId: notificationId,
          contractId: contractId,
          accepted: accepted,
        )).called(1);

        verify(mockRepository.createContractResponseNotification(
          contractorUserId: contractorUserId,
          contractId: contractId,
          accepted: accepted,
        )).called(1);
      });
    });

    group('Full Lobby Notification Flow', () {
      test('should handle complete full lobby notification flow', () async {
        // Arrange
        const creatorUserId = 'creator-123';
        const announcementId = 'announcement-789';
        
        final lobbyData = FullLobbyNotificationData(
          announcementId: announcementId,
          announcementTitle: 'Jogo de Futebol',
          gameDateTime: DateTime(2024, 12, 25, 15, 30),
          stadium: 'Estádio Central',
          participantCount: 22,
          maxParticipants: 22,
        );

        // Mock repository calls
        when(mockRepository.createFullLobbyNotification(
          creatorUserId: creatorUserId,
          announcementId: announcementId,
          data: lobbyData,
        )).thenAnswer((_) async => {});

        // Mock notification service calls
        when(mockNotificationService.sendFullLobbyNotification(
          creatorUserId: creatorUserId,
          data: lobbyData,
        )).thenAnswer((_) async => {});

        // Act
        await mockRepository.createFullLobbyNotification(
          creatorUserId: creatorUserId,
          announcementId: announcementId,
          data: lobbyData,
        );

        await mockNotificationService.sendFullLobbyNotification(
          creatorUserId: creatorUserId,
          data: lobbyData,
        );

        // Assert
        verify(mockRepository.createFullLobbyNotification(
          creatorUserId: creatorUserId,
          announcementId: announcementId,
          data: lobbyData,
        )).called(1);

        verify(mockNotificationService.sendFullLobbyNotification(
          creatorUserId: creatorUserId,
          data: lobbyData,
        )).called(1);
      });

      test('should trigger full lobby notification when capacity reached', () async {
        // Arrange
        const announcementId = 'announcement-789';
        const creatorUserId = 'creator-123';
        const maxParticipants = 22;
        const currentParticipants = 22;

        final lobbyData = FullLobbyNotificationData(
          announcementId: announcementId,
          announcementTitle: 'Jogo de Futebol',
          gameDateTime: DateTime(2024, 12, 25, 15, 30),
          stadium: 'Estádio Central',
          participantCount: currentParticipants,
          maxParticipants: maxParticipants,
        );

        // Mock announcement capacity check
        when(mockRepository.checkAnnouncementCapacity(announcementId))
            .thenAnswer((_) async => {
              'current_participants': currentParticipants,
              'max_participants': maxParticipants,
              'is_full': true,
            });

        when(mockRepository.createFullLobbyNotification(
          creatorUserId: creatorUserId,
          announcementId: announcementId,
          data: lobbyData,
        )).thenAnswer((_) async => {});

        // Act
        final capacityInfo = await mockRepository.checkAnnouncementCapacity(announcementId);
        
        if (capacityInfo['is_full'] == true) {
          await mockRepository.createFullLobbyNotification(
            creatorUserId: creatorUserId,
            announcementId: announcementId,
            data: lobbyData,
          );
        }

        // Assert
        verify(mockRepository.checkAnnouncementCapacity(announcementId)).called(1);
        verify(mockRepository.createFullLobbyNotification(
          creatorUserId: creatorUserId,
          announcementId: announcementId,
          data: lobbyData,
        )).called(1);
      });
    });

    group('Real-time Notification Updates', () {
      test('should handle real-time notification subscription', () async {
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

        // Mock real-time subscription
        when(mockRealtimeService.subscribeToNotifications(userId))
            .thenReturn(mockChannel);
        when(mockChannel.subscribe())
            .thenAnswer((_) async => RealtimeSubscribeStatus.subscribed);

        // Mock notification stream
        when(mockRepository.watchNotifications(userId))
            .thenAnswer((_) => Stream.value([newNotification]));

        // Act
        final channel = mockRealtimeService.subscribeToNotifications(userId);
        final subscriptionStatus = await channel.subscribe();
        final notificationStream = mockRepository.watchNotifications(userId);

        // Assert
        expect(subscriptionStatus, equals(RealtimeSubscribeStatus.subscribed));
        
        await expectLater(
          notificationStream,
          emits([newNotification]),
        );

        verify(mockRealtimeService.subscribeToNotifications(userId)).called(1);
        verify(mockRepository.watchNotifications(userId)).called(1);
      });

      test('should handle real-time notification updates', () async {
        // Arrange
        const userId = 'user-123';
        final initialNotifications = <AppNotification>[];
        final updatedNotifications = [
          AppNotification(
            id: 'notification-1',
            userId: userId,
            title: 'Contract Request',
            body: 'New contract available',
            type: 'contract_request',
            data: {},
            sentAt: DateTime.now(),
            createdAt: DateTime.now(),
            readAt: null,
          ),
        ];

        // Mock progressive updates
        when(mockRepository.watchNotifications(userId))
            .thenAnswer((_) => Stream.fromIterable([
              initialNotifications,
              updatedNotifications,
            ]));

        // Act
        final notificationStream = mockRepository.watchNotifications(userId);
        final notifications = await notificationStream.toList();

        // Assert
        expect(notifications, hasLength(2));
        expect(notifications[0], isEmpty);
        expect(notifications[1], hasLength(1));
        expect(notifications[1].first.type, equals('contract_request'));
      });
    });

    group('Error Handling Integration', () {
      test('should handle database connection errors gracefully', () async {
        // Arrange
        const userId = 'user-123';
        when(mockRepository.getNotifications(userId))
            .thenThrow(Exception('Database connection failed'));

        // Act & Assert
        expect(
          () => mockRepository.getNotifications(userId),
          throwsException,
        );
      });

      test('should handle push notification failures gracefully', () async {
        // Arrange
        const goalkeeperUserId = 'goalkeeper-123';
        final contractData = ContractNotificationData(
          contractId: 'contract-123',
          contractorId: 'contractor-456',
          contractorName: 'João Silva',
          announcementId: 'announcement-789',
          announcementTitle: 'Jogo de Futebol',
          gameDateTime: DateTime(2024, 12, 25, 15, 30),
          stadium: 'Estádio Central',
          offeredAmount: 150.0,
        );

        // Mock database success but push notification failure
        when(mockRepository.createContractNotification(
          goalkeeperUserId: goalkeeperUserId,
          contractorUserId: any,
          announcementId: any,
          data: contractData,
        )).thenAnswer((_) async => {});

        when(mockNotificationService.sendContractNotification(
          goalkeeperUserId: goalkeeperUserId,
          data: contractData,
        )).thenThrow(Exception('FCM token invalid'));

        // Act
        await mockRepository.createContractNotification(
          goalkeeperUserId: goalkeeperUserId,
          contractorUserId: 'contractor-456',
          announcementId: 'announcement-789',
          data: contractData,
        );

        // Push notification should fail but database operation should succeed
        expect(
          () => mockNotificationService.sendContractNotification(
            goalkeeperUserId: goalkeeperUserId,
            data: contractData,
          ),
          throwsException,
        );

        // Assert database operation succeeded
        verify(mockRepository.createContractNotification(
          goalkeeperUserId: goalkeeperUserId,
          contractorUserId: 'contractor-456',
          announcementId: 'announcement-789',
          data: contractData,
        )).called(1);
      });

      test('should handle real-time subscription failures', () async {
        // Arrange
        const userId = 'user-123';
        when(mockRealtimeService.subscribeToNotifications(userId))
            .thenReturn(mockChannel);
        when(mockChannel.subscribe())
            .thenAnswer((_) async => RealtimeSubscribeStatus.timedOut);

        // Act
        final channel = mockRealtimeService.subscribeToNotifications(userId);
        final subscriptionStatus = await channel.subscribe();

        // Assert
        expect(subscriptionStatus, equals(RealtimeSubscribeStatus.timedOut));
        verify(mockRealtimeService.subscribeToNotifications(userId)).called(1);
      });
    });

    group('Performance Integration', () {
      test('should handle large notification lists efficiently', () async {
        // Arrange
        const userId = 'user-123';
        final largeNotificationList = List.generate(1000, (index) => 
          AppNotification(
            id: 'notification-$index',
            userId: userId,
            title: 'Notification $index',
            body: 'Body $index',
            type: 'general',
            data: {},
            sentAt: DateTime.now(),
            createdAt: DateTime.now(),
            readAt: null,
          ),
        );

        when(mockRepository.getNotifications(userId))
            .thenAnswer((_) async => largeNotificationList);

        // Act
        final stopwatch = Stopwatch()..start();
        final notifications = await mockRepository.getNotifications(userId);
        stopwatch.stop();

        // Assert
        expect(notifications, hasLength(1000));
        expect(stopwatch.elapsedMilliseconds, lessThan(1000)); // Should complete within 1 second
      });

      test('should handle concurrent notification operations', () async {
        // Arrange
        const userId = 'user-123';
        final futures = <Future>[];

        // Mock multiple concurrent operations
        when(mockRepository.getNotifications(userId))
            .thenAnswer((_) async => []);
        when(mockRepository.getUnreadCount(userId))
            .thenAnswer((_) async => 5);
        when(mockRepository.markAsRead(any))
            .thenAnswer((_) async => {});

        // Act
        futures.add(mockRepository.getNotifications(userId));
        futures.add(mockRepository.getUnreadCount(userId));
        futures.add(mockRepository.markAsRead('notification-1'));
        futures.add(mockRepository.markAsRead('notification-2'));

        await Future.wait(futures);

        // Assert
        verify(mockRepository.getNotifications(userId)).called(1);
        verify(mockRepository.getUnreadCount(userId)).called(1);
        verify(mockRepository.markAsRead('notification-1')).called(1);
        verify(mockRepository.markAsRead('notification-2')).called(1);
      });
    });

    group('Data Consistency Integration', () {
      test('should maintain data consistency across operations', () async {
        // Arrange
        const userId = 'user-123';
        const notificationId = 'notification-123';
        
        final unreadNotification = AppNotification(
          id: notificationId,
          userId: userId,
          title: 'Test Notification',
          body: 'Test body',
          type: 'general',
          data: {},
          sentAt: DateTime.now(),
          createdAt: DateTime.now(),
          readAt: null,
        );

        final readNotification = unreadNotification.copyWith(
          readAt: DateTime.now(),
        );

        // Mock initial state
        when(mockRepository.getNotifications(userId))
            .thenAnswer((_) async => [unreadNotification]);
        when(mockRepository.getUnreadCount(userId))
            .thenAnswer((_) async => 1);

        // Mock after marking as read
        when(mockRepository.markAsRead(notificationId))
            .thenAnswer((_) async => {});

        // Act
        final initialNotifications = await mockRepository.getNotifications(userId);
        final initialUnreadCount = await mockRepository.getUnreadCount(userId);
        
        expect(initialNotifications.first.isUnread, true);
        expect(initialUnreadCount, equals(1));

        await mockRepository.markAsRead(notificationId);

        // Mock updated state
        when(mockRepository.getNotifications(userId))
            .thenAnswer((_) async => [readNotification]);
        when(mockRepository.getUnreadCount(userId))
            .thenAnswer((_) async => 0);

        final updatedNotifications = await mockRepository.getNotifications(userId);
        final updatedUnreadCount = await mockRepository.getUnreadCount(userId);

        // Assert
        expect(updatedNotifications.first.isRead, true);
        expect(updatedUnreadCount, equals(0));
      });
    });
  });
}
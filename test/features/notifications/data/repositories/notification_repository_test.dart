import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:goalkeeper/src/features/notifications/data/repositories/notification_repository.dart';
import 'package:goalkeeper/src/features/notifications/data/models/notification.dart';
import 'package:goalkeeper/src/features/notifications/data/models/contract_notification_data.dart';
import 'package:goalkeeper/src/features/notifications/data/models/full_lobby_notification_data.dart';
import 'package:goalkeeper/src/features/notifications/data/models/notification_category.dart';

import 'notification_repository_test.mocks.dart';

@GenerateMocks([SupabaseClient, SupabaseQueryBuilder, PostgrestFilterBuilder])
void main() {
  group('NotificationRepository', () {
    late NotificationRepository repository;
    late MockSupabaseClient mockSupabaseClient;
    late MockSupabaseQueryBuilder mockQueryBuilder;
    late MockPostgrestFilterBuilder mockFilterBuilder;

    setUp(() {
      mockSupabaseClient = MockSupabaseClient();
      mockQueryBuilder = MockSupabaseQueryBuilder();
      mockFilterBuilder = MockPostgrestFilterBuilder();
      repository = NotificationRepositoryImpl(mockSupabaseClient);
    });

    group('createContractNotification', () {
      test('should create contract notification successfully', () async {
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

        when(mockSupabaseClient.from('notifications'))
            .thenReturn(mockQueryBuilder);
        when(mockQueryBuilder.insert(any))
            .thenAnswer((_) async => null);

        // Act
        await repository.createContractNotification(
          goalkeeperUserId: goalkeeperUserId,
          contractorUserId: contractorUserId,
          announcementId: announcementId,
          data: contractData,
        );

        // Assert
        verify(mockSupabaseClient.from('notifications')).called(1);
        verify(mockQueryBuilder.insert(any)).called(1);
      });

      test('should handle database errors gracefully', () async {
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

        when(mockSupabaseClient.from('notifications'))
            .thenReturn(mockQueryBuilder);
        when(mockQueryBuilder.insert(any))
            .thenThrow(Exception('Database error'));

        // Act & Assert
        expect(
          () => repository.createContractNotification(
            goalkeeperUserId: goalkeeperUserId,
            contractorUserId: contractorUserId,
            announcementId: announcementId,
            data: contractData,
          ),
          throwsException,
        );
      });
    });

    group('createFullLobbyNotification', () {
      test('should create full lobby notification successfully', () async {
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

        when(mockSupabaseClient.from('notifications'))
            .thenReturn(mockQueryBuilder);
        when(mockQueryBuilder.insert(any))
            .thenAnswer((_) async => null);

        // Act
        await repository.createFullLobbyNotification(
          creatorUserId: creatorUserId,
          announcementId: announcementId,
          data: lobbyData,
        );

        // Assert
        verify(mockSupabaseClient.from('notifications')).called(1);
        verify(mockQueryBuilder.insert(any)).called(1);
      });
    });

    group('getNotificationsByCategory', () {
      test('should return notifications filtered by category', () async {
        // Arrange
        const userId = 'user-123';
        const category = NotificationCategory.contracts;
        
        final mockNotifications = [
          {
            'id': 'notification-1',
            'user_id': userId,
            'title': 'Contract Request',
            'body': 'New contract available',
            'type': 'contract_request',
            'category': 'contracts',
            'data': {'contract_id': 'contract-123'},
            'sent_at': DateTime.now().toIso8601String(),
            'created_at': DateTime.now().toIso8601String(),
            'read_at': null,
          }
        ];

        when(mockSupabaseClient.from('notifications'))
            .thenReturn(mockQueryBuilder);
        when(mockQueryBuilder.select())
            .thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.eq('user_id', userId))
            .thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.eq('category', category.name))
            .thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.order('created_at', ascending: false))
            .thenAnswer((_) async => mockNotifications);

        // Act
        final result = await repository.getNotificationsByCategory(userId, category);

        // Assert
        expect(result, hasLength(1));
        expect(result.first.type, equals('contract_request'));
        verify(mockSupabaseClient.from('notifications')).called(1);
      });

      test('should return empty list when no notifications found', () async {
        // Arrange
        const userId = 'user-123';
        const category = NotificationCategory.contracts;

        when(mockSupabaseClient.from('notifications'))
            .thenReturn(mockQueryBuilder);
        when(mockQueryBuilder.select())
            .thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.eq('user_id', userId))
            .thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.eq('category', category.name))
            .thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.order('created_at', ascending: false))
            .thenAnswer((_) async => <Map<String, dynamic>>[]);

        // Act
        final result = await repository.getNotificationsByCategory(userId, category);

        // Assert
        expect(result, isEmpty);
      });
    });

    group('handleContractResponse', () {
      test('should handle contract acceptance successfully', () async {
        // Arrange
        const notificationId = 'notification-123';
        const contractId = 'contract-456';
        const accepted = true;

        when(mockSupabaseClient.from('notifications'))
            .thenReturn(mockQueryBuilder);
        when(mockQueryBuilder.update(any))
            .thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.eq('id', notificationId))
            .thenAnswer((_) async => null);

        when(mockSupabaseClient.from('goalkeeper_contracts'))
            .thenReturn(mockQueryBuilder);
        when(mockQueryBuilder.update(any))
            .thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.eq('id', contractId))
            .thenAnswer((_) async => null);

        // Act
        await repository.handleContractResponse(
          notificationId: notificationId,
          contractId: contractId,
          accepted: accepted,
        );

        // Assert
        verify(mockSupabaseClient.from('notifications')).called(1);
        verify(mockSupabaseClient.from('goalkeeper_contracts')).called(1);
      });

      test('should handle contract decline successfully', () async {
        // Arrange
        const notificationId = 'notification-123';
        const contractId = 'contract-456';
        const accepted = false;

        when(mockSupabaseClient.from('notifications'))
            .thenReturn(mockQueryBuilder);
        when(mockQueryBuilder.update(any))
            .thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.eq('id', notificationId))
            .thenAnswer((_) async => null);

        when(mockSupabaseClient.from('goalkeeper_contracts'))
            .thenReturn(mockQueryBuilder);
        when(mockQueryBuilder.update(any))
            .thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.eq('id', contractId))
            .thenAnswer((_) async => null);

        // Act
        await repository.handleContractResponse(
          notificationId: notificationId,
          contractId: contractId,
          accepted: accepted,
        );

        // Assert
        verify(mockSupabaseClient.from('notifications')).called(1);
        verify(mockSupabaseClient.from('goalkeeper_contracts')).called(1);
      });
    });

    group('watchNotifications', () {
      test('should return stream of notifications', () async {
        // Arrange
        const userId = 'user-123';
        
        // This would typically test the real-time subscription
        // For now, we verify the method exists and can be called
        
        // Act & Assert
        expect(
          () => repository.watchNotifications(userId),
          returnsNormally,
        );
      });
    });

    group('markAsRead', () {
      test('should mark notification as read successfully', () async {
        // Arrange
        const notificationId = 'notification-123';

        when(mockSupabaseClient.from('notifications'))
            .thenReturn(mockQueryBuilder);
        when(mockQueryBuilder.update(any))
            .thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.eq('id', notificationId))
            .thenAnswer((_) async => null);

        // Act
        await repository.markAsRead(notificationId);

        // Assert
        verify(mockSupabaseClient.from('notifications')).called(1);
        verify(mockQueryBuilder.update(any)).called(1);
      });
    });

    group('deleteNotification', () {
      test('should delete notification successfully', () async {
        // Arrange
        const notificationId = 'notification-123';

        when(mockSupabaseClient.from('notifications'))
            .thenReturn(mockQueryBuilder);
        when(mockQueryBuilder.delete())
            .thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.eq('id', notificationId))
            .thenAnswer((_) async => null);

        // Act
        await repository.deleteNotification(notificationId);

        // Assert
        verify(mockSupabaseClient.from('notifications')).called(1);
        verify(mockQueryBuilder.delete()).called(1);
      });
    });

    group('getUnreadCount', () {
      test('should return correct unread count', () async {
        // Arrange
        const userId = 'user-123';
        const expectedCount = 5;

        when(mockSupabaseClient.from('notifications'))
            .thenReturn(mockQueryBuilder);
        when(mockQueryBuilder.select('id', const FetchOptions(count: CountOption.exact)))
            .thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.eq('user_id', userId))
            .thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.isFilter('read_at', null))
            .thenAnswer((_) async => PostgrestResponse(
              data: [],
              count: expectedCount,
              status: 200,
            ));

        // Act
        final result = await repository.getUnreadCount(userId);

        // Assert
        expect(result, equals(expectedCount));
      });
    });
  });
}
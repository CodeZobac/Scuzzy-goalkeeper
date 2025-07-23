import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:goalkeeper/src/features/notifications/services/full_lobby_detection_service.dart';
import 'package:goalkeeper/src/features/notifications/data/repositories/notification_repository.dart';
import 'package:goalkeeper/src/features/notifications/data/models/full_lobby_notification_data.dart';

import 'full_lobby_detection_service_test.mocks.dart';

@GenerateMocks([
  NotificationRepository,
  SupabaseClient,
  SupabaseQueryBuilder,
  PostgrestFilterBuilder,
  RealtimeChannel,
])
void main() {
  group('FullLobbyDetectionService', () {
    late FullLobbyDetectionService service;
    late MockNotificationRepository mockNotificationRepository;
    late MockSupabaseClient mockSupabaseClient;
    late MockSupabaseQueryBuilder mockQueryBuilder;
    late MockPostgrestFilterBuilder mockFilterBuilder;
    late MockRealtimeChannel mockChannel;

    setUp(() {
      mockNotificationRepository = MockNotificationRepository();
      mockSupabaseClient = MockSupabaseClient();
      mockQueryBuilder = MockSupabaseQueryBuilder();
      mockFilterBuilder = MockPostgrestFilterBuilder();
      mockChannel = MockRealtimeChannel();

      // Mock Supabase.instance.client
      when(mockSupabaseClient.from(any)).thenReturn(mockQueryBuilder);
      when(mockSupabaseClient.channel(any)).thenReturn(mockChannel);
      
      service = FullLobbyDetectionService(mockNotificationRepository);
    });

    group('initialization', () {
      test('should initialize successfully', () async {
        // Mock existing notifications query
        when(mockQueryBuilder.select(any)).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.eq(any, any)).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.then()).thenAnswer((_) async => []);

        // Mock channel setup
        when(mockChannel.onPostgresChanges(
          event: anyNamed('event'),
          schema: anyNamed('schema'),
          table: anyNamed('table'),
          callback: anyNamed('callback'),
        )).thenReturn(mockChannel);
        when(mockChannel.subscribe()).thenAnswer((_) async => RealtimeSubscribeStatus.subscribed);

        await service.initialize();

        verify(mockQueryBuilder.select('data')).called(1);
        verify(mockFilterBuilder.eq('type', 'full_lobby')).called(1);
        verify(mockChannel.subscribe()).called(1);
      });

      test('should load existing full lobbies to prevent duplicates', () async {
        final existingNotifications = [
          {
            'data': {
              'announcement_id': '123',
            }
          },
          {
            'data': {
              'announcement_id': '456',
            }
          }
        ];

        when(mockQueryBuilder.select(any)).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.eq(any, any)).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.then()).thenAnswer((_) async => existingNotifications);

        // Mock channel setup
        when(mockChannel.onPostgresChanges(
          event: anyNamed('event'),
          schema: anyNamed('schema'),
          table: anyNamed('table'),
          callback: anyNamed('callback'),
        )).thenReturn(mockChannel);
        when(mockChannel.subscribe()).thenAnswer((_) async => RealtimeSubscribeStatus.subscribed);

        await service.initialize();

        expect(service.isAnnouncementProcessed(123), isTrue);
        expect(service.isAnnouncementProcessed(456), isTrue);
        expect(service.isAnnouncementProcessed(789), isFalse);
      });
    });

    group('announcement capacity checking', () {
      test('should detect when announcement reaches full capacity', () async {
        final announcementData = {
          'id': 123,
          'created_by': 'user123',
          'title': 'Test Game',
          'date': '2024-01-15',
          'time': '18:00',
          'stadium': 'Test Stadium',
          'max_participants': 22,
        };

        final participantData = List.generate(22, (index) => {'user_id': 'user$index'});

        // Mock announcement query
        when(mockQueryBuilder.select(any)).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.eq('id', 123)).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.single()).thenAnswer((_) async => announcementData);

        // Mock participant query
        final mockParticipantQueryBuilder = MockSupabaseQueryBuilder();
        final mockParticipantFilterBuilder = MockPostgrestFilterBuilder();
        
        when(mockSupabaseClient.from('announcement_participants')).thenReturn(mockParticipantQueryBuilder);
        when(mockParticipantQueryBuilder.select('user_id')).thenReturn(mockParticipantFilterBuilder);
        when(mockParticipantFilterBuilder.eq('announcement_id', 123)).thenReturn(mockParticipantFilterBuilder);
        when(mockParticipantFilterBuilder.then()).thenAnswer((_) async => participantData);

        // Mock notification creation
        when(mockNotificationRepository.createFullLobbyNotification(
          creatorUserId: anyNamed('creatorUserId'),
          announcementId: anyNamed('announcementId'),
          data: anyNamed('data'),
        )).thenAnswer((_) async {});

        // Mock FCM tokens query
        final mockFcmQueryBuilder = MockSupabaseQueryBuilder();
        final mockFcmFilterBuilder = MockPostgrestFilterBuilder();
        
        when(mockSupabaseClient.from('fcm_tokens')).thenReturn(mockFcmQueryBuilder);
        when(mockFcmQueryBuilder.select('token')).thenReturn(mockFcmFilterBuilder);
        when(mockFcmFilterBuilder.eq('user_id', 'user123')).thenReturn(mockFcmFilterBuilder);
        when(mockFcmFilterBuilder.eq('is_active', true)).thenReturn(mockFcmFilterBuilder);
        when(mockFcmFilterBuilder.then()).thenAnswer((_) async => []);

        await service.checkAnnouncement(123);

        verify(mockNotificationRepository.createFullLobbyNotification(
          creatorUserId: 'user123',
          announcementId: '123',
          data: any,
        )).called(1);

        expect(service.isAnnouncementProcessed(123), isTrue);
        expect(service.getAnnouncementStatus(123), equals(AnnouncementStatus.full));
      });

      test('should not trigger notification if announcement is not full', () async {
        final announcementData = {
          'id': 123,
          'created_by': 'user123',
          'title': 'Test Game',
          'date': '2024-01-15',
          'time': '18:00',
          'stadium': 'Test Stadium',
          'max_participants': 22,
        };

        final participantData = List.generate(15, (index) => {'user_id': 'user$index'});

        // Mock announcement query
        when(mockQueryBuilder.select(any)).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.eq('id', 123)).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.single()).thenAnswer((_) async => announcementData);

        // Mock participant query
        final mockParticipantQueryBuilder = MockSupabaseQueryBuilder();
        final mockParticipantFilterBuilder = MockPostgrestFilterBuilder();
        
        when(mockSupabaseClient.from('announcement_participants')).thenReturn(mockParticipantQueryBuilder);
        when(mockParticipantQueryBuilder.select('user_id')).thenReturn(mockParticipantFilterBuilder);
        when(mockParticipantFilterBuilder.eq('announcement_id', 123)).thenReturn(mockParticipantFilterBuilder);
        when(mockParticipantFilterBuilder.then()).thenAnswer((_) async => participantData);

        await service.checkAnnouncement(123);

        verifyNever(mockNotificationRepository.createFullLobbyNotification(
          creatorUserId: anyNamed('creatorUserId'),
          announcementId: anyNamed('announcementId'),
          data: anyNamed('data'),
        ));

        expect(service.isAnnouncementProcessed(123), isFalse);
        expect(service.getAnnouncementStatus(123), equals(AnnouncementStatus.active));
      });

      test('should prevent duplicate notifications for same announcement', () async {
        final announcementData = {
          'id': 123,
          'created_by': 'user123',
          'title': 'Test Game',
          'date': '2024-01-15',
          'time': '18:00',
          'stadium': 'Test Stadium',
          'max_participants': 22,
        };

        final participantData = List.generate(22, (index) => {'user_id': 'user$index'});

        // Mock announcement query
        when(mockQueryBuilder.select(any)).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.eq('id', 123)).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.single()).thenAnswer((_) async => announcementData);

        // Mock participant query
        final mockParticipantQueryBuilder = MockSupabaseQueryBuilder();
        final mockParticipantFilterBuilder = MockPostgrestFilterBuilder();
        
        when(mockSupabaseClient.from('announcement_participants')).thenReturn(mockParticipantQueryBuilder);
        when(mockParticipantQueryBuilder.select('user_id')).thenReturn(mockParticipantFilterBuilder);
        when(mockParticipantFilterBuilder.eq('announcement_id', 123)).thenReturn(mockParticipantFilterBuilder);
        when(mockParticipantFilterBuilder.then()).thenAnswer((_) async => participantData);

        // Mock notification creation
        when(mockNotificationRepository.createFullLobbyNotification(
          creatorUserId: anyNamed('creatorUserId'),
          announcementId: anyNamed('announcementId'),
          data: anyNamed('data'),
        )).thenAnswer((_) async {});

        // Mock FCM tokens query
        final mockFcmQueryBuilder = MockSupabaseQueryBuilder();
        final mockFcmFilterBuilder = MockPostgrestFilterBuilder();
        
        when(mockSupabaseClient.from('fcm_tokens')).thenReturn(mockFcmQueryBuilder);
        when(mockFcmQueryBuilder.select('token')).thenReturn(mockFcmFilterBuilder);
        when(mockFcmFilterBuilder.eq('user_id', 'user123')).thenReturn(mockFcmFilterBuilder);
        when(mockFcmFilterBuilder.eq('is_active', true)).thenReturn(mockFcmFilterBuilder);
        when(mockFcmFilterBuilder.then()).thenAnswer((_) async => []);

        // First call should trigger notification
        await service.checkAnnouncement(123);
        
        // Second call should not trigger notification
        await service.checkAnnouncement(123);

        verify(mockNotificationRepository.createFullLobbyNotification(
          creatorUserId: anyNamed('creatorUserId'),
          announcementId: anyNamed('announcementId'),
          data: anyNamed('data'),
        )).called(1); // Should only be called once
      });
    });

    group('statistics and status tracking', () {
      test('should provide accurate statistics', () async {
        // Mock some processed announcements
        service.isAnnouncementProcessed(123); // This will be false initially
        
        final stats = service.getStatistics();
        
        expect(stats['processed_full_lobbies'], isA<int>());
        expect(stats['tracked_announcements'], isA<int>());
        expect(stats['full_announcements'], isA<int>());
        expect(stats['active_announcements'], isA<int>());
      });

      test('should track announcement status correctly', () {
        expect(service.getAnnouncementStatus(123), isNull);
        expect(service.isAnnouncementProcessed(123), isFalse);
      });
    });

    group('error handling', () {
      test('should handle database errors gracefully', () async {
        when(mockQueryBuilder.select(any)).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.eq('id', 123)).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.single()).thenThrow(Exception('Database error'));

        // Should not throw, but handle error gracefully
        await service.checkAnnouncement(123);
        
        expect(service.isAnnouncementProcessed(123), isFalse);
      });

      test('should handle notification creation errors gracefully', () async {
        final announcementData = {
          'id': 123,
          'created_by': 'user123',
          'title': 'Test Game',
          'date': '2024-01-15',
          'time': '18:00',
          'stadium': 'Test Stadium',
          'max_participants': 22,
        };

        final participantData = List.generate(22, (index) => {'user_id': 'user$index'});

        // Mock announcement query
        when(mockQueryBuilder.select(any)).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.eq('id', 123)).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.single()).thenAnswer((_) async => announcementData);

        // Mock participant query
        final mockParticipantQueryBuilder = MockSupabaseQueryBuilder();
        final mockParticipantFilterBuilder = MockPostgrestFilterBuilder();
        
        when(mockSupabaseClient.from('announcement_participants')).thenReturn(mockParticipantQueryBuilder);
        when(mockParticipantQueryBuilder.select('user_id')).thenReturn(mockParticipantFilterBuilder);
        when(mockParticipantFilterBuilder.eq('announcement_id', 123)).thenReturn(mockParticipantFilterBuilder);
        when(mockParticipantFilterBuilder.then()).thenAnswer((_) async => participantData);

        // Mock notification creation to throw error
        when(mockNotificationRepository.createFullLobbyNotification(
          creatorUserId: anyNamed('creatorUserId'),
          announcementId: anyNamed('announcementId'),
          data: anyNamed('data'),
        )).thenThrow(Exception('Notification creation failed'));

        // Should throw the error from notification creation
        expect(
          () => service.checkAnnouncement(123),
          throwsException,
        );
      });
    });

    group('disposal', () {
      test('should dispose resources properly', () {
        when(mockChannel.unsubscribe()).thenAnswer((_) async => RealtimeSubscribeStatus.closed);
        
        service.dispose();
        
        // Should not throw when disposed
        expect(() => service.dispose(), returnsNormally);
      });
    });
  });
}
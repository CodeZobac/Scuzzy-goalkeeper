import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:goalkeeper/src/features/announcements/presentation/controllers/announcement_controller.dart';
import 'package:goalkeeper/src/features/announcements/data/repositories/announcement_repository.dart';
import 'package:goalkeeper/src/features/announcements/data/models/announcement.dart';

// Generate mocks
@GenerateMocks([AnnouncementRepository])
import 'announcement_controller_enhanced_test.mocks.dart';

void main() {
  group('AnnouncementController Enhanced Loading and Error Tests', () {
    late AnnouncementController controller;
    late MockAnnouncementRepository mockRepository;

    setUp(() {
      mockRepository = MockAnnouncementRepository();
      controller = AnnouncementController(mockRepository);
    });

    group('Loading States', () {
      test('fetchAnnouncements sets loading state correctly', () async {
        // Arrange
        final announcements = [
          Announcement(
            id: 1,
            title: 'Test Announcement',
            date: DateTime.now(),
            time: '10:00',
            price: 50.0,
            maxParticipants: 10,
            participantCount: 5,
            participants: [],
          ),
        ];
        
        when(mockRepository.getAnnouncements())
            .thenAnswer((_) async {
          // Simulate network delay
          await Future.delayed(const Duration(milliseconds: 100));
          return announcements;
        });

        // Act & Assert
        expect(controller.isLoading, isFalse);
        expect(controller.hasError, isFalse);

        final future = controller.fetchAnnouncements();
        
        // Should be loading immediately
        expect(controller.isLoading, isTrue);
        expect(controller.hasError, isFalse);

        await future;

        // Should not be loading after completion
        expect(controller.isLoading, isFalse);
        expect(controller.hasError, isFalse);
        expect(controller.announcements, equals(announcements));
      });

      test('refreshAnnouncements sets refresh loading state correctly', () async {
        // Arrange
        final announcements = [
          Announcement(
            id: 1,
            title: 'Refreshed Announcement',
            date: DateTime.now(),
            time: '11:00',
            price: 60.0,
            maxParticipants: 12,
            participantCount: 6,
            participants: [],
          ),
        ];
        
        when(mockRepository.getAnnouncements())
            .thenAnswer((_) async => announcements);

        // Act & Assert
        expect(controller.isRefreshing, isFalse);

        final future = controller.refreshAnnouncements();
        
        // Should be refreshing immediately
        expect(controller.isRefreshing, isTrue);

        await future;

        // Should not be refreshing after completion
        expect(controller.isRefreshing, isFalse);
        expect(controller.announcements, equals(announcements));
      });

      test('joinAnnouncement sets join/leave loading state correctly', () async {
        // Arrange
        const announcementId = 1;
        const userId = 'user123';
        final announcement = Announcement(
          id: announcementId,
          title: 'Test Announcement',
          date: DateTime.now(),
          time: '10:00',
          price: 50.0,
          maxParticipants: 10,
          participantCount: 5,
          participants: [],
        );

        when(mockRepository.getAnnouncementById(announcementId))
            .thenAnswer((_) async => announcement);
        when(mockRepository.isUserParticipant(announcementId, userId))
            .thenAnswer((_) async => false);
        when(mockRepository.joinAnnouncement(announcementId, userId))
            .thenAnswer((_) async {});

        // Act & Assert
        expect(controller.isJoinLeaveLoading(announcementId), isFalse);

        final future = controller.joinAnnouncement(announcementId, userId);
        
        // Should be loading immediately
        expect(controller.isJoinLeaveLoading(announcementId), isTrue);

        await future;

        // Should not be loading after completion
        expect(controller.isJoinLeaveLoading(announcementId), isFalse);
        expect(controller.isUserParticipant(announcementId), isTrue);
      });

      test('leaveAnnouncement sets join/leave loading state correctly', () async {
        // Arrange
        const announcementId = 1;
        const userId = 'user123';
        final announcement = Announcement(
          id: announcementId,
          title: 'Test Announcement',
          date: DateTime.now(),
          time: '10:00',
          price: 50.0,
          maxParticipants: 10,
          participantCount: 5,
          participants: [],
        );

        when(mockRepository.isUserParticipant(announcementId, userId))
            .thenAnswer((_) async => true);
        when(mockRepository.leaveAnnouncement(announcementId, userId))
            .thenAnswer((_) async {});
        when(mockRepository.getAnnouncementById(announcementId))
            .thenAnswer((_) async => announcement);

        // Act & Assert
        expect(controller.isJoinLeaveLoading(announcementId), isFalse);

        final future = controller.leaveAnnouncement(announcementId, userId);
        
        // Should be loading immediately
        expect(controller.isJoinLeaveLoading(announcementId), isTrue);

        await future;

        // Should not be loading after completion
        expect(controller.isJoinLeaveLoading(announcementId), isFalse);
        expect(controller.isUserParticipant(announcementId), isFalse);
      });
    });

    group('Error Handling', () {
      test('fetchAnnouncements handles network errors correctly', () async {
        // Arrange
        when(mockRepository.getAnnouncements())
            .thenThrow(Exception('Network connection failed'));

        // Act
        await controller.fetchAnnouncements();

        // Assert
        expect(controller.isLoading, isFalse);
        expect(controller.hasError, isTrue);
        expect(controller.errorMessage, contains('Failed to load announcements'));
        expect(controller.announcements, isEmpty);
      });

      test('refreshAnnouncements handles errors correctly', () async {
        // Arrange
        when(mockRepository.getAnnouncements())
            .thenThrow(Exception('Server error'));

        // Act
        await controller.refreshAnnouncements();

        // Assert
        expect(controller.isRefreshing, isFalse);
        expect(controller.hasError, isTrue);
        expect(controller.errorMessage, isNotNull);
      });

      test('joinAnnouncement handles full announcement error', () async {
        // Arrange
        const announcementId = 1;
        const userId = 'user123';
        final fullAnnouncement = Announcement(
          id: announcementId,
          title: 'Full Announcement',
          date: DateTime.now(),
          time: '10:00',
          price: 50.0,
          maxParticipants: 10,
          participantCount: 10, // Full
          participants: [],
        );

        when(mockRepository.getAnnouncementById(announcementId))
            .thenAnswer((_) async => fullAnnouncement);

        // Act & Assert
        expect(
          () => controller.joinAnnouncement(announcementId, userId),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('full'),
          )),
        );
      });

      test('joinAnnouncement handles already participant error', () async {
        // Arrange
        const announcementId = 1;
        const userId = 'user123';
        final announcement = Announcement(
          id: announcementId,
          title: 'Test Announcement',
          date: DateTime.now(),
          time: '10:00',
          price: 50.0,
          maxParticipants: 10,
          participantCount: 5,
          participants: [],
        );

        when(mockRepository.getAnnouncementById(announcementId))
            .thenAnswer((_) async => announcement);
        when(mockRepository.isUserParticipant(announcementId, userId))
            .thenAnswer((_) async => true); // Already participant

        // Act & Assert
        expect(
          () => controller.joinAnnouncement(announcementId, userId),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('already a participant'),
          )),
        );
      });

      test('leaveAnnouncement handles not participant error', () async {
        // Arrange
        const announcementId = 1;
        const userId = 'user123';

        when(mockRepository.isUserParticipant(announcementId, userId))
            .thenAnswer((_) async => false); // Not a participant

        // Act & Assert
        expect(
          () => controller.leaveAnnouncement(announcementId, userId),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('not a participant'),
          )),
        );
      });

      test('retry method calls fetchAnnouncements when there is an error', () async {
        // Arrange
        when(mockRepository.getAnnouncements())
            .thenThrow(Exception('Network error'))
            .thenAnswer((_) async => []);

        // Set up error state
        await controller.fetchAnnouncements();
        expect(controller.hasError, isTrue);

        // Reset mock to return success
        when(mockRepository.getAnnouncements())
            .thenAnswer((_) async => []);

        // Act
        await controller.retry();

        // Assert
        expect(controller.hasError, isFalse);
        verify(mockRepository.getAnnouncements()).called(2);
      });

      test('clearError removes error state', () async {
        // Arrange
        when(mockRepository.getAnnouncements())
            .thenThrow(Exception('Test error'));

        await controller.fetchAnnouncements();
        expect(controller.hasError, isTrue);

        // Act
        controller.clearError();

        // Assert
        expect(controller.hasError, isFalse);
        expect(controller.errorMessage, isNull);
      });
    });

    group('State Management', () {
      test('clearParticipationCache clears all cached states', () {
        // Arrange
        controller.isUserParticipant(1); // This will set default false
        controller.isJoinLeaveLoading(1); // This will set default false

        // Act
        controller.clearParticipationCache();

        // Assert - These should return default values after clearing
        expect(controller.isUserParticipant(1), isFalse);
        expect(controller.isJoinLeaveLoading(1), isFalse);
      });

      test('checkUserParticipation updates participation status', () async {
        // Arrange
        const announcementId = 1;
        const userId = 'user123';

        when(mockRepository.isUserParticipant(announcementId, userId))
            .thenAnswer((_) async => true);

        // Act
        final result = await controller.checkUserParticipation(announcementId, userId);

        // Assert
        expect(result, isTrue);
        expect(controller.isUserParticipant(announcementId), isTrue);
      });
    });
  });
}
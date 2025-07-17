import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:goalkeeper/src/features/announcements/presentation/controllers/announcement_controller.dart';
import 'package:goalkeeper/src/features/announcements/data/repositories/announcement_repository.dart';
import 'package:goalkeeper/src/features/announcements/data/models/announcement.dart';

// Simple mock repository for integration testing
class MockAnnouncementRepository implements AnnouncementRepository {
  final Map<int, Announcement> _announcements = {};
  final Map<int, List<String>> _participants = {};
  
  @override
  Future<List<Announcement>> getAnnouncements() async {
    return _announcements.values.toList();
  }

  @override
  Future<void> createAnnouncement(Announcement announcement) async {
    _announcements[announcement.id] = announcement;
  }

  @override
  Future<void> joinAnnouncement(int announcementId, String userId) async {
    final announcement = _announcements[announcementId];
    if (announcement == null) throw Exception('Announcement not found');
    
    final participants = _participants[announcementId] ?? [];
    if (participants.contains(userId)) {
      throw Exception('User is already a participant in this announcement');
    }
    
    if (participants.length >= announcement.maxParticipants) {
      throw Exception('This announcement is full. Cannot join.');
    }
    
    _participants[announcementId] = [...participants, userId];
  }

  @override
  Future<void> leaveAnnouncement(int announcementId, String userId) async {
    final participants = _participants[announcementId] ?? [];
    if (!participants.contains(userId)) {
      throw Exception('You are not a participant in this announcement.');
    }
    
    _participants[announcementId] = participants.where((id) => id != userId).toList();
  }

  @override
  Future<List<String>> getAnnouncementParticipants(int announcementId) async {
    return _participants[announcementId] ?? [];
  }

  @override
  Future<Announcement> getAnnouncementById(int id) async {
    final announcement = _announcements[id];
    if (announcement == null) throw Exception('Announcement not found');
    
    final participantCount = _participants[id]?.length ?? 0;
    return Announcement(
      id: announcement.id,
      title: announcement.title,
      description: announcement.description,
      date: announcement.date,
      time: announcement.time,
      createdAt: announcement.createdAt,
      createdBy: announcement.createdBy,
      price: announcement.price,
      stadium: announcement.stadium,
      organizerName: announcement.organizerName,
      organizerAvatarUrl: announcement.organizerAvatarUrl,
      organizerRating: announcement.organizerRating,
      stadiumImageUrl: announcement.stadiumImageUrl,
      distanceKm: announcement.distanceKm,
      participantCount: participantCount,
      maxParticipants: announcement.maxParticipants,
      participants: announcement.participants,
    );
  }

  @override
  Future<List<AnnouncementParticipant>> getParticipants(int announcementId) async {
    final participants = _participants[announcementId] ?? [];
    return participants.map((userId) => AnnouncementParticipant(
      userId: userId,
      name: 'User $userId',
      joinedAt: DateTime.now(),
    )).toList();
  }

  @override
  Future<bool> isUserParticipant(int announcementId, String userId) async {
    final participants = _participants[announcementId] ?? [];
    return participants.contains(userId);
  }

  @override
  Future<Map<String, dynamic>> getOrganizerInfo(String userId) async {
    return {'name': 'Test Organizer', 'avatar_url': null, 'rating': 4.5};
  }

  @override
  Future<Map<String, dynamic>> getStadiumInfo(String stadiumName) async {
    return {
      'name': stadiumName,
      'image_url': null,
      'distance_km': null,
      'photo_count': 0,
    };
  }

  // Helper methods for testing
  void addAnnouncement(Announcement announcement) {
    _announcements[announcement.id] = announcement;
  }
}

void main() {
  late MockAnnouncementRepository mockRepository;

  setUp(() {
    mockRepository = MockAnnouncementRepository();
  });

  group('Join/Leave Integration Tests', () {
    test('should successfully join and leave announcement', () async {
      // Arrange
      final controller = AnnouncementController(mockRepository);
      const userId = 'test_user';
      const announcementId = 1;
      
      final testAnnouncement = Announcement(
        id: announcementId,
        title: 'Football Match',
        description: 'Join us for a friendly match',
        date: DateTime.now().add(const Duration(days: 1)),
        time: const TimeOfDay(hour: 18, minute: 0),
        createdAt: DateTime.now(),
        organizerName: 'John Organizer',
        organizerRating: 4.5,
        participantCount: 0,
        maxParticipants: 22,
        stadium: 'Central Stadium',
        price: 25.0,
      );
      
      mockRepository.addAnnouncement(testAnnouncement);

      // Act - Join announcement
      await controller.joinAnnouncement(announcementId, userId);

      // Assert - User should be participant
      expect(controller.isUserParticipant(announcementId), true);
      expect(controller.isJoinLeaveLoading(announcementId), false);
      
      final participants = await mockRepository.getAnnouncementParticipants(announcementId);
      expect(participants.contains(userId), true);

      // Act - Leave announcement
      await controller.leaveAnnouncement(announcementId, userId);

      // Assert - User should no longer be participant
      expect(controller.isUserParticipant(announcementId), false);
      expect(controller.isJoinLeaveLoading(announcementId), false);
      
      final participantsAfterLeave = await mockRepository.getAnnouncementParticipants(announcementId);
      expect(participantsAfterLeave.contains(userId), false);
    });

    test('should handle full announcement correctly', () async {
      // Arrange
      final controller = AnnouncementController(mockRepository);
      const userId = 'test_user';
      const announcementId = 1;
      
      final fullAnnouncement = Announcement(
        id: announcementId,
        title: 'Football Match',
        date: DateTime.now().add(const Duration(days: 1)),
        time: const TimeOfDay(hour: 18, minute: 0),
        createdAt: DateTime.now(),
        participantCount: 2,
        maxParticipants: 2,
      );
      
      mockRepository.addAnnouncement(fullAnnouncement);
      
      // Fill up the announcement
      mockRepository._participants[announcementId] = ['user1', 'user2'];

      // Act & Assert
      try {
        await controller.joinAnnouncement(announcementId, userId);
        fail('Expected exception was not thrown');
      } catch (e) {
        expect(e.toString(), contains('This announcement is full'));
      }
      
      expect(controller.isJoinLeaveLoading(announcementId), false);
    });

    test('should prevent duplicate joins', () async {
      // Arrange
      final controller = AnnouncementController(mockRepository);
      const userId = 'test_user';
      const announcementId = 1;
      
      final testAnnouncement = Announcement(
        id: announcementId,
        title: 'Football Match',
        date: DateTime.now().add(const Duration(days: 1)),
        time: const TimeOfDay(hour: 18, minute: 0),
        createdAt: DateTime.now(),
        participantCount: 0,
        maxParticipants: 22,
      );
      
      mockRepository.addAnnouncement(testAnnouncement);
      
      // Join first time
      await controller.joinAnnouncement(announcementId, userId);

      // Act & Assert - Try to join again
      try {
        await controller.joinAnnouncement(announcementId, userId);
        fail('Expected exception was not thrown');
      } catch (e) {
        expect(e.toString(), contains('already a participant'));
      }
      
      expect(controller.isJoinLeaveLoading(announcementId), false);
    });

    test('should handle leave when not participant', () async {
      // Arrange
      final controller = AnnouncementController(mockRepository);
      const userId = 'test_user';
      const announcementId = 1;
      
      final testAnnouncement = Announcement(
        id: announcementId,
        title: 'Football Match',
        date: DateTime.now().add(const Duration(days: 1)),
        time: const TimeOfDay(hour: 18, minute: 0),
        createdAt: DateTime.now(),
        participantCount: 0,
        maxParticipants: 22,
      );
      
      mockRepository.addAnnouncement(testAnnouncement);

      // Act & Assert - Try to leave without joining
      try {
        await controller.leaveAnnouncement(announcementId, userId);
        fail('Expected exception was not thrown');
      } catch (e) {
        expect(e.toString(), contains('not a participant'));
      }
      
      expect(controller.isJoinLeaveLoading(announcementId), false);
    });

    test('should check user participation status correctly', () async {
      // Arrange
      final controller = AnnouncementController(mockRepository);
      const userId = 'test_user';
      const announcementId = 1;
      
      final testAnnouncement = Announcement(
        id: announcementId,
        title: 'Football Match',
        date: DateTime.now().add(const Duration(days: 1)),
        time: const TimeOfDay(hour: 18, minute: 0),
        createdAt: DateTime.now(),
        participantCount: 0,
        maxParticipants: 22,
      );
      
      mockRepository.addAnnouncement(testAnnouncement);

      // Act - Check participation before joining
      final isParticipantBefore = await controller.checkUserParticipation(announcementId, userId);
      
      // Assert
      expect(isParticipantBefore, false);
      expect(controller.isUserParticipant(announcementId), false);

      // Act - Join and check again
      await controller.joinAnnouncement(announcementId, userId);
      final isParticipantAfter = await controller.checkUserParticipation(announcementId, userId);
      
      // Assert
      expect(isParticipantAfter, true);
      expect(controller.isUserParticipant(announcementId), true);
    });
  });
}
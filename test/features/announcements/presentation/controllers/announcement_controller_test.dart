import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:goalkeeper/src/features/announcements/presentation/controllers/announcement_controller.dart';
import 'package:goalkeeper/src/features/announcements/data/repositories/announcement_repository.dart';
import 'package:goalkeeper/src/features/announcements/data/models/announcement.dart';

// Mock implementation of AnnouncementRepository for testing
class MockAnnouncementRepository implements AnnouncementRepository {
  final Map<int, Announcement> _announcements = {};
  final Map<int, List<String>> _participants = {};
  final Map<String, Map<String, dynamic>> _users = {};
  
  bool shouldThrowError = false;
  String errorMessage = '';

  void setError(String message) {
    shouldThrowError = true;
    errorMessage = message;
  }

  void clearError() {
    shouldThrowError = false;
    errorMessage = '';
  }

  @override
  Future<List<Announcement>> getAnnouncements() async {
    if (shouldThrowError) throw Exception(errorMessage);
    return _announcements.values.toList();
  }

  @override
  Future<void> createAnnouncement(Announcement announcement) async {
    if (shouldThrowError) throw Exception(errorMessage);
    _announcements[announcement.id] = announcement;
  }

  @override
  Future<void> joinAnnouncement(int announcementId, String userId) async {
    if (shouldThrowError) throw Exception(errorMessage);
    
    final announcement = _announcements[announcementId];
    if (announcement == null) throw Exception('Announcement not found');
    
    final participants = _participants[announcementId] ?? [];
    if (participants.contains(userId)) {
      throw Exception('User is already a participant in this announcement');
    }
    
    if (participants.length >= announcement.maxParticipants) {
      throw Exception('Announcement is full');
    }
    
    _participants[announcementId] = [...participants, userId];
  }

  @override
  Future<void> leaveAnnouncement(int announcementId, String userId) async {
    if (shouldThrowError) throw Exception(errorMessage);
    
    final participants = _participants[announcementId] ?? [];
    if (!participants.contains(userId)) {
      throw Exception('User is not a participant in this announcement');
    }
    
    _participants[announcementId] = participants.where((id) => id != userId).toList();
  }

  @override
  Future<List<String>> getAnnouncementParticipants(int announcementId) async {
    if (shouldThrowError) throw Exception(errorMessage);
    return _participants[announcementId] ?? [];
  }

  @override
  Future<Announcement> getAnnouncementById(int id) async {
    if (shouldThrowError) throw Exception(errorMessage);
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
    if (shouldThrowError) throw Exception(errorMessage);
    final participants = _participants[announcementId] ?? [];
    return participants.map((userId) => AnnouncementParticipant(
      userId: userId,
      name: _users[userId]?['name'] ?? 'User $userId',
      avatarUrl: _users[userId]?['avatar_url'],
      joinedAt: DateTime.now(),
    )).toList();
  }

  @override
  Future<bool> isUserParticipant(int announcementId, String userId) async {
    if (shouldThrowError) throw Exception(errorMessage);
    final participants = _participants[announcementId] ?? [];
    return participants.contains(userId);
  }

  @override
  Future<Map<String, dynamic>> getOrganizerInfo(String userId) async {
    if (shouldThrowError) throw Exception(errorMessage);
    return _users[userId] ?? {'name': 'Unknown', 'avatar_url': null, 'rating': null};
  }

  @override
  Future<Map<String, dynamic>> getStadiumInfo(String stadiumName) async {
    if (shouldThrowError) throw Exception(errorMessage);
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

  void addUser(String userId, Map<String, dynamic> userData) {
    _users[userId] = userData;
  }
}

void main() {
  late AnnouncementController controller;
  late MockAnnouncementRepository mockRepository;

  setUp(() {
    mockRepository = MockAnnouncementRepository();
    controller = AnnouncementController(mockRepository);
  });

  group('AnnouncementController Join/Leave Tests', () {
    final testAnnouncement = Announcement(
      id: 1,
      title: 'Test Game',
      date: DateTime.now(),
      time: const TimeOfDay(hour: 18, minute: 0),
      createdAt: DateTime.now(),
      participantCount: 5,
      maxParticipants: 22,
    );

    test('should check user participation status', () async {
      // Arrange
      const userId = 'user123';
      const announcementId = 1;
      mockRepository.addAnnouncement(testAnnouncement);
      mockRepository._participants[announcementId] = [userId];

      // Act
      final result = await controller.checkUserParticipation(announcementId, userId);

      // Assert
      expect(result, true);
      expect(controller.isUserParticipant(announcementId), true);
    });

    test('should successfully join announcement when valid', () async {
      // Arrange
      const userId = 'user123';
      const announcementId = 1;
      mockRepository.addAnnouncement(testAnnouncement);

      // Act
      await controller.joinAnnouncement(announcementId, userId);

      // Assert
      expect(controller.isUserParticipant(announcementId), true);
      expect(controller.isJoinLeaveLoading(announcementId), false);
      final participants = await mockRepository.getAnnouncementParticipants(announcementId);
      expect(participants.contains(userId), true);
    });

    test('should throw exception when trying to join full announcement', () async {
      // Arrange
      const userId = 'user123';
      const announcementId = 1;
      final fullAnnouncement = testAnnouncement.copyWith(
        participantCount: 22,
        maxParticipants: 22,
      );
      mockRepository.addAnnouncement(fullAnnouncement);
      
      // Fill up the announcement with participants
      for (int i = 0; i < 22; i++) {
        mockRepository._participants[announcementId] = 
            (mockRepository._participants[announcementId] ?? [])..add('user$i');
      }

      // Act & Assert
      try {
        await controller.joinAnnouncement(announcementId, userId);
        fail('Expected exception was not thrown');
      } catch (e) {
        expect(e.toString(), contains('This announcement is full'));
      }
      expect(controller.isJoinLeaveLoading(announcementId), false);
    });

    test('should throw exception when user already participant', () async {
      // Arrange
      const userId = 'user123';
      const announcementId = 1;
      mockRepository.addAnnouncement(testAnnouncement);
      mockRepository._participants[announcementId] = [userId];

      // Act & Assert
      try {
        await controller.joinAnnouncement(announcementId, userId);
        fail('Expected exception was not thrown');
      } catch (e) {
        expect(e.toString(), contains('already a participant'));
      }
      expect(controller.isJoinLeaveLoading(announcementId), false);
    });

    test('should successfully leave announcement when participant', () async {
      // Arrange
      const userId = 'user123';
      const announcementId = 1;
      mockRepository.addAnnouncement(testAnnouncement);
      mockRepository._participants[announcementId] = [userId];

      // Act
      await controller.leaveAnnouncement(announcementId, userId);

      // Assert
      expect(controller.isUserParticipant(announcementId), false);
      expect(controller.isJoinLeaveLoading(announcementId), false);
      final participants = await mockRepository.getAnnouncementParticipants(announcementId);
      expect(participants.contains(userId), false);
    });

    test('should throw exception when trying to leave non-participant', () async {
      // Arrange
      const userId = 'user123';
      const announcementId = 1;
      mockRepository.addAnnouncement(testAnnouncement);
      // Don't add user to participants list

      // Act & Assert
      try {
        await controller.leaveAnnouncement(announcementId, userId);
        fail('Expected exception was not thrown');
      } catch (e) {
        expect(e.toString(), contains('not a participant'));
      }
      expect(controller.isJoinLeaveLoading(announcementId), false);
    });

    test('should track loading states correctly', () async {
      // Arrange
      const userId = 'user123';
      const announcementId = 1;
      mockRepository.addAnnouncement(testAnnouncement);

      // Act
      final future = controller.joinAnnouncement(announcementId, userId);
      
      // Assert loading state during operation
      expect(controller.isJoinLeaveLoading(announcementId), true);
      
      await future;
      
      // Assert loading state after operation
      expect(controller.isJoinLeaveLoading(announcementId), false);
    });

    test('should clear participation cache', () {
      // Arrange
      controller.checkUserParticipation(1, 'user1');
      controller.checkUserParticipation(2, 'user2');

      // Act
      controller.clearParticipationCache();

      // Assert
      expect(controller.isUserParticipant(1), false);
      expect(controller.isUserParticipant(2), false);
      expect(controller.isJoinLeaveLoading(1), false);
      expect(controller.isJoinLeaveLoading(2), false);
    });
  });
}

// Extension to add copyWith method for testing
extension AnnouncementCopyWith on Announcement {
  Announcement copyWith({
    int? id,
    String? createdBy,
    String? title,
    String? description,
    DateTime? date,
    TimeOfDay? time,
    double? price,
    String? stadium,
    DateTime? createdAt,
    String? organizerName,
    String? organizerAvatarUrl,
    double? organizerRating,
    String? stadiumImageUrl,
    double? distanceKm,
    int? participantCount,
    int? maxParticipants,
    List<AnnouncementParticipant>? participants,
  }) {
    return Announcement(
      id: id ?? this.id,
      createdBy: createdBy ?? this.createdBy,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      time: time ?? this.time,
      price: price ?? this.price,
      stadium: stadium ?? this.stadium,
      createdAt: createdAt ?? this.createdAt,
      organizerName: organizerName ?? this.organizerName,
      organizerAvatarUrl: organizerAvatarUrl ?? this.organizerAvatarUrl,
      organizerRating: organizerRating ?? this.organizerRating,
      stadiumImageUrl: stadiumImageUrl ?? this.stadiumImageUrl,
      distanceKm: distanceKm ?? this.distanceKm,
      participantCount: participantCount ?? this.participantCount,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      participants: participants ?? this.participants,
    );
  }
}
import 'package:flutter/material.dart';
import '../models/announcement.dart';
import 'announcement_repository.dart';

/// Repository implementation that provides mock/sample data for guest users
/// when Supabase connection is not available
class GuestAnnouncementRepository implements AnnouncementRepository {
  
  @override
  Future<void> createAnnouncement(Announcement announcement) async {
    throw Exception('Creating announcements requires authentication. Please sign up or log in.');
  }

  @override
  Future<List<Announcement>> getAnnouncements() async {
    // Return mock announcements for guest users
    await Future.delayed(const Duration(milliseconds: 500)); // Simulate network delay
    
    return [
      Announcement(
        id: 1,
        title: "Football Game at Estádio José Alvalade",
        description: "Looking for a goalkeeper for our evening match. Good level players welcome!",
        date: DateTime.now().add(const Duration(days: 2)),
        time: const TimeOfDay(hour: 19, minute: 0),
        stadium: "Estádio José Alvalade XXI",
        maxParticipants: 22,
        participantCount: 8,
        organizerName: "João Silva",
        organizerAvatarUrl: null,
        organizerRating: 4.5,
        distanceKm: 2.5,
        createdBy: "guest_organizer_1",
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
        participants: _generateMockParticipants(8),
      ),
      Announcement(
        id: 2, 
        title: "Weekend Match at Campo Municipal",
        description: "Casual weekend game, all skill levels welcome. Need goalkeeper and few field players.",
        date: DateTime.now().add(const Duration(days: 5)),
        time: const TimeOfDay(hour: 15, minute: 30),
        stadium: "Campo Municipal de Lisboa",
        maxParticipants: 20,
        participantCount: 12,
        organizerName: "Miguel Santos",
        organizerAvatarUrl: null,
        organizerRating: 4.2,
        distanceKm: 1.8,
        createdBy: "guest_organizer_2",
        createdAt: DateTime.now().subtract(const Duration(hours: 8)),
        participants: _generateMockParticipants(12),
      ),
      Announcement(
        id: 3,
        title: "Training Session at Complexo do Porto",
        description: "Technical training session. Looking for dedicated goalkeeper to join our practice.",
        date: DateTime.now().add(const Duration(days: 1)),
        time: const TimeOfDay(hour: 18, minute: 0),
        stadium: "Complexo Desportivo do Porto",
        maxParticipants: 16,
        participantCount: 6,
        organizerName: "Pedro Costa",
        organizerAvatarUrl: null,
        organizerRating: 4.8,
        distanceKm: 3.2,
        createdBy: "guest_organizer_3",
        createdAt: DateTime.now().subtract(const Duration(hours: 12)),
        participants: _generateMockParticipants(6),
      ),
    ];
  }

  @override
  Future<List<String>> getAnnouncementParticipants(int announcementId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    
    // Return mock participant IDs based on announcement
    switch (announcementId) {
      case 1:
        return List.generate(8, (index) => 'guest_participant_${index + 1}');
      case 2:
        return List.generate(12, (index) => 'guest_participant_${index + 1}');
      case 3:
        return List.generate(6, (index) => 'guest_participant_${index + 1}');
      default:
        return [];
    }
  }

  @override
  Future<void> joinAnnouncement(int announcementId, String userId) async {
    throw Exception('Joining announcements requires authentication. Please sign up or log in.');
  }

  @override
  Future<void> leaveAnnouncement(int announcementId, String userId) async {
    throw Exception('Leaving announcements requires authentication. Please sign up or log in.');
  }

  @override
  Future<Announcement> getAnnouncementById(int id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    final announcements = await getAnnouncements();
    final announcement = announcements.firstWhere(
      (a) => a.id == id,
      orElse: () => throw Exception('Announcement not found'),
    );
    
    return announcement;
  }

  @override
  Future<List<AnnouncementParticipant>> getParticipants(int announcementId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    
    switch (announcementId) {
      case 1:
        return _generateMockParticipants(8);
      case 2:
        return _generateMockParticipants(12);
      case 3:
        return _generateMockParticipants(6);
      default:
        return [];
    }
  }

  @override
  Future<bool> isUserParticipant(int announcementId, String userId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    // Guest users are never participants
    return false;
  }

  @override
  Future<Map<String, dynamic>> getOrganizerInfo(String userId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    
    final organizerNames = {
      'guest_organizer_1': 'João Silva',
      'guest_organizer_2': 'Miguel Santos', 
      'guest_organizer_3': 'Pedro Costa',
    };
    
    return {
      'name': organizerNames[userId] ?? 'Unknown Organizer',
      'avatar_url': null,
      'rating': 4.5,
    };
  }

  @override
  Future<Map<String, dynamic>> getStadiumInfo(String stadiumName) async {
    await Future.delayed(const Duration(milliseconds: 200));
    
    return {
      'name': stadiumName,
      'image_url': null,
      'distance_km': 2.0,
      'photo_count': 0,
    };
  }

  @override
  Future<void> endGame(int announcementId) async {
    throw Exception('Ending games requires authentication. Please sign up or log in.');
  }

  /// Generate mock participants for demonstration
  List<AnnouncementParticipant> _generateMockParticipants(int count) {
    final mockNames = [
      'Carlos Silva', 'Ana Costa', 'Bruno Santos', 'Maria Oliveira',
      'Ricardo Pereira', 'Sofia Rodrigues', 'Tiago Ferreira', 'Inês Martins',
      'André Sousa', 'Catarina Lima', 'Hugo Alves', 'Beatriz Nunes',
      'Francisco Gomes', 'Joana Ribeiro', 'Nuno Carvalho', 'Teresa Lopes'
    ];
    
    return List.generate(count, (index) {
      return AnnouncementParticipant(
        userId: 'guest_participant_${index + 1}',
        name: mockNames[index % mockNames.length],
        avatarUrl: null,
        joinedAt: DateTime.now().subtract(Duration(hours: index + 1)),
      );
    });
  }
}

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:goalkeeper/src/features/announcements/data/models/announcement.dart';

void main() {
  group('AnnouncementParticipant', () {
    test('should create AnnouncementParticipant from JSON', () {
      final json = {
        'user_id': 'user123',
        'name': 'John Doe',
        'avatar_url': 'https://example.com/avatar.jpg',
        'joined_at': '2024-01-15T10:30:00Z',
      };

      final participant = AnnouncementParticipant.fromJson(json);

      expect(participant.userId, 'user123');
      expect(participant.name, 'John Doe');
      expect(participant.avatarUrl, 'https://example.com/avatar.jpg');
      expect(participant.joinedAt, DateTime.parse('2024-01-15T10:30:00Z'));
    });

    test('should convert AnnouncementParticipant to JSON', () {
      final participant = AnnouncementParticipant(
        userId: 'user123',
        name: 'John Doe',
        avatarUrl: 'https://example.com/avatar.jpg',
        joinedAt: DateTime.parse('2024-01-15T10:30:00Z'),
      );

      final json = participant.toJson();

      expect(json['user_id'], 'user123');
      expect(json['name'], 'John Doe');
      expect(json['avatar_url'], 'https://example.com/avatar.jpg');
      expect(json['joined_at'], '2024-01-15T10:30:00.000Z');
    });
  });

  group('Announcement', () {
    test('should create enhanced Announcement from JSON', () {
      final json = {
        'id': 1,
        'created_by': 'organizer123',
        'title': 'Football Match',
        'description': 'Friendly match',
        'date': '2024-01-20T00:00:00Z',
        'time': '15:30',
        'price': 25.0,
        'stadium': 'Central Stadium',
        'created_at': '2024-01-15T10:00:00Z',
        'organizer_name': 'John Organizer',
        'organizer_avatar_url': 'https://example.com/organizer.jpg',
        'organizer_rating': 4.5,
        'stadium_image_url': 'https://example.com/stadium.jpg',
        'distance_km': 2.5,
        'participant_count': 10,
        'max_participants': 22,
        'participants': [
          {
            'user_id': 'user1',
            'name': 'Player One',
            'avatar_url': null,
            'joined_at': '2024-01-16T09:00:00Z',
          }
        ],
      };

      final announcement = Announcement.fromJson(json);

      expect(announcement.id, 1);
      expect(announcement.title, 'Football Match');
      expect(announcement.organizerName, 'John Organizer');
      expect(announcement.organizerRating, 4.5);
      expect(announcement.participantCount, 10);
      expect(announcement.maxParticipants, 22);
      expect(announcement.participants.length, 1);
      expect(announcement.participants.first.name, 'Player One');
    });

    test('should create Announcement with default values', () {
      final announcement = Announcement(
        id: 1,
        title: 'Test Match',
        date: DateTime.now(),
        time: const TimeOfDay(hour: 15, minute: 30),
        createdAt: DateTime.now(),
      );

      expect(announcement.participantCount, 0);
      expect(announcement.maxParticipants, 22);
      expect(announcement.participants, isEmpty);
    });
  });
}
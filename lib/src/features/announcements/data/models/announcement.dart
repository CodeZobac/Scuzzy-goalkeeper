import 'package:flutter/material.dart';

class AnnouncementParticipant {
  final String userId;
  final String name;
  final String? avatarUrl;
  final DateTime joinedAt;

  AnnouncementParticipant({
    required this.userId,
    required this.name,
    this.avatarUrl,
    required this.joinedAt,
  });

  factory AnnouncementParticipant.fromJson(Map<String, dynamic> json) {
    return AnnouncementParticipant(
      userId: json['user_id'],
      name: json['name'] ?? '',
      avatarUrl: json['avatar_url'],
      joinedAt: DateTime.parse(json['joined_at'] ?? json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'name': name,
      'avatar_url': avatarUrl,
      'joined_at': joinedAt.toIso8601String(),
    };
  }
}

class Announcement {
  final int id;
  final String? createdBy;
  final String title;
  final String? description;
  final DateTime date;
  final TimeOfDay time;
  final double? price;
  final String? stadium;
  final DateTime createdAt;
  
  // Enhanced fields for organizer info, participant data, and stadium details
  final String? organizerName;
  final String? organizerAvatarUrl;
  final double? organizerRating;
  final String? stadiumImageUrl;
  final double? distanceKm;
  final int participantCount;
  final int maxParticipants;
  final List<AnnouncementParticipant> participants;
  
  // Goalkeeper hiring fields
  final bool needsGoalkeeper;
  final String? hiredGoalkeeperId;
  final String? hiredGoalkeeperName;
  final double? goalkeeperPrice;

  Announcement({
    required this.id,
    this.createdBy,
    required this.title,
    this.description,
    required this.date,
    required this.time,
    this.price,
    this.stadium,
    required this.createdAt,
    this.organizerName,
    this.organizerAvatarUrl,
    this.organizerRating,
    this.stadiumImageUrl,
    this.distanceKm,
    this.participantCount = 0,
    this.maxParticipants = 22,
    this.participants = const [],
    this.needsGoalkeeper = false,
    this.hiredGoalkeeperId,
    this.hiredGoalkeeperName,
    this.goalkeeperPrice,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) {
    // Parse participants if provided
    List<AnnouncementParticipant> participantsList = [];
    if (json['participants'] != null) {
      participantsList = (json['participants'] as List)
          .map((p) => AnnouncementParticipant.fromJson(p))
          .toList();
    }

    return Announcement(
      id: json['id'],
      createdBy: json['created_by'],
      title: json['title'],
      description: json['description'],
      date: DateTime.parse(json['date']),
      time: TimeOfDay(
        hour: int.parse(json['time'].split(':')[0]),
        minute: int.parse(json['time'].split(':')[1]),
      ),
      price: json['price']?.toDouble(),
      stadium: json['stadium'],
      createdAt: DateTime.parse(json['created_at']),
      // Enhanced fields
      organizerName: json['organizer_name'],
      organizerAvatarUrl: json['organizer_avatar_url'],
      organizerRating: json['organizer_rating']?.toDouble(),
      stadiumImageUrl: json['stadium_image_url'],
      distanceKm: json['distance_km']?.toDouble(),
      participantCount: json['participant_count'] ?? participantsList.length,
      maxParticipants: json['max_participants'] ?? 22,
      participants: participantsList,
      // Goalkeeper fields
      needsGoalkeeper: json['needs_goalkeeper'] ?? false,
      hiredGoalkeeperId: json['hired_goalkeeper_id'],
      hiredGoalkeeperName: json['hired_goalkeeper_name'],
      goalkeeperPrice: json['goalkeeper_price']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'created_by': createdBy,
      'title': title,
      'description': description,
      'date': date.toIso8601String(),
      'time': '${time.hour}:${time.minute}',
      'price': price,
      'stadium': stadium,
      'created_at': createdAt.toIso8601String(),
      // Enhanced fields
      'organizer_name': organizerName,
      'organizer_avatar_url': organizerAvatarUrl,
      'organizer_rating': organizerRating,
      'stadium_image_url': stadiumImageUrl,
      'distance_km': distanceKm,
      'participant_count': participantCount,
      'max_participants': maxParticipants,
      'participants': participants.map((p) => p.toJson()).toList(),
      // Goalkeeper fields
      'needs_goalkeeper': needsGoalkeeper,
      'hired_goalkeeper_id': hiredGoalkeeperId,
      'hired_goalkeeper_name': hiredGoalkeeperName,
      'goalkeeper_price': goalkeeperPrice,
    };
  }
}

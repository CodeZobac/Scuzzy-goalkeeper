import 'dart:convert';

class FullLobbyNotificationData {
  final String announcementId;
  final String announcementTitle;
  final DateTime gameDateTime;
  final String stadium;
  final int participantCount;
  final int maxParticipants;

  FullLobbyNotificationData({
    required this.announcementId,
    required this.announcementTitle,
    required this.gameDateTime,
    required this.stadium,
    required this.participantCount,
    required this.maxParticipants,
  });

  Map<String, dynamic> toMap() {
    return {
      'announcement_id': announcementId,
      'announcement_title': announcementTitle,
      'game_date_time': gameDateTime.toIso8601String(),
      'stadium': stadium,
      'participant_count': participantCount,
      'max_participants': maxParticipants,
    };
  }

  factory FullLobbyNotificationData.fromMap(Map<String, dynamic> map) {
    return FullLobbyNotificationData(
      announcementId: map['announcement_id'] ?? '',
      announcementTitle: map['announcement_title'] ?? '',
      gameDateTime: DateTime.parse(map['game_date_time']),
      stadium: map['stadium'] ?? '',
      participantCount: map['participant_count']?.toInt() ?? 0,
      maxParticipants: map['max_participants']?.toInt() ?? 0,
    );
  }

  String toJson() => json.encode(toMap());

  factory FullLobbyNotificationData.fromJson(String source) =>
      FullLobbyNotificationData.fromMap(json.decode(source));

  FullLobbyNotificationData copyWith({
    String? announcementId,
    String? announcementTitle,
    DateTime? gameDateTime,
    String? stadium,
    int? participantCount,
    int? maxParticipants,
  }) {
    return FullLobbyNotificationData(
      announcementId: announcementId ?? this.announcementId,
      announcementTitle: announcementTitle ?? this.announcementTitle,
      gameDateTime: gameDateTime ?? this.gameDateTime,
      stadium: stadium ?? this.stadium,
      participantCount: participantCount ?? this.participantCount,
      maxParticipants: maxParticipants ?? this.maxParticipants,
    );
  }

  String get participantCountDisplay => '($participantCount/$maxParticipants)';

  bool get isFull => participantCount >= maxParticipants;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is FullLobbyNotificationData &&
        other.announcementId == announcementId &&
        other.announcementTitle == announcementTitle &&
        other.gameDateTime == gameDateTime &&
        other.stadium == stadium &&
        other.participantCount == participantCount &&
        other.maxParticipants == maxParticipants;
  }

  @override
  int get hashCode {
    return announcementId.hashCode ^
        announcementTitle.hashCode ^
        gameDateTime.hashCode ^
        stadium.hashCode ^
        participantCount.hashCode ^
        maxParticipants.hashCode;
  }
}
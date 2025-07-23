import 'dart:convert';

import 'notification_category.dart';
import 'contract_notification_data.dart';
import 'full_lobby_notification_data.dart';

class AppNotification {
  final String id;
  final String userId;
  final String? bookingId;
  final String title;
  final String body;
  final String type;
  final Map<String, dynamic>? data;
  final DateTime sentAt;
  final DateTime? readAt;
  final DateTime createdAt;
  final DateTime? archivedAt;

  AppNotification({
    required this.id,
    required this.userId,
    this.bookingId,
    required this.title,
    required this.body,
    required this.type,
    this.data,
    required this.sentAt,
    this.readAt,
    required this.createdAt,
    this.archivedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'booking_id': bookingId,
      'title': title,
      'body': body,
      'type': type,
      'data': data,
      'sent_at': sentAt.toIso8601String(),
      'read_at': readAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'archived_at': archivedAt?.toIso8601String(),
    };
  }

  factory AppNotification.fromMap(Map<String, dynamic> map) {
    return AppNotification(
      id: map['id'],
      userId: map['user_id'],
      bookingId: map['booking_id'],
      title: map['title'],
      body: map['body'],
      type: map['type'],
      data: map['data'] is String ? json.decode(map['data']) : map['data'],
      sentAt: DateTime.parse(map['sent_at']),
      readAt: map['read_at'] != null ? DateTime.parse(map['read_at']) : null,
      createdAt: DateTime.parse(map['created_at']),
      archivedAt: map['archived_at'] != null ? DateTime.parse(map['archived_at']) : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory AppNotification.fromJson(String source) =>
      AppNotification.fromMap(json.decode(source));

  // Helper methods
  bool get isRead => readAt != null;
  bool get isUnread => readAt == null;
  bool get isArchived => archivedAt != null;
  bool get isActive => archivedAt == null;
  
  String get displayTime {
    final now = DateTime.now();
    final difference = now.difference(sentAt);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d atrás';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h atrás';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m atrás';
    } else {
      return 'Agora';
    }
  }

  String get displayDate {
    return '${sentAt.day}/${sentAt.month}/${sentAt.year} às ${sentAt.hour.toString().padLeft(2, '0')}:${sentAt.minute.toString().padLeft(2, '0')}';
  }

  String get detailedDisplayDate {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final notificationDate = DateTime(sentAt.year, sentAt.month, sentAt.day);
    
    final timeString = '${sentAt.hour.toString().padLeft(2, '0')}:${sentAt.minute.toString().padLeft(2, '0')}';
    
    if (notificationDate == today) {
      return 'Hoje às $timeString';
    } else if (notificationDate == yesterday) {
      return 'Ontem às $timeString';
    } else if (now.difference(sentAt).inDays < 7) {
      final weekdays = ['Segunda', 'Terça', 'Quarta', 'Quinta', 'Sexta', 'Sábado', 'Domingo'];
      return '${weekdays[sentAt.weekday - 1]} às $timeString';
    } else {
      return displayDate;
    }
  }

  String get shortDisplayDate {
    final now = DateTime.now();
    final difference = now.difference(sentAt);
    
    if (difference.inDays == 0) {
      return '${sentAt.hour.toString().padLeft(2, '0')}:${sentAt.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Ontem';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return '${sentAt.day}/${sentAt.month}';
    }
  }

  bool get isBookingRequest => type == 'booking_request';
  bool get isBookingConfirmed => type == 'booking_confirmed';
  bool get isBookingCancelled => type == 'booking_cancelled';

  // New notification type helpers
  bool get isContractRequest => type == 'contract_request';
  bool get isFullLobby => type == 'full_lobby';
  bool get requiresAction => isContractRequest;

  // Notification category
  NotificationCategory get category {
    if (isContractRequest) return NotificationCategory.contracts;
    if (isFullLobby) return NotificationCategory.fullLobbies;
    return NotificationCategory.general;
  }

  // Enhanced data accessors
  String? get contractId => data?['contract_id'];
  String? get announcementId => data?['announcement_id'];
  String? get contractorName => data?['contractor_name'];
  String? get contractorAvatarUrl => data?['contractor_avatar_url'];
  double? get offeredAmount => data?['offered_amount']?.toDouble();
  String? get gameLocation => data?['stadium'];
  DateTime? get gameDateTime => data?['game_date_time'] != null
      ? DateTime.parse(data!['game_date_time']) : null;

  // Structured data accessors
  ContractNotificationData? get contractData {
    if (!isContractRequest || data == null) return null;
    try {
      return ContractNotificationData.fromMap(data!);
    } catch (e) {
      return null;
    }
  }

  FullLobbyNotificationData? get fullLobbyData {
    if (!isFullLobby || data == null) return null;
    try {
      return FullLobbyNotificationData.fromMap(data!);
    } catch (e) {
      return null;
    }
  }

  // Create copy with updated fields
  AppNotification copyWith({
    String? id,
    String? userId,
    String? bookingId,
    String? title,
    String? body,
    String? type,
    Map<String, dynamic>? data,
    DateTime? sentAt,
    DateTime? readAt,
    DateTime? createdAt,
    DateTime? archivedAt,
  }) {
    return AppNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      bookingId: bookingId ?? this.bookingId,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      data: data ?? this.data,
      sentAt: sentAt ?? this.sentAt,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt ?? this.createdAt,
      archivedAt: archivedAt ?? this.archivedAt,
    );
  }
}

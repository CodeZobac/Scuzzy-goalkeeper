import 'dart:convert';

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
    );
  }

  String toJson() => json.encode(toMap());

  factory AppNotification.fromJson(String source) =>
      AppNotification.fromMap(json.decode(source));

  // Helper methods
  bool get isRead => readAt != null;
  bool get isUnread => readAt == null;
  
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

  bool get isBookingRequest => type == 'booking_request';
  bool get isBookingConfirmed => type == 'booking_confirmed';
  bool get isBookingCancelled => type == 'booking_cancelled';

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
    );
  }
}

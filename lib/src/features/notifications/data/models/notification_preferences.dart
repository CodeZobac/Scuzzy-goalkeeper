import 'dart:convert';

/// Model for user notification preferences
class NotificationPreferences {
  final String userId;
  final bool contractNotifications;
  final bool fullLobbyNotifications;
  final bool generalNotifications;
  final bool pushNotificationsEnabled;
  final DateTime updatedAt;

  const NotificationPreferences({
    required this.userId,
    this.contractNotifications = true,
    this.fullLobbyNotifications = true,
    this.generalNotifications = true,
    this.pushNotificationsEnabled = true,
    required this.updatedAt,
  });

  /// Create default preferences for a new user
  factory NotificationPreferences.defaultPreferences(String userId) {
    return NotificationPreferences(
      userId: userId,
      contractNotifications: true,
      fullLobbyNotifications: true,
      generalNotifications: true,
      pushNotificationsEnabled: true,
      updatedAt: DateTime.now(),
    );
  }

  /// Create from database map
  factory NotificationPreferences.fromMap(Map<String, dynamic> map) {
    return NotificationPreferences(
      userId: map['user_id'] as String,
      contractNotifications: map['contract_notifications'] as bool? ?? true,
      fullLobbyNotifications: map['full_lobby_notifications'] as bool? ?? true,
      generalNotifications: map['general_notifications'] as bool? ?? true,
      pushNotificationsEnabled: map['push_notifications_enabled'] as bool? ?? true,
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  /// Convert to database map
  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'contract_notifications': contractNotifications,
      'full_lobby_notifications': fullLobbyNotifications,
      'general_notifications': generalNotifications,
      'push_notifications_enabled': pushNotificationsEnabled,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Create copy with updated values
  NotificationPreferences copyWith({
    String? userId,
    bool? contractNotifications,
    bool? fullLobbyNotifications,
    bool? generalNotifications,
    bool? pushNotificationsEnabled,
    DateTime? updatedAt,
  }) {
    return NotificationPreferences(
      userId: userId ?? this.userId,
      contractNotifications: contractNotifications ?? this.contractNotifications,
      fullLobbyNotifications: fullLobbyNotifications ?? this.fullLobbyNotifications,
      generalNotifications: generalNotifications ?? this.generalNotifications,
      pushNotificationsEnabled: pushNotificationsEnabled ?? this.pushNotificationsEnabled,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Check if a specific notification type is enabled
  bool isNotificationTypeEnabled(String notificationType) {
    switch (notificationType) {
      case 'contract_request':
        return contractNotifications && pushNotificationsEnabled;
      case 'full_lobby':
        return fullLobbyNotifications && pushNotificationsEnabled;
      case 'general':
      case 'booking_request':
      case 'booking_confirmed':
      case 'booking_cancelled':
        return generalNotifications && pushNotificationsEnabled;
      default:
        return generalNotifications && pushNotificationsEnabled;
    }
  }

  /// Convert to JSON string
  String toJson() => json.encode(toMap());

  /// Create from JSON string
  factory NotificationPreferences.fromJson(String source) =>
      NotificationPreferences.fromMap(json.decode(source));

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is NotificationPreferences &&
        other.userId == userId &&
        other.contractNotifications == contractNotifications &&
        other.fullLobbyNotifications == fullLobbyNotifications &&
        other.generalNotifications == generalNotifications &&
        other.pushNotificationsEnabled == pushNotificationsEnabled;
  }

  @override
  int get hashCode {
    return userId.hashCode ^
        contractNotifications.hashCode ^
        fullLobbyNotifications.hashCode ^
        generalNotifications.hashCode ^
        pushNotificationsEnabled.hashCode;
  }

  @override
  String toString() {
    return 'NotificationPreferences(userId: $userId, contractNotifications: $contractNotifications, fullLobbyNotifications: $fullLobbyNotifications, generalNotifications: $generalNotifications, pushNotificationsEnabled: $pushNotificationsEnabled, updatedAt: $updatedAt)';
  }
}
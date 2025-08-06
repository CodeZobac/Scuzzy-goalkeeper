import 'dart:convert';

/// Enum representing the type of authentication code
enum AuthCodeType {
  emailConfirmation('email_confirmation'),
  passwordReset('password_reset');

  const AuthCodeType(this.value);
  final String value;

  static AuthCodeType fromString(String value) {
    switch (value) {
      case 'email_confirmation':
        return AuthCodeType.emailConfirmation;
      case 'password_reset':
        return AuthCodeType.passwordReset;
      default:
        throw ArgumentError('Invalid AuthCodeType: $value');
    }
  }
}

/// Data model for authentication codes used in email confirmation and password reset
class AuthCode {
  final String id;
  final String code;
  final String userId;
  final AuthCodeType type;
  final DateTime createdAt;
  final DateTime expiresAt;
  final bool isUsed;
  final DateTime? usedAt;

  const AuthCode({
    required this.id,
    required this.code,
    required this.userId,
    required this.type,
    required this.createdAt,
    required this.expiresAt,
    required this.isUsed,
    this.usedAt,
  });

  /// Creates an AuthCode from a database row map
  factory AuthCode.fromMap(Map<String, dynamic> map) {
    return AuthCode(
      id: map['id'] as String,
      code: map['code'] as String,
      userId: map['user_id'] as String,
      type: AuthCodeType.fromString(map['type'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
      expiresAt: DateTime.parse(map['expires_at'] as String),
      isUsed: map['is_used'] as bool,
      usedAt: map['used_at'] != null 
          ? DateTime.parse(map['used_at'] as String) 
          : null,
    );
  }

  /// Converts the AuthCode to a map for database insertion
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'code': code,
      'user_id': userId,
      'type': type.value,
      'created_at': createdAt.toIso8601String(),
      'expires_at': expiresAt.toIso8601String(),
      'is_used': isUsed,
      'used_at': usedAt?.toIso8601String(),
    };
  }

  /// Creates an AuthCode from JSON string
  factory AuthCode.fromJson(String source) {
    return AuthCode.fromMap(json.decode(source) as Map<String, dynamic>);
  }

  /// Converts the AuthCode to JSON string
  String toJson() => json.encode(toMap());

  /// Checks if the authentication code has expired
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// Checks if the authentication code is valid (not used and not expired)
  bool get isValid => !isUsed && !isExpired;

  /// Creates a copy of this AuthCode with the given fields replaced
  AuthCode copyWith({
    String? id,
    String? code,
    String? userId,
    AuthCodeType? type,
    DateTime? createdAt,
    DateTime? expiresAt,
    bool? isUsed,
    DateTime? usedAt,
  }) {
    return AuthCode(
      id: id ?? this.id,
      code: code ?? this.code,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      isUsed: isUsed ?? this.isUsed,
      usedAt: usedAt ?? this.usedAt,
    );
  }

  @override
  String toString() {
    return 'AuthCode(id: $id, code: $code, userId: $userId, type: $type, '
           'createdAt: $createdAt, expiresAt: $expiresAt, isUsed: $isUsed, '
           'usedAt: $usedAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is AuthCode &&
      other.id == id &&
      other.code == code &&
      other.userId == userId &&
      other.type == type &&
      other.createdAt == createdAt &&
      other.expiresAt == expiresAt &&
      other.isUsed == isUsed &&
      other.usedAt == usedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
      code.hashCode ^
      userId.hashCode ^
      type.hashCode ^
      createdAt.hashCode ^
      expiresAt.hashCode ^
      isUsed.hashCode ^
      usedAt.hashCode;
  }
}
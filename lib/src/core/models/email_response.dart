/// Model for email response from Azure Communication Services
class EmailResponse {
  final String id;
  final EmailStatus status;
  final String? error;
  final DateTime timestamp;

  const EmailResponse({
    required this.id,
    required this.status,
    this.error,
    required this.timestamp,
  });

  /// Creates an EmailResponse from Azure Communication Services API response
  factory EmailResponse.fromJson(Map<String, dynamic> json) {
    return EmailResponse(
      id: json['id'] as String? ?? '',
      status: _parseStatus(json['status'] as String?),
      error: json['error'] as String?,
      timestamp: DateTime.now(),
    );
  }

  /// Creates a successful EmailResponse
  factory EmailResponse.success(String id) {
    return EmailResponse(
      id: id,
      status: EmailStatus.sent,
      timestamp: DateTime.now(),
    );
  }

  /// Creates a failed EmailResponse
  factory EmailResponse.failure(String error, [String? id]) {
    return EmailResponse(
      id: id ?? '',
      status: EmailStatus.failed,
      error: error,
      timestamp: DateTime.now(),
    );
  }

  static EmailStatus _parseStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'queued':
        return EmailStatus.queued;
      case 'sent':
        return EmailStatus.sent;
      case 'delivered':
        return EmailStatus.delivered;
      case 'failed':
        return EmailStatus.failed;
      default:
        return EmailStatus.unknown;
    }
  }

  @override
  String toString() {
    return 'EmailResponse(id: $id, status: $status, error: $error, timestamp: $timestamp)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EmailResponse &&
        other.id == id &&
        other.status == status &&
        other.error == error &&
        other.timestamp == timestamp;
  }

  @override
  int get hashCode {
    return Object.hash(id, status, error, timestamp);
  }
}

/// Enum representing the status of an email
enum EmailStatus {
  queued,
  sent,
  delivered,
  failed,
  unknown,
}
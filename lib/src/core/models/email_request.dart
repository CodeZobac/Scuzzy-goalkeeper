/// Model for email request to Azure Communication Services
class EmailRequest {
  final String to;
  final String subject;
  final String htmlContent;
  final String from;
  final String? fromName;

  const EmailRequest({
    required this.to,
    required this.subject,
    required this.htmlContent,
    required this.from,
    this.fromName,
  });

  /// Converts the email request to JSON format for Azure Communication Services API
  Map<String, dynamic> toJson() {
    return {
      'senderAddress': from,
      'content': {
        'subject': subject,
        'html': htmlContent,
      },
      'recipients': {
        'to': [
          {
            'address': to,
          }
        ],
      },
    };
  }

  @override
  String toString() {
    return 'EmailRequest(to: $to, subject: $subject, from: $from, fromName: $fromName)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EmailRequest &&
        other.to == to &&
        other.subject == subject &&
        other.htmlContent == htmlContent &&
        other.from == from &&
        other.fromName == fromName;
  }

  @override
  int get hashCode {
    return Object.hash(to, subject, htmlContent, from, fromName);
  }
}
/// Exception thrown by email service operations
class EmailServiceException implements Exception {
  final String message;
  final EmailServiceErrorType type;
  final dynamic originalError;
  final int? statusCode;

  const EmailServiceException(
    this.message,
    this.type, [
    this.originalError,
    this.statusCode,
  ]);

  @override
  String toString() {
    return 'EmailServiceException: $message (type: $type, statusCode: $statusCode)';
  }
}

/// Types of email service errors
enum EmailServiceErrorType {
  /// Azure Communication Services API errors
  azureServiceError,
  
  /// Template processing errors
  templateError,
  
  /// Database operation errors
  databaseError,
  
  /// Authentication code related errors
  authCodeError,
  
  /// Configuration errors
  configurationError,
  
  /// Network connectivity errors
  networkError,
  
  /// Authentication/authorization errors
  authenticationError,
  
  /// Rate limiting errors
  rateLimitError,
  
  /// Input validation errors
  validationError,
  
  /// Unknown or unexpected errors
  unknownError,
}
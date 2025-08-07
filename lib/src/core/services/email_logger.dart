import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

/// Comprehensive logging service for email operations
class EmailLogger {
  static const String _loggerName = 'EmailService';
  
  /// Logs debug information
  static void debug(String message, {Map<String, dynamic>? context}) {
    if (kDebugMode) {
      final contextStr = context != null ? ' | Context: ${_formatContext(context)}' : '';
      developer.log(
        message + contextStr,
        name: _loggerName,
        level: 500, // Debug level
      );
    }
  }
  
  /// Logs informational messages
  static void info(String message, {Map<String, dynamic>? context}) {
    final contextStr = context != null ? ' | Context: ${_formatContext(context)}' : '';
    developer.log(
      message + contextStr,
      name: _loggerName,
      level: 800, // Info level
    );
  }
  
  /// Logs warning messages
  static void warning(String message, {Map<String, dynamic>? context}) {
    final contextStr = context != null ? ' | Context: ${_formatContext(context)}' : '';
    developer.log(
      message + contextStr,
      name: _loggerName,
      level: 900, // Warning level
    );
  }
  
  /// Logs error messages
  static void error(String message, {
    dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  }) {
    final contextStr = context != null ? ' | Context: ${_formatContext(context)}' : '';
    final errorStr = error != null ? ' | Error: $error' : '';
    
    developer.log(
      message + contextStr + errorStr,
      name: _loggerName,
      level: 1000, // Error level
      error: error,
      stackTrace: stackTrace,
    );
  }
  
  /// Logs Azure API call attempts
  static void logApiCall({
    required String operation,
    required String endpoint,
    required int attempt,
    required int maxAttempts,
    Map<String, dynamic>? requestData,
  }) {
    info(
      'Azure API Call: $operation (attempt $attempt/$maxAttempts)',
      context: {
        'endpoint': endpoint,
        'attempt': attempt,
        'maxAttempts': maxAttempts,
        if (requestData != null) 'requestData': _sanitizeRequestData(requestData),
      },
    );
  }
  
  /// Logs Azure API call responses
  static void logApiResponse({
    required String operation,
    required int statusCode,
    required bool success,
    String? messageId,
    String? errorMessage,
    Duration? duration,
  }) {
    final level = success ? 'info' : 'error';
    final message = 'Azure API Response: $operation - ${success ? 'SUCCESS' : 'FAILED'} ($statusCode)';
    
    final context = {
      'statusCode': statusCode,
      'success': success,
      if (messageId != null) 'messageId': messageId,
      if (errorMessage != null) 'errorMessage': errorMessage,
      if (duration != null) 'duration': '${duration.inMilliseconds}ms',
    };
    
    if (success) {
      info(message, context: context);
    } else {
      error(message, context: context);
    }
  }
  
  /// Logs retry attempts
  static void logRetryAttempt({
    required String operation,
    required int attempt,
    required int maxAttempts,
    required Duration delay,
    required String reason,
  }) {
    warning(
      'Retrying $operation (attempt $attempt/$maxAttempts) after ${delay.inMilliseconds}ms',
      context: {
        'operation': operation,
        'attempt': attempt,
        'maxAttempts': maxAttempts,
        'delayMs': delay.inMilliseconds,
        'reason': reason,
      },
    );
  }
  
  /// Logs email sending operations
  static void logEmailOperation({
    required String operation,
    required String emailType,
    String? recipientEmail,
    String? userId,
    bool? success,
    String? errorMessage,
    Duration? duration,
  }) {
    final message = 'Email Operation: $operation - $emailType';
    final context = {
      'operation': operation,
      'emailType': emailType,
      if (recipientEmail != null) 'recipientEmail': _maskEmail(recipientEmail),
      if (userId != null) 'userId': userId,
      if (success != null) 'success': success,
      if (errorMessage != null) 'errorMessage': errorMessage,
      if (duration != null) 'duration': '${duration.inMilliseconds}ms',
    };
    
    if (success == true) {
      info(message, context: context);
    } else if (success == false) {
      error(message, context: context);
    } else {
      debug(message, context: context);
    }
  }
  
  /// Logs authentication code operations
  static void logAuthCodeOperation({
    required String operation,
    required String codeType,
    String? userId,
    bool? success,
    String? errorMessage,
  }) {
    final message = 'Auth Code Operation: $operation - $codeType';
    final context = {
      'operation': operation,
      'codeType': codeType,
      if (userId != null) 'userId': userId,
      if (success != null) 'success': success,
      if (errorMessage != null) 'errorMessage': errorMessage,
    };
    
    if (success == true) {
      info(message, context: context);
    } else if (success == false) {
      error(message, context: context);
    } else {
      debug(message, context: context);
    }
  }
  
  /// Logs template processing operations
  static void logTemplateOperation({
    required String operation,
    required String templateName,
    bool? success,
    String? errorMessage,
    Map<String, String>? variables,
  }) {
    final message = 'Template Operation: $operation - $templateName';
    final context = {
      'operation': operation,
      'templateName': templateName,
      if (success != null) 'success': success,
      if (errorMessage != null) 'errorMessage': errorMessage,
      if (variables != null) 'variableCount': variables.length,
    };
    
    if (success == true) {
      debug(message, context: context);
    } else if (success == false) {
      error(message, context: context);
    } else {
      debug(message, context: context);
    }
  }
  
  /// Formats context data for logging
  static String _formatContext(Map<String, dynamic> context) {
    final entries = context.entries
        .map((e) => '${e.key}=${e.value}')
        .join(', ');
    return '{$entries}';
  }
  
  /// Sanitizes request data to remove sensitive information
  static Map<String, dynamic> _sanitizeRequestData(Map<String, dynamic> data) {
    final sanitized = Map<String, dynamic>.from(data);
    
    // Remove or mask sensitive fields
    const sensitiveFields = ['authorization', 'password', 'token', 'key', 'secret'];
    
    for (final field in sensitiveFields) {
      if (sanitized.containsKey(field)) {
        sanitized[field] = '***MASKED***';
      }
    }
    
    // Mask email addresses in recipient fields
    if (sanitized.containsKey('to')) {
      sanitized['to'] = _maskEmail(sanitized['to'].toString());
    }
    
    return sanitized;
  }
  
  /// Masks email addresses for privacy
  static String _maskEmail(String email) {
    if (!email.contains('@')) return email;
    
    final parts = email.split('@');
    if (parts.length != 2) return email;
    
    final username = parts[0];
    final domain = parts[1];
    
    if (username.length <= 2) {
      return '${username[0]}***@$domain';
    } else {
      return '${username[0]}***${username[username.length - 1]}@$domain';
    }
  }
}
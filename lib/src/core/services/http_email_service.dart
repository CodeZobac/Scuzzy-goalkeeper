import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

import '../models/email_response.dart';
import '../exceptions/email_service_exception.dart';
import '../config/app_config.dart';
import 'email_logger.dart';
import 'email_error_handler.dart';

/// HTTP-based email service for communicating with Python backend
/// 
/// This service replaces the Azure-specific email service and communicates
/// with the Python FastAPI backend for all email operations.
class HttpEmailService {
  static const int _maxRetries = 3;
  static const Duration _baseRetryDelay = Duration(seconds: 1);
  static const Duration _requestTimeout = Duration(seconds: 30);
  
  final http.Client _httpClient;
  final String _backendBaseUrl;
  
  HttpEmailService({
    http.Client? httpClient,
    String? backendBaseUrl,
  }) : _httpClient = httpClient ?? http.Client(),
       _backendBaseUrl = backendBaseUrl ?? _getBackendUrl();

  /// Sends a confirmation email via the Python backend
  /// 
  /// This method sends an HTTP request to the backend which handles:
  /// - Authentication code generation
  /// - Email template processing
  /// - Azure Communication Services integration
  /// 
  /// [email] The recipient email address
  /// [userId] The user ID for the recipient
  Future<EmailResponse> sendConfirmationEmail(
    String email,
    String userId,
  ) async {
    final stopwatch = Stopwatch()..start();
    
    EmailLogger.logEmailOperation(
      operation: 'sendConfirmationEmail',
      emailType: 'email_confirmation',
      recipientEmail: email,
      userId: userId,
    );
    
    try {
      final response = await _sendEmailWithRetry(
        endpoint: '/api/v1/send-confirmation',
        requestData: {
          'email': email,
          'user_id': userId,
        },
      );
      
      stopwatch.stop();
      EmailLogger.logEmailOperation(
        operation: 'sendConfirmationEmail',
        emailType: 'email_confirmation',
        recipientEmail: email,
        userId: userId,
        success: true,
        duration: stopwatch.elapsed,
      );
      
      EmailLogger.info('Confirmation email sent successfully via Python backend');
      
      return response;
    } catch (e) {
      stopwatch.stop();
      
      if (e is EmailServiceException) {
        EmailLogger.logEmailOperation(
          operation: 'sendConfirmationEmail',
          emailType: 'email_confirmation',
          recipientEmail: email,
          userId: userId,
          success: false,
          errorMessage: EmailErrorHandler.getUserFriendlyMessage(e),
          duration: stopwatch.elapsed,
        );
        rethrow;
      }
      
      final exception = EmailServiceException(
        'Failed to send confirmation email: $e',
        EmailServiceErrorType.backendError,
        e,
      );
      
      EmailLogger.logEmailOperation(
        operation: 'sendConfirmationEmail',
        emailType: 'email_confirmation',
        recipientEmail: email,
        userId: userId,
        success: false,
        errorMessage: EmailErrorHandler.getUserFriendlyMessage(exception),
        duration: stopwatch.elapsed,
      );
      
      throw exception;
    }
  }

  /// Sends a password reset email via the Python backend
  /// 
  /// This method sends an HTTP request to the backend which handles:
  /// - Authentication code generation
  /// - Email template processing
  /// - Azure Communication Services integration
  /// 
  /// [email] The recipient email address
  /// [userId] The user ID for the recipient
  Future<EmailResponse> sendPasswordResetEmail(
    String email,
    String userId,
  ) async {
    final stopwatch = Stopwatch()..start();
    
    EmailLogger.logEmailOperation(
      operation: 'sendPasswordResetEmail',
      emailType: 'password_reset',
      recipientEmail: email,
      userId: userId,
    );
    
    try {
      final response = await _sendEmailWithRetry(
        endpoint: '/api/v1/send-password-reset',
        requestData: {
          'email': email,
          'user_id': userId,
        },
      );
      
      stopwatch.stop();
      EmailLogger.logEmailOperation(
        operation: 'sendPasswordResetEmail',
        emailType: 'password_reset',
        recipientEmail: email,
        userId: userId,
        success: true,
        duration: stopwatch.elapsed,
      );
      
      EmailLogger.info('Password reset email sent successfully via Python backend');
      
      return response;
    } catch (e) {
      stopwatch.stop();
      
      if (e is EmailServiceException) {
        EmailLogger.logEmailOperation(
          operation: 'sendPasswordResetEmail',
          emailType: 'password_reset',
          recipientEmail: email,
          userId: userId,
          success: false,
          errorMessage: EmailErrorHandler.getUserFriendlyMessage(e),
          duration: stopwatch.elapsed,
        );
        rethrow;
      }
      
      final exception = EmailServiceException(
        'Failed to send password reset email: $e',
        EmailServiceErrorType.backendError,
        e,
      );
      
      EmailLogger.logEmailOperation(
        operation: 'sendPasswordResetEmail',
        emailType: 'password_reset',
        recipientEmail: email,
        userId: userId,
        success: false,
        errorMessage: EmailErrorHandler.getUserFriendlyMessage(exception),
        duration: stopwatch.elapsed,
      );
      
      throw exception;
    }
  }

  /// Validates an authentication code via the Python backend
  /// 
  /// [code] The authentication code to validate
  /// [codeType] The type of code ('email_confirmation' or 'password_reset')
  Future<Map<String, dynamic>?> validateAuthCode(
    String code,
    String codeType,
  ) async {
    final stopwatch = Stopwatch()..start();
    
    EmailLogger.logEmailOperation(
      operation: 'validateAuthCode',
      emailType: codeType,
    );
    
    try {
      final url = Uri.parse('$_backendBaseUrl/api/v1/validate-code');
      
      EmailLogger.logApiCall(
        operation: 'validateAuthCode',
        endpoint: url.toString(),
        attempt: 1,
        maxAttempts: 1,
        requestData: {
          'code': code,
          'code_type': codeType,
        },
      );
      
      final response = await _httpClient.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'code': code,
          'code_type': codeType,
        }),
      ).timeout(_requestTimeout);
      
      stopwatch.stop();
      
      EmailLogger.logApiResponse(
        operation: 'validateAuthCode',
        statusCode: response.statusCode,
        success: response.statusCode == 200,
        duration: stopwatch.elapsed,
      );
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        
        EmailLogger.logEmailOperation(
          operation: 'validateAuthCode',
          emailType: codeType,
          success: true,
          duration: stopwatch.elapsed,
        );
        
        return responseData;
      } else if (response.statusCode == 400 || response.statusCode == 404) {
        // Invalid or expired code
        EmailLogger.logEmailOperation(
          operation: 'validateAuthCode',
          emailType: codeType,
          success: false,
          errorMessage: 'Invalid or expired code',
          duration: stopwatch.elapsed,
        );
        
        return null;
      } else {
        throw _createExceptionFromResponse(response);
      }
    } on SocketException catch (e) {
      stopwatch.stop();
      
      final exception = EmailServiceException(
        'Network connection failed: ${e.message}',
        EmailServiceErrorType.networkError,
        e,
      );
      
      EmailLogger.logApiResponse(
        operation: 'validateAuthCode',
        statusCode: 0,
        success: false,
        errorMessage: exception.message,
        duration: stopwatch.elapsed,
      );
      
      throw exception;
    } catch (e) {
      stopwatch.stop();
      
      if (e is EmailServiceException) {
        rethrow;
      }
      
      final exception = EmailServiceException(
        'Failed to validate authentication code: $e',
        EmailServiceErrorType.unknownError,
        e,
      );
      
      EmailLogger.logApiResponse(
        operation: 'validateAuthCode',
        statusCode: 0,
        success: false,
        errorMessage: exception.message,
        duration: stopwatch.elapsed,
      );
      
      throw exception;
    }
  }

  /// Sends email request with retry logic
  Future<EmailResponse> _sendEmailWithRetry({
    required String endpoint,
    required Map<String, dynamic> requestData,
  }) async {
    EmailServiceException? lastException;
    
    for (int attempt = 1; attempt <= _maxRetries; attempt++) {
      try {
        EmailLogger.logApiCall(
          operation: 'sendEmail',
          endpoint: '$_backendBaseUrl$endpoint',
          attempt: attempt,
          maxAttempts: _maxRetries,
          requestData: requestData,
        );
        
        final response = await _sendHttpRequest(endpoint, requestData);
        
        if (attempt > 1) {
          EmailLogger.info('Email sending succeeded after $attempt attempts');
        }
        
        return response;
      } catch (e) {
        final exception = e is EmailServiceException 
            ? e 
            : EmailServiceException(
                'Unexpected error: $e',
                EmailServiceErrorType.unknownError,
                e,
              );
        
        lastException = exception;
        
        // Log the error
        EmailLogger.error(
          'Email sending attempt $attempt failed',
          error: exception,
          context: {
            'attempt': attempt,
            'maxAttempts': _maxRetries,
            'errorType': exception.type.toString(),
            'statusCode': exception.statusCode,
          },
        );
        
        // Check if we should retry this error
        if (!EmailErrorHandler.shouldAutoRetry(exception)) {
          EmailLogger.warning(
            'Error type ${exception.type} is not retryable, failing immediately',
            context: {'errorType': exception.type.toString()},
          );
          rethrow;
        }
        
        // If this is the last attempt, throw the exception
        if (attempt == _maxRetries) {
          EmailLogger.error(
            'All retry attempts exhausted, failing',
            context: {
              'totalAttempts': _maxRetries,
              'finalError': exception.message,
            },
          );
          break;
        }
        
        // Calculate delay for next retry
        final delay = EmailErrorHandler.getRetryDelay(exception, attempt);
        
        EmailLogger.logRetryAttempt(
          operation: 'sendEmail',
          attempt: attempt,
          maxAttempts: _maxRetries,
          delay: delay,
          reason: exception.message,
        );
        
        // Wait before retrying
        await Future.delayed(delay);
      }
    }
    
    // If we get here, all retries failed
    EmailLogger.error(
      'Email sending failed after all retry attempts',
      error: lastException,
      context: {
        'totalAttempts': _maxRetries,
        'userFriendlyMessage': lastException != null 
            ? EmailErrorHandler.getUserFriendlyMessage(lastException!)
            : 'Unknown error',
      },
    );
    
    throw lastException!;
  }

  /// Makes the actual HTTP request to the Python backend
  Future<EmailResponse> _sendHttpRequest(
    String endpoint,
    Map<String, dynamic> requestData,
  ) async {
    final url = Uri.parse('$_backendBaseUrl$endpoint');
    final stopwatch = Stopwatch()..start();
    
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    EmailLogger.debug(
      'Making HTTP request to Python backend',
      context: {
        'url': url.toString(),
        'method': 'POST',
      },
    );

    try {
      final response = await _httpClient.post(
        url,
        headers: headers,
        body: jsonEncode(requestData),
      ).timeout(_requestTimeout);

      stopwatch.stop();
      
      EmailLogger.logApiResponse(
        operation: 'sendEmail',
        statusCode: response.statusCode,
        success: response.statusCode == 200,
        duration: stopwatch.elapsed,
      );

      return _handleResponse(response);
    } on SocketException catch (e) {
      stopwatch.stop();
      
      final exception = EmailServiceException(
        'Network connection failed: ${e.message}',
        EmailServiceErrorType.networkError,
        e,
      );
      
      EmailLogger.logApiResponse(
        operation: 'sendEmail',
        statusCode: 0,
        success: false,
        errorMessage: exception.message,
        duration: stopwatch.elapsed,
      );
      
      throw exception;
    } on HttpException catch (e) {
      stopwatch.stop();
      
      final exception = EmailServiceException(
        'HTTP protocol error: ${e.message}',
        EmailServiceErrorType.backendError,
        e,
      );
      
      EmailLogger.logApiResponse(
        operation: 'sendEmail',
        statusCode: 0,
        success: false,
        errorMessage: exception.message,
        duration: stopwatch.elapsed,
      );
      
      throw exception;
    } catch (e) {
      stopwatch.stop();
      
      final exception = EmailServiceException(
        'Unexpected error during HTTP request: $e',
        EmailServiceErrorType.unknownError,
        e,
      );
      
      EmailLogger.logApiResponse(
        operation: 'sendEmail',
        statusCode: 0,
        success: false,
        errorMessage: exception.message,
        duration: stopwatch.elapsed,
      );
      
      throw exception;
    }
  }

  /// Handles the HTTP response from the Python backend
  EmailResponse _handleResponse(http.Response response) {
    EmailLogger.debug(
      'Processing Python backend API response',
      context: {
        'statusCode': response.statusCode,
        'responseLength': response.body.length,
      },
    );
    
    switch (response.statusCode) {
      case 200: // Success
        try {
          final responseData = jsonDecode(response.body) as Map<String, dynamic>;
          final messageId = responseData['message_id'] as String?;
          final success = responseData['success'] as bool? ?? true;
          final message = responseData['message'] as String? ?? 'Email sent successfully';
          
          if (!success) {
            throw EmailServiceException(
              message,
              EmailServiceErrorType.backendError,
            );
          }
          
          EmailLogger.info(
            'Email accepted by Python backend',
            context: {'messageId': messageId ?? 'unknown'},
          );
          
          return EmailResponse.success(messageId ?? _generateMessageId());
        } catch (e) {
          if (e is EmailServiceException) {
            rethrow;
          }
          // If we can't parse the response, still consider it successful
          final messageId = _generateMessageId();
          
          EmailLogger.warning(
            'Could not parse backend response body, but request was successful',
            context: {
              'generatedMessageId': messageId,
              'parseError': e.toString(),
            },
          );
          
          return EmailResponse.success(messageId);
        }
        
      default:
        throw _createExceptionFromResponse(response);
    }
  }

  /// Creates an appropriate exception from HTTP response
  EmailServiceException _createExceptionFromResponse(http.Response response) {
    String message;
    EmailServiceErrorType errorType;
    
    try {
      final errorData = jsonDecode(response.body) as Map<String, dynamic>;
      message = errorData['message'] as String? ?? 'Backend error occurred';
      
      // Map backend error types to local error types
      final backendErrorType = errorData['error_type'] as String?;
      switch (backendErrorType) {
        case 'validation_error':
          errorType = EmailServiceErrorType.validationError;
          break;
        case 'authentication_error':
          errorType = EmailServiceErrorType.authenticationError;
          break;
        case 'rate_limit_error':
          errorType = EmailServiceErrorType.rateLimitError;
          break;
        case 'azure_service_error':
          errorType = EmailServiceErrorType.azureServiceError;
          break;
        default:
          errorType = EmailServiceErrorType.backendError;
      }
    } catch (e) {
      // If we can't parse the error response
      message = 'Backend returned error ${response.statusCode}';
      errorType = EmailServiceErrorType.backendError;
    }
    
    switch (response.statusCode) {
      case 400:
        errorType = EmailServiceErrorType.validationError;
        break;
      case 401:
      case 403:
        errorType = EmailServiceErrorType.authenticationError;
        break;
      case 429:
        errorType = EmailServiceErrorType.rateLimitError;
        break;
      case 500:
      case 502:
      case 503:
      case 504:
        errorType = EmailServiceErrorType.backendError;
        break;
    }
    
    final exception = EmailServiceException(
      message,
      errorType,
      null,
      response.statusCode,
    );
    
    EmailLogger.error(
      'Python backend error',
      error: exception,
      context: {
        'statusCode': response.statusCode,
        'responseBody': response.body.length > 500 
            ? '${response.body.substring(0, 500)}...' 
            : response.body,
      },
    );
    
    return exception;
  }

  /// Gets the backend URL from environment configuration
  static String _getBackendUrl() {
    return AppConfig.backendBaseUrl;
  }

  /// Generates a unique message ID for tracking
  String _generateMessageId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'http_msg_$timestamp';
  }

  /// Disposes of the HTTP client
  void dispose() {
    _httpClient.close();
  }
}

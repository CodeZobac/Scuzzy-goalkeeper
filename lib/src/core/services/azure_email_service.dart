import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:http/http.dart' as http;

import '../config/azure_config.dart';
import '../models/email_request.dart';
import '../models/email_response.dart';
import '../exceptions/email_service_exception.dart';
import 'email_template_manager.dart';
import 'email_logger.dart';
import 'email_error_handler.dart';

/// Service for sending emails via Azure Communication Services
class AzureEmailService {
  static const int _maxRetries = 3;
  static const Duration _baseRetryDelay = Duration(seconds: 1);
  
  final http.Client _httpClient;
  
  AzureEmailService({http.Client? httpClient}) 
      : _httpClient = httpClient ?? http.Client();

  /// Sends an email using Azure Communication Services
  Future<EmailResponse> sendEmail(EmailRequest emailRequest) async {
    final stopwatch = Stopwatch()..start();
    
    EmailLogger.logEmailOperation(
      operation: 'sendEmail',
      emailType: 'generic',
      recipientEmail: emailRequest.to,
    );
    
    try {
      // Validate configuration before attempting to send
      EmailLogger.debug('Validating Azure configuration');
      AzureConfig.validateConfiguration();
      
      final response = await _sendEmailWithRetry(emailRequest);
      
      stopwatch.stop();
      EmailLogger.logEmailOperation(
        operation: 'sendEmail',
        emailType: 'generic',
        recipientEmail: emailRequest.to,
        success: true,
        duration: stopwatch.elapsed,
      );
      
      return response;
    } catch (e) {
      stopwatch.stop();
      
      if (e is EmailServiceException) {
        EmailLogger.error(
          'Email sending failed: ${e.message}',
          error: e,
          context: {
            'errorType': e.type.toString(),
            'statusCode': e.statusCode,
            'duration': '${stopwatch.elapsed.inMilliseconds}ms',
          },
        );
        
        EmailLogger.logEmailOperation(
          operation: 'sendEmail',
          emailType: 'generic',
          recipientEmail: emailRequest.to,
          success: false,
          errorMessage: EmailErrorHandler.getUserFriendlyMessage(e),
          duration: stopwatch.elapsed,
        );
        
        rethrow;
      }
      
      final exception = EmailServiceException(
        'Failed to send email: $e',
        EmailServiceErrorType.unknownError,
        e,
      );
      
      EmailLogger.error(
        'Unexpected error sending email',
        error: e,
        context: {
          'duration': '${stopwatch.elapsed.inMilliseconds}ms',
        },
      );
      
      EmailLogger.logEmailOperation(
        operation: 'sendEmail',
        emailType: 'generic',
        recipientEmail: emailRequest.to,
        success: false,
        errorMessage: EmailErrorHandler.getUserFriendlyMessage(exception),
        duration: stopwatch.elapsed,
      );
      
      throw exception;
    }
  }

  /// Sends a confirmation email for user signup
  Future<EmailResponse> sendConfirmationEmail(
    String email,
    String userId,
    String authCode,
  ) async {
    final stopwatch = Stopwatch()..start();
    
    EmailLogger.logEmailOperation(
      operation: 'sendConfirmationEmail',
      emailType: 'email_confirmation',
      recipientEmail: email,
      userId: userId,
    );
    
    try {
      EmailLogger.debug('Building confirmation email template');
      final htmlContent = await EmailTemplateManager.buildConfirmationEmail(authCode);
      
      final emailRequest = EmailRequest(
        to: email,
        subject: 'Confirme o seu E-mail - Goalkeeper-Finder',
        htmlContent: htmlContent,
        from: AzureConfig.fromAddress,
        fromName: AzureConfig.fromName,
      );

      final response = await sendEmail(emailRequest);
      
      stopwatch.stop();
      EmailLogger.logEmailOperation(
        operation: 'sendConfirmationEmail',
        emailType: 'email_confirmation',
        recipientEmail: email,
        userId: userId,
        success: true,
        duration: stopwatch.elapsed,
      );
      
      EmailLogger.info(EmailErrorHandler.getEmailSendingMessage('confirmation'));
      
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
        EmailServiceErrorType.templateError,
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

  /// Sends a password reset email
  Future<EmailResponse> sendPasswordResetEmail(
    String email,
    String userId,
    String authCode,
  ) async {
    final stopwatch = Stopwatch()..start();
    
    EmailLogger.logEmailOperation(
      operation: 'sendPasswordResetEmail',
      emailType: 'password_reset',
      recipientEmail: email,
      userId: userId,
    );
    
    try {
      EmailLogger.debug('Building password reset email template');
      final htmlContent = await EmailTemplateManager.buildPasswordResetEmail(authCode);
      
      final emailRequest = EmailRequest(
        to: email,
        subject: 'Recuperação de Palavra-passe - Goalkeeper-Finder',
        htmlContent: htmlContent,
        from: AzureConfig.fromAddress,
        fromName: AzureConfig.fromName,
      );

      final response = await sendEmail(emailRequest);
      
      stopwatch.stop();
      EmailLogger.logEmailOperation(
        operation: 'sendPasswordResetEmail',
        emailType: 'password_reset',
        recipientEmail: email,
        userId: userId,
        success: true,
        duration: stopwatch.elapsed,
      );
      
      EmailLogger.info(EmailErrorHandler.getEmailSendingMessage('password_reset'));
      
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
        EmailServiceErrorType.templateError,
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

  /// Sends email with retry logic and comprehensive error handling
  Future<EmailResponse> _sendEmailWithRetry(EmailRequest emailRequest) async {
    EmailServiceException? lastException;
    
    for (int attempt = 1; attempt <= _maxRetries; attempt++) {
      try {
        EmailLogger.logApiCall(
          operation: 'sendEmail',
          endpoint: '${AzureConfig.emailServiceEndpoint}emails:send',
          attempt: attempt,
          maxAttempts: _maxRetries,
          requestData: {
            'to': emailRequest.to,
            'subject': emailRequest.subject,
            'from': emailRequest.from,
          },
        );
        
        final response = await _sendEmailRequest(emailRequest);
        
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

  /// Makes the actual HTTP request to Azure Communication Services
  Future<EmailResponse> _sendEmailRequest(EmailRequest emailRequest) async {
    final url = Uri.parse('${AzureConfig.emailServiceEndpoint}emails:send?api-version=2023-03-31');
    final stopwatch = Stopwatch()..start();
    
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${AzureConfig.azureKey}',
      'Accept': 'application/json',
    };

    EmailLogger.debug(
      'Making HTTP request to Azure Communication Services',
      context: {
        'url': url.toString(),
        'method': 'POST',
      },
    );

    try {
      final response = await _httpClient.post(
        url,
        headers: headers,
        body: jsonEncode(emailRequest.toJson()),
      );

      stopwatch.stop();
      
      EmailLogger.logApiResponse(
        operation: 'sendEmail',
        statusCode: response.statusCode,
        success: response.statusCode == 202,
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
        EmailServiceErrorType.azureServiceError,
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
    } on FormatException catch (e) {
      stopwatch.stop();
      
      final exception = EmailServiceException(
        'Invalid request format: ${e.message}',
        EmailServiceErrorType.validationError,
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

  /// Handles the HTTP response from Azure Communication Services
  EmailResponse _handleResponse(http.Response response) {
    EmailLogger.debug(
      'Processing Azure API response',
      context: {
        'statusCode': response.statusCode,
        'responseLength': response.body.length,
      },
    );
    
    switch (response.statusCode) {
      case 202: // Accepted
        try {
          final responseData = jsonDecode(response.body) as Map<String, dynamic>;
          final messageId = responseData['id'] as String? ?? 
                           responseData['messageId'] as String? ?? 
                           _generateMessageId();
          
          EmailLogger.info(
            'Email accepted by Azure Communication Services',
            context: {'messageId': messageId},
          );
          
          return EmailResponse.success(messageId);
        } catch (e) {
          // If we can't parse the response, still consider it successful
          final messageId = _generateMessageId();
          
          EmailLogger.warning(
            'Could not parse Azure response body, but request was accepted',
            context: {
              'generatedMessageId': messageId,
              'parseError': e.toString(),
            },
          );
          
          return EmailResponse.success(messageId);
        }
        
      case 400: // Bad Request
        final exception = EmailServiceException(
          'Invalid request format or parameters',
          EmailServiceErrorType.validationError,
          null,
          response.statusCode,
        );
        
        EmailLogger.error(
          'Azure API returned bad request',
          error: exception,
          context: {
            'statusCode': response.statusCode,
            'responseBody': response.body,
          },
        );
        
        throw exception;
        
      case 401: // Unauthorized
        final exception = EmailServiceException(
          'Authentication failed: Invalid or expired Azure key',
          EmailServiceErrorType.authenticationError,
          null,
          response.statusCode,
        );
        
        EmailLogger.error(
          'Azure API authentication failed',
          error: exception,
          context: {
            'statusCode': response.statusCode,
            'hint': 'Check AZURE_KEY environment variable',
          },
        );
        
        throw exception;
        
      case 403: // Forbidden
        final exception = EmailServiceException(
          'Access forbidden: Insufficient permissions or invalid sender domain',
          EmailServiceErrorType.authenticationError,
          null,
          response.statusCode,
        );
        
        EmailLogger.error(
          'Azure API access forbidden',
          error: exception,
          context: {
            'statusCode': response.statusCode,
            'hint': 'Check Azure Communication Services permissions and sender domain',
          },
        );
        
        throw exception;
        
      case 429: // Too Many Requests
        final exception = EmailServiceException(
          'Rate limit exceeded - too many requests',
          EmailServiceErrorType.rateLimitError,
          null,
          response.statusCode,
        );
        
        EmailLogger.warning(
          'Azure API rate limit exceeded',
          context: {
            'statusCode': response.statusCode,
            'retryAfter': response.headers['retry-after'],
          },
        );
        
        throw exception;
        
      case 500: // Internal Server Error
      case 502: // Bad Gateway
      case 503: // Service Unavailable
      case 504: // Gateway Timeout
        final exception = EmailServiceException(
          'Azure service temporarily unavailable (${response.statusCode})',
          EmailServiceErrorType.azureServiceError,
          null,
          response.statusCode,
        );
        
        EmailLogger.error(
          'Azure service error',
          error: exception,
          context: {
            'statusCode': response.statusCode,
            'responseBody': response.body.length > 500 
                ? '${response.body.substring(0, 500)}...' 
                : response.body,
          },
        );
        
        throw exception;
        
      default:
        final exception = EmailServiceException(
          'Unexpected Azure API response (${response.statusCode})',
          EmailServiceErrorType.azureServiceError,
          null,
          response.statusCode,
        );
        
        EmailLogger.error(
          'Unexpected Azure API response',
          error: exception,
          context: {
            'statusCode': response.statusCode,
            'responseBody': response.body.length > 500 
                ? '${response.body.substring(0, 500)}...' 
                : response.body,
          },
        );
        
        throw exception;
    }
  }



  /// Generates a unique message ID for tracking
  String _generateMessageId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(999999);
    return 'msg_${timestamp}_$random';
  }

  /// Disposes of the HTTP client
  void dispose() {
    _httpClient.close();
  }
}
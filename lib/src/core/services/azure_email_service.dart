import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:http/http.dart' as http;

import '../config/azure_config.dart';
import '../models/email_request.dart';
import '../models/email_response.dart';
import '../exceptions/email_service_exception.dart';
import 'email_template_manager.dart';

/// Service for sending emails via Azure Communication Services
class AzureEmailService {
  static const int _maxRetries = 3;
  static const Duration _baseRetryDelay = Duration(seconds: 1);
  
  final http.Client _httpClient;
  
  AzureEmailService({http.Client? httpClient}) 
      : _httpClient = httpClient ?? http.Client();

  /// Sends an email using Azure Communication Services
  Future<EmailResponse> sendEmail(EmailRequest emailRequest) async {
    try {
      AzureConfig.validateConfiguration();
      
      return await _sendEmailWithRetry(emailRequest);
    } catch (e) {
      if (e is EmailServiceException) {
        rethrow;
      }
      throw EmailServiceException(
        'Failed to send email: $e',
        EmailServiceErrorType.unknownError,
        e,
      );
    }
  }

  /// Sends a confirmation email for user signup
  Future<EmailResponse> sendConfirmationEmail(
    String email,
    String userId,
    String authCode,
  ) async {
    try {
      final htmlContent = await EmailTemplateManager.buildConfirmationEmail(authCode);
      
      final emailRequest = EmailRequest(
        to: email,
        subject: 'Confirme o seu E-mail - Goalkeeper-Finder',
        htmlContent: htmlContent,
        from: AzureConfig.fromAddress,
        fromName: AzureConfig.fromName,
      );

      return await sendEmail(emailRequest);
    } catch (e) {
      if (e is EmailServiceException) {
        rethrow;
      }
      throw EmailServiceException(
        'Failed to send confirmation email: $e',
        EmailServiceErrorType.templateError,
        e,
      );
    }
  }

  /// Sends a password reset email
  Future<EmailResponse> sendPasswordResetEmail(
    String email,
    String userId,
    String authCode,
  ) async {
    try {
      final htmlContent = await EmailTemplateManager.buildPasswordResetEmail(authCode);
      
      final emailRequest = EmailRequest(
        to: email,
        subject: 'Recuperação de Palavra-passe - Goalkeeper-Finder',
        htmlContent: htmlContent,
        from: AzureConfig.fromAddress,
        fromName: AzureConfig.fromName,
      );

      return await sendEmail(emailRequest);
    } catch (e) {
      if (e is EmailServiceException) {
        rethrow;
      }
      throw EmailServiceException(
        'Failed to send password reset email: $e',
        EmailServiceErrorType.templateError,
        e,
      );
    }
  }

  /// Sends email with retry logic
  Future<EmailResponse> _sendEmailWithRetry(EmailRequest emailRequest) async {
    Exception? lastException;
    
    for (int attempt = 0; attempt < _maxRetries; attempt++) {
      try {
        return await _sendEmailRequest(emailRequest);
      } catch (e) {
        lastException = e is Exception ? e : Exception(e.toString());
        
        // Don't retry on authentication or configuration errors
        if (e is EmailServiceException) {
          if (e.type == EmailServiceErrorType.authenticationError ||
              e.type == EmailServiceErrorType.configurationError) {
            rethrow;
          }
        }
        
        // If this is the last attempt, throw the exception
        if (attempt == _maxRetries - 1) {
          break;
        }
        
        // Wait before retrying with exponential backoff
        final delay = _baseRetryDelay * pow(2, attempt);
        await Future.delayed(delay);
      }
    }
    
    throw lastException!;
  }

  /// Makes the actual HTTP request to Azure Communication Services
  Future<EmailResponse> _sendEmailRequest(EmailRequest emailRequest) async {
    final url = Uri.parse('${AzureConfig.emailServiceEndpoint}emails:send?api-version=2023-03-31');
    
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${AzureConfig.azureKey}',
      'Accept': 'application/json',
    };

    try {
      final response = await _httpClient.post(
        url,
        headers: headers,
        body: jsonEncode(emailRequest.toJson()),
      );

      return _handleResponse(response);
    } on SocketException catch (e) {
      throw EmailServiceException(
        'Network error: ${e.message}',
        EmailServiceErrorType.networkError,
        e,
      );
    } on HttpException catch (e) {
      throw EmailServiceException(
        'HTTP error: ${e.message}',
        EmailServiceErrorType.azureServiceError,
        e,
      );
    } catch (e) {
      throw EmailServiceException(
        'Unexpected error sending email: $e',
        EmailServiceErrorType.unknownError,
        e,
      );
    }
  }

  /// Handles the HTTP response from Azure Communication Services
  EmailResponse _handleResponse(http.Response response) {
    switch (response.statusCode) {
      case 202: // Accepted
        try {
          final responseData = jsonDecode(response.body) as Map<String, dynamic>;
          final messageId = responseData['id'] as String? ?? 
                           responseData['messageId'] as String? ?? 
                           _generateMessageId();
          return EmailResponse.success(messageId);
        } catch (e) {
          // If we can't parse the response, still consider it successful
          return EmailResponse.success(_generateMessageId());
        }
        
      case 400: // Bad Request
        throw EmailServiceException(
          'Bad request: ${response.body}',
          EmailServiceErrorType.azureServiceError,
          null,
          response.statusCode,
        );
        
      case 401: // Unauthorized
        throw EmailServiceException(
          'Authentication failed: Invalid Azure key',
          EmailServiceErrorType.authenticationError,
          null,
          response.statusCode,
        );
        
      case 403: // Forbidden
        throw EmailServiceException(
          'Access forbidden: Check Azure permissions',
          EmailServiceErrorType.authenticationError,
          null,
          response.statusCode,
        );
        
      case 429: // Too Many Requests
        throw EmailServiceException(
          'Rate limit exceeded',
          EmailServiceErrorType.rateLimitError,
          null,
          response.statusCode,
        );
        
      case 500: // Internal Server Error
      case 502: // Bad Gateway
      case 503: // Service Unavailable
      case 504: // Gateway Timeout
        throw EmailServiceException(
          'Azure service error: ${response.statusCode} - ${response.body}',
          EmailServiceErrorType.azureServiceError,
          null,
          response.statusCode,
        );
        
      default:
        throw EmailServiceException(
          'Unexpected response: ${response.statusCode} - ${response.body}',
          EmailServiceErrorType.azureServiceError,
          null,
          response.statusCode,
        );
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
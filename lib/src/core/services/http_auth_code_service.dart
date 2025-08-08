import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

import '../../features/auth/data/models/auth_code.dart';
import '../exceptions/email_service_exception.dart';
import '../config/app_config.dart';
import 'email_logger.dart';

/// HTTP-based authentication code service for communicating with Python backend
/// 
/// This service replaces the local AuthCodeService and communicates with the
/// Python FastAPI backend for all authentication code operations.
class HttpAuthCodeService {
  static const Duration _requestTimeout = Duration(seconds: 30);
  
  final http.Client _httpClient;
  final String _backendBaseUrl;
  
  HttpAuthCodeService({
    http.Client? httpClient,
    String? backendBaseUrl,
  }) : _httpClient = httpClient ?? http.Client(),
       _backendBaseUrl = backendBaseUrl ?? _getBackendUrl();

  /// Validates an authentication code via the Python backend
  /// 
  /// This method performs comprehensive validation through the backend:
  /// 1. Verifies the code exists and matches the stored hash
  /// 2. Checks that the code has not expired
  /// 3. Ensures the code has not been used before
  /// 4. Validates the code type matches the expected type
  /// 
  /// [plainCode] The plain text code provided by the user
  /// [type] The expected type of authentication code
  /// 
  /// Returns the AuthCode information if valid, null if invalid/expired/used
  Future<AuthCode?> validateAuthCode(String plainCode, AuthCodeType type) async {
    final stopwatch = Stopwatch()..start();
    
    EmailLogger.logEmailOperation(
      operation: 'validateAuthCode',
      emailType: type.toString(),
    );
    
    try {
      final url = Uri.parse('$_backendBaseUrl/api/v1/validate-code');
      
      EmailLogger.logApiCall(
        operation: 'validateAuthCode',
        endpoint: url.toString(),
        attempt: 1,
        maxAttempts: 1,
        requestData: {
          'code': plainCode,
          'code_type': _mapAuthCodeTypeToString(type),
        },
      );
      
      final response = await _httpClient.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'code': plainCode,
          'code_type': _mapAuthCodeTypeToString(type),
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
        final valid = responseData['valid'] as bool? ?? false;
        final userId = responseData['user_id'] as String?;
        
        if (valid && userId != null) {
          // Create a mock AuthCode object with the information from backend
          final authCode = AuthCode(
            id: 'backend_validated',
            code: plainCode, // This would normally be hashed, but we don't need it
            userId: userId,
            type: type,
            createdAt: DateTime.now().subtract(const Duration(minutes: 1)), // Mock creation time
            expiresAt: DateTime.now().add(const Duration(minutes: 4)), // Mock expiry time
            isUsed: false,
            usedAt: null,
          );
          
          EmailLogger.logEmailOperation(
            operation: 'validateAuthCode',
            emailType: type.toString(),
            userId: userId,
            success: true,
            duration: stopwatch.elapsed,
          );
          
          return authCode;
        } else {
          EmailLogger.logEmailOperation(
            operation: 'validateAuthCode',
            emailType: type.toString(),
            success: false,
            errorMessage: 'Invalid or expired code',
            duration: stopwatch.elapsed,
          );
          
          return null;
        }
      } else if (response.statusCode == 400 || response.statusCode == 404) {
        // Invalid or expired code
        EmailLogger.logEmailOperation(
          operation: 'validateAuthCode',
          emailType: type.toString(),
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
      
      final exception = HttpAuthCodeServiceException(
        'Network connection failed: ${e.message}',
        HttpAuthCodeServiceErrorType.networkError,
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
      
      if (e is HttpAuthCodeServiceException) {
        rethrow;
      }
      
      final exception = HttpAuthCodeServiceException(
        'Failed to validate authentication code: $e',
        HttpAuthCodeServiceErrorType.validationError,
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

  /// Validates and consumes an authentication code in a single operation
  /// 
  /// This method:
  /// 1. Validates the code using all security checks via the backend
  /// 2. If valid, the backend immediately marks it as used to prevent reuse
  /// 3. Returns the validated AuthCode information
  /// 
  /// This is the recommended method for code validation as it ensures
  /// one-time use enforcement through the backend.
  /// 
  /// [plainCode] The plain text code provided by the user
  /// [type] The expected type of authentication code
  /// 
  /// Returns the AuthCode if valid and successfully consumed, null if invalid
  Future<AuthCode?> validateAndConsumeAuthCode(String plainCode, AuthCodeType type) async {
    try {
      // The backend validation endpoint automatically consumes valid codes
      // So this method is effectively the same as validateAuthCode for the HTTP service
      return await validateAuthCode(plainCode, type);
    } catch (e) {
      if (e is HttpAuthCodeServiceException) {
        rethrow;
      }
      
      throw HttpAuthCodeServiceException(
        'Failed to validate and consume authentication code: $e',
        HttpAuthCodeServiceErrorType.validationError,
        e,
      );
    }
  }

  /// Checks if a plain text code is valid without consuming it
  /// 
  /// Note: With the HTTP backend, validation automatically consumes the code
  /// for security reasons, so this method is not recommended for production use.
  /// It's mainly provided for compatibility with the existing interface.
  /// 
  /// [plainCode] The plain text code to check
  /// [type] The expected type of authentication code
  /// 
  /// Returns true if the code is valid, false otherwise
  Future<bool> isCodeValid(String plainCode, AuthCodeType type) async {
    try {
      final authCode = await validateAuthCode(plainCode, type);
      return authCode != null;
    } catch (e) {
      return false; // Any exception means the code is not valid
    }
  }

  /// Maps AuthCodeType enum to string representation for API
  String _mapAuthCodeTypeToString(AuthCodeType type) {
    switch (type) {
      case AuthCodeType.emailConfirmation:
        return 'email_confirmation';
      case AuthCodeType.passwordReset:
        return 'password_reset';
    }
  }

  /// Creates an appropriate exception from HTTP response
  HttpAuthCodeServiceException _createExceptionFromResponse(http.Response response) {
    String message;
    HttpAuthCodeServiceErrorType errorType;
    
    try {
      final errorData = jsonDecode(response.body) as Map<String, dynamic>;
      message = errorData['message'] as String? ?? 'Backend error occurred';
      
      // Map backend error types to local error types
      final backendErrorType = errorData['error_type'] as String?;
      switch (backendErrorType) {
        case 'validation_error':
          errorType = HttpAuthCodeServiceErrorType.validationError;
          break;
        case 'expired':
          errorType = HttpAuthCodeServiceErrorType.expired;
          break;
        case 'already_used':
          errorType = HttpAuthCodeServiceErrorType.alreadyUsed;
          break;
        case 'not_found':
          errorType = HttpAuthCodeServiceErrorType.notFound;
          break;
        default:
          errorType = HttpAuthCodeServiceErrorType.backendError;
      }
    } catch (e) {
      // If we can't parse the error response
      message = 'Backend returned error ${response.statusCode}';
      errorType = HttpAuthCodeServiceErrorType.backendError;
    }
    
    switch (response.statusCode) {
      case 400:
        errorType = HttpAuthCodeServiceErrorType.validationError;
        break;
      case 401:
      case 403:
        errorType = HttpAuthCodeServiceErrorType.authenticationError;
        break;
      case 404:
        errorType = HttpAuthCodeServiceErrorType.notFound;
        break;
      case 429:
        errorType = HttpAuthCodeServiceErrorType.rateLimitError;
        break;
      case 500:
      case 502:
      case 503:
      case 504:
        errorType = HttpAuthCodeServiceErrorType.backendError;
        break;
    }
    
    final exception = HttpAuthCodeServiceException(
      message,
      errorType,
      null,
      response.statusCode,
    );
    
    EmailLogger.error(
      'Python backend auth code error',
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

  /// Disposes of the HTTP client
  void dispose() {
    _httpClient.close();
  }
}

/// Exception thrown by HttpAuthCodeService operations
class HttpAuthCodeServiceException implements Exception {
  final String message;
  final HttpAuthCodeServiceErrorType type;
  final dynamic originalError;
  final int? statusCode;

  const HttpAuthCodeServiceException(
    this.message,
    this.type, [
    this.originalError,
    this.statusCode,
  ]);

  @override
  String toString() => 'HttpAuthCodeServiceException: $message';
}

/// Types of errors that can occur in HttpAuthCodeService
enum HttpAuthCodeServiceErrorType {
  validationError,
  networkError,
  backendError,
  authenticationError,
  rateLimitError,
  expired,
  alreadyUsed,
  notFound,
}

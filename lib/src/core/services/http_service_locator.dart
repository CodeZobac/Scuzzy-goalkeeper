import 'package:http/http.dart' as http;

import 'http_email_service.dart';
import 'http_auth_code_service.dart';
import '../config/app_config.dart';

/// Service locator for managing HTTP-based email service dependencies
/// 
/// This class provides a centralized way to register and retrieve
/// HTTP service instances that communicate with the Python backend
/// instead of directly with Azure services.
class HttpServiceLocator {
  static final HttpServiceLocator _instance = HttpServiceLocator._internal();
  static HttpServiceLocator get instance => _instance;
  
  HttpServiceLocator._internal();

  // Service instances
  HttpEmailService? _httpEmailService;
  HttpAuthCodeService? _httpAuthCodeService;
  http.Client? _httpClient;
  String? _backendBaseUrl;

  /// Initializes all HTTP services with proper configuration
  /// 
  /// This method should be called during app startup to ensure
  /// all services are properly configured and ready for use.
  /// 
  /// [backendBaseUrl] Optional override for the backend URL
  Future<void> initialize({String? backendBaseUrl}) async {
    try {
      // Initialize HTTP client
      _httpClient = http.Client();
      
      // Set backend URL (can be overridden for testing)
      _backendBaseUrl = backendBaseUrl ?? _getBackendUrl();
      
      // Initialize HTTP email service
      _httpEmailService = HttpEmailService(
        httpClient: _httpClient!,
        backendBaseUrl: _backendBaseUrl!,
      );
      
      // Initialize HTTP auth code service
      _httpAuthCodeService = HttpAuthCodeService(
        httpClient: _httpClient!,
        backendBaseUrl: _backendBaseUrl!,
      );
      
    } catch (e) {
      throw HttpServiceLocatorException(
        'Failed to initialize HTTP services: $e',
        HttpServiceLocatorErrorType.initializationError,
        e,
      );
    }
  }

  /// Gets the HTTP email service instance
  /// 
  /// Throws [HttpServiceLocatorException] if services haven't been initialized
  HttpEmailService get httpEmailService {
    if (_httpEmailService == null) {
      throw HttpServiceLocatorException(
        'HttpEmailService not initialized. Call HttpServiceLocator.instance.initialize() first.',
        HttpServiceLocatorErrorType.notInitialized,
      );
    }
    return _httpEmailService!;
  }

  /// Gets the HTTP authentication code service instance
  /// 
  /// Throws [HttpServiceLocatorException] if services haven't been initialized
  HttpAuthCodeService get httpAuthCodeService {
    if (_httpAuthCodeService == null) {
      throw HttpServiceLocatorException(
        'HttpAuthCodeService not initialized. Call HttpServiceLocator.instance.initialize() first.',
        HttpServiceLocatorErrorType.notInitialized,
      );
    }
    return _httpAuthCodeService!;
  }

  /// Gets the HTTP client instance
  /// 
  /// Throws [HttpServiceLocatorException] if services haven't been initialized
  http.Client get httpClient {
    if (_httpClient == null) {
      throw HttpServiceLocatorException(
        'HTTP Client not initialized. Call HttpServiceLocator.instance.initialize() first.',
        HttpServiceLocatorErrorType.notInitialized,
      );
    }
    return _httpClient!;
  }

  /// Gets the configured backend base URL
  String get backendBaseUrl {
    if (_backendBaseUrl == null) {
      throw HttpServiceLocatorException(
        'Backend URL not initialized. Call HttpServiceLocator.instance.initialize() first.',
        HttpServiceLocatorErrorType.notInitialized,
      );
    }
    return _backendBaseUrl!;
  }

  /// Factory method for creating a new HTTP email service instance
  /// 
  /// This is useful for testing or when you need a fresh instance
  /// with custom configuration.
  static HttpEmailService createHttpEmailService({
    http.Client? httpClient,
    String? backendBaseUrl,
  }) {
    return HttpEmailService(
      httpClient: httpClient ?? http.Client(),
      backendBaseUrl: backendBaseUrl,
    );
  }

  /// Factory method for creating a new HTTP authentication code service instance
  /// 
  /// This is useful for testing or when you need a fresh instance
  /// with custom dependencies.
  static HttpAuthCodeService createHttpAuthCodeService({
    http.Client? httpClient,
    String? backendBaseUrl,
  }) {
    return HttpAuthCodeService(
      httpClient: httpClient ?? http.Client(),
      backendBaseUrl: backendBaseUrl,
    );
  }

  /// Checks if all services have been initialized
  bool get isInitialized {
    return _httpEmailService != null &&
           _httpAuthCodeService != null &&
           _httpClient != null &&
           _backendBaseUrl != null;
  }

  /// Disposes of all services and cleans up resources
  /// 
  /// This should be called when the app is shutting down to ensure
  /// proper cleanup of resources like HTTP clients.
  void dispose() {
    _httpEmailService?.dispose();
    _httpAuthCodeService?.dispose();
    _httpClient?.close();
    
    // Clear all instances
    _httpEmailService = null;
    _httpAuthCodeService = null;
    _httpClient = null;
    _backendBaseUrl = null;
  }

  /// Resets the service locator (useful for testing)
  /// 
  /// This method disposes of current services and resets the locator
  /// to an uninitialized state.
  void reset() {
    dispose();
  }

  /// Gets the backend URL from environment configuration
  static String _getBackendUrl() {
    // Try to get from app config first
    try {
      // This would be configured through AppConfig when properly set up
      // For now, return a default that can be overridden
      return AppConfig.backendBaseUrl.isNotEmpty 
          ? AppConfig.backendBaseUrl 
          : 'http://localhost:8000';
    } catch (e) {
      // If AppConfig doesn't have the backend URL configured,
      // return default for local development
      return 'http://localhost:8000';
    }
  }
}

/// Exception thrown by HttpServiceLocator operations
class HttpServiceLocatorException implements Exception {
  final String message;
  final HttpServiceLocatorErrorType type;
  final dynamic originalError;

  const HttpServiceLocatorException(
    this.message,
    this.type, [
    this.originalError,
  ]);

  @override
  String toString() => 'HttpServiceLocatorException: $message';
}

/// Types of errors that can occur in HttpServiceLocator
enum HttpServiceLocatorErrorType {
  initializationError,
  notInitialized,
  configurationError,
  dependencyError,
}

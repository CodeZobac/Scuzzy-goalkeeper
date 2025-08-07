import 'package:flutter/foundation.dart';

import 'http_service_locator.dart';
import 'http_email_service_providers.dart';
import '../config/app_config.dart';
import 'email_logger.dart';

/// Service initializer for HTTP-based email services
/// 
/// This class handles the initialization of all HTTP email-related services
/// during app startup with proper error handling and logging. These services
/// communicate with the Python FastAPI backend instead of directly with Azure.
class HttpEmailServiceInitializer {
  static bool _isInitialized = false;
  static HttpEmailServiceManager? _httpEmailServiceManager;

  /// Whether the HTTP email services have been initialized
  static bool get isInitialized => _isInitialized;

  /// Gets the initialized HTTP email service manager
  static HttpEmailServiceManager? get httpEmailServiceManager => _httpEmailServiceManager;

  /// Initializes all HTTP email services
  /// 
  /// This method should be called during app startup, after Supabase
  /// initialization but before the app widget is created.
  /// 
  /// Returns true if initialization was successful, false otherwise.
  static Future<bool> initialize() async {
    if (_isInitialized) {
      EmailLogger.warning('HTTP email services already initialized, skipping');
      return true;
    }

    final stopwatch = Stopwatch()..start();
    
    try {
      EmailLogger.info('Starting HTTP email services initialization');
      
      // Step 1: Validate backend configuration
      await _validateConfiguration();
      
      // Step 2: Initialize HTTP service locator
      await _initializeHttpServiceLocator();
      
      // Step 3: Initialize HTTP email service manager
      await _initializeHttpEmailServiceManager();
      
      stopwatch.stop();
      _isInitialized = true;
      
      EmailLogger.info(
        'HTTP email services initialized successfully',
        context: {
          'initializationTime': '${stopwatch.elapsedMilliseconds}ms',
          'servicesInitialized': [
            'HttpServiceLocator',
            'HttpEmailService',
            'HttpAuthCodeService',
            'HttpEmailServiceManager',
          ],
        },
      );
      
      return true;
    } catch (e) {
      stopwatch.stop();
      
      EmailLogger.error(
        'Failed to initialize HTTP email services',
        error: e,
        context: {
          'initializationTime': '${stopwatch.elapsedMilliseconds}ms',
          'failureStage': _getFailureStage(e),
        },
      );
      
      // Clean up any partially initialized services
      await _cleanup();
      
      return false;
    }
  }

  /// Validates the backend configuration
  static Future<void> _validateConfiguration() async {
    try {
      EmailLogger.debug('Validating Python backend configuration');
      
      // Check if backend URL is configured
      final backendUrl = AppConfig.backendBaseUrl;
      if (backendUrl.isEmpty) {
        throw HttpEmailServiceInitializationException(
          'Backend URL not configured. Please set the backend base URL in app configuration.',
          HttpEmailServiceInitializationStage.configurationValidation,
        );
      }
      
      EmailLogger.info(
        'Backend configuration validated successfully',
        context: {
          'backendUrl': backendUrl,
          'serviceType': 'HTTP-based (Python backend)',
        },
      );
    } catch (e) {
      // Log the specific configuration error but don't throw - let it fail gracefully
      EmailLogger.warning(
        'Backend configuration validation failed: $e',
        context: {
          'stage': 'configurationValidation',
          'canContinueWithoutEmail': true,
        },
      );
      throw HttpEmailServiceInitializationException(
        'Backend configuration validation failed: $e',
        HttpEmailServiceInitializationStage.configurationValidation,
        e,
      );
    }
  }

  /// Initializes the HTTP service locator
  static Future<void> _initializeHttpServiceLocator() async {
    try {
      EmailLogger.debug('Initializing HTTP service locator');
      await HttpServiceLocator.instance.initialize();
      
      EmailLogger.info('HTTP service locator initialized successfully');
    } catch (e) {
      throw HttpEmailServiceInitializationException(
        'HTTP service locator initialization failed: $e',
        HttpEmailServiceInitializationStage.serviceLocator,
        e,
      );
    }
  }

  /// Initializes the HTTP email service manager
  static Future<void> _initializeHttpEmailServiceManager() async {
    try {
      EmailLogger.debug('Initializing HTTP email service manager');
      _httpEmailServiceManager = HttpEmailServiceManager();
      await _httpEmailServiceManager!.initialize();
      
      EmailLogger.info('HTTP email service manager initialized successfully');
    } catch (e) {
      throw HttpEmailServiceInitializationException(
        'HTTP email service manager initialization failed: $e',
        HttpEmailServiceInitializationStage.emailServiceManager,
        e,
      );
    }
  }

  /// Gets the failure stage from an exception
  static String _getFailureStage(dynamic error) {
    if (error is HttpEmailServiceInitializationException) {
      return error.stage.toString();
    }
    return 'unknown';
  }

  /// Cleans up partially initialized services
  static Future<void> _cleanup() async {
    try {
      EmailLogger.debug('Cleaning up partially initialized HTTP services');
      
      _httpEmailServiceManager?.dispose();
      _httpEmailServiceManager = null;
      
      HttpServiceLocator.instance.dispose();
      
      _isInitialized = false;
      
      EmailLogger.info('HTTP service cleanup completed');
    } catch (e) {
      EmailLogger.error(
        'Error during HTTP service cleanup',
        error: e,
      );
    }
  }

  /// Reinitializes the HTTP email services
  /// 
  /// This method can be used to reinitialize services after configuration
  /// changes or when recovering from initialization failures.
  static Future<bool> reinitialize() async {
    EmailLogger.info('Reinitializing HTTP email services');
    
    await _cleanup();
    return await initialize();
  }

  /// Disposes of all HTTP email services
  /// 
  /// This method should be called when the app is shutting down
  /// to ensure proper cleanup of resources.
  static Future<void> dispose() async {
    if (!_isInitialized) {
      return;
    }

    EmailLogger.info('Disposing HTTP email services');
    
    await _cleanup();
    
    EmailLogger.info('HTTP email services disposed successfully');
  }

  /// Checks if the HTTP email services are healthy and ready to use
  static bool isHealthy() {
    if (!_isInitialized) {
      return false;
    }

    try {
      // Check if HTTP service locator is initialized
      if (!HttpServiceLocator.instance.isInitialized) {
        return false;
      }

      // Check if HTTP email service manager is initialized
      if (_httpEmailServiceManager == null || !_httpEmailServiceManager!.isInitialized) {
        return false;
      }

      return true;
    } catch (e) {
      EmailLogger.error(
        'HTTP service health check failed',
        error: e,
      );
      return false;
    }
  }

  /// Gets initialization status information
  static Map<String, dynamic> getStatus() {
    return {
      'isInitialized': _isInitialized,
      'isHealthy': isHealthy(),
      'httpServiceLocatorInitialized': HttpServiceLocator.instance.isInitialized,
      'httpEmailServiceManagerInitialized': _httpEmailServiceManager?.isInitialized ?? false,
      'httpEmailServiceManagerBusy': _httpEmailServiceManager?.isBusy ?? false,
      'lastError': _httpEmailServiceManager?.lastError,
    };
  }
}

/// Exception thrown during HTTP email service initialization
class HttpEmailServiceInitializationException implements Exception {
  final String message;
  final HttpEmailServiceInitializationStage stage;
  final dynamic originalError;

  const HttpEmailServiceInitializationException(
    this.message,
    this.stage, [
    this.originalError,
  ]);

  @override
  String toString() => 'HttpEmailServiceInitializationException: $message (Stage: $stage)';
}

/// Stages of HTTP email service initialization
enum HttpEmailServiceInitializationStage {
  configurationValidation,
  serviceLocator,
  emailServiceManager,
}

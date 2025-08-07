import 'package:flutter/foundation.dart';

import 'service_locator.dart';
import 'email_service_providers.dart';
import '../config/azure_config.dart';
import 'email_logger.dart';

/// Service initializer for Azure email services
/// 
/// This class handles the initialization of all email-related services
/// during app startup with proper error handling and logging.
class EmailServiceInitializer {
  static bool _isInitialized = false;
  static EmailServiceManager? _emailServiceManager;

  /// Whether the email services have been initialized
  static bool get isInitialized => _isInitialized;

  /// Gets the initialized email service manager
  static EmailServiceManager? get emailServiceManager => _emailServiceManager;

  /// Initializes all email services
  /// 
  /// This method should be called during app startup, after Supabase
  /// initialization but before the app widget is created.
  /// 
  /// Returns true if initialization was successful, false otherwise.
  static Future<bool> initialize() async {
    if (_isInitialized) {
      EmailLogger.warning('Email services already initialized, skipping');
      return true;
    }

    final stopwatch = Stopwatch()..start();
    
    try {
      EmailLogger.info('Starting email services initialization');
      
      // Step 1: Validate environment configuration
      await _validateConfiguration();
      
      // Step 2: Initialize service locator
      await _initializeServiceLocator();
      
      // Step 3: Initialize email service manager
      await _initializeEmailServiceManager();
      
      stopwatch.stop();
      _isInitialized = true;
      
      EmailLogger.info(
        'Email services initialized successfully',
        context: {
          'initializationTime': '${stopwatch.elapsedMilliseconds}ms',
          'servicesInitialized': [
            'ServiceLocator',
            'AzureEmailService',
            'AuthCodeService',
            'EmailServiceManager',
          ],
        },
      );
      
      return true;
    } catch (e) {
      stopwatch.stop();
      
      EmailLogger.error(
        'Failed to initialize email services',
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

  /// Validates the Azure configuration
  static Future<void> _validateConfiguration() async {
    try {
      EmailLogger.debug('Validating Azure configuration');
      AzureConfig.validateConfiguration();
      
      EmailLogger.info(
        'Azure configuration validated successfully',
        context: {
          'emailServiceEndpoint': AzureConfig.emailServiceEndpoint,
          'fromAddress': AzureConfig.fromAddress,
          'fromName': AzureConfig.fromName,
        },
      );
    } catch (e) {
      // Log the specific configuration error but don't throw - let it fail gracefully
      EmailLogger.warning(
        'Azure configuration validation failed: $e',
        context: {
          'stage': 'configurationValidation',
          'canContinueWithoutEmail': true,
        },
      );
      throw EmailServiceInitializationException(
        'Azure configuration validation failed: $e',
        EmailServiceInitializationStage.configurationValidation,
        e,
      );
    }
  }

  /// Initializes the service locator
  static Future<void> _initializeServiceLocator() async {
    try {
      EmailLogger.debug('Initializing service locator');
      await ServiceLocator.instance.initialize();
      
      EmailLogger.info('Service locator initialized successfully');
    } catch (e) {
      throw EmailServiceInitializationException(
        'Service locator initialization failed: $e',
        EmailServiceInitializationStage.serviceLocator,
        e,
      );
    }
  }

  /// Initializes the email service manager
  static Future<void> _initializeEmailServiceManager() async {
    try {
      EmailLogger.debug('Initializing email service manager');
      _emailServiceManager = EmailServiceManager();
      await _emailServiceManager!.initialize();
      
      EmailLogger.info('Email service manager initialized successfully');
    } catch (e) {
      throw EmailServiceInitializationException(
        'Email service manager initialization failed: $e',
        EmailServiceInitializationStage.emailServiceManager,
        e,
      );
    }
  }

  /// Gets the failure stage from an exception
  static String _getFailureStage(dynamic error) {
    if (error is EmailServiceInitializationException) {
      return error.stage.toString();
    }
    return 'unknown';
  }

  /// Cleans up partially initialized services
  static Future<void> _cleanup() async {
    try {
      EmailLogger.debug('Cleaning up partially initialized services');
      
      _emailServiceManager?.dispose();
      _emailServiceManager = null;
      
      ServiceLocator.instance.dispose();
      
      _isInitialized = false;
      
      EmailLogger.info('Service cleanup completed');
    } catch (e) {
      EmailLogger.error(
        'Error during service cleanup',
        error: e,
      );
    }
  }

  /// Reinitializes the email services
  /// 
  /// This method can be used to reinitialize services after configuration
  /// changes or when recovering from initialization failures.
  static Future<bool> reinitialize() async {
    EmailLogger.info('Reinitializing email services');
    
    await _cleanup();
    return await initialize();
  }

  /// Disposes of all email services
  /// 
  /// This method should be called when the app is shutting down
  /// to ensure proper cleanup of resources.
  static Future<void> dispose() async {
    if (!_isInitialized) {
      return;
    }

    EmailLogger.info('Disposing email services');
    
    await _cleanup();
    
    EmailLogger.info('Email services disposed successfully');
  }

  /// Checks if the email services are healthy and ready to use
  static bool isHealthy() {
    if (!_isInitialized) {
      return false;
    }

    try {
      // Check if service locator is initialized
      if (!ServiceLocator.instance.isInitialized) {
        return false;
      }

      // Check if email service manager is initialized
      if (_emailServiceManager == null || !_emailServiceManager!.isInitialized) {
        return false;
      }

      return true;
    } catch (e) {
      EmailLogger.error(
        'Health check failed',
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
      'serviceLocatorInitialized': ServiceLocator.instance.isInitialized,
      'emailServiceManagerInitialized': _emailServiceManager?.isInitialized ?? false,
      'emailServiceManagerBusy': _emailServiceManager?.isBusy ?? false,
      'lastError': _emailServiceManager?.lastError,
    };
  }
}

/// Exception thrown during email service initialization
class EmailServiceInitializationException implements Exception {
  final String message;
  final EmailServiceInitializationStage stage;
  final dynamic originalError;

  const EmailServiceInitializationException(
    this.message,
    this.stage, [
    this.originalError,
  ]);

  @override
  String toString() => 'EmailServiceInitializationException: $message (Stage: $stage)';
}

/// Stages of email service initialization
enum EmailServiceInitializationStage {
  configurationValidation,
  serviceLocator,
  emailServiceManager,
}
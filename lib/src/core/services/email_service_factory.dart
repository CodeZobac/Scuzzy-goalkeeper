import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'http_email_service.dart';
import 'http_auth_code_service.dart';
import 'email_service_providers.dart';
import 'http_service_locator.dart';
import '../models/email_response.dart';
import '../../features/auth/data/models/auth_code.dart';

/// Factory class for creating and accessing email services in production
/// 
/// This class provides convenient factory methods for creating email service
/// instances and accessing them through the dependency injection system.
class EmailServiceFactory {
  
  /// Creates a new HTTP email service instance for production use
  /// 
  /// This method creates a properly configured HttpEmailService instance
  /// with all necessary dependencies injected.
  static HttpEmailService createHttpEmailService({String? backendBaseUrl}) {
    return HttpServiceLocator.createHttpEmailService(
      backendBaseUrl: backendBaseUrl,
    );
  }

  /// Creates a new HTTP authentication code service instance for production use
  /// 
  /// This method creates a properly configured HttpAuthCodeService instance
  /// with all necessary dependencies injected.
  static HttpAuthCodeService createHttpAuthCodeService({String? backendBaseUrl}) {
    return HttpServiceLocator.createHttpAuthCodeService(
      backendBaseUrl: backendBaseUrl,
    );
  }

  /// Gets the HTTP email service from the dependency injection container
  /// 
  /// This method retrieves the singleton HttpEmailService instance from
  /// the service locator. Throws an exception if services haven't been initialized.
  static HttpEmailService getHttpEmailService() {
    return HttpServiceLocator.instance.httpEmailService;
  }

  /// Gets the HTTP authentication code service from the dependency injection container
  /// 
  /// This method retrieves the singleton HttpAuthCodeService instance from
  /// the service locator. Throws an exception if services haven't been initialized.
  static HttpAuthCodeService getHttpAuthCodeService() {
    return HttpServiceLocator.instance.httpAuthCodeService;
  }

  /// Gets the email service manager from a Flutter context
  /// 
  /// This method retrieves the EmailServiceManager from the Provider
  /// dependency injection system using the Flutter context.
  /// 
  /// [context] The Flutter build context
  /// [listen] Whether to listen for changes (default: false)
  static EmailServiceManager getEmailServiceManager(
    BuildContext context, {
    bool listen = false,
  }) {
    return Provider.of<EmailServiceManager>(context, listen: listen);
  }

  /// Gets the Azure email service provider from a Flutter context
  /// 
  /// This method retrieves the AzureEmailServiceProvider from the Provider
  /// dependency injection system using the Flutter context.
  /// 
  /// [context] The Flutter build context
  /// [listen] Whether to listen for changes (default: false)
  static AzureEmailServiceProvider getAzureEmailServiceProvider(
    BuildContext context, {
    bool listen = false,
  }) {
    return Provider.of<AzureEmailServiceProvider>(context, listen: listen);
  }

  /// Gets the authentication code service provider from a Flutter context
  /// 
  /// This method retrieves the AuthCodeServiceProvider from the Provider
  /// dependency injection system using the Flutter context.
  /// 
  /// [context] The Flutter build context
  /// [listen] Whether to listen for changes (default: false)
  static AuthCodeServiceProvider getAuthCodeServiceProvider(
    BuildContext context, {
    bool listen = false,
  }) {
    return Provider.of<AuthCodeServiceProvider>(context, listen: listen);
  }
}

/// Extension methods for easy access to email services from BuildContext
extension EmailServiceContext on BuildContext {
  
  /// Gets the email service manager from this context
  EmailServiceManager get emailServiceManager => 
      EmailServiceFactory.getEmailServiceManager(this);

  /// Gets the email service manager from this context with listening
  EmailServiceManager get emailServiceManagerWithListener => 
      EmailServiceFactory.getEmailServiceManager(this, listen: true);

  /// Gets the Azure email service provider from this context
  AzureEmailServiceProvider get azureEmailServiceProvider => 
      EmailServiceFactory.getAzureEmailServiceProvider(this);

  /// Gets the Azure email service provider from this context with listening
  AzureEmailServiceProvider get azureEmailServiceProviderWithListener => 
      EmailServiceFactory.getAzureEmailServiceProvider(this, listen: true);

  /// Gets the authentication code service provider from this context
  AuthCodeServiceProvider get authCodeServiceProvider => 
      EmailServiceFactory.getAuthCodeServiceProvider(this);

  /// Gets the authentication code service provider from this context with listening
  AuthCodeServiceProvider get authCodeServiceProviderWithListener => 
      EmailServiceFactory.getAuthCodeServiceProvider(this, listen: true);
}

/// Utility class for common email service operations
class EmailServiceUtils {
  
  /// Sends a confirmation email using the HTTP email service
  /// 
  /// This method communicates directly with the Python backend
  /// which handles auth code generation and email sending.
  /// 
  /// [email] The recipient email address
  /// [userId] The user ID
  static Future<EmailResponse> sendConfirmationEmail(
    String email,
    String userId,
  ) async {
    final httpEmailService = EmailServiceFactory.getHttpEmailService();
    return await httpEmailService.sendConfirmationEmail(email, userId);
  }

  /// Sends a password reset email using the HTTP email service
  /// 
  /// This method communicates directly with the Python backend
  /// which handles auth code generation and email sending.
  /// 
  /// [email] The recipient email address
  /// [userId] The user ID
  static Future<EmailResponse> sendPasswordResetEmail(
    String email,
    String userId,
  ) async {
    final httpEmailService = EmailServiceFactory.getHttpEmailService();
    return await httpEmailService.sendPasswordResetEmail(email, userId);
  }

  /// Validates an authentication code using the HTTP auth code service
  /// 
  /// This method communicates with the Python backend for validation.
  /// 
  /// [plainCode] The plain text code to validate
  /// [type] The type of authentication code
  static Future<AuthCode?> validateAuthCode(
    String plainCode,
    AuthCodeType type,
  ) async {
    final httpAuthCodeService = EmailServiceFactory.getHttpAuthCodeService();
    return await httpAuthCodeService.validateAuthCode(plainCode, type);
  }

  /// Validates and consumes an authentication code
  /// 
  /// This method communicates with the Python backend for validation and consumption.
  /// 
  /// [plainCode] The plain text code to validate and consume
  /// [type] The type of authentication code
  static Future<AuthCode?> validateAndConsumeAuthCode(
    String plainCode,
    AuthCodeType type,
  ) async {
    final httpAuthCodeService = EmailServiceFactory.getHttpAuthCodeService();
    return await httpAuthCodeService.validateAndConsumeAuthCode(plainCode, type);
  }

  /// Checks if HTTP email services are ready to use
  static bool areEmailServicesReady() {
    try {
      return HttpServiceLocator.instance.isInitialized;
    } catch (e) {
      return false;
    }
  }

  /// Gets the current status of HTTP email services
  static Map<String, dynamic> getEmailServicesStatus() {
    try {
      final isInitialized = HttpServiceLocator.instance.isInitialized;
      return {
        'isInitialized': isInitialized,
        'isBusy': false, // HTTP services don't have a busy state
        'lastError': null,
        'httpEmailServiceReady': isInitialized,
        'httpAuthCodeServiceReady': isInitialized,
        'backendUrl': isInitialized ? HttpServiceLocator.instance.backendBaseUrl : 'not configured',
      };
    } catch (e) {
      return {
        'error': e.toString(),
        'isInitialized': false,
        'isBusy': false,
      };
    }
  }
}

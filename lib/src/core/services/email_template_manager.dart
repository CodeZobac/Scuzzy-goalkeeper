import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../exceptions/email_service_exception.dart';
import '../../features/auth/data/models/auth_code.dart';
import 'email_logger.dart';
import 'email_error_handler.dart';

/// Manages email template loading and processing
class EmailTemplateManager {
  static const String _confirmationTemplatePath = 'email_templates/confirm_signup_template.html';
  static const String _resetTemplatePath = 'email_templates/reset_password_template.html';
  
  // Cache for loaded templates
  static final Map<String, String> _templateCache = {};

  /// Loads an HTML template from assets
  static Future<String> loadTemplate(String templateName) async {
    EmailLogger.logTemplateOperation(
      operation: 'loadTemplate',
      templateName: templateName,
    );
    
    try {
      // Check cache first
      if (_templateCache.containsKey(templateName)) {
        EmailLogger.debug(
          'Template loaded from cache',
          context: {
            'templateName': templateName,
            'cacheSize': _templateCache.length,
          },
        );
        
        EmailLogger.logTemplateOperation(
          operation: 'loadTemplate',
          templateName: templateName,
          success: true,
        );
        
        return _templateCache[templateName]!;
      }

      String templatePath;
      switch (templateName.toLowerCase()) {
        case 'confirmation':
        case 'confirm_signup':
          templatePath = _confirmationTemplatePath;
          break;
        case 'password_reset':
        case 'reset_password':
          templatePath = _resetTemplatePath;
          break;
        default:
          final exception = EmailServiceException(
            'Unknown template name: $templateName',
            EmailServiceErrorType.templateError,
          );
          
          EmailLogger.error(
            'Unknown template name requested',
            error: exception,
            context: {
              'requestedTemplate': templateName,
              'availableTemplates': ['confirmation', 'password_reset'],
            },
          );
          
          EmailLogger.logTemplateOperation(
            operation: 'loadTemplate',
            templateName: templateName,
            success: false,
            errorMessage: 'Unknown template name',
          );
          
          throw exception;
      }

      EmailLogger.debug(
        'Loading template from assets',
        context: {
          'templateName': templateName,
          'templatePath': templatePath,
        },
      );

      final templateContent = await rootBundle.loadString(templatePath);
      
      // Cache the template for future use
      _templateCache[templateName] = templateContent;
      
      EmailLogger.info(
        'Template loaded and cached successfully',
        context: {
          'templateName': templateName,
          'contentLength': templateContent.length,
          'cacheSize': _templateCache.length,
        },
      );
      
      EmailLogger.logTemplateOperation(
        operation: 'loadTemplate',
        templateName: templateName,
        success: true,
      );
      
      return templateContent;
    } on FlutterError catch (e) {
      final exception = EmailServiceException(
        'Template file not found or inaccessible: "$templateName"',
        EmailServiceErrorType.templateError,
        e,
      );
      
      EmailLogger.error(
        'Flutter error loading template',
        error: e,
        context: {
          'templateName': templateName,
          'flutterError': e.message,
        },
      );
      
      EmailLogger.logTemplateOperation(
        operation: 'loadTemplate',
        templateName: templateName,
        success: false,
        errorMessage: EmailErrorHandler.getUserFriendlyMessage(exception),
      );
      
      throw exception;
    } catch (e) {
      final exception = EmailServiceException(
        'Unexpected error loading template "$templateName": $e',
        EmailServiceErrorType.templateError,
        e,
      );
      
      EmailLogger.error(
        'Unexpected error loading template',
        error: e,
        context: {
          'templateName': templateName,
        },
      );
      
      EmailLogger.logTemplateOperation(
        operation: 'loadTemplate',
        templateName: templateName,
        success: false,
        errorMessage: EmailErrorHandler.getUserFriendlyMessage(exception),
      );
      
      throw exception;
    }
  }

  /// Processes a template by substituting variables with their values
  static String processTemplate(String template, Map<String, String> variables) {
    EmailLogger.logTemplateOperation(
      operation: 'processTemplate',
      templateName: 'dynamic',
      variables: variables,
    );
    
    try {
      EmailLogger.debug(
        'Starting template processing',
        context: {
          'templateLength': template.length,
          'variableCount': variables.length,
          'variables': variables.keys.toList(),
        },
      );
      
      String processedTemplate = template;
      
      // Validate and sanitize variables before substitution
      final sanitizedVariables = _sanitizeVariables(variables);
      
      EmailLogger.debug(
        'Variables sanitized successfully',
        context: {
          'originalCount': variables.length,
          'sanitizedCount': sanitizedVariables.length,
        },
      );
      
      // Replace template variables using Go-style template syntax {{ .VariableName }}
      for (final entry in sanitizedVariables.entries) {
        final placeholder = '{{ .${entry.key} }}';
        final beforeLength = processedTemplate.length;
        processedTemplate = processedTemplate.replaceAll(placeholder, entry.value);
        final afterLength = processedTemplate.length;
        
        if (beforeLength != afterLength) {
          EmailLogger.debug(
            'Variable substituted',
            context: {
              'variable': entry.key,
              'placeholder': placeholder,
              'lengthChange': afterLength - beforeLength,
            },
          );
        }
      }
      
      // Check for any remaining unsubstituted variables
      final unsubstitutedPattern = RegExp(r'\{\{\s*\.\w+\s*\}\}');
      final unsubstitutedMatches = unsubstitutedPattern.allMatches(processedTemplate);
      
      if (unsubstitutedMatches.isNotEmpty) {
        final unsubstitutedVars = unsubstitutedMatches
            .map((match) => match.group(0))
            .toSet()
            .join(', ');
        
        final exception = EmailServiceException(
          'Template contains unsubstituted variables: $unsubstitutedVars',
          EmailServiceErrorType.templateError,
        );
        
        EmailLogger.error(
          'Template processing failed due to unsubstituted variables',
          error: exception,
          context: {
            'unsubstitutedVariables': unsubstitutedVars,
            'providedVariables': variables.keys.toList(),
          },
        );
        
        EmailLogger.logTemplateOperation(
          operation: 'processTemplate',
          templateName: 'dynamic',
          success: false,
          errorMessage: 'Unsubstituted variables found',
          variables: variables,
        );
        
        throw exception;
      }
      
      EmailLogger.info(
        'Template processed successfully',
        context: {
          'originalLength': template.length,
          'processedLength': processedTemplate.length,
          'variablesSubstituted': sanitizedVariables.length,
        },
      );
      
      EmailLogger.logTemplateOperation(
        operation: 'processTemplate',
        templateName: 'dynamic',
        success: true,
        variables: variables,
      );
      
      return processedTemplate;
    } catch (e) {
      if (e is EmailServiceException) {
        rethrow;
      }
      
      final exception = EmailServiceException(
        'Failed to process template: $e',
        EmailServiceErrorType.templateError,
        e,
      );
      
      EmailLogger.error(
        'Unexpected error during template processing',
        error: e,
        context: {
          'templateLength': template.length,
          'variableCount': variables.length,
        },
      );
      
      EmailLogger.logTemplateOperation(
        operation: 'processTemplate',
        templateName: 'dynamic',
        success: false,
        errorMessage: EmailErrorHandler.getUserFriendlyMessage(exception),
        variables: variables,
      );
      
      throw exception;
    }
  }

  /// Generates a secure redirect URL with authentication code
  static String generateRedirectUrl(String authCode, AuthCodeType type) {
    try {
      final baseUrl = _getAppBaseUrl();
      final redirectPath = _getRedirectPath(type);
      
      // Validate auth code format (should be 32 characters alphanumeric)
      if (!_isValidAuthCode(authCode)) {
        throw EmailServiceException(
          'Invalid authentication code format',
          EmailServiceErrorType.authCodeError,
        );
      }
      
      // Build the URL with the authentication code as a query parameter
      final uri = Uri.parse('$baseUrl$redirectPath');
      final urlWithCode = uri.replace(
        queryParameters: {
          ...uri.queryParameters,
          'code': authCode,
        },
      );
      
      return urlWithCode.toString();
    } catch (e) {
      if (e is EmailServiceException) {
        rethrow;
      }
      throw EmailServiceException(
        'Failed to generate redirect URL: $e',
        EmailServiceErrorType.templateError,
        e,
      );
    }
  }

  /// Loads and processes a confirmation email template
  static Future<String> buildConfirmationEmail(String authCode) async {
    try {
      final template = await loadTemplate('confirmation');
      final confirmationUrl = generateRedirectUrl(authCode, AuthCodeType.emailConfirmation);
      
      final variables = {
        'ConfirmationURL': confirmationUrl,
      };
      
      return processTemplate(template, variables);
    } catch (e) {
      if (e is EmailServiceException) {
        rethrow;
      }
      throw EmailServiceException(
        'Failed to build confirmation email: $e',
        EmailServiceErrorType.templateError,
        e,
      );
    }
  }

  /// Loads and processes a password reset email template
  static Future<String> buildPasswordResetEmail(String authCode) async {
    try {
      final template = await loadTemplate('password_reset');
      
      // For password reset, we'll generate a URL that includes the Azure auth code
      // but redirects to the existing Supabase-compatible reset flow
      final resetUrl = generatePasswordResetUrl(authCode);
      
      final variables = {
        'ConfirmationURL': resetUrl, // Template uses ConfirmationURL for both types
      };
      
      return processTemplate(template, variables);
    } catch (e) {
      if (e is EmailServiceException) {
        rethrow;
      }
      throw EmailServiceException(
        'Failed to build password reset email: $e',
        EmailServiceErrorType.templateError,
        e,
      );
    }
  }

  /// Generates a password reset URL that includes the Azure auth code
  /// This URL will be handled by the reset password screen
  static String generatePasswordResetUrl(String authCode) {
    try {
      final baseUrl = _getAppBaseUrl();
      final resetPath = '/reset-password';
      
      // Validate auth code format
      if (!_isValidAuthCode(authCode)) {
        throw EmailServiceException(
          'Invalid authentication code format',
          EmailServiceErrorType.authCodeError,
        );
      }
      
      // Build the URL with the Azure authentication code as a query parameter
      final uri = Uri.parse('$baseUrl$resetPath');
      final urlWithCode = uri.replace(
        queryParameters: {
          ...uri.queryParameters,
          'code': authCode,
          'type': 'azure_reset', // Indicate this is an Azure-based reset
        },
      );
      
      return urlWithCode.toString();
    } catch (e) {
      if (e is EmailServiceException) {
        rethrow;
      }
      throw EmailServiceException(
        'Failed to generate password reset URL: $e',
        EmailServiceErrorType.templateError,
        e,
      );
    }
  }

  /// Sanitizes template variables to prevent injection attacks
  static Map<String, String> _sanitizeVariables(Map<String, String> variables) {
    final sanitized = <String, String>{};
    
    for (final entry in variables.entries) {
      // Validate variable name (should be alphanumeric with underscores)
      if (!RegExp(r'^[a-zA-Z_][a-zA-Z0-9_]*$').hasMatch(entry.key)) {
        throw EmailServiceException(
          'Invalid variable name: ${entry.key}',
          EmailServiceErrorType.templateError,
        );
      }
      
      // Sanitize variable value
      String sanitizedValue = entry.value;
      
      // For URLs, validate they are properly formatted
      if (entry.key.toLowerCase().contains('url')) {
        try {
          Uri.parse(sanitizedValue);
        } catch (e) {
          throw EmailServiceException(
            'Invalid URL format for variable ${entry.key}: ${entry.value}',
            EmailServiceErrorType.templateError,
            e,
          );
        }
      }
      
      // HTML encode special characters to prevent XSS
      sanitizedValue = _htmlEncode(sanitizedValue);
      
      sanitized[entry.key] = sanitizedValue;
    }
    
    return sanitized;
  }

  /// HTML encodes a string to prevent XSS attacks
  static String _htmlEncode(String input) {
    return input
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#x27;')
        .replaceAll('/', '&#x2F;');
  }

  /// Gets the application base URL from environment variables
  static String _getAppBaseUrl() {
    final baseUrl = dotenv.env['APP_BASE_URL'];
    if (baseUrl == null || baseUrl.isEmpty) {
      throw EmailServiceException(
        'APP_BASE_URL environment variable is not set',
        EmailServiceErrorType.configurationError,
      );
    }
    return baseUrl;
  }

  /// Gets the redirect path for the given authentication code type
  static String _getRedirectPath(AuthCodeType type) {
    switch (type) {
      case AuthCodeType.emailConfirmation:
        return dotenv.env['CONFIRMATION_REDIRECT_PATH'] ?? '/auth/confirm';
      case AuthCodeType.passwordReset:
        return dotenv.env['RESET_REDIRECT_PATH'] ?? '/auth/reset';
    }
  }

  /// Validates that an authentication code has the correct format
  static bool _isValidAuthCode(String code) {
    // Should be 32 characters, alphanumeric
    return RegExp(r'^[a-zA-Z0-9]{32}$').hasMatch(code);
  }

  /// Clears the template cache (useful for testing)
  static void clearCache() {
    _templateCache.clear();
  }
}


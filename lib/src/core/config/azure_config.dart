import 'app_config.dart';

/// Configuration class for Azure Communication Services
class AzureConfig {
  /// Azure Communication Services endpoint URL
  static String get emailServiceEndpoint {
    if (AppConfig.emailService.isEmpty) {
      throw Exception('EMAIL_SERVICE configuration is not set');
    }
    return AppConfig.emailService;
  }

  /// Azure authentication key
  static String get azureKey {
    if (AppConfig.azureKey.isEmpty) {
      throw Exception('AZURE_KEY configuration is not set');
    }
    return AppConfig.azureKey;
  }

  /// Azure connection string
  static String get connectionString {
    if (AppConfig.azureConnectionString.isEmpty) {
      throw Exception('AZURE_CONNECTION_STRING configuration is not set');
    }
    return AppConfig.azureConnectionString;
  }

  /// Email sender address
  static String get fromAddress {
    return AppConfig.emailFromAddress.isNotEmpty 
        ? AppConfig.emailFromAddress 
        : 'noreply@goalkeeper-finder.com';
  }

  /// Email sender name
  static String get fromName {
    return AppConfig.emailFromName.isNotEmpty 
        ? AppConfig.emailFromName 
        : 'Goalkeeper-Finder';
  }

  /// Validates that all required Azure configuration is present
  static void validateConfiguration() {
    try {
      emailServiceEndpoint;
      azureKey;
      connectionString;
    } catch (e) {
      throw Exception('Azure configuration validation failed: $e');
    }
  }
}
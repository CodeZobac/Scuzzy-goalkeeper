import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Configuration class for Azure Communication Services
class AzureConfig {
  /// Azure Communication Services endpoint URL
  static String get emailServiceEndpoint {
    final endpoint = dotenv.env['EMAIL_SERVICE'];
    if (endpoint == null || endpoint.isEmpty) {
      throw Exception('EMAIL_SERVICE environment variable is not set');
    }
    return endpoint;
  }

  /// Azure authentication key
  static String get azureKey {
    final key = dotenv.env['AZURE_KEY'];
    if (key == null || key.isEmpty) {
      throw Exception('AZURE_KEY environment variable is not set');
    }
    return key;
  }

  /// Azure connection string
  static String get connectionString {
    final connectionString = dotenv.env['AZURE_CONECTION_STRING'];
    if (connectionString == null || connectionString.isEmpty) {
      throw Exception('AZURE_CONECTION_STRING environment variable is not set');
    }
    return connectionString;
  }

  /// Email sender address
  static String get fromAddress {
    return dotenv.env['EMAIL_FROM_ADDRESS'] ?? 'noreply@goalkeeper-finder.com';
  }

  /// Email sender name
  static String get fromName {
    return dotenv.env['EMAIL_FROM_NAME'] ?? 'Goalkeeper-Finder';
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
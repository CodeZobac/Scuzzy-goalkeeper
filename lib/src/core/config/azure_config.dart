import 'app_config.dart';

/// Configuration class for Azure Communication Services
/// 
/// Note: This class is maintained for compatibility with existing code
/// that may reference Azure configs, but the Flutter app now communicates
/// with email services through the Python backend instead of directly with Azure.
class AzureConfig {
  /// Azure Communication Services endpoint URL
  /// Returns the backend URL since Azure is now handled by the Python backend
  static String get emailServiceEndpoint {
    return AppConfig.backendBaseUrl.isNotEmpty 
        ? '${AppConfig.backendBaseUrl}/api/email'
        : 'http://localhost:8000/api/email';
  }

  /// Azure authentication key
  /// Not used by Flutter app - authentication handled by backend
  static String get azureKey {
    return 'managed-by-backend';
  }

  /// Azure connection string  
  /// Not used by Flutter app - connection handled by backend
  static String get connectionString {
    return 'managed-by-backend';
  }

  /// Email sender address
  static String get fromAddress {
    return 'noreply@goalkeeper-finder.com';
  }

  /// Email sender name
  static String get fromName {
    return 'Goalkeeper-Finder';
  }

  /// Validates that all required configuration is present
  /// Now validates backend URL instead of Azure credentials
  static void validateConfiguration() {
    if (AppConfig.backendBaseUrl.isEmpty || AppConfig.backendBaseUrl == '{{PYTHON_BACKEND_URL}}') {
      throw Exception('Backend URL configuration is not set. Email services require a valid Python backend URL.');
    }
  }
}

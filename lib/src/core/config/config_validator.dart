import 'package:flutter/foundation.dart';
import 'app_config.dart';

class ConfigValidator {
  static void validateConfiguration() {
    final issues = <String>[];
    
    if (AppConfig.supabaseUrl.isEmpty) {
      issues.add('SUPABASE_URL is not configured');
    }
    
    if (AppConfig.supabaseAnonKey.isEmpty) {
      issues.add('SUPABASE_ANON_KEY is not configured');
    }
    
    if (AppConfig.mapboxAccessToken.isEmpty) {
      issues.add('MAPBOX_ACCESS_TOKEN is not configured');
    }
    
    if (AppConfig.mapboxDownloadsToken.isEmpty) {
      issues.add('MAPBOX_DOWNLOADS_TOKEN is not configured');
    }
    
    if (issues.isNotEmpty) {
      final message = 'Configuration issues found:\n${issues.join('\n')}';
      if (kDebugMode) {
        debugPrint('⚠️ $message');
      }
      throw Exception(message);
    }
    
    if (kDebugMode) {
      debugPrint('✅ All required environment variables are configured');
    }
  }
  
  static void logConfigurationStatus() {
    if (kDebugMode) {
      debugPrint('Configuration Status:');
      debugPrint('- SUPABASE_URL: ${AppConfig.supabaseUrl.isNotEmpty ? "✅ Set" : "❌ Missing"}');
      debugPrint('- SUPABASE_ANON_KEY: ${AppConfig.supabaseAnonKey.isNotEmpty ? "✅ Set" : "❌ Missing"}');
      debugPrint('- MAPBOX_ACCESS_TOKEN: ${AppConfig.mapboxAccessToken.isNotEmpty ? "✅ Set" : "❌ Missing"}');
      debugPrint('- MAPBOX_DOWNLOADS_TOKEN: ${AppConfig.mapboxDownloadsToken.isNotEmpty ? "✅ Set" : "❌ Missing"}');
      debugPrint('- GOOGLE_MAPS_API_KEY: ${AppConfig.googleMapsApiKey.isNotEmpty ? "✅ Set" : "❌ Missing"}');
      debugPrint('- DEMO_MODE: ${AppConfig.isDemoMode ? "✅ Enabled" : "❌ Disabled"}');
    }
  }
}
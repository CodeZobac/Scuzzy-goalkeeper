import 'package:flutter/foundation.dart';
import 'package:goalkeeper/src/core/config/app_config.dart';

class ConfigValidator {
  static void validateConfiguration() {
    if (AppConfig.supabaseUrl.isEmpty) {
      throw StateError('Supabase URL is not configured. Please provide SUPABASE_URL.');
    }
    if (AppConfig.supabaseAnonKey.isEmpty) {
      throw StateError('Supabase Anon Key is not configured. Please provide SUPABASE_ANON_KEY.');
    }
  }

  static void logConfigurationStatus() {
    debugPrint('--- Configuration Status ---');
    debugPrint('Mode: ${kReleaseMode ? 'Release' : kProfileMode ? 'Profile' : 'Debug'}');
    debugPrint('Supabase URL: ${AppConfig.supabaseUrl.isNotEmpty ? 'Loaded' : 'Missing'}');
    debugPrint('Supabase Anon Key: ${AppConfig.supabaseAnonKey.isNotEmpty ? 'Loaded' : 'Missing'}');
    debugPrint('Mapbox Access Token: ${AppConfig.mapboxAccessToken.isNotEmpty ? 'Loaded' : 'Missing'}');
    debugPrint('--------------------------');
  }
}

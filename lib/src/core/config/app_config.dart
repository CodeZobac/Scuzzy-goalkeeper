import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  // Unified approach: try dart-define first (production), then dotenv (local development)
  static String get supabaseUrl => 
    const String.fromEnvironment('SUPABASE_URL').isNotEmpty 
      ? const String.fromEnvironment('SUPABASE_URL')
      : dotenv.env['SUPABASE_URL'] ?? '';
      
  static String get supabaseAnonKey => 
    const String.fromEnvironment('SUPABASE_ANON_KEY').isNotEmpty 
      ? const String.fromEnvironment('SUPABASE_ANON_KEY')
      : dotenv.env['SUPABASE_ANON_KEY'] ?? '';
      
  static String get mapboxAccessToken => 
    const String.fromEnvironment('MAPBOX_ACCESS_TOKEN').isNotEmpty 
      ? const String.fromEnvironment('MAPBOX_ACCESS_TOKEN')
      : dotenv.env['MAPBOX_ACCESS_TOKEN'] ?? '';
      
  static String get mapboxDownloadsToken => 
    const String.fromEnvironment('MAPBOX_DOWNLOADS_TOKEN').isNotEmpty 
      ? const String.fromEnvironment('MAPBOX_DOWNLOADS_TOKEN')
      : dotenv.env['MAPBOX_DOWNLOADS_TOKEN'] ?? '';
      
  static String get googleMapsApiKey => 
    const String.fromEnvironment('GOOGLE_MAPS_API_KEY').isNotEmpty 
      ? const String.fromEnvironment('GOOGLE_MAPS_API_KEY')
      : dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';

  // Demo mode flag for development
  static bool get isDemoMode => 
    const String.fromEnvironment('DEMO_MODE').toLowerCase() == 'true' ||
    dotenv.env['DEMO_MODE']?.toLowerCase() == 'true';
}

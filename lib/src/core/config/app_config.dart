import 'package:flutter/foundation.dart';
import 'package.flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static String get supabaseUrl {
    if (kIsWeb) {
      return const String.fromEnvironment('SUPABASE_URL');
    }
    return dotenv.env['SUPABASE_URL'] ?? '';
  }

  static String get supabaseAnonKey {
    if (kIsWeb) {
      return const String.fromEnvironment('SUPABASE_ANON_KEY');
    }
    return dotenv.env['SUPABASE_ANON_KEY'] ?? '';
  }

  static String get mapboxAccessToken {
    if (kIsWeb) {
      return const String.fromEnvironment('MAPBOX_ACCESS_TOKEN');
    }
    return dotenv.env['MAPBOX_ACCESS_TOKEN'] ?? '';
  }
}

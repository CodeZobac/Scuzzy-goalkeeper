import 'package:geolocator/geolocator.dart';
import '../../features/user_profile/data/models/user_profile.dart';

class LocationUtils {
  /// Check if location services are available
  static Future<bool> isLocationServiceAvailable() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    return permission != LocationPermission.denied && 
           permission != LocationPermission.deniedForever;
  }

  /// Get location permission status message
  static Future<String> getLocationStatusMessage() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return 'Serviços de localização estão desabilitados';
    }

    LocationPermission permission = await Geolocator.checkPermission();
    switch (permission) {
      case LocationPermission.denied:
        return 'Permissão de localização negada';
      case LocationPermission.deniedForever:
        return 'Permissão de localização negada permanentemente';
      case LocationPermission.whileInUse:
      case LocationPermission.always:
        return 'Localização disponível';
      default:
        return 'Status de localização desconhecido';
    }
  }

  /// Check if user should be prompted to update location
  static bool shouldPromptLocationUpdate(UserProfile user) {
    // Prompt if user is a goalkeeper but doesn't have location
    if (user.isGoalkeeper && !user.hasLocation) {
      return true;
    }
    
    // Prompt if user has old location data (more than 30 days)
    // This would require adding a location_updated_at field in the future
    
    return false;
  }

  /// Format distance for display
  static String formatDistance(double distanceKm) {
    if (distanceKm < 1) {
      return '${(distanceKm * 1000).round()} m';
    } else if (distanceKm < 10) {
      return '${distanceKm.toStringAsFixed(1)} km';
    } else {
      return '${distanceKm.round()} km';
    }
  }

  /// Get approximate coordinates for Portuguese cities (fallback data)
  static Map<String, Map<String, double>> getCityCoordinates() {
    return {
      'lisboa': {'lat': 38.7223, 'lng': -9.1393},
      'porto': {'lat': 41.1579, 'lng': -8.6291},
      'coimbra': {'lat': 40.2033, 'lng': -8.4103},
      'braga': {'lat': 41.5518, 'lng': -8.4229},
      'aveiro': {'lat': 40.6443, 'lng': -8.6455},
      'faro': {'lat': 37.0194, 'lng': -7.9322},
      'setúbal': {'lat': 38.5244, 'lng': -8.8882},
      'funchal': {'lat': 32.6669, 'lng': -16.9241},
      'ponta delgada': {'lat': 37.7394, 'lng': -25.6681},
      'albufeira': {'lat': 37.0893, 'lng': -8.2446},
    };
  }

  /// Get approximate coordinates for a city name
  static Map<String, double>? getCoordinatesForCity(String cityName) {
    final coordinates = getCityCoordinates();
    final normalizedCity = cityName.toLowerCase().trim();
    return coordinates[normalizedCity];
  }
}
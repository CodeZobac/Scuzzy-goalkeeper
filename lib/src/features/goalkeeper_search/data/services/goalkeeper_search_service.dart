import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../../user_profile/data/models/user_profile.dart';
import '../../../../shared/services/location_service.dart';
import '../../../../shared/utils/location_utils.dart';

class GoalkeeperSearchService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final LocationService _locationService = LocationService();

  /// Get nearby goalkeepers based on user's current location
  Future<List<UserProfile>> getNearbyGoalkeepers({
    double radiusKm = 50.0,
    Position? userLocation,
    String? userCity,
  }) async {
    try {
      Position? location = userLocation;
      
      // Get user location if not provided
      if (location == null) {
        location = await _locationService.getCurrentLocation();
        
        // If GPS location fails but we have city info, use city coordinates
        if (location == null && userCity != null) {
          final cityCoords = LocationUtils.getCoordinatesForCity(userCity);
          if (cityCoords != null) {
            location = Position(
              latitude: cityCoords['lat']!,
              longitude: cityCoords['lng']!,
              timestamp: DateTime.now(),
              accuracy: 1000, // Lower accuracy for city-based location
              altitude: 0,
              altitudeAccuracy: 0,
              heading: 0,
              headingAccuracy: 0,
              speed: 0,
              speedAccuracy: 0,
            );
          }
        }
        
        if (location == null) {
          // Fallback to all goalkeepers if location is not available
          return await getAllGoalkeepers();
        }
      }

      // Use the database function to get nearby goalkeepers
      final response = await _supabase
          .rpc('get_nearby_goalkeepers', params: {
        'user_lat': location.latitude,
        'user_lon': location.longitude,
        'radius_km': radiusKm,
      });

      if (response == null) return [];

      return (response as List)
          .map((data) => UserProfile.fromMap(data))
          .toList();
    } catch (e) {
      print('Error getting nearby goalkeepers: $e');
      // Fallback to all goalkeepers
      return await getAllGoalkeepers();
    }
  }

  /// Get all goalkeepers (fallback when location is not available)
  Future<List<UserProfile>> getAllGoalkeepers() async {
    try {
      final response = await _supabase
          .from('users')
          .select()
          .eq('is_goalkeeper', true)
          .order('name');

      return (response as List)
          .map((data) => UserProfile.fromMap(data))
          .toList();
    } catch (e) {
      print('Error getting all goalkeepers: $e');
      return [];
    }
  }

  /// Search goalkeepers by name with optional location filtering
  Future<List<UserProfile>> searchGoalkeepers({
    required String query,
    double? radiusKm,
    Position? userLocation,
  }) async {
    try {
      List<UserProfile> goalkeepers;

      if (radiusKm != null && userLocation != null) {
        // Get nearby goalkeepers first
        goalkeepers = await getNearbyGoalkeepers(
          radiusKm: radiusKm,
          userLocation: userLocation,
        );
      } else {
        // Get all goalkeepers
        goalkeepers = await getAllGoalkeepers();
      }

      // Filter by name query
      if (query.isNotEmpty) {
        goalkeepers = goalkeepers
            .where((goalkeeper) =>
                goalkeeper.name.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }

      return goalkeepers;
    } catch (e) {
      print('Error searching goalkeepers: $e');
      return [];
    }
  }

  /// Update user location in the database
  Future<bool> updateUserLocation(String userId, double latitude, double longitude) async {
    try {
      await _supabase
          .from('users')
          .update({
            'latitude': latitude,
            'longitude': longitude,
          })
          .eq('id', userId);
      
      return true;
    } catch (e) {
      print('Error updating user location: $e');
      return false;
    }
  }
}
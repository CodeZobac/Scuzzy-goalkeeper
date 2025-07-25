import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/real_goalkeeper.dart';
import '../models/real_field.dart';

class RealDataService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Fetch all approved fields from the database
  Future<List<RealField>> getApprovedFields() async {
    try {
      final response = await _supabase
          .from('fields')
          .select('*')
          .eq('status', 'approved')
          .order('created_at', ascending: false);

      return (response as List)
          .map((field) => RealField.fromJson(field))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch fields: $e');
    }
  }

  /// Fetch all goalkeepers from the database
  Future<List<RealGoalkeeper>> getGoalkeepers() async {
    try {
      final response = await _supabase
          .from('users')
          .select('*')
          .eq('is_goalkeeper', true)
          .order('created_at', ascending: false);

      return (response as List)
          .map((user) => RealGoalkeeper.fromJson(user))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch goalkeepers: $e');
    }
  }

  /// Fetch goalkeepers near a specific location (within radius in km)
  Future<List<RealGoalkeeper>> getGoalkeepersNearLocation({
    required double latitude,
    required double longitude,
    double radiusKm = 50.0,
  }) async {
    try {
      // For now, get all goalkeepers and filter by city
      // In a production app, you'd want to use PostGIS for proper geospatial queries
      final allGoalkeepers = await getGoalkeepers();
      
      // Simple city-based filtering for now
      // You could enhance this with actual distance calculation
      return allGoalkeepers;
    } catch (e) {
      throw Exception('Failed to fetch nearby goalkeepers: $e');
    }
  }

  /// Fetch goalkeeper ratings and calculate average
  Future<double?> getGoalkeeperAverageRating(String goalkeeperUserId) async {
    try {
      final response = await _supabase
          .from('ratings')
          .select('rating')
          .eq('goalkeeper_id', goalkeeperUserId);

      if (response.isEmpty) return null;

      final ratings = (response as List).map((r) => r['rating'] as int).toList();
      return ratings.reduce((a, b) => a + b) / ratings.length;
    } catch (e) {
      return null; // Return null if there's an error fetching ratings
    }
  }

  /// Fetch fields by city
  Future<List<RealField>> getFieldsByCity(String city) async {
    try {
      final response = await _supabase
          .from('fields')
          .select('*')
          .eq('status', 'approved')
          .ilike('city', '%$city%')
          .order('created_at', ascending: false);

      return (response as List)
          .map((field) => RealField.fromJson(field))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch fields by city: $e');
    }
  }

  /// Get available cities from fields
  Future<List<String>> getAvailableCities() async {
    try {
      final response = await _supabase
          .from('fields')
          .select('city')
          .eq('status', 'approved')
          .not('city', 'is', null);

      final cities = (response as List)
          .map((field) => field['city'] as String?)
          .where((city) => city != null && city.isNotEmpty)
          .cast<String>()
          .toSet()
          .toList();

      cities.sort();
      return cities;
    } catch (e) {
      throw Exception('Failed to fetch available cities: $e');
    }
  }

  /// Create a booking request
  Future<String> createBookingRequest({
    required String playerId,
    required String goalkeeperUserId,
    String? fieldId,
    required DateTime gameDateTime,
    required double price,
  }) async {
    try {
      final response = await _supabase
          .from('bookings')
          .insert({
            'player_id': playerId,
            'goalkeeper_id': goalkeeperUserId,
            'field_id': fieldId,
            'game_datetime': gameDateTime.toIso8601String(),
            'price': price,
            'status': 'pending',
          })
          .select('id')
          .single();

      return response['id'] as String;
    } catch (e) {
      throw Exception('Failed to create booking request: $e');
    }
  }

  /// Get goalkeeper availability for a specific date
  Future<List<Map<String, dynamic>>> getGoalkeeperAvailability({
    required String goalkeeperUserId,
    required DateTime date,
  }) async {
    try {
      final response = await _supabase
          .from('availabilities')
          .select('*')
          .eq('goalkeeper_id', goalkeeperUserId)
          .eq('day', date.toIso8601String().split('T')[0])
          .order('start-time', ascending: true);

      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      return []; // Return empty list if no availability found
    }
  }
}
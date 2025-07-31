import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/real_goalkeeper.dart';
import '../models/real_field.dart';

class RealDataService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Insert a test field to verify database connectivity (for debugging)
  Future<void> insertTestField() async {
    try {
      print('🧪 Inserting test field...');
      
      final testField = {
        'name': 'Campo de Teste',
        'latitude': 38.7223,
        'longitude': -9.1393,
        'city': 'Lisboa',
        'surface_type': 'Synthetic',
        'dimensions': '11-a-side',
        'description': 'Campo de teste para a aplicação.',
        'photo_url': 'https://i.imgur.com/O38ITaA.jpeg',
      };
      
      final response = await _supabase
          .from('fields')
          .insert(testField)
          .select()
          .single();
      
      print('✅ Test field inserted successfully: ${response['id']}');
      
    } catch (e) {
      print('❌ Error inserting test field: $e');
    }
  }

  /// Test method to fetch ALL fields (for debugging)
  Future<void> testFieldsFetch() async {
    try {
      print('🧪 Testing database connection and fields table...');
      
      // First, try to fetch all fields regardless of status
      final allFields = await _supabase
          .from('fields')
          .select('*');
      
      print('📊 Total fields in database: ${(allFields as List).length}');
      
      if (allFields.isNotEmpty) {
        print('📋 First field sample: ${allFields.first}');
        
        // Check status distribution
        final statusCounts = <String, int>{};
        for (final field in allFields) {
          final status = field['status'] as String? ?? 'null';
          statusCounts[status] = (statusCounts[status] ?? 0) + 1;
        }
        print('📊 Status distribution: $statusCounts');
      }
      
      // Now try to fetch only approved fields
      final approvedFields = await _supabase
          .from('fields')
          .select('*')
          .eq('status', 'approved');
      
      print('✅ Approved fields count: ${(approvedFields as List).length}');
      
    } catch (e) {
      print('❌ Error in test fetch: $e');
    }
  }

  /// Fetch all approved fields from the database
  Future<List<RealField>> getApprovedFields() async {
    try {
      print('🔍 Fetching approved fields from database...');
      final response = await _supabase
          .from('fields')
          .select('*')
          .order('created_at', ascending: false);

      print('📊 Raw response from database: $response');
      print('📊 Response length: ${(response as List).length}');

      if (response.isEmpty) {
        print('⚠️ No approved fields found in database');
        return [];
      }

      final fields = (response as List)
          .map((field) {
            print('🏟️ Processing field: ${field['name']} - Status: ${field['status']}');
            return RealField.fromJson(field);
          })
          .toList();

      print('✅ Successfully loaded ${fields.length} approved fields');
      return fields;
    } catch (e) {
      print('❌ Error fetching fields: $e');
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
          .not('latitude', 'is', null)
          .not('longitude', 'is', null)
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
      final response = await _supabase.rpc(
        'get_goalkeepers_within_radius',
        params: {
          'lat': latitude,
          'long': longitude,
          'radius': radiusKm * 1000, // Convert km to meters
        },
      );

      return (response as List)
          .map((user) => RealGoalkeeper.fromJson(user))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch nearby goalkeepers: $e');
    }
  }

  /// Fetch all players (non-goalkeepers) from the database
  Future<List<RealGoalkeeper>> getPlayers() async {
    try {
      final response = await _supabase
          .from('users')
          .select('*')
          .eq('is_goalkeeper', false)
          .not('latitude', 'is', null)
          .not('longitude', 'is', null)
          .order('created_at', ascending: false);

      return (response as List)
          .map((user) => RealGoalkeeper.fromJson(user))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch players: $e');
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

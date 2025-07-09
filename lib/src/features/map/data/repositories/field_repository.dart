import 'dart:math' as math;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/map_field.dart';

class FieldRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get all approved fields for display on the map
  Future<List<MapField>> getApprovedFields() async {
    try {
      final response = await _supabase
          .from('fields')
          .select()
          .eq('status', 'approved')
          .order('created_at', ascending: false);

      return (response as List)
          .map((field) => MapField.fromMap(field))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch approved fields: $e');
    }
  }

  /// Get fields by status (pending, approved, rejected)
  Future<List<MapField>> getFieldsByStatus(String status) async {
    try {
      final response = await _supabase
          .from('fields')
          .select()
          .eq('status', status)
          .order('created_at', ascending: false);

      return (response as List)
          .map((field) => MapField.fromMap(field))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch fields by status: $e');
    }
  }

  /// Get fields submitted by a specific user
  Future<List<MapField>> getUserSubmittedFields(String userId) async {
    try {
      final response = await _supabase
          .from('fields')
          .select()
          .eq('submitted_by', userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((field) => MapField.fromMap(field))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch user submitted fields: $e');
    }
  }

  /// Suggest a new field (submits with pending status)
  Future<MapField> suggestField({
    required String name,
    required double latitude,
    required double longitude,
    String? photoUrl,
    String? description,
    String? surfaceType,
    String? dimensions,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User must be authenticated to suggest fields');
      }

      final fieldData = {
        'name': name,
        'latitude': latitude,
        'longitude': longitude,
        'photo_url': photoUrl,
        'status': 'pending',
        'submitted_by': user.id,
        'description': description,
        'surface_type': surfaceType,
        'dimensions': dimensions,
        'created_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabase
          .from('fields')
          .insert(fieldData)
          .select()
          .single();

      return MapField.fromMap(response);
    } catch (e) {
      throw Exception('Failed to suggest field: $e');
    }
  }

  /// Update field status (for admin use)
  Future<MapField> updateFieldStatus(String fieldId, String status) async {
    try {
      final response = await _supabase
          .from('fields')
          .update({'status': status})
          .eq('id', fieldId)
          .select()
          .single();

      return MapField.fromMap(response);
    } catch (e) {
      throw Exception('Failed to update field status: $e');
    }
  }

  /// Delete a field
  Future<void> deleteField(String fieldId) async {
    try {
      await _supabase
          .from('fields')
          .delete()
          .eq('id', fieldId);
    } catch (e) {
      throw Exception('Failed to delete field: $e');
    }
  }

  /// Get a single field by ID
  Future<MapField?> getFieldById(String fieldId) async {
    try {
      final response = await _supabase
          .from('fields')
          .select()
          .eq('id', fieldId)
          .maybeSingle();

      if (response == null) return null;
      return MapField.fromMap(response);
    } catch (e) {
      throw Exception('Failed to fetch field: $e');
    }
  }

  /// Search fields by name or description
  Future<List<MapField>> searchFields(String query) async {
    try {
      final response = await _supabase
          .from('fields')
          .select()
          .eq('status', 'approved')
          .or('name.ilike.%$query%,description.ilike.%$query%')
          .order('created_at', ascending: false);

      return (response as List)
          .map((field) => MapField.fromMap(field))
          .toList();
    } catch (e) {
      throw Exception('Failed to search fields: $e');
    }
  }

  /// Get fields within a specific radius (in meters) from a point
  Future<List<MapField>> getFieldsNearLocation({
    required double latitude,
    required double longitude,
    required double radiusInMeters,
  }) async {
    try {
      // Using PostgreSQL earth distance function
      // Note: This requires the earthdistance extension to be enabled in Supabase
      final response = await _supabase
          .from('fields')
          .select()
          .eq('status', 'approved')
          .filter('location', 'dwithin', 
              'POINT($longitude $latitude)::geography,${radiusInMeters.toString()}')
          .order('created_at', ascending: false);

      return (response as List)
          .map((field) => MapField.fromMap(field))
          .toList();
    } catch (e) {
      // Fallback to client-side filtering if PostGIS is not available
      final allFields = await getApprovedFields();
      return allFields.where((field) {
        final distance = _calculateDistance(
          latitude, longitude, 
          field.latitude, field.longitude
        );
        return distance <= radiusInMeters;
      }).toList();
    }
  }

  /// Calculate distance between two points in meters (Haversine formula)
  double _calculateDistance(
    double lat1, double lon1, 
    double lat2, double lon2
  ) {
    const double earthRadius = 6371000; // Earth's radius in meters
    final double dLat = _toRadians(lat2 - lat1);
    final double dLon = _toRadians(lon2 - lon1);
    
    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) * math.cos(_toRadians(lat2)) *
        math.sin(dLon / 2) * math.sin(dLon / 2);
    
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    
    return earthRadius * c;
  }

  double _toRadians(double degrees) {
    return degrees * (math.pi / 180);
  }
}

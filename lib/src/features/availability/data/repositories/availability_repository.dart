import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/availability.dart';

class AvailabilityRepository {
  final _supabase = Supabase.instance.client;

  /// Get all availabilities for a specific goalkeeper
  Future<List<Availability>> getGoalkeeperAvailabilities(String goalkeeperId) async {
    try {
      final response = await _supabase
          .from('availabilities')
          .select()
          .eq('goalkeeper_id', goalkeeperId)
          .order('day', ascending: true)
          .order('start_time', ascending: true);

      if (response.isEmpty) {
        return [];
      }

      return response
          .map<Availability>((availability) => Availability.fromMap(availability))
          .toList();
    } catch (e) {
      throw Exception('Erro ao carregar disponibilidades: $e');
    }
  }

  /// Add a new availability
  Future<Availability> addAvailability(Availability availability) async {
    try {
      final response = await _supabase
          .from('availabilities')
          .insert(availability.toMap())
          .select()
          .single();

      return Availability.fromMap(response);
    } catch (e) {
      throw Exception('Erro ao adicionar disponibilidade: $e');
    }
  }

  /// Update an existing availability
  Future<Availability> updateAvailability(Availability availability) async {
    try {
      final response = await _supabase
          .from('availabilities')
          .update(availability.toMap())
          .eq('id', availability.id)
          .select()
          .single();

      return Availability.fromMap(response);
    } catch (e) {
      throw Exception('Erro ao atualizar disponibilidade: $e');
    }
  }

  /// Delete an availability
  Future<void> deleteAvailability(String availabilityId) async {
    try {
      await _supabase
          .from('availabilities')
          .delete()
          .eq('id', availabilityId);
    } catch (e) {
      throw Exception('Erro ao remover disponibilidade: $e');
    }
  }

  /// Get availabilities for a specific date range
  Future<List<Availability>> getAvailabilitiesInRange({
    required String goalkeeperId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final response = await _supabase
          .from('availabilities')
          .select()
          .eq('goalkeeper_id', goalkeeperId)
          .gte('day', startDate.toIso8601String().split('T')[0])
          .lte('day', endDate.toIso8601String().split('T')[0])
          .order('day', ascending: true)
          .order('start_time', ascending: true);

      if (response.isEmpty) {
        return [];
      }

      return response
          .map<Availability>((availability) => Availability.fromMap(availability))
          .toList();
    } catch (e) {
      throw Exception('Erro ao carregar disponibilidades no período: $e');
    }
  }

  /// Get future availabilities (from today onwards)
  Future<List<Availability>> getFutureAvailabilities(String goalkeeperId) async {
    try {
      final today = DateTime.now().toIso8601String().split('T')[0];
      
      final response = await _supabase
          .from('availabilities')
          .select()
          .eq('goalkeeper_id', goalkeeperId)
          .gte('day', today)
          .order('day', ascending: true)
          .order('start_time', ascending: true);

      if (response.isEmpty) {
        return [];
      }

      return response
          .map<Availability>((availability) => Availability.fromMap(availability))
          .toList();
    } catch (e) {
      throw Exception('Erro ao carregar disponibilidades futuras: $e');
    }
  }

  /// Check if a time slot conflicts with existing availabilities
  Future<bool> hasTimeConflict({
    required String goalkeeperId,
    required DateTime day,
    required String startTime,
    required String endTime,
    String? excludeAvailabilityId,
  }) async {
    try {
      var query = _supabase
          .from('availabilities')
          .select()
          .eq('goalkeeper_id', goalkeeperId)
          .eq('day', day.toIso8601String().split('T')[0]);

      if (excludeAvailabilityId != null) {
        query = query.neq('id', excludeAvailabilityId);
      }

      final response = await query;

      if (response.isEmpty) {
        return false;
      }

      // Convert time strings to minutes for easier comparison
      int timeToMinutes(String time) {
        final parts = time.split(':');
        return int.parse(parts[0]) * 60 + int.parse(parts[1]);
      }

      final newStartMinutes = timeToMinutes(startTime);
      final newEndMinutes = timeToMinutes(endTime);

      for (final availability in response) {
        final existingStartMinutes = timeToMinutes(availability['start_time']);
        final existingEndMinutes = timeToMinutes(availability['end_time']);

        // Check for overlap
        if (newStartMinutes < existingEndMinutes && newEndMinutes > existingStartMinutes) {
          return true;
        }
      }

      return false;
    } catch (e) {
      throw Exception('Erro ao verificar conflitos de horário: $e');
    }
  }
}

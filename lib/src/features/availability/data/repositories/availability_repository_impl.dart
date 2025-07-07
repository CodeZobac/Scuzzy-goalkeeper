import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/availability.dart';
import 'availability_repository.dart';

class AvailabilityRepositoryImpl implements AvailabilityRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  @override
  Future<List<Availability>> getAvailabilities(String goalkeeperId) async {
    try {
      final response = await _supabase
          .from('availabilities')
          .select()
          .eq('goalkeeper_id', goalkeeperId)
          .order('day', ascending: true);

      return response.map((json) => Availability.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Erro ao buscar disponibilidades: $e');
    }
  }

  @override
  Future<Availability> createAvailability(Availability availability) async {
    try {
      final response = await _supabase
          .from('availabilities')
          .insert(availability.toJsonForInsert())
          .select()
          .single();

      return Availability.fromJson(response);
    } catch (e) {
      throw Exception('Erro ao criar disponibilidade: $e');
    }
  }

  @override
  Future<void> deleteAvailability(String availabilityId) async {
    try {
      await _supabase
          .from('availabilities')
          .delete()
          .eq('id', availabilityId);
    } catch (e) {
      throw Exception('Erro ao deletar disponibilidade: $e');
    }
  }

  @override
  Future<Availability> updateAvailability(Availability availability) async {
    try {
      final response = await _supabase
          .from('availabilities')
          .update(availability.toJsonForInsert())
          .eq('id', availability.id!)
          .select()
          .single();

      return Availability.fromJson(response);
    } catch (e) {
      throw Exception('Erro ao atualizar disponibilidade: $e');
    }
  }
}

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/goalkeeper.dart';

class GoalkeeperSearchRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Searches for goalkeepers based on optional filters
  Future<List<Goalkeeper>> searchGoalkeepers({
    String? searchQuery,
    String? cityFilter,
    double? maxPrice,
    double? minPrice,
  }) async {
    try {
      // Start with base query filtering for goalkeepers
      var query = _supabase
          .from('users')
          .select('*')
          .eq('is_goalkeeper', true);

      // Apply search query filter (searches in name and city)
      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final trimmedQuery = searchQuery.trim().toLowerCase();
        query = query.or('name.ilike.%$trimmedQuery%,city.ilike.%$trimmedQuery%');
      }

      // Apply city filter
      if (cityFilter != null && cityFilter.trim().isNotEmpty) {
        query = query.ilike('city', '%${cityFilter.trim()}%');
      }

      // Apply price filters
      if (minPrice != null) {
        query = query.gte('price_per_game', minPrice);
      }
      if (maxPrice != null) {
        query = query.lte('price_per_game', maxPrice);
      }

      // Order by name for consistent results
      final response = await query.order('name');
      
      return response
          .map<Goalkeeper>((data) => Goalkeeper.fromMap(data))
          .toList();
    } catch (e) {
      throw Exception('Erro ao buscar guarda-redes: $e');
    }
  }

  /// Gets all available cities where goalkeepers are located
  Future<List<String>> getAvailableCities() async {
    try {
      final response = await _supabase
          .from('users')
          .select('city')
          .eq('is_goalkeeper', true)
          .not('city', 'is', null);

      final cities = response
          .map<String>((data) => data['city'] as String)
          .where((city) => city.trim().isNotEmpty)
          .toSet()
          .toList();

      cities.sort();
      return cities;
    } catch (e) {
      throw Exception('Erro ao carregar cidades: $e');
    }
  }

  /// Gets goalkeeper statistics for dashboard
  Future<Map<String, dynamic>> getGoalkeeperStats() async {
    try {
      final response = await _supabase
          .from('users')
          .select('price_per_game')
          .eq('is_goalkeeper', true);

      final prices = response
          .where((data) => data['price_per_game'] != null)
          .map<double>((data) => (data['price_per_game'] as num).toDouble())
          .toList();

      if (prices.isEmpty) {
        return {
          'total_goalkeepers': 0,
          'average_price': 0.0,
          'min_price': 0.0,
          'max_price': 0.0,
        };
      }

      prices.sort();
      
      return {
        'total_goalkeepers': response.length,
        'average_price': prices.reduce((a, b) => a + b) / prices.length,
        'min_price': prices.first,
        'max_price': prices.last,
      };
    } catch (e) {
      throw Exception('Erro ao carregar estatísticas: $e');
    }
  }
}

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/rating.dart';

class RatingRepository {
  final SupabaseClient _client = Supabase.instance.client;

  /// Creates a new rating
  Future<void> createRating(Rating rating) async {
    try {
      await _client
          .from('ratings')
          .insert(rating.toCreateMap());
    } catch (e) {
      throw Exception('Erro ao enviar avaliação: $e');
    }
  }

  /// Gets ratings for a specific goalkeeper
  Future<List<Rating>> getGoalkeeperRatings(String goalkeeperId) async {
    try {
      final response = await _client
          .from('ratings')
          .select()
          .eq('goalkeeper_id', goalkeeperId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((rating) => Rating.fromMap(rating))
          .toList();
    } catch (e) {
      throw Exception('Erro ao carregar avaliações: $e');
    }
  }

  /// Gets ratings by a specific player
  Future<List<Rating>> getPlayerRatings(String playerId) async {
    try {
      final response = await _client
          .from('ratings')
          .select()
          .eq('player_id', playerId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((rating) => Rating.fromMap(rating))
          .toList();
    } catch (e) {
      throw Exception('Erro ao carregar as suas avaliações: $e');
    }
  }

  /// Checks if a booking has already been rated
  Future<bool> hasBookingBeenRated(String bookingId) async {
    try {
      final response = await _client
          .from('ratings')
          .select('id')
          .eq('booking_id', bookingId)
          .limit(1);

      return (response as List).isNotEmpty;
    } catch (e) {
      throw Exception('Erro ao verificar avaliação: $e');
    }
  }

  /// Gets rating for a specific booking
  Future<Rating?> getBookingRating(String bookingId) async {
    try {
      final response = await _client
          .from('ratings')
          .select()
          .eq('booking_id', bookingId)
          .limit(1);

      if ((response as List).isEmpty) {
        return null;
      }

      return Rating.fromMap(response.first);
    } catch (e) {
      throw Exception('Erro ao carregar avaliação: $e');
    }
  }

  /// Gets average rating and count for a goalkeeper
  Future<Map<String, dynamic>> getGoalkeeperRatingStats(String goalkeeperId) async {
    try {
      final response = await _client
          .rpc('get_goalkeeper_rating_stats', params: {
            'goalkeeper_id_param': goalkeeperId,
          });

      if (response == null) {
        return {
          'average_rating': 0.0,
          'total_ratings': 0,
        };
      }

      return {
        'average_rating': (response['average_rating'] ?? 0.0).toDouble(),
        'total_ratings': response['total_ratings'] ?? 0,
      };
    } catch (e) {
      // Fallback calculation if RPC function doesn't exist
      return await _calculateRatingStatsManually(goalkeeperId);
    }
  }

  /// Manual calculation fallback for rating stats
  Future<Map<String, dynamic>> _calculateRatingStatsManually(String goalkeeperId) async {
    try {
      final ratings = await getGoalkeeperRatings(goalkeeperId);
      
      if (ratings.isEmpty) {
        return {
          'average_rating': 0.0,
          'total_ratings': 0,
        };
      }

      final totalRating = ratings.fold<int>(0, (sum, rating) => sum + rating.rating);
      final averageRating = totalRating / ratings.length;

      return {
        'average_rating': averageRating,
        'total_ratings': ratings.length,
      };
    } catch (e) {
      return {
        'average_rating': 0.0,
        'total_ratings': 0,
      };
    }
  }
}

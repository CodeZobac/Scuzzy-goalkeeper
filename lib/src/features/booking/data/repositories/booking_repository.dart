import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/booking.dart';
import '../models/availability.dart';
import '../models/field.dart';

class BookingRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Gets availability slots for a goalkeeper
  Future<List<Availability>> getGoalkeeperAvailability(String goalkeeperId) async {
    try {
      final response = await _supabase
          .from('availabilities')
          .select('*')
          .eq('goalkeeper_id', goalkeeperId)
          .gte('day', DateTime.now().toIso8601String().split('T')[0]); // Only future dates

      return response
          .map<Availability>((data) => Availability.fromMap(data))
          .toList();
    } catch (e) {
      throw Exception('Erro ao carregar disponibilidade: $e');
    }
  }

  /// Gets all bookings for a player
  Future<List<Booking>> getPlayerBookings(String playerId) async {
    try {
      final response = await _supabase
          .from('bookings')
          .select('*')
          .eq('player_id', playerId)
          .order('game_datetime', ascending: false);

      return response
          .map<Booking>((data) => Booking.fromMap(data))
          .toList();
    } catch (e) {
      throw Exception('Erro ao carregar agendamentos: $e');
    }
  }

  /// Gets all approved fields
  Future<List<Field>> getAvailableFields() async {
    try {
      final response = await _supabase
          .from('fields')
          .select('*')
          .eq('status', 'approved')
          .order('name');

      return response
          .map<Field>((data) => Field.fromMap(data))
          .toList();
    } catch (e) {
      throw Exception('Erro ao carregar campos: $e');
    }
  }

  /// Creates a new booking
  Future<Booking> createBooking({
    required String playerId,
    required String goalkeeperId,
    String? fieldId,
    required DateTime gameDateTime,
    required double price,
  }) async {
    try {
      final bookingData = {
        'player_id': playerId,
        'goalkeeper_id': goalkeeperId,
        'field_id': fieldId,
        'game_datetime': gameDateTime.toIso8601String(),
        'price': price,
        'status': 'pending',
      };

      final response = await _supabase
          .from('bookings')
          .insert(bookingData)
          .select()
          .single();

      return Booking.fromMap(response);
    } catch (e) {
      throw Exception('Erro ao criar agendamento: $e');
    }
  }

  /// Deletes a booking
  Future<void> deleteBooking(String bookingId) async {
    try {
      await _supabase
          .from('bookings')
          .delete()
          .eq('id', bookingId);
    } catch (e) {
      throw Exception('Erro ao cancelar agendamento: $e');
    }
  }

  /// Checks if a time slot is available for a goalkeeper
  Future<bool> isTimeSlotAvailable(String goalkeeperId, DateTime dateTime) async {
    try {
      // Check if there's an availability slot that covers this time
      final availabilityList = await getGoalkeeperAvailability(goalkeeperId);
      bool hasAvailability = false;
      
      for (final availability in availabilityList) {
        if (availability.containsDateTime(dateTime)) {
          hasAvailability = true;
          break;
        }
      }
      
      if (!hasAvailability) {
        return false;
      }

      // Check if there's already a booking at this time
      final existingBookings = await _supabase
          .from('bookings')
          .select('*')
          .eq('goalkeeper_id', goalkeeperId)
          .eq('game_datetime', dateTime.toIso8601String())
          .neq('status', 'cancelled');

      return existingBookings.isEmpty;
    } catch (e) {
      throw Exception('Erro ao verificar disponibilidade: $e');
    }
  }

  /// Gets all available time slots for a goalkeeper on a specific date
  Future<List<DateTime>> getAvailableTimeSlots(String goalkeeperId, DateTime date) async {
    try {
      final availabilityList = await getGoalkeeperAvailability(goalkeeperId);
      final availableSlots = <DateTime>[];

      // Get all possible slots from availability
      for (final availability in availabilityList) {
        if (availability.day.year == date.year &&
            availability.day.month == date.month &&
            availability.day.day == date.day) {
          availableSlots.addAll(availability.getAvailableSlots());
        }
      }

      // Filter out already booked slots
      final bookedSlots = await _supabase
          .from('bookings')
          .select('game_datetime')
          .eq('goalkeeper_id', goalkeeperId)
          .gte('game_datetime', date.toIso8601String().split('T')[0])
          .lt('game_datetime', DateTime(date.year, date.month, date.day + 1).toIso8601String().split('T')[0])
          .neq('status', 'cancelled');

      final bookedTimes = bookedSlots
          .map<DateTime>((data) => DateTime.parse(data['game_datetime']))
          .toSet();

      return availableSlots
          .where((slot) => !bookedTimes.contains(slot))
          .toList();
    } catch (e) {
      throw Exception('Erro ao carregar horários disponíveis: $e');
    }
  }
}

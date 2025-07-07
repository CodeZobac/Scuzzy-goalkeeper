import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/repositories/rating_repository.dart';
import '../../booking/data/repositories/booking_repository.dart';
import '../../booking/data/models/booking.dart';

class RatingNotificationService extends ChangeNotifier {
  final RatingRepository _ratingRepository;
  final BookingRepository _bookingRepository;

  RatingNotificationService({
    required RatingRepository ratingRepository,
    required BookingRepository bookingRepository,
  })  : _ratingRepository = ratingRepository,
        _bookingRepository = bookingRepository;

  List<Booking> _completedBookingsToRate = [];
  Map<String, String> _goalkeeperNames = {};
  bool _isLoading = false;
  DateTime? _lastChecked;

  // Getters
  List<Booking> get completedBookingsToRate => _completedBookingsToRate;
  Map<String, String> get goalkeeperNames => _goalkeeperNames;
  bool get isLoading => _isLoading;
  bool get hasBookingsToRate => _completedBookingsToRate.isNotEmpty;
  int get pendingRatingsCount => _completedBookingsToRate.length;

  /// Checks for completed bookings that haven't been rated yet
  Future<void> checkForCompletedBookings(String userId) async {
    // Avoid checking too frequently
    if (_lastChecked != null && 
        DateTime.now().difference(_lastChecked!) < const Duration(minutes: 5)) {
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      // Get all completed bookings for the user
      final completedBookings = await _getCompletedBookingsForUser(userId);
      
      // Filter out bookings that have already been rated
      final unratedBookings = <Booking>[];
      final goalkeeperNamesMap = <String, String>{};

      for (final booking in completedBookings) {
        final alreadyRated = await _ratingRepository.hasBookingBeenRated(booking.id);
        if (!alreadyRated) {
          unratedBookings.add(booking);
          
          // Get goalkeeper name (this would ideally come from a user service)
          final goalkeeperName = await _getGoalkeeperName(booking.goalkeeperId);
          goalkeeperNamesMap[booking.goalkeeperId] = goalkeeperName;
        }
      }

      _completedBookingsToRate = unratedBookings;
      _goalkeeperNames = goalkeeperNamesMap;
      _lastChecked = DateTime.now();

    } catch (e) {
      debugPrint('Error checking for completed bookings: $e');
      _completedBookingsToRate = [];
      _goalkeeperNames = {};
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Gets completed bookings for a specific user
  Future<List<Booking>> _getCompletedBookingsForUser(String userId) async {
    try {
      // This would need to be implemented in BookingRepository
      // For now, we'll simulate the call
      return await _bookingRepository.getCompletedBookingsForPlayer(userId);
    } catch (e) {
      debugPrint('Error getting completed bookings: $e');
      return [];
    }
  }

  /// Gets goalkeeper name by ID
  Future<String> _getGoalkeeperName(String goalkeeperId) async {
    try {
      // Get goalkeeper name from users table
      final response = await Supabase.instance.client
          .from('users')
          .select('name')
          .eq('id', goalkeeperId)
          .limit(1);
      
      if (response.isNotEmpty) {
        return response.first['name'] ?? 'Guarda-redes';
      }
      
      return 'Guarda-redes';
    } catch (e) {
      debugPrint('Error getting goalkeeper name: $e');
      return 'Guarda-redes';
    }
  }

  /// Marks a booking as rated (removes it from pending list)
  void markBookingAsRated(String bookingId) {
    _completedBookingsToRate.removeWhere((booking) => booking.id == bookingId);
    notifyListeners();
  }

  /// Dismisses all rating notifications
  void dismissAllNotifications() {
    _completedBookingsToRate.clear();
    _goalkeeperNames.clear();
    notifyListeners();
  }

  /// Forces a refresh of the completed bookings check
  Future<void> forceRefresh(String userId) async {
    _lastChecked = null;
    await checkForCompletedBookings(userId);
  }

  /// Schedules periodic checks for completed bookings
  void startPeriodicChecks(String userId) {
    // Check immediately
    checkForCompletedBookings(userId);
    
    // Then check every 30 minutes
    Stream.periodic(const Duration(minutes: 30)).listen((_) {
      checkForCompletedBookings(userId);
    });
  }

  /// Gets the next booking to rate (most recent)
  Booking? getNextBookingToRate() {
    if (_completedBookingsToRate.isEmpty) return null;
    
    // Sort by game date, most recent first
    _completedBookingsToRate.sort((a, b) => b.gameDateTime.compareTo(a.gameDateTime));
    return _completedBookingsToRate.first;
  }

  /// Check if a specific booking can be rated
  Future<bool> canBookingBeRated(String bookingId, String userId) async {
    try {
      // Check if already rated
      final alreadyRated = await _ratingRepository.hasBookingBeenRated(bookingId);
      if (alreadyRated) return false;

      // Check if booking is completed and belongs to user
      final booking = _completedBookingsToRate.firstWhere(
        (b) => b.id == bookingId,
        orElse: () => throw Exception('Booking not found'),
      );

      return booking.isCompleted && booking.playerId == userId;
    } catch (e) {
      return false;
    }
  }

  /// Gets rating statistics for display
  Map<String, dynamic> getRatingStats() {
    return {
      'total_pending': _completedBookingsToRate.length,
      'oldest_booking': _completedBookingsToRate.isNotEmpty 
          ? _completedBookingsToRate
              .reduce((a, b) => a.gameDateTime.isBefore(b.gameDateTime) ? a : b)
              .gameDateTime
          : null,
      'newest_booking': _completedBookingsToRate.isNotEmpty
          ? _completedBookingsToRate
              .reduce((a, b) => a.gameDateTime.isAfter(b.gameDateTime) ? a : b)
              .gameDateTime
          : null,
    };
  }
}

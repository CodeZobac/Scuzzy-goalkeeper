import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/availability.dart';
import '../../data/repositories/availability_repository.dart';
import '../../data/repositories/availability_repository_impl.dart';

class AvailabilityController extends ChangeNotifier {
  final AvailabilityRepository _repository = AvailabilityRepositoryImpl();
  final SupabaseClient _supabase = Supabase.instance.client;

  List<Availability> _availabilities = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<Availability> get availabilities => _availabilities;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  // Get current user ID
  String? get _currentUserId => _supabase.auth.currentUser?.id;

  // Load availabilities for the current goalkeeper
  Future<void> loadAvailabilities() async {
    if (_currentUserId == null) {
      _errorMessage = 'Utilizador não autenticado';
      notifyListeners();
      return;
    }

    _setLoading(true);
    _clearError();

    try {
      _availabilities = await _repository.getAvailabilities(_currentUserId!);
      notifyListeners();
    } catch (e) {
      _setError('Erro ao carregar disponibilidades: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Create a new availability
  Future<bool> createAvailability(Availability availability) async {
    if (_currentUserId == null) {
      _setError('Utilizador não autenticado');
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      // Validate availability
      if (!availability.isValid) {
        _setError('Horário inválido: hora de fim deve ser posterior à hora de início');
        return false;
      }

      // Check for overlapping availabilities
      if (_hasOverlappingAvailability(availability)) {
        _setError('Já existe uma disponibilidade que se sobrepõe a este horário');
        return false;
      }

      // Create the availability with current user ID
      final newAvailability = Availability(
        goalkeeperId: _currentUserId!,
        day: availability.day,
        startTime: availability.startTime,
        endTime: availability.endTime,
      );

      final createdAvailability = await _repository.createAvailability(newAvailability);
      _availabilities.add(createdAvailability);
      
      // Sort by date
      _availabilities.sort((a, b) => a.day.compareTo(b.day));
      
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Erro ao criar disponibilidade: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Delete an availability
  Future<bool> deleteAvailability(String availabilityId) async {
    _setLoading(true);
    _clearError();

    try {
      await _repository.deleteAvailability(availabilityId);
      _availabilities.removeWhere((availability) => availability.id == availabilityId);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Erro ao deletar disponibilidade: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update an availability
  Future<bool> updateAvailability(Availability availability) async {
    _setLoading(true);
    _clearError();

    try {
      // Validate availability
      if (!availability.isValid) {
        _setError('Horário inválido: hora de fim deve ser posterior à hora de início');
        return false;
      }

      // Check for overlapping availabilities (excluding current one)
      if (_hasOverlappingAvailability(availability, excludeId: availability.id)) {
        _setError('Já existe uma disponibilidade que se sobrepõe a este horário');
        return false;
      }

      final updatedAvailability = await _repository.updateAvailability(availability);
      final index = _availabilities.indexWhere((a) => a.id == availability.id);
      
      if (index != -1) {
        _availabilities[index] = updatedAvailability;
        // Sort by date
        _availabilities.sort((a, b) => a.day.compareTo(b.day));
        notifyListeners();
      }
      
      return true;
    } catch (e) {
      _setError('Erro ao atualizar disponibilidade: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Check if there's an overlapping availability
  bool _hasOverlappingAvailability(Availability newAvailability, {String? excludeId}) {
    final newStartMinutes = newAvailability.startTime.hour * 60 + newAvailability.startTime.minute;
    final newEndMinutes = newAvailability.endTime.hour * 60 + newAvailability.endTime.minute;

    for (final existing in _availabilities) {
      // Skip if this is the same availability being updated
      if (excludeId != null && existing.id == excludeId) continue;
      
      // Check if it's the same day
      if (existing.day.year == newAvailability.day.year &&
          existing.day.month == newAvailability.day.month &&
          existing.day.day == newAvailability.day.day) {
        
        final existingStartMinutes = existing.startTime.hour * 60 + existing.startTime.minute;
        final existingEndMinutes = existing.endTime.hour * 60 + existing.endTime.minute;

        // Check for overlap
        if (newStartMinutes < existingEndMinutes && newEndMinutes > existingStartMinutes) {
          return true;
        }
      }
    }
    return false;
  }

  // Clear error message
  void clearError() {
    _clearError();
    notifyListeners();
  }

  // Private helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  @override
  void dispose() {
    super.dispose();
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import '../../data/repositories/booking_repository.dart';
import '../../data/models/field.dart';
import '../../../goalkeeper_search/data/models/goalkeeper.dart';

class BookingController extends ChangeNotifier {
  final BookingRepository _repository;

  BookingController(this._repository);

  // State variables
  List<DateTime> _availableTimeSlots = [];
  List<Field> _availableFields = [];
  String? _error;

  DateTime? _selectedDate;
  DateTime? _selectedTime;
  Field? _selectedField;

  bool _isLoading = false;

  // Getters
  List<DateTime> get availableTimeSlots => _availableTimeSlots;
  List<Field> get availableFields => _availableFields;
  String? get error => _error;
  bool get isLoading => _isLoading;
  
  DateTime? get selectedDate => _selectedDate;
  DateTime? get selectedTime => _selectedTime;
  Field? get selectedField => _selectedField;

  // Setters
  set selectedDate(DateTime? date) {
    _selectedDate = date;
    notifyListeners();
  }

  set selectedTime(DateTime? time) {
    _selectedTime = time;
    notifyListeners();
  }

  set selectedField(Field? field) {
    _selectedField = field;
    notifyListeners();
  }

  /// Loads available time slots for a given goalkeeper on the selected date
  Future<void> loadAvailableTimeSlots(String goalkeeperId) async {
    if (_selectedDate == null) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _availableTimeSlots = await _repository.getAvailableTimeSlots(goalkeeperId, _selectedDate!);
    } catch (e) {
      _error = e.toString();
      _availableTimeSlots = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Loads available fields for selection
  Future<void> loadAvailableFields() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _availableFields = await _repository.getAvailableFields();
    } catch (e) {
      _error = e.toString();
      _availableFields = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Creates a booking
  Future<void> createBooking(String playerId, Goalkeeper goalkeeper) async {
    if (_selectedTime == null) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _repository.createBooking(
        playerId: playerId,
        goalkeeperId: goalkeeper.id,
        fieldId: _selectedField?.id,
        gameDateTime: _selectedTime!,
        price: goalkeeper.pricePerGame!,
      );
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Initializes the booking process by loading fields
  Future<void> initialize() async {
    await loadAvailableFields();
  }
}


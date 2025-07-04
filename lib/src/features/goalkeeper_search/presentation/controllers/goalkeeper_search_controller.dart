import 'dart:async';
import 'package:flutter/material.dart';
import '../../data/models/goalkeeper.dart';
import '../../data/repositories/goalkeeper_search_repository.dart';

class GoalkeeperSearchController extends ChangeNotifier {
  final GoalkeeperSearchRepository _repository;

  GoalkeeperSearchController(this._repository);

  // State variables
  List<Goalkeeper> _goalkeepers = [];
  List<String> _availableCities = [];
  Map<String, dynamic> _stats = {};
  
  bool _isLoading = false;
  bool _isLoadingCities = false;
  String? _error;
  
  // Search filters
  String _searchQuery = '';
  String? _selectedCity;
  double? _minPrice;
  double? _maxPrice;

  // Getters
  List<Goalkeeper> get goalkeepers => _goalkeepers;
  List<String> get availableCities => _availableCities;
  Map<String, dynamic> get stats => _stats;
  bool get isLoading => _isLoading;
  bool get isLoadingCities => _isLoadingCities;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  String? get selectedCity => _selectedCity;
  double? get minPrice => _minPrice;
  double? get maxPrice => _maxPrice;
  
  bool get hasActiveFilters => 
      _searchQuery.isNotEmpty || 
      _selectedCity != null || 
      _minPrice != null || 
      _maxPrice != null;

  /// Searches for goalkeepers with current filters
  Future<void> searchGoalkeepers() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _goalkeepers = await _repository.searchGoalkeepers(
        searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
        cityFilter: _selectedCity,
        minPrice: _minPrice,
        maxPrice: _maxPrice,
      );
    } catch (e) {
      _error = e.toString();
      _goalkeepers = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Updates search query and performs search
  void updateSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
    
    // Debounce search - search after a short delay
    _debounceSearch();
  }

  /// Updates city filter and performs search
  void updateCityFilter(String? city) {
    _selectedCity = city;
    notifyListeners();
    searchGoalkeepers();
  }

  /// Updates price range filter and performs search
  void updatePriceRange(double? minPrice, double? maxPrice) {
    _minPrice = minPrice;
    _maxPrice = maxPrice;
    notifyListeners();
    searchGoalkeepers();
  }

  /// Clears all filters and performs search
  void clearFilters() {
    _searchQuery = '';
    _selectedCity = null;
    _minPrice = null;
    _maxPrice = null;
    notifyListeners();
    searchGoalkeepers();
  }

  /// Loads available cities for filter dropdown
  Future<void> loadAvailableCities() async {
    _isLoadingCities = true;
    notifyListeners();

    try {
      _availableCities = await _repository.getAvailableCities();
    } catch (e) {
      // Silently handle city loading errors
      _availableCities = [];
    } finally {
      _isLoadingCities = false;
      notifyListeners();
    }
  }

  /// Loads goalkeeper statistics
  Future<void> loadStats() async {
    try {
      _stats = await _repository.getGoalkeeperStats();
      notifyListeners();
    } catch (e) {
      // Silently handle stats loading errors
      _stats = {};
    }
  }

  /// Performs initial data load
  Future<void> initialize() async {
    await Future.wait([
      searchGoalkeepers(),
      loadAvailableCities(),
      loadStats(),
    ]);
  }

  /// Refreshes all data
  Future<void> refresh() async {
    await initialize();
  }

  // Debounce timer for search
  Timer? _debounceTimer;

  void _debounceSearch() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      searchGoalkeepers();
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}

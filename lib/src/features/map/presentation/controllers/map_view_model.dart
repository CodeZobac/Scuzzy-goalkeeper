import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../data/repositories/field_repository.dart';
import '../../domain/models/map_field.dart';
import '../providers/field_selection_provider.dart';

class MapViewModel extends ChangeNotifier {
  final FieldRepository _fieldRepository;
  final FieldSelectionProvider _fieldSelectionProvider;
  MapController? _mapController;

  List<MapField> _fields = [];
  List<MapField> _filteredFields = [];
  Position? _userLocation;
  bool _isLoading = false;
  String? _error;
  
  // Filter properties
  List<String> _selectedSurfaces = [];
  List<String> _selectedSizes = [];
  double _maxDistance = 50.0; // km
  
  // Additional filter properties for compatibility
  String? _selectedCity;
  String? _selectedAvailability;
  List<String> _availableCities = [];
  
  MapViewModel(this._fieldRepository, this._fieldSelectionProvider);

  // Getters
  List<MapField> get fields => _filteredFields;
  Position? get userLocation => _userLocation;
  bool get isLoading => _isLoading;
  String? get error => _error;
  MapController? get mapController => _mapController;
  List<String> get selectedSurfaces => _selectedSurfaces;
  List<String> get selectedSizes => _selectedSizes;
  double get maxDistance => _maxDistance;
  String? get selectedCity => _selectedCity;
  String? get selectedAvailability => _selectedAvailability;
  List<String> get availableCities => _availableCities;

  // Set the map controller from the map screen
  void setMapController(MapController controller) {
    _mapController = controller;
  }

  // Initialize the map
  Future<void> initialize() async {
    _setLoading(true);
    try {
      await _loadFields();
      await _getCurrentLocation();
      _applyFilters();
    } catch (e) {
      _setError('Failed to initialize map: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Load fields from repository
  Future<void> _loadFields() async {
    try {
      _fields = await _fieldRepository.getApprovedFields();
    } catch (e) {
      throw Exception('Failed to load fields: $e');
    }
  }

  // Get user's current location
  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied');
      }

      _userLocation = await Geolocator.getCurrentPosition();
    } catch (e) {
      // Don't throw, just log - map can work without location
      debugPrint('Failed to get location: $e');
    }
  }

  // Apply filters to fields
  void _applyFilters() {
    _filteredFields = _fields.where((field) {
      // Surface filter
      if (_selectedSurfaces.isNotEmpty && 
          (field.surfaceType == null || !_selectedSurfaces.contains(field.surfaceType!))) {
        return false;
      }

      // Size filter
      if (_selectedSizes.isNotEmpty && 
          (field.dimensions == null || !_selectedSizes.contains(field.dimensions!))) {
        return false;
      }

      // City filter
      if (_selectedCity != null && 
          (field.city == null || field.city != _selectedCity)) {
        return false;
      }

      // Availability filter (placeholder - would need availability data in MapField)
      if (_selectedAvailability != null) {
        // This would need actual availability logic
        // For now, just pass through
      }

      // Distance filter
      if (_userLocation != null) {
        double distance = Geolocator.distanceBetween(
          _userLocation!.latitude,
          _userLocation!.longitude,
          field.latitude,
          field.longitude,
        ) / 1000; // Convert to km

        if (distance > _maxDistance) {
          return false;
        }
      }

      return true;
    }).toList();
    
    // Update available cities based on current fields
    _availableCities = _fields
        .where((field) => field.city != null)
        .map((field) => field.city!)
        .toSet()
        .toList();
    
    notifyListeners();
  }

  // Update surface filter
  void updateSurfaceFilter(List<String> surfaces) {
    _selectedSurfaces = surfaces;
    _applyFilters();
  }

  // Update size filter
  void updateSizeFilter(List<String> sizes) {
    _selectedSizes = sizes;
    _applyFilters();
  }

  // Update distance filter
  void updateDistanceFilter(double distance) {
    _maxDistance = distance;
    _applyFilters();
  }

  // Clear all filters
  void clearFilters() {
    _selectedSurfaces.clear();
    _selectedSizes.clear();
    _maxDistance = 50.0;
    _selectedCity = null;
    _selectedAvailability = null;
    _applyFilters();
  }

  // Additional filter methods for compatibility
  void filterByCity(String? city) {
    _selectedCity = city;
    _applyFilters();
  }

  void filterByAvailability(String? availability) {
    _selectedAvailability = availability;
    _applyFilters();
  }

  void clearAllFilters() {
    clearFilters();
  }

  void centerOnUserLocation() {
    centerOnUser();
  }

  // Select a field
  void selectField(MapField field) {
    _fieldSelectionProvider.selectField(field);
    
    // Move map to field location - but only if map is ready
    _moveMapToLocation(field.latitude, field.longitude);
  }

  // Safely move map to a location
  void _moveMapToLocation(double latitude, double longitude) {
    if (_mapController == null) {
      debugPrint('MapController not set yet');
      return;
    }
    
    // Use post frame callback to ensure map is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        _mapController!.move(
          LatLng(latitude, longitude),
          15.0, // zoom level
        );
      } catch (e) {
        // If map controller isn't ready, silently fail
        debugPrint('Map controller not ready: $e');
      }
    });
  }

  // Build markers for flutter_map
  List<Marker> buildMarkers() {
    List<Marker> markers = [];

    // Add field markers
    for (MapField field in _filteredFields) {
      markers.add(
        Marker(
          point: LatLng(field.latitude, field.longitude),
          width: 40,
          height: 40,
          child: GestureDetector(
            onTap: () => selectField(field),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(
                Icons.sports_soccer,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ),
      );
    }

    // Add user location marker if available
    if (_userLocation != null) {
      markers.add(
        Marker(
          point: LatLng(_userLocation!.latitude, _userLocation!.longitude),
          width: 30,
          height: 30,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: const Icon(
              Icons.person,
              color: Colors.white,
              size: 15,
            ),
          ),
        ),
      );
    }

    return markers;
  }

  // Center map on user location
  void centerOnUser() {
    if (_userLocation != null) {
      _moveMapToLocation(_userLocation!.latitude, _userLocation!.longitude);
    }
  }

  // Refresh data
  Future<void> refresh() async {
    await initialize();
  }

  // Private helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  @override
  void dispose() {
    // Don't dispose the map controller since it's managed by the map screen
    super.dispose();
  }
}

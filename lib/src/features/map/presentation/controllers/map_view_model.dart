import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:math';
import '../../data/repositories/field_repository.dart';
import '../../domain/models/map_field.dart';
import '../providers/field_selection_provider.dart';
import '../../../../shared/widgets/web_svg_asset.dart';

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
      
      // If no fields found, add some sample data for demonstration
      if (_fields.isEmpty) {
        _fields = _generateSampleFields();
        debugPrint('Using sample field data since no fields were found in database');
      }
    } catch (e) {
      // If repository fails, use sample data as fallback
      _fields = _generateSampleFields();
      debugPrint('Using sample field data due to repository error: $e');
    }
  }
  
  // Generate sample fields around Lisbon for demonstration
  List<MapField> _generateSampleFields() {
    final Random random = Random(42); // Fixed seed for consistent results
    final centerLat = 38.7223;
    final centerLng = -9.1393;
    final fields = <MapField>[];
    
    final fieldNames = [
      'Campo da Ajuda',
      'Estádio Universitário',
      'Campo do Benfica',
      'Complexo Desportivo de Algés',
      'Campo Municipal da Amadora',
      'Estádio José Gomes',
      'Campo da Reboleira',
      'Complexo do Jamor',
      'Campo de Carnaxide',
      'Estádio do Restelo',
      'Campo de Alcântara',
      'Complexo de Monsanto',
    ];
    
    final cities = ['Lisboa', 'Amadora', 'Oeiras', 'Cascais', 'Sintra'];
    final surfaces = ['natural', 'artificial', 'hybrid'];
    final dimensions = ['11v11', '7v7', '5v5'];
    
    for (int i = 0; i < fieldNames.length; i++) {
      // Generate location within ~15km radius of Lisbon center
      final LatLng location = _generateRandomLocation(centerLat, centerLng, 15.0);
      
      fields.add(MapField(
        id: 'sample_${i + 1}',
        name: fieldNames[i],
        latitude: location.latitude,
        longitude: location.longitude,
        status: 'approved',
        createdAt: DateTime.now().subtract(Duration(days: random.nextInt(30))),
        city: cities[random.nextInt(cities.length)],
        surfaceType: surfaces[random.nextInt(surfaces.length)],
        dimensions: dimensions[random.nextInt(dimensions.length)],
        description: 'Campo de futebol bem mantido com excelentes condições para jogos.',
        photoUrl: null, // Could add sample images later
      ));
    }
    
    return fields;
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

  // Generate random location within radius (in kilometers)
  LatLng _generateRandomLocation(double centerLat, double centerLng, double radiusKm) {
    final Random random = Random();
    
    // Convert radius from km to degrees (approximately)
    double radiusInDegrees = radiusKm / 111.0; // 1 degree ≈ 111 km
    
    // Generate random angle and distance
    double angle = random.nextDouble() * 2 * pi;
    double distance = sqrt(random.nextDouble()) * radiusInDegrees;
    
    // Calculate new coordinates
    double deltaLat = distance * cos(angle);
    double deltaLng = distance * sin(angle) / cos(centerLat * pi / 180);
    
    return LatLng(centerLat + deltaLat, centerLng + deltaLng);
  }
  
  // Build markers for flutter_map
  List<Marker> buildMarkers() {
    List<Marker> markers = [];

    // Add field markers with SVG icons
    for (MapField field in _filteredFields) {
      markers.add(
        Marker(
          point: LatLng(field.latitude, field.longitude),
          width: 50,
          height: 50,
          child: GestureDetector(
            onTap: () => selectField(field),
            child: WebSvgAsset(
              assetPath: 'assets/icons8-football-field.svg',
              width: 50,
              height: 50,
              colorFilter: const ColorFilter.mode(
                Colors.green,
                BlendMode.srcIn,
              ),
              placeholder: Container(
                width: 50,
                height: 50,
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.sports_soccer,
                  color: Colors.white,
                  size: 30,
                ),
              ),
            ),
          ),
        ),
      );
      
      // Add random players around each field (within 10km radius)
      final Random random = Random(field.name.hashCode); // Use field name as seed for consistency
      int playerCount = 3 + random.nextInt(8); // 3-10 players per field
      
      for (int i = 0; i < playerCount; i++) {
        LatLng playerLocation = _generateRandomLocation(
          field.latitude, 
          field.longitude, 
          10.0 // 10km radius
        );
        
        bool isGoalkeeper = i == 0; // First player is always goalkeeper
        
        markers.add(
          Marker(
            point: playerLocation,
            width: 35,
            height: 35,
            child: WebSvgAsset(
              assetPath: isGoalkeeper 
                ? 'assets/icons8-goalkeeper-o-mais-baddy.svg'
                : 'assets/icons8-football.svg',
              width: 35,
              height: 35,
              colorFilter: ColorFilter.mode(
                isGoalkeeper ? Colors.orange : Colors.blue,
                BlendMode.srcIn,
              ),
              placeholder: Container(
                width: 35,
                height: 35,
                decoration: BoxDecoration(
                  color: isGoalkeeper ? Colors.orange : Colors.blue,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isGoalkeeper ? Icons.sports_handball : Icons.sports_soccer,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        );
      }
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
              color: Colors.red,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.3),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(
              Icons.person,
              color: Colors.white,
              size: 18,
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

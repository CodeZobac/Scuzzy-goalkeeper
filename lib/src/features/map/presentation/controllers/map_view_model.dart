import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

import 'dart:math';
import '../../data/repositories/field_repository.dart';
import '../../domain/models/map_field.dart';
import '../providers/field_selection_provider.dart';
import '../../../../shared/widgets/web_svg_asset.dart';
import '../../../../core/utils/guest_mode_utils.dart';
import '../../../../shared/helpers/registration_prompt_helper.dart';
import '../../data/services/real_data_service.dart';
import '../../data/services/clustering_service.dart';
import '../../data/models/real_goalkeeper.dart';
import '../../data/models/cluster_point.dart';
import '../../data/models/cluster_result.dart';
import '../widgets/cluster_marker.dart';

class MapViewModel extends ChangeNotifier {
  final FieldRepository _fieldRepository;
  final FieldSelectionProvider _fieldSelectionProvider;
  final RealDataService _realDataService = RealDataService();
  MapController? _mapController;

  List<MapField> _fields = [];
  List<MapField> _filteredFields = [];
  List<RealGoalkeeper> _goalkeepers = [];
  List<RealGoalkeeper> _filteredGoalkeepers = [];
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
  List<RealGoalkeeper> get goalkeepers => _filteredGoalkeepers;
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
      await Future.wait([
        _loadFields(),
        _loadGoalkeepers(),
        _getCurrentLocation(),
      ]);
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
      // Try to load real fields from Supabase
      final realFields = await _realDataService.getApprovedFields();
      
      // Convert RealField to MapField for compatibility
      _fields = realFields.map((realField) => MapField(
        id: realField.id,
        name: realField.name,
        latitude: realField.latitude,
        longitude: realField.longitude,
        status: realField.status,
        createdAt: realField.createdAt,
        city: realField.city,
        surfaceType: realField.surfaceType,
        dimensions: realField.dimensions,
        description: realField.description,
        photoUrl: realField.photoUrl,
      )).toList();
      
      debugPrint('Loaded ${_fields.length} real fields from database');
      
      // If no fields found, add some sample data for demonstration
      if (_fields.isEmpty) {
        _fields = _generateSampleFields();
        debugPrint('Using sample field data since no fields were found in database');
      }
    } catch (e) {
      // If real data service fails, try the original repository
      try {
        _fields = await _fieldRepository.getApprovedFields();
        debugPrint('Loaded fields from original repository');
      } catch (e2) {
        // If both fail, use sample data as fallback
        _fields = _generateSampleFields();
        debugPrint('Using sample field data due to errors: $e, $e2');
      }
    }
  }

  // Load goalkeepers from database
  Future<void> _loadGoalkeepers() async {
    try {
      _goalkeepers = await _realDataService.getGoalkeepers();
      debugPrint('Loaded ${_goalkeepers.length} real goalkeepers from database');
    } catch (e) {
      debugPrint('Failed to load goalkeepers: $e');
      _goalkeepers = [];
    }
  }
  
  // Generate sample fields around Lisbon for demonstration
  List<MapField> _generateSampleFields() {
    final Random random = Random(42); // Fixed seed for consistent results
    const centerLat = 38.7223;
    const centerLng = -9.1393;
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
    
    const cities = ['Lisboa', 'Amadora', 'Oeiras', 'Cascais', 'Sintra'];
    const surfaces = ['natural', 'artificial', 'hybrid'];
    const dimensions = ['11v11', '7v7', '5v5'];
    
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

  // Apply filters to fields and goalkeepers
  void _applyFilters() {
    // Filter fields
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

    // Filter goalkeepers
    _filteredGoalkeepers = _goalkeepers.where((goalkeeper) {
      // City filter
      if (_selectedCity != null && 
          (goalkeeper.city == null || goalkeeper.city != _selectedCity)) {
        return false;
      }

      // Availability filter
      if (_selectedAvailability != null) {
        switch (_selectedAvailability) {
          case 'available':
            return goalkeeper.status == 'available';
          case 'verified':
            return goalkeeper.isVerified;
          default:
            break;
        }
      }

      return true;
    }).toList();
    
    // Update available cities based on current fields and goalkeepers
    final fieldCities = _fields
        .where((field) => field.city != null)
        .map((field) => field.city!)
        .toSet();
    
    final goalkeeperCities = _goalkeepers
        .where((gk) => gk.city != null)
        .map((gk) => gk.city!)
        .toSet();
    
    _availableCities = {...fieldCities, ...goalkeeperCities}.toList();
    _availableCities.sort();
    
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
  
  // Build markers for flutter_map with clustering support
  List<Marker> buildMarkers({
    BuildContext? context,
    Function(dynamic)? onGoalkeeperTap,
    double zoom = 12.0,
  }) {
    final List<Marker> markers = [];
    
    // Convert all data to cluster points
    final List<ClusterPoint> allPoints = [];
    
    // Add field points
    for (final field in _filteredFields) {
      allPoints.add(ClusterPoint.fromField(field));
    }
    
    // Add goalkeeper points
    for (final goalkeeper in _filteredGoalkeepers) {
      // Generate location for goalkeeper (near a field or default location)
      LatLng goalkeeperLocation;
      if (_filteredFields.isNotEmpty) {
        final randomField = _filteredFields[Random().nextInt(_filteredFields.length)];
        goalkeeperLocation = _generateRandomLocation(
          randomField.latitude,
          randomField.longitude,
          15.0, // 15km radius from field
        );
      } else {
        // Default to Lisbon area if no fields
        goalkeeperLocation = _generateRandomLocation(38.7223, -9.1393, 20.0);
      }
      
      allPoints.add(ClusterPoint.fromGoalkeeper(goalkeeper, goalkeeperLocation));
    }
    
    // Add sample player points around fields
    for (final field in _filteredFields) {
      final Random random = Random(field.name.hashCode);
      int playerCount = 2 + random.nextInt(4); // 2-5 players per field
      
      for (int i = 0; i < playerCount; i++) {
        final playerLocation = _generateRandomLocation(
          field.latitude, 
          field.longitude, 
          5.0 // 5km radius
        );
        
        allPoints.add(ClusterPoint.fromPlayer({
          'id': '${field.id}_player_$i',
          'name': 'Jogador ${i + 1}',
        }, playerLocation));
      }
    }
    
    // Perform clustering
    final clusterResult = ClusteringService.clusterPoints(
      points: allPoints,
      zoom: zoom,
      minPointsForCluster: 2,
    );
    
    // Add cluster markers
    for (final cluster in clusterResult.clusters) {
      markers.add(
        Marker(
          point: cluster.center,
          width: 80,
          height: 80,
          child: ClusterMarker(
            cluster: cluster,
            isActive: false,
            onTap: () => _handleClusterTap(cluster, context),
          ),
        ),
      );
    }
    
    // Add individual point markers
    for (final point in clusterResult.singlePoints) {
      markers.add(_buildIndividualMarker(
        point: point,
        context: context,
        onGoalkeeperTap: onGoalkeeperTap,
      ));
    }
    
    // Add user location marker if available (always shown individually)
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
                  color: Colors.red.withValues(alpha: 0.3),
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
  
  // Build individual marker for a cluster point
  Marker _buildIndividualMarker({
    required ClusterPoint point,
    BuildContext? context,
    Function(dynamic)? onGoalkeeperTap,
  }) {
    switch (point.type) {
      case ClusterPointType.field:
        final field = point.data['field'] as MapField;
        return Marker(
          point: point.location,
          width: 50,
          height: 50,
          child: GestureDetector(
            onTap: () => selectField(field),
            child: WebSvgAsset(
              assetPath: 'assets/icons8-football-field.svg',
              width: 50,
              height: 50,
              colorFilter: const ColorFilter.mode(
                Colors.black,
                BlendMode.srcIn,
              ),
              placeholder: Container(
                width: 50,
                height: 50,
                decoration: const BoxDecoration(
                  color: Colors.black,
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
        );
        
      case ClusterPointType.goalkeeper:
        final goalkeeper = point.data['goalkeeper'] as RealGoalkeeper;
        return Marker(
          point: point.location,
          width: 40,
          height: 40,
          child: GestureDetector(
            onTap: () {
              if (onGoalkeeperTap != null) {
                final goalkeeperData = {
                  'id': goalkeeper.id,
                  'name': goalkeeper.name,
                  'location': goalkeeper.displayLocation,
                  'price': goalkeeper.displayPrice,
                  'experience': goalkeeper.displayExperienceLevel,
                  'rating': goalkeeper.displayOverallRating,
                  'club': goalkeeper.displayClub,
                  'nationality': goalkeeper.displayNationality,
                  'age': goalkeeper.displayAge,
                  'verified': goalkeeper.isVerified,
                  'status': goalkeeper.status,
                };
                onGoalkeeperTap(goalkeeperData);
              } else if (context != null) {
                handleGoalkeeperTap(context);
              }
            },
            child: WebSvgAsset(
              assetPath: 'assets/icons8-goalkeeper-o-mais-baddy.svg',
              width: 40,
              height: 40,
              colorFilter: const ColorFilter.mode(
                Colors.black,
                BlendMode.srcIn,
              ),
              placeholder: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Colors.black,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.sports_handball,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ),
        );
        
      case ClusterPointType.player:
        return Marker(
          point: point.location,
          width: 30,
          height: 30,
          child: WebSvgAsset(
            assetPath: 'assets/icons8-football.svg',
            width: 30,
            height: 30,
            colorFilter: const ColorFilter.mode(
              Colors.black,
              BlendMode.srcIn,
            ),
            placeholder: Container(
              width: 30,
              height: 30,
              decoration: const BoxDecoration(
                color: Colors.black,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.sports_soccer,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        );
    }
  }
  
  // Handle cluster tap - could expand cluster or show details
  void _handleClusterTap(Cluster cluster, BuildContext? context) {
    if (context == null || _mapController == null) return;
    
    // Move to cluster center and zoom in
    _mapController!.move(cluster.center, 15.0);
    
    // Show cluster details in a bottom sheet
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildClusterDetailsSheet(cluster),
    );
  }
  
  // Build cluster details bottom sheet
  Widget _buildClusterDetailsSheet(Cluster cluster) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE0E0E0),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Color(cluster.representativePoint.color),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.group,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Grupo de Localizações',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            cluster.displaySummary,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF757575),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Aproxime o zoom para ver os detalhes individuais',
                  style: TextStyle(
                    fontSize: 12,
                    color: const Color(0xFF757575),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Center map on user location
  void centerOnUser() {
    if (_userLocation != null) {
      _moveMapToLocation(_userLocation!.latitude, _userLocation!.longitude);
    }
  }

  // Handle goalkeeper marker tap
  void handleGoalkeeperTap(BuildContext context) {
    // Check if user is in guest mode
    if (GuestModeUtils.isGuest) {
      // Show registration prompt for hiring goalkeeper
      RegistrationPromptHelper.showHireGoalkeeperPrompt(context);
    } else {
      // Handle authenticated user hiring flow
      // TODO: Implement goalkeeper hiring flow for authenticated users
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Goalkeeper hiring functionality coming soon!'),
        ),
      );
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

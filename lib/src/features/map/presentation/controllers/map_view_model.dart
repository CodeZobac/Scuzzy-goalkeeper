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
import '../../../../core/navigation/navigation_service.dart';

class MapViewModel extends ChangeNotifier {
  final FieldRepository _fieldRepository;
  final FieldSelectionProvider _fieldSelectionProvider;
  final RealDataService _realDataService = RealDataService();
  MapController? _mapController;

  List<MapField> _fields = [];
  List<MapField> _filteredFields = [];
  List<RealGoalkeeper> _goalkeepers = [];
  List<RealGoalkeeper> _filteredGoalkeepers = [];
  List<RealGoalkeeper> _players = [];
  List<RealGoalkeeper> _filteredPlayers = [];
  Position? _userLocation;
  bool _isLoading = false;
  String? _error;
  
  // Filter properties
  List<String> _selectedSurfaces = [];
  List<String> _selectedSizes = [];
  double _maxDistance = 50.0; // km
  Set<String> _selectedMarkerTypes = {'Fields', 'Goalkeepers', 'Players'};
  
  // Additional filter properties for compatibility
  String? _selectedCity;
  String? _selectedAvailability;
  List<String> _availableCities = [];
  List<String> _availableSurfaces = [];
  List<String> _availableSizes = [];
  
  MapViewModel(this._fieldRepository, this._fieldSelectionProvider);

  // Getters
  List<MapField> get fields => _filteredFields;
  List<RealGoalkeeper> get goalkeepers => _filteredGoalkeepers;
  List<RealGoalkeeper> get players => _filteredPlayers;
  Position? get userLocation => _userLocation;
  bool get isLoading => _isLoading;
  String? get error => _error;
  MapController? get mapController => _mapController;
  List<String> get selectedSurfaces => _selectedSurfaces;
  List<String> get selectedSizes => _selectedSizes;
  double get maxDistance => _maxDistance;
  Set<String> get selectedMarkerTypes => _selectedMarkerTypes;
  String? get selectedCity => _selectedCity;
  String? get selectedAvailability => _selectedAvailability;
  List<String> get availableCities => _availableCities;
  List<String> get availableSurfaces => _availableSurfaces;
  List<String> get availableSizes => _availableSizes;

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
        _loadPlayers(),
      ]);
      await _getCurrentLocation(); // Ensure location is fetched before applying filters
      _applyFilters();

      // Center map on user location if available
      if (_userLocation != null) {
        centerOnUser();
      }
    } catch (e) {
      _setError('Failed to initialize map: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Load fields from repository
  Future<void> _loadFields() async {
    try {
      // First, run the test to see what's in the database
      await _realDataService.testFieldsFetch();
      
      // Try to load real fields from Supabase
      var realFields = await _realDataService.getApprovedFields();
      
      // If no fields found, insert a test field
      if (realFields.isEmpty) {
        print('⚠️ No fields found, inserting test field...');
        await _realDataService.insertTestField();
        
        // Try to fetch again
        realFields = await _realDataService.getApprovedFields();
        print('🔄 After test insert, found ${realFields.length} fields');
      }
      
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
      
      // If no fields found, log it.
      if (_fields.isEmpty) {
        debugPrint('No fields were found in database');
      }
    } catch (e) {
      _setError('Failed to load fields: $e');
      _fields = [];
    }
  }

  // Load goalkeepers from database
  Future<void> _loadGoalkeepers() async {
    try {
      if (_userLocation != null) {
        _goalkeepers = await _realDataService.getGoalkeepersNearLocation(
          latitude: _userLocation!.latitude,
          longitude: _userLocation!.longitude,
          radiusKm: _maxDistance,
        );
      } else {
        _goalkeepers = await _realDataService.getGoalkeepers();
      }
      debugPrint('Loaded ${_goalkeepers.length} real goalkeepers from database');
    } catch (e) {
      debugPrint('Failed to load goalkeepers: $e');
      _goalkeepers = [];
    }
  }

  // Load players from database
  Future<void> _loadPlayers() async {
    try {
      _players = await _realDataService.getPlayers();
      debugPrint('Loaded ${_players.length} real players from database');
    } catch (e) {
      debugPrint('Failed to load players: $e');
      _players = [];
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
    
    // Filter players
    _filteredPlayers = _players.where((player) {
      // City filter
      if (_selectedCity != null && 
          (player.city == null || player.city != _selectedCity)) {
        return false;
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
    
    // Update available surfaces from fields
    final fieldSurfaces = _fields
        .where((field) => field.surfaceType != null && field.surfaceType!.isNotEmpty)
        .map((field) => field.surfaceType!)
        .toSet();
    
    _availableSurfaces = fieldSurfaces.toList();
    _availableSurfaces.sort();
    
    // Update available sizes from fields
    final fieldSizes = _fields
        .where((field) => field.dimensions != null && field.dimensions!.isNotEmpty)
        .map((field) => field.dimensions!)
        .toSet();
    
    _availableSizes = fieldSizes.toList();
    _availableSizes.sort();
    
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

  // Update marker type filter
  void updateMarkerTypeFilter(Set<String> markerTypes) {
    _selectedMarkerTypes = markerTypes;
    _applyFilters();
  }
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
    _selectedMarkerTypes = {'Fields', 'Goalkeepers', 'Players'}; // Reset marker types
    _applyFilters();
  }

  // Additional filter methods for compatibility
  void filterByCity(String? city) {
    _selectedCity = city;
    _applyFilters();
    
    // Navigate to the selected city if it has data
    if (city != null) {
      _navigateToCity(city);
    }
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
    if (_selectedMarkerTypes.contains('Fields')) {
      for (final field in _filteredFields) {
        allPoints.add(ClusterPoint.fromField(field));
      }
    }
    
    // Add goalkeeper points
    if (_selectedMarkerTypes.contains('Goalkeepers')) {
      for (final goalkeeper in _filteredGoalkeepers) {
        if (goalkeeper.latitude != null && goalkeeper.longitude != null) {
          allPoints.add(ClusterPoint.fromGoalkeeper(
              goalkeeper, LatLng(goalkeeper.latitude!, goalkeeper.longitude!)));
        }
      }
    }
    
    // Add player points
    if (_selectedMarkerTypes.contains('Players')) {
      for (final player in _filteredPlayers) {
        if (player.latitude != null && player.longitude != null) {
          allPoints.add(ClusterPoint.fromPlayer(
              player.toJson(), LatLng(player.latitude!, player.longitude!)));
        }
      }
    }
    
    // Use the nearest zoom breakpoint for stable clustering
    final effectiveZoom = _findNearestZoomBreakpoint(zoom);
    
    // Perform clustering with enhanced parameters
    final clusterResult = ClusteringService.clusterPoints(
      points: allPoints,
      zoom: effectiveZoom,
      minPointsForCluster: effectiveZoom <= 10.0 ? 3 : 2,
    );
    
    // Add enhanced cluster markers
    for (final cluster in clusterResult.clusters) {
      markers.add(
        Marker(
          point: cluster.center,
          width: _getClusterSize(cluster.size, effectiveZoom),
          height: _getClusterSize(cluster.size, effectiveZoom),
          child: GestureDetector(
            onTap: () => _handleClusterTap(cluster, context),
            child: _buildEnhancedClusterMarker(cluster, effectiveZoom),
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
          width: 40,
          height: 40,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Pulsing outer ring
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFE53E3E).withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
              ),
              // Main marker
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFFF6B6B),
                      Color(0xFFE53E3E),
                    ],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                    BoxShadow(
                      color: const Color(0xFFE53E3E).withOpacity(0.4),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.person,
                  color: Colors.white,
                  size: 14,
                ),
              ),
            ],
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
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF66BB6A),
                    Color(0xFF2E7D32),
                  ],
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                  BoxShadow(
                    color: const Color(0xFF4CAF50).withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: const Icon(
                Icons.sports_soccer,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        );
        
      case ClusterPointType.goalkeeper:
        final goalkeeper = point.data['goalkeeper'] as RealGoalkeeper;
        return Marker(
          point: point.location,
          width: 44,
          height: 44,
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
            child: Stack(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFFFFB74D),
                        Color(0xFFE65100),
                      ],
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                      BoxShadow(
                        color: const Color(0xFFFF9800).withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.sports_handball,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                if (goalkeeper.isVerified)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 8,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
        
      case ClusterPointType.player:
        final player = point.data['player'] as RealGoalkeeper;
        return Marker(
          point: point.location,
          width: 40,
          height: 40,
          child: GestureDetector(
            onTap: () {
              // Handle player tap (e.g., show player profile)
              ScaffoldMessenger.of(context!).showSnackBar(
                SnackBar(
                  content: Text('Player: ${player.name}'),
                ),
              );
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF64B5F6),
                    Color(0xFF1565C0),
                  ],
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                  BoxShadow(
                    color: const Color(0xFF2196F3).withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: const Icon(
                Icons.person,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        );
    }
  }
  
  // Handle cluster tap - could expand cluster or show details
  void _handleClusterTap(Cluster cluster, BuildContext? context) {
    if (context == null || _mapController == null) return;

    final currentZoom = _mapController!.camera.zoom;
    final targetZoom = _calculateOptimalZoomForCluster(cluster, currentZoom);

    // Use a gentler zoom approach to prevent instability
    try {
      _mapController!.move(
        cluster.center,
        targetZoom,
      );
      
      // Show cluster details in a bottom sheet only if we're not zooming in significantly
      if (targetZoom - currentZoom < 2.0) {
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (context) => _buildClusterDetailsSheet(cluster),
        );
      }
    } catch (e) {
      debugPrint('Error handling cluster tap: $e');
    }
  }
  
  // Calculate optimal zoom level for expanding a cluster
  double _calculateOptimalZoomForCluster(Cluster cluster, double currentZoom) {
    // Base the target zoom on cluster size and density
    if (cluster.size <= 5) {
      return (currentZoom + 2.0).clamp(14.0, 18.0);
    } else if (cluster.size <= 15) {
      return (currentZoom + 1.5).clamp(13.0, 17.0);
    } else {
      return (currentZoom + 1.0).clamp(12.0, 16.0);
    }
  }
  
  // Handle zoom changes for smooth transitions
  double _lastZoom = 12.0;

  void onZoomChanged(double newZoom) {
    // Only update markers if the zoom level has changed significantly
    if ((newZoom - _lastZoom).abs() > 1.0) {
      _lastZoom = newZoom;
      notifyListeners();
    }
  }
  
  // Check if the view model is still mounted (useful for debouncing)
  bool get mounted => !_isDisposed;
  bool _isDisposed = false;

  static const List<double> _zoomBreakpoints = [
    1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
  ];
  
  double _findNearestZoomBreakpoint(double zoom) {
    double nearest = _zoomBreakpoints.first;
    double minDiff = (zoom - nearest).abs();
    
    for (final breakpoint in _zoomBreakpoints) {
      final diff = (zoom - breakpoint).abs();
      if (diff < minDiff) {
        minDiff = diff;
        nearest = breakpoint;
      }
    }
    
    return nearest;
  }
  
  // Build enhanced cluster details bottom sheet
  Widget _buildClusterDetailsSheet(Cluster cluster) {
    final typeBreakdown = cluster.typeBreakdown;
    final dominantType = cluster.dominantType;
    
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, -5),
            spreadRadius: 2,
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
          
          // Header with gradient background
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(cluster.representativePoint.color),
                  Color(cluster.representativePoint.color).withOpacity(0.8),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        Icons.group_work,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${cluster.size} Localizações',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            cluster.displaySummary,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.9),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Content
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Type breakdown
                const Text(
                  'Composição do Grupo',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C2C2C),
                  ),
                ),
                const SizedBox(height: 16),
                
                ...typeBreakdown.entries.map((entry) {
                  final type = entry.key;
                  final count = entry.value;
                  final percentage = (count / cluster.size * 100).round();
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFE9ECEF),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Color(ClusterPoint(
                              id: 'temp',
                              location: cluster.center,
                              type: type,
                              data: {},
                            ).color),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _getTypeIconForType(type),
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                count == 1 ? type.displayName : type.pluralDisplayName,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF2C2C2C),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '$count item${count != 1 ? 's' : ''} ($percentage%)',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF757575),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                
                const SizedBox(height: 16),
                
                // Action hint
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF4CAF50).withOpacity(0.1),
                        const Color(0xFF4CAF50).withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF4CAF50).withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.zoom_in,
                        color: Color(0xFF4CAF50),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Aproxime para ver detalhes',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF4CAF50),
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Faça zoom para expandir este grupo e ver cada localização individualmente',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF757575),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  // Helper method to get icon for cluster point type
  IconData _getTypeIconForType(ClusterPointType type) {
    switch (type) {
      case ClusterPointType.field:
        return Icons.sports_soccer;
      case ClusterPointType.goalkeeper:
        return Icons.sports_handball;
      case ClusterPointType.player:
        return Icons.person;
    }
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

  // Navigate to a specific city
  void _navigateToCity(String cityName) {
    // Find a field or goalkeeper in the selected city
    LatLng? cityLocation;
    
    // First try to find from filtered fields
    final matchingFields = _fields.where((field) => field.city == cityName);
    final cityField = matchingFields.isNotEmpty ? matchingFields.first : null;
    if (cityField != null) {
      cityLocation = LatLng(cityField.latitude, cityField.longitude);
    } else {
      // Then try to find from goalkeepers
      final matchingGoalkeepers = _goalkeepers.where((gk) => gk.city == cityName);
      final cityGoalkeeper = matchingGoalkeepers.isNotEmpty ? matchingGoalkeepers.first : null;
      if (cityGoalkeeper != null) {
        // Generate a location near a field or use default for the city
        if (_fields.isNotEmpty) {
          final randomField = _fields[Random().nextInt(_fields.length)];
          cityLocation = _generateRandomLocation(
            randomField.latitude,
            randomField.longitude,
            2.0, // 2km radius
          );
        }
      }
    }
    
    // If we found a location, navigate to it
    if (cityLocation != null) {
      _moveMapToLocation(cityLocation.latitude, cityLocation.longitude);
    } else {
      // Default locations for major Portuguese cities
      final cityCoordinates = {
        'Lisboa': LatLng(38.7223, -9.1393),
        'Porto': LatLng(41.1579, -8.6291),
        'Braga': LatLng(41.5518, -8.4229),
        'Coimbra': LatLng(40.2033, -8.4103),
        'Aveiro': LatLng(40.6405, -8.6538),
        'Faro': LatLng(37.0194, -7.9322),
        'Setúbal': LatLng(38.5244, -8.8882),
        'Évora': LatLng(38.5664, -7.9065),
        'Viseu': LatLng(40.6566, -7.9122),
        'Leiria': LatLng(39.7437, -8.8071),
        'Amadora': LatLng(38.7536, -9.2302),
        'Cascais': LatLng(38.6973, -9.4214),
        'Oeiras': LatLng(38.6872, -9.3097),
        'Sintra': LatLng(38.7930, -9.3936),
      };
      
      final defaultLocation = cityCoordinates[cityName];
      if (defaultLocation != null) {
        _moveMapToLocation(defaultLocation.latitude, defaultLocation.longitude);
      }
    }
  }

  LatLng _generateRandomLocation(double latitude, double longitude, double radiusKm) {
    final random = Random();
    
    // Convert radius from kilometers to degrees
    const double kmInDegree = 111.32;
    double radiusInDegrees = radiusKm / kmInDegree;

    // Get random angle and distance
    double u = random.nextDouble();
    double v = random.nextDouble();
    double w = radiusInDegrees * sqrt(u);
    double t = 2 * pi * v;
    
    // Calculate new coordinates
    double x = w * cos(t);
    double y = w * sin(t);

    // Adjust for Earth's curvature
    double newLongitude = y / cos(latitude);

    return LatLng(latitude + x, longitude + newLongitude);
  }

  // Get cluster size based on cluster size and zoom level
  double _getClusterSize(int clusterSize, double zoom) {
    double baseSize = 50.0;
    
    // Adjust size based on cluster count
    if (clusterSize <= 3) {
      baseSize = 46.0;
    } else if (clusterSize <= 8) {
      baseSize = 54.0;
    } else if (clusterSize <= 15) {
      baseSize = 62.0;
    } else if (clusterSize <= 25) {
      baseSize = 70.0;
    } else {
      baseSize = 78.0;
    }
    
    // Adjust size based on zoom level for better visibility
    if (zoom <= 10) {
      baseSize *= 1.1;
    } else if (zoom >= 16) {
      baseSize *= 0.9;
    }
    
    return baseSize;
  }
  
  // Build enhanced cluster marker with modern styling
  Widget _buildEnhancedClusterMarker(Cluster cluster, double zoom) {
    final size = _getClusterSize(cluster.size, zoom);
    final dominantType = cluster.dominantType;
    final typeBreakdown = cluster.typeBreakdown;
    
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: _getClusterGradient(dominantType),
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white,
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
            spreadRadius: 2,
          ),
          BoxShadow(
            color: Color(ClusterPoint(
              id: 'temp',
              location: cluster.center,
              type: dominantType,
              data: {},
            ).color).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Subtle inner glow
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  Colors.white.withOpacity(0.3),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.7],
              ),
              shape: BoxShape.circle,
            ),
          ),
          
          // Count text with better typography
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  cluster.size.toString(),
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: _getClusterTextSize(size),
                    letterSpacing: -0.5,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.4),
                        offset: const Offset(0, 1),
                        blurRadius: 3,
                      ),
                    ],
                  ),
                ),
                if (size >= 56) // Show type indicator for larger clusters
                  Text(
                    _getTypeLabel(dominantType),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w600,
                      fontSize: 8,
                      letterSpacing: 0.5,
                    ),
                  ),
              ],
            ),
          ),
          
          // Multi-type indicator (colored dots for mixed clusters)
          if (typeBreakdown.length > 1)
            Positioned(
              top: 6,
              right: 6,
              child: _buildTypeIndicators(typeBreakdown, size),
            ),
          
          // Dominant type icon for single-type clusters
          if (typeBreakdown.length == 1)
            Positioned(
              top: 6,
              right: 6,
              child: Container(
                width: size * 0.25,
                height: size * 0.25,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Icon(
                  _getTypeIconForType(dominantType),
                  size: size * 0.15,
                  color: Color(ClusterPoint(
                    id: 'temp',
                    location: cluster.center,
                    type: dominantType,
                    data: {},
                  ).color),
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  // Get gradient for cluster based on dominant type
  LinearGradient _getClusterGradient(ClusterPointType type) {
    switch (type) {
      case ClusterPointType.field:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF66BB6A),
            Color(0xFF2E7D32),
            Color(0xFF1B5E20),
          ],
          stops: [0.0, 0.6, 1.0],
        );
      case ClusterPointType.goalkeeper:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFB74D),
            Color(0xFFE65100),
            Color(0xFFBF360C),
          ],
          stops: [0.0, 0.6, 1.0],
        );
      case ClusterPointType.player:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF64B5F6),
            Color(0xFF1565C0),
            Color(0xFF0D47A1),
          ],
          stops: [0.0, 0.6, 1.0],
        );
    }
  }
  
  // Get text size for cluster count
  double _getClusterTextSize(double containerSize) {
    if (containerSize <= 46) return 16;
    if (containerSize <= 54) return 18;
    if (containerSize <= 62) return 20;
    if (containerSize <= 70) return 22;
    return 24;
  }
  
  // Get type label for display
  String _getTypeLabel(ClusterPointType type) {
    switch (type) {
      case ClusterPointType.field:
        return 'CAMPOS';
      case ClusterPointType.goalkeeper:
        return 'GR';
      case ClusterPointType.player:
        return 'JOGADORES';
    }
  }
  
  // Build type indicators for mixed clusters
  Widget _buildTypeIndicators(Map<ClusterPointType, int> typeBreakdown, double size) {
    final types = typeBreakdown.keys.toList();
    final indicatorSize = (size * 0.15).clamp(6.0, 12.0);
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: types.take(3).map((type) {
        return Container(
          width: indicatorSize,
          height: indicatorSize,
          margin: const EdgeInsets.only(bottom: 2),
          decoration: BoxDecoration(
            color: Color(ClusterPoint(
              id: 'temp',
              location: const LatLng(0, 0),
              type: type,
              data: {},
            ).color),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
  
  // Get list of active filters for display
  List<String> get activeFilters {
    final List<String> filters = [];
    
    if (_selectedCity != null) {
      filters.add(_selectedCity!);
    }
    
    if (_selectedAvailability != null) {
      filters.add(_selectedAvailability!);
    }
    
    if (_selectedSurfaces.isNotEmpty) {
      filters.add('${_selectedSurfaces.length} tipo${_selectedSurfaces.length != 1 ? 's' : ''} de relva');
    }
    
    if (_selectedSizes.isNotEmpty) {
      filters.add('${_selectedSizes.length} tamanho${_selectedSizes.length != 1 ? 's' : ''}');
    }
    
    if (_maxDistance < 50.0) {
      filters.add('${_maxDistance.toInt()}km de raio');
    }
    
    final disabledTypes = {'Players', 'Fields', 'Goalkeepers'}.difference(_selectedMarkerTypes);
    if (disabledTypes.isNotEmpty) {
      filters.add('${disabledTypes.length} tipo${disabledTypes.length != 1 ? 's' : ''} oculto${disabledTypes.length != 1 ? 's' : ''}');
    }
    
    return filters;
  }

  // Remove a specific filter
  void removeFilter(String filter) {
    if (filter == _selectedCity) {
      _selectedCity = null;
    } else if (filter == _selectedAvailability) {
      _selectedAvailability = null;
    } else if (filter.contains('tipo') && filter.contains('relva')) {
      _selectedSurfaces.clear();
    } else if (filter.contains('tamanho')) {
      _selectedSizes.clear();
    } else if (filter.contains('km de raio')) {
      _maxDistance = 50.0;
    } else if (filter.contains('tipo') && filter.contains('oculto')) {
      _selectedMarkerTypes = {'Players', 'Fields', 'Goalkeepers'};
    }
    _applyFilters();
  }
  
  // Check if any filters are active
  bool get hasActiveFilters {
    return _selectedCity != null ||
           _selectedAvailability != null ||
           _selectedSurfaces.isNotEmpty ||
           _selectedSizes.isNotEmpty ||
           _maxDistance < 50.0 ||
           _selectedMarkerTypes.length < 3;
  }

  @override
  void dispose() {
    _isDisposed = true;
    // Don't dispose the map controller since it's managed by the map screen
    super.dispose();
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong2/latlong.dart';
import '../../domain/models/map_field.dart';
import '../../data/repositories/field_repository.dart';
import '../widgets/field_marker.dart';
import '../widgets/cluster_marker.dart';
import '../widgets/user_marker.dart';

enum MapLoadingState {
  idle,
  loading,
  loaded,
  error,
}

class MapController extends ChangeNotifier {
  final FieldRepository _fieldRepository = FieldRepository();
  fm.MapController? _mapController;
  List<MapField> _fields = [];
  bool _isAddingField = false;
  String? _fieldName;
  String? _fieldDescription;
  String? _selectedSurfaceType;
  double? _selectedLatitude;
  double? _selectedLongitude;
  String? _selectedFieldId;
  
  // Mock user location (in a real app, you'd get this from location services)
  LatLng? _userLocation;
  
  // Text controllers for form
  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController photoUrlController = TextEditingController();
  final TextEditingController dimensionsController = TextEditingController();

  // Loading state enum
  MapLoadingState _loadingState = MapLoadingState.idle;

  // Getters
  fm.MapController? get mapController => _mapController;
  List<MapField> get fields => _fields;
  bool get isAddingField => _isAddingField;
  String? get fieldName => _fieldName;
  String? get fieldDescription => _fieldDescription;
  String? get selectedSurfaceType => _selectedSurfaceType;
  double? get selectedLatitude => _selectedLatitude;
  double? get selectedLongitude => _selectedLongitude;
  String? get selectedFieldId => _selectedFieldId;
  MapLoadingState get loadingState => _loadingState;
  bool get canSubmitField => nameController.text.isNotEmpty && _selectedLatitude != null && _selectedLongitude != null;
  LatLng? get userLocation => _userLocation;

  void setMapController(fm.MapController controller) {
    _mapController = controller;
  }

  // Initialize method for compatibility
  Future<void> initialize() async {
    await loadFields();
  }

  // Load fields from repository
  Future<void> loadFields() async {
    try {
      _loadingState = MapLoadingState.loading;
      notifyListeners();
      
      _fields = await _fieldRepository.getApprovedFields();
      
      _loadingState = MapLoadingState.loaded;
      notifyListeners();
    } catch (e) {
      _loadingState = MapLoadingState.error;
      notifyListeners();
      print('Error loading fields: $e');
    }
  }

  // Markers for the map with clustering
  List<fm.Marker> get markers {
    final List<fm.Marker> fieldMarkers = _fields.map((field) {
      return fm.Marker(
        width: 28.0,
        height: 28.0,
        point: LatLng(field.latitude, field.longitude),
        child: FieldMarker(
          isSelected: field.id == _selectedFieldId,
          onTap: () {
            _selectedFieldId = field.id;
            onFieldTapped?.call(field);
            notifyListeners();
          },
        ),
      );
    }).toList();

    // Add user marker if location is available
    if (_userLocation != null) {
      fieldMarkers.add(
        fm.Marker(
          width: 32.0,
          height: 32.0,
          point: _userLocation!,
          child: const UserMarker(),
        ),
      );
    }

    return fieldMarkers;
  }

  // Cluster marker builder
  Widget buildClusterMarker(BuildContext context, List<fm.Marker> markers) {
    return ClusterMarker(
      count: markers.length,
      onTap: () {
        // Optional: Handle cluster tap to zoom in
        if (_mapController != null && markers.isNotEmpty) {
          final bounds = _calculateBounds(markers);
          _mapController!.fitBounds(bounds);
        }
      },
    );
  }

  // Calculate bounds for markers
  fm.LatLngBounds _calculateBounds(List<fm.Marker> markers) {
    double minLat = double.infinity;
    double maxLat = -double.infinity;
    double minLng = double.infinity;
    double maxLng = -double.infinity;

    for (final marker in markers) {
      final point = marker.point;
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    return fm.LatLngBounds(
      LatLng(minLat, minLng),
      LatLng(maxLat, maxLng),
    );
  }

  // Toggle field adding mode
  void toggleAddingField() {
    _isAddingField = !_isAddingField;
    if (!_isAddingField) {
      _clearForm();
    }
    notifyListeners();
  }

  // Handle map tap for adding field
  void onMapTap(LatLng point) {
    if (!_isAddingField) return;

    _selectedLatitude = point.latitude;
    _selectedLongitude = point.longitude;
    notifyListeners();
  }

  // Submit field suggestion
  Future<void> submitFieldSuggestion() async {
    if (!canSubmitField) return;

    try {
      _loadingState = MapLoadingState.loading;
      notifyListeners();

      await _fieldRepository.suggestField(
        name: nameController.text.trim(),
        latitude: _selectedLatitude!,
        longitude: _selectedLongitude!,
        photoUrl: photoUrlController.text.trim().isEmpty 
            ? null 
            : photoUrlController.text.trim(),
        description: descriptionController.text.trim().isEmpty 
            ? null 
            : descriptionController.text.trim(),
        surfaceType: _selectedSurfaceType,
        dimensions: dimensionsController.text.trim().isEmpty 
            ? null 
            : dimensionsController.text.trim(),
      );

      _isAddingField = false;
      _loadingState = MapLoadingState.loaded;
      _clearForm();
      // Optionally reload fields to show pending ones if you want
      
    } catch (e) {
      _loadingState = MapLoadingState.error;
      print('Error submitting field suggestion: $e');
    } finally {
      notifyListeners();
    }
  }

  // Clear form data
  void _clearForm() {
    nameController.clear();
    photoUrlController.clear();
    descriptionController.clear();
    dimensionsController.clear();
    _selectedLatitude = null;
    _selectedLongitude = null;
    _selectedSurfaceType = 'natural';
  }

  // Set surface type
  void setSurfaceType(String surfaceType) {
    _selectedSurfaceType = surfaceType;
    notifyListeners();
  }

  // Refresh method for UI
  Future<void> refresh() async {
    await loadFields();
  }

  // Move camera to user location
  void moveToUserLocation() {
    if (_mapController == null) return;

    if (_userLocation != null) {
      _mapController!.move(LatLng(_userLocation!.latitude, _userLocation!.longitude), 15.0);
    } else {
      // Default to a sample location (you can integrate location services here)
      _mapController!.move(LatLng(40.7128, -74.0060), 12.0);
    }
  }

  // Move camera to specific location
  void moveToLocation(double latitude, double longitude) {
    if (_mapController == null) return;

    _mapController!.move(LatLng(latitude, longitude), 15.0);
  }

  // Search fields by name
  List<MapField> searchFields(String query) {
    if (query.isEmpty) return _fields;
    
    return _fields.where((field) {
      final nameMatch = field.name.toLowerCase().contains(query.toLowerCase());
      final descriptionMatch = field.description?.toLowerCase().contains(query.toLowerCase()) ?? false;
      return nameMatch || descriptionMatch;
    }).toList();
  }

  // Search fields via repository (server-side search)
  Future<void> searchFieldsRemote(String query) async {
    try {
      _loadingState = MapLoadingState.loading;
      notifyListeners();

      _fields = await _fieldRepository.searchFields(query);
      
      _loadingState = MapLoadingState.loaded;
    } catch (e) {
      _loadingState = MapLoadingState.error;
      print('Error searching fields: $e');
    } finally {
      notifyListeners();
    }
  }

  // Get fields near user location
  Future<void> getFieldsNearLocation() async {
    // For now using default location, you would get actual user location here
    try {
      _loadingState = MapLoadingState.loading;
      notifyListeners();

      _fields = await _fieldRepository.getFieldsNearLocation(
        latitude: 40.7128, // Default to New York, replace with actual user location
        longitude: -74.0060,
        radiusInMeters: 5000, // 5km radius
      );
      
      _loadingState = MapLoadingState.loaded;
    } catch (e) {
      _loadingState = MapLoadingState.error;
      print('Error getting nearby fields: $e');
    } finally {
      notifyListeners();
    }
  }

  // Get field by ID
  MapField? getFieldById(String id) {
    try {
      return _fields.firstWhere((field) => field.id == id);
    } catch (e) {
      return null;
    }
  }

  // Update field name for adding
  void updateFieldName(String name) {
    _fieldName = name;
  }

  // Update field description for adding
  void updateFieldDescription(String description) {
    _fieldDescription = description;
  }

  // Cancel adding field
  void cancelAddingField() {
    _isAddingField = false;
    _fieldName = null;
    _fieldDescription = null;
  }

  // Handle annotation click
  void onAnnotationClick(String fieldId) {
    final field = getFieldById(fieldId);
    if (field != null) {
      _selectedFieldId = fieldId;
      onFieldTapped?.call(field);
      notifyListeners();
    }
  }

  // Clear selected field
  void clearSelectedField() {
    _selectedFieldId = null;
    notifyListeners();
  }

  // Callback for field tapped - can be set from UI
  Function(MapField)? onFieldTapped;

  // Dispose resources
  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    photoUrlController.dispose();
    dimensionsController.dispose();
    _fields.clear();
    super.dispose();
  }
}

import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import '../../domain/models/map_field.dart';
import '../../data/repositories/field_repository.dart';

enum MapLoadingState {
  idle,
  loading,
  loaded,
  error,
}

class MapController extends ChangeNotifier {
  final FieldRepository _fieldRepository = FieldRepository();
  MapboxMap? _mapboxMap;
  List<MapField> _fields = [];
  bool _isAddingField = false;
  String? _fieldName;
  String? _fieldDescription;
  String? _selectedSurfaceType;
  double? _selectedLatitude;
  double? _selectedLongitude;
  
  // Mock user location (in a real app, you'd get this from location services)
  Position? _userLocation;
  
  // Text controllers for form
  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController photoUrlController = TextEditingController();
  final TextEditingController dimensionsController = TextEditingController();

  // Loading state enum
  MapLoadingState _loadingState = MapLoadingState.idle;

  // Getters
  List<MapField> get fields => _fields;
  bool get isAddingField => _isAddingField;
  String? get fieldName => _fieldName;
  String? get fieldDescription => _fieldDescription;
  String? get selectedSurfaceType => _selectedSurfaceType;
  double? get selectedLatitude => _selectedLatitude;
  double? get selectedLongitude => _selectedLongitude;
  MapLoadingState get loadingState => _loadingState;
  bool get canSubmitField => nameController.text.isNotEmpty && _selectedLatitude != null && _selectedLongitude != null;
  Position? get userLocation => _userLocation;

  // Initialize map
  void onMapCreated(MapboxMap mapboxMap) {
    _mapboxMap = mapboxMap;
    loadFields();
  }

  // Set mapbox map (alternative method for initialization)
  Future<void> setMapboxMap(MapboxMap mapboxMap) async {
    _mapboxMap = mapboxMap;
    await loadFields();
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
      await _createAnnotations();
      
      _loadingState = MapLoadingState.loaded;
      notifyListeners();
    } catch (e) {
      _loadingState = MapLoadingState.error;
      notifyListeners();
      print('Error loading fields: $e');
    }
  }

  // Create annotations on map
  Future<void> _createAnnotations() async {
    if (_mapboxMap == null) return;

    final pointAnnotationManager = await _mapboxMap!.annotations.createPointAnnotationManager();
    
    final options = _fields
        .map((field) => PointAnnotationOptions(
              geometry: Point(coordinates: Position(field.longitude, field.latitude)),
              textField: field.name,
              iconImage: 'marker-15',
            ))
        .toList();

    if (options.isNotEmpty) {
      await pointAnnotationManager.createMulti(options);
    }

    // Set up click listener
    pointAnnotationManager.addOnPointAnnotationClickListener(_AnnotationClickListener(this));
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
  Future<void> onMapTap(Point point) async {
    if (!_isAddingField) return;

    _selectedLatitude = point.coordinates.lat.toDouble();
    _selectedLongitude = point.coordinates.lng.toDouble();
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
  Future<void> moveToUserLocation() async {
    if (_mapboxMap == null) return;

    // If we have user location, use it, otherwise use default
    if (_userLocation != null) {
      final cameraOptions = CameraOptions(
        center: Point(coordinates: Position(_userLocation!.lng, _userLocation!.lat)),
        zoom: 15.0,
      );
      await _mapboxMap!.easeTo(cameraOptions, MapAnimationOptions(duration: 1000));
    } else {
      // Default to a sample location (you can integrate location services here)
      final cameraOptions = CameraOptions(
        center: Point(coordinates: Position(-74.0060, 40.7128)), // New York
        zoom: 12.0,
      );
      await _mapboxMap!.easeTo(cameraOptions, MapAnimationOptions(duration: 1000));
    }
  }

  // Move camera to specific location
  Future<void> moveToLocation(double latitude, double longitude) async {
    if (_mapboxMap == null) return;

    final cameraOptions = CameraOptions(
      center: Point(coordinates: Position(longitude, latitude)),
      zoom: 15.0,
    );

    await _mapboxMap!.easeTo(cameraOptions, MapAnimationOptions(duration: 1000));
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
      await _createAnnotations();
      
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
      await _createAnnotations();
      
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
      // You can emit an event or call a callback here
      print('Field clicked: ${field.name}');
    }
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
    _mapboxMap = null;
    _fields.clear();
    super.dispose();
  }
}

// Annotation click listener class
class _AnnotationClickListener extends OnPointAnnotationClickListener {
  final MapController _controller;

  _AnnotationClickListener(this._controller);

  @override
  void onPointAnnotationClick(PointAnnotation annotation) {
    _controller.onAnnotationClick(annotation.id);
  }
}

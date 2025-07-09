import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import 'package:permission_handler/permission_handler.dart';
import '../../data/repositories/field_repository.dart';
import '../../domain/models/map_field.dart';

enum MapLoadingState { loading, loaded, error }

class MapController extends ChangeNotifier {
  final FieldRepository _fieldRepository;
  
  // State variables
  MapLoadingState _loadingState = MapLoadingState.loading;
  String? _errorMessage;
  List<MapField> _fields = [];
  mapbox.PointAnnotationManager? _pointAnnotationManager;
  Position? _userLocation;
  mapbox.MapboxMap? _mapboxMap;
  
  // Form state for new field suggestion
  bool _isAddingField = false;
  double? _selectedLatitude;
  double? _selectedLongitude;
  final TextEditingController nameController = TextEditingController();
  final TextEditingController photoUrlController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  String _selectedSurfaceType = 'natural';
  final TextEditingController dimensionsController = TextEditingController();

  // Callback for field marker tap
  Function(MapField)? onFieldTapped;
  
  // Getters
  MapLoadingState get loadingState => _loadingState;
  String? get errorMessage => _errorMessage;
  List<MapField> get fields => _fields;
  Position? get userLocation => _userLocation;
  bool get isAddingField => _isAddingField;
  double? get selectedLatitude => _selectedLatitude;
  double? get selectedLongitude => _selectedLongitude;
  String get selectedSurfaceType => _selectedSurfaceType;
  bool get canSubmitField => 
      nameController.text.isNotEmpty && 
      _selectedLatitude != null && 
      _selectedLongitude != null;

  MapController(this._fieldRepository);

  @override
  void dispose() {
    nameController.dispose();
    photoUrlController.dispose();
    descriptionController.dispose();
    dimensionsController.dispose();
    super.dispose();
  }

  /// Initialize the map controller
  Future<void> initialize() async {
    await loadFields();
    await _requestLocationPermission();
  }

  Future<void> _requestLocationPermission() async {
    final status = await Permission.location.request();
    if (status.isGranted) {
      _userLocation = await Geolocator.getCurrentPosition();
      notifyListeners();
    }
  }

  /// Set the MapboxMap instance
  void setMapboxMap(mapbox.MapboxMap mapboxMap) {
    _mapboxMap = mapboxMap;
    _mapboxMap!.annotations.createPointAnnotationManager().then((value) {
      _pointAnnotationManager = value;
      // Set up annotation click listener
      _pointAnnotationManager!.addOnPointAnnotationClickListener(_AnnotationClickListener(this));
      // We need to create annotations after the manager is created
      _createAnnotations();
    });
  }

  void onMapTap(mapbox.Point point) {
    if (_isAddingField) {
      _selectedLatitude = point.coordinates.lat.toDouble();
      _selectedLongitude = point.coordinates.lng.toDouble();
      notifyListeners();
    }
  }

  void _handleAnnotationClick(mapbox.PointAnnotation annotation) {
    // Find the field associated with this annotation
    // Since we create annotations in the same order as fields,
    // we can use the annotation's position to find the matching field
    try {
      final annotationPosition = annotation.geometry.coordinates;
      final matchingField = _fields.firstWhere((field) {
        return (field.latitude - annotationPosition.lat).abs() < 0.00001 &&
               (field.longitude - annotationPosition.lng).abs() < 0.00001;
      });
      
      onFieldTapped?.call(matchingField);
    } catch (e) {
      // Field not found
      print('Could not find field for annotation: $e');
    }
  }

  Future<void> _createAnnotations() async {
    if (_pointAnnotationManager == null) return;

    // Clear existing annotations before adding new ones
    await _pointAnnotationManager!.deleteAll();
    
    final options = _fields
        .map((field) => mapbox.PointAnnotationOptions(
              geometry: mapbox.Point(
                coordinates: mapbox.Position(
                  field.longitude,
                  field.latitude,
                ),
              ),
              // You can customize the icon here
              // image: ..., 
            ))
        .toList();
    
    if (options.isNotEmpty) {
      await _pointAnnotationManager!.createMulti(options);
    }
  }

  Future<void> loadFields() async {
    try {
      _loadingState = MapLoadingState.loading;
      _errorMessage = null;
      notifyListeners();

      _fields = await _fieldRepository.getApprovedFields();
      await _createAnnotations();
      
      _loadingState = MapLoadingState.loaded;
    } catch (e) {
      _loadingState = MapLoadingState.error;
      _errorMessage = e.toString();
    } finally {
      notifyListeners();
    }
  }

  void toggleAddingField() {
    _isAddingField = !_isAddingField;
    if (!_isAddingField) {
      _clearFieldForm();
    }
    notifyListeners();
  }

  void moveToUserLocation() {
    if (_userLocation != null) {
      _mapboxMap?.flyTo(
        mapbox.CameraOptions(
          center: mapbox.Point(
            coordinates: mapbox.Position(
              _userLocation!.longitude,
              _userLocation!.latitude,
            ),
          ),
          zoom: 14.0,
        ),
        mapbox.MapAnimationOptions(duration: 1000),
      );
    }
  }

  /// Set surface type for new field
  void setSurfaceType(String surfaceType) {
    _selectedSurfaceType = surfaceType;
    notifyListeners();
  }

  /// Submit new field suggestion
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

      _clearFieldForm();
      _isAddingField = false;
      _loadingState = MapLoadingState.loaded;
      
      // Show success message
      // You might want to add a callback for this
      
    } catch (e) {
      _errorMessage = e.toString();
      _loadingState = MapLoadingState.error;
    } finally {
      notifyListeners();
    }
  }

  /// Clear the field suggestion form
  void _clearFieldForm() {
    nameController.clear();
    photoUrlController.clear();
    descriptionController.clear();
    dimensionsController.clear();
    _selectedLatitude = null;
    _selectedLongitude = null;
    _selectedSurfaceType = 'natural';
  }

  /// Search fields by name
  Future<void> searchFields(String query) async {
    if (query.isEmpty) {
      await loadFields();
      return;
    }

    try {
      _loadingState = MapLoadingState.loading;
      notifyListeners();

      _fields = await _fieldRepository.searchFields(query);
      await _createAnnotations();
      
      _loadingState = MapLoadingState.loaded;
    } catch (e) {
      _loadingState = MapLoadingState.error;
      _errorMessage = e.toString();
    } finally {
      notifyListeners();
    }
  }

  /// Get fields near user location
  Future<void> loadNearbyFields({double radiusInMeters = 5000}) async {
    if (_userLocation == null) return;

    try {
      _loadingState = MapLoadingState.loading;
      notifyListeners();

      _fields = await _fieldRepository.getFieldsNearLocation(
        latitude: _userLocation!.latitude,
        longitude: _userLocation!.longitude,
        radiusInMeters: radiusInMeters,
      );
      
      await _createAnnotations();
      _loadingState = MapLoadingState.loaded;
    } catch (e) {
      _loadingState = MapLoadingState.error;
      _errorMessage = e.toString();
    } finally {
      notifyListeners();
    }
  }

  /// Handle field marker tap
  void onFieldMarkerTap(MapField field) {
    // This will be handled by the UI to show field details
    // You can add a callback mechanism here if needed
  }

  /// Refresh the map data
  Future<void> refresh() async {
    await loadFields();
  }
}

class _AnnotationClickListener extends mapbox.OnPointAnnotationClickListener {
  final MapController controller;
  
  _AnnotationClickListener(this.controller);
  
  @override
  void onPointAnnotationClick(mapbox.PointAnnotation annotation) {
    controller._handleAnnotationClick(annotation);
  }
}

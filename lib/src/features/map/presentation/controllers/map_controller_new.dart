import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:latlong2/latlong.dart';
import '../../domain/models/map_field.dart';
import '../../data/repositories/field_repository.dart';

enum MapLoadingState {
  idle,
  loading,
  loaded,
  error,
}

class MapControllerNew extends ChangeNotifier {
  final FieldRepository _fieldRepository = FieldRepository();
  fm.MapController? _mapController;
  List<MapField> _fields = [];
  MapLoadingState _loadingState = MapLoadingState.idle;
  LatLng? _userLocation;
  MapField? _selectedField;

  // Getters
  fm.MapController? get mapController => _mapController;
  List<MapField> get fields => _fields;
  MapLoadingState get loadingState => _loadingState;
  LatLng? get userLocation => _userLocation;
  MapField? get selectedField => _selectedField;

  void setMapController(fm.MapController controller) {
    _mapController = controller;
  }

  Future<void> initialize() async {
    await _loadFields();
    // In a real app, you would initialize a location service to get the user's location.
    // For now, we'll use a mock location.
    _userLocation = LatLng(39.742043, -104.991531); // Mock user location in Denver
    notifyListeners();
  }

  Future<void> _loadFields() async {
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

  void onFieldSelected(MapField field) {
    _selectedField = field;
    notifyListeners();
  }

  void clearSelectedField() {
    _selectedField = null;
    notifyListeners();
  }

  void moveToUserLocation() {
    if (_mapController != null && _userLocation != null) {
      _mapController!.move(_userLocation!, 15.0);
    }
  }

  @override
  void dispose() {
    _fields.clear();
    super.dispose();
  }
}

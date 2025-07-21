import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../data/repositories/field_repository.dart';
import '../../domain/models/map_field.dart';
import '../widgets/field_marker.dart';
import '../providers/field_selection_provider.dart';

class MapViewModel extends ChangeNotifier {
  final FieldRepository _fieldRepository = FieldRepository();
  final FieldSelectionProvider _fieldSelectionProvider;

  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  final Set<Marker> _allMarkers = {};
  bool _isMapReady = false;
  LatLng? _userPosition;
  String? _mapStyle;
  List<MapField> _allFields = [];
  List<MapField> _filteredFields = [];
  String? _selectedCity;
  String? _selectedAvailability;
  List<String> _availableCities = [];
  
  MapViewModel(this._fieldSelectionProvider);

  // Getters
  Set<Marker> get markers => _markers;
  bool get isMapReady => _isMapReady;
  LatLng? get userPosition => _userPosition;
  MapField? get selectedField => _fieldSelectionProvider.selectedField;
  GoogleMapController? get mapController => _mapController;
  String? get mapStyle => _mapStyle;
  List<String> get availableCities => _availableCities;
  String? get selectedCity => _selectedCity;
  String? get selectedAvailability => _selectedAvailability;
  List<MapField> get filteredFields => _filteredFields;

  void setMapStyle(String style) {
    _mapStyle = style;
    _mapController?.setMapStyle(style);
    notifyListeners();
  }

  void onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    if (_mapStyle != null) {
      _mapController?.setMapStyle(_mapStyle);
    }
    _isMapReady = true;
    _loadFields();
    _determinePosition();
    notifyListeners();
  }

  Future<void> _loadFields() async {
    try {
      _allFields = await _fieldRepository.getApprovedFields();
      _filteredFields = _allFields;
      
      // Extract unique cities from fields
      _availableCities = _allFields
          .where((field) => field.city != null && field.city!.isNotEmpty)
          .map((field) => field.city!)
          .toSet()
          .toList();
      _availableCities.sort();
      
      await _updateMarkers();
      notifyListeners();
    } catch (e) {
      print('Error loading fields: $e');
    }
  }

  void clearSelectedField() {
    _fieldSelectionProvider.clearSelection();
  }

  // Filtering methods
  void filterByCity(String city) {
    _selectedCity = city;
    _applyFilters();
    notifyListeners();
  }

  void filterByAvailability(String availability) {
    _selectedAvailability = availability;
    _applyFilters();
    notifyListeners();
  }

  void clearCityFilter() {
    _selectedCity = null;
    _applyFilters();
    notifyListeners();
  }

  void clearAvailabilityFilter() {
    _selectedAvailability = null;
    _applyFilters();
    notifyListeners();
  }

  void clearAllFilters() {
    _selectedCity = null;
    _selectedAvailability = null;
    _applyFilters();
    notifyListeners();
  }

  void _applyFilters() {
    _filteredFields = _allFields.where((field) {
      bool cityMatch = _selectedCity == null || field.city == _selectedCity;
      bool availabilityMatch = _selectedAvailability == null || _matchesAvailability(field, _selectedAvailability!);
      return cityMatch && availabilityMatch;
    }).toList();
    _updateMarkers();
  }

  bool _matchesAvailability(MapField field, String availability) {
    // For now, we'll simulate availability matching
    // In a real implementation, this would check against actual booking data
    switch (availability) {
      case 'Disponível agora':
        return true; // Simulate that some fields are available now
      case 'Disponível hoje':
        return field.name.contains('Municipal') || field.name.contains('Complexo');
      case 'Disponível esta semana':
        return !field.name.contains('Estádio');
      case 'Sempre disponível':
        return field.name.contains('Campo');
      default:
        return true;
    }
  }

  Future<void> _updateMarkers() async {
    // Clear existing field markers (keep user location marker)
    _markers.removeWhere((marker) => marker.markerId.value != 'user_location');
    
    final customIcon = await _createStadiumMarker();
    
    final newMarkers = _filteredFields.map((field) {
      return Marker(
        markerId: MarkerId(field.id),
        position: LatLng(field.latitude, field.longitude),
        infoWindow: InfoWindow(
          title: field.name,
          snippet: field.city != null ? '${field.city} - ${field.description ?? "Campo de futebol"}' : field.description ?? 'Campo de futebol',
        ),
        icon: customIcon,
        onTap: () {
          _fieldSelectionProvider.selectField(field);
        },
      );
    }).toSet();

    _markers.addAll(newMarkers);
  }

  Future<BitmapDescriptor> _createStadiumMarker() async {
    // Create a simple but distinctive marker for football fields
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    final size = 60.0;
    
    final rect = Rect.fromLTWH(0, 0, size, size);
    final centerX = size / 2;
    final centerY = size / 2;
    
    // Create gradient paint
    final gradientPaint = Paint()
      ..shader = ui.Gradient.radial(
        Offset(centerX, centerY),
        size / 2,
        [const Color(0xFF6C5CE7), const Color(0xFF74B9FF)],
        [0.0, 1.0],
      );
    
    // Draw main circle
    canvas.drawCircle(Offset(centerX, centerY), size / 2 - 2, gradientPaint);
    
    // Draw white border
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    
    canvas.drawCircle(Offset(centerX, centerY), size / 2 - 2, borderPaint);
    
    // Draw stadium icon (simplified)
    final iconPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    
    // Draw stadium shape (rectangle with rounded corners)
    final stadiumRect = Rect.fromCenter(
      center: Offset(centerX, centerY),
      width: size * 0.5,
      height: size * 0.35,
    );
    
    canvas.drawRRect(
      RRect.fromRectAndRadius(stadiumRect, const Radius.circular(4)),
      iconPaint,
    );
    
    // Draw field lines
    final linePaint = Paint()
      ..color = const Color(0xFF6C5CE7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    
    // Center line
    canvas.drawLine(
      Offset(centerX, stadiumRect.top + 2),
      Offset(centerX, stadiumRect.bottom - 2),
      linePaint,
    );
    
    // Goal areas
    final goalWidth = stadiumRect.width * 0.3;
    final goalHeight = stadiumRect.height * 0.4;
    
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(stadiumRect.left + goalWidth / 2, centerY),
        width: goalWidth,
        height: goalHeight,
      ),
      linePaint,
    );
    
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(stadiumRect.right - goalWidth / 2, centerY),
        width: goalWidth,
        height: goalHeight,
      ),
      linePaint,
    );
    
    final picture = pictureRecorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    
    return BitmapDescriptor.fromBytes(bytes!.buffer.asUint8List());
  }

  Future<void> _determinePosition() async {
    try {
      bool serviceEnabled;
      LocationPermission permission;

      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return;
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return;
      }

      final position = await Geolocator.getCurrentPosition();
      _userPosition = LatLng(position.latitude, position.longitude);
      _markers.add(
        Marker(
          markerId: const MarkerId('user_location'),
          position: _userPosition!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: const InfoWindow(title: 'Sua Localização'),
        ),
      );
      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(_userPosition!, 15));
      notifyListeners();
    } catch (e) {
      print("Error getting user location: $e");
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}

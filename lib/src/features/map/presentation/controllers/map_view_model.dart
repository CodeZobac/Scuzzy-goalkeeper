import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../data/repositories/field_repository.dart';
import '../../domain/models/map_field.dart';

class MapViewModel extends ChangeNotifier {
  final FieldRepository _fieldRepository = FieldRepository();

  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  bool _isMapReady = false;
  LatLng? _userPosition;
  MapField? _selectedField;
  String? _mapStyle;

  // Getters
  Set<Marker> get markers => _markers;
  bool get isMapReady => _isMapReady;
  LatLng? get userPosition => _userPosition;
  MapField? get selectedField => _selectedField;
  GoogleMapController? get mapController => _mapController;
  String? get mapStyle => _mapStyle;

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
      final fields = await _fieldRepository.getApprovedFields();
      final newMarkers = fields.map((field) {
        return Marker(
          markerId: MarkerId(field.id),
          position: LatLng(field.latitude, field.longitude),
          infoWindow: InfoWindow(
            title: field.name,
            snippet: field.description ?? 'Campo de futebol',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          onTap: () {
            _selectedField = field;
            notifyListeners();
          },
        );
      }).toSet();

      _markers.addAll(newMarkers);
      notifyListeners();
    } catch (e) {
      print('Error loading fields: $e');
    }
  }

  void clearSelectedField() {
    _selectedField = null;
    notifyListeners();
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

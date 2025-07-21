import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart' as geolocator;
import 'package:geolocator_platform_interface/geolocator_platform_interface.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' hide Position;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../data/repositories/field_repository.dart';
import '../../domain/models/map_field.dart';
import '../providers/field_selection_provider.dart';

class MapViewModel extends ChangeNotifier {
  final FieldRepository _fieldRepository = FieldRepository();
  final FieldSelectionProvider _fieldSelectionProvider;

  MapboxMap? _mapboxMap;
  PointAnnotationManager? _pointAnnotationManager;
  PointAnnotation? _userLocationAnnotation;

  bool _isMapReady = false;
  geolocator.Position? _userPosition;
  List<MapField> _allFields = [];
  List<MapField> _filteredFields = [];
  String? _selectedCity;
  String? _selectedAvailability;
  List<String> _availableCities = [];

  MapViewModel(this._fieldSelectionProvider);

  // Getters
  bool get isMapReady => _isMapReady;
  geolocator.Position? get userPosition => _userPosition;
  MapField? get selectedField => _fieldSelectionProvider.selectedField;
  List<String> get availableCities => _availableCities;
  String? get selectedCity => _selectedCity;
  String? get selectedAvailability => _selectedAvailability;
  List<MapField> get filteredFields => _filteredFields;

  void setMapboxMap(MapboxMap map) {
    _mapboxMap = map;
    _isMapReady = true;
    notifyListeners();
  }

  void setPointAnnotationManager(PointAnnotationManager manager) {
    _pointAnnotationManager = manager;
    manager.onPointAnnotationClickListener.add((annotation) {
      final fieldId = annotation.textField;
      if (fieldId != null) {
        final field = _allFields.firstWhere((f) => f.id == fieldId);
        _fieldSelectionProvider.selectField(field);
        _animateToField(field);
      }
    });
  }

  void initializeMap() {
    _loadFields();
    _determinePosition();
  }

  Future<void> _loadFields() async {
    try {
      _allFields = await _fieldRepository.getApprovedFields();
      _filteredFields = _allFields;
      _availableCities = _allFields
          .map((field) => field.city)
          .where((city) => city != null && city.isNotEmpty)
          .toSet()
          .toList()
          .cast<String>();
      _availableCities.sort();
      await addMarkersToMapbox();
      notifyListeners();
    } catch (e) {
      print('Error loading fields: $e');
    }
  }

  Future<void> addMarkersToMapbox() async {
    if (_pointAnnotationManager == null || _mapboxMap == null) return;

    await _pointAnnotationManager?.deleteAll();

    final soccerIcon = await _createIconImage(FontAwesomeIcons.futbol);
    await _mapboxMap?.style.addStyleImage(
        'soccer-ball-icon',
        1.0,
        MbxImage(width: 64, height: 64, data: soccerIcon),
        false,
        [],
        [],
        null);

    final List<PointAnnotationOptions> options = [];
    for (final field in _filteredFields) {
      options.add(PointAnnotationOptions(
        geometry: Point(coordinates: Position(field.longitude, field.latitude)).toJson(),
        textField: field.id,
        iconImage: 'soccer-ball-icon',
      ));
    }
    _pointAnnotationManager?.createMulti(options);
    _updateUserLocationMarker();
  }

  void clearSelectedField() {
    _fieldSelectionProvider.clearSelection();
  }

  void filterByCity(String city) {
    _selectedCity = city;
    _applyFilters();
    animateToCity(city);
  }

  void filterByAvailability(String availability) {
    _selectedAvailability = availability;
    _applyFilters();
  }

  void clearAllFilters() {
    _selectedCity = null;
    _selectedAvailability = null;
    _applyFilters();
  }

  void _applyFilters() {
    _filteredFields = _allFields.where((field) {
      final cityMatch = _selectedCity == null || field.city == _selectedCity;
      final availabilityMatch = _selectedAvailability == null || _matchesAvailability(field, _selectedAvailability!);
      return cityMatch && availabilityMatch;
    }).toList();
    addMarkersToMapbox();
    notifyListeners();
  }

  bool _matchesAvailability(MapField field, String availability) {
    switch (availability) {
      case 'Disponível agora':
        return true;
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

  Future<void> _determinePosition() async {
    try {
      bool serviceEnabled = await geolocator.Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      geolocator.LocationPermission permission = await geolocator.Geolocator.checkPermission();
      if (permission == geolocator.LocationPermission.denied) {
        permission = await geolocator.Geolocator.requestPermission();
        if (permission == geolocator.LocationPermission.denied) return;
      }
      if (permission == geolocator.LocationPermission.deniedForever) return;

      _userPosition = await geolocator.Geolocator.getCurrentPosition();
      centerOnUserLocationWithStyle();
      _updateUserLocationMarker();
      notifyListeners();
    } catch (e) {
      print("Error getting user location: $e");
    }
  }

  Future<void> _updateUserLocationMarker() async {
    if (_mapboxMap == null || _userPosition == null || _pointAnnotationManager == null) return;

    final userIcon = await _createIconImage(FontAwesomeIcons.locationArrow, color: Colors.blue);
    await _mapboxMap?.style.addStyleImage(
        'user-location-icon',
        1.0,
        MbxImage(width: 64, height: 64, data: userIcon),
        false,
        [],
        [],
        null);

    if (_userLocationAnnotation != null) {
      _pointAnnotationManager?.delete(_userLocationAnnotation!);
    }

    _pointAnnotationManager
        ?.create(PointAnnotationOptions(
      geometry: Point(coordinates: Position(_userPosition!.longitude, _userPosition!.latitude))
          .toJson(),
      iconImage: 'user-location-icon',
    ))
        .then((annotation) => _userLocationAnnotation = annotation);
  }

  void _animateToField(MapField field) {
    _mapboxMap?.flyTo(
      CameraOptions(
        center: Point(coordinates: Position(field.longitude, field.latitude)).toJson(),
        zoom: 17.0,
        pitch: 60.0,
        bearing: -15.0,
      ),
      MapAnimationOptions(duration: 1200, startDelay: 0),
    );
  }

  void animateToCity(String cityName) {
    final cityFields = _allFields.where((field) => field.city == cityName).toList();
    if (cityFields.isNotEmpty) {
      double avgLat = cityFields.map((f) => f.latitude).reduce((a, b) => a + b) / cityFields.length;
      double avgLng = cityFields.map((f) => f.longitude).reduce((a, b) => a + b) / cityFields.length;

      _mapboxMap?.flyTo(
        CameraOptions(
          center: Point(coordinates: Position(avgLng, avgLat)).toJson(),
          zoom: 13.0,
          pitch: 45.0,
        ),
        MapAnimationOptions(duration: 1500),
      );
    }
  }

  void centerOnUserLocationWithStyle() {
    if (_userPosition != null) {
      _mapboxMap?.flyTo(
        CameraOptions(
          center: Point(coordinates: Position(_userPosition!.longitude, _userPosition!.latitude))
              .toJson(),
          zoom: 16.0,
          pitch: 50.0,
        ),
        MapAnimationOptions(duration: 1000),
      );
    }
  }

  Future<Uint8List> _createIconImage(IconData iconData, {Color color = Colors.white, double size = 48.0}) async {
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    final textPainter = TextPainter(textDirection: ui.TextDirection.ltr);
    final iconStr = String.fromCharCode(iconData.codePoint);
    textPainter.text = TextSpan(
      text: iconStr,
      style: TextStyle(
        letterSpacing: 0.0,
        fontSize: size,
        fontFamily: iconData.fontFamily,
        color: color,
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset.zero);
    final picture = pictureRecorder.endRecording();
    final image = await picture.toImage(textPainter.width.toInt(), textPainter.height.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return bytes!.buffer.asUint8List();
  }
}

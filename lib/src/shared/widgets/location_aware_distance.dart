import 'package:flutter/material.dart';
import '../services/location_service.dart';
import 'package:geolocator/geolocator.dart';

class LocationAwareDistance extends StatefulWidget {
  final double? fieldLatitude;
  final double? fieldLongitude;
  final TextStyle? textStyle;
  final String suffix;
  final Widget? child; // If provided, child will be shown instead of text when no location access

  const LocationAwareDistance({
    super.key,
    this.fieldLatitude,
    this.fieldLongitude,
    this.textStyle,
    this.suffix = ' km away',
    this.child,
  });

  @override
  State<LocationAwareDistance> createState() => _LocationAwareDistanceState();
}

class _LocationAwareDistanceState extends State<LocationAwareDistance> {
  final LocationService _locationService = LocationService();
  double? _calculatedDistance;
  bool _isCalculating = false;
  bool _hasLocationAccess = false;

  @override
  void initState() {
    super.initState();
    _checkLocationAndCalculateDistance();
  }

  @override
  void didUpdateWidget(LocationAwareDistance oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Recalculate if coordinates changed
    if (oldWidget.fieldLatitude != widget.fieldLatitude ||
        oldWidget.fieldLongitude != widget.fieldLongitude) {
      _checkLocationAndCalculateDistance();
    }
  }

  Future<void> _checkLocationAndCalculateDistance() async {
    if (widget.fieldLatitude == null || widget.fieldLongitude == null) {
      return;
    }

    setState(() {
      _isCalculating = true;
    });

    try {
      // Check if location is available (permission granted and service enabled)
      final bool locationAvailable = await _locationService.isLocationAvailable();
      
      if (!locationAvailable) {
        setState(() {
          _hasLocationAccess = false;
          _calculatedDistance = null;
          _isCalculating = false;
        });
        return;
      }

      // Get current location
      final Position? currentPosition = await _locationService.getCurrentLocation();
      
      if (currentPosition != null) {
        // Calculate distance
        final double distance = _locationService.calculateDistance(
          currentPosition.latitude,
          currentPosition.longitude,
          widget.fieldLatitude!,
          widget.fieldLongitude!,
        );

        setState(() {
          _hasLocationAccess = true;
          _calculatedDistance = distance;
          _isCalculating = false;
        });
      } else {
        setState(() {
          _hasLocationAccess = false;
          _calculatedDistance = null;
          _isCalculating = false;
        });
      }
    } catch (e) {
      setState(() {
        _hasLocationAccess = false;
        _calculatedDistance = null;
        _isCalculating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // If we're still calculating, show nothing to avoid flashing
    if (_isCalculating) {
      return const SizedBox.shrink();
    }

    // If no location access, show child widget if provided, otherwise show nothing
    if (!_hasLocationAccess || _calculatedDistance == null) {
      return widget.child ?? const SizedBox.shrink();
    }

    // Show the distance
    return Text(
      '${_calculatedDistance!.toStringAsFixed(1)}${widget.suffix}',
      style: widget.textStyle ?? const TextStyle(
        fontSize: 12,
        color: Color(0xFF757575),
      ),
    );
  }
}

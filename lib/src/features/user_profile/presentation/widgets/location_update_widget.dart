import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../shared/services/location_service.dart';
import '../../../goalkeeper_search/data/services/goalkeeper_search_service.dart';

class LocationUpdateWidget extends StatefulWidget {
  final String userId;
  final double? currentLatitude;
  final double? currentLongitude;
  final VoidCallback? onLocationUpdated;

  const LocationUpdateWidget({
    super.key,
    required this.userId,
    this.currentLatitude,
    this.currentLongitude,
    this.onLocationUpdated,
  });

  @override
  State<LocationUpdateWidget> createState() => _LocationUpdateWidgetState();
}

class _LocationUpdateWidgetState extends State<LocationUpdateWidget> {
  final LocationService _locationService = LocationService();
  final GoalkeeperSearchService _goalkeeperSearchService = GoalkeeperSearchService();
  bool _isUpdatingLocation = false;
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    if (widget.currentLatitude != null && widget.currentLongitude != null) {
      _currentPosition = Position(
        latitude: widget.currentLatitude!,
        longitude: widget.currentLongitude!,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      );
    }
  }

  Future<void> _updateLocation() async {
    setState(() {
      _isUpdatingLocation = true;
    });

    try {
      final position = await _locationService.getCurrentLocation();
      if (position == null) {
        _showErrorSnackBar('Não foi possível obter a sua localização');
        return;
      }

      final success = await _goalkeeperSearchService.updateUserLocation(
        widget.userId,
        position.latitude,
        position.longitude,
      );

      if (success) {
        setState(() {
          _currentPosition = position;
        });
        _showSuccessSnackBar('Localização atualizada com sucesso!');
        widget.onLocationUpdated?.call();
      } else {
        _showErrorSnackBar('Erro ao atualizar localização');
      }
    } catch (e) {
      _showErrorSnackBar('Erro ao atualizar localização: ${e.toString()}');
    } finally {
      setState(() {
        _isUpdatingLocation = false;
      });
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: const Color(0xFFFF6B6B),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }

  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: const Color(0xFF4CAF50),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.location_on,
                  color: Color(0xFF4CAF50),
                  size: 24,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Localização',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2C2C2C),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _currentPosition != null
                  ? 'Localização atual: ${_currentPosition!.latitude.toStringAsFixed(6)}, ${_currentPosition!.longitude.toStringAsFixed(6)}'
                  : 'Nenhuma localização definida',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF757575),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _currentPosition != null
                  ? 'Actualize a sua localização para melhorar a pesquisa por guarda-redes próximos.'
                  : 'Defina a sua localização para encontrar guarda-redes próximos.',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF2C2C2C),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isUpdatingLocation ? null : _updateLocation,
                icon: _isUpdatingLocation
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.my_location),
                label: Text(
                  _isUpdatingLocation
                      ? 'Atualizando...'
                      : _currentPosition != null
                          ? 'Atualizar Localização'
                          : 'Definir Localização',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
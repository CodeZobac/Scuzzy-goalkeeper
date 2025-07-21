import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import '../../../../core/config/app_config.dart';
import '../controllers/map_view_model.dart';
import '../providers/field_selection_provider.dart';
import '../widgets/field_details_card.dart';
import '../widgets/enhanced_filter_dialog.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MapViewModel(context.read<FieldSelectionProvider>()),
      child: const _MapScreenContent(),
    );
  }
}

class _MapScreenContent extends StatefulWidget {
  const _MapScreenContent();

  @override
  State<_MapScreenContent> createState() => _MapScreenContentState();
}

class _MapScreenContentState extends State<_MapScreenContent> {
  MapboxMap? _mapboxMap;
  Timer? _debounce;
  PointAnnotationManager? _pointAnnotationManager;

  @override
  void initState() {
    super.initState();
    // Initialization will be handled in _onMapCreated
  }

  void _onMapCreated(MapboxMap mapboxMap) {
    _mapboxMap = mapboxMap;
    final viewModel = context.read<MapViewModel>();
    viewModel.setMapboxMap(mapboxMap);
    viewModel.initializeMap();

    _mapboxMap?.annotations.createPointAnnotationManager().then((manager) {
      _pointAnnotationManager = manager;
      viewModel.setPointAnnotationManager(manager);
      // Add markers after the manager is created
      viewModel.addMarkersToMapbox();
    });

    _mapboxMap?.onCameraChangeListener.add(_cameraChanged);
  }

  void _cameraChanged(CameraChangedEventData event) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 100), () {
      _updatePitch();
    });
  }

  void _updatePitch() {
    if (_mapboxMap == null) return;

    _mapboxMap?.getCameraState().then((cameraState) {
      final currentZoom = cameraState.zoom;
      final newPitch = _calculatePitch(currentZoom);

      if (cameraState.pitch.abs() - newPitch.abs() > 1.0) {
        _mapboxMap?.flyTo(
          CameraOptions(pitch: newPitch),
          MapAnimationOptions(duration: 300),
        );
      }
    });
  }

  double _calculatePitch(double zoom) {
    // This function creates a smooth transition for the pitch based on the zoom level.
    // Zoom levels < 10: Pitch is 0 (top-down view)
    // Zoom levels 10-16: Pitch transitions from 0 to 60 degrees
    // Zoom levels > 16: Pitch is capped at 60 degrees
    const minZoom = 10.0;
    const maxZoom = 16.0;
    const maxPitch = 60.0;

    if (zoom < minZoom) {
      return 0.0;
    } else if (zoom > maxZoom) {
      return maxPitch;
    } else {
      // Linear interpolation between min and max zoom
      return ((zoom - minZoom) / (maxZoom - minZoom)) * maxPitch;
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _mapboxMap?.onCameraChangeListener.remove(_cameraChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<MapViewModel>();
    final token = AppConfig.mapboxAccessToken;

    if (token.isEmpty) {
      return const Scaffold(
        body: Center(
          child: Text("Mapbox token not found. Please check your configuration."),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          MapWidget(
            key: const ValueKey("mapWidget"),
            onMapCreated: _onMapCreated,
            onTapListener: (coordinate) {
              viewModel.clearSelectedField();
            },
            resourceOptions: ResourceOptions(accessToken: token),
            cameraOptions: CameraOptions(
              center: Point(
                coordinates: Position(
                  -9.1393, // lng
                  38.7223, // lat
                ),
              ).toJson(),
              zoom: 12.0,
              pitch: 0,
            ),
            styleUri: 'mapbox://styles/afonsocaboz/cmdd83lik011o01s9crrz77xe',
          ),
          _buildFloatingButtons(),
          _buildFilterStatusIndicator(),
          Consumer<FieldSelectionProvider>(
            builder: (context, fieldSelection, child) {
              return AnimatedOpacity(
                opacity: fieldSelection.selectedField != null ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeInOut,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeInOut,
                  transform: Matrix4.identity()
                    ..translate(
                      0.0,
                      fieldSelection.selectedField != null
                          ? 0.0
                          : MediaQuery.of(context).size.height * 0.5,
                    ),
                  child: fieldSelection.selectedField != null
                      ? FieldDetailsCard(
                          field: fieldSelection.selectedField!,
                          onClose: () => fieldSelection.clearSelection(),
                        )
                      : const SizedBox.shrink(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingButtons() {
    final viewModel = context.watch<MapViewModel>();

    return Positioned(
      top: 50,
      right: 16,
      child: Column(
        children: [
          // City filter button
          Container(
            decoration: BoxDecoration(
              color: (viewModel.selectedCity != null ||
                      viewModel.selectedAvailability != null)
                  ? const Color(0xFF6C5CE7)
                  : Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _showEnhancedFilterDialog(context),
                borderRadius: BorderRadius.circular(28),
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Icon(
                          Icons.tune,
                          color: (viewModel.selectedCity != null ||
                                  viewModel.selectedAvailability != null)
                              ? Colors.white
                              : Colors.black,
                          size: 24,
                        ),
                      ),
                      if (viewModel.selectedCity != null ||
                          viewModel.selectedAvailability != null)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: const BoxDecoration(
                              color: Color(0xFF00D68F),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Location button
          FloatingActionButton(
            onPressed: () => _centerOnUserLocation(context),
            backgroundColor: Colors.white,
            child: const Icon(Icons.near_me_outlined, color: Colors.black),
          ),
        ],
      ),
    );
  }

  void _showEnhancedFilterDialog(BuildContext context) {
    final viewModel = context.read<MapViewModel>();

    showDialog(
      context: context,
      builder: (context) => EnhancedFilterDialog(
        availableCities: viewModel.availableCities,
        selectedCity: viewModel.selectedCity,
        selectedAvailability: viewModel.selectedAvailability,
        onCitySelected: (city) {
          viewModel.filterByCity(city);
        },
        onAvailabilitySelected: (availability) {
          viewModel.filterByAvailability(availability);
        },
        onClearFilter: () {
          viewModel.clearAllFilters();
        },
      ),
    );
  }

  void _centerOnUserLocation(BuildContext context) {
    final viewModel = context.read<MapViewModel>();
    viewModel.centerOnUserLocationWithStyle();
  }

  Widget _buildFilterStatusIndicator() {
    final viewModel = context.watch<MapViewModel>();

    if (viewModel.selectedCity == null &&
        viewModel.selectedAvailability == null) {
      return const SizedBox.shrink();
    }

    return Positioned(
      top: 50,
      left: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF6C5CE7),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.filter_list,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (viewModel.selectedCity != null)
                  Text(
                    viewModel.selectedCity!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                if (viewModel.selectedAvailability != null)
                  Text(
                    viewModel.selectedAvailability!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                viewModel.clearAllFilters();
              },
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

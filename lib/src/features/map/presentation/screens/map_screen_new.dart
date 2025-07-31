import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
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
  late MapController _mapController;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    // Set the map controller after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MapViewModel>().setMapController(_mapController);
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<MapViewModel>();

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(38.7223, -9.1393), // Lisbon
              initialZoom: 12.0,
              onTap: (_, __) => viewModel.clearSelectedField(),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://api.mapbox.com/styles/v1/afonsocaboz/cmdd83lik011o01s9crrz77xe/tiles/256/{z}/{x}/{y}@2x?access_token=${AppConfig.mapboxAccessToken}',
                additionalOptions: const {
                  'access_token': AppConfig.mapboxAccessToken,
                },
              ),
              MarkerLayer(
                markers: viewModel.markers,
              ),
            ],
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
                  transform: Matrix4.identity()..translate(
                    0.0,
                    fieldSelection.selectedField != null ? 0.0 : MediaQuery.of(context).size.height * 0.5,
                  ),
                  child: fieldSelection.selectedField != null ?
                    FieldDetailsCard(
                      field: fieldSelection.selectedField!,
                      onClose: () => fieldSelection.clearSelection(),
                    ) : const SizedBox.shrink(),
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
          // Filter button
          Container(
            decoration: BoxDecoration(
              color: (viewModel.selectedCity != null || viewModel.selectedAvailability != null)
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
                          color: (viewModel.selectedCity != null || viewModel.selectedAvailability != null)
                              ? Colors.white 
                              : Colors.black,
                          size: 24,
                        ),
                      ),
                      if (viewModel.selectedCity != null || viewModel.selectedAvailability != null)
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
    viewModel.centerOnUserLocation();
  }

  Widget _buildFilterStatusIndicator() {
    final viewModel = context.watch<MapViewModel>();
    
    if (viewModel.selectedCity == null && viewModel.selectedAvailability == null) {
      return const SizedBox.shrink();
    }
    
    return Positioned(
      top: 110, // Adjusted position to avoid overlap with floating buttons
      left: 16,
      right: 16, // Allow it to take full width for better wrapping
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
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.filter_list,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Wrap(
                spacing: 8.0, // gap between adjacent chips
                runSpacing: 4.0, // gap between lines
                children: viewModel.activeFilters.map((filter) => Chip(
                  label: Text(filter),
                  labelStyle: const TextStyle(color: Color(0xFF6C5CE7), fontSize: 12, fontWeight: FontWeight.w600),
                  backgroundColor: Colors.white,
                  deleteIcon: const Icon(Icons.close, size: 16, color: Color(0xFF6C5CE7)),
                  onDeleted: () => viewModel.removeFilter(filter), // Assuming a removeFilter method exists
                )).toList(),
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
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../../../core/config/app_config.dart';
import '../controllers/map_view_model.dart';
import '../providers/field_selection_provider.dart';
import '../../data/repositories/field_repository.dart';
import '../widgets/field_details_card.dart';
import '../widgets/enhanced_filter_dialog.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => FieldSelectionProvider()),
        ChangeNotifierProxyProvider<FieldSelectionProvider, MapViewModel>(
          create: (context) => MapViewModel(FieldRepository(), context.read<FieldSelectionProvider>()),
          update: (context, fieldSelection, previous) => 
            previous ?? MapViewModel(FieldRepository(), fieldSelection),
        ),
      ],
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
    // Initialize the view model after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = context.read<MapViewModel>();
      viewModel.setMapController(_mapController);
      viewModel.initialize();
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
              onTap: (_, __) => context.read<FieldSelectionProvider>().clearSelection(),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://api.mapbox.com/styles/v1/afonsocaboz/cmdd83lik011o01s9crrz77xe/tiles/256/{z}/{x}/{y}@2x?access_token=${AppConfig.mapboxAccessToken}',
                additionalOptions: {
                  'access_token': AppConfig.mapboxAccessToken,
                },
              ),
              MarkerLayer(
                markers: viewModel.buildMarkers(),
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

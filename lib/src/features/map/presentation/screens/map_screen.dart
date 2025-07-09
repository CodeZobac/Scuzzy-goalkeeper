import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import '../controllers/map_controller.dart';
import '../../domain/models/map_field.dart';
import '../../../auth/presentation/theme/app_theme.dart';
import '../widgets/field_suggestion_sheet.dart';
import '../widgets/field_details_card.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
  late MapController _mapController;
  late AnimationController _fabAnimationController;
  late Animation<double> _fabScaleAnimation;
  MapField? _selectedField;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();

    // Set up field tap callback
    _mapController.onFieldTapped = (field) {
      setState(() {
        _selectedField = field;
      });
    };

    _fabAnimationController = AnimationController(
      duration: AppTheme.mediumAnimation,
      vsync: this,
    );

    _fabScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.8,
    ).animate(CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.elasticOut,
    ));

    _mapController.initialize();
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _mapController,
      child: Scaffold(
        backgroundColor: AppTheme.primaryBackground,
        body: Stack(
          children: [
            // Map Widget
            Consumer<MapController>(
              builder: (context, controller, _) {
                return Container(
                  decoration: const BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                  ),
                  child: MapWidget(
                    styleUri: MapboxStyles.STANDARD,
                    cameraOptions: CameraOptions(
                      center: Point(coordinates: Position(-104.9903, 39.7392)),
                      zoom: 10.0,
                    ),
                    onMapCreated: (MapboxMap mapboxMap) {
                      controller.setMapboxMap(mapboxMap);
                    },
                    onStyleLoadedListener: (data) {
                      controller.loadFields();
                    },
                    onTapListener: (MapContentGestureContext context) {
                      _mapController.onMapTap(context.point);
                    },
                  ),
                );
              },
            ),
            
            // Top Controls
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              left: 16,
              right: 16,
              child: _buildTopControls(),
            ),
            
            // Loading Overlay
            Consumer<MapController>(
              builder: (context, controller, _) {
                if (controller.loadingState == MapLoadingState.loading) {
                  return Container(
                    color: Colors.black26,
                    child: const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentColor),
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),

            // Field Details Card Overlay
            if (_selectedField != null)
              Positioned(
                bottom: 180,
                left: 16,
                right: 16,
                child: FieldDetailsCard(
                  field: _selectedField!,
                  onClose: () {
                    setState(() {
                      _selectedField = null;
                    });
                  },
                ),
              ),
            
            // FAB
            Positioned(
              bottom: 100,
              right: 16,
              child: _buildFloatingActionButtons(),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTopControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.secondaryBackground.withOpacity(0.95),
            AppTheme.primaryBackground.withOpacity(0.95),
          ],
        ),
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.map,
                  color: AppTheme.accentColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mapa de Campos',
                      style: AppTheme.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Consumer<MapController>(
                      builder: (context, controller, _) {
                        return Text(
                          '${controller.fields.length} campos disponíveis',
                          style: AppTheme.bodyMedium,
                        );
                      },
                    ),
                  ],
                ),
              ),
              Consumer<MapController>(
                builder: (context, controller, _) {
                  return IconButton(
                    onPressed: controller.userLocation != null 
                        ? () => controller.moveToUserLocation() 
                        : null,
                    icon: const Icon(
                      Icons.my_location,
                      color: AppTheme.accentColor,
                    ),
                  );
                },
              ),
            ],
          ),
          // Add warning for missing Mapbox token
          if (_isMapboxTokenMissing())
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning,
                    color: Colors.orange,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Configure o token do Mapbox no arquivo .env para funcionalidade completa do mapa',
                      style: AppTheme.bodyMedium.copyWith(
                        fontSize: 12,
                        color: Colors.orange,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  bool _isMapboxTokenMissing() {
    // You could also check via dotenv, but this is simpler
    return false; // For now, assume it's configured
  }
  
  Widget _buildFloatingActionButtons() {
    return Consumer<MapController>(
      builder: (context, controller, _) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Refresh button
            Container(
              decoration: BoxDecoration(
                gradient: AppTheme.buttonGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.accentColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: FloatingActionButton(
                heroTag: 'refresh',
                backgroundColor: Colors.transparent,
                elevation: 0,
                onPressed: controller.refresh,
                child: const Icon(
                  Icons.refresh,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Add field button
            AnimatedBuilder(
              animation: _fabScaleAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _fabScaleAnimation.value,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: controller.isAddingField 
                          ? const LinearGradient(
                              colors: [AppTheme.successColor, Color(0xFF2ECC71)]
                            )
                          : AppTheme.buttonGradient,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (controller.isAddingField 
                              ? AppTheme.successColor 
                              : AppTheme.accentColor).withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: FloatingActionButton(
                      heroTag: 'add_field',
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      onPressed: () {
                        _fabAnimationController.forward().then((_) {
                          _fabAnimationController.reverse();
                        });
                        
                        controller.toggleAddingField();
                        if (controller.isAddingField) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Toque no mapa para selecionar a localização do campo'),
                              backgroundColor: AppTheme.accentColor,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                              ),
                              duration: const Duration(seconds: 3),
                            ),
                          );
                        } else {
                          if (controller.selectedLatitude != null && controller.selectedLongitude != null) {
                            _showFieldSuggestionSheet(context);
                          }
                        }
                      },
                      child: AnimatedSwitcher(
                        duration: AppTheme.shortAnimation,
                        child: Icon(
                          controller.isAddingField ? Icons.add_location : Icons.add,
                          key: ValueKey(controller.isAddingField),
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
  
  void _showFieldSuggestionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FieldSuggestionSheet(
        mapController: _mapController,
      ),
    );
  }
}

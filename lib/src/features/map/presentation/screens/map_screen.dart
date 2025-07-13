import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong2/latlong.dart';
import 'dart:io' show Platform;
import '../controllers/map_controller_new.dart';
import '../../domain/models/map_field.dart';
import '../../../auth/presentation/theme/app_theme.dart';
import '../widgets/field_details_card_new.dart';
import '../widgets/field_marker.dart';
import '../widgets/user_marker.dart';
import '../widgets/cluster_marker.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late MapControllerNew _mapController;

  @override
  void initState() {
    super.initState();
    _mapController = MapControllerNew();
    _mapController.setMapController(fm.MapController());
    _mapController.initialize();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _mapController,
      child: Scaffold(
        body: Stack(
          children: [
            Consumer<MapControllerNew>(
              builder: (context, controller, _) {
                return fm.FlutterMap(
                  mapController: controller.mapController,
                  options: fm.MapOptions(
                    initialCenter: LatLng(39.7392, -104.9903),
                    initialZoom: 10.0,
                    onTap: (tapPosition, point) {
                      controller.clearSelectedField();
                    },
                  ),
                  children: [
                    fm.TileLayer(
                      urlTemplate: 'https://tiles.stadiamaps.com/tiles/stamen_terrain/{z}/{x}/{y}{r}.png?api_key=${dotenv.env['STADIA_API_KEY']}',
                      retinaMode: Platform.isAndroid || Platform.isIOS,
                      userAgentPackageName: 'com.goalkeeper.app',
                    ),
                    MarkerClusterLayerWidget(
                      options: MarkerClusterLayerOptions(
                        markers: _buildMarkers(controller),
                        builder: (context, markers) {
                          return ClusterMarker(
                            count: markers.length,
                            onTap: () {
                              // Implement zoom logic if needed
                            },
                          );
                        },
                        maxClusterRadius: 80,
                        size: const Size(40, 40),
                      ),
                    ),
                  ],
                );
              },
            ),
            Consumer<MapControllerNew>(
              builder: (context, controller, _) {
                if (controller.loadingState == MapLoadingState.loading) {
                  return const Center(child: CircularProgressIndicator());
                }
                return const SizedBox.shrink();
              },
            ),
            Consumer<MapControllerNew>(
              builder: (context, controller, _) {
                if (controller.selectedField != null) {
                  return Positioned(
                    bottom: 80,
                    left: 0,
                    right: 0,
                    child: FieldDetailsCardNew(
                      field: controller.selectedField!,
                      onClose: () => controller.clearSelectedField(),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            _buildFloatingActionButtons(),
          ],
        ),
      ),
    );
  }

  List<fm.Marker> _buildMarkers(MapControllerNew controller) {
    final markers = controller.fields.map((field) {
      return fm.Marker(
        width: 40.0,
        height: 40.0,
        point: LatLng(field.latitude, field.longitude),
        child: FieldMarker(
          isSelected: controller.selectedField?.id == field.id,
          onTap: () => controller.onFieldSelected(field),
        ),
      );
    }).toList();

    if (controller.userLocation != null) {
      markers.add(
        fm.Marker(
          width: 40.0,
          height: 40.0,
          point: controller.userLocation!,
          child: const UserMarker(
            imageUrl: 'https://via.placeholder.com/150/000000/FFFFFF/?text=User',
          ),
        ),
      );
    }

    return markers;
  }

  Widget _buildFloatingActionButtons() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      right: 16,
      child: Column(
        children: [
          FloatingActionButton(
            heroTag: 'filter_btn',
            onPressed: () {},
            backgroundColor: Colors.white,
            child: const Icon(Icons.tune, color: AppTheme.primaryText),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'location_btn',
            onPressed: () => _mapController.moveToUserLocation(),
            backgroundColor: Colors.white,
            child: const Icon(Icons.my_location, color: AppTheme.primaryText),
          ),
        ],
      ),
    );
  }
}

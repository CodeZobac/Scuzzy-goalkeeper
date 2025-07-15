
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../controllers/map_view_model.dart';
import '../widgets/field_details_card.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MapViewModel(),
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
  @override
  void initState() {
    super.initState();
    _loadMapStyle();
  }

  Future<void> _loadMapStyle() async {
    final style = await rootBundle.loadString('assets/map_style.json');
    context.read<MapViewModel>().setMapStyle(style);
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<MapViewModel>();

    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: viewModel.onMapCreated,
            initialCameraPosition: const CameraPosition(
              target: LatLng(38.7223, -9.1393), // Lisbon
              zoom: 12,
            ),
            markers: viewModel.markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false, // Disable default button
            zoomControlsEnabled: false,
            onTap: (_) => viewModel.clearSelectedField(),
          ),
          _buildFloatingButtons(),
          if (viewModel.selectedField != null)
            FieldDetailsCard(
              field: viewModel.selectedField!,
              onClose: () => viewModel.clearSelectedField(),
            ),
        ],
      ),
    );
  }

  Widget _buildFloatingButtons() {
    return Positioned(
      top: 50,
      right: 16,
      child: Column(
        children: [
          FloatingActionButton(
            onPressed: () {},
            backgroundColor: Colors.white,
            child: const Icon(Icons.tune, color: Colors.black),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            onPressed: () {},
            backgroundColor: Colors.white,
            child: const Icon(Icons.near_me_outlined, color: Colors.black),
          ),
        ],
      ),
    );
  }
}

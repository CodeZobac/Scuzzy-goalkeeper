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
  double _currentZoom = 12.0;

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
              onPositionChanged: (position, hasGesture) {
                if (position.zoom != _currentZoom) {
                  setState(() {
                    _currentZoom = position.zoom;
                  });
                  
                  // Notify view model of zoom change for smooth clustering transitions
                  if (hasGesture) {
                    final viewModel = context.read<MapViewModel>();
                    viewModel.onZoomChanged(_currentZoom);
                  }
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://api.mapbox.com/styles/v1/afonsocaboz/cmdd83lik011o01s9crrz77xe/tiles/256/{z}/{x}/{y}@2x?access_token=${AppConfig.mapboxAccessToken}',
                additionalOptions: {
                  'access_token': AppConfig.mapboxAccessToken,
                },
              ),
              MarkerLayer(
                markers: viewModel.buildMarkers(
                  context: context,
                  onGoalkeeperTap: (goalkeeper) => _showHireGoalkeeperForm(context, goalkeeper),
                  zoom: _currentZoom,
                ),
              ),
            ],
          ),
          _buildFloatingButtons(),
          _buildFilterStatusIndicator(),
          _buildCredibleDataNotice(),
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

  void _showHireGoalkeeperForm(BuildContext context, dynamic goalkeeper) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE0E0E0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF4CAF50), Color(0xFF45A049)],
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.sports_soccer,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Contratar Guarda-redes',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                goalkeeper?['name'] ?? 'Guarda-redes Selecionado',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            if (goalkeeper?['verified'] == true)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.verified,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Verificado',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Credible data notice
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF4CAF50).withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.verified,
                            color: Color(0xFF4CAF50),
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Dados Verificados',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF4CAF50),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Este guarda-redes foi verificado e possui dados credíveis.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF757575),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Goalkeeper details
                    _buildGoalkeeperDetail('Localização', goalkeeper?['location'] ?? 'Lisboa, Portugal'),
                    _buildGoalkeeperDetail('Preço', goalkeeper?['price'] ?? '€25/hora'),
                    _buildGoalkeeperDetail('Experiência', goalkeeper?['experience'] ?? '5 anos'),
                    _buildGoalkeeperDetail('Avaliação', goalkeeper?['rating'] ?? '4.8 ⭐'),
                    if (goalkeeper?['club'] != null && goalkeeper!['club'] != 'Sem clube')
                      _buildGoalkeeperDetail('Clube', goalkeeper['club']),
                    if (goalkeeper?['age'] != null && goalkeeper!['age'] != 'Idade não informada')
                      _buildGoalkeeperDetail('Idade', goalkeeper['age']),
                    
                    const Spacer(),
                    
                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFF4CAF50)),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Cancelar',
                              style: TextStyle(
                                color: Color(0xFF4CAF50),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              _proceedToBooking(context, goalkeeper);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4CAF50),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Contratar',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalkeeperDetail(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF757575),
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF2C2C2C),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _proceedToBooking(BuildContext context, dynamic goalkeeper) {
    // Navigate to booking screen or show booking form
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Redirecionando para agendamento...'),
        backgroundColor: Color(0xFF4CAF50),
        behavior: SnackBarBehavior.floating,
      ),
    );
    
    // Here you would typically navigate to the booking screen
    // Navigator.of(context).push(
    //   MaterialPageRoute(
    //     builder: (context) => BookingScreen(goalkeeper: goalkeeper),
    //   ),
    // );
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

  Widget _buildCredibleDataNotice() {
    return Positioned(
      bottom: 100,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF4CAF50), Color(0xFF45A049)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.verified_user,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Dados Verificados',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Todos os guarda-redes são verificados com dados credíveis',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => _showCredibleDataInfo(context),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.info_outline,
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

  void _showCredibleDataInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.verified_user,
                color: Color(0xFF4CAF50),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Dados Credíveis',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2C2C2C),
              ),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Garantimos que todos os guarda-redes na nossa plataforma:',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF757575),
              ),
            ),
            SizedBox(height: 16),
            _CredibleDataPoint(
              icon: Icons.person_search,
              text: 'Identidade verificada',
            ),
            _CredibleDataPoint(
              icon: Icons.star,
              text: 'Avaliações autênticas',
            ),
            _CredibleDataPoint(
              icon: Icons.location_on,
              text: 'Localização confirmada',
            ),
            _CredibleDataPoint(
              icon: Icons.sports_soccer,
              text: 'Experiência validada',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Entendi',
              style: TextStyle(
                color: Color(0xFF4CAF50),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CredibleDataPoint extends StatelessWidget {
  final IconData icon;
  final String text;

  const _CredibleDataPoint({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: const Color(0xFF4CAF50),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF2C2C2C),
            ),
          ),
        ],
      ),
    );
  }
}

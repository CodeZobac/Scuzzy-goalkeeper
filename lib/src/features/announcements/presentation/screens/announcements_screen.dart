import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/announcement_controller.dart';
import '../widgets/announcement_card.dart';
import '../widgets/loading_state_widget.dart';
import '../widgets/error_state_widget.dart';
import '../../../../core/navigation/navigation_service.dart';
import '../../../auth/presentation/providers/auth_state_provider.dart';
import 'package:intl/intl.dart';

class AnnouncementsScreen extends StatefulWidget {
  const AnnouncementsScreen({super.key});

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
  String _selectedFilter = 'Todos os Anúncios';
  
  @override
  void initState() {
    super.initState();
    // Fetch announcements after the first frame is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<AnnouncementController>(context, listen: false)
            .fetchAnnouncements();
      }
    });
  }

  String _getCurrentDateString() {
    final now = DateTime.now();
    final formatter = DateFormat('dd MMMM');
    return 'Hoje, ${formatter.format(now)}';
  }

  @override
  Widget build(BuildContext context) {
    final announcementController = Provider.of<AnnouncementController>(context);
    final authStateProvider = Provider.of<AuthStateProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      floatingActionButton: authStateProvider.isGuest ? null : Container(
        margin: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 80), // Above nav bar
        child: FloatingActionButton(
          onPressed: () {
            Navigator.of(context).pushNamed('/create-announcement');
          },
          backgroundColor: const Color(0xFF4CAF50),
          child: const Icon(
            Icons.add,
            color: Colors.white,
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: Column(
        children: [
          // Large rounded green header container
          Container(
            height: 200,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF4CAF50),
                  Color(0xFF45A049),
                ],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getCurrentDateString(),
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Lobby',
                              style: TextStyle(
                                fontSize: 32,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Cria ou entra num jogo',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                        // Filter icon
                        GestureDetector(
                          onTap: () {
                            _showFilterBottomSheet(context);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.tune,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Content area that can scroll freely
          Expanded(
            child: Transform.translate(
              offset: const Offset(0, -60), // Move content up to overlap header
              child: announcementController.isLoading
                  ? _buildLoadingState()
                  : announcementController.hasError
                      ? _buildErrorState(announcementController)
                      : announcementController.announcements.isEmpty
                          ? _buildEmptyState()
                          : _buildAnnouncementsList(announcementController),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return RefreshIndicator(
      onRefresh: () => Provider.of<AnnouncementController>(context, listen: false).refreshAnnouncements(),
      color: const Color(0xFF4CAF50),
      backgroundColor: Colors.white,
      strokeWidth: 2.5,
      displacement: 40,
      child: const SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: 400,
          child: LoadingStateWidget(
            message: 'A carregar anúncios...',
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return RefreshIndicator(
      onRefresh: () => Provider.of<AnnouncementController>(context, listen: false).refreshAnnouncements(),
      color: const Color(0xFF4CAF50),
      backgroundColor: Colors.white,
      strokeWidth: 2.5,
      displacement: 40,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: 400,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.campaign_outlined,
                  size: 80,
                  color: Color(0xFF757575),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Ainda não há anúncios',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2C2C2C),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Seja o primeiro a criar um anúncio',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF757575),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Deslize para baixo para atualizar',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF9E9E9E),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(AnnouncementController controller) {
    return RefreshIndicator(
      onRefresh: () => controller.refreshAnnouncements(),
      color: const Color(0xFF4CAF50),
      backgroundColor: Colors.white,
      strokeWidth: 2.5,
      displacement: 40,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: 400,
          child: ErrorStateWidget(
            errorMessage: controller.errorMessage,
            onRetry: () => controller.retry(),
            isRetrying: controller.isLoading,
            onDismiss: () => controller.clearError(),
          ),
        ),
      ),
    );
  }

  Widget _buildAnnouncementsList(AnnouncementController controller) {
    final filteredAnnouncements = _getFilteredAnnouncements(controller.announcements);
    
    return RefreshIndicator(
      onRefresh: () => controller.refreshAnnouncements(),
      color: const Color(0xFF4CAF50),
      backgroundColor: Colors.white,
      strokeWidth: 2.5,
      displacement: 40,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: filteredAnnouncements.length,
        itemBuilder: (context, index) {
          final announcement = filteredAnnouncements[index];
          return AnnouncementCard(
            announcement: announcement,
            onTap: () {
              NavigationService.pushAnnouncementDetail(
                context,
                announcement,
              );
            },
          );
        },
      ),
    );
  }

  List<dynamic> _getFilteredAnnouncements(List<dynamic> announcements) {
    final now = DateTime.now();
    
    switch (_selectedFilter) {
      case 'Hoje':
        return announcements.where((announcement) {
          final announcementDate = DateTime.parse(announcement.date.toString());
          return announcementDate.year == now.year &&
                 announcementDate.month == now.month &&
                 announcementDate.day == now.day;
        }).toList();
      
      case 'Esta Semana':
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final endOfWeek = startOfWeek.add(const Duration(days: 6));
        return announcements.where((announcement) {
          final announcementDate = DateTime.parse(announcement.date.toString());
          return announcementDate.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
                 announcementDate.isBefore(endOfWeek.add(const Duration(days: 1)));
        }).toList();
      
      case 'Jogos Gratuitos':
        return announcements.where((announcement) {
          return announcement.price == null || announcement.price == 0;
        }).toList();
      
      case 'Jogos Pagos':
        return announcements.where((announcement) {
          return announcement.price != null && announcement.price > 0;
        }).toList();
      
      default: // 'Todos os Anúncios'
        return announcements;
    }
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0E0E0),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Title
                  const Text(
                    'Filtrar Anúncios',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2C2C2C),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Filter options
                  _buildFilterOption('Todos os Anúncios', _selectedFilter == 'Todos os Anúncios', setModalState),
                  _buildFilterOption('Hoje', _selectedFilter == 'Hoje', setModalState),
                  _buildFilterOption('Esta Semana', _selectedFilter == 'Esta Semana', setModalState),
                  _buildFilterOption('Jogos Gratuitos', _selectedFilter == 'Jogos Gratuitos', setModalState),
                  _buildFilterOption('Jogos Pagos', _selectedFilter == 'Jogos Pagos', setModalState),
                  
                  const SizedBox(height: 24),
                  
                  // Safe area padding
                  SizedBox(height: MediaQuery.of(context).padding.bottom),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFilterOption(String title, bool isSelected, StateSetter setModalState) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          setModalState(() {
            _selectedFilter = title;
          });
          // Close the bottom sheet after a short delay to show the selection
          Future.delayed(const Duration(milliseconds: 200), () {
            if (mounted) {
              Navigator.of(context).pop();
              setState(() {});
            }
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF4CAF50).withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? const Color(0xFF4CAF50) : const Color(0xFFE0E0E0),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                color: isSelected ? const Color(0xFF4CAF50) : const Color(0xFF757575),
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? const Color(0xFF4CAF50) : const Color(0xFF2C2C2C),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

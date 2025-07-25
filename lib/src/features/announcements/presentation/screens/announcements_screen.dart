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
  @override
  void initState() {
    super.initState();
    // Fetch announcements when the screen is initialized
    Provider.of<AnnouncementController>(context, listen: false)
        .fetchAnnouncements();
  }

  String _getCurrentDateString() {
    final now = DateTime.now();
    final formatter = DateFormat('dd MMMM');
    return 'Today, ${formatter.format(now)}';
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
                              'Recruitment',
                              style: TextStyle(
                                fontSize: 32,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
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
    return const LoadingStateWidget(
      message: 'Loading announcements...',
    );
  }

  Widget _buildEmptyState() {
    return Center(
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
            'No announcements yet',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2C2C2C),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Be the first to create an announcement',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF757575),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(AnnouncementController controller) {
    return ErrorStateWidget(
      errorMessage: controller.errorMessage,
      onRetry: () => controller.retry(),
      isRetrying: controller.isLoading,
      onDismiss: () => controller.clearError(),
    );
  }

  Widget _buildAnnouncementsList(AnnouncementController controller) {
    return RefreshIndicator(
      onRefresh: () => controller.refreshAnnouncements(),
      color: const Color(0xFF4CAF50),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: controller.announcements.length,
        itemBuilder: (context, index) {
          final announcement = controller.announcements[index];
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

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
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
              'Filter Announcements',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2C2C2C),
              ),
            ),
            const SizedBox(height: 24),
            
            // Filter options
            _buildFilterOption('All Announcements', true),
            _buildFilterOption('Today', false),
            _buildFilterOption('This Week', false),
            _buildFilterOption('Free Games', false),
            _buildFilterOption('Paid Games', false),
            
            const SizedBox(height: 24),
            
            // Apply button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // TODO: Apply filters
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Apply Filters',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            
            // Safe area padding
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterOption(String title, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          // TODO: Handle filter selection
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF4CAF50).withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? const Color(0xFF4CAF50) : const Color(0xFFE0E0E0),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                color: isSelected ? const Color(0xFF4CAF50) : const Color(0xFF757575),
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
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

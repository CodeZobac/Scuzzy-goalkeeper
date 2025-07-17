import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/announcement_controller.dart';
import '../widgets/announcement_card.dart';
import '../widgets/loading_state_widget.dart';
import '../widgets/error_state_widget.dart';
import '../../../../core/navigation/navigation_service.dart';
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

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // Light gray background from design
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).pushNamed('/create-announcement');
        },
        backgroundColor: const Color(0xFF4CAF50),
        child: const Icon(
          Icons.add,
          color: Colors.white,
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Green gradient header matching design
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF4CAF50), // Primary green from design
                    Color(0xFF45A049), // Darker green for gradient
                  ],
                ),
              ),
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
                              fontSize: 14,
                              color: Colors.white,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Recruitment',
                            style: TextStyle(
                              fontSize: 28,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      // Filter icon matching design
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.tune,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Content area with scrollable list
            Expanded(
              child: announcementController.isLoading
                  ? _buildLoadingState()
                  : announcementController.hasError
                      ? _buildErrorState(announcementController)
                      : announcementController.announcements.isEmpty
                          ? _buildEmptyState()
                          : _buildAnnouncementsList(announcementController),
            ),
          ],
        ),
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
}

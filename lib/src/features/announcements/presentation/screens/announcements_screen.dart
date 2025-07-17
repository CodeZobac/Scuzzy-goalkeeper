import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/announcement_controller.dart';
import '../widgets/announcement_form.dart';
import 'announcement_detail_screen.dart';
import 'package:goalkeeper/src/features/auth/presentation/theme/app_theme.dart';

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

  @override
  Widget build(BuildContext context) {
    final announcementController = Provider.of<AnnouncementController>(context);

    return Scaffold(
      backgroundColor: AppTheme.primaryBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Header with beautiful gradient
            Container(
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.accentColor.withOpacity(0.1),
                    AppTheme.secondaryBackground.withOpacity(0.05),
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
                            'Announcements',
                            style: AppTheme.headingLarge.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Find your next game',
                            style: AppTheme.bodyLarge.copyWith(
                              color: AppTheme.secondaryText,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: AppTheme.buttonGradient,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.accentColor.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (_) => const AnnouncementForm(),
                              );
                            },
                            child: const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Icon(
                                Icons.add,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Content area
            Expanded(
              child: announcementController.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : announcementController.announcements.isEmpty
                      ? _buildEmptyState()
                      : _buildAnnouncementsList(announcementController),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.campaign_outlined,
            size: 80,
            color: AppTheme.secondaryText,
          ),
          const SizedBox(height: 16),
          Text(
            'No announcements yet',
            style: AppTheme.headingMedium.copyWith(
              color: AppTheme.secondaryText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Be the first to create an announcement',
            style: AppTheme.bodyMedium.copyWith(
              color: AppTheme.secondaryText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnnouncementsList(AnnouncementController controller) {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: controller.announcements.length,
      itemBuilder: (context, index) {
        final announcement = controller.announcements[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16.0),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.secondaryBackground.withOpacity(0.8),
                AppTheme.secondaryBackground.withOpacity(0.4),
              ],
            ),
            borderRadius: BorderRadius.circular(AppTheme.borderRadius),
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
              borderRadius: BorderRadius.circular(AppTheme.borderRadius),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AnnouncementDetailScreen(
                      announcement: announcement,
                    ),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            announcement.title,
                            style: AppTheme.headingMedium.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        if (announcement.price != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.accentColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppTheme.accentColor.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              '€${announcement.price}',
                              style: AppTheme.bodyMedium.copyWith(
                                color: AppTheme.accentColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: AppTheme.secondaryText,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${announcement.date.day}/${announcement.date.month}/${announcement.date.year}',
                          style: AppTheme.bodyMedium.copyWith(
                            color: AppTheme.secondaryText,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(
                          Icons.access_time,
                          size: 16,
                          color: AppTheme.secondaryText,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          announcement.time.format(context),
                          style: AppTheme.bodyMedium.copyWith(
                            color: AppTheme.secondaryText,
                          ),
                        ),
                      ],
                    ),
                    if (announcement.stadium != null)
                      Column(
                        children: [
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.stadium,
                                size: 16,
                                color: AppTheme.secondaryText,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                announcement.stadium!,
                                style: AppTheme.bodyMedium.copyWith(
                                  color: AppTheme.secondaryText,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    if (announcement.description != null)
                      Column(
                        children: [
                          const SizedBox(height: 12),
                          Text(
                            announcement.description!,
                            style: AppTheme.bodyMedium.copyWith(
                              color: Colors.white.withOpacity(0.8),
                              height: 1.4,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

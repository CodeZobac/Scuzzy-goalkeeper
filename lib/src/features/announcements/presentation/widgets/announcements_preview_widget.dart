import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/announcement_controller.dart';
import '../screens/announcement_detail_screen.dart';
import '../../../../core/config/app_config.dart';

class AnnouncementsPreviewWidget extends StatefulWidget {
  const AnnouncementsPreviewWidget({super.key});

  @override
  State<AnnouncementsPreviewWidget> createState() =>
      _AnnouncementsPreviewWidgetState();
}

class _AnnouncementsPreviewWidgetState
    extends State<AnnouncementsPreviewWidget> {
  @override
  void initState() {
    super.initState();
    // Fetch announcements when the widget is initialized
    Provider.of<AnnouncementController>(context, listen: false)
        .fetchAnnouncements();
  }

  @override
  Widget build(BuildContext context) {
    final announcementController = Provider.of<AnnouncementController>(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            'Announcements',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        announcementController.isLoading
            ? const Center(child: CircularProgressIndicator())
            : SizedBox(
                height: 150,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: announcementController.announcements.length,
                  itemBuilder: (context, index) {
                    final announcement =
                        announcementController.announcements[index];
                    return GestureDetector(
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
                      child: Card(
                        margin: const EdgeInsets.all(8.0),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                announcement.title,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                  '${announcement.date.toLocal().toString().split(' ')[0]} at ${announcement.time.format(context)}'),
                              const SizedBox(height: 4),
                              if (announcement.price != null)
                                Text('${announcement.price!.toStringAsFixed(0)}${AppConfig.currencySymbol}'),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/announcement_controller.dart';
import '../widgets/announcement_form.dart';
import 'announcement_detail_screen.dart';

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
      appBar: AppBar(
        title: const Text('Announcements'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            builder: (_) => const AnnouncementForm(),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: announcementController.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: announcementController.announcements.length,
              itemBuilder: (context, index) {
                final announcement =
                    announcementController.announcements[index];
                return Card(
                  margin: const EdgeInsets.all(8.0),
                  child: ListTile(
                    title: Text(announcement.title),
                    subtitle: Text(
                      '${announcement.date.toLocal()} at ${announcement.time.format(context)}',
                    ),
                    trailing: announcement.price != null
                        ? Text('\$${announcement.price}')
                        : null,
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
                  ),
                );
              },
            ),
    );
  }
}

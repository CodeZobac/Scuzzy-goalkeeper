import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/announcement.dart';
import '../controllers/announcement_controller.dart';

class AnnouncementDetailScreen extends StatefulWidget {
  final Announcement announcement;

  const AnnouncementDetailScreen({super.key, required this.announcement});

  @override
  State<AnnouncementDetailScreen> createState() =>
      _AnnouncementDetailScreenState();
}

class _AnnouncementDetailScreenState extends State<AnnouncementDetailScreen> {
  List<String> _participants = [];
  bool _isLoading = true;
  bool _isJoined = false;

  @override
  void initState() {
    super.initState();
    _fetchParticipants();
  }

  Future<void> _fetchParticipants() async {
    final announcementController =
        Provider.of<AnnouncementController>(context, listen: false);
    final participants = await announcementController
        .getAnnouncementParticipants(widget.announcement.id);
    final userId = Supabase.instance.client.auth.currentUser?.id;
    setState(() {
      _participants = participants;
      if (userId != null) {
        _isJoined = _participants.contains(userId);
      }
      _isLoading = false;
    });
  }

  Future<void> _toggleJoinStatus() async {
    final announcementController =
        Provider.of<AnnouncementController>(context, listen: false);
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    setState(() {
      _isLoading = true;
    });

    if (_isJoined) {
      await announcementController.leaveAnnouncement(
          widget.announcement.id, userId);
    } else {
      await announcementController.joinAnnouncement(
          widget.announcement.id, userId);
    }

    await _fetchParticipants();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.announcement.title),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.announcement.title,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Date: ${widget.announcement.date.toLocal().toString().split(' ')[0]}',
                  ),
                  const SizedBox(height: 8),
                  Text('Time: ${widget.announcement.time.format(context)}'),
                  const SizedBox(height: 8),
                  if (widget.announcement.price != null)
                    Text('Price: \$${widget.announcement.price}'),
                  const SizedBox(height: 8),
                  if (widget.announcement.stadium != null)
                    Text('Stadium: ${widget.announcement.stadium}'),
                  const SizedBox(height: 16),
                  if (widget.announcement.description != null)
                    Text(widget.announcement.description!),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _toggleJoinStatus,
                    child: Text(_isJoined ? 'Leave' : 'Join'),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Participants (${_participants.length})',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _participants.length,
                      itemBuilder: (context, index) {
                        return Text(_participants[index]);
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

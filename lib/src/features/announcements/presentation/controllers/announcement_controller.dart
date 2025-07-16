import 'package:flutter/material.dart';
import '../../data/models/announcement.dart';
import '../../data/repositories/announcement_repository.dart';

class AnnouncementController extends ChangeNotifier {
  final AnnouncementRepository _announcementRepository;

  AnnouncementController(this._announcementRepository);

  List<Announcement> _announcements = [];
  List<Announcement> get announcements => _announcements;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> fetchAnnouncements() async {
    _isLoading = true;
    notifyListeners();
    _announcements = await _announcementRepository.getAnnouncements();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> createAnnouncement(Announcement announcement) async {
    await _announcementRepository.createAnnouncement(announcement);
    await fetchAnnouncements();
  }

  Future<void> joinAnnouncement(int announcementId, String userId) async {
    await _announcementRepository.joinAnnouncement(announcementId, userId);
  }

  Future<void> leaveAnnouncement(int announcementId, String userId) async {
    await _announcementRepository.leaveAnnouncement(announcementId, userId);
  }

  Future<List<String>> getAnnouncementParticipants(int announcementId) async {
    return await _announcementRepository.getAnnouncementParticipants(announcementId);
  }
}

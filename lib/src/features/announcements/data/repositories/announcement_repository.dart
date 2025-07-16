import '../models/announcement.dart';

abstract class AnnouncementRepository {
  Future<List<Announcement>> getAnnouncements();
  Future<void> createAnnouncement(Announcement announcement);
  Future<void> joinAnnouncement(int announcementId, String userId);
  Future<void> leaveAnnouncement(int announcementId, String userId);
  Future<List<String>> getAnnouncementParticipants(int announcementId);
}

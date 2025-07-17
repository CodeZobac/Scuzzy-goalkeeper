import '../models/announcement.dart';

abstract class AnnouncementRepository {
  Future<List<Announcement>> getAnnouncements();
  Future<void> createAnnouncement(Announcement announcement);
  Future<void> joinAnnouncement(int announcementId, String userId);
  Future<void> leaveAnnouncement(int announcementId, String userId);
  Future<List<String>> getAnnouncementParticipants(int announcementId);
  
  // Enhanced methods for participants and organizer info
  Future<Announcement> getAnnouncementById(int id);
  Future<List<AnnouncementParticipant>> getParticipants(int announcementId);
  Future<bool> isUserParticipant(int announcementId, String userId);
  Future<Map<String, dynamic>> getOrganizerInfo(String userId);
  Future<Map<String, dynamic>> getStadiumInfo(String stadiumName);
}

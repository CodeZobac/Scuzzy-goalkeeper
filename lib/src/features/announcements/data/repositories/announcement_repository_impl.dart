import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/announcement.dart';
import 'announcement_repository.dart';

class AnnouncementRepositoryImpl implements AnnouncementRepository {
  final SupabaseClient _supabaseClient;

  AnnouncementRepositoryImpl(this._supabaseClient);

  @override
  Future<void> createAnnouncement(Announcement announcement) async {
    await _supabaseClient.from('announcements').insert(announcement.toJson());
  }

  @override
  Future<List<Announcement>> getAnnouncements() async {
    final response = await _supabaseClient.from('announcements').select();
    return (response as List).map((e) => Announcement.fromJson(e)).toList();
  }

  @override
  Future<List<String>> getAnnouncementParticipants(int announcementId) async {
    final response = await _supabaseClient
        .from('announcement_participants')
        .select('user_id')
        .eq('announcement_id', announcementId);
    return (response as List).map((e) => e['user_id'] as String).toList();
  }

  @override
  Future<void> joinAnnouncement(int announcementId, String userId) async {
    await _supabaseClient.from('announcement_participants').insert({
      'announcement_id': announcementId,
      'user_id': userId,
    });
  }

  @override
  Future<void> leaveAnnouncement(int announcementId, String userId) async {
    await _supabaseClient
        .from('announcement_participants')
        .delete()
        .eq('announcement_id', announcementId)
        .eq('user_id', userId);
  }
}

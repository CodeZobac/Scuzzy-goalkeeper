import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/announcement.dart';
import 'announcement_repository.dart';

class AnnouncementRepositoryImpl implements AnnouncementRepository {
  final SupabaseClient _supabaseClient;

  AnnouncementRepositoryImpl(this._supabaseClient);

  @override
  Future<void> createAnnouncement(Announcement announcement) async {
    try {
      await _supabaseClient.from('announcements').insert(announcement.toJson());
    } catch (e) {
      throw Exception('Failed to create announcement: $e');
    }
  }

  @override
  Future<List<Announcement>> getAnnouncements() async {
    try {
      final response = await _supabaseClient
          .from('announcements')
          .select('''
            *,
            users!announcements_created_by_fkey(name),
            announcement_participants(count)
          ''');
      
      return (response as List).map((e) {
        final userData = e['users'] ?? {};
        final participantCount = e['announcement_participants']?.length ?? 0;
        
        return Announcement.fromJson({
          ...e,
          'organizer_name': userData['name'],
          'organizer_avatar_url': null, // Not available in public.users
          'organizer_rating': null, // Not available in public.users
          'participant_count': participantCount,
        });
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch announcements: $e');
    }
  }

  @override
  Future<List<String>> getAnnouncementParticipants(int announcementId) async {
    try {
      final response = await _supabaseClient
          .from('announcement_participants')
          .select('user_id')
          .eq('announcement_id', announcementId);
      return (response as List).map((e) => e['user_id'] as String).toList();
    } catch (e) {
      throw Exception('Failed to fetch announcement participants: $e');
    }
  }

  @override
  Future<void> joinAnnouncement(int announcementId, String userId) async {
    try {
      // Check if user is already a participant
      final isAlreadyParticipant = await isUserParticipant(announcementId, userId);
      if (isAlreadyParticipant) {
        throw Exception('User is already a participant in this announcement');
      }
      
      // Get current participant count and max participants
      final announcement = await getAnnouncementById(announcementId);
      if (announcement.participantCount >= announcement.maxParticipants) {
        throw Exception('Announcement is full');
      }
      
      await _supabaseClient.from('announcement_participants').insert({
        'announcement_id': announcementId,
        'user_id': userId,
      });
    } catch (e) {
      if (e.toString().contains('User is already a participant') || 
          e.toString().contains('Announcement is full')) {
        rethrow;
      }
      throw Exception('Failed to join announcement: $e');
    }
  }

  @override
  Future<void> leaveAnnouncement(int announcementId, String userId) async {
    try {
      await _supabaseClient
          .from('announcement_participants')
          .delete()
          .eq('announcement_id', announcementId)
          .eq('user_id', userId);
    } catch (e) {
      throw Exception('Failed to leave announcement: $e');
    }
  }

  @override
  Future<Announcement> getAnnouncementById(int id) async {
    try {
      final response = await _supabaseClient
          .from('announcements')
          .select('''
            *,
            users!announcements_created_by_fkey(name),
            announcement_participants(
              user_id,
              created_at,
              users(name)
            )
          ''')
          .eq('id', id)
          .single();
      
      final userData = response['users'] ?? {};
      final participantsData = response['announcement_participants'] ?? [];
      
      final participants = (participantsData as List).map((p) {
        final pUserData = p['users'] ?? {};
        return AnnouncementParticipant.fromJson({
          'user_id': p['user_id'],
          'name': pUserData['name'] ?? '',
          'avatar_url': null, // Not available in public.users
          'created_at': p['created_at'],
        });
      }).toList();
      
      return Announcement.fromJson({
        ...response,
        'organizer_name': userData['name'],
        'organizer_avatar_url': null, // Not available in public.users
        'organizer_rating': null, // Not available in public.users
        'participant_count': participants.length,
        'participants': participants.map((p) => p.toJson()).toList(),
      });
    } catch (e) {
      throw Exception('Failed to fetch announcement by ID: $e');
    }
  }

  @override
  Future<List<AnnouncementParticipant>> getParticipants(int announcementId) async {
    try {
      final response = await _supabaseClient
          .from('announcement_participants')
          .select('user_id, created_at, users(name)')
          .eq('announcement_id', announcementId);
      
      return (response as List).map((e) {
        final userData = e['users'] ?? {};
        return AnnouncementParticipant.fromJson({
          'user_id': e['user_id'],
          'name': userData['name'] ?? '',
          'avatar_url': null, // Not available in public.users
          'created_at': e['created_at'],
        });
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch participants: $e');
    }
  }

  @override
  Future<bool> isUserParticipant(int announcementId, String userId) async {
    try {
      final response = await _supabaseClient
          .from('announcement_participants')
          .select('user_id')
          .eq('announcement_id', announcementId)
          .eq('user_id', userId);
      
      return (response as List).isNotEmpty;
    } catch (e) {
      throw Exception('Failed to check user participation: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> getOrganizerInfo(String userId) async {
    try {
      final response = await _supabaseClient
          .from('users')
          .select('name')
          .eq('id', userId)
          .single();
      
      return {
        'name': response['name'],
        'avatar_url': null, // Not available in public.users
        'rating': null, // Not available in public.users
      };
    } catch (e) {
      throw Exception('Failed to fetch organizer info: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> getStadiumInfo(String stadiumName) async {
    // This would typically query a stadiums table or external API
    // For now, return basic info with placeholder data
    return {
      'name': stadiumName,
      'image_url': null,
      'distance_km': null,
      'photo_count': 0,
    };
  }
}

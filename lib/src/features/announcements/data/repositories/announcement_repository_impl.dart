import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/announcement.dart';
import 'announcement_repository.dart';

class AnnouncementRepositoryImpl implements AnnouncementRepository {
  final SupabaseClient _supabaseClient;

  AnnouncementRepositoryImpl(this._supabaseClient);

  @override
  Future<void> createAnnouncement(Announcement announcement) async {
    try {
      // Only send fields that exist in the database table
      final data = {
        'created_by': announcement.createdBy,
        'title': announcement.title,
        'description': announcement.description,
        'date': announcement.date.toIso8601String().split('T')[0], // DATE format
        'time': '${announcement.time.hour.toString().padLeft(2, '0')}:${announcement.time.minute.toString().padLeft(2, '0')}:00', // TIME format
        'price': announcement.price,
        'stadium': announcement.stadium,
        'max_participants': announcement.maxParticipants,
        'needs_goalkeeper': announcement.needsGoalkeeper,
        'hired_goalkeeper_id': announcement.hiredGoalkeeperId,
        'hired_goalkeeper_name': announcement.hiredGoalkeeperName,
        'goalkeeper_price': announcement.goalkeeperPrice,
      };
      
      await _supabaseClient.from('announcements').insert(data);
    } catch (e) {
      throw Exception('Failed to create announcement: $e');
    }
  }

  @override
  Future<List<Announcement>> getAnnouncements() async {
    try {
      // First, get basic announcements data
      final response = await _supabaseClient
          .from('announcements')
          .select('*')
          .order('created_at', ascending: false);
      
      final announcements = <Announcement>[];
      
      for (final announcementData in response as List) {
        // Get organizer name
        String? organizerName;
        try {
          final userResponse = await _supabaseClient
              .from('users')
              .select('name')
              .eq('id', announcementData['created_by'])
              .single();
          organizerName = userResponse['name'];
        } catch (e) {
          organizerName = 'Unknown';
        }
        
        // Get participant count
        int participantCount = 0;
        try {
          final participantResponse = await _supabaseClient
              .from('announcement_participants')
              .select('id')
              .eq('announcement_id', announcementData['id']);
          participantCount = (participantResponse as List).length;
        } catch (e) {
          participantCount = 0;
        }
        
        // Get field information if stadium name matches a field
        String? fieldId;
        double? fieldLatitude;
        double? fieldLongitude;
        String? fieldPhotoUrl;
        
        if (announcementData['stadium'] != null) {
          try {
            final fieldResponse = await _supabaseClient
                .from('fields')
                .select('id, latitude, longitude, photo_url')
                .eq('name', announcementData['stadium'])
                .maybeSingle();
            
            if (fieldResponse != null) {
              fieldId = fieldResponse['id'];
              fieldLatitude = fieldResponse['latitude']?.toDouble();
              fieldLongitude = fieldResponse['longitude']?.toDouble();
              fieldPhotoUrl = fieldResponse['photo_url'];
            }
          } catch (e) {
            // Field not found or error, keep null values
          }
        }
        
        announcements.add(Announcement.fromJson({
          ...announcementData,
          'organizer_name': organizerName,
          'organizer_avatar_url': null,
          'organizer_rating': 4.5, // Default rating
          'participant_count': participantCount,
          'distance_km': 2.0, // Default distance
          'field_id': fieldId,
          'field_latitude': fieldLatitude,
          'field_longitude': fieldLongitude,
          'field_photo_url': fieldPhotoUrl,
        }));
      }
      
      return announcements;
    } catch (e) {
      print('Error fetching announcements: $e'); // Debug print
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
      // Get basic announcement data
      final response = await _supabaseClient
          .from('announcements')
          .select('*')
          .eq('id', id)
          .single();
      
      // Get organizer name separately
      String? organizerName;
      try {
        final userResponse = await _supabaseClient
            .from('users')
            .select('name')
            .eq('id', response['created_by'])
            .single();
        organizerName = userResponse['name'];
      } catch (e) {
        organizerName = 'Unknown';
      }
      
      // Get participants separately
      final participants = <AnnouncementParticipant>[];
      try {
        final participantsResponse = await _supabaseClient
            .from('announcement_participants')
            .select('user_id, created_at')
            .eq('announcement_id', id);
        
        for (final participantData in participantsResponse as List) {
          // Get participant name
          String participantName = 'Unknown';
          try {
            final participantUserResponse = await _supabaseClient
                .from('users')
                .select('name')
                .eq('id', participantData['user_id'])
                .single();
            participantName = participantUserResponse['name'] ?? 'Unknown';
          } catch (e) {
            // Keep default name
          }
          
          participants.add(AnnouncementParticipant.fromJson({
            'user_id': participantData['user_id'],
            'name': participantName,
            'avatar_url': null,
            'created_at': participantData['created_at'],
          }));
        }
      } catch (e) {
        // Keep empty participants list
      }
      
      // Get field information if stadium name matches a field
      String? fieldId;
      double? fieldLatitude;
      double? fieldLongitude;
      String? fieldPhotoUrl;
      
      if (response['stadium'] != null) {
        try {
          final fieldResponse = await _supabaseClient
              .from('fields')
              .select('id, latitude, longitude, photo_url')
              .eq('name', response['stadium'])
              .maybeSingle();
          
          if (fieldResponse != null) {
            fieldId = fieldResponse['id'];
            fieldLatitude = fieldResponse['latitude']?.toDouble();
            fieldLongitude = fieldResponse['longitude']?.toDouble();
            fieldPhotoUrl = fieldResponse['photo_url'];
          }
        } catch (e) {
          // Field not found or error, keep null values
        }
      }
      
      return Announcement.fromJson({
        ...response,
        'organizer_name': organizerName,
        'organizer_avatar_url': null,
        'organizer_rating': 4.5, // Default rating
        'participant_count': participants.length,
        'participants': participants.map((p) => p.toJson()).toList(),
        'distance_km': 2.0, // Default distance
        'field_id': fieldId,
        'field_latitude': fieldLatitude,
        'field_longitude': fieldLongitude,
        'field_photo_url': fieldPhotoUrl,
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

  @override
  Future<void> endGame(int announcementId) async {
    try {
      await _supabaseClient
          .from('announcements')
          .update({'status': 'completed'})
          .eq('id', announcementId);
    } catch (e) {
      throw Exception('Failed to end game: $e');
    }
  }
}

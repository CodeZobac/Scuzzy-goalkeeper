import 'package:supabase_flutter/supabase_flutter.dart';

class FieldEvent {
  final int id;
  final String title;
  final String? description;
  final DateTime date;
  final String time;
  final double? price;
  final int participantCount;
  final int maxParticipants;
  final String status;

  FieldEvent({
    required this.id,
    required this.title,
    this.description,
    required this.date,
    required this.time,
    this.price,
    required this.participantCount,
    required this.maxParticipants,
    required this.status,
  });

  factory FieldEvent.fromJson(Map<String, dynamic> json) {
    return FieldEvent(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      date: DateTime.parse(json['date']),
      time: json['time'],
      price: json['price']?.toDouble(),
      participantCount: json['participant_count'] ?? 0,
      maxParticipants: json['max_participants'] ?? 22,
      status: json['status'] ?? 'active',
    );
  }

  String get formattedDate {
    final months = [
      'JAN', 'FEV', 'MAR', 'ABR', 'MAI', 'JUN',
      'JUL', 'AGO', 'SET', 'OUT', 'NOV', 'DEZ'
    ];
    return '${months[date.month - 1]}\n${date.day}';
  }

  String get formattedTime {
    final timeParts = time.split(':');
    final hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  String get eventDetails {
    final slots = maxParticipants - participantCount;
    final level = participantCount < 10 ? 'Iniciantes' : 
                 participantCount < 18 ? 'Intermédio' : 'Avançado';
    return '$formattedTime - $slots vagas - $level';
  }
}

class FieldEventsService {
  final SupabaseClient _supabaseClient;

  FieldEventsService(this._supabaseClient);

  Future<List<FieldEvent>> getUpcomingEventsForField(String fieldName) async {
    try {
      final now = DateTime.now();
      final response = await _supabaseClient
          .from('announcements')
          .select('''
            id,
            title,
            description,
            date,
            time,
            price,
            max_participants,
            status
          ''')
          .eq('stadium', fieldName)
          .eq('status', 'active')
          .gte('date', now.toIso8601String().split('T')[0])
          .order('date', ascending: true)
          .order('time', ascending: true)
          .limit(5);

      final events = <FieldEvent>[];
      
      for (final eventData in response as List) {
        // Get participant count
        int participantCount = 0;
        try {
          final participantResponse = await _supabaseClient
              .from('announcement_participants')
              .select('id')
              .eq('announcement_id', eventData['id']);
          participantCount = (participantResponse as List).length;
        } catch (e) {
          participantCount = 0;
        }

        events.add(FieldEvent.fromJson({
          ...eventData,
          'participant_count': participantCount,
        }));
      }

      return events;
    } catch (e) {
      throw Exception('Failed to fetch upcoming events: $e');
    }
  }
}
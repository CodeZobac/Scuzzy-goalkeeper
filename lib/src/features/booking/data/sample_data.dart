import 'package:supabase_flutter/supabase_flutter.dart';

/// Sample data insertion script for testing the booking functionality
/// This should be run once to populate the database with test data
class SampleDataInsertion {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Inserts sample availability data for existing goalkeepers
  static Future<void> insertSampleAvailabilities() async {
    try {
      // Get all goalkeepers
      final goalkeepers = await _supabase
          .from('users')
          .select('id')
          .eq('is_goalkeeper', true);

      if (goalkeepers.isEmpty) {
        print('No goalkeepers found. Please add some goalkeepers first.');
        return;
      }

      // Sample availability data for the next 7 days
      final now = DateTime.now();
      final availabilities = <Map<String, dynamic>>[];

      for (final gk in goalkeepers) {
        final gkId = gk['id'];
        
        // Add availability for the next 7 days
        for (int i = 1; i <= 7; i++) {
          final date = now.add(Duration(days: i));
          
          // Morning session (9:00 - 12:00)
          availabilities.add({
            'goalkeeper_id': gkId,
            'day': date.toIso8601String().split('T')[0],
            'start-time': '09:00',
            'end-time': '12:00',
          });
          
          // Afternoon session (14:00 - 18:00)
          availabilities.add({
            'goalkeeper_id': gkId,
            'day': date.toIso8601String().split('T')[0],
            'start-time': '14:00',
            'end-time': '18:00',
          });
          
          // Evening session (19:00 - 22:00) - only on weekdays
          if (date.weekday <= 5) {
            availabilities.add({
              'goalkeeper_id': gkId,
              'day': date.toIso8601String().split('T')[0],
              'start-time': '19:00',
              'end-time': '22:00',
            });
          }
        }
      }

      // Insert all availabilities
      await _supabase.from('availabilities').insert(availabilities);
      print('Sample availabilities inserted successfully!');
      
    } catch (e) {
      print('Error inserting sample availabilities: $e');
    }
  }

  /// Inserts sample football field data
  static Future<void> insertSampleFields() async {
    try {
      final fields = [
        {
          'name': 'Campo Municipal de Lisboa',
          'latitude': 38.7223,
          'longitude': -9.1393,
          'photo_url': null,
          'status': 'approved',
        },
        {
          'name': 'Estádio José Alvalade XXI',
          'latitude': 38.7613,
          'longitude': -9.1611,
          'photo_url': null,
          'status': 'approved',
        },
        {
          'name': 'Campo do Benfica',
          'latitude': 38.7529,
          'longitude': -9.1845,
          'photo_url': null,
          'status': 'approved',
        },
        {
          'name': 'Complexo Desportivo do Porto',
          'latitude': 41.1579,
          'longitude': -8.6291,
          'photo_url': null,
          'status': 'approved',
        },
        {
          'name': 'Campo de Futebol de Coimbra',
          'latitude': 40.2033,
          'longitude': -8.4103,
          'photo_url': null,
          'status': 'approved',
        },
      ];

      await _supabase.from('fields').insert(fields);
      print('Sample fields inserted successfully!');
      
    } catch (e) {
      print('Error inserting sample fields: $e');
    }
  }

  /// Main method to insert all sample data
  static Future<void> insertAllSampleData() async {
    print('Inserting sample data...');
    await insertSampleFields();
    await insertSampleAvailabilities();
    print('All sample data inserted successfully!');
  }
}

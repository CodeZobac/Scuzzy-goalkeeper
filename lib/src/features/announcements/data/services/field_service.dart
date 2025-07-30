import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../map/data/models/real_field.dart';

class FieldService {
  final SupabaseClient _supabaseClient;

  FieldService(this._supabaseClient);

  Future<List<RealField>> getFields() async {
    try {
      final response = await _supabaseClient.from('fields').select();
      return (response as List)
          .map((data) => RealField.fromJson(data))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch fields: $e');
    }
  }
}

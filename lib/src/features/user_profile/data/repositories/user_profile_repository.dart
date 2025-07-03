import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user_profile.dart';

class UserProfileRepository {
  final _supabase = Supabase.instance.client;

  Future<UserProfile> getUserProfile() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    final response = await _supabase
        .from('users')
        .select()
        .eq('id', user.id)
        .single();

    return UserProfile.fromMap(response);
  }

  Future<void> updateUserProfile(UserProfile userProfile) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    await _supabase
        .from('users')
        .update(userProfile.toMap())
        .eq('id', user.id);
  }
}

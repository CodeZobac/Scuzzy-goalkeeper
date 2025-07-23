import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification_preferences.dart';

/// Repository for managing notification preferences
class NotificationPreferencesRepository {
  final SupabaseClient _supabaseClient;

  NotificationPreferencesRepository({SupabaseClient? supabaseClient})
      : _supabaseClient = supabaseClient ?? Supabase.instance.client;

  /// Get notification preferences for a user
  Future<NotificationPreferences?> getNotificationPreferences(String userId) async {
    try {
      final response = await _supabaseClient
          .from('notification_preferences')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) {
        // Create default preferences if none exist
        return await createDefaultPreferences(userId);
      }

      return NotificationPreferences.fromMap(response);
    } catch (e) {
      throw Exception('Failed to get notification preferences: $e');
    }
  }

  /// Create default notification preferences for a user
  Future<NotificationPreferences> createDefaultPreferences(String userId) async {
    try {
      final defaultPreferences = NotificationPreferences.defaultPreferences(userId);
      
      await _supabaseClient
          .from('notification_preferences')
          .insert(defaultPreferences.toMap());

      return defaultPreferences;
    } catch (e) {
      throw Exception('Failed to create default notification preferences: $e');
    }
  }

  /// Update notification preferences
  Future<NotificationPreferences> updateNotificationPreferences(
    NotificationPreferences preferences,
  ) async {
    try {
      final updatedPreferences = preferences.copyWith(updatedAt: DateTime.now());
      
      await _supabaseClient
          .from('notification_preferences')
          .upsert(updatedPreferences.toMap());

      return updatedPreferences;
    } catch (e) {
      throw Exception('Failed to update notification preferences: $e');
    }
  }

  /// Update specific notification type preference
  Future<NotificationPreferences> updateNotificationType({
    required String userId,
    required String notificationType,
    required bool enabled,
  }) async {
    try {
      final currentPreferences = await getNotificationPreferences(userId);
      if (currentPreferences == null) {
        throw Exception('Notification preferences not found');
      }

      NotificationPreferences updatedPreferences;
      
      switch (notificationType) {
        case 'contract_notifications':
          updatedPreferences = currentPreferences.copyWith(
            contractNotifications: enabled,
            updatedAt: DateTime.now(),
          );
          break;
        case 'full_lobby_notifications':
          updatedPreferences = currentPreferences.copyWith(
            fullLobbyNotifications: enabled,
            updatedAt: DateTime.now(),
          );
          break;
        case 'general_notifications':
          updatedPreferences = currentPreferences.copyWith(
            generalNotifications: enabled,
            updatedAt: DateTime.now(),
          );
          break;
        case 'push_notifications_enabled':
          updatedPreferences = currentPreferences.copyWith(
            pushNotificationsEnabled: enabled,
            updatedAt: DateTime.now(),
          );
          break;
        default:
          throw Exception('Unknown notification type: $notificationType');
      }

      return await updateNotificationPreferences(updatedPreferences);
    } catch (e) {
      throw Exception('Failed to update notification type: $e');
    }
  }

  /// Check if a specific notification type is enabled for a user
  Future<bool> isNotificationTypeEnabled({
    required String userId,
    required String notificationType,
  }) async {
    try {
      final preferences = await getNotificationPreferences(userId);
      if (preferences == null) {
        return true; // Default to enabled if no preferences found
      }

      return preferences.isNotificationTypeEnabled(notificationType);
    } catch (e) {
      throw Exception('Failed to check notification type status: $e');
    }
  }

  /// Watch notification preferences changes in real-time
  Stream<NotificationPreferences?> watchNotificationPreferences(String userId) {
    return _supabaseClient
        .from('notification_preferences')
        .stream(primaryKey: ['user_id'])
        .eq('user_id', userId)
        .map((data) {
          if (data.isEmpty) return null;
          return NotificationPreferences.fromMap(data.first);
        });
  }

  /// Reset notification preferences to default
  Future<NotificationPreferences> resetToDefaults(String userId) async {
    try {
      final defaultPreferences = NotificationPreferences.defaultPreferences(userId);
      
      await _supabaseClient
          .from('notification_preferences')
          .upsert(defaultPreferences.toMap());

      return defaultPreferences;
    } catch (e) {
      throw Exception('Failed to reset notification preferences: $e');
    }
  }

  /// Delete notification preferences (used when user deletes account)
  Future<void> deleteNotificationPreferences(String userId) async {
    try {
      await _supabaseClient
          .from('notification_preferences')
          .delete()
          .eq('user_id', userId);
    } catch (e) {
      throw Exception('Failed to delete notification preferences: $e');
    }
  }
}
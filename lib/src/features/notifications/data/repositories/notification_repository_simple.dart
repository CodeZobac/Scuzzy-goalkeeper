import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification.dart';
import '../models/notification_category.dart';

/// Simple notification repository for web compilation
class NotificationRepository {
  final SupabaseClient _supabase;

  NotificationRepository({SupabaseClient? supabaseClient})
      : _supabase = supabaseClient ?? Supabase.instance.client;

  /// Get user notifications
  Future<List<AppNotification>> getUserNotifications(String userId) async {
    try {
      final response = await _supabase
          .from('notifications')
          .select('*')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List<dynamic>)
          .map((json) => AppNotification.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error getting user notifications: $e');
      return [];
    }
  }

  /// Get unread notifications count
  Future<int> getUnreadNotificationsCount(String userId) async {
    try {
      final response = await _supabase
          .from('notifications')
          .select('id')
          .eq('user_id', userId)
          .isFilter('read_at', null);

      return (response as List).length;
    } catch (e) {
      debugPrint('Error getting unread count: $e');
      return 0;
    }
  }

  /// Mark notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _supabase
          .from('notifications')
          .update({'read_at': DateTime.now().toIso8601String()})
          .eq('id', notificationId);
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  /// Mark all notifications as read
  Future<void> markAllNotificationsAsRead(String userId) async {
    try {
      await _supabase
          .from('notifications')
          .update({'read_at': DateTime.now().toIso8601String()})
          .eq('user_id', userId)
          .isFilter('read_at', null);
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
    }
  }

  /// Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _supabase
          .from('notifications')
          .delete()
          .eq('id', notificationId);
    } catch (e) {
      debugPrint('Error deleting notification: $e');
    }
  }

  /// Create notification
  Future<void> createNotification({
    required String userId,
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    try {
      await _supabase.from('notifications').insert({
        'user_id': userId,
        'title': title,
        'body': body,
        'type': type,
        'data': data,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error creating notification: $e');
    }
  }

  /// Listen to user notifications (simplified)
  Stream<List<AppNotification>> listenToUserNotifications(String userId) {
    return _supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .map((data) => data
            .map((json) => AppNotification.fromJson(json))
            .toList());
  }

  // Placeholder methods for compatibility
  Future<List<AppNotification>> getUserNotificationsPaginated(
    String userId, {
    int limit = 20,
    int offset = 0,
    String? searchQuery,
    NotificationCategory? category,
    bool includeArchived = false,
  }) async {
    return getUserNotifications(userId);
  }

  Future<int> getUserNotificationsCount(
    String userId, {
    String? searchQuery,
    NotificationCategory? category,
    bool includeArchived = false,
  }) async {
    return getUnreadNotificationsCount(userId);
  }

  Future<void> markAllNotificationsAsReadByCategory(
    String userId,
    NotificationCategory category,
  ) async {
    await markAllNotificationsAsRead(userId);
  }

  Future<void> markNotificationAsReadOnView(String notificationId) async {
    await markNotificationAsRead(notificationId);
  }

  Future<void> archiveOldNotifications(String userId) async {
    // Placeholder implementation
  }

  Future<void> deleteNotifications(List<String> notificationIds) async {
    for (final id in notificationIds) {
      await deleteNotification(id);
    }
  }

  Future<void> deleteAllNotifications(String userId) async {
    try {
      await _supabase
          .from('notifications')
          .delete()
          .eq('user_id', userId);
    } catch (e) {
      debugPrint('Error deleting all notifications: $e');
    }
  }

  Future<void> deleteNotificationsByCategory(
    String userId,
    NotificationCategory category,
  ) async {
    await deleteAllNotifications(userId);
  }

  Future<List<AppNotification>> getArchivedNotifications(
    String userId, {
    int limit = 20,
    int offset = 0,
    String? searchQuery,
    NotificationCategory? category,
  }) async {
    return [];
  }

  Future<void> cleanupArchivedNotifications(
    String userId, {
    int olderThanDays = 90,
  }) async {
    // Placeholder implementation
  }

  Future<void> restoreArchivedNotification(String notificationId) async {
    // Placeholder implementation
  }

  Future<List<AppNotification>> getNotificationsAdvanced(
    String userId, {
    int limit = 20,
    int offset = 0,
    String? searchQuery,
    NotificationCategory? category,
    bool includeArchived = false,
    String sortBy = 'created_at',
    bool ascending = false,
    DateTime? dateFrom,
    DateTime? dateTo,
    bool? readStatus,
  }) async {
    return getUserNotifications(userId);
  }

  Future<int> getNotificationsCountAdvanced(
    String userId, {
    String? searchQuery,
    NotificationCategory? category,
    bool includeArchived = false,
    DateTime? dateFrom,
    DateTime? dateTo,
    bool? readStatus,
  }) async {
    return getUnreadNotificationsCount(userId);
  }

  Future<List<AppNotification>> getBookingNotifications(String bookingId) async {
    return [];
  }
}
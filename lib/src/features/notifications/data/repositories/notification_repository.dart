import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification.dart';

class NotificationRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Gets all notifications for a user
  Future<List<AppNotification>> getUserNotifications(String userId) async {
    try {
      final response = await _supabase
          .from('notifications')
          .select('*')
          .eq('user_id', userId)
          .order('sent_at', ascending: false);

      return response
          .map<AppNotification>((data) => AppNotification.fromMap(data))
          .toList();
    } catch (e) {
      throw Exception('Erro ao carregar notificações: $e');
    }
  }

  /// Gets unread notifications count for a user
  Future<int> getUnreadNotificationsCount(String userId) async {
    try {
      final response = await _supabase
          .from('notifications')
          .select('id')
          .eq('user_id', userId)
          .isFilter('read_at', null);

      return response.length;
    } catch (e) {
      throw Exception('Erro ao contar notificações não lidas: $e');
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
      throw Exception('Erro ao marcar notificação como lida: $e');
    }
  }

  /// Mark all notifications as read for a user
  Future<void> markAllNotificationsAsRead(String userId) async {
    try {
      await _supabase
          .from('notifications')
          .update({'read_at': DateTime.now().toIso8601String()})
          .eq('user_id', userId)
          .isFilter('read_at', null);
    } catch (e) {
      throw Exception('Erro ao marcar todas notificações como lidas: $e');
    }
  }

  /// Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _supabase
          .from('notifications')
          .delete()
          .eq('id', notificationId);
    } catch (e) {
      throw Exception('Erro ao eliminar notificação: $e');
    }
  }

  /// Get notifications for a specific booking
  Future<List<AppNotification>> getBookingNotifications(String bookingId) async {
    try {
      final response = await _supabase
          .from('notifications')
          .select('*')
          .eq('booking_id', bookingId)
          .order('sent_at', ascending: false);

      return response
          .map<AppNotification>((data) => AppNotification.fromMap(data))
          .toList();
    } catch (e) {
      throw Exception('Erro ao carregar notificações do agendamento: $e');
    }
  }

  /// Listen to real-time notifications for a user
  Stream<AppNotification> listenToUserNotifications(String userId) {
    return _supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('sent_at', ascending: false)
        .map((List<Map<String, dynamic>> data) {
          return data.map((item) => AppNotification.fromMap(item)).first;
        });
  }

  /// Save FCM token for a user
  Future<void> saveFCMToken({
    required String userId,
    required String token,
    String? deviceId,
    required String platform,
  }) async {
    try {
      await _supabase.from('fcm_tokens').upsert({
        'user_id': userId,
        'token': token,
        'device_id': deviceId,
        'platform': platform,
        'is_active': true,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Erro ao guardar token FCM: $e');
    }
  }

  /// Disable FCM token for a user
  Future<void> disableFCMToken(String userId, String token) async {
    try {
      await _supabase
          .from('fcm_tokens')
          .update({'is_active': false})
          .eq('user_id', userId)
          .eq('token', token);
    } catch (e) {
      throw Exception('Erro ao desativar token FCM: $e');
    }
  }

  /// Get active FCM tokens for a user
  Future<List<String>> getUserFCMTokens(String userId) async {
    try {
      final response = await _supabase
          .from('fcm_tokens')
          .select('token')
          .eq('user_id', userId)
          .eq('is_active', true);

      return response.map<String>((data) => data['token'] as String).toList();
    } catch (e) {
      throw Exception('Erro ao carregar tokens FCM: $e');
    }
  }
}

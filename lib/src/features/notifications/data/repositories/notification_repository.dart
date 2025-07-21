import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification.dart';
import '../models/contract_notification_data.dart';
import '../models/full_lobby_notification_data.dart';
import '../models/notification_category.dart';

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

  /// Create a contract notification for goalkeeper contract requests
  Future<void> createContractNotification({
    required String goalkeeperUserId,
    required String contractorUserId,
    required String announcementId,
    required ContractNotificationData data,
  }) async {
    try {
      // First create the contract record
      final contractResponse = await _supabase
          .from('goalkeeper_contracts')
          .insert({
            'announcement_id': announcementId,
            'goalkeeper_user_id': goalkeeperUserId,
            'contractor_user_id': contractorUserId,
            'offered_amount': data.offeredAmount,
            'additional_notes': data.additionalNotes,
            'status': 'pending',
            'expires_at': DateTime.now().add(const Duration(hours: 24)).toIso8601String(),
          })
          .select()
          .single();

      // Update the contract data with the generated contract ID
      final updatedData = data.copyWith(contractId: contractResponse['id']);

      // Create the notification
      await _supabase.from('notifications').insert({
        'user_id': goalkeeperUserId,
        'title': 'Nova Proposta de Contrato',
        'body': '${data.contractorName} quer contratá-lo para um jogo',
        'type': 'contract_request',
        'data': updatedData.toMap(),
        'category': 'contracts',
        'requires_action': true,
        'expires_at': DateTime.now().add(const Duration(hours: 24)).toIso8601String(),
        'sent_at': DateTime.now().toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Erro ao criar notificação de contrato: $e');
    }
  }

  /// Create a full lobby notification for full announcement notifications
  Future<void> createFullLobbyNotification({
    required String creatorUserId,
    required String announcementId,
    required FullLobbyNotificationData data,
  }) async {
    try {
      await _supabase.from('notifications').insert({
        'user_id': creatorUserId,
        'title': 'Lobby Completo!',
        'body': 'Seu anúncio "${data.announcementTitle}" está completo ${data.participantCountDisplay}',
        'type': 'full_lobby',
        'data': data.toMap(),
        'category': 'full_lobbies',
        'requires_action': false,
        'sent_at': DateTime.now().toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Erro ao criar notificação de lobby completo: $e');
    }
  }

  /// Handle contract response for accept/decline actions
  Future<void> handleContractResponse({
    required String notificationId,
    required String contractId,
    required bool accepted,
  }) async {
    try {
      // Update the contract status
      await _supabase
          .from('goalkeeper_contracts')
          .update({
            'status': accepted ? 'accepted' : 'declined',
            'responded_at': DateTime.now().toIso8601String(),
          })
          .eq('id', contractId);

      // Mark the notification as having action taken
      await _supabase
          .from('notifications')
          .update({
            'action_taken_at': DateTime.now().toIso8601String(),
            'read_at': DateTime.now().toIso8601String(),
          })
          .eq('id', notificationId);

      // If accepted, create a confirmation notification for the contractor
      if (accepted) {
        final contractData = await _supabase
            .from('goalkeeper_contracts')
            .select('''
              *,
              goalkeeper:goalkeeper_user_id(id, name, avatar_url),
              announcement:announcement_id(title, game_date, stadium)
            ''')
            .eq('id', contractId)
            .single();

        await _supabase.from('notifications').insert({
          'user_id': contractData['contractor_user_id'],
          'title': 'Contrato Aceito!',
          'body': '${contractData['goalkeeper']['name']} aceitou seu contrato',
          'type': 'contract_accepted',
          'data': {
            'contract_id': contractId,
            'goalkeeper_name': contractData['goalkeeper']['name'],
            'announcement_title': contractData['announcement']['title'],
          },
          'category': 'contracts',
          'requires_action': false,
          'sent_at': DateTime.now().toIso8601String(),
          'created_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      throw Exception('Erro ao processar resposta do contrato: $e');
    }
  }

  /// Get notifications by category for filtered notifications
  Future<List<AppNotification>> getNotificationsByCategory(
    String userId,
    NotificationCategory category,
  ) async {
    try {
      final response = await _supabase
          .from('notifications')
          .select('*')
          .eq('user_id', userId)
          .eq('category', category.value)
          .order('sent_at', ascending: false);

      return response
          .map<AppNotification>((data) => AppNotification.fromMap(data))
          .toList();
    } catch (e) {
      throw Exception('Erro ao carregar notificações por categoria: $e');
    }
  }

  /// Create watchNotifications stream for real-time updates
  Stream<List<AppNotification>> watchNotifications(String userId) {
    return _supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('sent_at', ascending: false)
        .map((List<Map<String, dynamic>> data) {
          return data.map((item) => AppNotification.fromMap(item)).toList();
        });
  }
}

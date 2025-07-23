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
      return await getUserNotificationsNonArchived(userId);
    } catch (e) {
      throw Exception('Erro ao carregar notificações: $e');
    }
  }

  /// Gets paginated notifications for a user
  Future<List<AppNotification>> getUserNotificationsPaginated(
    String userId, {
    int limit = 20,
    int offset = 0,
    String? searchQuery,
    NotificationCategory? category,
    bool includeArchived = false,
  }) async {
    try {
      var query = _supabase
          .from('notifications')
          .select('*')
          .eq('user_id', userId);

      // Filter by archived status
      if (!includeArchived) {
        query = query.isFilter('archived_at', null);
      }

      // Filter by category
      if (category != null) {
        query = query.eq('category', category.value);
      }

      // Search functionality
      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.or('title.ilike.%$searchQuery%,body.ilike.%$searchQuery%');
      }

      // Apply pagination and ordering
      final response = await query
          .order('sent_at', ascending: false)
          .range(offset, offset + limit - 1);

      return response
          .map<AppNotification>((data) => AppNotification.fromMap(data))
          .toList();
    } catch (e) {
      throw Exception('Erro ao carregar notificações paginadas: $e');
    }
  }

  /// Gets total count of notifications for pagination
  Future<int> getUserNotificationsCount(
    String userId, {
    String? searchQuery,
    NotificationCategory? category,
    bool includeArchived = false,
  }) async {
    try {
      var query = _supabase
          .from('notifications')
          .select('id')
          .eq('user_id', userId);

      // Filter by archived status
      if (!includeArchived) {
        query = query.isFilter('archived_at', null);
      }

      // Filter by category
      if (category != null) {
        query = query.eq('category', category.value);
      }

      // Search functionality
      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.or('title.ilike.%$searchQuery%,body.ilike.%$searchQuery%');
      }

      final response = await query;
      return response.length;
    } catch (e) {
      throw Exception('Erro ao contar notificações: $e');
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

  /// Mark all notifications as read for a specific category
  Future<void> markAllNotificationsAsReadByCategory(String userId, NotificationCategory category) async {
    try {
      await _supabase
          .from('notifications')
          .update({'read_at': DateTime.now().toIso8601String()})
          .eq('user_id', userId)
          .eq('category', category.value)
          .isFilter('read_at', null);
    } catch (e) {
      throw Exception('Erro ao marcar notificações da categoria como lidas: $e');
    }
  }

  /// Get unread notifications count for a specific category
  Future<int> getUnreadNotificationsCountByCategory(String userId, NotificationCategory category) async {
    try {
      final response = await _supabase
          .from('notifications')
          .select('id')
          .eq('user_id', userId)
          .eq('category', category.value)
          .isFilter('read_at', null);

      return response.length;
    } catch (e) {
      throw Exception('Erro ao contar notificações não lidas da categoria: $e');
    }
  }

  /// Archive old notifications (older than 30 days)
  Future<void> archiveOldNotifications(String userId) async {
    try {
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      
      await _supabase
          .from('notifications')
          .update({'archived_at': DateTime.now().toIso8601String()})
          .eq('user_id', userId)
          .lt('created_at', thirtyDaysAgo.toIso8601String())
          .isFilter('archived_at', null);
    } catch (e) {
      throw Exception('Erro ao arquivar notificações antigas: $e');
    }
  }

  /// Get non-archived notifications for a user
  Future<List<AppNotification>> getUserNotificationsNonArchived(String userId) async {
    try {
      final response = await _supabase
          .from('notifications')
          .select('*')
          .eq('user_id', userId)
          .isFilter('archived_at', null)
          .order('sent_at', ascending: false);

      return response
          .map<AppNotification>((data) => AppNotification.fromMap(data))
          .toList();
    } catch (e) {
      throw Exception('Erro ao carregar notificações: $e');
    }
  }

  /// Automatically mark notification as read when viewed
  Future<void> markNotificationAsReadOnView(String notificationId) async {
    try {
      // Only update if not already read
      await _supabase
          .from('notifications')
          .update({'read_at': DateTime.now().toIso8601String()})
          .eq('id', notificationId)
          .isFilter('read_at', null);
    } catch (e) {
      throw Exception('Erro ao marcar notificação como lida: $e');
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

  /// Listen to real-time notifications for a user (deprecated - use NotificationRealtimeService)
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

  /// Get real-time notifications stream with better error handling
  Stream<List<AppNotification>> getNotificationsStream(String userId) {
    return _supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('sent_at', ascending: false)
        .map((List<Map<String, dynamic>> data) {
          return data.map((item) => AppNotification.fromMap(item)).toList();
        })
        .handleError((error) {
          throw Exception('Erro no stream de notificações: $error');
        });
  }

  /// Get real-time unread count stream
  Stream<int> getUnreadCountStream(String userId) {
    return _supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .map((List<Map<String, dynamic>> data) {
          // Filter unread notifications in memory since stream doesn't support isFilter
          return data.where((item) => item['read_at'] == null).length;
        })
        .handleError((error) {
          throw Exception('Erro no stream de contagem não lida: $error');
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

  /// Get notifications with advanced filtering and sorting options
  Future<List<AppNotification>> getNotificationsAdvanced(
    String userId, {
    int limit = 20,
    int offset = 0,
    String? searchQuery,
    NotificationCategory? category,
    bool includeArchived = false,
    String sortBy = 'sent_at',
    bool ascending = false,
    DateTime? dateFrom,
    DateTime? dateTo,
    bool? readStatus, // null = all, true = read only, false = unread only
  }) async {
    try {
      var query = _supabase
          .from('notifications')
          .select('*')
          .eq('user_id', userId);

      // Filter by archived status
      if (!includeArchived) {
        query = query.isFilter('archived_at', null);
      }

      // Filter by category
      if (category != null) {
        query = query.eq('category', category.value);
      }

      // Filter by read status
      if (readStatus != null) {
        if (readStatus) {
          query = query.not('read_at', 'is', null);
        } else {
          query = query.isFilter('read_at', null);
        }
      }

      // Date range filtering
      if (dateFrom != null) {
        query = query.gte('sent_at', dateFrom.toIso8601String());
      }
      if (dateTo != null) {
        query = query.lte('sent_at', dateTo.toIso8601String());
      }

      // Search functionality with improved matching
      if (searchQuery != null && searchQuery.isNotEmpty) {
        // Search in title, body, and data fields
        query = query.or(
          'title.ilike.%$searchQuery%,'
          'body.ilike.%$searchQuery%,'
          'data->>contractor_name.ilike.%$searchQuery%,'
          'data->>announcement_title.ilike.%$searchQuery%,'
          'data->>stadium.ilike.%$searchQuery%'
        );
      }

      // Apply sorting and pagination
      final response = await query
          .order(sortBy, ascending: ascending)
          .range(offset, offset + limit - 1);

      return response
          .map<AppNotification>((data) => AppNotification.fromMap(data))
          .toList();
    } catch (e) {
      throw Exception('Erro ao carregar notificações avançadas: $e');
    }
  }

  /// Get total count with advanced filtering
  Future<int> getNotificationsCountAdvanced(
    String userId, {
    String? searchQuery,
    NotificationCategory? category,
    bool includeArchived = false,
    DateTime? dateFrom,
    DateTime? dateTo,
    bool? readStatus,
  }) async {
    try {
      var query = _supabase
          .from('notifications')
          .select('id')
          .eq('user_id', userId);

      // Apply same filters as getNotificationsAdvanced
      if (!includeArchived) {
        query = query.isFilter('archived_at', null);
      }

      if (category != null) {
        query = query.eq('category', category.value);
      }

      if (readStatus != null) {
        if (readStatus) {
          query = query.not('read_at', 'is', null);
        } else {
          query = query.isFilter('read_at', null);
        }
      }

      if (dateFrom != null) {
        query = query.gte('sent_at', dateFrom.toIso8601String());
      }
      if (dateTo != null) {
        query = query.lte('sent_at', dateTo.toIso8601String());
      }

      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.or(
          'title.ilike.%$searchQuery%,'
          'body.ilike.%$searchQuery%,'
          'data->>contractor_name.ilike.%$searchQuery%,'
          'data->>announcement_title.ilike.%$searchQuery%,'
          'data->>stadium.ilike.%$searchQuery%'
        );
      }

      final response = await query;
      return response.length;
    } catch (e) {
      throw Exception('Erro ao contar notificações avançadas: $e');
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

  /// Delete multiple notifications by IDs
  Future<void> deleteNotifications(List<String> notificationIds) async {
    try {
      await _supabase
          .from('notifications')
          .delete()
          .inFilter('id', notificationIds);
    } catch (e) {
      throw Exception('Erro ao eliminar notificações: $e');
    }
  }

  /// Delete all notifications for a user (with confirmation)
  Future<void> deleteAllNotifications(String userId) async {
    try {
      await _supabase
          .from('notifications')
          .delete()
          .eq('user_id', userId);
    } catch (e) {
      throw Exception('Erro ao eliminar todas as notificações: $e');
    }
  }

  /// Delete notifications by category
  Future<void> deleteNotificationsByCategory(String userId, NotificationCategory category) async {
    try {
      await _supabase
          .from('notifications')
          .delete()
          .eq('user_id', userId)
          .eq('category', category.value);
    } catch (e) {
      throw Exception('Erro ao eliminar notificações da categoria: $e');
    }
  }

  /// Get archived notifications for history view
  Future<List<AppNotification>> getArchivedNotifications(
    String userId, {
    int limit = 20,
    int offset = 0,
    String? searchQuery,
    NotificationCategory? category,
  }) async {
    try {
      var query = _supabase
          .from('notifications')
          .select('*')
          .eq('user_id', userId)
          .not('archived_at', 'is', null);

      // Filter by category
      if (category != null) {
        query = query.eq('category', category.value);
      }

      // Search functionality
      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.or('title.ilike.%$searchQuery%,body.ilike.%$searchQuery%');
      }

      // Apply pagination and ordering
      final response = await query
          .order('archived_at', ascending: false)
          .range(offset, offset + limit - 1);

      return response
          .map<AppNotification>((data) => AppNotification.fromMap(data))
          .toList();
    } catch (e) {
      throw Exception('Erro ao carregar notificações arquivadas: $e');
    }
  }

  /// Permanently delete archived notifications older than specified days
  Future<void> cleanupArchivedNotifications(String userId, {int olderThanDays = 90}) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: olderThanDays));
      
      await _supabase
          .from('notifications')
          .delete()
          .eq('user_id', userId)
          .not('archived_at', 'is', null)
          .lt('archived_at', cutoffDate.toIso8601String());
    } catch (e) {
      throw Exception('Erro ao limpar notificações arquivadas: $e');
    }
  }

  /// Restore archived notification
  Future<void> restoreArchivedNotification(String notificationId) async {
    try {
      await _supabase
          .from('notifications')
          .update({'archived_at': null})
          .eq('id', notificationId);
    } catch (e) {
      throw Exception('Erro ao restaurar notificação: $e');
    }
  }
}

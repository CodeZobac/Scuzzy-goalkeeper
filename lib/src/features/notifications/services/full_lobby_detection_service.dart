import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../announcements/data/models/announcement.dart';
import '../data/models/full_lobby_notification_data.dart';
import '../data/repositories/notification_repository.dart';

/// Service responsible for monitoring announcement participant counts
/// and triggering full lobby notifications when capacity is reached
class FullLobbyDetectionService {
  final SupabaseClient? _supabase;
  final NotificationRepository? _notificationRepository;
  
  // Track processed announcements to prevent duplicate notifications
  final Set<int> _processedFullLobbies = <int>{};
  
  // Real-time subscription for participant changes
  RealtimeChannel? _participantChannel;
  
  // Timer for periodic checks (fallback mechanism)
  Timer? _periodicCheckTimer;
  
  // Track announcement statuses
  final Map<int, AnnouncementStatus> _announcementStatuses = {};

  FullLobbyDetectionService(this._notificationRepository, [this._supabase]);

  /// Initialize the full lobby detection system
  Future<void> initialize() async {
    try {
      debugPrint('Initializing FullLobbyDetectionService...');
      
      // Load existing full lobby statuses to prevent duplicates
      await _loadExistingFullLobbies();
      
      // Set up real-time monitoring
      await _setupRealtimeMonitoring();
      
      // Set up periodic fallback checks (every 30 seconds)
      _setupPeriodicChecks();
      
      debugPrint('FullLobbyDetectionService initialized successfully');
    } catch (e) {
      debugPrint('Error initializing FullLobbyDetectionService: $e');
      rethrow;
    }
  }

  /// Load existing full lobbies from database to prevent duplicate notifications
  Future<void> _loadExistingFullLobbies() async {
    if (_supabase == null) return;
    
    try {
      // Get all announcements that already have full lobby notifications
      final existingNotifications = await _supabase!
          .from('notifications')
          .select('data')
          .eq('type', 'full_lobby');

      for (final notification in existingNotifications) {
        final data = notification['data'] as Map<String, dynamic>?;
        if (data != null && data['announcement_id'] != null) {
          final announcementId = int.tryParse(data['announcement_id'].toString());
          if (announcementId != null) {
            _processedFullLobbies.add(announcementId);
            _announcementStatuses[announcementId] = AnnouncementStatus.full;
          }
        }
      }
      
      debugPrint('Loaded ${_processedFullLobbies.length} existing full lobby notifications');
    } catch (e) {
      debugPrint('Error loading existing full lobbies: $e');
    }
  }

  /// Set up real-time monitoring for participant changes
  Future<void> _setupRealtimeMonitoring() async {
    if (_supabase == null) return;
    
    try {
      _participantChannel = _supabase!
          .channel('announcement_participants_monitor')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'announcement_participants',
            callback: _handleParticipantChange,
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.delete,
            schema: 'public',
            table: 'announcement_participants',
            callback: _handleParticipantChange,
          );

      await _participantChannel!.subscribe();
      debugPrint('Real-time participant monitoring set up successfully');
    } catch (e) {
      debugPrint('Error setting up real-time monitoring: $e');
    }
  }

  /// Set up periodic checks as fallback mechanism
  void _setupPeriodicChecks() {
    _periodicCheckTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _performPeriodicCheck(),
    );
    debugPrint('Periodic checks set up (every 30 seconds)');
  }

  /// Handle participant count changes from real-time events
  void _handleParticipantChange(PostgresChangePayload payload) async {
    try {
      final announcementId = payload.newRecord['announcement_id'] as int?;
      if (announcementId == null) return;

      debugPrint('Participant change detected for announcement $announcementId');
      
      // Check if this announcement reached full capacity
      await _checkAnnouncementCapacity(announcementId);
    } catch (e) {
      debugPrint('Error handling participant change: $e');
    }
  }

  /// Perform periodic check for full lobbies (fallback mechanism)
  Future<void> _performPeriodicCheck() async {
    if (_supabase == null) return;
    
    try {
      debugPrint('Performing periodic full lobby check...');
      
      // Get all active announcements that haven't been processed yet
      final announcements = await _supabase!
          .from('announcements')
          .select('id, created_by, title, date, time, stadium, max_participants')
          .gte('date', DateTime.now().toIso8601String().split('T')[0])
          .order('created_at', ascending: false);

      for (final announcementData in announcements) {
        final announcementId = announcementData['id'] as int;
        
        // Skip if already processed
        if (_processedFullLobbies.contains(announcementId)) continue;
        
        await _checkAnnouncementCapacity(announcementId);
      }
    } catch (e) {
      debugPrint('Error in periodic check: $e');
    }
  }

  /// Check if an announcement has reached full capacity
  Future<void> _checkAnnouncementCapacity(int announcementId) async {
    if (_supabase == null) return;
    
    try {
      // Skip if already processed
      if (_processedFullLobbies.contains(announcementId)) return;

      // Get announcement details
      final announcementResponse = await _supabase!
          .from('announcements')
          .select('*')
          .eq('id', announcementId)
          .single();

      // Get current participant count
      final participantResponse = await _supabase!
          .from('announcement_participants')
          .select('user_id')
          .eq('announcement_id', announcementId);

      final participantCount = participantResponse.length;
      final maxParticipants = announcementResponse['max_participants'] ?? 22;
      
      debugPrint('Announcement $announcementId: $participantCount/$maxParticipants participants');

      // Update announcement status
      final previousStatus = _announcementStatuses[announcementId];
      final currentStatus = participantCount >= maxParticipants 
          ? AnnouncementStatus.full 
          : AnnouncementStatus.active;
      
      _announcementStatuses[announcementId] = currentStatus;

      // Check if announcement just became full
      if (currentStatus == AnnouncementStatus.full && 
          previousStatus != AnnouncementStatus.full) {
        
        await _triggerFullLobbyNotification(
          announcementId: announcementId,
          announcementData: announcementResponse,
          participantCount: participantCount,
          maxParticipants: maxParticipants,
        );
      }
    } catch (e) {
      debugPrint('Error checking announcement capacity for $announcementId: $e');
    }
  }

  /// Trigger full lobby notification for an announcement
  Future<void> _triggerFullLobbyNotification({
    required int announcementId,
    required Map<String, dynamic> announcementData,
    required int participantCount,
    required int maxParticipants,
  }) async {
    try {
      // Prevent duplicate notifications
      if (_processedFullLobbies.contains(announcementId)) {
        debugPrint('Full lobby notification already sent for announcement $announcementId');
        return;
      }

      final creatorUserId = announcementData['created_by'] as String;
      final title = announcementData['title'] as String;
      final stadium = announcementData['stadium'] as String? ?? 'Local não especificado';
      
      // Parse game date and time
      final gameDate = DateTime.parse(announcementData['date']);
      final timeString = announcementData['time'] as String;
      final timeParts = timeString.split(':');
      final gameDateTime = DateTime(
        gameDate.year,
        gameDate.month,
        gameDate.day,
        int.parse(timeParts[0]),
        int.parse(timeParts[1]),
      );

      // Create full lobby notification data
      final fullLobbyData = FullLobbyNotificationData(
        announcementId: announcementId.toString(),
        announcementTitle: title,
        gameDateTime: gameDateTime,
        stadium: stadium,
        participantCount: participantCount,
        maxParticipants: maxParticipants,
      );

      // Send notification
      await _notificationRepository?.createFullLobbyNotification(
        creatorUserId: creatorUserId,
        announcementId: announcementId.toString(),
        data: fullLobbyData,
      );

      // Mark as processed to prevent duplicates
      _processedFullLobbies.add(announcementId);
      
      debugPrint('Full lobby notification sent for announcement $announcementId');
      
      // Also send push notification if FCM tokens are available
      await _sendPushNotification(
        userId: creatorUserId,
        title: 'Lobby Completo!',
        body: 'O seu anúncio "$title" está completo ($participantCount/$maxParticipants)',
        data: fullLobbyData.toMap(),
      );
      
    } catch (e) {
      debugPrint('Error triggering full lobby notification: $e');
      rethrow;
    }
  }

  /// Send push notification for full lobby
  Future<void> _sendPushNotification({
    required String userId,
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) async {
    if (_supabase == null) return;
    
    try {
      // Get user's FCM tokens
      final tokens = await _supabase!
          .from('fcm_tokens')
          .select('token')
          .eq('user_id', userId)
          .eq('is_active', true);

      if (tokens.isEmpty) {
        debugPrint('No active FCM tokens found for user $userId');
        return;
      }

      // Here you would integrate with your push notification service
      // For now, we'll just log the intent
      debugPrint('Would send push notification to ${tokens.length} devices for user $userId');
      debugPrint('Title: $title');
      debugPrint('Body: $body');
      
      // TODO: Integrate with Firebase Cloud Functions or your push service
      // to actually send the push notifications
      
    } catch (e) {
      debugPrint('Error sending push notification: $e');
    }
  }

  /// Get announcement status
  AnnouncementStatus? getAnnouncementStatus(int announcementId) {
    return _announcementStatuses[announcementId];
  }

  /// Check if announcement has been processed for full lobby notification
  bool isAnnouncementProcessed(int announcementId) {
    return _processedFullLobbies.contains(announcementId);
  }

  /// Manually trigger check for a specific announcement (for testing)
  Future<void> checkAnnouncement(int announcementId) async {
    await _checkAnnouncementCapacity(announcementId);
  }

  /// Get statistics about monitored announcements
  Map<String, dynamic> getStatistics() {
    return {
      'processed_full_lobbies': _processedFullLobbies.length,
      'tracked_announcements': _announcementStatuses.length,
      'full_announcements': _announcementStatuses.values
          .where((status) => status == AnnouncementStatus.full)
          .length,
      'active_announcements': _announcementStatuses.values
          .where((status) => status == AnnouncementStatus.active)
          .length,
    };
  }

  /// Dispose of resources
  void dispose() {
    _participantChannel?.unsubscribe();
    _periodicCheckTimer?.cancel();
    debugPrint('FullLobbyDetectionService disposed');
  }
}

/// Enum to track announcement status
enum AnnouncementStatus {
  active,
  full,
  expired,
}
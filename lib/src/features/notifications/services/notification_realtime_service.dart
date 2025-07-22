import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/models/notification.dart';

/// Service for handling real-time notification updates via Supabase
class NotificationRealtimeService extends ChangeNotifier {
  final SupabaseClient? _supabase;

  NotificationRealtimeService({SupabaseClient? supabaseClient}) 
      : _supabase = supabaseClient ?? _getSupabaseClient();

  static SupabaseClient? _getSupabaseClient() {
    try {
      return Supabase.instance.client;
    } catch (e) {
      debugPrint('Supabase not initialized: $e');
      return null;
    }
  }
  
  // Real-time channels
  RealtimeChannel? _notificationChannel;
  RealtimeChannel? _contractChannel;
  
  // Connection state
  bool _isConnected = false;
  bool _isInitialized = false;
  bool _isDisposed = false;
  String? _currentUserId;
  
  // Reconnection handling
  Timer? _reconnectionTimer;
  int _reconnectionAttempts = 0;
  static const int _maxReconnectionAttempts = 5;
  static const Duration _reconnectionDelay = Duration(seconds: 2);
  
  // Callbacks for real-time events
  Function(AppNotification)? onNotificationInserted;
  Function(AppNotification)? onNotificationUpdated;
  Function(String)? onNotificationDeleted;
  Function(int)? onUnreadCountChanged;
  Function(bool)? onConnectionStateChanged;
  
  // Statistics
  int _notificationsReceived = 0;
  int _notificationsUpdated = 0;
  DateTime? _lastNotificationTime;
  
  // Getters
  bool get isConnected => _isConnected;
  bool get isInitialized => _isInitialized;
  String? get currentUserId => _currentUserId;
  int get notificationsReceived => _notificationsReceived;
  int get notificationsUpdated => _notificationsUpdated;
  DateTime? get lastNotificationTime => _lastNotificationTime;
  
  /// Initialize the real-time service for a specific user
  Future<void> initialize(String userId) async {
    if (_isInitialized && _currentUserId == userId) {
      debugPrint('NotificationRealtimeService already initialized for user: $userId');
      return;
    }
    
    debugPrint('Initializing NotificationRealtimeService for user: $userId');
    
    // Check if Supabase is available
    if (_supabase == null) {
      debugPrint('Supabase client not available. Skipping real-time initialization.');
      _currentUserId = userId;
      _isInitialized = true;
      return;
    }
    
    // Cleanup existing connections
    await dispose();
    
    _currentUserId = userId;
    _reconnectionAttempts = 0;
    
    try {
      await _setupNotificationChannel(userId);
      await _setupContractChannel(userId);
      
      _isInitialized = true;
      debugPrint('NotificationRealtimeService initialized successfully');
    } catch (e) {
      debugPrint('Error initializing NotificationRealtimeService: $e');
      _scheduleReconnection();
    }
  }
  
  /// Set up real-time subscription for notifications table
  Future<void> _setupNotificationChannel(String userId) async {
    if (_supabase == null) return;
    
    try {
      _notificationChannel = _supabase!
          .channel('notifications:$userId')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'notifications',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'user_id',
              value: userId,
            ),
            callback: _handleNotificationInsert,
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.update,
            schema: 'public',
            table: 'notifications',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'user_id',
              value: userId,
            ),
            callback: _handleNotificationUpdate,
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.delete,
            schema: 'public',
            table: 'notifications',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'user_id',
              value: userId,
            ),
            callback: _handleNotificationDelete,
          );
      
      // Subscribe to the channel
      await _notificationChannel!.subscribe((status, error) {
        _handleSubscriptionStatus('notifications', status, error);
      });
      
      debugPrint('Notification channel subscribed for user: $userId');
    } catch (e) {
      debugPrint('Error setting up notification channel: $e');
      throw e;
    }
  }
  
  /// Set up real-time subscription for goalkeeper_contracts table
  Future<void> _setupContractChannel(String userId) async {
    if (_supabase == null) return;
    
    try {
      _contractChannel = _supabase!
          .channel('contracts:$userId')
          .onPostgresChanges(
            event: PostgresChangeEvent.update,
            schema: 'public',
            table: 'goalkeeper_contracts',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'goalkeeper_user_id',
              value: userId,
            ),
            callback: _handleContractUpdate,
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.update,
            schema: 'public',
            table: 'goalkeeper_contracts',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'contractor_user_id',
              value: userId,
            ),
            callback: _handleContractUpdate,
          );
      
      // Subscribe to the channel
      await _contractChannel!.subscribe((status, error) {
        _handleSubscriptionStatus('contracts', status, error);
      });
      
      debugPrint('Contract channel subscribed for user: $userId');
    } catch (e) {
      debugPrint('Error setting up contract channel: $e');
      throw e;
    }
  }
  
  /// Handle subscription status changes
  void _handleSubscriptionStatus(String channelName, RealtimeSubscribeStatus status, [Object? error]) {
    debugPrint('$channelName channel status: $status');
    
    if (error != null) {
      debugPrint('$channelName channel error: $error');
    }
    
    switch (status) {
      case RealtimeSubscribeStatus.subscribed:
        _isConnected = true;
        _reconnectionAttempts = 0;
        _cancelReconnectionTimer();
        onConnectionStateChanged?.call(true);
        break;
        
      case RealtimeSubscribeStatus.channelError:
      case RealtimeSubscribeStatus.timedOut:
      case RealtimeSubscribeStatus.closed:
        _isConnected = false;
        onConnectionStateChanged?.call(false);
        _scheduleReconnection();
        break;
        
      default:
        break;
    }
    
    notifyListeners();
  }
  
  /// Handle notification insert events
  void _handleNotificationInsert(PostgresChangePayload payload) {
    try {
      debugPrint('Notification inserted: ${payload.newRecord}');
      
      final notification = AppNotification.fromMap(payload.newRecord);
      _notificationsReceived++;
      _lastNotificationTime = DateTime.now();
      
      onNotificationInserted?.call(notification);
      _updateUnreadCount();
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error handling notification insert: $e');
    }
  }
  
  /// Handle notification update events
  void _handleNotificationUpdate(PostgresChangePayload payload) {
    try {
      debugPrint('Notification updated: ${payload.newRecord}');
      
      final notification = AppNotification.fromMap(payload.newRecord);
      _notificationsUpdated++;
      
      onNotificationUpdated?.call(notification);
      _updateUnreadCount();
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error handling notification update: $e');
    }
  }
  
  /// Handle notification delete events
  void _handleNotificationDelete(PostgresChangePayload payload) {
    try {
      debugPrint('Notification deleted: ${payload.oldRecord}');
      
      final notificationId = payload.oldRecord['id'] as String;
      onNotificationDeleted?.call(notificationId);
      _updateUnreadCount();
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error handling notification delete: $e');
    }
  }
  
  /// Handle contract update events (affects related notifications)
  void _handleContractUpdate(PostgresChangePayload payload) {
    try {
      debugPrint('Contract updated: ${payload.newRecord}');
      
      final contractId = payload.newRecord['id'] as String;
      final status = payload.newRecord['status'] as String;
      
      // When a contract status changes, we need to update related notifications
      _updateRelatedNotifications(contractId, status);
      
    } catch (e) {
      debugPrint('Error handling contract update: $e');
    }
  }
  
  /// Update notifications related to a contract status change
  Future<void> _updateRelatedNotifications(String contractId, String status) async {
    if (_supabase == null || _currentUserId == null) return;
    
    try {
      // Find notifications related to this contract
      final response = await _supabase!
          .from('notifications')
          .select('*')
          .eq('user_id', _currentUserId!)
          .like('data', '%"contract_id":"$contractId"%');
      
      for (final notificationData in response) {
        final notification = AppNotification.fromMap(notificationData);
        
        // Update notification based on contract status
        if (status == 'accepted' || status == 'declined') {
          // Mark notification as having action taken
          await _supabase!
              .from('notifications')
              .update({
                'action_taken_at': DateTime.now().toIso8601String(),
                'read_at': DateTime.now().toIso8601String(),
              })
              .eq('id', notification.id);
        }
      }
    } catch (e) {
      debugPrint('Error updating related notifications: $e');
    }
  }
  
  /// Update unread notification count
  Future<void> _updateUnreadCount() async {
    if (_supabase == null || _currentUserId == null) return;
    
    try {
      final response = await _supabase!
          .from('notifications')
          .select('id')
          .eq('user_id', _currentUserId!)
          .isFilter('read_at', null);
      
      final unreadCount = response.length;
      onUnreadCountChanged?.call(unreadCount);
    } catch (e) {
      debugPrint('Error updating unread count: $e');
    }
  }
  
  /// Schedule reconnection attempt
  void _scheduleReconnection() {
    if (_reconnectionAttempts >= _maxReconnectionAttempts) {
      debugPrint('Max reconnection attempts reached. Stopping reconnection.');
      return;
    }
    
    _cancelReconnectionTimer();
    
    final delay = _reconnectionDelay * (_reconnectionAttempts + 1);
    debugPrint('Scheduling reconnection attempt ${_reconnectionAttempts + 1} in ${delay.inSeconds} seconds');
    
    _reconnectionTimer = Timer(delay, () async {
      _reconnectionAttempts++;
      
      if (_currentUserId != null) {
        try {
          await initialize(_currentUserId!);
        } catch (e) {
          debugPrint('Reconnection attempt failed: $e');
          _scheduleReconnection();
        }
      }
    });
  }
  
  /// Cancel reconnection timer
  void _cancelReconnectionTimer() {
    _reconnectionTimer?.cancel();
    _reconnectionTimer = null;
  }
  
  /// Force reconnection
  Future<void> reconnect() async {
    if (_currentUserId != null) {
      _reconnectionAttempts = 0;
      await initialize(_currentUserId!);
    }
  }
  
  /// Get connection statistics
  Map<String, dynamic> getStatistics() {
    return {
      'isConnected': _isConnected,
      'isInitialized': _isInitialized,
      'currentUserId': _currentUserId,
      'notificationsReceived': _notificationsReceived,
      'notificationsUpdated': _notificationsUpdated,
      'lastNotificationTime': _lastNotificationTime?.toIso8601String(),
      'reconnectionAttempts': _reconnectionAttempts,
    };
  }
  
  /// Reset statistics
  void resetStatistics() {
    _notificationsReceived = 0;
    _notificationsUpdated = 0;
    _lastNotificationTime = null;
    notifyListeners();
  }
  
  /// Dispose of the service and cleanup resources
  Future<void> dispose() async {
    if (_isDisposed) {
      return; // Already disposed
    }
    
    debugPrint('Disposing NotificationRealtimeService');
    
    _isDisposed = true;
    _cancelReconnectionTimer();
    
    // Unsubscribe from channels
    if (_notificationChannel != null) {
      await _notificationChannel!.unsubscribe();
      _notificationChannel = null;
    }
    
    if (_contractChannel != null) {
      await _contractChannel!.unsubscribe();
      _contractChannel = null;
    }
    
    _isConnected = false;
    _isInitialized = false;
    _currentUserId = null;
    
    // Clear callbacks
    onNotificationInserted = null;
    onNotificationUpdated = null;
    onNotificationDeleted = null;
    onUnreadCountChanged = null;
    onConnectionStateChanged = null;
    
    super.dispose();
  }
}
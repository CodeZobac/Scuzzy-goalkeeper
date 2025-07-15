import 'dart:async';
import 'package:flutter/material.dart';
import '../../data/models/notification.dart';
import '../../data/repositories/notification_repository.dart';
import '../../services/notification_service.dart';

class NotificationController extends ChangeNotifier {
  final NotificationRepository _repository;
  final NotificationService _notificationService;

  NotificationController(this._repository, this._notificationService);

  // State variables
  List<AppNotification> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  String? _error;

  StreamSubscription? _notificationStreamSubscription;

  // Getters
  List<AppNotification> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  String? get error => _error;

  bool get hasUnreadNotifications => _unreadCount > 0;

  List<AppNotification> get unreadNotifications =>
      _notifications.where((notification) => notification.isUnread).toList();

  /// Initialize the controller
  Future<void> initialize(String userId) async {
    await loadNotifications(userId);
    _startListeningToNotifications(userId);
    _setupNotificationCallbacks();
  }

  /// Load notifications for a user
  Future<void> loadNotifications(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _notifications = await _repository.getUserNotifications(userId);
      _unreadCount = await _repository.getUnreadNotificationsCount(userId);
    } catch (e) {
      _error = e.toString();
      _notifications = [];
      _unreadCount = 0;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refresh notifications
  Future<void> refreshNotifications(String userId) async {
    await loadNotifications(userId);
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _repository.markNotificationAsRead(notificationId);

      // Update local state
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(
          readAt: DateTime.now(),
        );
        _unreadCount = _notifications.where((n) => n.isUnread).length;
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead(String userId) async {
    try {
      await _repository.markAllNotificationsAsRead(userId);

      // Update local state
      final now = DateTime.now();
      _notifications = _notifications
          .map((notification) => notification.copyWith(readAt: now))
          .toList();
      _unreadCount = 0;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _repository.deleteNotification(notificationId);
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index == -1) return;
      final notification = _notifications.removeAt(index);
      if (notification.isUnread) {
        _unreadCount--;
      }
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Handle notification tap (navigation)
  void handleNotificationTap(Map<String, dynamic> data) {
    debugPrint('Handling notification tap: $data');
    
    final type = data['type'] as String?;
    final bookingId = data['booking_id'] as String?;
    
    if (type == 'booking_request' && bookingId != null) {
      // Navigate to booking details or booking management screen
      // This should be handled by the main app navigation
      onNotificationTapped?.call(data);
    }
  }

  /// Handle notification received in foreground
  void handleNotificationReceived(Map<String, dynamic> data) {
    debugPrint('Handling notification received: $data');
    
    // Refresh notifications to show the new one
    final userId = data['goalkeeper_id'] as String?;
    if (userId != null) {
      loadNotifications(userId);
    }
  }

  /// Start listening to real-time notifications
  void _startListeningToNotifications(String userId) {
    _notificationStreamSubscription?.cancel();
    
    try {
      _notificationStreamSubscription = _repository
          .listenToUserNotifications(userId)
          .listen(
            (notification) {
              // Add new notification to the beginning of the list
              if (!_notifications.any((n) => n.id == notification.id)) {
                _notifications.insert(0, notification);
                
                if (notification.isUnread) {
                  _unreadCount++;
                }
                
                notifyListeners();
              }
            },
            onError: (error) {
              debugPrint('Error listening to notifications: $error');
            },
          );
    } catch (e) {
      debugPrint('Error setting up notification stream: $e');
    }
  }

  /// Setup notification service callbacks
  void _setupNotificationCallbacks() {
    _notificationService.onNotificationTapped = handleNotificationTap;
    _notificationService.onNotificationReceived = handleNotificationReceived;
  }

  /// Get notifications for a specific booking
  Future<List<AppNotification>> getBookingNotifications(String bookingId) async {
    try {
      return await _repository.getBookingNotifications(bookingId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return [];
    }
  }

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    return await _notificationService.areNotificationsEnabled();
  }

  /// Get FCM token
  String? get fcmToken => _notificationService.fcmToken;

  // Callback for navigation handling
  Function(Map<String, dynamic>)? onNotificationTapped;

  @override
  void dispose() {
    _notificationStreamSubscription?.cancel();
    super.dispose();
  }
}

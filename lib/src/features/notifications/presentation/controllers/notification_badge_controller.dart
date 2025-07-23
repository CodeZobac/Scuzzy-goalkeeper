import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/repositories/notification_repository.dart';

/// Controller for managing notification badge count in the navbar
class NotificationBadgeController extends ChangeNotifier {
  final NotificationRepository _repository;
  
  int _unreadCount = 0;
  bool _isInitialized = false;
  String? _currentUserId;

  NotificationBadgeController(this._repository);

  int get unreadCount => _unreadCount;
  bool get hasUnreadNotifications => _unreadCount > 0;

  /// Initialize the badge controller for a user
  Future<void> initialize(String userId) async {
    if (_currentUserId == userId && _isInitialized) return;
    
    _currentUserId = userId;
    await _loadUnreadCount();
    _isInitialized = true;
  }

  /// Load unread count from repository
  Future<void> _loadUnreadCount() async {
    if (_currentUserId == null) return;
    
    try {
      _unreadCount = await _repository.getUnreadNotificationsCount(_currentUserId!);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading unread count: $e');
      _unreadCount = 0;
      notifyListeners();
    }
  }

  /// Update unread count (called by notification controller)
  void updateUnreadCount(int count) {
    if (_unreadCount != count) {
      _unreadCount = count;
      notifyListeners();
    }
  }

  /// Increment unread count
  void incrementUnreadCount() {
    _unreadCount++;
    notifyListeners();
  }

  /// Decrement unread count
  void decrementUnreadCount() {
    if (_unreadCount > 0) {
      _unreadCount--;
      notifyListeners();
    }
  }

  /// Reset unread count
  void resetUnreadCount() {
    _unreadCount = 0;
    notifyListeners();
  }

  /// Refresh unread count
  Future<void> refresh() async {
    await _loadUnreadCount();
  }

  /// Clear state when user logs out
  void clear() {
    _unreadCount = 0;
    _isInitialized = false;
    _currentUserId = null;
    notifyListeners();
  }
}
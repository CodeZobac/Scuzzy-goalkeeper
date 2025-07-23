import 'dart:async';
import 'package:flutter/foundation.dart';
import '../data/repositories/notification_repository.dart';

/// Service responsible for automatically archiving old notifications
class NotificationArchivingService {
  final NotificationRepository _repository;
  Timer? _archivingTimer;
  
  static const Duration _archivingInterval = Duration(hours: 24); // Check daily
  static const Duration _archiveAfterDuration = Duration(days: 30); // Archive after 30 days
  
  NotificationArchivingService(this._repository);

  /// Initialize the archiving service
  void initialize(String userId) {
    // Run initial archiving
    _archiveOldNotifications(userId);
    
    // Set up periodic archiving
    _archivingTimer = Timer.periodic(_archivingInterval, (_) {
      _archiveOldNotifications(userId);
    });
    
    debugPrint('Notification archiving service initialized');
  }

  /// Archive old notifications for a user
  Future<void> _archiveOldNotifications(String userId) async {
    try {
      await _repository.archiveOldNotifications(userId);
      debugPrint('Old notifications archived for user: $userId');
    } catch (e) {
      debugPrint('Error archiving old notifications: $e');
    }
  }

  /// Manually trigger archiving for a user
  Future<void> archiveOldNotifications(String userId) async {
    await _archiveOldNotifications(userId);
  }

  /// Get statistics about archiving
  Map<String, dynamic> getStatistics() {
    return {
      'is_active': _archivingTimer?.isActive ?? false,
      'archive_interval_hours': _archivingInterval.inHours,
      'archive_after_days': _archiveAfterDuration.inDays,
    };
  }

  /// Dispose the service
  void dispose() {
    _archivingTimer?.cancel();
    _archivingTimer = null;
    debugPrint('Notification archiving service disposed');
  }
}
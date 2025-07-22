import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/notification_preferences.dart';
import '../../data/repositories/notification_preferences_repository.dart';

/// Controller for managing notification preferences
class NotificationPreferencesController extends ChangeNotifier {
  final NotificationPreferencesRepository _repository;
  
  NotificationPreferences? _preferences;
  bool _isLoading = false;
  String? _error;

  NotificationPreferencesController({
    NotificationPreferencesRepository? repository,
  }) : _repository = repository ?? NotificationPreferencesRepository();

  // Getters
  NotificationPreferences? get preferences => _preferences;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Load notification preferences for current user
  Future<void> loadPreferences() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      _error = 'User not authenticated';
      notifyListeners();
      return;
    }

    _setLoading(true);
    _clearError();

    try {
      _preferences = await _repository.getNotificationPreferences(user.id);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading notification preferences: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Update contract notifications preference
  Future<void> updateContractNotifications(bool enabled) async {
    await _updateNotificationType('contract_notifications', enabled);
  }

  /// Update full lobby notifications preference
  Future<void> updateFullLobbyNotifications(bool enabled) async {
    await _updateNotificationType('full_lobby_notifications', enabled);
  }

  /// Update general notifications preference
  Future<void> updateGeneralNotifications(bool enabled) async {
    await _updateNotificationType('general_notifications', enabled);
  }

  /// Update push notifications enabled preference
  Future<void> updatePushNotificationsEnabled(bool enabled) async {
    await _updateNotificationType('push_notifications_enabled', enabled);
  }

  /// Update a specific notification type
  Future<void> _updateNotificationType(String notificationType, bool enabled) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      _error = 'User not authenticated';
      notifyListeners();
      return;
    }

    if (_preferences == null) {
      await loadPreferences();
      if (_preferences == null) return;
    }

    _clearError();

    try {
      // Optimistically update the UI
      _updatePreferencesLocally(notificationType, enabled);
      notifyListeners();

      // Update in database
      _preferences = await _repository.updateNotificationType(
        userId: user.id,
        notificationType: notificationType,
        enabled: enabled,
      );
      
      notifyListeners();
    } catch (e) {
      // Revert optimistic update on error
      _updatePreferencesLocally(notificationType, !enabled);
      _error = 'Failed to update notification preference: ${e.toString()}';
      debugPrint('Error updating notification preference: $e');
      notifyListeners();
    }
  }

  /// Update preferences locally (for optimistic updates)
  void _updatePreferencesLocally(String notificationType, bool enabled) {
    if (_preferences == null) return;

    switch (notificationType) {
      case 'contract_notifications':
        _preferences = _preferences!.copyWith(contractNotifications: enabled);
        break;
      case 'full_lobby_notifications':
        _preferences = _preferences!.copyWith(fullLobbyNotifications: enabled);
        break;
      case 'general_notifications':
        _preferences = _preferences!.copyWith(generalNotifications: enabled);
        break;
      case 'push_notifications_enabled':
        _preferences = _preferences!.copyWith(pushNotificationsEnabled: enabled);
        break;
    }
  }

  /// Reset preferences to defaults
  Future<void> resetToDefaults() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      _error = 'User not authenticated';
      notifyListeners();
      return;
    }

    _setLoading(true);
    _clearError();

    try {
      _preferences = await _repository.resetToDefaults(user.id);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to reset preferences: ${e.toString()}';
      debugPrint('Error resetting notification preferences: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Check if a specific notification type is enabled
  bool isNotificationTypeEnabled(String notificationType) {
    if (_preferences == null) return true; // Default to enabled
    return _preferences!.isNotificationTypeEnabled(notificationType);
  }

  /// Watch preferences changes in real-time
  void watchPreferences() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    _repository.watchNotificationPreferences(user.id).listen(
      (preferences) {
        if (preferences != null) {
          _preferences = preferences;
          notifyListeners();
        }
      },
      onError: (error) {
        _error = 'Real-time sync error: ${error.toString()}';
        debugPrint('Error watching notification preferences: $error');
        notifyListeners();
      },
    );
  }

  /// Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Clear error state
  void _clearError() {
    _error = null;
  }

  /// Clear all data (used when user logs out)
  void clear() {
    _preferences = null;
    _isLoading = false;
    _error = null;
    notifyListeners();
  }
}
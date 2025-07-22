import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/repositories/notification_repository.dart';
import '../data/models/contract_notification_data.dart';
import '../data/models/full_lobby_notification_data.dart';
import '../data/models/notification_error.dart';
import 'notification_service.dart';
import 'full_lobby_detection_service.dart';
import 'contract_management_service.dart';
import 'contract_expiration_handler.dart';
import 'notification_error_handler.dart';
import 'notification_retry_manager.dart';

/// Service manager that coordinates all notification-related services
/// and ensures proper initialization and lifecycle management
class NotificationServiceManager {
  static NotificationServiceManager? _instance;
  static NotificationServiceManager get instance => _instance ??= NotificationServiceManager._();
  
  NotificationServiceManager._();

  // Services
  late final NotificationRepository _notificationRepository;
  late final NotificationService _notificationService;
  late final FullLobbyDetectionService _fullLobbyDetectionService;
  late final ContractManagementService _contractManagementService;
  late final ContractExpirationHandler _contractExpirationHandler;
  final NotificationErrorHandler _errorHandler = NotificationErrorHandler.instance;
  final NotificationRetryManager _retryManager = NotificationRetryManager.instance;

  bool _isInitialized = false;
  String? _currentUserId;
  NotificationError? _lastError;

  /// Initialize all notification services
  Future<void> initialize() async {
    if (_isInitialized) return;

    final result = await _retryManager.executeWithRetry(
      'notification_service_manager_init',
      () async {
        debugPrint('Initializing NotificationServiceManager...');

        // Initialize repositories
        _notificationRepository = NotificationRepository();

        // Initialize core notification service
        _notificationService = NotificationService();
        final initResult = await _notificationService.initialize();
        if (!initResult.isSuccess) {
          throw initResult.error!;
        }

        // Initialize specialized services
        _fullLobbyDetectionService = FullLobbyDetectionService(_notificationRepository, Supabase.instance.client);
        _contractManagementService = ContractManagementService(_notificationRepository);
        _contractExpirationHandler = ContractExpirationHandler(_notificationRepository);

        _isInitialized = true;
        _lastError = null;
        debugPrint('NotificationServiceManager initialized successfully');
      },
      context: {'operation': 'initialize'},
    );

    if (!result.isSuccess) {
      _lastError = result.error;
      throw result.error!;
    }
  }

  /// Called when user signs in - initializes user-specific services
  Future<void> onUserSignIn(String userId) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (_currentUserId == userId) return;

    try {
      debugPrint('Setting up notification services for user: $userId');
      _currentUserId = userId;

      // Initialize core notification service for user
      await _notificationService.onUserSignIn();

      // Initialize full lobby detection service
      await _fullLobbyDetectionService.initialize();

      // Initialize contract management service
      await _contractManagementService.initialize();

      // Initialize contract expiration handler
      await _contractExpirationHandler.initialize();

      debugPrint('All notification services initialized for user: $userId');
    } catch (e) {
      debugPrint('Error setting up notification services for user: $e');
      rethrow;
    }
  }

  /// Called when user signs out - cleanup user-specific services
  Future<void> onUserSignOut() async {
    if (!_isInitialized || _currentUserId == null) return;

    try {
      debugPrint('Cleaning up notification services for user: $_currentUserId');

      // Disable FCM token
      await _notificationService.disableToken();

      // Dispose services
      _fullLobbyDetectionService.dispose();
      _contractExpirationHandler.dispose();

      _currentUserId = null;
      debugPrint('Notification services cleaned up successfully');
    } catch (e) {
      debugPrint('Error cleaning up notification services: $e');
    }
  }

  /// Get the notification repository
  NotificationRepository get notificationRepository {
    if (!_isInitialized) {
      throw StateError('NotificationServiceManager not initialized. Call initialize() first.');
    }
    return _notificationRepository;
  }

  /// Get the notification service
  NotificationService get notificationService {
    if (!_isInitialized) {
      throw StateError('NotificationServiceManager not initialized. Call initialize() first.');
    }
    return _notificationService;
  }

  /// Get the full lobby detection service
  FullLobbyDetectionService get fullLobbyDetectionService {
    if (!_isInitialized) {
      throw StateError('NotificationServiceManager not initialized. Call initialize() first.');
    }
    return _fullLobbyDetectionService;
  }

  /// Get the contract management service
  ContractManagementService get contractManagementService {
    if (!_isInitialized) {
      throw StateError('NotificationServiceManager not initialized. Call initialize() first.');
    }
    return _contractManagementService;
  }

  /// Send contract request notification (database + push)
  Future<void> sendContractNotification({
    required String goalkeeperUserId,
    required String contractorUserId,
    required String announcementId,
    required ContractNotificationData contractData,
  }) async {
    try {
      // Create database notification through repository
      await _notificationRepository.createContractNotification(
        goalkeeperUserId: goalkeeperUserId,
        contractorUserId: contractorUserId,
        announcementId: announcementId,
        data: contractData,
      );

      // Send push notification
      final pushResult = await _notificationService.sendContractNotification(
        goalkeeperUserId: goalkeeperUserId,
        data: contractData,
      );

      if (!pushResult.isSuccess) {
        // Log push notification failure but don't fail the entire operation
        // since the database notification was created successfully
        _lastError = pushResult.error;
        debugPrint('Push notification failed but database notification created: ${pushResult.error?.message}');
      }

      debugPrint('Contract notification sent successfully');
    } catch (e) {
      final error = _errorHandler.handleException(
        e is Exception ? e : Exception(e.toString()),
        operationId: 'send_contract_notification',
        context: {
          'goalkeeper_user_id': goalkeeperUserId,
          'contractor_user_id': contractorUserId,
          'announcement_id': announcementId,
        },
      );
      _lastError = error;
      debugPrint('Error sending contract notification: ${error.message}');
      rethrow;
    }
  }

  /// Send full lobby notification (database + push)
  Future<void> sendFullLobbyNotification({
    required String creatorUserId,
    required String announcementId,
    required FullLobbyNotificationData lobbyData,
  }) async {
    try {
      // Create database notification through repository
      await _notificationRepository.createFullLobbyNotification(
        creatorUserId: creatorUserId,
        announcementId: announcementId,
        data: lobbyData,
      );

      // Send push notification
      await _notificationService.sendFullLobbyNotification(
        creatorUserId: creatorUserId,
        data: lobbyData,
      );

      debugPrint('Full lobby notification sent successfully');
    } catch (e) {
      debugPrint('Error sending full lobby notification: $e');
      rethrow;
    }
  }

  /// Get the contract expiration handler
  ContractExpirationHandler get contractExpirationHandler {
    if (!_isInitialized) {
      throw StateError('NotificationServiceManager not initialized. Call initialize() first.');
    }
    return _contractExpirationHandler;
  }

  /// Check if services are initialized
  bool get isInitialized => _isInitialized;

  /// Get current user ID
  String? get currentUserId => _currentUserId;

  /// Get full lobby detection statistics
  Map<String, dynamic> getFullLobbyStatistics() {
    return _fullLobbyDetectionService.getStatistics();
  }

  /// Manually trigger full lobby check for an announcement
  Future<void> checkAnnouncementFullLobby(int announcementId) async {
    await _fullLobbyDetectionService.checkAnnouncement(announcementId);
  }

  /// Check if an announcement has been processed for full lobby notification
  bool isAnnouncementProcessed(int announcementId) {
    return _fullLobbyDetectionService.isAnnouncementProcessed(announcementId);
  }

  /// Get announcement status
  AnnouncementStatus? getAnnouncementStatus(int announcementId) {
    return _fullLobbyDetectionService.getAnnouncementStatus(announcementId);
  }

  /// Dispose all services
  void dispose() {
    if (!_isInitialized) return;

    try {
      _fullLobbyDetectionService.dispose();
      _contractExpirationHandler.dispose();
      _isInitialized = false;
      _currentUserId = null;
      debugPrint('NotificationServiceManager disposed');
    } catch (e) {
      debugPrint('Error disposing NotificationServiceManager: $e');
    }
  }
}
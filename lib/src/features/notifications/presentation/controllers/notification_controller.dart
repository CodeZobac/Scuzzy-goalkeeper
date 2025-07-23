import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/notification.dart';
import '../../data/models/notification_category.dart';
import '../../data/repositories/notification_repository.dart';
import '../../services/notification_service.dart';
import '../../services/notification_realtime_service.dart';
import '../../services/full_lobby_detection_service.dart';
import '../../services/contract_management_service.dart';
import '../../services/notification_archiving_service.dart';
import '../../../announcements/presentation/screens/announcement_detail_screen.dart';
import '../../../auth/presentation/theme/app_theme.dart';

import '../../../announcements/data/repositories/announcement_repository.dart';
import '../../../announcements/data/repositories/announcement_repository_impl.dart';
import '../../../../core/navigation/navigation_service.dart';
import 'notification_badge_controller.dart';

class NotificationController extends ChangeNotifier {
  final NotificationRepository _repository;
  final NotificationService _notificationService;
  late final NotificationRealtimeService _realtimeService;
  late final FullLobbyDetectionService _fullLobbyDetectionService;
  late final ContractManagementService _contractService;
  late final AnnouncementRepository _announcementRepository;
  late final NotificationArchivingService _archivingService;
  final SupabaseClient _supabase = Supabase.instance.client;
  
  // Badge controller for navbar integration
  NotificationBadgeController? _badgeController;

  NotificationController(this._repository, this._notificationService) {
    _realtimeService = NotificationRealtimeService();
    _fullLobbyDetectionService = FullLobbyDetectionService(_repository, Supabase.instance.client);
    _contractService = ContractManagementService();
    _announcementRepository = AnnouncementRepositoryImpl(Supabase.instance.client);
    _archivingService = NotificationArchivingService(_repository);
  }

  // State variables
  List<AppNotification> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  String? _error;
  bool _isRealtimeConnected = false;

  // Pagination state
  bool _hasMoreNotifications = true;
  bool _isLoadingMore = false;
  int _currentPage = 0;
  static const int _pageSize = 20;
  int _totalNotifications = 0;

  // Search and filter state
  String _searchQuery = '';
  NotificationCategory? _selectedCategory;
  bool _showArchived = false;
  String _sortBy = 'sent_at';
  bool _sortAscending = false;
  DateTime? _dateFrom;
  DateTime? _dateTo;
  bool? _readStatusFilter; // null = all, true = read only, false = unread only

  // Bulk selection state
  final Set<String> _selectedNotificationIds = {};
  bool _selectionMode = false;

  // Action loading states
  final Map<String, bool> _actionLoadingStates = {};

  StreamSubscription? _notificationStreamSubscription;

  // Getters
  List<AppNotification> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isRealtimeConnected => _isRealtimeConnected;

  // Pagination getters
  bool get hasMoreNotifications => _hasMoreNotifications;
  bool get isLoadingMore => _isLoadingMore;
  int get currentPage => _currentPage;
  int get totalNotifications => _totalNotifications;

  // Search and filter getters
  String get searchQuery => _searchQuery;
  NotificationCategory? get selectedCategory => _selectedCategory;
  bool get showArchived => _showArchived;
  String get sortBy => _sortBy;
  bool get sortAscending => _sortAscending;
  DateTime? get dateFrom => _dateFrom;
  DateTime? get dateTo => _dateTo;
  bool? get readStatusFilter => _readStatusFilter;

  // Bulk selection getters
  Set<String> get selectedNotificationIds => _selectedNotificationIds;
  bool get selectionMode => _selectionMode;
  bool get hasSelectedNotifications => _selectedNotificationIds.isNotEmpty;
  List<AppNotification> get selectedNotifications => 
      _notifications.where((n) => _selectedNotificationIds.contains(n.id)).toList();

  bool get hasUnreadNotifications => _unreadCount > 0;

  List<AppNotification> get unreadNotifications =>
      _notifications.where((notification) => notification.isUnread).toList();

  /// Initialize the controller
  Future<void> initialize(String userId, {NotificationBadgeController? badgeController}) async {
    _badgeController = badgeController;
    
    await loadNotifications(userId);
    await _initializeRealtimeService(userId);
    _setupNotificationCallbacks();
    
    // Initialize full lobby detection service
    try {
      await _fullLobbyDetectionService.initialize();
      debugPrint('Full lobby detection service initialized successfully');
    } catch (e) {
      debugPrint('Error initializing full lobby detection service: $e');
      _error = 'Erro ao inicializar detecção de lobby completo: $e';
      notifyListeners();
    }

    // Initialize archiving service
    try {
      _archivingService.initialize(userId);
      debugPrint('Notification archiving service initialized successfully');
    } catch (e) {
      debugPrint('Error initializing archiving service: $e');
      _error = 'Erro ao inicializar serviço de arquivamento: $e';
      notifyListeners();
    }
  }

  /// Load notifications for a user
  Future<void> loadNotifications(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _notifications = await _repository.getUserNotifications(userId);
      _unreadCount = await _repository.getUnreadNotificationsCount(userId);
      _syncBadgeController();
    } catch (e) {
      _error = e.toString();
      _notifications = [];
      _unreadCount = 0;
      _syncBadgeController();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refresh notifications
  Future<void> refreshNotifications(String userId) async {
    await loadNotifications(userId);
  }

  /// Load notifications with pagination
  Future<void> loadNotificationsPaginated(String userId, {bool reset = false}) async {
    if (reset) {
      _currentPage = 0;
      _notifications.clear();
      _hasMoreNotifications = true;
    }

    if (!_hasMoreNotifications || _isLoadingMore) return;

    if (_currentPage == 0) {
      _isLoading = true;
    } else {
      _isLoadingMore = true;
    }
    
    _error = null;
    notifyListeners();

    try {
      final offset = _currentPage * _pageSize;
      
      final newNotifications = await _repository.getUserNotificationsPaginated(
        userId,
        limit: _pageSize,
        offset: offset,
        searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
        category: _selectedCategory,
        includeArchived: _showArchived,
      );

      // Get total count for pagination info
      _totalNotifications = await _repository.getUserNotificationsCount(
        userId,
        searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
        category: _selectedCategory,
        includeArchived: _showArchived,
      );

      if (reset) {
        _notifications = newNotifications;
      } else {
        _notifications.addAll(newNotifications);
      }

      _hasMoreNotifications = newNotifications.length == _pageSize;
      _currentPage++;

      // Update unread count
      _unreadCount = await _repository.getUnreadNotificationsCount(userId);
    } catch (e) {
      _error = e.toString();
      if (reset) {
        _notifications = [];
      }
    } finally {
      _isLoading = false;
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  /// Load more notifications (infinite scroll)
  Future<void> loadMoreNotifications(String userId) async {
    await loadNotificationsPaginated(userId, reset: false);
  }

  /// Search notifications
  Future<void> searchNotifications(String userId, String query) async {
    _searchQuery = query;
    await loadNotificationsPaginated(userId, reset: true);
  }

  /// Clear search
  Future<void> clearSearch(String userId) async {
    _searchQuery = '';
    await loadNotificationsPaginated(userId, reset: true);
  }

  /// Filter notifications by category
  Future<void> filterByCategory(String userId, NotificationCategory? category) async {
    _selectedCategory = category;
    await loadNotificationsPaginated(userId, reset: true);
  }

  /// Toggle archived notifications view
  Future<void> toggleArchivedView(String userId) async {
    _showArchived = !_showArchived;
    await loadNotificationsPaginated(userId, reset: true);
  }

  /// Load notifications with advanced filtering and sorting
  Future<void> loadNotificationsAdvanced(String userId, {bool reset = false}) async {
    if (reset) {
      _currentPage = 0;
      _notifications.clear();
      _hasMoreNotifications = true;
    }

    if (!_hasMoreNotifications || _isLoadingMore) return;

    if (_currentPage == 0) {
      _isLoading = true;
    } else {
      _isLoadingMore = true;
    }
    
    _error = null;
    notifyListeners();

    try {
      final offset = _currentPage * _pageSize;
      
      final newNotifications = await _repository.getNotificationsAdvanced(
        userId,
        limit: _pageSize,
        offset: offset,
        searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
        category: _selectedCategory,
        includeArchived: _showArchived,
        sortBy: _sortBy,
        ascending: _sortAscending,
        dateFrom: _dateFrom,
        dateTo: _dateTo,
        readStatus: _readStatusFilter,
      );

      // Get total count for pagination info
      _totalNotifications = await _repository.getNotificationsCountAdvanced(
        userId,
        searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
        category: _selectedCategory,
        includeArchived: _showArchived,
        dateFrom: _dateFrom,
        dateTo: _dateTo,
        readStatus: _readStatusFilter,
      );

      if (reset) {
        _notifications = newNotifications;
      } else {
        _notifications.addAll(newNotifications);
      }

      _hasMoreNotifications = newNotifications.length == _pageSize;
      _currentPage++;

      // Update unread count
      _unreadCount = await _repository.getUnreadNotificationsCount(userId);
    } catch (e) {
      _error = e.toString();
      if (reset) {
        _notifications = [];
      }
    } finally {
      _isLoading = false;
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  /// Set sorting options
  Future<void> setSorting(String userId, String sortBy, bool ascending) async {
    _sortBy = sortBy;
    _sortAscending = ascending;
    await loadNotificationsAdvanced(userId, reset: true);
  }

  /// Set date range filter
  Future<void> setDateRange(String userId, DateTime? from, DateTime? to) async {
    _dateFrom = from;
    _dateTo = to;
    await loadNotificationsAdvanced(userId, reset: true);
  }

  /// Clear date range filter
  Future<void> clearDateRange(String userId) async {
    _dateFrom = null;
    _dateTo = null;
    await loadNotificationsAdvanced(userId, reset: true);
  }

  /// Set read status filter
  Future<void> setReadStatusFilter(String userId, bool? readStatus) async {
    _readStatusFilter = readStatus;
    await loadNotificationsAdvanced(userId, reset: true);
  }

  /// Clear all filters and reset to default
  Future<void> clearAllFilters(String userId) async {
    _searchQuery = '';
    _selectedCategory = null;
    _showArchived = false;
    _sortBy = 'sent_at';
    _sortAscending = false;
    _dateFrom = null;
    _dateTo = null;
    _readStatusFilter = null;
    await loadNotificationsAdvanced(userId, reset: true);
  }

  /// Get pagination info
  Map<String, dynamic> getPaginationInfo() {
    return {
      'currentPage': _currentPage,
      'totalNotifications': _totalNotifications,
      'hasMore': _hasMoreNotifications,
      'isLoading': _isLoading,
      'isLoadingMore': _isLoadingMore,
      'pageSize': _pageSize,
      'totalPages': (_totalNotifications / _pageSize).ceil(),
    };
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
        _syncBadgeController();
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
      _syncBadgeController();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Mark all notifications as read for a specific category
  Future<void> markAllAsReadByCategory(String userId, NotificationCategory category) async {
    try {
      await _repository.markAllNotificationsAsReadByCategory(userId, category);

      // Update local state
      final now = DateTime.now();
      _notifications = _notifications.map((notification) {
        if (notification.category == category && notification.isUnread) {
          return notification.copyWith(readAt: now);
        }
        return notification;
      }).toList();
      
      // Recalculate unread count
      _unreadCount = _notifications.where((n) => n.isUnread).length;
      _syncBadgeController();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Get unread count for a specific category
  int getUnreadCountByCategory(NotificationCategory category) {
    return _notifications
        .where((notification) => 
            notification.category == category && notification.isUnread)
        .length;
  }

  /// Automatically mark notification as read when viewed
  Future<void> markAsReadOnView(String notificationId) async {
    try {
      await _repository.markNotificationAsReadOnView(notificationId);

      // Update local state
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1 && _notifications[index].isUnread) {
        _notifications[index] = _notifications[index].copyWith(
          readAt: DateTime.now(),
        );
        _unreadCount--;
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Archive old notifications (30+ days)
  Future<void> archiveOldNotifications(String userId) async {
    try {
      await _repository.archiveOldNotifications(userId);
      
      // Refresh notifications to remove archived ones
      await loadNotifications(userId);
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

  /// Delete multiple notifications
  Future<void> deleteNotifications(List<String> notificationIds) async {
    try {
      await _repository.deleteNotifications(notificationIds);
      
      // Remove from local state
      int unreadDeleted = 0;
      _notifications.removeWhere((notification) {
        if (notificationIds.contains(notification.id)) {
          if (notification.isUnread) unreadDeleted++;
          return true;
        }
        return false;
      });
      
      _unreadCount -= unreadDeleted;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Delete all notifications for current user
  Future<void> deleteAllNotifications(String userId) async {
    try {
      await _repository.deleteAllNotifications(userId);
      _notifications.clear();
      _unreadCount = 0;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Delete notifications by category
  Future<void> deleteNotificationsByCategory(String userId, NotificationCategory category) async {
    try {
      await _repository.deleteNotificationsByCategory(userId, category);
      
      // Remove from local state
      int unreadDeleted = 0;
      _notifications.removeWhere((notification) {
        if (notification.category == category) {
          if (notification.isUnread) unreadDeleted++;
          return true;
        }
        return false;
      });
      
      _unreadCount -= unreadDeleted;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Get archived notifications for history view
  Future<List<AppNotification>> getArchivedNotifications({
    int limit = 20,
    int offset = 0,
    String? searchQuery,
    NotificationCategory? category,
  }) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return [];
      
      return await _repository.getArchivedNotifications(
        user.id,
        limit: limit,
        offset: offset,
        searchQuery: searchQuery,
        category: category,
      );
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return [];
    }
  }

  /// Cleanup archived notifications older than specified days
  Future<void> cleanupArchivedNotifications({int olderThanDays = 90}) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;
      
      await _repository.cleanupArchivedNotifications(user.id, olderThanDays: olderThanDays);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Restore archived notification
  Future<void> restoreArchivedNotification(String notificationId) async {
    try {
      await _repository.restoreArchivedNotification(notificationId);
      
      // Refresh notifications if we're showing archived ones
      if (_showArchived) {
        final user = Supabase.instance.client.auth.currentUser;
        if (user != null) {
          await loadNotificationsPaginated(user.id, reset: true);
        }
      }
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

  /// Initialize real-time service
  Future<void> _initializeRealtimeService(String userId) async {
    try {
      // Set up real-time service callbacks
      _realtimeService.onNotificationInserted = _handleNotificationInserted;
      _realtimeService.onNotificationUpdated = _handleNotificationUpdated;
      _realtimeService.onNotificationDeleted = _handleNotificationDeleted;
      _realtimeService.onUnreadCountChanged = _handleUnreadCountChanged;
      _realtimeService.onConnectionStateChanged = _handleConnectionStateChanged;
      
      // Initialize the real-time service
      await _realtimeService.initialize(userId);
      
      debugPrint('Real-time notification service initialized successfully');
    } catch (e) {
      debugPrint('Error initializing real-time service: $e');
      _error = 'Erro ao inicializar serviço em tempo real: $e';
      notifyListeners();
    }
  }

  /// Handle new notification insertion
  void _handleNotificationInserted(AppNotification notification) {
    debugPrint('New notification inserted: ${notification.id}');
    
    // Add new notification to the beginning of the list
    _notifications.insert(0, notification);
    
    if (notification.isUnread) {
      _unreadCount++;
    }
    
    notifyListeners();
  }

  /// Handle notification updates
  void _handleNotificationUpdated(AppNotification notification) {
    debugPrint('Notification updated: ${notification.id}');
    
    final existingIndex = _notifications.indexWhere((n) => n.id == notification.id);
    
    if (existingIndex != -1) {
      final oldNotification = _notifications[existingIndex];
      _notifications[existingIndex] = notification;
      
      // Update unread count if read status changed
      if (oldNotification.isUnread && notification.isRead) {
        _unreadCount--;
      } else if (oldNotification.isRead && notification.isUnread) {
        _unreadCount++;
      }
      
      notifyListeners();
    }
  }

  /// Handle notification deletion
  void _handleNotificationDeleted(String notificationId) {
    debugPrint('Notification deleted: $notificationId');
    
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      final notification = _notifications.removeAt(index);
      if (notification.isUnread) {
        _unreadCount--;
      }
      notifyListeners();
    }
  }

  /// Handle unread count changes
  void _handleUnreadCountChanged(int newCount) {
    debugPrint('Unread count changed: $newCount');
    _unreadCount = newCount;
    _syncBadgeController();
    notifyListeners();
  }

  /// Sync unread count with badge controller
  void _syncBadgeController() {
    _badgeController?.updateUnreadCount(_unreadCount);
  }

  /// Handle connection state changes
  void _handleConnectionStateChanged(bool isConnected) {
    debugPrint('Real-time connection state changed: $isConnected');
    _isRealtimeConnected = isConnected;
    
    if (!isConnected) {
      _error = 'Conexão em tempo real perdida. Tentando reconectar...';
    } else {
      _error = null;
    }
    
    notifyListeners();
  }

  /// Start listening to real-time notifications (deprecated - using NotificationRealtimeService)
  void _startListeningToNotifications(String userId) {
    _notificationStreamSubscription?.cancel();
    
    try {
      _notificationStreamSubscription = _repository
          .listenToUserNotifications(userId)
          .listen(
            (notification) {
              _handleRealtimeNotification(notification);
            },
            onError: (error) {
              debugPrint('Error listening to notifications: $error');
              _error = 'Erro na conexão em tempo real: $error';
              notifyListeners();
            },
          );
    } catch (e) {
      debugPrint('Error setting up notification stream: $e');
      _error = 'Erro ao configurar atualizações em tempo real: $e';
      notifyListeners();
    }
  }

  /// Handle real-time notification updates
  void _handleRealtimeNotification(AppNotification notification) {
    final existingIndex = _notifications.indexWhere((n) => n.id == notification.id);
    
    if (existingIndex != -1) {
      // Update existing notification
      final oldNotification = _notifications[existingIndex];
      _notifications[existingIndex] = notification;
      
      // Update unread count if read status changed
      if (oldNotification.isUnread && notification.isRead) {
        _unreadCount--;
      } else if (oldNotification.isRead && notification.isUnread) {
        _unreadCount++;
      }
    } else {
      // Add new notification to the beginning of the list
      _notifications.insert(0, notification);
      
      if (notification.isUnread) {
        _unreadCount++;
      }
    }
    
    notifyListeners();
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

  /// Get real-time service statistics
  Map<String, dynamic> getRealtimeStatistics() {
    return _realtimeService.getStatistics();
  }

  /// Force reconnection to real-time service
  Future<void> reconnectRealtime() async {
    try {
      await _realtimeService.reconnect();
      debugPrint('Real-time service reconnection initiated');
    } catch (e) {
      debugPrint('Error reconnecting real-time service: $e');
      _error = 'Erro ao reconectar serviço em tempo real: $e';
      notifyListeners();
    }
  }

  /// Reset real-time statistics
  void resetRealtimeStatistics() {
    _realtimeService.resetStatistics();
  }

  /// Get full lobby detection service statistics
  Map<String, dynamic> getFullLobbyStatistics() {
    return _fullLobbyDetectionService.getStatistics();
  }

  /// Manually check an announcement for full lobby status (for testing)
  Future<void> checkAnnouncementFullLobby(int announcementId) async {
    try {
      await _fullLobbyDetectionService.checkAnnouncement(announcementId);
    } catch (e) {
      debugPrint('Error checking announcement $announcementId: $e');
      _error = 'Erro ao verificar anúncio: $e';
      notifyListeners();
    }
  }

  /// Check if an announcement has been processed for full lobby notification
  bool isAnnouncementProcessed(int announcementId) {
    return _fullLobbyDetectionService.isAnnouncementProcessed(announcementId);
  }

  /// Get announcement status
  AnnouncementStatus? getAnnouncementStatus(int announcementId) {
    return _fullLobbyDetectionService.getAnnouncementStatus(announcementId);
  }

  // Callback for navigation handling
  Function(Map<String, dynamic>)? onNotificationTapped;

  /// Set action loading state for a notification
  void _setActionLoading(String notificationId, bool isLoading) {
    _actionLoadingStates[notificationId] = isLoading;
    notifyListeners();
  }

  /// Show error message to user
  void _showErrorMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  /// Show success message to user
  void _showSuccessMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  /// Show info message to user
  void _showInfoMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.accentColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  /// Show confirmation dialog
  Future<bool> _showConfirmationDialog(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmText,
    required String cancelText,
  }) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.secondaryBackground,
        title: Text(
          title,
          style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.w600),
        ),
        content: Text(
          message,
          style: AppTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              cancelText,
              style: AppTheme.bodyMedium.copyWith(color: AppTheme.secondaryText),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              confirmText,
              style: AppTheme.bodyMedium.copyWith(color: AppTheme.errorColor),
            ),
          ),
        ],
      ),
    ) ?? false;
  }

  /// Check if an action is currently loading for a notification
  bool isActionLoading(String notificationId) {
    return _actionLoadingStates[notificationId] ?? false;
  }

  /// Handle contract accept action
  Future<bool> handleContractAccept(BuildContext context, AppNotification notification) async {
    final contractId = notification.contractId;
    if (contractId == null) {
      _showErrorMessage(context, 'ID do contrato não encontrado');
      return false;
    }

    _setActionLoading(notification.id, true);

    try {
      await _contractService.acceptContract(
        contractId: contractId,
        notificationId: notification.id,
      );

      // Mark notification as read
      await markAsRead(notification.id);

      _showSuccessMessage(context, 'Contrato aceito com sucesso!');
      return true;
    } catch (e) {
      _showErrorMessage(context, 'Erro ao aceitar contrato: $e');
      return false;
    } finally {
      _setActionLoading(notification.id, false);
    }
  }

  /// Handle contract decline action with confirmation dialog
  Future<bool> handleContractDecline(BuildContext context, AppNotification notification) async {
    // Show confirmation dialog
    final confirmed = await _showConfirmationDialog(
      context,
      title: 'Recusar Contrato',
      message: 'Tem certeza que deseja recusar esta proposta de contrato?',
      confirmText: 'Recusar',
      cancelText: 'Cancelar',
    );

    if (!confirmed) return false;

    final contractId = notification.contractId;
    if (contractId == null) {
      _showErrorMessage(context, 'ID do contrato não encontrado');
      return false;
    }

    _setActionLoading(notification.id, true);

    try {
      await _contractService.declineContract(
        contractId: contractId,
        notificationId: notification.id,
      );

      // Mark notification as read
      await markAsRead(notification.id);

      _showSuccessMessage(context, 'Contrato recusado');
      return true;
    } catch (e) {
      _showErrorMessage(context, 'Erro ao recusar contrato: $e');
      return false;
    } finally {
      _setActionLoading(notification.id, false);
    }
  }

  /// Navigate to contract details
  Future<void> navigateToContractDetails(BuildContext context, AppNotification notification) async {
    final contractId = notification.contractId;
    if (contractId == null) {
      _showErrorMessage(context, 'ID do contrato não encontrado');
      return;
    }

    try {
      // Verify contract exists
      await _contractService.getContract(contractId);
      
      // Mark notification as read
      await markAsRead(notification.id);

      // Use enhanced navigation service
      final contractData = {
        'contract_id': contractId,
        'notification_id': notification.id,
        'contractor_name': notification.data?['contractor_name'],
        'announcement_title': notification.data?['announcement_title'],
        'game_date_time': notification.data?['game_date_time'],
        'stadium': notification.data?['stadium'],
        'offered_amount': notification.data?['offered_amount'],
      };

      await NavigationService.pushToContractDetails(context, contractData);
    } catch (e) {
      _showErrorMessage(context, 'Erro ao carregar detalhes do contrato: $e');
    }
  }

  /// Navigate to announcement details
  Future<void> navigateToAnnouncementDetails(BuildContext context, AppNotification notification) async {
    final announcementIdStr = notification.announcementId;
    if (announcementIdStr == null) {
      _showErrorMessage(context, 'ID do anúncio não encontrado');
      return;
    }

    final announcementId = int.tryParse(announcementIdStr);
    if (announcementId == null) {
      _showErrorMessage(context, 'ID do anúncio inválido');
      return;
    }

    try {
      // Verify announcement exists
      final announcement = await _announcementRepository.getAnnouncementById(announcementId);
      
      // Mark notification as read
      await markAsRead(notification.id);

      // Use enhanced navigation service for better transition
      await NavigationService.pushAnnouncementDetail(context, announcement);
    } catch (e) {
      _showErrorMessage(context, 'Erro ao carregar detalhes do anúncio: $e');
    }
  }

  /// Handle general notification navigation based on type
  Future<void> handleNotificationNavigation(BuildContext context, AppNotification notification) async {
    try {
      switch (notification.type) {
        case 'contract_request':
          await navigateToContractDetails(context, notification);
          break;
        case 'full_lobby':
          await navigateToAnnouncementDetails(context, notification);
          break;
        case 'booking_request':
        case 'booking_confirmed':
        case 'booking_cancelled':
          // Navigate to booking details if bookingId exists
          if (notification.bookingId != null) {
            _showInfoMessage(context, 'Navegação para detalhes da reserva será implementada');
          }
          break;
        default:
          // For general notifications, just mark as read
          if (notification.isUnread) {
            await markAsRead(notification.id);
          }
          break;
      }
    } catch (e) {
      _showErrorMessage(context, 'Erro na navegação: $e');
    }
  }



  /// Get archiving service statistics
  Map<String, dynamic> getArchivingStatistics() {
    return _archivingService.getStatistics();
  }

  /// Manually trigger archiving for current user
  Future<void> manualArchiveOldNotifications() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      await _archivingService.archiveOldNotifications(user.id);
      await loadNotifications(user.id);
    }
  }

  // Bulk selection methods
  
  /// Toggle selection mode
  void toggleSelectionMode() {
    _selectionMode = !_selectionMode;
    if (!_selectionMode) {
      _selectedNotificationIds.clear();
    }
    notifyListeners();
  }

  /// Select or deselect a notification
  void toggleNotificationSelection(String notificationId) {
    if (_selectedNotificationIds.contains(notificationId)) {
      _selectedNotificationIds.remove(notificationId);
    } else {
      _selectedNotificationIds.add(notificationId);
    }
    
    // Exit selection mode if no notifications are selected
    if (_selectedNotificationIds.isEmpty) {
      _selectionMode = false;
    }
    
    notifyListeners();
  }

  /// Select all visible notifications
  void selectAllNotifications() {
    _selectedNotificationIds.clear();
    _selectedNotificationIds.addAll(_notifications.map((n) => n.id));
    notifyListeners();
  }

  /// Clear all selections
  void clearSelection() {
    _selectedNotificationIds.clear();
    _selectionMode = false;
    notifyListeners();
  }

  /// Check if a notification is selected
  bool isNotificationSelected(String notificationId) {
    return _selectedNotificationIds.contains(notificationId);
  }

  /// Mark selected notifications as read
  Future<void> markSelectedAsRead() async {
    if (_selectedNotificationIds.isEmpty) return;

    try {
      final selectedIds = _selectedNotificationIds.toList();
      
      // Mark each notification as read
      for (final id in selectedIds) {
        await _repository.markNotificationAsRead(id);
      }

      // Update local state
      final now = DateTime.now();
      int markedCount = 0;
      
      for (int i = 0; i < _notifications.length; i++) {
        if (selectedIds.contains(_notifications[i].id) && _notifications[i].isUnread) {
          _notifications[i] = _notifications[i].copyWith(readAt: now);
          markedCount++;
        }
      }
      
      _unreadCount -= markedCount;
      clearSelection();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Delete selected notifications
  Future<void> deleteSelectedNotifications() async {
    if (_selectedNotificationIds.isEmpty) return;

    try {
      final selectedIds = _selectedNotificationIds.toList();
      await deleteNotifications(selectedIds);
      clearSelection();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Archive selected notifications
  Future<void> archiveSelectedNotifications() async {
    if (_selectedNotificationIds.isEmpty) return;

    try {
      final selectedIds = _selectedNotificationIds.toList();
      final now = DateTime.now();
      
      // Archive each notification
      for (final id in selectedIds) {
        await _supabase
            .from('notifications')
            .update({'archived_at': now.toIso8601String()})
            .eq('id', id);
      }

      // Update local state
      int unreadArchived = 0;
      _notifications.removeWhere((notification) {
        if (selectedIds.contains(notification.id)) {
          if (notification.isUnread) unreadArchived++;
          return true;
        }
        return false;
      });
      
      _unreadCount -= unreadArchived;
      clearSelection();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _notificationStreamSubscription?.cancel();
    _realtimeService.dispose();
    _fullLobbyDetectionService.dispose();
    _contractService.dispose();
    _archivingService.dispose();
    super.dispose();
  }
}

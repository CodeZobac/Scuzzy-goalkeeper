import 'dart:convert';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';  // Temporarily disabled
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/models/contract_notification_data.dart';
import '../data/models/full_lobby_notification_data.dart';
import '../data/models/notification_error.dart';
import '../data/repositories/notification_preferences_repository.dart';
import '../../../core/navigation/navigation_service.dart';
import 'notification_error_handler.dart';
import 'notification_retry_manager.dart';

class NotificationService with ChangeNotifier {
  FirebaseMessaging? _firebaseMessaging;
  final NotificationPreferencesRepository _preferencesRepository;
  final NotificationErrorHandler _errorHandler = NotificationErrorHandler.instance;
  final NotificationRetryManager _retryManager = NotificationRetryManager.instance;
  
  // Temporarily disabled local notifications
  // final FlutterLocalNotificationsPlugin _localNotifications =
  //     FlutterLocalNotificationsPlugin();

  static const String _channelId = 'goalkeeper_notifications';
  static const String _channelName = 'Goalkeeper Notifications';
  static const String _channelDescription = 'Notifications for goalkeeper bookings';

  bool _isInitialized = false;
  String? _fcmToken;
  NotificationError? _lastError;
  bool _hasPermissions = false;

  // Callbacks
  Function(Map<String, dynamic>)? onNotificationTapped;
  Function(Map<String, dynamic>)? onNotificationReceived;
  Function(NotificationError)? onError;

  NotificationService({NotificationPreferencesRepository? preferencesRepository})
      : _preferencesRepository = preferencesRepository ?? NotificationPreferencesRepository();

  /// Initialize the core notification service (pre-user login)
  Future<NotificationResult<void>> initialize() async {
    if (_isInitialized) {
      return NotificationResult.success(null);
    }

    return await _retryManager.executeWithRetry(
      'notification_service_init',
      () async {
        // Check if Firebase is available
        if (Firebase.apps.isEmpty) {
          debugPrint('Firebase not initialized - push notifications will be disabled');
          _isInitialized = true;
          return;
        }

        _firebaseMessaging = FirebaseMessaging.instance;

        // Request notification permissions
        final permissionResult = await _requestPermissions();
        if (!permissionResult.isSuccess) {
          throw permissionResult.error!;
        }

        // Initialize local notifications
        // await _initializeLocalNotifications();  // Temporarily disabled

        // Initialize Firebase messaging handlers
        final messagingResult = await _initializeFirebaseMessaging();
        if (!messagingResult.isSuccess) {
          throw messagingResult.error!;
        }

        _isInitialized = true;
        _lastError = null;
        debugPrint('NotificationService core components initialized successfully');
        notifyListeners();
      },
      context: {'operation': 'initialize'},
    );
  }

  /// Actions to perform when a user signs in
  Future<void> onUserSignIn() async {
    if (!_isInitialized) {
      debugPrint('NotificationService not initialized. Call initialize() first.');
      return;
    }
    await _getFCMToken();
  }

  /// Request notification permissions
  Future<NotificationResult<void>> _requestPermissions() async {
    return await _retryManager.executeWithRetry(
      'request_permissions',
      () async {
        if (_firebaseMessaging == null) {
          throw NotificationError.serviceInitialization(
            message: 'Firebase messaging not initialized',
            userMessage: 'Serviço de mensagens não inicializado.',
          );
        }

        try {
          // Request notification permission from Firebase
          if (_firebaseMessaging == null) {
            debugPrint('Firebase messaging not available - skipping permission request');
            return;
          }
          
          final settings = await _firebaseMessaging!.requestPermission(
            alert: true,
            announcement: false,
            badge: true,
            carPlay: false,
            criticalAlert: false,
            provisional: false,
            sound: true,
          );

          debugPrint('Notification permission status: ${settings.authorizationStatus}');

          // Check if permission was granted
          if (settings.authorizationStatus == AuthorizationStatus.denied) {
            throw NotificationError.permission(
              message: 'Notification permission denied by user',
              userMessage: 'Permissão para notificações negada.',
              technicalDetails: 'AuthorizationStatus: ${settings.authorizationStatus}',
            );
          }

          // Request additional permissions for Android
          if (Platform.isAndroid) {
            final androidPermission = await Permission.notification.request();
            if (androidPermission.isDenied) {
              throw NotificationError.permission(
                message: 'Android notification permission denied',
                userMessage: 'Permissão para notificações negada no Android.',
                technicalDetails: 'PermissionStatus: $androidPermission',
              );
            }
          }

          _hasPermissions = true;
        } catch (e) {
          if (e is NotificationError) rethrow;
          
          throw NotificationError.permission(
            message: 'Failed to request notification permissions: $e',
            userMessage: 'Falha ao solicitar permissões de notificação.',
            technicalDetails: e.toString(),
            originalException: e is Exception ? e : Exception(e.toString()),
          );
        }
      },
      context: {'operation': 'request_permissions'},
    );
  }

  /// Initialize local notifications - temporarily disabled
  /*
  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onLocalNotificationTapped,
    );

    // Create notification channel for Android
    if (Platform.isAndroid) {
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDescription,
        importance: Importance.high,
        enableVibration: true,
        playSound: true,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }
  }
  */

  /// Initialize Firebase messaging
  Future<NotificationResult<void>> _initializeFirebaseMessaging() async {
    return await _retryManager.executeWithRetry(
      'firebase_messaging_init',
      () async {
        if (_firebaseMessaging == null) {
          throw NotificationError.serviceInitialization(
            message: 'Firebase messaging not initialized',
            userMessage: 'Serviço de mensagens não inicializado.',
          );
        }

        try {
          // Handle background messages
          FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

          // Handle foreground messages
          FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

          // Handle notification tap when app is in background
          FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

          // Handle notification tap when app is terminated
          if (_firebaseMessaging != null) {
            RemoteMessage? initialMessage = await _firebaseMessaging!.getInitialMessage();
            if (initialMessage != null) {
              _handleNotificationTap(initialMessage);
            }
          }

          debugPrint('Firebase messaging handlers initialized successfully');
        } catch (e) {
          throw NotificationError.firebase(
            message: 'Failed to initialize Firebase messaging: $e',
            userMessage: 'Falha ao inicializar mensagens push.',
            technicalDetails: e.toString(),
            originalException: e is Exception ? e : Exception(e.toString()),
          );
        }
      },
      context: {'operation': 'firebase_messaging_init'},
    );
  }

  /// Get FCM token and save it to Supabase
  Future<NotificationResult<void>> _getFCMToken() async {
    return await _retryManager.executeWithRetry(
      'get_fcm_token',
      () async {
        if (_firebaseMessaging == null) {
          throw NotificationError.serviceInitialization(
            message: 'Firebase messaging not initialized',
            userMessage: 'Serviço de mensagens não inicializado.',
          );
        }

        try {
          if (_firebaseMessaging == null) {
            debugPrint('Firebase messaging not available - skipping FCM token retrieval');
            return;
          }
          
          _fcmToken = await _firebaseMessaging!.getToken();
          if (_fcmToken != null) {
            debugPrint('FCM Token: $_fcmToken');
            final saveResult = await _saveFCMTokenToSupabase(_fcmToken!);
            if (!saveResult.isSuccess) {
              throw saveResult.error!;
            }
          } else {
            throw NotificationError(
              type: NotificationErrorType.fcmTokenError,
              severity: NotificationErrorSeverity.medium,
              message: 'Failed to get FCM token',
              userMessage: 'Falha ao obter token de notificação.',
              recoveryStrategy: NotificationErrorRecoveryStrategy.retry,
            );
          }

          // Listen for token refresh
          _firebaseMessaging!.onTokenRefresh.listen((newToken) {
            _fcmToken = newToken;
            _saveFCMTokenToSupabase(newToken).then((result) {
              if (!result.isSuccess) {
                _lastError = result.error;
                onError?.call(result.error!);
                notifyListeners();
              }
            });
          });
        } catch (e) {
          if (e is NotificationError) rethrow;
          
          throw NotificationError(
            type: NotificationErrorType.fcmTokenError,
            severity: NotificationErrorSeverity.medium,
            message: 'Error getting FCM token: $e',
            userMessage: 'Erro ao obter token de notificação.',
            technicalDetails: e.toString(),
            originalException: e is Exception ? e : Exception(e.toString()),
            recoveryStrategy: NotificationErrorRecoveryStrategy.retry,
          );
        }
      },
      context: {'operation': 'get_fcm_token'},
    );
  }

  /// Save FCM token to Supabase
  Future<NotificationResult<void>> _saveFCMTokenToSupabase(String token) async {
    return await _retryManager.executeWithRetry(
      'save_fcm_token',
      () async {
        try {
          final user = Supabase.instance.client.auth.currentUser;
          if (user == null) {
            throw NotificationError(
              type: NotificationErrorType.authenticationError,
              severity: NotificationErrorSeverity.medium,
              message: 'User not authenticated',
              userMessage: 'Usuário não autenticado.',
              recoveryStrategy: NotificationErrorRecoveryStrategy.userAction,
            );
          }

          final platform = Platform.isAndroid ? 'android' : Platform.isIOS ? 'ios' : 'web';

          await Supabase.instance.client.from('fcm_tokens').upsert({
            'user_id': user.id,
            'token': token,
            'platform': platform,
            'is_active': true,
            'updated_at': DateTime.now().toIso8601String(),
          });

          debugPrint('FCM token saved to Supabase');
        } catch (e) {
          if (e is NotificationError) rethrow;
          
          throw NotificationError.supabase(
            message: 'Failed to save FCM token: $e',
            userMessage: 'Falha ao salvar token de notificação.',
            technicalDetails: e.toString(),
            originalException: e is Exception ? e : Exception(e.toString()),
          );
        }
      },
      context: {'operation': 'save_fcm_token', 'token': token},
    );
  }

  /// Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Foreground message received: ${message.notification?.title}');
    
    // Show local notification when app is in foreground
    // _showLocalNotification(message);  // Temporarily disabled
    
    // Call callback if set
    if (onNotificationReceived != null && message.data.isNotEmpty) {
      onNotificationReceived!(message.data);
    }
  }

  /// Handle notification tap with enhanced navigation
  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('Notification tapped: ${message.data}');
    
    // Use the enhanced navigation service for better handling
    NavigationService.handlePushNotificationTap(message.data);
    
    if (onNotificationTapped != null && message.data.isNotEmpty) {
      onNotificationTapped!(message.data);
    }
  }

  /// Handle navigation based on notification data (deprecated - using NavigationService)
  void _handleNotificationNavigation(Map<String, dynamic> data) {
    NavigationService.handlePushNotificationTap(data);
  }

  /// Navigate to contract details or notifications screen (deprecated)
  void _navigateToContractDetails(BuildContext context, Map<String, dynamic> data) {
    NavigationService.pushToContractDetails(context, data);
  }

  /// Navigate to announcement details (deprecated)
  void _navigateToAnnouncementDetails(BuildContext context, Map<String, dynamic> data) {
    NavigationService.handleNotificationDeepLink(context, data);
  }

  /// Navigate to notifications screen (deprecated)
  void _navigateToNotifications(BuildContext context) {
    NavigationService.pushToNotifications(context);
  }

  /// Handle local notification tap - temporarily disabled
  /*
  void _onLocalNotificationTapped(NotificationResponse response) {
    debugPrint('Local notification tapped: ${response.payload}');
    
    if (onNotificationTapped != null && response.payload != null) {
      try {
        final data = json.decode(response.payload!) as Map<String, dynamic>;
        onNotificationTapped!(data);
      } catch (e) {
        debugPrint('Error parsing notification payload: $e');
      }
    }
  }
  */

  /// Show local notification - temporarily disabled
  /*
  Future<void> _showLocalNotification(RemoteMessage message) async {
    try {
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        enableVibration: true,
        playSound: true,
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.show(
        message.hashCode,
        message.notification?.title ?? 'Nova Notificação',
        message.notification?.body ?? '',
        notificationDetails,
        payload: json.encode(message.data),
      );
    } catch (e) {
      debugPrint('Error showing local notification: $e');
    }
  }
  */

  /// Send contract request push notification
  Future<NotificationResult<void>> sendContractNotification({
    required String goalkeeperUserId,
    required ContractNotificationData data,
  }) async {
    return await _retryManager.executeWithRetry(
      'send_contract_notification',
      () async {
        try {
          // Check if user has contract notifications enabled
          final isEnabled = await _preferencesRepository.isNotificationTypeEnabled(
            userId: goalkeeperUserId,
            notificationType: 'contract_request',
          );

          if (!isEnabled) {
            debugPrint('Contract notifications disabled for user: $goalkeeperUserId');
            return;
          }

          // Get goalkeeper's FCM tokens
          final tokens = await _getUserFCMTokens(goalkeeperUserId);
          if (tokens.isEmpty) {
            throw NotificationError(
              type: NotificationErrorType.fcmTokenError,
              severity: NotificationErrorSeverity.medium,
              message: 'No FCM tokens found for goalkeeper: $goalkeeperUserId',
              userMessage: 'Usuário não tem dispositivos registrados para notificações.',
              recoveryStrategy: NotificationErrorRecoveryStrategy.ignore,
            );
          }

          // Format notification content
          final title = 'Nova Proposta de Contrato';
          final body = '${data.contractorName} quer contratá-lo para um jogo';
          
          // Prepare notification data
          final notificationData = {
            'type': 'contract_request',
            'contract_id': data.contractId,
            'contractor_id': data.contractorId,
            'contractor_name': data.contractorName,
            'contractor_avatar_url': data.contractorAvatarUrl,
            'announcement_id': data.announcementId,
            'announcement_title': data.announcementTitle,
            'game_date_time': data.gameDateTime.toIso8601String(),
            'stadium': data.stadium,
            'offered_amount': data.offeredAmount?.toString(),
            'additional_notes': data.additionalNotes,
          };

          // Send push notification to all user's devices
          final List<Exception> failures = [];
          for (final token in tokens) {
            try {
              await _sendPushNotification(
                token: token,
                title: title,
                body: body,
                data: notificationData,
              );
            } catch (e) {
              failures.add(e is Exception ? e : Exception(e.toString()));
            }
          }

          // If all tokens failed, throw error
          if (failures.length == tokens.length) {
            throw NotificationError.pushNotificationError(
              message: 'Failed to send notification to all devices',
              userMessage: 'Falha ao enviar notificação.',
              technicalDetails: 'All ${tokens.length} tokens failed',
            );
          }

          debugPrint('Contract notification sent to goalkeeper: $goalkeeperUserId');
        } catch (e) {
          if (e is NotificationError) rethrow;
          
          throw NotificationError.pushNotificationError(
            message: 'Error sending contract notification: $e',
            userMessage: 'Erro ao enviar notificação de contrato.',
            technicalDetails: e.toString(),
            originalException: e is Exception ? e : Exception(e.toString()),
          );
        }
      },
      context: {
        'operation': 'send_contract_notification',
        'goalkeeper_user_id': goalkeeperUserId,
        'contract_id': data.contractId,
      },
    );
  }

  /// Send full lobby push notification
  Future<void> sendFullLobbyNotification({
    required String creatorUserId,
    required FullLobbyNotificationData data,
  }) async {
    try {
      // Check if user has full lobby notifications enabled
      final isEnabled = await _preferencesRepository.isNotificationTypeEnabled(
        userId: creatorUserId,
        notificationType: 'full_lobby',
      );

      if (!isEnabled) {
        debugPrint('Full lobby notifications disabled for user: $creatorUserId');
        return;
      }

      // Get creator's FCM tokens
      final tokens = await _getUserFCMTokens(creatorUserId);
      if (tokens.isEmpty) {
        debugPrint('No FCM tokens found for creator: $creatorUserId');
        return;
      }

      // Format notification content
      final title = 'Lobby Completo!';
      final body = 'O seu anúncio "${data.announcementTitle}" está completo ${data.participantCountDisplay}';
      
      // Prepare notification data
      final notificationData = {
        'type': 'full_lobby',
        'announcement_id': data.announcementId,
        'announcement_title': data.announcementTitle,
        'game_date_time': data.gameDateTime.toIso8601String(),
        'stadium': data.stadium,
        'participant_count': data.participantCount.toString(),
        'max_participants': data.maxParticipants.toString(),
      };

      // Send push notification to all user's devices
      for (final token in tokens) {
        await _sendPushNotification(
          token: token,
          title: title,
          body: body,
          data: notificationData,
        );
      }

      debugPrint('Full lobby notification sent to creator: $creatorUserId');
    } catch (e) {
      debugPrint('Error sending full lobby notification: $e');
    }
  }

  /// Get user's active FCM tokens
  Future<List<String>> _getUserFCMTokens(String userId) async {
    try {
      final response = await Supabase.instance.client
          .from('fcm_tokens')
          .select('token')
          .eq('user_id', userId)
          .eq('is_active', true);

      return (response as List<dynamic>)
          .map((row) => row['token'] as String)
          .toList();
    } catch (e) {
      debugPrint('Error getting user FCM tokens: $e');
      return [];
    }
  }

  /// Send push notification to specific token
  Future<void> _sendPushNotification({
    required String token,
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) async {
    try {
      // This would typically use Firebase Admin SDK or a backend service
      // For now, we'll log the notification details
      debugPrint('Sending push notification:');
      debugPrint('Token: $token');
      debugPrint('Title: $title');
      debugPrint('Body: $body');
      debugPrint('Data: $data');
      
      // In a real implementation, you would call your backend service here
      // that uses Firebase Admin SDK to send the notification
      // Example:
      // await _backendService.sendPushNotification(
      //   token: token,
      //   title: title,
      //   body: body,
      //   data: data,
      // );
      
    } catch (e) {
      debugPrint('Error sending push notification to token $token: $e');
    }
  }

  /// Parse notification data for navigation
  Map<String, dynamic>? parseNotificationData(Map<String, dynamic> data) {
    try {
      final notificationType = data['type'] as String?;
      
      switch (notificationType) {
        case 'contract_request':
          return _parseContractNotificationData(data);
        case 'full_lobby':
          return _parseFullLobbyNotificationData(data);
        default:
          return data;
      }
    } catch (e) {
      debugPrint('Error parsing notification data: $e');
      return null;
    }
  }

  /// Parse contract notification data
  Map<String, dynamic> _parseContractNotificationData(Map<String, dynamic> data) {
    return {
      'type': 'contract_request',
      'contract_id': data['contract_id'],
      'contractor_id': data['contractor_id'],
      'contractor_name': data['contractor_name'],
      'contractor_avatar_url': data['contractor_avatar_url'],
      'announcement_id': data['announcement_id'],
      'announcement_title': data['announcement_title'],
      'game_date_time': data['game_date_time'],
      'stadium': data['stadium'],
      'offered_amount': data['offered_amount'] != null 
          ? double.tryParse(data['offered_amount'].toString()) 
          : null,
      'additional_notes': data['additional_notes'],
    };
  }

  /// Parse full lobby notification data
  Map<String, dynamic> _parseFullLobbyNotificationData(Map<String, dynamic> data) {
    return {
      'type': 'full_lobby',
      'announcement_id': data['announcement_id'],
      'announcement_title': data['announcement_title'],
      'game_date_time': data['game_date_time'],
      'stadium': data['stadium'],
      'participant_count': int.tryParse(data['participant_count'].toString()) ?? 0,
      'max_participants': int.tryParse(data['max_participants'].toString()) ?? 0,
    };
  }

  /// Get current FCM token
  String? get fcmToken => _fcmToken;

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    if (_firebaseMessaging == null) return false;
    try {
      final settings = await _firebaseMessaging!.getNotificationSettings();
      return settings.authorizationStatus == AuthorizationStatus.authorized;
    } catch (e) {
      debugPrint('Error checking notification settings: $e');
      return false;
    }
  }

  /// Disable FCM token (when user logs out)
  Future<void> disableToken() async {
    try {
      if (_fcmToken != null) {
        final user = Supabase.instance.client.auth.currentUser;
        if (user != null) {
          await Supabase.instance.client
              .from('fcm_tokens')
              .update({'is_active': false})
              .eq('user_id', user.id)
              .eq('token', _fcmToken!);
        }
      }
    } catch (e) {
      debugPrint('Error disabling FCM token: $e');
    }
  }
}

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
    debugPrint('Background message received: ${message.notification?.title}');
  } catch (e) {
    debugPrint('Firebase not available in background handler: $e');
  }
}

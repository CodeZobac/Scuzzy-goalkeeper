import 'dart:convert';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';  // Temporarily disabled
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationService with ChangeNotifier {
  FirebaseMessaging? _firebaseMessaging;
  
  // Temporarily disabled local notifications
  // final FlutterLocalNotificationsPlugin _localNotifications =
  //     FlutterLocalNotificationsPlugin();

  static const String _channelId = 'goalkeeper_notifications';
  static const String _channelName = 'Goalkeeper Notifications';
  static const String _channelDescription = 'Notifications for goalkeeper bookings';

  bool _isInitialized = false;
  String? _fcmToken;

  // Callbacks
  Function(Map<String, dynamic>)? onNotificationTapped;
  Function(Map<String, dynamic>)? onNotificationReceived;

  /// Initialize the core notification service (pre-user login)
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Firebase must be initialized before this point
      if (Firebase.apps.isEmpty) {
        debugPrint('Firebase not initialized. Call Firebase.initializeApp() in main.dart before this.');
        return;
      }
      _firebaseMessaging = FirebaseMessaging.instance;

      // Request notification permissions
      await _requestPermissions();

      // Initialize local notifications
      // await _initializeLocalNotifications();  // Temporarily disabled

      // Initialize Firebase messaging handlers
      await _initializeFirebaseMessaging();

      _isInitialized = true;
      debugPrint('NotificationService core components initialized successfully');
    } catch (e) {
      debugPrint('Error initializing NotificationService core: $e');
    }
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
  Future<void> _requestPermissions() async {
    if (_firebaseMessaging == null) return;
    // Request notification permission from Firebase
    NotificationSettings settings = await _firebaseMessaging!.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    debugPrint('Notification permission status: ${settings.authorizationStatus}');

    // Request additional permissions for Android
    if (Platform.isAndroid) {
      await Permission.notification.request();
    }
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
  Future<void> _initializeFirebaseMessaging() async {
    if (_firebaseMessaging == null) return;
    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle notification tap when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Handle notification tap when app is terminated
    RemoteMessage? initialMessage = await _firebaseMessaging!.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }
  }

  /// Get FCM token and save it to Supabase
  Future<void> _getFCMToken() async {
    if (_firebaseMessaging == null) return;
    try {
      _fcmToken = await _firebaseMessaging!.getToken();
      if (_fcmToken != null) {
        debugPrint('FCM Token: $_fcmToken');
        await _saveFCMTokenToSupabase(_fcmToken!);
      }

      // Listen for token refresh
      _firebaseMessaging!.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        _saveFCMTokenToSupabase(newToken);
      });
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
    }
  }

  /// Save FCM token to Supabase
  Future<void> _saveFCMTokenToSupabase(String token) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

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
      debugPrint('Error saving FCM token to Supabase: $e');
    }
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

  /// Handle notification tap
  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('Notification tapped: ${message.data}');
    
    if (onNotificationTapped != null && message.data.isNotEmpty) {
      onNotificationTapped!(message.data);
    }
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

  /// Get current FCM token
  String? get fcmToken => _fcmToken;

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    if (_firebaseMessaging == null) return false;
    final settings = await _firebaseMessaging!.getNotificationSettings();
    return settings.authorizationStatus == AuthorizationStatus.authorized;
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
  await Firebase.initializeApp();
  debugPrint('Background message received: ${message.notification?.title}');
}

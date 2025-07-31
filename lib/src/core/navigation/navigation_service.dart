import 'package:flutter/material.dart';

class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static NavigatorState? get navigator => navigatorKey.currentState;

  // Smooth slide transition for announcement detail
  static Future<T?> pushAnnouncementDetail<T extends Object?>(
    BuildContext context,
    Object announcement,
  ) {
    return Navigator.of(context).pushNamed<T>(
      '/announcement-detail',
      arguments: announcement,
    );
  }

  // Fade transition for general navigation
  static Future<T?> pushWithFadeTransition<T extends Object?>(
    BuildContext context,
    Widget page,
  ) {
    return Navigator.of(context).push<T>(
      _createFadeRoute<T>(page),
    );
  }

  // Scale transition for modal-like screens
  static Future<T?> pushWithScaleTransition<T extends Object?>(
    BuildContext context,
    Widget page,
  ) {
    return Navigator.of(context).push<T>(
      _createScaleRoute<T>(page),
    );
  }

  // Fade transition
  static PageRouteBuilder<T> _createFadeRoute<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: const Duration(milliseconds: 250),
      reverseTransitionDuration: const Duration(milliseconds: 200),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
    );
  }

  // Scale transition
  static PageRouteBuilder<T> _createScaleRoute<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 250),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = 0.8;
        const end = 1.0;
        const curve = Curves.easeInOutBack;

        var tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );

        var scaleAnimation = animation.drive(tween);
        var fadeAnimation = animation.drive(
          Tween(begin: 0.0, end: 1.0).chain(
            CurveTween(curve: Curves.easeInOut),
          ),
        );

        return FadeTransition(
          opacity: fadeAnimation,
          child: ScaleTransition(
            scale: scaleAnimation,
            child: child,
          ),
        );
      },
    );
  }

  // Navigation to map screen with smooth transition
  static Future<T?> pushToMap<T extends Object?>(BuildContext context, {
    double? fieldLatitude,
    double? fieldLongitude,
    String? fieldName,
  }) {
    final arguments = <String, dynamic>{};
    if (fieldLatitude != null) arguments['fieldLatitude'] = fieldLatitude;
    if (fieldLongitude != null) arguments['fieldLongitude'] = fieldLongitude;
    if (fieldName != null) arguments['fieldName'] = fieldName;
    
    return Navigator.of(context).pushNamed<T>(
      '/map',
      arguments: arguments.isNotEmpty ? arguments : null,
    );
  }

  // Navigation to announcements screen
  static Future<T?> pushToAnnouncements<T extends Object?>(BuildContext context) {
    return Navigator.of(context).pushNamed<T>('/announcements');
  }

  // Navigation helpers
  static void pop<T extends Object?>(BuildContext context, [T? result]) {
    Navigator.of(context).pop(result);
  }

  static void popUntil(BuildContext context, String routeName) {
    Navigator.of(context).popUntil(ModalRoute.withName(routeName));
  }

  static Future<T?> pushReplacementNamed<T extends Object?, TO extends Object?>(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) {
    return Navigator.of(context).pushReplacementNamed<T, TO>(
      routeName,
      arguments: arguments,
    );
  }

  static Future<T?> pushNamedAndClearStack<T extends Object?>(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) {
    return Navigator.of(context).pushNamedAndRemoveUntil<T>(
      routeName,
      (route) => false,
      arguments: arguments,
    );
  }

  // Check if we can pop the current route
  static bool canPop(BuildContext context) {
    return Navigator.of(context).canPop();
  }

  // Pop with custom result handling
  static void popWithResult<T extends Object?>(
    BuildContext context,
    T result,
  ) {
    Navigator.of(context).pop<T>(result);
  }

  // Navigate back to home screen (main screen)
  static Future<T?> pushToHome<T extends Object?>(BuildContext context) {
    return Navigator.of(context).pushNamedAndRemoveUntil<T>(
      '/home',
      (route) => false,
    );
  }

  // Get current route name
  static String? getCurrentRouteName(BuildContext context) {
    return ModalRoute.of(context)?.settings.name;
  }

  // Navigate with custom transition animation
  static Future<T?> pushWithCustomTransition<T extends Object?>(
    BuildContext context,
    Widget page, {
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeInOut,
  }) {
    return Navigator.of(context).push<T>(
      PageRouteBuilder<T>(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionDuration: duration,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: curve,
            )),
            child: child,
          );
        },
      ),
    );
  }

  // Enhanced notification navigation methods

  /// Navigate to notifications screen with optional category selection
  static Future<T?> pushToNotifications<T extends Object?>(
    BuildContext context, {
    String? category,
  }) {
    return Navigator.of(context).pushNamed<T>(
      '/notifications',
      arguments: category != null ? {'category': category} : null,
    );
  }

  /// Navigate to contract details screen
  static Future<T?> pushToContractDetails<T extends Object?>(
    BuildContext context,
    Map<String, dynamic> contractData,
  ) {
    return Navigator.of(context).pushNamed<T>(
      '/contract-details',
      arguments: contractData,
    );
  }

  /// Handle notification deep link navigation
  static Future<T?> handleNotificationDeepLink<T extends Object?>(
    BuildContext context,
    Map<String, dynamic> notificationData,
  ) {
    return Navigator.of(context).pushNamed<T>(
      '/notification-deep-link',
      arguments: notificationData,
    );
  }

  /// Navigate to main screen with specific tab selected
  static Future<T?> pushToMainWithTab<T extends Object?>(
    BuildContext context,
    int tabIndex,
  ) {
    return Navigator.of(context).pushNamedAndRemoveUntil<T>(
      '/home',
      (route) => false,
      arguments: {'selectedTab': tabIndex},
    );
  }

  /// Navigate to notifications tab in main screen
  static Future<T?> pushToNotificationsTab<T extends Object?>(
    BuildContext context,
  ) {
    return pushToMainWithTab<T>(context, 2); // Notifications is index 2 in navbar
  }

  /// Navigate from push notification tap
  static Future<void> handlePushNotificationTap(
    Map<String, dynamic> notificationData,
  ) async {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    final type = notificationData['type'] as String?;
    
    try {
      switch (type) {
        case 'contract_request':
          await handleNotificationDeepLink(context, notificationData);
          break;
        case 'full_lobby':
          await handleNotificationDeepLink(context, notificationData);
          break;
        case 'booking_request':
        case 'booking_confirmed':
        case 'booking_cancelled':
          await pushToNotifications(context);
          break;
        default:
          await pushToNotifications(context);
      }
    } catch (e) {
      debugPrint('Error handling push notification tap: $e');
      // Fallback to notifications screen
      await pushToNotifications(context);
    }
  }

  /// Navigate back to main screen from any screen
  static Future<T?> backToMain<T extends Object?>(BuildContext context) {
    return Navigator.of(context).pushNamedAndRemoveUntil<T>(
      '/home',
      (route) => false,
    );
  }

  /// Check if current route is main screen
  static bool isOnMainScreen(BuildContext context) {
    final currentRoute = getCurrentRouteName(context);
    return currentRoute == '/home';
  }

  /// Navigate with proper back stack management for notifications
  static Future<T?> pushFromNotification<T extends Object?>(
    BuildContext context,
    String routeName, {
    Object? arguments,
    bool clearStack = false,
  }) {
    if (clearStack) {
      return Navigator.of(context).pushNamedAndRemoveUntil<T>(
        routeName,
        (route) => route.settings.name == '/home',
        arguments: arguments,
      );
    } else {
      return Navigator.of(context).pushNamed<T>(
        routeName,
        arguments: arguments,
      );
    }
  }

  /// Get navigation context safely
  static BuildContext? getNavigationContext() {
    return navigatorKey.currentContext;
  }

  /// Check if navigator is ready
  static bool get isNavigatorReady => navigatorKey.currentState != null;

  /// Safe navigation method that checks if navigator is ready
  static Future<T?> safeNavigate<T extends Object?>(
    Future<T?> Function(BuildContext) navigationFunction,
  ) async {
    final context = getNavigationContext();
    if (context == null || !isNavigatorReady) {
      debugPrint('Navigator not ready for navigation');
      return null;
    }
    
    try {
      return await navigationFunction(context);
    } catch (e) {
      debugPrint('Navigation error: $e');
      return null;
    }
  }
}
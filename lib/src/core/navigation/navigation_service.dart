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
  static Future<T?> pushToMap<T extends Object?>(BuildContext context) {
    return Navigator.of(context).pushNamed<T>('/map');
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
}
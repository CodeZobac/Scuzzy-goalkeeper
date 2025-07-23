import 'package:flutter/material.dart';

/// Utility class for handling responsive design across different screen sizes
class ResponsiveUtils {
  // Breakpoints
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;

  /// Check if the current screen is mobile
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobileBreakpoint;
  }

  /// Check if the current screen is tablet
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobileBreakpoint && width < tabletBreakpoint;
  }

  /// Check if the current screen is desktop
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= desktopBreakpoint;
  }

  /// Get responsive value based on screen size
  static T getResponsiveValue<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    if (isDesktop(context) && desktop != null) {
      return desktop;
    } else if (isTablet(context) && tablet != null) {
      return tablet;
    } else {
      return mobile;
    }
  }

  /// Get responsive padding for authentication screens
  static EdgeInsets getAuthPadding(BuildContext context) {
    return getResponsiveValue(
      context,
      mobile: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      tablet: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      desktop: const EdgeInsets.symmetric(horizontal: 60, vertical: 32),
    );
  }

  /// Get responsive content width for authentication forms
  static double getAuthContentWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    if (isDesktop(context)) {
      return (screenWidth * 0.4).clamp(400.0, 500.0);
    } else if (isTablet(context)) {
      return (screenWidth * 0.6).clamp(350.0, 450.0);
    } else {
      return screenWidth - 48; // Mobile with 24px padding on each side
    }
  }

  /// Get responsive font size
  static double getResponsiveFontSize(
    BuildContext context, {
    required double mobile,
    double? tablet,
    double? desktop,
  }) {
    return getResponsiveValue(
      context,
      mobile: mobile,
      tablet: tablet ?? mobile * 1.1,
      desktop: desktop ?? mobile * 1.2,
    );
  }

  /// Get responsive spacing
  static double getResponsiveSpacing(
    BuildContext context, {
    required double mobile,
    double? tablet,
    double? desktop,
  }) {
    return getResponsiveValue(
      context,
      mobile: mobile,
      tablet: tablet ?? mobile * 1.2,
      desktop: desktop ?? mobile * 1.4,
    );
  }

  /// Get responsive header height for auth screens
  static double getAuthHeaderHeight(BuildContext context) {
    return getResponsiveValue(
      context,
      mobile: 240.0,
      tablet: 280.0,
      desktop: 320.0,
    );
  }

  /// Get responsive card elevation
  static double getResponsiveElevation(BuildContext context) {
    return getResponsiveValue(
      context,
      mobile: 8.0,
      tablet: 12.0,
      desktop: 16.0,
    );
  }

  /// Check if keyboard is visible
  static bool isKeyboardVisible(BuildContext context) {
    return MediaQuery.of(context).viewInsets.bottom > 0;
  }

  /// Get safe area padding
  static EdgeInsets getSafeAreaPadding(BuildContext context) {
    return MediaQuery.of(context).padding;
  }

  /// Get responsive border radius
  static BorderRadius getResponsiveBorderRadius(BuildContext context) {
    return BorderRadius.circular(
      getResponsiveValue(
        context,
        mobile: 16.0,
        tablet: 20.0,
        desktop: 24.0,
      ),
    );
  }
}

/// Extension on BuildContext for easier access to responsive utilities
extension ResponsiveContext on BuildContext {
  bool get isMobile => ResponsiveUtils.isMobile(this);
  bool get isTablet => ResponsiveUtils.isTablet(this);
  bool get isDesktop => ResponsiveUtils.isDesktop(this);
  bool get isKeyboardVisible => ResponsiveUtils.isKeyboardVisible(this);
  
  EdgeInsets get authPadding => ResponsiveUtils.getAuthPadding(this);
  double get authContentWidth => ResponsiveUtils.getAuthContentWidth(this);
  double get authHeaderHeight => ResponsiveUtils.getAuthHeaderHeight(this);
  EdgeInsets get safeAreaPadding => ResponsiveUtils.getSafeAreaPadding(this);
  BorderRadius get responsiveBorderRadius => ResponsiveUtils.getResponsiveBorderRadius(this);
}
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Main App Palette (Dark Theme for Main App)
  static const Color primaryBackground = Color(0xFF1A1A2E);
  static const Color secondaryBackground = Color(0xFF16213E);
  static const Color accentColor = Color(0xFF00A85A);
  static const Color primaryText = Color(0xFFF0F0F0);
  static const Color secondaryText = Color(0xFFA9A9A9);
  static const Color errorColor = Color(0xFFFF6B6B);
  static const Color successColor = Color(0xFF4ECDC4);
  
  // Auth Theme Colors (White/Green matching announcements and map)
  static const Color authPrimaryGreen = Color(0xFF4CAF50);
  static const Color authSecondaryGreen = Color(0xFF45A049);
  static const Color authLightGreen = Color(0xFF66BB6A);
  static const Color authBackground = Color(0xFFF8F9FA);
  static const Color authCardBackground = Color(0xFFFFFFFF);
  static const Color authTextPrimary = Color(0xFF2C2C2C);
  static const Color authTextSecondary = Color(0xFF757575);
  static const Color authTextLight = Color(0xFFFFFFFF);
  static const Color authInputBackground = Color(0xFFFFFFFF);
  static const Color authInputBorder = Color(0xFFE0E0E0);
  static const Color authInputFocused = Color(0xFF4CAF50);
  static const Color authError = Color(0xFFFF6B6B);
  static const Color authSuccess = Color(0xFF4CAF50);
  
  // Auth Theme Gradients
  static const LinearGradient authPrimaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      authPrimaryGreen,
      authSecondaryGreen,
    ],
  );

  static const LinearGradient authButtonGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      authPrimaryGreen,
      authLightGreen,
    ],
  );

  static const LinearGradient authBackgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      authPrimaryGreen,
      authSecondaryGreen,
    ],
  );
  
  // Main App Gradients (Keep original dark theme)
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF1A1A2E),
      Color(0xFF16213E),
    ],
  );

  static const LinearGradient buttonGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      Color(0xFFE94560),
      Color(0xFFFF6B6B),
    ],
  );

  // Estilos de Texto (Main App - Dark Theme)
  static TextStyle get headingLarge => GoogleFonts.poppins(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: primaryText,
    height: 1.2,
  );

  static TextStyle get headingMedium => GoogleFonts.poppins(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: primaryText,
    height: 1.3,
  );

  static TextStyle get bodyLarge => GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: primaryText,
    height: 1.5,
  );

  static TextStyle get bodyMedium => GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: secondaryText,
    height: 1.4,
  );

  static TextStyle get buttonText => GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    letterSpacing: 0.5,
  );

  static TextStyle get linkText => GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: accentColor,
    decoration: TextDecoration.underline,
  );

  // Auth Theme Text Styles (White/Green Theme)
  static TextStyle get authHeadingLarge => GoogleFonts.poppins(
    fontSize: 34,
    fontWeight: FontWeight.bold,
    color: authTextPrimary,
    height: 1.2,
  );

  static TextStyle get authHeadingMedium => GoogleFonts.poppins(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: authTextPrimary,
    height: 1.3,
  );

  static TextStyle get authHeadingSmall => GoogleFonts.poppins(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: authTextPrimary,
    height: 1.3,
  );

  static TextStyle get authBodyLarge => GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: authTextPrimary,
    height: 1.5,
  );

  static TextStyle get authBodyMedium => GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: authTextSecondary,
    height: 1.4,
  );

  static TextStyle get authButtonText => GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: authTextLight,
    letterSpacing: 0.5,
  );

  static TextStyle get authLinkText => GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: authPrimaryGreen,
    decoration: TextDecoration.none,
  );

  static TextStyle get authInputText => GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: authTextPrimary,
    height: 1.4,
  );

  static TextStyle get authHintText => GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: authTextSecondary,
    height: 1.4,
  );

  static TextStyle get authBodyText => GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: authTextSecondary,
    height: 1.4,
  );

  // Theme Data
  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primarySwatch: Colors.pink,
    primaryColor: accentColor,
    scaffoldBackgroundColor: primaryBackground,
    fontFamily: GoogleFonts.poppins().fontFamily,
    
    // AppBar Theme
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: headingMedium,
      iconTheme: const IconThemeData(color: primaryText),
    ),

    // Input Decoration Theme
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: secondaryBackground,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: accentColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: errorColor, width: 2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: errorColor, width: 2),
      ),
      hintStyle: GoogleFonts.poppins(
        color: secondaryText,
        fontSize: 14,
      ),
      labelStyle: GoogleFonts.poppins(
        color: secondaryText,
        fontSize: 16,
      ),
      errorStyle: GoogleFonts.poppins(
        color: errorColor,
        fontSize: 12,
      ),
    ),

    // Button Themes
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: accentColor,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: authButtonText,
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: accentColor,
        textStyle: authLinkText,
      ),
    ),

    // Card Theme
    cardTheme: CardThemeData(
      color: secondaryBackground,
      elevation: 8,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),

    // Icon Theme
    iconTheme: const IconThemeData(
      color: secondaryText,
      size: 24,
    ),

    // Color Scheme
    colorScheme: const ColorScheme.dark(
      primary: accentColor,
      secondary: successColor,
      background: primaryBackground,
      surface: secondaryBackground,
      error: errorColor,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onBackground: primaryText,
      onSurface: primaryText,
      onError: Colors.white,
    ),
  );

  // Constantes de Layout
  static const double borderRadius = 12.0;
  static const double borderRadiusLarge = 16.0;
  static const double cardElevation = 8.0;
  static const double spacing = 16.0;
  static const double spacingLarge = 24.0;
  static const double spacingSmall = 8.0;

  // Modern Theme Colors (for compatibility with ModernTextField)
  static const Color primaryGreen = authPrimaryGreen;
  static const Color textDark = authTextPrimary;
  static const Color textSecondary = authTextSecondary;
  static const Color surfaceLight = authInputBackground;
  static const Color borderLight = authInputBorder;
  
  // Modern Theme Text Styles (for compatibility)
  static TextStyle get bodySmall => GoogleFonts.poppins(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: authTextSecondary,
    height: 1.4,
  );

  // Duração das Animações
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);
}

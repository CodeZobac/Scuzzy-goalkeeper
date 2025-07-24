import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Firebase configuration helper
class FirebaseConfig {
  static bool _isInitialized = false;
  
  /// Check if Firebase is properly configured and initialized
  static bool get isAvailable => _isInitialized && Firebase.apps.isNotEmpty;
  
  /// Initialize Firebase with proper error handling
  static Future<bool> initialize() async {
    try {
      await Firebase.initializeApp();
      _isInitialized = true;
      debugPrint('Firebase initialized successfully');
      return true;
    } catch (e) {
      debugPrint('Firebase initialization failed: $e');
      debugPrint('Note: Firebase configuration files may be missing');
      debugPrint('Push notifications will not work without Firebase configuration');
      _isInitialized = false;
      return false;
    }
  }
  
  /// Get Firebase initialization status
  static bool get isInitialized => _isInitialized;
}
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:uni_links/uni_links.dart';
import '../logging/error_logger.dart';

/// Service to handle deep links, especially for password reset flow
class DeepLinkService {
  static final DeepLinkService _instance = DeepLinkService._internal();
  factory DeepLinkService() => _instance;
  DeepLinkService._internal();

  static DeepLinkService get instance => _instance;

  StreamSubscription<String?>? _linkSubscription;
  Uri? _initialUri;
  bool _isInitialized = false;

  /// Callback function to handle deep link routing
  Function(Uri)? onDeepLinkReceived;

  /// Initialize the deep link service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Get the initial URI when the app was launched from a link
      _initialUri = await getInitialUri();
      
      if (_initialUri != null) {
        debugPrint('App launched with initial URI: $_initialUri');
        _handleDeepLink(_initialUri!);
      }

      // Listen for incoming links when the app is already running
      _linkSubscription = linkStream.listen(
        (String? uriString) {
          if (uriString != null) {
            final uri = Uri.parse(uriString);
            debugPrint('Deep link received: $uri');
            _handleDeepLink(uri);
          }
        },
        onError: (err) {
          ErrorLogger.logError(
            err is Exception ? err : Exception(err.toString()),
            StackTrace.current,
            context: 'DEEP_LINK_ERROR',
            severity: ErrorSeverity.error,
          );
        },
      );

      _isInitialized = true;
      
      ErrorLogger.logInfo(
        'Deep link service initialized successfully',
        context: 'DEEP_LINK_INIT',
      );

    } on PlatformException catch (e) {
      ErrorLogger.logError(
        e,
        StackTrace.current,
        context: 'DEEP_LINK_PLATFORM_ERROR',
        severity: ErrorSeverity.error,
        additionalData: {'platform_error': e.message},
      );
    } catch (e) {
      ErrorLogger.logError(
        e is Exception ? e : Exception(e.toString()),
        StackTrace.current,
        context: 'DEEP_LINK_INIT_ERROR',
        severity: ErrorSeverity.error,
      );
    }
  }

  /// Handle incoming deep links
  void _handleDeepLink(Uri uri) {
    try {
      // Log the deep link for debugging
      ErrorLogger.logInfo(
        'Processing deep link',
        context: 'DEEP_LINK_RECEIVED',
        additionalData: {
          'scheme': uri.scheme,
          'host': uri.host,
          'path': uri.path,
          'query_params': uri.queryParameters.toString(),
        },
      );

      // Check if this is our expected scheme
      if (uri.scheme == 'io.supabase.goalkeeper') {
        // Handle password reset deep link
        if (uri.host == 'reset-password') {
          _handlePasswordResetLink(uri);
        } else {
          debugPrint('Unknown deep link host: ${uri.host}');
        }
      } else {
        debugPrint('Unknown deep link scheme: ${uri.scheme}');
      }

      // Call the callback if set
      onDeepLinkReceived?.call(uri);

    } catch (e) {
      ErrorLogger.logError(
        e is Exception ? e : Exception(e.toString()),
        StackTrace.current,
        context: 'DEEP_LINK_HANDLE_ERROR',
        severity: ErrorSeverity.error,
        additionalData: {'uri': uri.toString()},
      );
    }
  }

  /// Handle password reset deep link specifically
  void _handlePasswordResetLink(Uri uri) {
    try {
      // Extract tokens from the URI fragment or query parameters
      final fragment = uri.fragment;
      final queryParams = uri.queryParameters;
      
      debugPrint('Password reset link received');
      debugPrint('Fragment: $fragment');
      debugPrint('Query params: $queryParams');

      // The actual navigation will be handled in main.dart
      // This just logs the event for debugging
      ErrorLogger.logInfo(
        'Password reset deep link processed',
        context: 'PASSWORD_RESET_DEEP_LINK',
        additionalData: {
          'has_fragment': fragment.isNotEmpty,
          'has_query_params': queryParams.isNotEmpty,
        },
      );

    } catch (e) {
      ErrorLogger.logError(
        e is Exception ? e : Exception(e.toString()),
        StackTrace.current,
        context: 'PASSWORD_RESET_LINK_ERROR',
        severity: ErrorSeverity.error,
      );
    }
  }

  /// Get the initial URI that launched the app (if any)
  Uri? get initialUri => _initialUri;

  /// Check if the initial URI is a password reset link
  bool get isInitialPasswordResetLink {
    return _initialUri?.scheme == 'io.supabase.goalkeeper' &&
           _initialUri?.host == 'reset-password';
  }

  /// Set a callback for handling deep links
  void setDeepLinkCallback(Function(Uri) callback) {
    onDeepLinkReceived = callback;
  }

  /// Clear the initial URI after handling
  void clearInitialUri() {
    _initialUri = null;
  }

  /// Dispose of the service
  void dispose() {
    _linkSubscription?.cancel();
    _linkSubscription = null;
    onDeepLinkReceived = null;
    _isInitialized = false;
  }
}

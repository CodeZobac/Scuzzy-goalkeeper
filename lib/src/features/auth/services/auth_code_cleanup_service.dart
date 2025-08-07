import 'dart:async';
import 'auth_code_validation_service.dart';
import '../../../core/services/email_logger.dart';

/// Scheduled cleanup service for expired authentication codes
/// 
/// This service provides automatic cleanup of expired authentication codes
/// to maintain database performance and security.
class AuthCodeCleanupService {
  final AuthCodeValidationService _validationService;
  Timer? _cleanupTimer;
  bool _isRunning = false;

  AuthCodeCleanupService({
    AuthCodeValidationService? validationService,
  }) : _validationService = validationService ?? AuthCodeValidationService();

  /// Starts automatic cleanup with the specified interval
  /// 
  /// [interval] How often to run cleanup (default: 1 hour)
  /// [runImmediately] Whether to run cleanup immediately on start (default: false)
  void startAutomaticCleanup({
    Duration interval = const Duration(hours: 1),
    bool runImmediately = false,
  }) {
    if (_isRunning) {
      EmailLogger.warning('Cleanup service is already running');
      return;
    }

    _isRunning = true;
    
    EmailLogger.info(
      'Starting automatic authentication code cleanup',
      context: {
        'interval': '${interval.inMinutes} minutes',
        'runImmediately': runImmediately,
      },
    );

    // Run immediately if requested
    if (runImmediately) {
      _performCleanup();
    }

    // Schedule periodic cleanup
    _cleanupTimer = Timer.periodic(interval, (_) => _performCleanup());
  }

  /// Stops automatic cleanup
  void stopAutomaticCleanup() {
    if (!_isRunning) {
      return;
    }

    _cleanupTimer?.cancel();
    _cleanupTimer = null;
    _isRunning = false;
    
    EmailLogger.info('Stopped automatic authentication code cleanup');
  }

  /// Performs a single cleanup operation
  /// 
  /// Returns [AuthCodeCleanupResult] with cleanup statistics
  Future<AuthCodeCleanupResult> performManualCleanup() async {
    EmailLogger.info('Performing manual authentication code cleanup');
    return await _performCleanup();
  }

  /// Internal method to perform cleanup
  Future<AuthCodeCleanupResult> _performCleanup() async {
    try {
      EmailLogger.debug('Starting authentication code cleanup');
      
      final result = await _validationService.cleanupExpiredCodes();
      
      if (result.isSuccess) {
        EmailLogger.info(
          'Authentication code cleanup completed successfully',
          context: {
            'cleanedCount': result.cleanedCount,
            'duration': '${result.duration?.inMilliseconds}ms',
          },
        );
      } else {
        EmailLogger.error(
          'Authentication code cleanup failed',
          context: {
            'errorMessage': result.errorMessage,
          },
        );
      }
      
      return result;
    } catch (e) {
      EmailLogger.error(
        'Unexpected error during authentication code cleanup',
        error: e,
      );
      
      return AuthCodeCleanupResult.error(
        'Erro inesperado durante limpeza',
        e,
      );
    }
  }

  /// Checks if automatic cleanup is currently running
  bool get isRunning => _isRunning;

  /// Gets the current cleanup interval (if running)
  Duration? get cleanupInterval {
    return _cleanupTimer?.isActive == true 
        ? const Duration(hours: 1) // Default interval
        : null;
  }

  /// Disposes of the cleanup service
  void dispose() {
    stopAutomaticCleanup();
    EmailLogger.info('Authentication code cleanup service disposed');
  }
}

/// Configuration for authentication code cleanup
class AuthCodeCleanupConfig {
  /// How often to run automatic cleanup
  final Duration cleanupInterval;
  
  /// Whether to run cleanup immediately when service starts
  final bool runImmediatelyOnStart;
  
  /// Whether to enable automatic cleanup
  final bool enableAutomaticCleanup;
  
  /// Maximum age of codes to keep (codes older than this will be cleaned up)
  final Duration maxCodeAge;

  const AuthCodeCleanupConfig({
    this.cleanupInterval = const Duration(hours: 1),
    this.runImmediatelyOnStart = false,
    this.enableAutomaticCleanup = true,
    this.maxCodeAge = const Duration(hours: 24),
  });

  /// Creates a configuration for development/testing
  factory AuthCodeCleanupConfig.development() {
    return const AuthCodeCleanupConfig(
      cleanupInterval: Duration(minutes: 5),
      runImmediatelyOnStart: true,
      enableAutomaticCleanup: true,
      maxCodeAge: Duration(hours: 1),
    );
  }

  /// Creates a configuration for production
  factory AuthCodeCleanupConfig.production() {
    return const AuthCodeCleanupConfig(
      cleanupInterval: Duration(hours: 6),
      runImmediatelyOnStart: false,
      enableAutomaticCleanup: true,
      maxCodeAge: Duration(hours: 24),
    );
  }

  /// Creates a configuration with cleanup disabled
  factory AuthCodeCleanupConfig.disabled() {
    return const AuthCodeCleanupConfig(
      enableAutomaticCleanup: false,
    );
  }
}
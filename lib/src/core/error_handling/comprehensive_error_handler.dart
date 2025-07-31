import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'error_boundary.dart';
import 'error_monitoring_service.dart';
import 'network_error_handler.dart';
import '../logging/error_logger.dart';
import '../../shared/widgets/error_recovery_widget.dart';

/// Comprehensive error handler that provides unified error management
/// across the entire application
class ComprehensiveErrorHandler {
  static final ComprehensiveErrorHandler _instance = ComprehensiveErrorHandler._internal();
  factory ComprehensiveErrorHandler() => _instance;
  ComprehensiveErrorHandler._internal();

  static ComprehensiveErrorHandler get instance => _instance;

  /// Handle any error and provide appropriate user feedback
  static Future<void> handleError(
    Object error,
    StackTrace stackTrace, {
    BuildContext? context,
    String? errorContext,
    bool showUserFeedback = true,
    VoidCallback? onRetry,
  }) async {
    // Log the error
    ErrorLogger.logError(
      error,
      stackTrace,
      context: errorContext ?? 'COMPREHENSIVE_ERROR_HANDLER',
      severity: _getErrorSeverity(error),
    );

    // Report to monitoring service
    ErrorMonitoringService.instance.reportError(
      _getErrorType(error),
      context: errorContext,
      metadata: {
        'error_class': error.runtimeType.toString(),
        'has_context': context != null,
        'show_user_feedback': showUserFeedback,
      },
      severity: _getErrorSeverity(error),
    );

    // Show user feedback if context is available and requested
    if (context != null && showUserFeedback) {
      await _showUserErrorFeedback(
        context,
        error,
        errorContext: errorContext,
        onRetry: onRetry,
      );
    }
  }

  /// Handle authentication-specific errors
  static Future<void> handleAuthError(
    Object error,
    StackTrace stackTrace, {
    required BuildContext context,
    VoidCallback? onRetry,
    VoidCallback? onGoToSignUp,
  }) async {
    final errorType = _getAuthErrorType(error);
    
    await handleError(
      error,
      stackTrace,
      context: context,
      errorContext: 'AUTH_ERROR',
      showUserFeedback: false, // We'll show custom auth feedback
    );

    // Show specialized auth error recovery
    if (context.mounted) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => AuthErrorRecoveryWidget(
            errorType: errorType,
            onRetry: onRetry,
            onGoToSignUp: onGoToSignUp,
          ),
        ),
      );
    }
  }

  /// Handle network-specific errors
  static Future<void> handleNetworkError(
    Object error,
    StackTrace stackTrace, {
    required BuildContext context,
    VoidCallback? onRetry,
    String? customMessage,
  }) async {
    await handleError(
      error,
      stackTrace,
      context: context,
      errorContext: 'NETWORK_ERROR',
      showUserFeedback: false, // We'll show custom network feedback
    );

    // Show specialized network error recovery
    if (context.mounted) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => NetworkErrorRecoveryWidget(
            onRetry: onRetry,
            customMessage: customMessage,
          ),
        ),
      );
    }
  }

  /// Handle SVG loading errors
  static void handleSvgError(
    Object error,
    StackTrace stackTrace, {
    String? assetPath,
    VoidCallback? onError,
  }) {
    ErrorLogger.logError(
      error,
      stackTrace,
      context: 'SVG_ERROR',
      additionalData: {
        'asset_path': assetPath,
      },
    );

    ErrorMonitoringService.instance.reportError(
      'svg_loading_failure',
      context: 'SVG_ERROR',
      metadata: {
        'asset_path': assetPath,
      },
    );

    onError?.call();
  }

  /// Show appropriate user error feedback based on error type
  static Future<void> _showUserErrorFeedback(
    BuildContext context,
    Object error, {
    String? errorContext,
    VoidCallback? onRetry,
  }) async {
    if (!context.mounted) return;

    final errorType = _getErrorType(error);
    final userMessage = _getUserFriendlyMessage(error);

    // For critical errors, show full-screen recovery
    if (_isCriticalError(error)) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ErrorRecoveryWidget(
            title: 'Erro Crítico',
            message: userMessage,
            icon: Icons.warning_outlined,
            primaryColor: Colors.red.shade600,
            onRetry: onRetry,
            troubleshootingSteps: _getTroubleshootingSteps(errorType),
            showSupportButton: true,
            onContactSupport: () => _contactSupport(context),
          ),
        ),
      );
    } else {
      // For non-critical errors, show snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                _getErrorIcon(error),
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(userMessage),
              ),
            ],
          ),
          backgroundColor: _getErrorColor(error),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 4),
          action: onRetry != null ? SnackBarAction(
            label: 'Tentar novamente',
            textColor: Colors.white,
            onPressed: onRetry,
          ) : null,
        ),
      );
    }
  }

  static ErrorSeverity _getErrorSeverity(Object error) {
    if (error is AuthException) {
      return ErrorSeverity.warning;
    } else if (error is PostgrestException) {
      return error.code?.startsWith('5') == true 
          ? ErrorSeverity.error 
          : ErrorSeverity.warning;
    } else if (_isNetworkError(error)) {
      return ErrorSeverity.warning;
    } else {
      return ErrorSeverity.error;
    }
  }

  static String _getErrorType(Object error) {
    if (error is AuthException) {
      return 'auth_exception';
    } else if (error is PostgrestException) {
      return 'database_exception';
    } else if (_isNetworkError(error)) {
      return 'network_exception';
    } else if (error.toString().contains('svg') || error.toString().contains('asset')) {
      return 'asset_exception';
    } else {
      return 'unknown_exception';
    }
  }

  static String _getAuthErrorType(Object error) {
    if (error is AuthException) {
      final message = error.message.toLowerCase();
      if (message.contains('invalid login credentials')) {
        return 'credentials';
      } else if (message.contains('email not confirmed')) {
        return 'email_not_confirmed';
      } else if (message.contains('network') || message.contains('connection')) {
        return 'network';
      } else {
        return 'server';
      }
    } else if (_isNetworkError(error)) {
      return 'network';
    } else {
      return 'server';
    }
  }

  static bool _isNetworkError(Object error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('network') ||
           errorString.contains('connection') ||
           errorString.contains('socket') ||
           errorString.contains('timeout');
  }

  static bool _isCriticalError(Object error) {
    // Define what constitutes a critical error
    return error.toString().contains('critical') ||
           error.toString().contains('fatal') ||
           (error is PostgrestException && error.code?.startsWith('5') == true);
  }

  static String _getUserFriendlyMessage(Object error) {
    if (error is AuthException) {
      return NetworkErrorHandler.handleAuthError(error);
    } else if (error is PostgrestException) {
      return 'Problema com o banco de dados. Tente novamente.';
    } else if (_isNetworkError(error)) {
      return 'Problema de conexão. Verifique a sua internet.';
    } else {
      return 'Ocorreu um erro inesperado. Tente novamente.';
    }
  }

  static IconData _getErrorIcon(Object error) {
    if (error is AuthException) {
      return Icons.security_outlined;
    } else if (_isNetworkError(error)) {
      return Icons.wifi_off_outlined;
    } else {
      return Icons.error_outline;
    }
  }

  static Color _getErrorColor(Object error) {
    if (error is AuthException) {
      return Colors.orange.shade600;
    } else if (_isNetworkError(error)) {
      return Colors.blue.shade600;
    } else {
      return Colors.red.shade600;
    }
  }

  static List<String> _getTroubleshootingSteps(String errorType) {
    switch (errorType) {
      case 'auth_exception':
        return [
          'Verifique as suas credenciais de início de sessão',
          'Confirme o seu email se necessário',
          'Tente redefinir a sua palavra-passe',
          'Verifique a sua conexão com a internet',
        ];
      case 'network_exception':
        return [
          'Verifique a sua conexão com a internet',
          'Tente alternar entre Wi-Fi e dados móveis',
          'Reinicie o seu roteador',
          'Aguarde alguns minutos e tente novamente',
        ];
      case 'database_exception':
        return [
          'Aguarde alguns minutos e tente novamente',
          'Verifique a sua conexão com a internet',
          'Reinicie o aplicativo',
          'Entre em contato com o suporte se persistir',
        ];
      default:
        return [
          'Reinicie o aplicativo',
          'Verifique a sua conexão com a internet',
          'Aguarde alguns minutos e tente novamente',
          'Entre em contato com o suporte se necessário',
        ];
    }
  }

  static void _contactSupport(BuildContext context) {
    // Implement support contact logic
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Contatar Suporte'),
        content: const Text(
          'A funcionalidade de suporte está em desenvolvimento. '
          'Por enquanto, tente reiniciar o aplicativo ou aguarde alguns minutos.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

/// Extension to add error handling to widgets
extension ErrorHandlingExtension on Widget {
  /// Wrap widget with comprehensive error handling
  Widget withErrorHandling({
    String? errorContext,
    VoidCallback? onError,
  }) {
    return Builder(
      builder: (context) {
        return ErrorBoundary(
          errorContext: errorContext,
          onError: onError,
          child: this,
        );
      },
    );
  }

  /// Wrap widget with auth-specific error handling
  Widget withAuthErrorHandling({
    VoidCallback? onAuthError,
  }) {
    return AuthErrorBoundary(
      onAuthError: onAuthError,
      child: this,
    );
  }
}

/// Mixin for widgets that need error handling capabilities
mixin ErrorHandlingMixin<T extends StatefulWidget> on State<T> {
  /// Handle error with comprehensive error handling
  Future<void> handleError(
    Object error,
    StackTrace stackTrace, {
    String? errorContext,
    bool showUserFeedback = true,
    VoidCallback? onRetry,
  }) async {
    await ComprehensiveErrorHandler.handleError(
      error,
      stackTrace,
      context: context,
      errorContext: errorContext,
      showUserFeedback: showUserFeedback,
      onRetry: onRetry,
    );
  }

  /// Handle authentication error
  Future<void> handleAuthError(
    Object error,
    StackTrace stackTrace, {
    VoidCallback? onRetry,
    VoidCallback? onGoToSignUp,
  }) async {
    await ComprehensiveErrorHandler.handleAuthError(
      error,
      stackTrace,
      context: context,
      onRetry: onRetry,
      onGoToSignUp: onGoToSignUp,
    );
  }

  /// Handle network error
  Future<void> handleNetworkError(
    Object error,
    StackTrace stackTrace, {
    VoidCallback? onRetry,
    String? customMessage,
  }) async {
    await ComprehensiveErrorHandler.handleNetworkError(
      error,
      stackTrace,
      context: context,
      onRetry: onRetry,
      customMessage: customMessage,
    );
  }
}
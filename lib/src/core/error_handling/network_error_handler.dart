import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../logging/error_logger.dart';

/// Network error handler for authentication flows and general network operations
class NetworkErrorHandler {
  static const int _maxRetries = 3;
  static const Duration _baseRetryDelay = Duration(seconds: 1);

  /// Handle authentication errors with user-friendly messages
  static String handleAuthError(Object error) {
    ErrorLogger.logError(
      error,
      StackTrace.current,
      context: 'AUTH_ERROR',
      additionalData: {'error_type': error.runtimeType.toString()},
    );

    if (error is AuthException) {
      return _getAuthErrorMessage(error);
    } else if (error is PostgrestException) {
      return _getPostgrestErrorMessage(error);
    } else if (_isNetworkError(error)) {
      return 'Problema de conexão. Verifique sua internet e tente novamente.';
    } else {
      return 'Ocorreu um erro inesperado. Tente novamente em alguns instantes.';
    }
  }

  /// Handle general network errors
  static String handleNetworkError(Object error, {String? context}) {
    ErrorLogger.logError(
      error,
      StackTrace.current,
      context: context ?? 'NETWORK_ERROR',
      additionalData: {'error_type': error.runtimeType.toString()},
    );

    if (_isTimeoutError(error)) {
      return 'A operação demorou muito para responder. Tente novamente.';
    } else if (_isConnectionError(error)) {
      return 'Problema de conexão. Verifique sua internet.';
    } else if (_isServerError(error)) {
      return 'Problema no servidor. Tente novamente em alguns instantes.';
    } else {
      return 'Erro de rede. Verifique sua conexão e tente novamente.';
    }
  }

  /// Retry mechanism for network operations
  static Future<T> retryOperation<T>(
    Future<T> Function() operation, {
    int maxRetries = _maxRetries,
    Duration baseDelay = _baseRetryDelay,
    bool Function(Object error)? shouldRetry,
    String? context,
  }) async {
    int attempts = 0;
    Object? lastError;

    while (attempts < maxRetries) {
      try {
        return await operation();
      } catch (error) {
        lastError = error;
        attempts++;

        ErrorLogger.logWarning(
          'Operation failed, attempt $attempts/$maxRetries',
          context: context ?? 'RETRY_OPERATION',
          additionalData: {
            'attempt': attempts,
            'max_retries': maxRetries,
            'error': error.toString(),
          },
        );

        // Check if we should retry this error
        if (shouldRetry != null && !shouldRetry(error)) {
          break;
        }

        // Don't retry on the last attempt
        if (attempts >= maxRetries) {
          break;
        }

        // Only retry on retryable errors
        if (!_isRetryableError(error)) {
          break;
        }

        // Exponential backoff with jitter
        final delay = Duration(
          milliseconds: (baseDelay.inMilliseconds * (1 << (attempts - 1))) +
              (DateTime.now().millisecondsSinceEpoch % 1000),
        );

        await Future.delayed(delay);
      }
    }

    // If we get here, all retries failed
    throw NetworkRetryException(
      'Operation failed after $attempts attempts',
      lastError: lastError,
      attempts: attempts,
    );
  }

  /// Check if error is retryable
  static bool _isRetryableError(Object error) {
    if (error is AuthException) {
      // Don't retry authentication errors that are user-related
      return !_isUserAuthError(error);
    }

    if (error is PostgrestException) {
      // Retry on server errors, not client errors
      return error.code != null && error.code!.startsWith('5');
    }

    // Retry network-related errors
    return _isNetworkError(error) || _isTimeoutError(error);
  }

  static bool _isUserAuthError(AuthException error) {
    const userErrors = [
      'Invalid login credentials',
      'Email not confirmed',
      'User not found',
      'Invalid email',
      'Password too short',
      'Email already registered',
    ];

    return userErrors.any((userError) => 
        error.message.toLowerCase().contains(userError.toLowerCase()));
  }

  static String _getAuthErrorMessage(AuthException error) {
    final message = error.message.toLowerCase();

    if (message.contains('invalid login credentials')) {
      return 'Email ou palavra-passe incorretos. Verifique os dados e tente novamente.';
    } else if (message.contains('email not confirmed')) {
      return 'Email não confirmado. Verifique sua caixa de entrada e confirme seu email.';
    } else if (message.contains('user not found')) {
      return 'Usuário não encontrado. Verifique o email ou crie uma nova conta.';
    } else if (message.contains('invalid email')) {
      return 'Formato de email inválido. Digite um email válido.';
    } else if (message.contains('password too short')) {
      return 'A palavra-passe deve ter pelo menos 6 caracteres.';
    } else if (message.contains('email already registered')) {
      return 'Este email já está registrado. Tente iniciar sessão ou use outro email.';
    } else if (message.contains('signup disabled')) {
      return 'Registro temporariamente desabilitado. Tente novamente mais tarde.';
    } else if (message.contains('too many requests')) {
      return 'Muitas tentativas. Aguarde alguns minutos antes de tentar novamente.';
    } else if (_isNetworkError(error)) {
      return 'Problema de conexão. Verifique sua internet e tente novamente.';
    } else {
      return 'Erro de autenticação. Tente novamente em alguns instantes.';
    }
  }

  static String _getPostgrestErrorMessage(PostgrestException error) {
    if (error.code?.startsWith('5') == true) {
      return 'Problema no servidor. Tente novamente em alguns instantes.';
    } else if (error.code?.startsWith('4') == true) {
      return 'Dados inválidos. Verifique as informações e tente novamente.';
    } else {
      return 'Erro no banco de dados. Tente novamente.';
    }
  }

  static bool _isNetworkError(Object error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('network') ||
           errorString.contains('connection') ||
           errorString.contains('socket') ||
           errorString.contains('host') ||
           errorString.contains('dns');
  }

  static bool _isTimeoutError(Object error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('timeout') ||
           errorString.contains('timed out');
  }

  static bool _isConnectionError(Object error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('connection refused') ||
           errorString.contains('connection failed') ||
           errorString.contains('no internet') ||
           errorString.contains('network unreachable');
  }

  static bool _isServerError(Object error) {
    if (error is PostgrestException) {
      return error.code?.startsWith('5') == true;
    }
    
    final errorString = error.toString().toLowerCase();
    return errorString.contains('server error') ||
           errorString.contains('internal server error') ||
           errorString.contains('service unavailable');
  }
}

/// Exception thrown when retry operations fail
class NetworkRetryException implements Exception {
  final String message;
  final Object? lastError;
  final int attempts;

  const NetworkRetryException(
    this.message, {
    this.lastError,
    required this.attempts,
  });

  @override
  String toString() {
    return 'NetworkRetryException: $message (after $attempts attempts)';
  }
}

/// Widget that provides network error recovery UI
class NetworkErrorRecovery extends StatefulWidget {
  final Widget child;
  final VoidCallback? onRetry;
  final String? errorMessage;
  final bool showRetryButton;

  const NetworkErrorRecovery({
    super.key,
    required this.child,
    this.onRetry,
    this.errorMessage,
    this.showRetryButton = true,
  });

  @override
  State<NetworkErrorRecovery> createState() => _NetworkErrorRecoveryState();
}

class _NetworkErrorRecoveryState extends State<NetworkErrorRecovery> {
  bool _hasNetworkError = false;
  String? _currentErrorMessage;

  @override
  Widget build(BuildContext context) {
    if (_hasNetworkError) {
      return _buildErrorRecoveryUI();
    }

    return widget.child;
  }

  Widget _buildErrorRecoveryUI() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.wifi_off_outlined,
            size: 64,
            color: Colors.orange.shade600,
          ),
          const SizedBox(height: 16),
          const Text(
            'Problema de Conexão',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _currentErrorMessage ?? 'Verifique sua conexão com a internet.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14),
          ),
          if (widget.showRetryButton) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _handleRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar Novamente'),
            ),
          ],
        ],
      ),
    );
  }

  void _handleRetry() {
    setState(() {
      _hasNetworkError = false;
      _currentErrorMessage = null;
    });
    
    widget.onRetry?.call();
  }

  void showNetworkError(String message) {
    if (mounted) {
      setState(() {
        _hasNetworkError = true;
        _currentErrorMessage = message;
      });
    }
  }

  void hideNetworkError() {
    if (mounted) {
      setState(() {
        _hasNetworkError = false;
        _currentErrorMessage = null;
      });
    }
  }
}
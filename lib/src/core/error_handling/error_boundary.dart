import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../logging/error_logger.dart';

/// Error boundary widget that catches and handles errors in its child tree
/// Provides graceful fallback UI when errors occur
class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final Widget? fallback;
  final String? errorContext;
  final bool showErrorDetails;
  final VoidCallback? onError;
  final bool enableRetry;

  const ErrorBoundary({
    super.key,
    required this.child,
    this.fallback,
    this.errorContext,
    this.showErrorDetails = false,
    this.onError,
    this.enableRetry = true,
  });

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  bool _hasError = false;
  Object? _error;
  StackTrace? _stackTrace;
  int _retryCount = 0;
  static const int _maxRetries = 3;

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return widget.fallback ?? _buildDefaultErrorUI(context);
    }

    return ErrorBoundaryWrapper(
      onError: _handleError,
      child: widget.child,
    );
  }

  void _handleError(Object error, StackTrace stackTrace) {
    setState(() {
      _hasError = true;
      _error = error;
      _stackTrace = stackTrace;
    });

    // Log error without sensitive information
    ErrorLogger.logError(
      error,
      stackTrace,
      context: widget.errorContext ?? 'ErrorBoundary',
      additionalData: {
        'retry_count': _retryCount,
        'widget_type': widget.child.runtimeType.toString(),
      },
    );

    widget.onError?.call();
  }

  Widget _buildDefaultErrorUI(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red.shade600,
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            'Algo deu errado',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.red.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ocorreu um erro inesperado. Por favor, tente novamente.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.red.shade700,
            ),
            textAlign: TextAlign.center,
          ),
          if (widget.enableRetry && _retryCount < _maxRetries) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _retry,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
              ),
            ),
          ],
          if (widget.showErrorDetails && _error != null) ...[
            const SizedBox(height: 12),
            ExpansionTile(
              title: const Text('Detalhes do erro'),
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    _error.toString(),
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _retry() {
    if (_retryCount < _maxRetries) {
      setState(() {
        _hasError = false;
        _error = null;
        _stackTrace = null;
        _retryCount++;
      });
    }
  }
}

/// Wrapper widget that catches errors in its child tree
class ErrorBoundaryWrapper extends StatefulWidget {
  final Widget child;
  final Function(Object error, StackTrace stackTrace) onError;

  const ErrorBoundaryWrapper({
    super.key,
    required this.child,
    required this.onError,
  });

  @override
  State<ErrorBoundaryWrapper> createState() => _ErrorBoundaryWrapperState();
}

class _ErrorBoundaryWrapperState extends State<ErrorBoundaryWrapper> {
  @override
  void initState() {
    super.initState();
    
    // Set up error handling for the current zone
    FlutterError.onError = (FlutterErrorDetails details) {
      widget.onError(details.exception, details.stack ?? StackTrace.current);
    };
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

/// Specialized error boundary for SVG rendering failures
class SvgErrorBoundary extends StatelessWidget {
  final Widget child;
  final String? assetPath;
  final Widget? fallback;

  const SvgErrorBoundary({
    super.key,
    required this.child,
    this.assetPath,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    return ErrorBoundary(
      errorContext: 'SVG_RENDERING${assetPath != null ? '_$assetPath' : ''}',
      fallback: fallback ?? _buildSvgFallback(),
      onError: () {
        debugPrint('SVG rendering error for asset: $assetPath');
      },
      child: child,
    );
  }

  Widget _buildSvgFallback() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Icon(
        Icons.broken_image_outlined,
        color: Colors.grey.shade400,
        size: 24,
      ),
    );
  }
}

/// Specialized error boundary for authentication flows
class AuthErrorBoundary extends StatelessWidget {
  final Widget child;
  final VoidCallback? onAuthError;

  const AuthErrorBoundary({
    super.key,
    required this.child,
    this.onAuthError,
  });

  @override
  Widget build(BuildContext context) {
    return ErrorBoundary(
      errorContext: 'AUTH_FLOW',
      fallback: _buildAuthFallback(context),
      onError: onAuthError,
      child: child,
    );
  }

  Widget _buildAuthFallback(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.security_outlined,
            size: 64,
            color: Colors.orange.shade600,
          ),
          const SizedBox(height: 16),
          const Text(
            'Erro de Autenticação',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Ocorreu um problema com a autenticação. Por favor, recarregue a página.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              // Restart the app or navigate to a safe state
              Navigator.of(context).pushNamedAndRemoveUntil(
                '/signin',
                (route) => false,
              );
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Recarregar'),
          ),
        ],
      ),
    );
  }
}
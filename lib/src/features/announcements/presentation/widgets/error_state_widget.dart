import 'package:flutter/material.dart';

class ErrorStateWidget extends StatelessWidget {
  final String? errorMessage;
  final VoidCallback? onRetry;
  final String? title;
  final IconData? icon;
  final bool isRetrying;
  final bool isCompact;
  final VoidCallback? onDismiss;

  const ErrorStateWidget({
    super.key,
    this.errorMessage,
    this.onRetry,
    this.title,
    this.icon,
    this.isRetrying = false,
    this.isCompact = false,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(isCompact ? 16.0 : 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: isCompact ? MainAxisSize.min : MainAxisSize.max,
          children: [
            Icon(
              icon ?? _getErrorIcon(),
              size: isCompact ? 48 : 80,
              color: _getErrorColor(),
            ),
            SizedBox(height: isCompact ? 12 : 16),
            Text(
              title ?? _getErrorTitle(),
              style: TextStyle(
                fontSize: isCompact ? 18 : 24,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF2C2C2C),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: isCompact ? 6 : 8),
            Text(
              errorMessage ?? 'An unexpected error occurred',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isCompact ? 12 : 14,
                color: const Color(0xFF757575),
                height: 1.4,
              ),
            ),
            if (onRetry != null) ...[
              SizedBox(height: isCompact ? 16 : 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: isRetrying ? null : onRetry,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: isCompact ? 24 : 32,
                        vertical: isCompact ? 10 : 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: isRetrying
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            'Try Again',
                            style: TextStyle(
                              fontSize: isCompact ? 14 : 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                  if (onDismiss != null) ...[
                    const SizedBox(width: 12),
                    TextButton(
                      onPressed: onDismiss,
                      child: Text(
                        'Dismiss',
                        style: TextStyle(
                          fontSize: isCompact ? 14 : 16,
                          color: const Color(0xFF757575),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getErrorIcon() {
    final message = errorMessage?.toLowerCase() ?? '';
    if (message.contains('network') || message.contains('connection')) {
      return Icons.wifi_off;
    } else if (message.contains('timeout')) {
      return Icons.access_time;
    } else if (message.contains('unauthorized') || message.contains('login')) {
      return Icons.lock_outline;
    } else if (message.contains('not found')) {
      return Icons.search_off;
    } else if (message.contains('full') || message.contains('capacity')) {
      return Icons.group_off;
    }
    return Icons.error_outline;
  }

  Color _getErrorColor() {
    final message = errorMessage?.toLowerCase() ?? '';
    if (message.contains('network') || message.contains('connection')) {
      return const Color(0xFF2196F3);
    } else if (message.contains('unauthorized') || message.contains('login')) {
      return const Color(0xFFFF9800);
    }
    return const Color(0xFFE57373);
  }

  String _getErrorTitle() {
    final message = errorMessage?.toLowerCase() ?? '';
    if (message.contains('network') || message.contains('connection')) {
      return 'Connection Problem';
    } else if (message.contains('timeout')) {
      return 'Request Timed Out';
    } else if (message.contains('unauthorized') || message.contains('login')) {
      return 'Authentication Required';
    } else if (message.contains('not found')) {
      return 'Not Found';
    } else if (message.contains('full') || message.contains('capacity')) {
      return 'Event Full';
    }
    return 'Something went wrong';
  }
}

/// Inline error widget for smaller spaces
class InlineErrorWidget extends StatelessWidget {
  final String? errorMessage;
  final VoidCallback? onRetry;
  final bool isRetrying;

  const InlineErrorWidget({
    super.key,
    this.errorMessage,
    this.onRetry,
    this.isRetrying = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE57373).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            size: 20,
            color: const Color(0xFFE57373),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              errorMessage ?? 'An error occurred',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFFD32F2F),
              ),
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(width: 8),
            TextButton(
              onPressed: isRetrying ? null : onRetry,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
              ),
              child: isRetrying
                  ? SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          const Color(0xFFD32F2F),
                        ),
                      ),
                    )
                  : Text(
                      'Retry',
                      style: TextStyle(
                        fontSize: 12,
                        color: const Color(0xFFD32F2F),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ],
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';

class AnnouncementErrorHandler {
  /// Convert exception to user-friendly error message
  static String getErrorMessage(dynamic error) {
    if (error is Exception) {
      final message = error.toString();
      if (message.contains('Exception: ')) {
        return message.replaceFirst('Exception: ', '');
      }
      return message;
    }
    
    // Handle common error types
    final errorString = error.toString().toLowerCase();
    if (errorString.contains('network') || errorString.contains('connection')) {
      return 'Network connection error. Please check your internet connection.';
    } else if (errorString.contains('timeout')) {
      return 'Request timed out. Please try again.';
    } else if (errorString.contains('unauthorized') || errorString.contains('401')) {
      return 'Authentication required. Please log in again.';
    } else if (errorString.contains('forbidden') || errorString.contains('403')) {
      return 'You don\'t have permission to perform this action.';
    } else if (errorString.contains('not found') || errorString.contains('404')) {
      return 'The requested resource was not found.';
    } else if (errorString.contains('server') || errorString.contains('500')) {
      return 'Server error. Please try again later.';
    } else if (errorString.contains('full') || errorString.contains('capacity')) {
      return 'This event is at full capacity.';
    } else if (errorString.contains('already joined') || errorString.contains('participant')) {
      return 'You are already participating in this event.';
    }
    
    return 'An unexpected error occurred. Please try again.';
  }

  /// Show error snackbar with consistent styling
  static void showErrorSnackBar(BuildContext context, String message) {
    if (!context.mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  /// Show success snackbar with consistent styling
  static void showSuccessSnackBar(BuildContext context, String message) {
    if (!context.mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  /// Show info snackbar with consistent styling
  static void showInfoSnackBar(BuildContext context, String message) {
    if (!context.mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF2196F3),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  /// Handle async operations with loading states and error handling
  static Future<T?> handleAsyncOperation<T>(
    Future<T> Function() operation, {
    required VoidCallback onLoadingStart,
    required VoidCallback onLoadingEnd,
    BuildContext? context,
    String? successMessage,
    String? errorPrefix,
  }) async {
    onLoadingStart();
    
    try {
      final result = await operation();
      
      if (context != null && successMessage != null) {
        showSuccessSnackBar(context, successMessage);
      }
      
      return result;
    } catch (e) {
      if (context != null) {
        final errorMessage = errorPrefix != null 
            ? '$errorPrefix: ${getErrorMessage(e)}'
            : getErrorMessage(e);
        showErrorSnackBar(context, errorMessage);
      }
      return null;
    } finally {
      onLoadingEnd();
    }
  }

  /// Handle async operations with retry mechanism
  static Future<T?> handleAsyncOperationWithRetry<T>(
    Future<T> Function() operation, {
    required VoidCallback onLoadingStart,
    required VoidCallback onLoadingEnd,
    BuildContext? context,
    String? successMessage,
    String? errorPrefix,
    int maxRetries = 3,
    Duration initialDelay = const Duration(seconds: 1),
    Duration? timeout,
  }) async {
    onLoadingStart();
    
    for (int attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        final Future<T> operationFuture = operation();
        final result = timeout != null 
            ? await operationFuture.timeout(timeout)
            : await operationFuture;
        
        if (context != null && successMessage != null) {
          showSuccessSnackBar(context, successMessage);
        }
        
        return result;
      } catch (e) {
        if (attempt == maxRetries) {
          // Final attempt failed
          if (context != null) {
            final errorMessage = errorPrefix != null 
                ? '$errorPrefix: ${getErrorMessage(e)}'
                : getErrorMessage(e);
            showErrorSnackBar(context, errorMessage);
          }
          return null;
        } else {
          // Wait before retrying with exponential backoff
          final delay = Duration(
            milliseconds: (initialDelay.inMilliseconds * (attempt + 1)).toInt(),
          );
          await Future.delayed(delay);
        }
      }
    }
    
    onLoadingEnd();
    return null;
  }

  /// Handle network operations with automatic retry for network errors
  static Future<T?> handleNetworkOperation<T>(
    Future<T> Function() operation, {
    required VoidCallback onLoadingStart,
    required VoidCallback onLoadingEnd,
    BuildContext? context,
    String? successMessage,
    String? errorPrefix,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    return handleAsyncOperationWithRetry<T>(
      operation,
      onLoadingStart: onLoadingStart,
      onLoadingEnd: onLoadingEnd,
      context: context,
      successMessage: successMessage,
      errorPrefix: errorPrefix,
      maxRetries: 2,
      initialDelay: const Duration(milliseconds: 500),
      timeout: timeout,
    );
  }

  /// Show loading dialog with timeout
  static Future<T?> showLoadingDialog<T>(
    BuildContext context,
    Future<T> Function() operation, {
    String? loadingMessage,
    Duration? timeout,
  }) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
              ),
              const SizedBox(height: 16),
              Text(
                loadingMessage ?? 'Loading...',
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      final result = timeout != null 
          ? await operation().timeout(timeout)
          : await operation();
      
      if (context.mounted) {
        Navigator.of(context).pop();
      }
      return result;
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
        showErrorSnackBar(context, getErrorMessage(e));
      }
      return null;
    }
  }
}
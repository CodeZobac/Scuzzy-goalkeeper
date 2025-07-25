import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:goalkeeper/src/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:goalkeeper/src/features/auth/data/models/registration_prompt_config.dart';
import 'package:goalkeeper/src/shared/widgets/registration_prompt_dialog.dart';
import 'package:goalkeeper/src/core/logging/error_logger.dart';

/// Callback type for handling restricted actions
typedef RestrictedActionCallback = void Function();

/// Callback type for handling action interception
typedef ActionInterceptCallback = Future<bool> Function(String action);

/// A wrapper component that handles auth-required actions consistently
/// for both guest and authenticated users
class GuestModeWrapper extends StatefulWidget {
  /// The child widget to wrap
  final Widget child;
  
  /// Whether this wrapper should intercept restricted actions
  final bool interceptActions;
  
  /// List of actions that require authentication
  final Set<String> restrictedActions;
  
  /// Custom callback for handling restricted actions
  final RestrictedActionCallback? onRestrictedAction;
  
  /// Custom callback for intercepting actions before they execute
  final ActionInterceptCallback? onActionIntercept;
  
  /// Whether to show registration prompts automatically
  final bool showRegistrationPrompts;
  
  /// Custom registration prompt configuration
  final RegistrationPromptConfig? customPromptConfig;
  
  /// Fallback widget to show when action is restricted
  final Widget? fallbackWidget;
  
  /// Whether to track guest user engagement
  final bool trackEngagement;
  
  /// Context for analytics tracking
  final String? analyticsContext;

  const GuestModeWrapper({
    super.key,
    required this.child,
    this.interceptActions = true,
    this.restrictedActions = const {
      'join_match',
      'hire_goalkeeper',
      'create_announcement',
      'edit_profile',
      'manage_notifications',
      'create_booking',
      'rate_goalkeeper',
      'send_message',
    },
    this.onRestrictedAction,
    this.onActionIntercept,
    this.showRegistrationPrompts = true,
    this.customPromptConfig,
    this.fallbackWidget,
    this.trackEngagement = true,
    this.analyticsContext,
  });

  @override
  State<GuestModeWrapper> createState() => _GuestModeWrapperState();
}

class _GuestModeWrapperState extends State<GuestModeWrapper> {
  late AuthStateProvider _authProvider;
  bool _isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _initializeWrapper();
      _isInitialized = true;
    }
  }

  void _initializeWrapper() {
    try {
      _authProvider = context.read<AuthStateProvider>();
      
      // Initialize guest context if user is in guest mode
      if (_authProvider.isGuest && widget.trackEngagement) {
        _authProvider.initializeGuestContext();
        
        // Track wrapper initialization for analytics
        if (widget.analyticsContext != null) {
          _authProvider.trackGuestContentView('wrapper_${widget.analyticsContext}');
        }
      }
    } catch (error, stackTrace) {
      ErrorLogger.logError(
        error,
        stackTrace,
        context: 'GUEST_MODE_WRAPPER_INIT',
        severity: ErrorSeverity.warning,
        additionalData: {
          'analytics_context': widget.analyticsContext,
          'intercept_actions': widget.interceptActions,
        },
      );
    }
  }

  /// Handle restricted action attempts
  Future<bool> _handleRestrictedAction(String action) async {
    try {
      // If user is authenticated, allow the action
      if (_authProvider.isAuthenticated) {
        return true;
      }

      // Custom action intercept callback
      if (widget.onActionIntercept != null) {
        final shouldProceed = await widget.onActionIntercept!(action);
        if (shouldProceed) {
          return true;
        }
      }

      // Track the restricted action attempt
      if (widget.trackEngagement) {
        _authProvider.trackGuestContentView('restricted_action_$action');
      }

      // Handle restricted action
      if (widget.onRestrictedAction != null) {
        widget.onRestrictedAction!();
        return false;
      }

      // Show registration prompt if enabled
      if (widget.showRegistrationPrompts && mounted) {
        await _showRegistrationPrompt(action);
      }

      return false;
    } catch (error, stackTrace) {
      ErrorLogger.logError(
        error,
        stackTrace,
        context: 'GUEST_MODE_WRAPPER_ACTION',
        severity: ErrorSeverity.error,
        additionalData: {
          'action': action,
          'is_guest': _authProvider.isGuest,
        },
      );
      
      // On error, show fallback or default behavior
      if (widget.fallbackWidget != null && mounted) {
        _showFallbackDialog();
      }
      
      return false;
    }
  }

  /// Show registration prompt based on action context
  Future<void> _showRegistrationPrompt(String action) async {
    if (!mounted) return;

    try {
      // Use custom config if provided
      RegistrationPromptConfig config;
      if (widget.customPromptConfig != null) {
        config = widget.customPromptConfig!;
      } else {
        config = _getPromptConfigForAction(action);
      }

      // Track prompt shown
      await _authProvider.promptForRegistration(action);

      // Show the dialog
      final result = await showDialog<bool>(
        context: context,
        barrierDismissible: true,
        builder: (context) => RegistrationPromptDialog(
          config: config,
        ),
      );
      
      // Handle dialog result
      if (result == true && mounted) {
        Navigator.of(context).pushNamed('/signup');
      }
    } catch (error, stackTrace) {
      ErrorLogger.logError(
        error,
        stackTrace,
        context: 'GUEST_MODE_WRAPPER_PROMPT',
        severity: ErrorSeverity.warning,
        additionalData: {
          'action': action,
        },
      );
    }
  }

  /// Get appropriate prompt configuration for action
  RegistrationPromptConfig _getPromptConfigForAction(String action) {
    switch (action) {
      case 'join_match':
        return RegistrationPromptConfig.joinMatch;
      case 'hire_goalkeeper':
        return RegistrationPromptConfig.hireGoalkeeper;
      case 'create_announcement':
        return RegistrationPromptConfig.createAnnouncement;
      case 'edit_profile':
      case 'manage_notifications':
        return RegistrationPromptConfig.profileAccess;
      default:
        return RegistrationPromptConfig.forContext('default');
    }
  }

  /// Show fallback dialog when errors occur
  void _showFallbackDialog() {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ação Não Disponível'),
        content: widget.fallbackWidget ?? 
          const Text('Esta ação não está disponível no momento. Tente novamente mais tarde.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Check if an action is restricted for the current user
  bool _isActionRestricted(String action) {
    return _authProvider.isGuest && 
           widget.restrictedActions.contains(action) &&
           widget.interceptActions;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthStateProvider>(
      builder: (context, authProvider, child) {
        // Provide action handler to child widgets through InheritedWidget
        return _GuestModeActionProvider(
          onActionAttempt: _handleRestrictedAction,
          isActionRestricted: _isActionRestricted,
          isGuest: authProvider.isGuest,
          child: widget.child,
        );
      },
    );
  }
}

/// InheritedWidget that provides action handling to descendant widgets
class _GuestModeActionProvider extends InheritedWidget {
  final Future<bool> Function(String action) onActionAttempt;
  final bool Function(String action) isActionRestricted;
  final bool isGuest;

  const _GuestModeActionProvider({
    required this.onActionAttempt,
    required this.isActionRestricted,
    required this.isGuest,
    required super.child,
  });

  static _GuestModeActionProvider? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_GuestModeActionProvider>();
  }

  @override
  bool updateShouldNotify(_GuestModeActionProvider oldWidget) {
    return isGuest != oldWidget.isGuest;
  }
}

/// Extension to easily access guest mode functionality from any widget
extension GuestModeContext on BuildContext {
  /// Check if user is in guest mode
  bool get isGuest {
    final provider = _GuestModeActionProvider.of(this);
    return provider?.isGuest ?? false;
  }

  /// Check if an action is restricted
  bool isActionRestricted(String action) {
    final provider = _GuestModeActionProvider.of(this);
    return provider?.isActionRestricted(action) ?? false;
  }

  /// Attempt to perform an action (will show prompt if restricted)
  Future<bool> attemptAction(String action) async {
    final provider = _GuestModeActionProvider.of(this);
    if (provider == null) {
      return true; // Allow action if no provider (not wrapped)
    }
    return await provider.onActionAttempt(action);
  }
}

/// Mixin for widgets that need to handle guest mode actions
mixin GuestModeActionMixin<T extends StatefulWidget> on State<T> {
  /// Safely attempt an action, handling guest mode restrictions
  Future<bool> safelyAttemptAction(String action, VoidCallback onSuccess) async {
    try {
      final canProceed = await context.attemptAction(action);
      if (canProceed && mounted) {
        onSuccess();
        return true;
      }
      return false;
    } catch (error, stackTrace) {
      ErrorLogger.logError(
        error,
        stackTrace,
        context: 'GUEST_MODE_ACTION_MIXIN',
        severity: ErrorSeverity.warning,
        additionalData: {
          'action': action,
          'widget': T.toString(),
        },
      );
      return false;
    }
  }

  /// Check if current user can perform action without prompts
  bool canPerformAction(String action) {
    return !context.isActionRestricted(action);
  }
}
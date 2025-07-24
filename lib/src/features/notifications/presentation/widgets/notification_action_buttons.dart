import 'package:flutter/material.dart';

/// Represents an action that can be performed on a notification
class NotificationAction {
  final String text;
  final VoidCallback onPressed;
  final NotificationActionType type;
  final bool isEnabled;

  const NotificationAction({
    required this.text,
    required this.onPressed,
    required this.type,
    this.isEnabled = true,
  });
}

/// Types of notification actions with predefined styling
enum NotificationActionType {
  accept,
  decline,
  viewDetails,
  custom,
}

/// Reusable action button component for notifications with consistent styling
class NotificationActionButtons extends StatelessWidget {
  final List<NotificationAction> actions;
  final bool isLoading;
  final String? loadingText;

  const NotificationActionButtons({
    super.key,
    required this.actions,
    this.isLoading = false,
    this.loadingText,
  });

  @override
  Widget build(BuildContext context) {
    if (actions.isEmpty) {
      return const SizedBox.shrink();
    }

    if (actions.length == 1) {
      return _buildSingleButton(actions.first);
    }

    return Row(
      children: actions.asMap().entries.map((entry) {
        final index = entry.key;
        final action = entry.value;
        
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: index < actions.length - 1 ? 12 : 0,
            ),
            child: _buildActionButton(action),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSingleButton(NotificationAction action) {
    return _buildActionButton(action);
  }

  Widget _buildActionButton(NotificationAction action) {
    final buttonStyle = _getButtonStyle(action.type);
    final isButtonEnabled = action.isEnabled && !isLoading;

    return Container(
      height: 44, // Minimum touch target size for accessibility
      decoration: BoxDecoration(
        gradient: isButtonEnabled ? buttonStyle.gradient : null,
        color: !isButtonEnabled ? Colors.grey.shade300 : null,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isButtonEnabled ? action.onPressed : null,
          borderRadius: BorderRadius.circular(12),
          child: Center(
            child: _buildButtonContent(action, buttonStyle),
          ),
        ),
      ),
    );
  }

  Widget _buildButtonContent(NotificationAction action, _ButtonStyle buttonStyle) {
    if (isLoading) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(buttonStyle.textColor),
            ),
          ),
          if (loadingText != null) ...[
            const SizedBox(width: 8),
            Text(
              loadingText!,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: buttonStyle.textColor,
              ),
            ),
          ],
        ],
      );
    }

    return Text(
      action.text,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: action.isEnabled ? buttonStyle.textColor : Colors.grey.shade600,
      ),
      semanticsLabel: _getSemanticLabel(action),
    );
  }

  _ButtonStyle _getButtonStyle(NotificationActionType type) {
    switch (type) {
      case NotificationActionType.accept:
        return _ButtonStyle(
          gradient: const LinearGradient(
            colors: [Color(0xFF4CAF50), Color(0xFF45A049)],
          ),
          textColor: Colors.white,
        );
      case NotificationActionType.decline:
        return _ButtonStyle(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF6B6B), Color(0xFFE94560)],
          ),
          textColor: Colors.white,
        );
      case NotificationActionType.viewDetails:
        return _ButtonStyle(
          gradient: const LinearGradient(
            colors: [Color(0xFF00A85A), Color(0xFF008A4A)],
          ),
          textColor: Colors.white,
        );
      case NotificationActionType.custom:
        return _ButtonStyle(
          gradient: const LinearGradient(
            colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
          ),
          textColor: Colors.white,
        );
    }
  }

  String _getSemanticLabel(NotificationAction action) {
    switch (action.type) {
      case NotificationActionType.accept:
        return 'Aceitar proposta de contrato';
      case NotificationActionType.decline:
        return 'Recusar proposta de contrato';
      case NotificationActionType.viewDetails:
        return 'Ver detalhes da notificação';
      case NotificationActionType.custom:
        return action.text;
    }
  }
}

class _ButtonStyle {
  final LinearGradient gradient;
  final Color textColor;

  const _ButtonStyle({
    required this.gradient,
    required this.textColor,
  });
}
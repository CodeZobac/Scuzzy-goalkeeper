import 'package:flutter/material.dart';
import '../../../auth/presentation/theme/app_theme.dart';
import '../../data/models/notification.dart';
import '../../data/models/notification_category.dart';

class NotificationBulkActions extends StatelessWidget {
  final List<AppNotification> selectedNotifications;
  final VoidCallback onClearSelection;
  final VoidCallback onSelectAll;
  final VoidCallback onMarkAsRead;
  final VoidCallback onDelete;
  final VoidCallback onArchive;
  final bool isLoading;

  const NotificationBulkActions({
    super.key,
    required this.selectedNotifications,
    required this.onClearSelection,
    required this.onSelectAll,
    required this.onMarkAsRead,
    required this.onDelete,
    required this.onArchive,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (selectedNotifications.isEmpty) {
      return const SizedBox.shrink();
    }

    final unreadCount = selectedNotifications.where((n) => n.isUnread).length;
    final archivedCount = selectedNotifications.where((n) => n.isArchived).length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.accentColor.withOpacity(0.1),
        border: Border(
          top: BorderSide(
            color: AppTheme.accentColor.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Selection info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${selectedNotifications.length} selecionada${selectedNotifications.length != 1 ? 's' : ''}',
                    style: AppTheme.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.accentColor,
                    ),
                  ),
                  if (unreadCount > 0)
                    Text(
                      '$unreadCount não lida${unreadCount != 1 ? 's' : ''}',
                      style: AppTheme.bodyMedium.copyWith(
                        fontSize: 12,
                        color: AppTheme.secondaryText,
                      ),
                    ),
                ],
              ),
            ),
            
            // Action buttons
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (unreadCount > 0)
                  _buildActionButton(
                    icon: Icons.mark_email_read,
                    tooltip: 'Marcar como lidas',
                    onPressed: isLoading ? null : onMarkAsRead,
                  ),
                
                if (archivedCount == 0)
                  _buildActionButton(
                    icon: Icons.archive,
                    tooltip: 'Arquivar',
                    onPressed: isLoading ? null : onArchive,
                  ),
                
                _buildActionButton(
                  icon: Icons.delete,
                  tooltip: 'Eliminar',
                  onPressed: isLoading ? null : onDelete,
                  color: AppTheme.errorColor,
                ),
                
                const SizedBox(width: 8),
                
                _buildActionButton(
                  icon: Icons.close,
                  tooltip: 'Cancelar seleção',
                  onPressed: isLoading ? null : onClearSelection,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback? onPressed,
    Color? color,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onPressed,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: (color ?? AppTheme.accentColor).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              icon,
              size: 20,
              color: color ?? AppTheme.accentColor,
            ),
          ),
        ),
      ),
    );
  }
}

class NotificationSelectionWrapper extends StatefulWidget {
  final AppNotification notification;
  final Widget child;
  final bool isSelected;
  final ValueChanged<bool> onSelectionChanged;
  final bool selectionMode;

  const NotificationSelectionWrapper({
    super.key,
    required this.notification,
    required this.child,
    required this.isSelected,
    required this.onSelectionChanged,
    required this.selectionMode,
  });

  @override
  State<NotificationSelectionWrapper> createState() => _NotificationSelectionWrapperState();
}

class _NotificationSelectionWrapperState extends State<NotificationSelectionWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _opacityAnimation = Tween<double>(
      begin: 1.0,
      end: 0.7,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    if (widget.isSelected) {
      _animationController.forward();
    }
  }

  @override
  void didUpdateWidget(NotificationSelectionWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected != oldWidget.isSelected) {
      if (widget.isSelected) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: widget.selectionMode ? null : () {
        widget.onSelectionChanged(true);
      },
      onTap: widget.selectionMode ? () {
        widget.onSelectionChanged(!widget.isSelected);
      } : null,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Opacity(
              opacity: _opacityAnimation.value,
              child: Stack(
                children: [
                  widget.child,
                  if (widget.selectionMode)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: widget.isSelected 
                              ? AppTheme.accentColor 
                              : Colors.white,
                          border: Border.all(
                            color: widget.isSelected 
                                ? AppTheme.accentColor 
                                : AppTheme.secondaryText.withOpacity(0.5),
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: widget.isSelected
                            ? const Icon(
                                Icons.check,
                                size: 16,
                                color: Colors.white,
                              )
                            : null,
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
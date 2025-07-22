import 'package:flutter/material.dart';
import '../../../auth/presentation/theme/app_theme.dart';

/// Widget for displaying a notification preference toggle
class NotificationPreferenceTile extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool isEnabled;
  final Color accentColor;

  const NotificationPreferenceTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.onChanged,
    this.isEnabled = true,
    this.accentColor = AppTheme.accentColor,
  });

  @override
  State<NotificationPreferenceTile> createState() => _NotificationPreferenceTileState();
}

class _NotificationPreferenceTileState extends State<NotificationPreferenceTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            decoration: BoxDecoration(
              color: widget.isEnabled 
                  ? Colors.transparent 
                  : AppTheme.secondaryText.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: widget.isEnabled 
                    ? Colors.transparent 
                    : AppTheme.secondaryText.withOpacity(0.1),
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: widget.isEnabled ? () => widget.onChanged(!widget.value) : null,
                onTapDown: widget.isEnabled ? (_) {
                  setState(() => _isPressed = true);
                  _animationController.forward();
                } : null,
                onTapUp: widget.isEnabled ? (_) {
                  setState(() => _isPressed = false);
                  _animationController.reverse();
                } : null,
                onTapCancel: widget.isEnabled ? () {
                  setState(() => _isPressed = false);
                  _animationController.reverse();
                } : null,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Icon container
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: widget.isEnabled 
                              ? widget.accentColor.withOpacity(0.1)
                              : AppTheme.secondaryText.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          widget.icon,
                          color: widget.isEnabled 
                              ? widget.accentColor
                              : AppTheme.secondaryText.withOpacity(0.5),
                          size: 24,
                        ),
                      ),
                      
                      const SizedBox(width: 16),
                      
                      // Title and subtitle
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.title,
                              style: AppTheme.bodyLarge.copyWith(
                                fontWeight: FontWeight.w600,
                                color: widget.isEnabled 
                                    ? AppTheme.primaryText
                                    : AppTheme.secondaryText.withOpacity(0.5),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.subtitle,
                              style: AppTheme.bodyMedium.copyWith(
                                color: widget.isEnabled 
                                    ? AppTheme.secondaryText
                                    : AppTheme.secondaryText.withOpacity(0.5),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(width: 16),
                      
                      // Custom toggle switch
                      _buildCustomSwitch(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCustomSwitch() {
    return GestureDetector(
      onTap: widget.isEnabled ? () => widget.onChanged(!widget.value) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 52,
        height: 28,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: widget.isEnabled
              ? (widget.value ? widget.accentColor : AppTheme.secondaryText.withOpacity(0.3))
              : AppTheme.secondaryText.withOpacity(0.1),
          boxShadow: widget.isEnabled && widget.value
              ? [
                  BoxShadow(
                    color: widget.accentColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Stack(
          children: [
            AnimatedPositioned(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              left: widget.value ? 26 : 2,
              top: 2,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: widget.value
                    ? Icon(
                        Icons.check,
                        size: 16,
                        color: widget.accentColor,
                      )
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
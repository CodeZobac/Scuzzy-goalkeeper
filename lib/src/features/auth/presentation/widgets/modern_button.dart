import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ModernButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool outlined;
  final Color? backgroundColor;
  final Color? textColor;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const ModernButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.outlined = false,
    this.backgroundColor,
    this.textColor,
    this.width,
    this.height,
    this.borderRadius,
  });

  @override
  State<ModernButton> createState() => _ModernButtonState();
}

class _ModernButtonState extends State<ModernButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _elevationAnimation = Tween<double>(
      begin: 6.0,
      end: 12.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    setState(() {
      _isPressed = true;
    });
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    setState(() {
      _isPressed = false;
    });
    _controller.reverse();
  }

  void _onTapCancel() {
    setState(() {
      _isPressed = false;
    });
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = widget.backgroundColor ?? AppTheme.authPrimaryGreen;
    final textColor = widget.textColor ?? Colors.white;
    final isEnabled = widget.onPressed != null && !widget.isLoading;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTapDown: isEnabled ? _onTapDown : null,
            onTapUp: isEnabled ? _onTapUp : null,
            onTapCancel: isEnabled ? _onTapCancel : null,
            onTap: widget.onPressed,
            child: Container(
              width: widget.width ?? double.infinity,
              height: widget.height ?? 56,
              decoration: BoxDecoration(
                gradient: !widget.outlined && isEnabled
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          backgroundColor,
                          backgroundColor.withOpacity(0.8),
                        ],
                      )
                    : null,
                color: widget.outlined 
                    ? Colors.transparent
                    : isEnabled 
                        ? null 
                        : const Color(0xFFE5E7EB),
                borderRadius: widget.borderRadius ?? BorderRadius.circular(16),
                border: widget.outlined
                    ? Border.all(
                        color: isEnabled 
                            ? backgroundColor 
                            : const Color(0xFFE5E7EB),
                        width: 2,
                      )
                    : null,
                boxShadow: !widget.outlined && isEnabled
                    ? [
                        BoxShadow(
                          color: backgroundColor.withOpacity(0.3),
                          blurRadius: _elevationAnimation.value,
                          offset: const Offset(0, 4),
                        ),
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Ripple effect overlay
                  if (_isPressed)
                    Container(
                      decoration: BoxDecoration(
                        color: widget.outlined
                            ? backgroundColor.withOpacity(0.1)
                            : Colors.white.withOpacity(0.1),
                        borderRadius: widget.borderRadius ?? BorderRadius.circular(16),
                      ),
                    ),
                  
                  // Content
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (widget.isLoading) ...[
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              widget.outlined ? backgroundColor : textColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ] else if (widget.icon != null) ...[
                        Icon(
                          widget.icon,
                          color: widget.outlined
                              ? (isEnabled ? backgroundColor : const Color(0xFF9CA3AF))
                              : (isEnabled ? textColor : const Color(0xFF9CA3AF)),
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                      ],
                      Text(
                        widget.text,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: widget.outlined
                              ? (isEnabled ? backgroundColor : const Color(0xFF9CA3AF))
                              : (isEnabled ? textColor : const Color(0xFF9CA3AF)),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class ModernLinkButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color? color;
  final TextStyle? style;

  const ModernLinkButton({
    super.key,
    required this.text,
    this.onPressed,
    this.color,
    this.style,
  });

  @override
  State<ModernLinkButton> createState() => _ModernLinkButtonState();
}

class _ModernLinkButtonState extends State<ModernLinkButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTapDown: widget.onPressed != null ? _onTapDown : null,
            onTapUp: widget.onPressed != null ? _onTapUp : null,
            onTapCancel: widget.onPressed != null ? _onTapCancel : null,
            onTap: widget.onPressed,
            child: Text(
              widget.text,
              style: widget.style ??
                  TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: widget.color ?? AppTheme.authPrimaryGreen,
                    decoration: TextDecoration.underline,
                    decorationColor: widget.color ?? AppTheme.authPrimaryGreen,
                  ),
            ),
          ),
        );
      },
    );
  }
}

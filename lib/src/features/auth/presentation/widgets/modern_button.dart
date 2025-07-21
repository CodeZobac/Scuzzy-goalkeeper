import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ModernButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final double? width;
  final double height;
  final Color? backgroundColor;
  final Color? textColor;
  final BorderRadius? borderRadius;
  final EdgeInsets? padding;
  final bool outlined;

  const ModernButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.width,
    this.height = 56,
    this.backgroundColor,
    this.textColor,
    this.borderRadius,
    this.padding,
    this.outlined = false,
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
      begin: 8.0,
      end: 16.0,
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

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              gradient: widget.outlined 
                  ? null 
                  : LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        backgroundColor,
                        backgroundColor.withOpacity(0.8),
                      ],
                    ),
              color: widget.outlined ? Colors.transparent : null,
              borderRadius: widget.borderRadius ?? BorderRadius.circular(16),
              border: widget.outlined 
                  ? Border.all(
                      color: backgroundColor,
                      width: 2,
                    )
                  : null,
              boxShadow: widget.outlined 
                  ? null 
                  : [
                      BoxShadow(
                        color: backgroundColor.withOpacity(0.3),
                        blurRadius: _elevationAnimation.value,
                        offset: const Offset(0, 4),
                      ),
                      BoxShadow(
                        color: backgroundColor.withOpacity(0.1),
                        blurRadius: _elevationAnimation.value * 2,
                        offset: const Offset(0, 8),
                      ),
                    ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.isLoading ? null : widget.onPressed,
                onTapDown: widget.onPressed != null ? _onTapDown : null,
                onTapUp: widget.onPressed != null ? _onTapUp : null,
                onTapCancel: widget.onPressed != null ? _onTapCancel : null,
                borderRadius: widget.borderRadius ?? BorderRadius.circular(16),
                child: Container(
                  padding: widget.padding ?? 
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: widget.isLoading
                      ? Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                widget.outlined ? backgroundColor : textColor,
                              ),
                              strokeWidth: 2.5,
                            ),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (widget.icon != null) ...[
                              Icon(
                                widget.icon,
                                color: widget.outlined ? backgroundColor : textColor,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                            ],
                            Text(
                              widget.text,
                              style: AppTheme.authButtonText.copyWith(
                                color: widget.outlined ? backgroundColor : textColor,
                              ),
                            ),
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
  bool _isPressed = false;

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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() {
          _isPressed = true;
        });
        _controller.forward();
      },
      onTapUp: (_) {
        setState(() {
          _isPressed = false;
        });
        _controller.reverse();
        if (widget.onPressed != null) {
          widget.onPressed!();
        }
      },
      onTapCancel: () {
        setState(() {
          _isPressed = false;
        });
        _controller.reverse();
      },
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Text(
              widget.text,
              style: widget.style ?? 
                  AppTheme.authLinkText.copyWith(
                    color: widget.color ?? AppTheme.authPrimaryGreen,
                    decoration: _isPressed 
                        ? TextDecoration.underline 
                        : TextDecoration.none,
                  ),
            ),
          );
        },
      ),
    );
  }
}

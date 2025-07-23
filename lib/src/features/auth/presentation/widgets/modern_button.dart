import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final EdgeInsets? padding;
  final double? elevation;
  final String? loadingText;
  final bool showLoadingText;
  final Duration? animationDuration;

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
    this.padding,
    this.elevation,
    this.loadingText,
    this.showLoadingText = true,
    this.animationDuration,
  });

  @override
  State<ModernButton> createState() => _ModernButtonState();
}

class _ModernButtonState extends State<ModernButton>
    with TickerProviderStateMixin {
  late AnimationController _pressController;
  late AnimationController _hoverController;
  late AnimationController _loadingController;
  late AnimationController _rippleController;
  
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;
  late Animation<double> _hoverAnimation;
  late Animation<double> _loadingRotationAnimation;
  late Animation<double> _loadingFadeAnimation;
  late Animation<double> _rippleAnimation;
  late Animation<double> _rippleOpacityAnimation;
  
  bool _isPressed = false;
  bool _isHovered = false;
  Offset? _ripplePosition;

  @override
  void initState() {
    super.initState();
    
    final animationDuration = widget.animationDuration ?? const Duration(milliseconds: 200);
    
    // Press animation controller
    _pressController = AnimationController(
      duration: animationDuration,
      vsync: this,
    );
    
    // Hover animation controller
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    // Loading animation controller
    _loadingController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    // Ripple animation controller
    _rippleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    // Press animations
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.96,
    ).animate(CurvedAnimation(
      parent: _pressController,
      curve: Curves.easeOutCubic,
    ));

    _elevationAnimation = Tween<double>(
      begin: widget.elevation ?? 4.0,
      end: (widget.elevation ?? 4.0) * 2,
    ).animate(CurvedAnimation(
      parent: _pressController,
      curve: Curves.easeOut,
    ));

    // Hover animation
    _hoverAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _hoverController,
      curve: Curves.easeOutCubic,
    ));

    // Loading animations
    _loadingRotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _loadingController,
      curve: Curves.linear,
    ));

    _loadingFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _loadingController,
      curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
    ));

    // Ripple animations
    _rippleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _rippleController,
      curve: Curves.easeOut,
    ));

    _rippleOpacityAnimation = Tween<double>(
      begin: 0.3,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _rippleController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
    ));

    // Start loading animation if initially loading
    if (widget.isLoading) {
      _loadingController.repeat();
    }
  }

  @override
  void didUpdateWidget(ModernButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Handle loading state changes
    if (widget.isLoading != oldWidget.isLoading) {
      if (widget.isLoading) {
        _loadingController.repeat();
      } else {
        _loadingController.stop();
        _loadingController.reset();
      }
    }
  }

  @override
  void dispose() {
    _pressController.dispose();
    _hoverController.dispose();
    _loadingController.dispose();
    _rippleController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    setState(() {
      _isPressed = true;
      _ripplePosition = details.localPosition;
    });
    _pressController.forward();
    _rippleController.forward();
    HapticFeedback.selectionClick();
  }

  void _onTapUp(TapUpDetails details) {
    setState(() {
      _isPressed = false;
    });
    _pressController.reverse();
  }

  void _onTapCancel() {
    setState(() {
      _isPressed = false;
    });
    _pressController.reverse();
  }

  void _onHover(bool isHovered) {
    setState(() {
      _isHovered = isHovered;
    });
    
    if (isHovered) {
      _hoverController.forward();
    } else {
      _hoverController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = widget.backgroundColor ?? AppTheme.authPrimaryGreen;
    final textColor = widget.textColor ?? Colors.white;
    final isEnabled = widget.onPressed != null && !widget.isLoading;
    final borderRadius = widget.borderRadius ?? BorderRadius.circular(16);

    return AnimatedBuilder(
      animation: Listenable.merge([
        _pressController,
        _hoverController,
        _loadingController,
        _rippleController,
      ]),
      builder: (context, child) {
        return MouseRegion(
          onEnter: (_) => _onHover(true),
          onExit: (_) => _onHover(false),
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: GestureDetector(
              onTapDown: isEnabled ? _onTapDown : null,
              onTapUp: isEnabled ? _onTapUp : null,
              onTapCancel: isEnabled ? _onTapCancel : null,
              onTap: isEnabled ? () {
                widget.onPressed?.call();
                _rippleController.reset();
              } : null,
              child: Container(
                width: widget.width ?? double.infinity,
                height: widget.height ?? 56,
                padding: widget.padding,
                decoration: BoxDecoration(
                  gradient: !widget.outlined && isEnabled
                      ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color.lerp(backgroundColor, backgroundColor.withOpacity(0.9), _hoverAnimation.value)!,
                            Color.lerp(backgroundColor.withOpacity(0.8), backgroundColor.withOpacity(0.7), _hoverAnimation.value)!,
                          ],
                        )
                      : null,
                  color: widget.outlined 
                      ? Color.lerp(Colors.transparent, backgroundColor.withOpacity(0.05), _hoverAnimation.value)
                      : isEnabled 
                          ? null 
                          : const Color(0xFFE5E7EB),
                  borderRadius: borderRadius,
                  border: widget.outlined
                      ? Border.all(
                          color: isEnabled 
                              ? Color.lerp(backgroundColor, backgroundColor.withOpacity(0.8), _hoverAnimation.value)!
                              : const Color(0xFFE5E7EB),
                          width: 2 + (_hoverAnimation.value * 0.5),
                        )
                      : null,
                  boxShadow: !widget.outlined && isEnabled
                      ? [
                          BoxShadow(
                            color: backgroundColor.withOpacity(0.25 + (_hoverAnimation.value * 0.1)),
                            blurRadius: _elevationAnimation.value + (_hoverAnimation.value * 4),
                            offset: Offset(0, 4 + (_hoverAnimation.value * 2)),
                          ),
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08 + (_hoverAnimation.value * 0.02)),
                            blurRadius: 8 + (_hoverAnimation.value * 4),
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04 + (_hoverAnimation.value * 0.02)),
                            blurRadius: 6 + (_hoverAnimation.value * 2),
                            offset: const Offset(0, 2),
                          ),
                        ],
                ),
                child: ClipRRect(
                  borderRadius: borderRadius,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Ripple effect
                      if (_ripplePosition != null)
                        Positioned.fill(
                          child: CustomPaint(
                            painter: RipplePainter(
                              center: _ripplePosition!,
                              radius: _rippleAnimation.value * 200,
                              opacity: _rippleOpacityAnimation.value,
                              color: widget.outlined
                                  ? backgroundColor.withOpacity(0.2)
                                  : Colors.white.withOpacity(0.3),
                            ),
                          ),
                        ),
                      
                      // Hover overlay
                      if (_isHovered && isEnabled)
                        Container(
                          decoration: BoxDecoration(
                            color: widget.outlined
                                ? backgroundColor.withOpacity(0.05 * _hoverAnimation.value)
                                : Colors.white.withOpacity(0.1 * _hoverAnimation.value),
                            borderRadius: borderRadius,
                          ),
                        ),
                      
                      // Content
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: _buildButtonContent(backgroundColor, textColor, isEnabled),
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

  Widget _buildButtonContent(Color backgroundColor, Color textColor, bool isEnabled) {
    if (widget.isLoading) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          FadeTransition(
            opacity: _loadingFadeAnimation,
            child: RotationTransition(
              turns: _loadingRotationAnimation,
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    widget.outlined ? backgroundColor : textColor,
                  ),
                ),
              ),
            ),
          ),
          if (widget.showLoadingText) ...[
            const SizedBox(width: 12),
            FadeTransition(
              opacity: _loadingFadeAnimation,
              child: Text(
                widget.loadingText ?? 'Carregando...',
                style: AppTheme.authButtonText.copyWith(
                  color: widget.outlined
                      ? (isEnabled ? backgroundColor : const Color(0xFF9CA3AF))
                      : (isEnabled ? textColor : const Color(0xFF9CA3AF)),
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.icon != null) ...[
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
          style: AppTheme.authButtonText.copyWith(
            color: widget.outlined
                ? (isEnabled ? backgroundColor : const Color(0xFF9CA3AF))
                : (isEnabled ? textColor : const Color(0xFF9CA3AF)),
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

/// Custom painter for ripple effect
class RipplePainter extends CustomPainter {
  final Offset center;
  final double radius;
  final double opacity;
  final Color color;

  RipplePainter({
    required this.center,
    required this.radius,
    required this.opacity,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (opacity <= 0) return;

    final paint = Paint()
      ..color = color.withOpacity(opacity)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(RipplePainter oldDelegate) {
    return oldDelegate.center != center ||
        oldDelegate.radius != radius ||
        oldDelegate.opacity != opacity ||
        oldDelegate.color != color;
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
    with TickerProviderStateMixin {
  late AnimationController _pressController;
  late AnimationController _hoverController;
  
  late Animation<double> _scaleAnimation;
  late Animation<double> _hoverAnimation;
  late Animation<Color?> _colorAnimation;
  
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    
    _pressController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.96,
    ).animate(CurvedAnimation(
      parent: _pressController,
      curve: Curves.easeOutCubic,
    ));

    _hoverAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _hoverController,
      curve: Curves.easeOut,
    ));

    final baseColor = widget.color ?? AppTheme.authPrimaryGreen;
    _colorAnimation = ColorTween(
      begin: baseColor,
      end: baseColor.withOpacity(0.8),
    ).animate(CurvedAnimation(
      parent: _hoverController,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _pressController.dispose();
    _hoverController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _pressController.forward();
    HapticFeedback.selectionClick();
  }

  void _onTapUp(TapUpDetails details) {
    _pressController.reverse();
  }

  void _onTapCancel() {
    _pressController.reverse();
  }

  void _onHover(bool isHovered) {
    setState(() {
      _isHovered = isHovered;
    });
    
    if (isHovered) {
      _hoverController.forward();
    } else {
      _hoverController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_pressController, _hoverController]),
      builder: (context, child) {
        return MouseRegion(
          onEnter: (_) => _onHover(true),
          onExit: (_) => _onHover(false),
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: GestureDetector(
              onTapDown: widget.onPressed != null ? _onTapDown : null,
              onTapUp: widget.onPressed != null ? _onTapUp : null,
              onTapCancel: widget.onPressed != null ? _onTapCancel : null,
              onTap: widget.onPressed,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: _isHovered 
                      ? (widget.color ?? AppTheme.authPrimaryGreen).withOpacity(0.08 * _hoverAnimation.value)
                      : Colors.transparent,
                ),
                child: Text(
                  widget.text,
                  style: widget.style ??
                      TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _colorAnimation.value,
                        decoration: TextDecoration.underline,
                        decorationColor: _colorAnimation.value,
                        decorationThickness: _isHovered ? 2.0 : 1.5,
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

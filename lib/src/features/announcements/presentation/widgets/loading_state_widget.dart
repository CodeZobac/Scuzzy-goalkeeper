import 'package:flutter/material.dart';

class LoadingStateWidget extends StatelessWidget {
  final String? message;
  final Color? color;
  final bool isSmall;
  final bool showBackground;

  const LoadingStateWidget({
    super.key,
    this.message,
    this.color,
    this.isSmall = false,
    this.showBackground = false,
  });

  @override
  Widget build(BuildContext context) {
    final widget = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: isSmall ? 20 : 40,
          height: isSmall ? 20 : 40,
          child: CircularProgressIndicator(
            strokeWidth: isSmall ? 2 : 3,
            valueColor: AlwaysStoppedAnimation<Color>(
              color ?? const Color(0xFF4CAF50),
            ),
          ),
        ),
        if (message != null) ...[
          SizedBox(height: isSmall ? 8 : 16),
          Text(
            message!,
            style: TextStyle(
              fontSize: isSmall ? 14 : 16,
              color: const Color(0xFF757575),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );

    if (showBackground) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(25),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: widget,
      );
    }

    return Center(child: widget);
  }
}

/// Specialized loading widget for inline operations
class InlineLoadingWidget extends StatelessWidget {
  final String? message;
  final Color? color;

  const InlineLoadingWidget({
    super.key,
    this.message,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              color ?? const Color(0xFF4CAF50),
            ),
          ),
        ),
        if (message != null) ...[
          const SizedBox(width: 8),
          Text(
            message!,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF757575),
            ),
          ),
        ],
      ],
    );
  }
}

/// Shimmer loading effect for list items
class ShimmerLoadingWidget extends StatefulWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const ShimmerLoadingWidget({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
  });

  @override
  State<ShimmerLoadingWidget> createState() => _ShimmerLoadingWidgetState();
}

class _ShimmerLoadingWidgetState extends State<ShimmerLoadingWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height ?? 20,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius ?? BorderRadius.circular(4),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: const [
                Color(0xFFE0E0E0),
                Color(0xFFF5F5F5),
                Color(0xFFE0E0E0),
              ],
              stops: [
                (_animation.value - 1).clamp(0.0, 1.0),
                _animation.value.clamp(0.0, 1.0),
                (_animation.value + 1).clamp(0.0, 1.0),
              ],
            ),
          ),
        );
      },
    );
  }
}

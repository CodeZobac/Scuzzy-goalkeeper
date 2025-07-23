import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Collection of fallback UI components for when assets fail to load
class FallbackComponents {
  
  /// Creates a fallback for the auth header SVG
  static Widget authHeaderFallback({
    double? width,
    double? height,
    bool showMessage = false,
  }) {
    return Container(
      width: width,
      height: height ?? 240,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF4CAF50), // Primary green
            const Color(0xFF66BB6A), // Secondary green
          ],
        ),
      ),
      child: CustomPaint(
        painter: AuthHeaderFallbackPainter(),
        child: showMessage ? _buildFallbackMessage(
          'Imagem de cabeçalho indisponível',
          Icons.login,
        ) : null,
      ),
    );
  }

  /// Creates a fallback for football field markers
  static Widget footballFieldFallback({
    double size = 32,
    Color? color,
    bool showLabel = false,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: (color ?? Colors.green).withOpacity(0.1),
        borderRadius: BorderRadius.circular(size / 4),
        border: Border.all(
          color: color ?? Colors.green,
          width: 2,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.sports_soccer,
            size: size * 0.6,
            color: color ?? Colors.green,
          ),
          if (showLabel && size > 40) ...[
            const SizedBox(height: 2),
            Text(
              'Campo',
              style: TextStyle(
                fontSize: size * 0.15,
                color: color ?? Colors.green,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Creates a fallback for football player markers
  static Widget footballPlayerFallback({
    double size = 28,
    Color? color,
    bool showLabel = false,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: (color ?? Colors.orange).withOpacity(0.1),
        borderRadius: BorderRadius.circular(size / 2),
        border: Border.all(
          color: color ?? Colors.orange,
          width: 2,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person,
            size: size * 0.6,
            color: color ?? Colors.orange,
          ),
          if (showLabel && size > 40) ...[
            const SizedBox(height: 2),
            Text(
              'Jogador',
              style: TextStyle(
                fontSize: size * 0.15,
                color: color ?? Colors.orange,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Creates a fallback for goalkeeper markers
  static Widget goalkeeperFallback({
    double size = 32,
    Color? color,
    bool showLabel = false,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: (color ?? Colors.blue).withOpacity(0.1),
        borderRadius: BorderRadius.circular(size / 4),
        border: Border.all(
          color: color ?? Colors.blue,
          width: 2,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.sports,
            size: size * 0.6,
            color: color ?? Colors.blue,
          ),
          if (showLabel && size > 40) ...[
            const SizedBox(height: 2),
            Text(
              'GR',
              style: TextStyle(
                fontSize: size * 0.2,
                color: color ?? Colors.blue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Creates a generic SVG fallback with customizable appearance
  static Widget genericSvgFallback({
    double? width,
    double? height,
    Color? color,
    IconData? icon,
    String? label,
    bool showBorder = true,
  }) {
    final fallbackColor = color ?? Colors.grey.shade400;
    final size = math.min(width ?? 48, height ?? 48);

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: showBorder ? Border.all(
          color: Colors.grey.shade300,
          width: 1,
        ) : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon ?? Icons.broken_image_outlined,
            size: size * 0.5,
            color: fallbackColor,
          ),
          if (label != null && (height ?? 48) > 40) ...[
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: (size * 0.2).clamp(8.0, 12.0),
                color: fallbackColor,
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  /// Creates an animated loading fallback
  static Widget loadingFallback({
    double? width,
    double? height,
    Color? color,
    String? message,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                color ?? Colors.grey.shade400,
              ),
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  /// Creates a retry fallback with action button
  static Widget retryFallback({
    double? width,
    double? height,
    VoidCallback? onRetry,
    String? message,
    Color? color,
  }) {
    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.refresh,
            size: 32,
            color: color ?? Colors.grey.shade400,
          ),
          const SizedBox(height: 8),
          Text(
            message ?? 'Falha ao carregar',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                minimumSize: const Size(0, 0),
              ),
              child: Text(
                'Tentar novamente',
                style: TextStyle(
                  fontSize: 10,
                  color: color ?? Colors.blue,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  static Widget _buildFallbackMessage(String message, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 48,
            color: Colors.white.withOpacity(0.8),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Custom painter for auth header fallback background
class AuthHeaderFallbackPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    // Draw geometric pattern
    _drawGeometricPattern(canvas, size, paint);
  }

  void _drawGeometricPattern(Canvas canvas, Size size, Paint paint) {
    const patternSize = 40.0;
    final rows = (size.height / patternSize).ceil();
    final cols = (size.width / patternSize).ceil();

    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < cols; col++) {
        final x = col * patternSize + (row % 2) * (patternSize / 2);
        final y = row * patternSize;

        if (x < size.width && y < size.height) {
          _drawHexagon(canvas, Offset(x, y), patternSize / 4, paint);
        }
      }
    }
  }

  void _drawHexagon(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (i * 60) * (math.pi / 180);
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

/// Animated fallback component with pulse effect
class AnimatedFallback extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final bool enabled;

  const AnimatedFallback({
    super.key,
    required this.child,
    this.duration = const Duration(seconds: 2),
    this.enabled = true,
  });

  @override
  State<AnimatedFallback> createState() => _AnimatedFallbackState();
}

class _AnimatedFallbackState extends State<AnimatedFallback>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    
    _animation = Tween<double>(
      begin: 0.7,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    if (widget.enabled) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return widget.child;
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: widget.child,
        );
      },
    );
  }
}
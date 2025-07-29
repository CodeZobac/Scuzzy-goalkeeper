import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../data/models/cluster_result.dart';
import '../../data/models/cluster_point.dart';

/// Beautiful animation widget that shows cluster expansion
class ClusterExpansionAnimation extends StatefulWidget {
  final Cluster cluster;
  final VoidCallback? onComplete;
  final Duration duration;

  const ClusterExpansionAnimation({
    Key? key,
    required this.cluster,
    this.onComplete,
    this.duration = const Duration(milliseconds: 800),
  }) : super(key: key);

  @override
  State<ClusterExpansionAnimation> createState() => _ClusterExpansionAnimationState();
}

class _ClusterExpansionAnimationState extends State<ClusterExpansionAnimation>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late List<Animation<Offset>> _particleAnimations;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 2.5,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _opacityAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
    ));

    // Create particle animations for each point in the cluster
    _particleAnimations = widget.cluster.points.asMap().entries.map((entry) {
      final index = entry.key;
      final point = entry.value;
      
      // Calculate target position for this particle
      final angle = (index * (360 / widget.cluster.points.length)) * (math.pi / 180);
      final distance = 60.0 + (index % 3) * 20.0; // Vary distance for visual interest
      
      final targetOffset = Offset(
        math.cos(angle) * distance,
        math.sin(angle) * distance,
      );

      return Tween<Offset>(
        begin: Offset.zero,
        end: targetOffset,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Interval(
          0.2 + (index * 0.1).clamp(0.0, 0.6), // Stagger the animations
          1.0,
          curve: Curves.elasticOut,
        ),
      ));
    }).toList();

    // Start animation
    _controller.forward().then((_) {
      widget.onComplete?.call();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Central cluster that scales and fades
            Transform.scale(
              scale: _scaleAnimation.value,
              child: Opacity(
                opacity: _opacityAnimation.value,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        Color(widget.cluster.representativePoint.color),
                        Color(widget.cluster.representativePoint.color).withOpacity(0.6),
                      ],
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Color(widget.cluster.representativePoint.color).withOpacity(0.4),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      widget.cluster.size.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            
            // Individual particles flying out
            ...widget.cluster.points.asMap().entries.map((entry) {
              final index = entry.key;
              final point = entry.value;
              final animation = _particleAnimations[index];
              
              return Transform.translate(
                offset: animation.value,
                child: _buildParticle(point, index),
              );
            }).toList(),
          ],
        );
      },
    );
  }

  Widget _buildParticle(ClusterPoint point, int index) {
    final delay = index * 0.1;
    final particleOpacity = _controller.value > delay ? 
        ((_controller.value - delay) / (1.0 - delay)).clamp(0.0, 1.0) : 0.0;
    
    return Opacity(
      opacity: particleOpacity,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(point.color),
              Color(point.color).withOpacity(0.8),
            ],
          ),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Color(point.color).withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          _getIconForType(point.type),
          color: Colors.white,
          size: 12,
        ),
      ),
    );
  }

  IconData _getIconForType(ClusterPointType type) {
    switch (type) {
      case ClusterPointType.field:
        return Icons.sports_soccer;
      case ClusterPointType.goalkeeper:
        return Icons.sports_handball;
      case ClusterPointType.player:
        return Icons.person;
    }
  }
}
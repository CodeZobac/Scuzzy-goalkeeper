import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../../../auth/presentation/theme/app_theme.dart';
import '../../data/models/cluster_result.dart';
import '../../data/models/cluster_point.dart';

class ClusterMarker extends StatefulWidget {
  final Cluster cluster;
  final bool isActive;
  final bool isVisibleWhenZoomedOut;
  final VoidCallback? onTap;
  final double animationProgress;

  const ClusterMarker({
    Key? key,
    required this.cluster,
    this.isActive = false,
    this.isVisibleWhenZoomedOut = true,
    this.onTap,
    this.animationProgress = 1.0,
  }) : super(key: key);

  // Backwards compatibility constructor
  factory ClusterMarker.legacy({
    Key? key,
    required int count,
    bool isActive = false,
    bool isVisibleWhenZoomedOut = true,
  }) {
    // Create a dummy cluster for legacy support
    final dummyCluster = Cluster(
      center: const LatLng(0, 0),
      points: List.generate(count, (i) => ClusterPoint(
        id: 'dummy_$i',
        location: const LatLng(0, 0),
        type: ClusterPointType.field,
        data: {},
      )),
    );
    
    return ClusterMarker(
      key: key,
      cluster: dummyCluster,
      isActive: isActive,
      isVisibleWhenZoomedOut: isVisibleWhenZoomedOut,
    );
  }

  @override
  State<ClusterMarker> createState() => _ClusterMarkerState();
}

class _ClusterMarkerState extends State<ClusterMarker>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    // Start subtle pulsing animation for active clusters
    if (widget.isActive) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(ClusterMarker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _pulseController.repeat(reverse: true);
      } else {
        _pulseController.stop();
        _pulseController.reset();
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisibleWhenZoomedOut) {
      return const SizedBox.shrink();
    }

    final dominantType = widget.cluster.dominantType;
    final size = _getClusterSize(widget.cluster.size);
    final color = _getClusterColor(dominantType, widget.isActive);
    
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        final scale = widget.isActive ? _pulseAnimation.value : 1.0;
        
        return Transform.scale(
          scale: scale * widget.animationProgress,
          child: GestureDetector(
            onTap: widget.onTap,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer glow for active state
                if (widget.isActive)
                  Container(
                    width: size + 16,
                    height: size + 16,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                  ),
                
                // Main cluster circle
                Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    gradient: _getClusterGradient(dominantType, widget.isActive),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Count text
                      Center(
                        child: Text(
                          widget.cluster.size.toString(),
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: _getFontSize(size),
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(0.3),
                                offset: const Offset(0, 1),
                                blurRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      // Type indicator (small icon in corner)
                      Positioned(
                        top: 2,
                        right: 2,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _getTypeIcon(dominantType),
                            size: 10,
                            color: Color(widget.cluster.representativePoint.color),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Particle effect for expansion (when animationProgress < 1)
                if (widget.animationProgress < 1.0)
                  ...List.generate(3, (index) {
                    final angle = (index * 120) * (3.14159 / 180);
                    final distance = (1.0 - widget.animationProgress) * 30;
                    
                    return Transform.translate(
                      offset: Offset(
                        math.cos(angle) * distance,
                        math.sin(angle) * distance,
                      ),
                      child: Opacity(
                        opacity: 1.0 - widget.animationProgress,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.7),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    );
                  }),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Get cluster size based on point count
  double _getClusterSize(int count) {
    if (count <= 5) return 40;
    if (count <= 10) return 48;
    if (count <= 20) return 56;
    return 64;
  }

  /// Get cluster color based on type and state
  Color _getClusterColor(ClusterPointType type, bool isActive) {
    if (isActive) {
      return const Color(0xFFFF8C00); // Active orange
    }
    
    switch (type) {
      case ClusterPointType.field:
        return const Color(0xFF4CAF50); // Green
      case ClusterPointType.goalkeeper:
        return const Color(0xFFFF9800); // Orange
      case ClusterPointType.player:
        return const Color(0xFF2196F3); // Blue
    }
  }

  /// Get cluster gradient for beautiful visual effect
  LinearGradient _getClusterGradient(ClusterPointType type, bool isActive) {
    final baseColor = _getClusterColor(type, isActive);
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        baseColor,
        baseColor.withOpacity(0.8),
      ],
    );
  }

  /// Get font size based on cluster size
  double _getFontSize(double containerSize) {
    if (containerSize <= 40) return 14;
    if (containerSize <= 48) return 16;
    if (containerSize <= 56) return 18;
    return 20;
  }

  /// Get icon for cluster type
  IconData _getTypeIcon(ClusterPointType type) {
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

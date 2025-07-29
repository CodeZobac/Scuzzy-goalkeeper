import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../../data/models/cluster_result.dart';
import '../../data/models/cluster_point.dart';

class ClusterMarker extends StatefulWidget {
  final Cluster cluster;
  final bool isActive;
  final bool isVisibleWhenZoomedOut;
  final VoidCallback? onTap;
  final double animationProgress;
  final double zoom;

  const ClusterMarker({
    Key? key,
    required this.cluster,
    this.isActive = false,
    this.isVisibleWhenZoomedOut = true,
    this.onTap,
    this.animationProgress = 1.0,
    this.zoom = 12.0,
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
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rippleController;
  late AnimationController _scaleController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rippleAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    // Pulse animation for active state
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.15,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    // Ripple animation for tap feedback
    _rippleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _rippleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _rippleController,
      curve: Curves.easeOut,
    ));
    
    // Scale animation for appearance
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));
    
    // Start animations
    _scaleController.forward();
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
    _rippleController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisibleWhenZoomedOut) {
      return const SizedBox.shrink();
    }

    final dominantType = widget.cluster.dominantType;
    final size = _getClusterSize(widget.cluster.size);
    final colors = _getClusterColors(dominantType, widget.isActive);
    final typeBreakdown = widget.cluster.typeBreakdown;
    
    return AnimatedBuilder(
      animation: Listenable.merge([_pulseAnimation, _rippleAnimation, _scaleAnimation]),
      builder: (context, child) {
        final pulseScale = widget.isActive ? _pulseAnimation.value : 1.0;
        final scale = pulseScale * widget.animationProgress * _scaleAnimation.value;
        
        return Transform.scale(
          scale: scale,
          child: GestureDetector(
            onTap: () {
              _rippleController.forward().then((_) {
                _rippleController.reset();
              });
              widget.onTap?.call();
            },
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Ripple effect on tap
                if (_rippleAnimation.value > 0)
                  Container(
                    width: size * (1 + _rippleAnimation.value * 0.8),
                    height: size * (1 + _rippleAnimation.value * 0.8),
                    decoration: BoxDecoration(
                      color: colors.primary.withOpacity(0.3 * (1 - _rippleAnimation.value)),
                      shape: BoxShape.circle,
                    ),
                  ),
                
                // Outer glow for active state
                if (widget.isActive)
                  Container(
                    width: size + 20,
                    height: size + 20,
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          colors.primary.withOpacity(0.4),
                          colors.primary.withOpacity(0.1),
                          Colors.transparent,
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                  ),
                
                // Shadow layer
                Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                        spreadRadius: 2,
                      ),
                      BoxShadow(
                        color: colors.primary.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
                
                // Main cluster circle with gradient
                Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    gradient: _getModernGradient(colors, widget.isActive),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 3,
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Subtle inner glow
                      Container(
                        width: size,
                        height: size,
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            colors: [
                              Colors.white.withOpacity(0.3),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.7],
                          ),
                          shape: BoxShape.circle,
                        ),
                      ),
                      
                      // Count text with better typography
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.cluster.size.toString(),
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: _getFontSize(size),
                                letterSpacing: -0.5,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.4),
                                    offset: const Offset(0, 1),
                                    blurRadius: 3,
                                  ),
                                ],
                              ),
                            ),
                            if (size >= 56) // Show type indicator for larger clusters
                              Text(
                                _getTypeLabel(dominantType),
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 8,
                                  letterSpacing: 0.5,
                                ),
                              ),
                          ],
                        ),
                      ),
                      
                      // Multi-type indicator (colored dots for mixed clusters)
                      if (typeBreakdown.length > 1)
                        Positioned(
                          top: 4,
                          right: 4,
                          child: _buildTypeIndicators(typeBreakdown, size),
                        ),
                      
                      // Dominant type icon for single-type clusters
                      if (typeBreakdown.length == 1)
                        Positioned(
                          top: 4,
                          right: 4,
                          child: Container(
                            width: size * 0.25,
                            height: size * 0.25,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 2,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Icon(
                              _getTypeIcon(dominantType),
                              size: size * 0.15,
                              color: colors.primary,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                
                // Particle effect for expansion
                if (widget.animationProgress < 1.0)
                  ..._buildExpansionParticles(colors.primary, size),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Get cluster size based on point count with better scaling
  double _getClusterSize(int count) {
    if (count <= 2) return 44;
    if (count <= 5) return 52;
    if (count <= 10) return 60;
    if (count <= 20) return 68;
    if (count <= 50) return 76;
    return 84;
  }

  /// Get modern color scheme for cluster
  ClusterColorScheme _getClusterColors(ClusterPointType type, bool isActive) {
    if (isActive) {
      return const ClusterColorScheme(
        primary: Color(0xFFFF6B35),
        secondary: Color(0xFFFF8C42),
        accent: Color(0xFFFFA726),
      );
    }
    
    switch (type) {
      case ClusterPointType.field:
        return const ClusterColorScheme(
          primary: Color(0xFF2E7D32),
          secondary: Color(0xFF4CAF50),
          accent: Color(0xFF66BB6A),
        );
      case ClusterPointType.goalkeeper:
        return const ClusterColorScheme(
          primary: Color(0xFFE65100),
          secondary: Color(0xFFFF9800),
          accent: Color(0xFFFFB74D),
        );
      case ClusterPointType.player:
        return const ClusterColorScheme(
          primary: Color(0xFF1565C0),
          secondary: Color(0xFF2196F3),
          accent: Color(0xFF64B5F6),
        );
    }
  }

  /// Get modern gradient with depth and shine
  LinearGradient _getModernGradient(ClusterColorScheme colors, bool isActive) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        colors.accent,
        colors.primary,
        colors.primary.withOpacity(0.9),
      ],
      stops: const [0.0, 0.6, 1.0],
    );
  }

  /// Get font size based on cluster size with better scaling
  double _getFontSize(double containerSize) {
    if (containerSize <= 44) return 16;
    if (containerSize <= 52) return 18;
    if (containerSize <= 60) return 20;
    if (containerSize <= 68) return 22;
    if (containerSize <= 76) return 24;
    return 26;
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

  /// Get type label for display
  String _getTypeLabel(ClusterPointType type) {
    switch (type) {
      case ClusterPointType.field:
        return 'CAMPOS';
      case ClusterPointType.goalkeeper:
        return 'GR';
      case ClusterPointType.player:
        return 'JOGADORES';
    }
  }

  /// Build type indicators for mixed clusters
  Widget _buildTypeIndicators(Map<ClusterPointType, int> typeBreakdown, double size) {
    final types = typeBreakdown.keys.toList();
    final indicatorSize = (size * 0.15).clamp(6.0, 12.0);
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: types.take(3).map((type) {
        final colors = _getClusterColors(type, false);
        return Container(
          width: indicatorSize,
          height: indicatorSize,
          margin: const EdgeInsets.only(bottom: 2),
          decoration: BoxDecoration(
            color: colors.primary,
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  /// Build expansion particle effects
  List<Widget> _buildExpansionParticles(Color color, double size) {
    return List.generate(6, (index) {
      final angle = (index * 60) * (math.pi / 180);
      final distance = (1.0 - widget.animationProgress) * (size * 0.8);
      final particleSize = 6.0 + (index % 3) * 2;
      
      return Transform.translate(
        offset: Offset(
          math.cos(angle) * distance,
          math.sin(angle) * distance,
        ),
        child: Opacity(
          opacity: (1.0 - widget.animationProgress) * 0.8,
          child: Container(
            width: particleSize,
            height: particleSize,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  color.withOpacity(0.8),
                  color.withOpacity(0.4),
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

/// Color scheme for modern cluster styling
class ClusterColorScheme {
  final Color primary;
  final Color secondary;
  final Color accent;

  const ClusterColorScheme({
    required this.primary,
    required this.secondary,
    required this.accent,
  });
}

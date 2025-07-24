import 'package:flutter/material.dart';
import '../../../../shared/widgets/svg_asset_manager.dart';

/// Base widget for map markers that use SVG icons
/// Provides consistent styling and animation behavior across all marker types
class MapIconMarker extends StatefulWidget {
  final String svgAssetKey;
  final bool isSelected;
  final bool isActive;
  final double size;
  final Color? primaryColor;
  final Color? secondaryColor;
  final Widget? statusIndicator;
  final VoidCallback? onTap;
  final String? semanticsLabel;
  final Duration animationDuration;
  final bool enablePulseAnimation;
  final double elevation;

  const MapIconMarker({
    super.key,
    required this.svgAssetKey,
    this.isSelected = false,
    this.isActive = true,
    this.size = 48,
    this.primaryColor,
    this.secondaryColor,
    this.statusIndicator,
    this.onTap,
    this.semanticsLabel,
    this.animationDuration = const Duration(milliseconds: 300),
    this.enablePulseAnimation = false,
    this.elevation = 4,
  });

  @override
  State<MapIconMarker> createState() => _MapIconMarkerState();
}

class _MapIconMarkerState extends State<MapIconMarker>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    _scaleController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    if (widget.enablePulseAnimation) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(MapIconMarker oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.isSelected != oldWidget.isSelected) {
      if (widget.isSelected) {
        _scaleController.forward();
      } else {
        _scaleController.reverse();
      }
    }

    if (widget.enablePulseAnimation != oldWidget.enablePulseAnimation) {
      if (widget.enablePulseAnimation) {
        _pulseController.repeat(reverse: true);
      } else {
        _pulseController.stop();
        _pulseController.reset();
      }
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveSize = widget.isSelected ? widget.size * 1.2 : widget.size;
    final primaryColor = widget.primaryColor ?? Theme.of(context).primaryColor;
    final secondaryColor = widget.secondaryColor ?? primaryColor.withOpacity(0.2);

    return GestureDetector(
      onTap: widget.onTap,
      child: Semantics(
        label: widget.semanticsLabel ?? 'Map marker',
        button: widget.onTap != null,
        child: AnimatedBuilder(
          animation: Listenable.merge([_scaleAnimation, _pulseAnimation]),
          builder: (context, child) {
            final scale = widget.enablePulseAnimation 
                ? _pulseAnimation.value 
                : _scaleAnimation.value;
            
            return Transform.scale(
              scale: scale,
              child: Container(
                width: effectiveSize,
                height: effectiveSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: secondaryColor,
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.3),
                      blurRadius: widget.elevation * 2,
                      offset: Offset(0, widget.elevation),
                      spreadRadius: widget.isSelected ? 2 : 0,
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Background circle with gradient
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            primaryColor.withOpacity(0.8),
                            primaryColor,
                          ],
                          stops: const [0.3, 1.0],
                        ),
                      ),
                    ),
                    
                    // SVG Icon
                    Center(
                      child: SvgAssetManager.getAsset(
                        widget.svgAssetKey,
                        width: effectiveSize * 0.6,
                        height: effectiveSize * 0.6,
                        color: Colors.white,
                        onError: () {
                          debugPrint('Failed to load SVG for marker: ${widget.svgAssetKey}');
                        },
                      ),
                    ),
                    
                    // Selection ring
                    if (widget.isSelected)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 3,
                            ),
                          ),
                        ),
                      ),
                    
                    // Status indicator
                    if (widget.statusIndicator != null)
                      Positioned(
                        top: 0,
                        right: 0,
                        child: widget.statusIndicator!,
                      ),
                    
                    // Inactive overlay
                    if (!widget.isActive)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.grey.withOpacity(0.6),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.block,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Status indicator widget for markers
class MarkerStatusIndicator extends StatelessWidget {
  final Color color;
  final IconData? icon;
  final double size;

  const MarkerStatusIndicator({
    super.key,
    required this.color,
    this.icon,
    this.size = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: icon != null
          ? Icon(
              icon,
              size: size * 0.6,
              color: Colors.white,
            )
          : null,
    );
  }
}
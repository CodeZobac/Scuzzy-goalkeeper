import 'package:flutter/material.dart';
import '../../../auth/presentation/theme/app_theme.dart';

class StarRatingWidget extends StatefulWidget {
  final int rating;
  final Function(int) onRatingChanged;
  final double size;
  final bool isReadOnly;
  final Color? activeColor;
  final Color? inactiveColor;

  const StarRatingWidget({
    super.key,
    required this.rating,
    required this.onRatingChanged,
    this.size = 32,
    this.isReadOnly = false,
    this.activeColor,
    this.inactiveColor,
  });

  @override
  State<StarRatingWidget> createState() => _StarRatingWidgetState();
}

class _StarRatingWidgetState extends State<StarRatingWidget>
    with TickerProviderStateMixin {
  late List<AnimationController> _animationControllers;
  late List<Animation<double>> _scaleAnimations;
  late List<Animation<double>> _rotationAnimations;
  
  int _hoveredRating = 0;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _animationControllers = List.generate(
      5,
      (index) => AnimationController(
        duration: AppTheme.shortAnimation,
        vsync: this,
      ),
    );

    _scaleAnimations = _animationControllers.map((controller) {
      return Tween<double>(
        begin: 1.0,
        end: 1.3,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.elasticOut,
      ));
    }).toList();

    _rotationAnimations = _animationControllers.map((controller) {
      return Tween<double>(
        begin: 0.0,
        end: 0.2,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.easeInOut,
      ));
    }).toList();
  }

  @override
  void dispose() {
    for (var controller in _animationControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onStarTap(int index) {
    if (widget.isReadOnly) return;

    final newRating = index + 1;
    widget.onRatingChanged(newRating);

    // Animate the tapped star and previous stars
    for (int i = 0; i <= index; i++) {
      _animationControllers[i].forward().then((_) {
        _animationControllers[i].reverse();
      });
    }
  }

  void _onStarHover(int index) {
    if (widget.isReadOnly) return;
    
    setState(() {
      _hoveredRating = index + 1;
    });
  }

  void _onHoverExit() {
    if (widget.isReadOnly) return;
    
    setState(() {
      _hoveredRating = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) => _buildStar(index)),
    );
  }

  Widget _buildStar(int index) {
    final isActive = index < widget.rating;
    final isHovered = index < _hoveredRating;
    final shouldHighlight = isActive || (_hoveredRating > 0 && isHovered);

    return GestureDetector(
      onTap: () => _onStarTap(index),
      child: MouseRegion(
        onEnter: (_) => _onStarHover(index),
        onExit: (_) => _onHoverExit(),
        cursor: widget.isReadOnly 
            ? SystemMouseCursors.basic 
            : SystemMouseCursors.click,
        child: AnimatedBuilder(
          animation: Listenable.merge([
            _scaleAnimations[index],
            _rotationAnimations[index],
          ]),
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimations[index].value,
              child: Transform.rotate(
                angle: _rotationAnimations[index].value,
                child: Container(
                  width: widget.size + 16,
                  height: widget.size + 16,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  child: Center(
                    child: TweenAnimationBuilder<Color?>(
                      duration: AppTheme.shortAnimation,
                      tween: ColorTween(
                        begin: shouldHighlight 
                            ? (widget.activeColor ?? AppTheme.accentColor)
                            : (widget.inactiveColor ?? AppTheme.secondaryText),
                        end: shouldHighlight 
                            ? (widget.activeColor ?? AppTheme.accentColor)
                            : (widget.inactiveColor ?? AppTheme.secondaryText),
                      ),
                      builder: (context, color, child) {
                        return Stack(
                          alignment: Alignment.center,
                          children: [
                            // Shadow/glow effect for active stars
                            if (shouldHighlight)
                              Icon(
                                Icons.star,
                                size: widget.size + 4,
                                color: color?.withOpacity(0.3),
                              ),
                            
                            // Main star
                            Icon(
                              shouldHighlight ? Icons.star : Icons.star_outline,
                              size: widget.size,
                              color: color,
                            ),
                            
                            // Shine effect for active stars
                            if (shouldHighlight)
                              Positioned(
                                top: widget.size * 0.2,
                                left: widget.size * 0.3,
                                child: Container(
                                  width: widget.size * 0.15,
                                  height: widget.size * 0.15,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.6),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// Compact version for displaying ratings in lists
class CompactStarRating extends StatelessWidget {
  final double rating;
  final double size;
  final Color? activeColor;
  final Color? inactiveColor;
  final bool showNumber;

  const CompactStarRating({
    super.key,
    required this.rating,
    this.size = 16,
    this.activeColor,
    this.inactiveColor,
    this.showNumber = false,
  });

  @override
  Widget build(BuildContext context) {
    final fullStars = rating.floor();
    final hasHalfStar = (rating - fullStars) >= 0.5;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Full stars
        for (int i = 0; i < fullStars; i++)
          Icon(
            Icons.star,
            size: size,
            color: activeColor ?? AppTheme.accentColor,
          ),
        
        // Half star
        if (hasHalfStar)
          Icon(
            Icons.star_half,
            size: size,
            color: activeColor ?? AppTheme.accentColor,
          ),
        
        // Empty stars
        for (int i = fullStars + (hasHalfStar ? 1 : 0); i < 5; i++)
          Icon(
            Icons.star_outline,
            size: size,
            color: inactiveColor ?? AppTheme.secondaryText,
          ),
        
        // Rating number
        if (showNumber) ...[
          const SizedBox(width: 4),
          Text(
            rating.toStringAsFixed(1),
            style: AppTheme.bodyMedium.copyWith(
              fontSize: size * 0.8,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}

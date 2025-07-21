import 'package:flutter/material.dart';
import 'package:goalkeeper/src/features/user_profile/data/models/user_profile.dart';
import '../../../auth/presentation/theme/app_theme.dart';
import 'dart:math' as math;

class FUTProfileCard extends StatefulWidget {
  final UserProfile userProfile;

  const FUTProfileCard({
    super.key,
    required this.userProfile,
  });

  @override
  State<FUTProfileCard> createState() => _FUTProfileCardState();
}

class _FUTProfileCardState extends State<FUTProfileCard>
    with TickerProviderStateMixin {
  late AnimationController _hoverController;
  late Animation<double> _elevationAnimation;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _elevationAnimation = Tween<double>(
      begin: 8,
      end: 20,
    ).animate(CurvedAnimation(
      parent: _hoverController,
      curve: Curves.easeOutCubic,
    ));

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(
      parent: _hoverController,
      curve: Curves.easeOutCubic,
    ));
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
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

  Color get _cardColor {
    if (widget.userProfile.isGoalkeeper) {
      return const Color(0xFF00A85A); // Green for goalkeeper
    }
    return const Color(0xFFE94560); // Pink/Red for player
  }

  Color get _accentColor {
    if (widget.userProfile.isGoalkeeper) {
      return const Color(0xFF4ECDC4); // Cyan accent
    }
    return const Color(0xFFFF6B6B); // Red accent
  }

  String get _positionText {
    return widget.userProfile.isGoalkeeper ? 'GK' : 'FP';
  }

  String get _overallRating {
    if (widget.userProfile.isGoalkeeper) {
      final reflexes = _calculateAverage(widget.userProfile.reflexes);
      final positioning = _calculateAverage(widget.userProfile.positioning);
      final distribution = _calculateAverage(widget.userProfile.distribution);
      final communication = _calculateAverage(widget.userProfile.communication);
      if (reflexes == 0 && positioning == 0 && distribution == 0 && communication == 0) {
        return 'N/D';
      }
      final average = (reflexes + positioning + distribution + communication) / 4;
      return math.min(99, average.round()).toString();
    } else {
      // Generate a rating based on profile completion and other factors
      int baseRating = 65;
      if (widget.userProfile.club != null) baseRating += 5;
      if (widget.userProfile.nationality != null) baseRating += 5;
      if (widget.userProfile.birthDate != null) baseRating += 5;
      if (widget.userProfile.pricePerGame != null) baseRating += 10;
      return math.min(99, baseRating).toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _onHover(true),
      onExit: (_) => _onHover(false),
      child: AnimatedBuilder(
        animation: _hoverController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              height: 280,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: _cardColor.withOpacity(0.3),
                    blurRadius: _elevationAnimation.value,
                    offset: Offset(0, _elevationAnimation.value * 0.5),
                    spreadRadius: 2,
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: _elevationAnimation.value * 0.8,
                    offset: Offset(0, _elevationAnimation.value * 0.3),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        _cardColor,
                        _cardColor.withOpacity(0.8),
                        _accentColor.withOpacity(0.6),
                      ],
                      stops: const [0.0, 0.7, 1.0],
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Background pattern
                      _buildBackgroundPattern(),
                      
                      // Main content
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header with rating and position
                            _buildCardHeader(),
                            
                            const SizedBox(height: 16),
                            
                            // Player info and avatar
                            _buildPlayerSection(),
                            
                            const Spacer(),
                            
                            // Stats section
                            _buildStatsSection(),
                            
                            const SizedBox(height: 12),
                            
                            // Footer with club and nationality
                            _buildCardFooter(),
                          ],
                        ),
                      ),
                      
                      // Shine effect when hovered
                      if (_isHovered) _buildShineEffect(),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBackgroundPattern() {
    return Positioned.fill(
      child: CustomPaint(
        painter: FUTCardPatternPainter(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
    );
  }

  Widget _buildCardHeader() {
    return Row(
      children: [
        // Overall Rating
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 2,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _overallRating.toString(),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  height: 1,
                ),
              ),
              Text(
                _positionText,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  height: 1,
                ),
              ),
            ],
          ),
        ),
        
        const Spacer(),
        
        // Card type indicator
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
            ),
          ),
          child: Text(
            widget.userProfile.isGoalkeeper ? 'GOALKEEPER' : 'PLAYER',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlayerSection() {
    return Row(
      children: [
        // Avatar
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.4),
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(17),
            child: Center(
              child: Text(
                widget.userProfile.name.isNotEmpty
                    ? widget.userProfile.name[0].toUpperCase()
                    : 'U',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
        
        const SizedBox(width: 16),
        
        // Player name and details
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.userProfile.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      offset: Offset(0, 1),
                      blurRadius: 3,
                      color: Colors.black26,
                    ),
                  ],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              if (widget.userProfile.city != null)
                Text(
                  widget.userProfile.city!,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsSection() {
    final stats = _getPlayerStats();
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: stats.map((stat) => _buildStatItem(stat['label']!, stat['value']!)).toList(),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildCardFooter() {
    return Row(
      children: [
        // Club
        if (widget.userProfile.club != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              widget.userProfile.club!,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
        
        // Nationality flag placeholder
        if (widget.userProfile.nationality != null)
          Container(
            width: 24,
            height: 16,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
              ),
            ),
            child: Center(
              child: Text(
                widget.userProfile.nationality!.substring(0, math.min(2, widget.userProfile.nationality!.length)).toUpperCase(),
                style: const TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        
        const Spacer(),
        
        // Price indicator
        if (widget.userProfile.pricePerGame != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '€${widget.userProfile.pricePerGame!.toStringAsFixed(0)}',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildShineEffect() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: const Alignment(-1, -1),
            end: const Alignment(1, 1),
            colors: [
              Colors.white.withOpacity(0.0),
              Colors.white.withOpacity(0.1),
              Colors.white.withOpacity(0.0),
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
      ),
    );
  }

  double _calculateAverage(List<int>? values) {
    if (values == null || values.isEmpty) {
      return 0.0;
    }
    return values.reduce((a, b) => a + b) / values.length;
  }

  List<Map<String, String>> _getPlayerStats() {
    if (widget.userProfile.isGoalkeeper) {
      final reflexes = _calculateAverage(widget.userProfile.reflexes);
      final positioning = _calculateAverage(widget.userProfile.positioning);
      final distribution = _calculateAverage(widget.userProfile.distribution);

      return [
        {'label': 'REF', 'value': reflexes > 0 ? reflexes.toStringAsFixed(0) : 'N/D'},
        {'label': 'POS', 'value': positioning > 0 ? positioning.toStringAsFixed(0) : 'N/D'},
        {'label': 'KIC', 'value': distribution > 0 ? distribution.toStringAsFixed(0) : 'N/D'},
      ];
    } else {
      return [
        {'label': 'PAC', 'value': '82'},
        {'label': 'SHO', 'value': '78'},
        {'label': 'PAS', 'value': '85'},
      ];
    }
  }
}

class FUTCardPatternPainter extends CustomPainter {
  final Color color;

  FUTCardPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // Draw diagonal lines pattern
    for (int i = 0; i < size.width + size.height; i += 30) {
      canvas.drawLine(
        Offset(i.toDouble(), 0),
        Offset(0, i.toDouble()),
        paint,
      );
    }

    // Draw dots pattern
    for (double x = 20; x < size.width; x += 40) {
      for (double y = 20; y < size.height; y += 40) {
        canvas.drawCircle(
          Offset(x, y),
          1.5,
          Paint()..color = color.withOpacity(0.3),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

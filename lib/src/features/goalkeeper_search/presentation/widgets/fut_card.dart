import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/models/goalkeeper.dart';
import '../../../auth/presentation/theme/app_theme.dart';
import 'fifa_card_clipper.dart';
import '../screens/goalkeeper_details_screen.dart';

enum CardRarity { 
  Bronze, 
  Silver, 
  Gold, 
  Special, 
  TeamOfTheWeek, 
  Icon 
}

class ExpandableFutCard extends StatefulWidget {
  final Goalkeeper goalkeeper;
  final bool isExpanded;
  final VoidCallback? onTap;

  const ExpandableFutCard({
    super.key,
    required this.goalkeeper,
    required this.isExpanded,
    this.onTap,
  });

  @override
  State<ExpandableFutCard> createState() => _ExpandableFutCardState();
}

class _ExpandableFutCardState extends State<ExpandableFutCard>
    with TickerProviderStateMixin {
  late AnimationController _glowController;
  late AnimationController _shimmerController;
  late AnimationController _rotationController;
  late Animation<double> _glowAnimation;
  late Animation<double> _shimmerAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    
    _glowController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _shimmerController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    
    _rotationController = AnimationController(
      duration: AppTheme.mediumAnimation,
      vsync: this,
    );

    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
    
    _shimmerAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.linear),
    );
    
    _rotationAnimation = Tween<double>(begin: 0.0, end: 0.05).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.elasticOut),
    );

    if (_rarity == CardRarity.Special || _rarity == CardRarity.TeamOfTheWeek || _rarity == CardRarity.Icon) {
      _glowController.repeat(reverse: true);
      _shimmerController.repeat();
    }

    if (widget.goalkeeper.inDemand == true) {
      _glowController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _glowController.dispose();
    _shimmerController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  CardRarity get _rarity {
    final rating = widget.goalkeeper.overallRating ?? 0;
    if (rating >= 95) return CardRarity.Icon;
    if (rating >= 90) return CardRarity.TeamOfTheWeek;
    if (rating >= 85) return CardRarity.Special;
    if (rating >= 75) return CardRarity.Gold;
    if (rating >= 65) return CardRarity.Silver;
    return CardRarity.Bronze;
  }

  List<Color> get _rarityGradientColors {
    switch (_rarity) {
      case CardRarity.Icon:
        return [
          const Color(0xFF8A2387),
          const Color(0xFFE94057),
          const Color(0xFFF27121),
          const Color(0xFFE94057),
          const Color(0xFF8A2387),
        ];
      case CardRarity.TeamOfTheWeek:
        return [
          const Color(0xFF000428),
          const Color(0xFF004e92),
          const Color(0xFF009ffd),
          const Color(0xFF004e92),
          const Color(0xFF000428),
        ];
      case CardRarity.Special:
        return [
          Colors.blue.shade900,
          Colors.blue.shade700,
          Colors.blue.shade500,
          Colors.blue.shade700,
          Colors.blue.shade900,
        ];
      case CardRarity.Gold:
        return [
          const Color(0xFFB8860B),
          const Color(0xFFDAA520),
          const Color(0xFFFFD700),
          const Color(0xFFDAA520),
          const Color(0xFFB8860B),
        ];
      case CardRarity.Silver:
        return [
          const Color(0xFF708090),
          const Color(0xFF9A9A9A),
          const Color(0xFFC0C0C0),
          const Color(0xFF9A9A9A),
          const Color(0xFF708090),
        ];
      case CardRarity.Bronze:
        return [
          const Color(0xFFCD7F32),
          const Color(0xFFB87333),
          const Color(0xFF8C7853),
          const Color(0xFFB87333),
          const Color(0xFFCD7F32),
        ];
    }
  }

  Color get _glowColor {
    switch (_rarity) {
      case CardRarity.Icon:
        return const Color(0xFFE94057);
      case CardRarity.TeamOfTheWeek:
        return const Color(0xFF009ffd);
      case CardRarity.Special:
        return Colors.blue;
      case CardRarity.Gold:
        return const Color(0xFFFFD700);
      case CardRarity.Silver:
        return const Color(0xFFC0C0C0);
      case CardRarity.Bronze:
        return const Color(0xFFCD7F32);
    }
  }

  CustomClipper<Path> get _cardClipper {
    switch (_rarity) {
      case CardRarity.Icon:
        return PremiumCardClipper();
      case CardRarity.TeamOfTheWeek:
        return const EnhancedFifaCardClipper(notchDepth: 0.08);
      case CardRarity.Special:
        return const EnhancedFifaCardClipper(notchDepth: 0.06);
      default:
        return FifaCardClipper();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        HapticFeedback.lightImpact();
        _rotationController.forward();
      },
      onTapUp: (_) {
        _rotationController.reverse();
        widget.onTap?.call();
      },
      onTapCancel: () => _rotationController.reverse(),
      child: AnimatedBuilder(
        animation: Listenable.merge([_glowAnimation, _rotationAnimation]),
        builder: (context, child) {
          return Transform.rotate(
            angle: _rotationAnimation.value,
            child: AnimatedContainer(
              duration: AppTheme.mediumAnimation,
              curve: Curves.easeInOut,
              height: widget.isExpanded ? 600 : 380,
              child: Stack(
                children: [
                  // Glow effect for special cards
                  if (_rarity == CardRarity.Special || 
                      _rarity == CardRarity.TeamOfTheWeek || 
                      _rarity == CardRarity.Icon ||
                      widget.goalkeeper.inDemand == true)
                    _buildGlowEffect(),
                  
                  // Main card
                  _buildMainCard(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGlowEffect() {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28.0),
            boxShadow: [
              BoxShadow(
                color: _glowColor.withOpacity(0.3 + (_glowAnimation.value * 0.4)),
                blurRadius: 20 + (_glowAnimation.value * 10),
                spreadRadius: 2 + (_glowAnimation.value * 3),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMainCard() {
    return ClipPath(
      clipper: _cardClipper,
      child: Card(
        elevation: 12.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.0),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24.0),
            gradient: LinearGradient(
              colors: _rarityGradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
            ),
          ),
          child: Stack(
            children: [
              // Background pattern for special cards
              if (_rarity == CardRarity.Special || 
                  _rarity == CardRarity.TeamOfTheWeek || 
                  _rarity == CardRarity.Icon)
                _buildBackgroundPattern(),
              
              // Shimmer effect
              if (_rarity == CardRarity.Special || 
                  _rarity == CardRarity.TeamOfTheWeek || 
                  _rarity == CardRarity.Icon)
                _buildShimmerEffect(),
              
              // Holographic effect for Icon cards
              if (_rarity == CardRarity.Icon)
                _buildHolographicEffect(),
              
              // Card border
              _buildCardBorder(),
              
              // Country flag for premium cards
              if (_rarity == CardRarity.TeamOfTheWeek || _rarity == CardRarity.Icon)
                _buildCountryFlag(),
              
              if (!widget.isExpanded) ...[
                _buildRatingBadge(),
                _buildPlayerImage(),
                _buildPlayerInfo(),
                _buildCardDetails(),
              ],
              
              if (widget.isExpanded)
                Positioned.fill(
                  top: 0,
                  child: AnimatedOpacity(
                    duration: AppTheme.mediumAnimation,
                    opacity: widget.isExpanded ? 1.0 : 0.0,
                    child: _buildExpandedContent(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackgroundPattern() {
    return Positioned.fill(
      child: CustomPaint(
        painter: CardPatternPainter(_rarity),
      ),
    );
  }

  Widget _buildShimmerEffect() {
    return AnimatedBuilder(
      animation: _shimmerAnimation,
      builder: (context, child) {
        return Positioned.fill(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24.0),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.transparent,
                    Colors.white.withOpacity(0.1),
                    Colors.white.withOpacity(0.3),
                    Colors.white.withOpacity(0.1),
                    Colors.transparent,
                  ],
                  stops: [
                    math.max(0.0, _shimmerAnimation.value - 0.3),
                    math.max(0.0, _shimmerAnimation.value - 0.15),
                    _shimmerAnimation.value,
                    math.min(1.0, _shimmerAnimation.value + 0.15),
                    math.min(1.0, _shimmerAnimation.value + 0.3),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHolographicEffect() {
    return AnimatedBuilder(
      animation: _shimmerAnimation,
      builder: (context, child) {
        return Positioned.fill(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24.0),
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(
                    _shimmerAnimation.value - 0.5,
                    math.sin(_shimmerAnimation.value * math.pi * 2) * 0.5,
                  ),
                  radius: 0.8,
                  colors: [
                    Colors.transparent,
                    Colors.white.withOpacity(0.1),
                    const Color(0xFFE94057).withOpacity(0.2),
                    const Color(0xFFF27121).withOpacity(0.15),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCardBorder() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24.0),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildCountryFlag() {
    // Placeholder for country flag - can be enhanced with real flag images
    return Positioned(
      top: 15,
      right: 15,
      child: Container(
        width: 30,
        height: 20,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.white, width: 1),
          gradient: LinearGradient(
            colors: [Colors.green.shade700, Colors.red.shade700],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        child: const Center(
          child: Text(
            'PT',
            style: TextStyle(
              color: Colors.white,
              fontSize: 8,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRatingBadge() {
    final rating = widget.goalkeeper.overallRating ?? 0;
    return Positioned(
      top: 15,
      left: 15,
      child: Container(
        width: 45,
        height: 45,
        decoration: BoxDecoration(
          color: _glowColor,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            rating.toString(),
            style: AppTheme.headingSmall.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerImage() {
    return Positioned(
      top: 70,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: CircleAvatar(
            radius: 50,
            backgroundImage: widget.goalkeeper.photoUrl != null
                ? NetworkImage(widget.goalkeeper.photoUrl!)
                : null,
            child: widget.goalkeeper.photoUrl == null
                ? const Icon(Icons.person, size: 50, color: Colors.white)
                : null,
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerInfo() {
    return Positioned(
      top: 180,
      left: 0,
      right: 0,
      child: Column(
        children: [
          Text(
            widget.goalkeeper.name,
            style: AppTheme.headingMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  color: Colors.black.withOpacity(0.7),
                  offset: const Offset(1, 1),
                  blurRadius: 3,
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: Text(
              'GK',
              style: AppTheme.bodyLarge.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardDetails() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withOpacity(0.4),
              Colors.black.withOpacity(0.8),
            ],
          ),
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(24.0),
            bottomRight: Radius.circular(24.0),
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatColumn(
                  'Rating', 
                  widget.goalkeeper.overallRating?.toString() ?? 'N/A',
                  Icons.star,
                ),
                _buildStatColumn(
                  'Value', 
                  widget.goalkeeper.displayPrice,
                  Icons.euro,
                ),
                _buildStatColumn(
                  'Age', 
                  widget.goalkeeper.age?.toString() ?? 'N/A',
                  Icons.calendar_today,
                ),
              ],
            ),
            if (widget.goalkeeper.inDemand == true)
              Container(
                margin: const EdgeInsets.only(top: 12.0),
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE94560), Color(0xFFFF6B6B)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFE94560).withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.local_fire_department, 
                        color: Colors.white, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'Em Destaque',
                      style: AppTheme.bodyMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String title, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: Colors.white70,
          size: 16,
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: AppTheme.bodySmall.copyWith(
            color: Colors.white70,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.25),
                Colors.white.withOpacity(0.15),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(0.4),
              width: 1,
            ),
          ),
          child: Text(
            value,
            style: AppTheme.bodyMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExpandedContent() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          children: [
            // Header with close indication
            _buildExpandedHeader(),
            const SizedBox(height: 8),
            
            // Player large image and name
            _buildExpandedPlayerInfo(),
            const SizedBox(height: 12),
            
            // Stats grid
            _buildExpandedStats(),
            const SizedBox(height: 12),
            
            // Additional info cards
            _buildExpandedInfoCards(),
            const SizedBox(height: 12),
            
            // Action button
            _buildExpandedActionButton(),
            const SizedBox(height: 16), // Bottom padding
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          width: 35,
          height: 35,
          decoration: BoxDecoration(
            color: _glowColor,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              (widget.goalkeeper.overallRating ?? 0).toString(),
              style: AppTheme.bodyMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.4),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.touch_app,
                color: Colors.white.withOpacity(0.8),
                size: 14,
              ),
              const SizedBox(width: 4),
              Text(
                'Toque para fechar',
                style: AppTheme.bodySmall.copyWith(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExpandedPlayerInfo() {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 4),
            boxShadow: [
              BoxShadow(
                color: _glowColor.withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: CircleAvatar(
            radius: 60,
            backgroundImage: widget.goalkeeper.photoUrl != null
                ? NetworkImage(widget.goalkeeper.photoUrl!)
                : null,
            child: widget.goalkeeper.photoUrl == null
                ? const Icon(Icons.person, size: 60, color: Colors.white)
                : null,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          widget.goalkeeper.name,
          style: AppTheme.headingMedium.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.7),
                offset: const Offset(1, 1),
                blurRadius: 3,
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.3)),
              ),
              child: Text(
                'GUARDA-REDES',
                style: AppTheme.bodyMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  fontSize: 12,
                ),
              ),
            ),
            if (widget.goalkeeper.inDemand == true) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE94560), Color(0xFFFF6B6B)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.local_fire_department, 
                        color: Colors.white, size: 12),
                    const SizedBox(width: 2),
                    Text(
                      'EM DESTAQUE',
                      style: AppTheme.bodySmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildExpandedStats() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.black.withOpacity(0.4),
            Colors.black.withOpacity(0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(
            'ESTATÍSTICAS',
            style: AppTheme.bodyMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildExpandedStatItem(
                'RATING',
                widget.goalkeeper.overallRating?.toString() ?? '0',
                Icons.star,
                _glowColor,
              ),
              _buildExpandedStatItem(
                'IDADE',
                widget.goalkeeper.age?.toString() ?? 'N/A',
                Icons.calendar_today,
                Colors.blue,
              ),
              _buildExpandedStatItem(
                'VALOR',
                widget.goalkeeper.displayPrice.replaceAll('€', ''),
                Icons.euro,
                Colors.green,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedStatItem(String title, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.8),
                color.withOpacity(0.6),
              ],
            ),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: AppTheme.bodyLarge.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          title,
          style: AppTheme.bodySmall.copyWith(
            color: Colors.white70,
            fontSize: 10,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildExpandedInfoCards() {
    return Column(
      children: [
        if (widget.goalkeeper.city != null)
          _buildExpandedInfoCard(
            Icons.location_on,
            'LOCALIZAÇÃO',
            widget.goalkeeper.displayLocation,
            Colors.red,
          ),
        if (widget.goalkeeper.club != null) ...[
          const SizedBox(height: 8),
          _buildExpandedInfoCard(
            Icons.sports,
            'CLUBE',
            widget.goalkeeper.displayClub,
            Colors.orange,
          ),
        ],
        if (widget.goalkeeper.nationality != null) ...[
          const SizedBox(height: 8),
          _buildExpandedInfoCard(
            Icons.flag,
            'NACIONALIDADE',
            widget.goalkeeper.nationality!,
            Colors.purple,
          ),
        ],
      ],
    );
  }

  Widget _buildExpandedInfoCard(IconData icon, String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Colors.black.withOpacity(0.3),
            Colors.black.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withOpacity(0.4)),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTheme.bodySmall.copyWith(
                    color: Colors.white70,
                    fontSize: 10,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTheme.bodyMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedActionButton() {
    return Container(
      width: double.infinity,
      height: 48,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            _glowColor,
            _glowColor.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _glowColor.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {
            // Navigate to booking or detailed view
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => GoalkeeperDetailsScreen(goalkeeper: widget.goalkeeper),
              ),
            );
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.calendar_today,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'AGENDAR JOGO',
                style: AppTheme.bodyMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CardPatternPainter extends CustomPainter {
  final CardRarity rarity;

  CardPatternPainter(this.rarity);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..style = PaintingStyle.fill;

    // Create subtle geometric patterns based on rarity
    switch (rarity) {
      case CardRarity.Icon:
        _drawIconPattern(canvas, size, paint);
        break;
      case CardRarity.TeamOfTheWeek:
        _drawTOTWPattern(canvas, size, paint);
        break;
      case CardRarity.Special:
        _drawSpecialPattern(canvas, size, paint);
        break;
      default:
        break;
    }
  }

  void _drawIconPattern(Canvas canvas, Size size, Paint paint) {
    // Draw diamond pattern for Icon cards
    for (int i = 0; i < 8; i++) {
      for (int j = 0; j < 12; j++) {
        final x = (i * size.width / 8) + (j % 2 * size.width / 16);
        final y = j * size.height / 12;
        
        final path = Path();
        path.moveTo(x, y - 10);
        path.lineTo(x + 10, y);
        path.lineTo(x, y + 10);
        path.lineTo(x - 10, y);
        path.close();
        
        canvas.drawPath(path, paint);
      }
    }
  }

  void _drawTOTWPattern(Canvas canvas, Size size, Paint paint) {
    // Draw hexagonal pattern for TOTW cards
    for (int i = 0; i < 6; i++) {
      for (int j = 0; j < 10; j++) {
        final x = (i * size.width / 6) + (j % 2 * size.width / 12);
        final y = j * size.height / 10;
        
        _drawHexagon(canvas, Offset(x, y), 8, paint);
      }
    }
  }

  void _drawSpecialPattern(Canvas canvas, Size size, Paint paint) {
    // Draw circular pattern for Special cards
    for (int i = 0; i < 10; i++) {
      for (int j = 0; j < 15; j++) {
        final x = (i * size.width / 10) + (j % 2 * size.width / 20);
        final y = j * size.height / 15;
        
        canvas.drawCircle(Offset(x, y), 3, paint);
      }
    }
  }

  void _drawHexagon(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (i * math.pi * 2) / 6;
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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

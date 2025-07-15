import 'package:flutter/material.dart';
import '../../../auth/presentation/theme/app_theme.dart';
import '../../../booking/data/models/booking.dart';
import '../screens/rating_screen.dart';

class RatingNotificationWidget extends StatefulWidget {
  final List<Booking> completedBookings;
  final Map<String, String> goalkeeperNames;
  final VoidCallback? onDismiss;

  const RatingNotificationWidget({
    super.key,
    required this.completedBookings,
    required this.goalkeeperNames,
    this.onDismiss,
  });

  @override
  State<RatingNotificationWidget> createState() => _RatingNotificationWidgetState();
}

class _RatingNotificationWidgetState extends State<RatingNotificationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: AppTheme.mediumAnimation,
      vsync: this,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(-1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _dismissNotification() {
    _animationController.reverse().then((_) {
      widget.onDismiss?.call();
    });
  }

  void _navigateToRating(Booking booking) {
    final goalkeeperName = widget.goalkeeperNames[booking.goalkeeperId] ?? 'Guarda-redes';
    
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => RatingScreen(
          booking: booking,
          goalkeeperName: goalkeeperName,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          );
        },
        transitionDuration: AppTheme.mediumAnimation,
      ),
    ).then((_) {
      // After rating, dismiss the notification
      _dismissNotification();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.completedBookings.isEmpty) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Container(
              margin: const EdgeInsets.all(AppTheme.spacing),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.accentColor.withOpacity(0.1),
                    AppTheme.accentColor.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                border: Border.all(
                  color: AppTheme.accentColor.withOpacity(0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.accentColor.withOpacity(0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.spacing),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header with close button
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: const BoxDecoration(
                              gradient: AppTheme.buttonGradient,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.star,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: AppTheme.spacing),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Avaliar Guarda-redes',
                                  style: AppTheme.bodyLarge.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.accentColor,
                                  ),
                                ),
                                Text(
                                  widget.completedBookings.length == 1
                                      ? 'Tem 1 jogo concluído para avaliar'
                                      : 'Tem ${widget.completedBookings.length} jogos concluídos para avaliar',
                                  style: AppTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: _dismissNotification,
                            icon: Icon(
                              Icons.close,
                              color: AppTheme.secondaryText,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: AppTheme.spacing),
                      
                      // List of completed bookings
                      ...widget.completedBookings.take(3).map((booking) => 
                        _buildBookingItem(booking)
                      ),
                      
                      // Show more indicator if there are more than 3
                      if (widget.completedBookings.length > 3) ...[
                        const SizedBox(height: 8),
                        Text(
                          '+${widget.completedBookings.length - 3} mais...',
                          style: AppTheme.bodyMedium.copyWith(
                            color: AppTheme.accentColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
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

  Widget _buildBookingItem(Booking booking) {
    final goalkeeperName = widget.goalkeeperNames[booking.goalkeeperId] ?? 'Guarda-redes';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => _navigateToRating(booking),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.primaryBackground.withOpacity(0.3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                Icons.sports_soccer,
                color: AppTheme.accentColor,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goalkeeperName,
                      style: AppTheme.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      booking.displayDateTime,
                      style: AppTheme.bodyMedium.copyWith(
                        fontSize: 12,
                        color: AppTheme.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.accentColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Avaliar',
                  style: AppTheme.bodyMedium.copyWith(
                    fontSize: 11,
                    color: AppTheme.accentColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Floating action button version for minimal UI impact
class RatingFloatingButton extends StatefulWidget {
  final List<Booking> completedBookings;
  final Map<String, String> goalkeeperNames;

  const RatingFloatingButton({
    super.key,
    required this.completedBookings,
    required this.goalkeeperNames,
  });

  @override
  State<RatingFloatingButton> createState() => _RatingFloatingButtonState();
}

class _RatingFloatingButtonState extends State<RatingFloatingButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _showRatingBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => RatingBottomSheet(
        completedBookings: widget.completedBookings,
        goalkeeperNames: widget.goalkeeperNames,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.completedBookings.isEmpty) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: FloatingActionButton(
            onPressed: _showRatingBottomSheet,
            backgroundColor: AppTheme.accentColor,
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Icon(
                  Icons.star,
                  color: Colors.white,
                  size: 24,
                ),
                if (widget.completedBookings.length > 1)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${widget.completedBookings.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Bottom sheet for selecting which booking to rate
class RatingBottomSheet extends StatelessWidget {
  final List<Booking> completedBookings;
  final Map<String, String> goalkeeperNames;

  const RatingBottomSheet({
    super.key,
    required this.completedBookings,
    required this.goalkeeperNames,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.secondaryText,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacingLarge),
            child: Text(
              'Selecione um jogo para avaliar',
              style: AppTheme.headingMedium,
            ),
          ),
          
          // Bookings list
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLarge),
              itemCount: completedBookings.length,
              itemBuilder: (context, index) {
                final booking = completedBookings[index];
                final goalkeeperName = goalkeeperNames[booking.goalkeeperId] ?? 'Guarda-redes';
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => RatingScreen(
                              booking: booking,
                              goalkeeperName: goalkeeperName,
                            ),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                      child: Container(
                        padding: const EdgeInsets.all(AppTheme.spacing),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.secondaryBackground.withOpacity(0.8),
                              AppTheme.secondaryBackground.withOpacity(0.4),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: const BoxDecoration(
                                gradient: AppTheme.buttonGradient,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.sports_soccer,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: AppTheme.spacing),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    goalkeeperName,
                                    style: AppTheme.bodyLarge.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    booking.displayDateTime,
                                    style: AppTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios,
                              color: AppTheme.accentColor,
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          
          const SizedBox(height: AppTheme.spacingLarge),
        ],
      ),
    );
  }
}

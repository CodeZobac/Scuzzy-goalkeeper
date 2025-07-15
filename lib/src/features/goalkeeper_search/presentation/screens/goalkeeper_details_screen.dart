import 'package:flutter/material.dart';
import '../../data/models/goalkeeper.dart';
import '../../../auth/presentation/theme/app_theme.dart';
import '../../../auth/presentation/widgets/primary_button.dart';
import '../../../booking/presentation/screens/booking_screen.dart';

class GoalkeeperDetailsScreen extends StatefulWidget {
  final Goalkeeper goalkeeper;

  const GoalkeeperDetailsScreen({
    super.key,
    required this.goalkeeper,
  });

  @override
  State<GoalkeeperDetailsScreen> createState() => _GoalkeeperDetailsScreenState();
}

class _GoalkeeperDetailsScreenState extends State<GoalkeeperDetailsScreen>
    with TickerProviderStateMixin {
  late AnimationController _headerAnimationController;
  late AnimationController _contentAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    _headerAnimationController = AnimationController(
      duration: AppTheme.mediumAnimation,
      vsync: this,
    );
    
    _contentAnimationController = AnimationController(
      duration: AppTheme.longAnimation,
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _headerAnimationController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _contentAnimationController,
      curve: Curves.easeOutCubic,
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _contentAnimationController,
      curve: Curves.easeOutBack,
    ));
    
    _headerAnimationController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _contentAnimationController.forward();
    });
  }

  @override
  void dispose() {
    _headerAnimationController.dispose();
    _contentAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBackground,
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.primaryGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: _buildContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return AnimatedBuilder(
      animation: _headerAnimationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingLarge),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(
                    Icons.arrow_back_ios,
                    color: AppTheme.primaryText,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.goalkeeper.name,
                    style: AppTheme.headingLarge,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent() {
    return AnimatedBuilder(
      animation: _contentAnimationController,
      builder: (context, child) {
        return SlideTransition(
          position: _slideAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLarge),
                child: Column(
                  children: [
                    _buildGoalkeeperCard(),
                    const SizedBox(height: AppTheme.spacingLarge),
                    _buildInfoCards(),
                    const Spacer(),
                    _buildBookingButton(),
                    const SizedBox(height: AppTheme.spacingLarge),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGoalkeeperCard() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingLarge),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.secondaryBackground.withOpacity(0.8),
            AppTheme.secondaryBackground.withOpacity(0.4),
          ],
        ),
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: AppTheme.buttonGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.accentColor.withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.sports_soccer,
              color: Colors.white,
              size: 60,
            ),
          ),
          const SizedBox(height: AppTheme.spacing),
          Text(
            widget.goalkeeper.name,
            style: AppTheme.headingMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            widget.goalkeeper.displayPrice,
            style: AppTheme.bodyLarge.copyWith(
              color: AppTheme.accentColor,
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCards() {
    return Column(
      children: [
        _buildInfoCard(
          icon: Icons.location_on,
          title: 'Localização',
          value: widget.goalkeeper.displayLocation,
        ),
        const SizedBox(height: AppTheme.spacing),
        _buildInfoCard(
          icon: Icons.sports,
          title: 'Clube',
          value: widget.goalkeeper.displayClub,
        ),
        if (widget.goalkeeper.age != null) ...[
          const SizedBox(height: AppTheme.spacing),
          _buildInfoCard(
            icon: Icons.cake,
            title: 'Idade',
            value: widget.goalkeeper.displayAge,
          ),
        ],
        if (widget.goalkeeper.nationality != null) ...[
          const SizedBox(height: AppTheme.spacing),
          _buildInfoCard(
            icon: Icons.flag,
            title: 'Nacionalidade',
            value: widget.goalkeeper.nationality!,
          ),
        ],
      ],
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            AppTheme.secondaryBackground.withOpacity(0.6),
            AppTheme.secondaryBackground.withOpacity(0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        border: Border.all(
          color: AppTheme.accentColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.accentColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: AppTheme.accentColor,
              size: 20,
            ),
          ),
          const SizedBox(width: AppTheme.spacing),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTheme.bodyMedium.copyWith(
                    fontSize: 12,
                    color: AppTheme.secondaryText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTheme.bodyLarge.copyWith(
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

  Widget _buildBookingButton() {
    return PrimaryButton(
      text: 'Agendar Jogo',
      icon: Icons.calendar_today,
      onPressed: () => _navigateToBooking(),
      width: double.infinity,
    );
  }

  void _navigateToBooking() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BookingScreen(goalkeeper: widget.goalkeeper),
      ),
    );
  }
}

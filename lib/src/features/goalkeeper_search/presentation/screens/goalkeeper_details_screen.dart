import 'package:flutter/material.dart';
import '../../data/models/goalkeeper.dart';
import '../../../auth/presentation/theme/app_theme.dart';
import '../../../auth/presentation/widgets/primary_button.dart';
import '../../../booking/presentation/screens/booking_screen.dart';

class GoalkeeperDetailsScreen extends StatelessWidget {
  final Goalkeeper goalkeeper;

  const GoalkeeperDetailsScreen({
    super.key,
    required this.goalkeeper,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLarge),
        child: Column(
          children: [
            _buildGoalkeeperCard(),
            const SizedBox(height: AppTheme.spacingLarge),
            _buildInfoCards(),
            _buildBookingButton(context),
            const SizedBox(height: AppTheme.spacingLarge),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalkeeperCard() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing),
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
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: AppTheme.buttonGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.accentColor.withOpacity(0.4),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(
              Icons.sports_soccer,
              color: Colors.white,
              size: 40,
            ),
          ),
          const SizedBox(height: AppTheme.spacing),
          Text(
            goalkeeper.name,
            style: AppTheme.headingSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            goalkeeper.displayPrice,
            style: AppTheme.bodyMedium.copyWith(
              color: AppTheme.accentColor,
              fontWeight: FontWeight.w600,
              fontSize: 16,
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
          value: goalkeeper.displayLocation,
        ),
        const SizedBox(height: AppTheme.spacing),
        _buildInfoCard(
          icon: Icons.sports,
          title: 'Clube',
          value: goalkeeper.displayClub,
        ),
        if (goalkeeper.age != null) ...[
          const SizedBox(height: AppTheme.spacing),
          _buildInfoCard(
            icon: Icons.cake,
            title: 'Idade',
            value: goalkeeper.displayAge,
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
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: AppTheme.accentColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: AppTheme.accentColor,
              size: 16,
            ),
          ),
          const SizedBox(width: AppTheme.spacing),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.secondaryText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTheme.bodyMedium.copyWith(
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

  Widget _buildBookingButton(BuildContext context) {
    return PrimaryButton(
      text: 'Agendar Jogo',
      icon: Icons.calendar_today,
      onPressed: () => _navigateToBooking(context),
      width: double.infinity,
    );
  }

  void _navigateToBooking(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BookingScreen(goalkeeper: goalkeeper),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../domain/models/map_field.dart';
import '../../../auth/presentation/theme/app_theme.dart';

class FieldDetailsCardNew extends StatelessWidget {
  final MapField field;
  final VoidCallback? onClose;

  const FieldDetailsCardNew({
    Key? key,
    required this.field,
    this.onClose,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.4,
      minChildSize: 0.2,
      maxChildSize: 0.8,
      builder: (_, controller) {
        return Container(
          decoration: BoxDecoration(
            color: AppTheme.secondaryBackground,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: ListView(
            controller: controller,
            children: [
              _buildHeader(),
              _buildDetails(),
              _buildUpcomingEvents(),
              _buildBookingSection(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          child: CachedNetworkImage(
            imageUrl: field.photoUrl ?? '',
            height: 200,
            width: double.infinity,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              height: 200,
              color: AppTheme.primaryBackground,
              child: const Center(
                child: CircularProgressIndicator(color: AppTheme.accentColor),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              height: 200,
              color: AppTheme.primaryBackground,
              child: const Icon(Icons.error, color: AppTheme.errorColor, size: 40),
            ),
          ),
        ),
        // Dark overlay for better text readability
        Container(
          height: 200,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.3),
                Colors.black.withOpacity(0.1),
              ],
            ),
          ),
        ),
        if (onClose != null)
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: onClose,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDetails() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            field.name,
            style: AppTheme.headingMedium.copyWith(
              color: AppTheme.primaryText,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 16),
              const SizedBox(width: 4),
              Text(
                '4.5',
                style: AppTheme.bodyMedium.copyWith(
                  color: AppTheme.primaryText,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '4291 Rogahn Terrace',
                style: AppTheme.bodyMedium.copyWith(
                  color: AppTheme.secondaryText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Modern football field, based on the football academy of the AC Milan. Open to everyone since 2017. Free amateur friday tournaments.',
            style: AppTheme.bodyMedium.copyWith(
              color: AppTheme.primaryText,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildTag('Natural Grass'),
              const SizedBox(width: 8),
              _buildTag('40x70m'),
              const SizedBox(width: 8),
              _buildTag('Outdoor'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.accentColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.accentColor.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: AppTheme.bodyMedium.copyWith(
          color: AppTheme.accentColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildUpcomingEvents() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Upcoming events (9)',
            style: AppTheme.headingMedium.copyWith(
              color: AppTheme.primaryText,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 16),
          _buildEventCard(),
        ],
      ),
    );
  }

  Widget _buildEventCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.primaryBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.accentColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.accentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text(
                    'NOV',
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.accentColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '25',
                    style: AppTheme.headingMedium.copyWith(
                      color: AppTheme.accentColor,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Friday Free Tournament',
                  style: AppTheme.bodyLarge.copyWith(
                    color: AppTheme.primaryText,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '12:30 pm - 4 slots - Beginners',
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.secondaryText,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingSection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '£24 / hour',
            style: AppTheme.headingMedium.copyWith(
              color: AppTheme.primaryText,
              fontSize: 18,
            ),
          ),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Availability',
                  style: AppTheme.buttonText,
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward, size: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

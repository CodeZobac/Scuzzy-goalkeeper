import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../domain/models/map_field.dart';
import '../../../auth/presentation/theme/app_theme.dart';
import '../../../../core/utils/guest_mode_utils.dart';
import '../../../../shared/widgets/registration_prompt_dialog.dart';
import '../../../../shared/helpers/registration_prompt_helper.dart';

class FieldDetailsCard extends StatelessWidget {
  final MapField field;
  final VoidCallback? onClose;

  const FieldDetailsCard({
    Key? key,
    required this.field,
    this.onClose,
  }) : super(key: key);

  void _handleAvailabilityPressed(BuildContext context) {
    // Check if user is in guest mode
    if (GuestModeUtils.isGuest) {
      // Show registration prompt for hiring goalkeeper
      RegistrationPromptHelper.showHireGoalkeeperPrompt(context);
    } else {
      // Handle authenticated user booking flow
      // TODO: Implement booking flow for authenticated users
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Booking functionality coming soon!'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.4,
      minChildSize: 0.2,
      maxChildSize: 0.8,
      builder: (_, controller) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10,
                offset: Offset(0, -2),
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
              color: Colors.grey[300],
            ),
            errorWidget: (context, url, error) => Container(
              height: 200,
              color: Colors.grey[300],
              child: const Icon(Icons.error, color: Colors.red),
            ),
          ),
        ),
        if (onClose != null)
          Positioned(
            top: 16,
            left: 16,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: onClose,
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
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 16),
              const SizedBox(width: 4),
              const Text(
                '4.5',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                field.city != null ? '${field.city}' : 'Localização não disponível',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            field.description ?? 'Descrição não disponível.',
            style: TextStyle(color: Colors.grey[800], height: 1.5),
          ),
          const SizedBox(height: 16),
            Row(
              children: [
                _buildTag(field.displaySurfaceType),
                const SizedBox(width: 8),
                _buildTag(field.dimensions ?? 'N/A'),
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
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
          color: Colors.black,
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
          const Text(
            'Upcoming events (9)',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          _buildEventCard(),
        ],
      ),
    );
  }

  Widget _buildEventCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Column(
                children: [
                  Text('NOV', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                  Text('25',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black)),
                ],
              ),
            ),
            const SizedBox(width: 16),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Friday Free Tournament',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                ),
                SizedBox(height: 4),
                Text('12:30 pm - 4 slots - Beginners', style: TextStyle(color: Colors.black)),
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
          const Text(
            '€24 / hour',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => _handleAvailabilityPressed(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Row(
                children: [
                  Text('Availability', style: TextStyle(color: Colors.black)),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward, size: 16, color: Colors.black),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

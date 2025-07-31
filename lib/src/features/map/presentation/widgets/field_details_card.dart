import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/map_field.dart';
import '../../../auth/presentation/theme/app_theme.dart';
import '../../../../core/utils/guest_mode_utils.dart';
import '../../../../shared/widgets/registration_prompt_dialog.dart';
import '../../../../shared/helpers/registration_prompt_helper.dart';
import '../../data/services/field_events_service.dart';
import '../screens/field_availability_screen.dart';

class FieldDetailsCard extends StatefulWidget {
  final MapField field;
  final VoidCallback? onClose;

  const FieldDetailsCard({
    Key? key,
    required this.field,
    this.onClose,
  }) : super(key: key);

  @override
  State<FieldDetailsCard> createState() => _FieldDetailsCardState();
}

class _FieldDetailsCardState extends State<FieldDetailsCard> {
  final FieldEventsService _eventsService = FieldEventsService(Supabase.instance.client);
  List<FieldEvent>? _upcomingEvents;
  bool _isLoadingEvents = true;

  @override
  void initState() {
    super.initState();
    _loadUpcomingEvents();
  }

  Future<void> _loadUpcomingEvents() async {
    try {
      final events = await _eventsService.getUpcomingEventsForField(widget.field.name);
      if (mounted) {
        setState(() {
          _upcomingEvents = events;
          _isLoadingEvents = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _upcomingEvents = [];
          _isLoadingEvents = false;
        });
      }
    }
  }

  void _handleAvailabilityPressed(BuildContext context) {
    // Check if user is in guest mode
    if (GuestModeUtils.isGuest) {
      // Show registration prompt for field booking
      RegistrationPromptHelper.showJoinMatchPrompt(context);
    } else {
      // Navigate to availability screen for authenticated users
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => FieldAvailabilityScreen(field: widget.field),
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
              if (_upcomingEvents != null && _upcomingEvents!.isNotEmpty)
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
            imageUrl: widget.field.photoUrl ?? '',
            height: 200,
            width: double.infinity,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              height: 200,
              color: AppTheme.authBackground,
              child: const Center(
                child: CircularProgressIndicator(
                  color: AppTheme.authPrimaryGreen,
                ),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              height: 200,
              decoration: const BoxDecoration(
                gradient: AppTheme.authPrimaryGradient,
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.sports_soccer,
                      color: Colors.white,
                      size: 40,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Sem imagem disponível',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (widget.onClose != null)
          Positioned(
            top: 16,
            left: 16,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: widget.onClose,
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
            widget.field.name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.authTextPrimary,
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
                  color: AppTheme.authTextPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                widget.field.address ?? 'Localização não disponível',
                style: const TextStyle(color: AppTheme.authTextSecondary),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            widget.field.description ?? 'Descrição não disponível.',
            style: const TextStyle(color: AppTheme.authTextSecondary, height: 1.5),
          ),
          const SizedBox(height: 16),
            Row(
              children: [
                _buildTag(widget.field.displaySurfaceType),
                const SizedBox(width: 8),
                _buildTag(widget.field.dimensions ?? 'N/A'),
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
        color: AppTheme.authPrimaryGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.authPrimaryGreen.withOpacity(0.3),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
          color: AppTheme.authPrimaryGreen,
        ),
      ),
    );
  }

  Widget _buildUpcomingEvents() {
    if (_isLoadingEvents) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(
          child: CircularProgressIndicator(
            color: AppTheme.authPrimaryGreen,
          ),
        ),
      );
    }

    if (_upcomingEvents == null || _upcomingEvents!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Próximos eventos (${_upcomingEvents!.length})',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.authTextPrimary,
            ),
          ),
          const SizedBox(height: 16),
          ..._upcomingEvents!.map((event) => _buildEventCard(event)).toList(),
        ],
      ),
    );
  }

  Widget _buildEventCard(FieldEvent event) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: AppTheme.authPrimaryGradient,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppTheme.authPrimaryGreen.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text(
                    event.formattedDate.split('\n')[0],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    event.formattedDate.split('\n')[1],
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    event.eventDetails,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  if (event.price != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '€${event.price!.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
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
            '€24 / hora',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.authTextPrimary,
            ),
          ),
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => _handleAvailabilityPressed(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.authPrimaryGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                elevation: 0,
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Disponibilidade',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward, size: 16, color: Colors.white),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

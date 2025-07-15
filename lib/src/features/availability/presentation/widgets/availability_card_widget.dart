import 'package:flutter/material.dart';
import '../../data/models/availability.dart';
import '../../../auth/presentation/theme/app_theme.dart';

class AvailabilityCardWidget extends StatefulWidget {
  final Availability availability;
  final VoidCallback onDelete;

  const AvailabilityCardWidget({
    super.key,
    required this.availability,
    required this.onDelete,
  });

  @override
  State<AvailabilityCardWidget> createState() => _AvailabilityCardWidgetState();
}

class _AvailabilityCardWidgetState extends State<AvailabilityCardWidget>
    with TickerProviderStateMixin {
  late AnimationController _hoverController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;

  @override
  void initState() {
    super.initState();
    
    _hoverController = AnimationController(
      duration: AppTheme.shortAnimation,
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(
      parent: _hoverController,
      curve: Curves.easeInOut,
    ));
    
    _elevationAnimation = Tween<double>(
      begin: 8.0,
      end: 16.0,
    ).animate(CurvedAnimation(
      parent: _hoverController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _hoverController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.secondaryBackground,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: _elevationAnimation.value,
                  offset: Offset(0, _elevationAnimation.value / 2),
                ),
                BoxShadow(
                  color: AppTheme.accentColor.withOpacity(0.05),
                  blurRadius: _elevationAnimation.value * 2,
                  offset: Offset(0, _elevationAnimation.value),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  _hoverController.forward().then((_) {
                    _hoverController.reverse();
                  });
                },
                onHover: (hovering) {
                  if (hovering) {
                    _hoverController.forward();
                  } else {
                    _hoverController.reverse();
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 16),
                      _buildContent(),
                      const SizedBox(height: 16),
                      _buildActions(),
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

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: AppTheme.buttonGradient,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.event_available,
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.availability.formattedDate,
                style: AppTheme.headingMedium.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _getRelativeDate(),
                style: AppTheme.bodyMedium.copyWith(
                  color: _getRelativeDateColor(),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryBackground.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.accentColor.withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.access_time,
            color: AppTheme.accentColor,
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(
            widget.availability.formattedTimeRange,
            style: AppTheme.bodyLarge.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.successColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _getDuration(),
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.successColor,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton.icon(
          onPressed: widget.onDelete,
          icon: Icon(
            Icons.delete_outline,
            size: 18,
            color: AppTheme.errorColor,
          ),
          label: Text(
            'Remover',
            style: AppTheme.bodyMedium.copyWith(
              color: AppTheme.errorColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          style: TextButton.styleFrom(
            foregroundColor: AppTheme.errorColor,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

  String _getRelativeDate() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final availabilityDate = DateTime(
      widget.availability.day.year,
      widget.availability.day.month,
      widget.availability.day.day,
    );
    
    final difference = availabilityDate.difference(today).inDays;
    
    if (difference == 0) {
      return 'Hoje';
    } else if (difference == 1) {
      return 'Amanhã';
    } else if (difference < 7) {
      return 'Em $difference dias';
    } else if (difference < 30) {
      final weeks = (difference / 7).floor();
      return weeks == 1 ? 'Em 1 semana' : 'Em $weeks semanas';
    } else {
      final months = (difference / 30).floor();
      return months == 1 ? 'Em 1 mês' : 'Em $months meses';
    }
  }

  Color _getRelativeDateColor() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final availabilityDate = DateTime(
      widget.availability.day.year,
      widget.availability.day.month,
      widget.availability.day.day,
    );
    
    final difference = availabilityDate.difference(today).inDays;
    
    if (difference == 0) {
      return AppTheme.successColor;
    } else if (difference <= 3) {
      return AppTheme.accentColor;
    } else {
      return AppTheme.secondaryText;
    }
  }

  String _getDuration() {
    final startMinutes = widget.availability.startTime.hour * 60 + widget.availability.startTime.minute;
    final endMinutes = widget.availability.endTime.hour * 60 + widget.availability.endTime.minute;
    final durationMinutes = endMinutes - startMinutes;
    
    final hours = durationMinutes ~/ 60;
    final minutes = durationMinutes % 60;
    
    if (hours == 0) {
      return '${minutes}min';
    } else if (minutes == 0) {
      return '${hours}h';
    } else {
      return '${hours}h ${minutes}min';
    }
  }
}

import 'package:flutter/material.dart';
import '../../../auth/presentation/theme/app_theme.dart';
import 'map_icon_marker.dart';

/// Enhanced field marker that uses SVG assets for better visual representation
class FieldMarker extends StatelessWidget {
  final bool isSelected;
  final bool isAvailable;
  final VoidCallback? onTap;
  final String? fieldStatus;
  final bool enablePulseAnimation;

  const FieldMarker({
    Key? key,
    this.isSelected = false,
    this.isAvailable = true,
    this.onTap,
    this.fieldStatus,
    this.enablePulseAnimation = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = _getPrimaryColor();
    final Widget? statusIndicator = _buildStatusIndicator();

    return MapIconMarker(
      svgAssetKey: 'football_field',
      isSelected: isSelected,
      isActive: isAvailable,
      size: 56,
      primaryColor: primaryColor,
      onTap: onTap,
      statusIndicator: statusIndicator,
      semanticsLabel: _buildSemanticLabel(),
      enablePulseAnimation: enablePulseAnimation,
      elevation: isSelected ? 6 : 4,
    );
  }

  Color _getPrimaryColor() {
    if (!isAvailable) {
      return const Color(0xFFE17055); // Red for unavailable
    }
    
    switch (fieldStatus) {
      case 'approved':
        return const Color(0xFF00C851); // Green for approved
      case 'pending':
        return const Color(0xFFFFBB33); // Orange for pending
      case 'rejected':
        return const Color(0xFFFF4444); // Red for rejected
      default:
        return isSelected 
            ? const Color(0xFF1E88E5) // Blue for selected
            : const Color(0xFF6C5CE7); // Purple for default
    }
  }

  Widget? _buildStatusIndicator() {
    if (!isAvailable) {
      return const MarkerStatusIndicator(
        color: Color(0xFFE17055),
        icon: Icons.block,
        size: 18,
      );
    }

    switch (fieldStatus) {
      case 'approved':
        return const MarkerStatusIndicator(
          color: Color(0xFF00C851),
          icon: Icons.check,
          size: 16,
        );
      case 'pending':
        return const MarkerStatusIndicator(
          color: Color(0xFFFFBB33),
          icon: Icons.schedule,
          size: 16,
        );
      case 'rejected':
        return const MarkerStatusIndicator(
          color: Color(0xFFFF4444),
          icon: Icons.close,
          size: 16,
        );
      default:
        return null;
    }
  }

  String _buildSemanticLabel() {
    final baseLabel = 'Football field marker';
    final statusLabel = isAvailable ? 'available' : 'unavailable';
    final selectionLabel = isSelected ? 'selected' : 'unselected';
    
    String fieldStatusLabel = '';
    if (fieldStatus != null) {
      fieldStatusLabel = ', status: $fieldStatus';
    }
    
    return '$baseLabel, $statusLabel, $selectionLabel$fieldStatusLabel';
  }
}

/// Legacy FieldMarker for backward compatibility
/// This maintains the original gradient-based design
class LegacyFieldMarker extends StatelessWidget {
  final bool isSelected;
  final bool isAvailable;

  const LegacyFieldMarker({
    Key? key,
    this.isSelected = false,
    this.isAvailable = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: isSelected ? 70 : 60,
      height: isSelected ? 70 : 60,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isSelected
              ? [const Color(0xFF1E88E5), const Color(0xFF42A5F5)]
              : isAvailable
                  ? [const Color(0xFF6C5CE7), const Color(0xFF74B9FF)]
                  : [const Color(0xFFE17055), const Color(0xFFD63031)],
        ),
        borderRadius: BorderRadius.circular(isSelected ? 20 : 16),
        boxShadow: [
          BoxShadow(
            color: (isSelected 
                ? const Color(0xFF1E88E5) 
                : const Color(0xFF6C5CE7))
                .withOpacity(0.4),
            blurRadius: isSelected ? 15 : 10,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: Colors.white.withOpacity(0.8),
          width: 3,
        ),
      ),
      child: Stack(
        children: [
          // Background pattern
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(isSelected ? 17 : 13),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.1),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          // Main stadium icon
          Center(
            child: Icon(
              Icons.stadium,
              color: Colors.white,
              size: isSelected ? 34 : 28,
              shadows: [
                Shadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
          // Status indicator
          if (!isAvailable)
            Positioned(
              top: 6,
              right: 6,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFE17055),
                    width: 1,
                  ),
                ),
              ),
            ),
          // Selection pulse effect
          if (isSelected)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(17),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.6),
                    width: 2,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

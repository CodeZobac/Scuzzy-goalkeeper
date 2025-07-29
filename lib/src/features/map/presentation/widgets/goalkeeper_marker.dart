import 'package:flutter/material.dart';
import 'map_icon_marker.dart';

/// Enhanced goalkeeper marker that uses SVG assets for better visual representation
class GoalkeeperMarker extends StatelessWidget {
  final bool isSelected;
  final bool isActive;
  final VoidCallback? onTap;
  final String? goalkeeperStatus;
  final bool enablePulseAnimation;
  final String? goalkeeperName;
  final int? experienceLevel;
  final double? rating;
  final bool isVerified;

  const GoalkeeperMarker({
    Key? key,
    this.isSelected = false,
    this.isActive = true,
    this.onTap,
    this.goalkeeperStatus,
    this.enablePulseAnimation = false,
    this.goalkeeperName,
    this.experienceLevel,
    this.rating,
    this.isVerified = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = _getPrimaryColor();
    final Widget? statusIndicator = _buildStatusIndicator();

    return MapIconMarker(
      svgAssetKey: 'goalkeeper',
      isSelected: isSelected,
      isActive: isActive,
      size: 52,
      primaryColor: primaryColor,
      onTap: onTap,
      statusIndicator: statusIndicator,
      semanticsLabel: _buildSemanticLabel(),
      enablePulseAnimation: enablePulseAnimation,
      elevation: isSelected ? 6 : 4,
    );
  }

  Color _getPrimaryColor() {
    if (!isActive) {
      return const Color(0xFF757575); // Darker grey for inactive for better contrast
    }
    
    // Color based on rating if available - improved contrast colors
    if (rating != null) {
      if (rating! >= 4.5) {
        return const Color(0xFFFF8F00); // Darker gold/amber for excellent rating
      } else if (rating! >= 4.0) {
        return const Color(0xFF1976D2); // Darker blue for good rating
      } else if (rating! >= 3.0) {
        return const Color(0xFF388E3C); // Darker green for average rating
      } else {
        return const Color(0xFFE65100); // Darker orange for low rating
      }
    }
    
    // Color based on experience level - improved contrast
    if (experienceLevel != null) {
      switch (experienceLevel!) {
        case 1:
        case 2:
          return const Color(0xFF2E7D32); // Darker green for beginner
        case 3:
        case 4:
          return const Color(0xFF1565C0); // Darker blue for intermediate
        case 5:
          return const Color(0xFF7B1FA2); // Darker purple for expert
        default:
          return const Color(0xFF2E7D32);
      }
    }
    
    switch (goalkeeperStatus) {
      case 'available':
        return const Color(0xFF2E7D32); // Darker green for available
      case 'busy':
        return const Color(0xFFE65100); // Darker orange for busy
      case 'in_game':
        return const Color(0xFFC2185B); // Darker pink for in game
      case 'offline':
        return const Color(0xFF424242); // Darker grey for offline
      default:
        return isSelected 
            ? const Color(0xFF1565C0) // Darker blue for selected
            : const Color(0xFF512DA8); // Darker purple for default
    }
  }

  Widget? _buildStatusIndicator() {
    if (!isActive) {
      return const MarkerStatusIndicator(
        color: Color(0xFF9E9E9E),
        icon: Icons.person_off,
        size: 18,
      );
    }

    // Show verified badge if verified
    if (isVerified) {
      return const MarkerStatusIndicator(
        color: Color(0xFF1976D2),
        icon: Icons.verified,
        size: 18,
      );
    }

    // Show rating indicator if available
    if (rating != null) {
      return MarkerStatusIndicator(
        color: _getRatingColor(),
        icon: _getRatingIcon(),
        size: 16,
      );
    }

    // Show experience level indicator
    if (experienceLevel != null) {
      return MarkerStatusIndicator(
        color: _getExperienceLevelColor(),
        size: 14,
      );
    }

    switch (goalkeeperStatus) {
      case 'available':
        return const MarkerStatusIndicator(
          color: Color(0xFF2E7D32),
          icon: Icons.check_circle,
          size: 16,
        );
      case 'busy':
        return const MarkerStatusIndicator(
          color: Color(0xFFE65100),
          icon: Icons.schedule,
          size: 16,
        );
      case 'in_game':
        return const MarkerStatusIndicator(
          color: Color(0xFFC2185B),
          icon: Icons.sports_soccer,
          size: 16,
        );
      case 'offline':
        return const MarkerStatusIndicator(
          color: Color(0xFF424242),
          icon: Icons.offline_bolt,
          size: 16,
        );
      default:
        return null;
    }
  }

  Color _getRatingColor() {
    if (rating == null) return const Color(0xFF2E7D32);
    
    if (rating! >= 4.5) {
      return const Color(0xFFFF8F00); // Darker gold/amber
    } else if (rating! >= 4.0) {
      return const Color(0xFF1976D2); // Darker blue
    } else if (rating! >= 3.0) {
      return const Color(0xFF388E3C); // Darker green
    } else {
      return const Color(0xFFE65100); // Darker orange
    }
  }

  IconData _getRatingIcon() {
    if (rating == null) return Icons.star;
    
    if (rating! >= 4.5) {
      return Icons.star;
    } else if (rating! >= 4.0) {
      return Icons.star_half;
    } else {
      return Icons.star_border;
    }
  }

  Color _getExperienceLevelColor() {
    if (experienceLevel == null) return const Color(0xFF2E7D32);
    
    switch (experienceLevel!) {
      case 1:
      case 2:
        return const Color(0xFF2E7D32); // Darker green for beginner
      case 3:
      case 4:
        return const Color(0xFF1565C0); // Darker blue for intermediate
      case 5:
        return const Color(0xFF7B1FA2); // Darker purple for expert
      default:
        return const Color(0xFF2E7D32);
    }
  }

  String _buildSemanticLabel() {
    final baseLabel = 'Goalkeeper marker';
    final statusLabel = isActive ? 'active' : 'inactive';
    final selectionLabel = isSelected ? 'selected' : 'unselected';
    
    String goalkeeperInfo = '';
    if (goalkeeperName != null) {
      goalkeeperInfo += ', goalkeeper: $goalkeeperName';
    }
    
    if (isVerified) {
      goalkeeperInfo += ', verified';
    }
    
    if (rating != null) {
      goalkeeperInfo += ', rating: ${rating!.toStringAsFixed(1)} stars';
    }
    
    if (experienceLevel != null) {
      final experienceText = _getExperienceLevelText();
      goalkeeperInfo += ', experience: $experienceText';
    }
    
    if (goalkeeperStatus != null) {
      goalkeeperInfo += ', status: $goalkeeperStatus';
    }
    
    return '$baseLabel, $statusLabel, $selectionLabel$goalkeeperInfo';
  }

  String _getExperienceLevelText() {
    if (experienceLevel == null) return 'unknown';
    
    switch (experienceLevel!) {
      case 1:
      case 2:
        return 'beginner';
      case 3:
      case 4:
        return 'intermediate';
      case 5:
        return 'expert';
      default:
        return 'unknown';
    }
  }
}

/// Specialized marker for showing goalkeeper availability in a specific area
class GoalkeeperAvailabilityMarker extends StatelessWidget {
  final int availableCount;
  final bool isSelected;
  final VoidCallback? onTap;
  final double? averageRating;

  const GoalkeeperAvailabilityMarker({
    Key? key,
    required this.availableCount,
    this.isSelected = false,
    this.onTap,
    this.averageRating,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = _getPrimaryColorByRating();
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              primaryColor.withOpacity(0.8),
              primaryColor,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withOpacity(0.4),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
          border: isSelected
              ? Border.all(color: Colors.white, width: 3)
              : null,
        ),
        child: Stack(
          children: [
            // Goalkeeper icon background
            Center(
              child: Icon(
                Icons.sports,
                color: Colors.white.withOpacity(0.3),
                size: 32,
              ),
            ),
            
            // Count indicator
            Center(
              child: Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    availableCount.toString(),
                    style: TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
            
            // Rating indicator
            if (averageRating != null)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.star,
                        size: 10,
                        color: _getPrimaryColorByRating(),
                      ),
                      Text(
                        averageRating!.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          color: _getPrimaryColorByRating(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getPrimaryColorByRating() {
    if (averageRating == null) return const Color(0xFF512DA8);
    
    if (averageRating! >= 4.5) {
      return const Color(0xFFFF8F00); // Darker gold/amber
    } else if (averageRating! >= 4.0) {
      return const Color(0xFF1976D2); // Darker blue
    } else if (averageRating! >= 3.0) {
      return const Color(0xFF388E3C); // Darker green
    } else {
      return const Color(0xFFE65100); // Darker orange
    }
  }
}
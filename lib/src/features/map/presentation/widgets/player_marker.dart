import 'package:flutter/material.dart';
import 'map_icon_marker.dart';

/// Enhanced player marker that uses SVG assets for better visual representation
class PlayerMarker extends StatelessWidget {
  final bool isSelected;
  final bool isActive;
  final VoidCallback? onTap;
  final String? playerStatus;
  final bool enablePulseAnimation;
  final String? playerName;
  final int? skillLevel;

  const PlayerMarker({
    Key? key,
    this.isSelected = false,
    this.isActive = true,
    this.onTap,
    this.playerStatus,
    this.enablePulseAnimation = false,
    this.playerName,
    this.skillLevel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = _getPrimaryColor();
    final Widget? statusIndicator = _buildStatusIndicator();

    return MapIconMarker(
      svgAssetKey: 'football_player',
      isSelected: isSelected,
      isActive: isActive,
      size: 48,
      primaryColor: primaryColor,
      onTap: onTap,
      statusIndicator: statusIndicator,
      semanticsLabel: _buildSemanticLabel(),
      enablePulseAnimation: enablePulseAnimation,
      elevation: isSelected ? 5 : 3,
    );
  }

  Color _getPrimaryColor() {
    if (!isActive) {
      return const Color(0xFF9E9E9E); // Grey for inactive
    }
    
    // Color based on skill level if available
    if (skillLevel != null) {
      switch (skillLevel!) {
        case 1:
        case 2:
          return const Color(0xFF4CAF50); // Green for beginner
        case 3:
        case 4:
          return const Color(0xFF2196F3); // Blue for intermediate
        case 5:
          return const Color(0xFF9C27B0); // Purple for advanced
        default:
          return const Color(0xFF4CAF50);
      }
    }
    
    switch (playerStatus) {
      case 'available':
        return const Color(0xFF4CAF50); // Green for available
      case 'busy':
        return const Color(0xFFFF9800); // Orange for busy
      case 'offline':
        return const Color(0xFF757575); // Grey for offline
      default:
        return isSelected 
            ? const Color(0xFF2196F3) // Blue for selected
            : const Color(0xFF4CAF50); // Green for default
    }
  }

  Widget? _buildStatusIndicator() {
    if (!isActive) {
      return const MarkerStatusIndicator(
        color: Color(0xFF9E9E9E),
        icon: Icons.person_off,
        size: 16,
      );
    }

    // Show skill level indicator if available
    if (skillLevel != null) {
      return MarkerStatusIndicator(
        color: _getSkillLevelColor(),
        size: 14,
      );
    }

    switch (playerStatus) {
      case 'available':
        return const MarkerStatusIndicator(
          color: Color(0xFF4CAF50),
          icon: Icons.check_circle,
          size: 16,
        );
      case 'busy':
        return const MarkerStatusIndicator(
          color: Color(0xFFFF9800),
          icon: Icons.schedule,
          size: 16,
        );
      case 'offline':
        return const MarkerStatusIndicator(
          color: Color(0xFF757575),
          icon: Icons.offline_bolt,
          size: 16,
        );
      default:
        return null;
    }
  }

  Color _getSkillLevelColor() {
    if (skillLevel == null) return const Color(0xFF4CAF50);
    
    switch (skillLevel!) {
      case 1:
      case 2:
        return const Color(0xFF4CAF50); // Green for beginner
      case 3:
      case 4:
        return const Color(0xFF2196F3); // Blue for intermediate
      case 5:
        return const Color(0xFF9C27B0); // Purple for advanced
      default:
        return const Color(0xFF4CAF50);
    }
  }

  String _buildSemanticLabel() {
    final baseLabel = 'Football player marker';
    final statusLabel = isActive ? 'active' : 'inactive';
    final selectionLabel = isSelected ? 'selected' : 'unselected';
    
    String playerInfo = '';
    if (playerName != null) {
      playerInfo += ', player: $playerName';
    }
    
    if (skillLevel != null) {
      final skillText = _getSkillLevelText();
      playerInfo += ', skill level: $skillText';
    }
    
    if (playerStatus != null) {
      playerInfo += ', status: $playerStatus';
    }
    
    return '$baseLabel, $statusLabel, $selectionLabel$playerInfo';
  }

  String _getSkillLevelText() {
    if (skillLevel == null) return 'unknown';
    
    switch (skillLevel!) {
      case 1:
      case 2:
        return 'beginner';
      case 3:
      case 4:
        return 'intermediate';
      case 5:
        return 'advanced';
      default:
        return 'unknown';
    }
  }
}

/// Specialized marker for showing multiple players in a cluster
class PlayerClusterMarker extends StatelessWidget {
  final int playerCount;
  final bool isSelected;
  final VoidCallback? onTap;
  final List<String>? playerNames;

  const PlayerClusterMarker({
    Key? key,
    required this.playerCount,
    this.isSelected = false,
    this.onTap,
    this.playerNames,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              const Color(0xFF4CAF50).withOpacity(0.8),
              const Color(0xFF4CAF50),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4CAF50).withOpacity(0.4),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
          border: isSelected
              ? Border.all(color: Colors.white, width: 3)
              : null,
        ),
        child: Stack(
          children: [
            // Background players
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person,
                  size: 12,
                  color: Color(0xFF4CAF50),
                ),
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person,
                  size: 12,
                  color: Color(0xFF4CAF50),
                ),
              ),
            ),
            
            // Count indicator
            Center(
              child: Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    playerCount.toString(),
                    style: const TextStyle(
                      color: Color(0xFF4CAF50),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
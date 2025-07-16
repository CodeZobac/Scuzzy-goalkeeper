import 'package:flutter/material.dart';
import '../../../auth/presentation/theme/app_theme.dart';

class FieldMarker extends StatelessWidget {
  final bool isSelected;
  final bool isAvailable;

  const FieldMarker({
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

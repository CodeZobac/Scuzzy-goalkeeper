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
      width: isSelected ? 60 : 50,
      height: isSelected ? 60 : 50,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isSelected
              ? [AppTheme.accentColor, AppTheme.successColor]
              : isAvailable
                  ? [AppTheme.accentColor, AppTheme.accentColor.withOpacity(0.8)]
                  : [AppTheme.errorColor, AppTheme.errorColor.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(isSelected ? 18 : 15),
        boxShadow: [
          BoxShadow(
            color: (isSelected ? AppTheme.accentColor : AppTheme.primaryBackground)
                .withOpacity(0.4),
            blurRadius: isSelected ? 12 : 8,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Stack(
        children: [
          // Main icon
          Center(
            child: Icon(
              Icons.sports_soccer,
              color: Colors.white,
              size: isSelected ? 28 : 24,
            ),
          ),
          // Status indicator
          if (!isAvailable)
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          // Selection indicator
          if (isSelected)
            Positioned(
              bottom: 4,
              right: 4,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.accentColor,
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

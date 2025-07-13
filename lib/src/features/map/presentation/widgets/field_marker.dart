import 'package:flutter/material.dart';
import '../../../auth/presentation/theme/app_theme.dart';

class FieldMarker extends StatelessWidget {
  final bool isSelected;
  final VoidCallback onTap;

  const FieldMarker({
    Key? key,
    this.isSelected = false,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppTheme.shortAnimation,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.accentColor : AppTheme.primaryBackground,
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
          border: Border.all(
            color: isSelected ? Colors.white : AppTheme.accentColor,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(
          Icons.sports_soccer,
          color: Colors.white,
          size: 12,
        ),
      ),
    );
  }
}

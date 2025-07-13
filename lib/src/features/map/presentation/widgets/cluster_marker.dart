import 'package:flutter/material.dart';
import '../../../auth/presentation/theme/app_theme.dart';

class ClusterMarker extends StatelessWidget {
  final int count;
  final VoidCallback onTap;

  const ClusterMarker({
    Key? key,
    required this.count,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppTheme.accentColor.withOpacity(0.8),
          border: Border.all(
            color: Colors.white,
            width: 2,
          ),
        ),
        child: Center(
          child: Text(
            count.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../../auth/presentation/theme/app_theme.dart';

class ClusterMarker extends StatelessWidget {
  final int count;
  final bool isActive;
  final bool isVisibleWhenZoomedOut;

  const ClusterMarker({
    Key? key,
    required this.count,
    this.isActive = false,
    this.isVisibleWhenZoomedOut = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!isVisibleWhenZoomedOut) {
      return const SizedBox.shrink();
    }
    
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: isActive 
            ? const Color(0xFFFF8C00) // Yellow-orange for active state
            : Colors.black.withOpacity(0.7), // Black with opacity for inactive
        shape: BoxShape.circle,
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
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}

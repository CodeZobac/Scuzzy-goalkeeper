import 'package:flutter/material.dart';
import '../../../../core/config/app_config.dart';

class GameDetailsRow extends StatelessWidget {
  final DateTime date;
  final TimeOfDay time;
  final double? price;
  final bool showLargeIcons;

  const GameDetailsRow({
    super.key,
    required this.date,
    required this.time,
    this.price,
    this.showLargeIcons = false,
  });

  @override
  Widget build(BuildContext context) {
    final iconSize = showLargeIcons ? 24.0 : 20.0;
    final textSize = showLargeIcons ? 16.0 : 12.0;
    
    return Row(
      children: [
        // Time
        _buildDetailItem(
          Icons.access_time,
          '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
          iconSize,
          textSize,
        ),
        SizedBox(width: showLargeIcons ? 24 : 16),
        
        // Date
        _buildDetailItem(
          Icons.calendar_today,
          _formatDate(date),
          iconSize,
          textSize,
        ),
        SizedBox(width: showLargeIcons ? 24 : 16),
        
        // Price
        _buildDetailItem(
          Icons.euro,
          price != null ? price!.toStringAsFixed(0) : 'Free',
          iconSize,
          textSize,
        ),
      ],
    );
  }

  Widget _buildDetailItem(IconData icon, String text, double iconSize, double textSize) {
    return Row(
      children: [
        Icon(
          icon,
          size: iconSize,
          color: const Color(0xFF757575),
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: textSize,
            color: const Color(0xFF757575),
            fontWeight: showLargeIcons ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDate = DateTime(date.year, date.month, date.day);
    
    if (targetDate == today) {
      return 'Today';
    } else if (targetDate == today.add(const Duration(days: 1))) {
      return 'Tomorrow';
    } else {
      return '${date.day}/${date.month}';
    }
  }
}

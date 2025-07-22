import 'package:flutter/material.dart';
import '../../../auth/presentation/theme/app_theme.dart';
import 'star_rating_widget.dart';

class StatRatingWidget extends StatelessWidget {
  final String title;
  final double rating;
  final ValueChanged<double> onRatingChanged;

  const StatRatingWidget({
    super.key,
    required this.title,
    required this.rating,
    required this.onRatingChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTheme.bodyLarge.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: AppTheme.spacing),
        Row(
          children: [
            Expanded(
              child: StarRatingWidget(
                rating: (rating / 20).round(),
                onRatingChanged: (newRating) {
                  onRatingChanged(newRating * 20.0);
                },
                size: 28,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

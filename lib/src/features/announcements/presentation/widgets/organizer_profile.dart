import 'package:flutter/material.dart';

class OrganizerProfile extends StatelessWidget {
  final String? name;
  final String? avatarUrl;
  final double? rating;
  final String? badge;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final double avatarSize;

  const OrganizerProfile({
    super.key,
    this.name,
    this.avatarUrl,
    this.rating,
    this.badge,
    this.showBackButton = false,
    this.onBackPressed,
    this.avatarSize = 40,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Back button (for detail screen)
        if (showBackButton) ...[
          IconButton(
            onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
            icon: const Icon(
              Icons.arrow_back,
              color: Color(0xFF2C2C2C),
            ),
          ),
          const SizedBox(width: 8),
        ],
        
        // Organizer avatar
        CircleAvatar(
          radius: avatarSize / 2,
          backgroundColor: const Color(0xFF4CAF50),
          backgroundImage: avatarUrl != null
              ? NetworkImage(avatarUrl!)
              : null,
          child: avatarUrl == null
              ? Icon(
                  Icons.person,
                  color: Colors.white,
                  size: avatarSize * 0.5,
                )
              : null,
        ),
        const SizedBox(width: 12),
        
        // Organizer info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name ?? 'Organizer',
                style: TextStyle(
                  fontSize: showBackButton ? 18 : 16,
                  fontWeight: showBackButton ? FontWeight.bold : FontWeight.w500,
                  color: const Color(0xFF2C2C2C),
                ),
              ),
              if (!showBackButton) // Show rating and badge only in card view
                Row(
                  children: [
                    // Rating stars
                    if (rating != null) ...[
                      _buildStarRating(rating!),
                      const SizedBox(width: 4),
                      Text(
                        rating!.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF757575),
                        ),
                      ),
                    ],
                    const Spacer(),
                    
                    // Badge (Solo, Organizer, etc.)
                    if (badge != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4CAF50),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          badge!,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              if (showBackButton) // Show organizer label in detail view
                const Text(
                  'Organizer',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF757575),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStarRating(double rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < rating.floor()
              ? Icons.star
              : (index < rating && rating % 1 >= 0.5)
                  ? Icons.star_half
                  : Icons.star_border,
          size: 16,
          color: const Color(0xFFFF9800),
        );
      }),
    );
  }
}
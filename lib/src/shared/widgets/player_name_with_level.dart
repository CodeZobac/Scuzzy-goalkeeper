import 'package:flutter/material.dart';
import 'package:goalkeeper/src/features/user_profile/data/models/user_profile.dart';

class PlayerNameWithLevel extends StatelessWidget {
  final UserProfile userProfile;

  const PlayerNameWithLevel({
    super.key,
    required this.userProfile,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (!userProfile.isGoalkeeper)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
              ),
            ),
            child: Text(
              'LVL ${userProfile.level}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            userProfile.name,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: [
                Shadow(
                  offset: Offset(0, 1),
                  blurRadius: 3,
                  color: Colors.black26,
                ),
              ],
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

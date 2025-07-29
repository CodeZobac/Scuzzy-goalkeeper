import 'package:flutter/material.dart';
import 'package:goalkeeper/src/features/announcements/data/models/announcement.dart';
import 'package:goalkeeper/src/features/announcements/presentation/widgets/game_details_row.dart';
import 'package:goalkeeper/src/features/announcements/presentation/widgets/organizer_profile.dart';

class AnnouncementCard extends StatelessWidget {
  final Announcement announcement;
  final VoidCallback onTap;

  const AnnouncementCard({
    super.key,
    required this.announcement,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Stadium info header
                Row(
                  children: [
                    // Stadium image
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: const Color(0xFF2C2C2C),
                      ),
                      child: const Icon(
                        Icons.sports_soccer,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    // Stadium info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            announcement.stadium ?? '#78 School Stadium',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2C2C2C),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${announcement.distanceKm?.toStringAsFixed(1) ?? '2'} km away',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF757575),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Participant indicator
                    if (announcement.participantCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF9800),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '+${announcement.participantCount}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Description
                Text(
                  announcement.description ?? 'Hello, we will play today at school Stadium. Some pro, some beginners. Welcome to us. Anyway we playing 4 times per week...',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF2C2C2C),
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                
                // Game details row (time, date, price)
                GameDetailsRow(
                  date: announcement.date,
                  time: announcement.time,
                  price: announcement.price,
                ),
                const SizedBox(height: 16),
                
                // Organizer section removed to maintain privacy
              ],
            ),
          ),
        ),
      ),
    );
  }
}
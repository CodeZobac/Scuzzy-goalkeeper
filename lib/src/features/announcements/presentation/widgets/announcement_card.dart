import 'package:flutter/material.dart';
import 'package:goalkeeper/src/features/announcements/data/models/announcement.dart';
import 'package:goalkeeper/src/features/announcements/presentation/widgets/stadium_image_card.dart';
import 'package:goalkeeper/src/features/announcements/presentation/widgets/game_details_row.dart';
import 'package:goalkeeper/src/features/announcements/presentation/widgets/organizer_profile.dart';
import 'package:goalkeeper/src/features/announcements/presentation/widgets/participant_avatar_row.dart';

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
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Stadium section with image and details
                StadiumImageCard(
                  stadiumName: announcement.stadium,
                  imageUrl: announcement.stadiumImageUrl,
                  distanceKm: announcement.distanceKm,
                  participantCount: announcement.participantCount > 0 ? announcement.participantCount : null,
                  height: 120,
                ),
                const SizedBox(height: 12),
                
                // Description
                if (announcement.description != null)
                  Text(
                    announcement.description!,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF757575),
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 12),
                
                // Game details row (time, date, price)
                GameDetailsRow(
                  date: announcement.date,
                  time: announcement.time,
                  price: announcement.price,
                ),
                const SizedBox(height: 16),
                
                // Organizer section
                OrganizerProfile(
                  name: announcement.organizerName,
                  avatarUrl: announcement.organizerAvatarUrl,
                  rating: announcement.organizerRating,
                  badge: 'Solo',
                ),
                const SizedBox(height: 12),
                
                // Participant avatars section
                ParticipantAvatarRow(
                  participants: announcement.participants,
                  participantCount: announcement.participantCount,
                  maxParticipants: announcement.maxParticipants,
                  maxVisible: 4,
                  onTap: onTap, // Allow tapping to view details
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
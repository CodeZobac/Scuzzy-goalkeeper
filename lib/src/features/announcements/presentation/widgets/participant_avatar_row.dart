import 'package:flutter/material.dart';
import '../../data/models/announcement.dart';

class ParticipantAvatarRow extends StatelessWidget {
  final List<AnnouncementParticipant> participants;
  final int participantCount;
  final int maxParticipants;
  final int maxVisible;
  final VoidCallback? onTap;

  const ParticipantAvatarRow({
    super.key,
    required this.participants,
    required this.participantCount,
    required this.maxParticipants,
    this.maxVisible = 4,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Handle empty participant states
    if (participantCount == 0) {
      return _buildEmptyState();
    }

    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          // Participant avatars with overlap
          _buildAvatarStack(),
          const SizedBox(width: 12),
          // Members label and count
          _buildParticipantInfo(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Row(
      children: [
        // Empty avatar placeholder
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: const Color(0xFFF0F0F0),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white,
              width: 2,
            ),
          ),
          child: const Icon(
            Icons.person_outline,
            size: 16,
            color: Color(0xFF757575),
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Members',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF757575),
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '(0/$maxParticipants)',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF2C2C2C),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAvatarStack() {
    final visibleParticipants = participants.take(maxVisible).toList();
    final remainingCount = participantCount - maxVisible;
    
    return SizedBox(
      width: _calculateStackWidth(visibleParticipants.length, remainingCount > 0),
      height: 32,
      child: Stack(
        children: [
          // Render visible participant avatars
          ...visibleParticipants.asMap().entries.map((entry) {
            final index = entry.key;
            final participant = entry.value;
            return Positioned(
              left: index * 20.0, // 20px overlap for each avatar
              child: _buildAvatar(
                avatarUrl: participant.avatarUrl,
                name: participant.name,
              ),
            );
          }),
          
          // Render "+X" indicator if there are more participants
          if (remainingCount > 0)
            Positioned(
              left: visibleParticipants.length * 20.0,
              child: _buildPlusIndicator(remainingCount),
            ),
        ],
      ),
    );
  }

  Widget _buildAvatar({String? avatarUrl, required String name}) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white,
          width: 2,
        ),
      ),
      child: ClipOval(
        child: avatarUrl != null && avatarUrl.isNotEmpty
            ? Image.network(
                avatarUrl,
                width: 32,
                height: 32,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildAvatarFallback(name);
                },
              )
            : _buildAvatarFallback(name),
      ),
    );
  }

  Widget _buildAvatarFallback(String name) {
    // Generate initials from name
    String initials = '';
    if (name.isNotEmpty) {
      final nameParts = name.trim().split(' ');
      if (nameParts.isNotEmpty) {
        initials = nameParts[0][0].toUpperCase();
        if (nameParts.length > 1) {
          initials += nameParts[1][0].toUpperCase();
        }
      }
    }
    
    return Container(
      width: 32,
      height: 32,
      decoration: const BoxDecoration(
        color: Color(0xFF4CAF50),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initials.isNotEmpty ? initials : '?',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildPlusIndicator(int count) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: const Color(0xFFFF9800),
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white,
          width: 2,
        ),
      ),
      child: Center(
        child: Text(
          '+$count',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildParticipantInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Members',
          style: TextStyle(
            fontSize: 12,
            color: Color(0xFF757575),
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          '($participantCount/$maxParticipants)',
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF2C2C2C),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  double _calculateStackWidth(int visibleCount, bool hasMore) {
    if (visibleCount == 0) return 32;
    
    // Base width for first avatar + overlap for additional avatars
    double width = 32 + ((visibleCount - 1) * 20);
    
    // Add space for "+X" indicator if needed
    if (hasMore) {
      width += 20; // Additional overlap for "+X" indicator
    }
    
    return width;
  }
}
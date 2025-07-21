import 'package:flutter/material.dart';
import 'package:goalkeeper/src/features/notifications/data/models/models.dart';
import 'notification_action_buttons.dart';

class FullLobbyNotificationCard extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onViewDetails;
  final VoidCallback onTap;
  final bool isLoading;

  const FullLobbyNotificationCard({
    super.key,
    required this.notification,
    required this.onViewDetails,
    required this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final fullLobbyData = notification.fullLobbyData;
    if (fullLobbyData == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
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
                // Header with celebration icon and full lobby indicator
                Row(
                  children: [
                    // Celebration icon
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: const LinearGradient(
                          colors: <Color>[Color(0xFF4CAF50), Color(0xFF45A049)],
                        ),
                      ),
                      child: const Icon(
                        Icons.celebration,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    // Full lobby info
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Lobby Completo!',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2C2C2C),
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Seu anúncio atingiu a capacidade máxima',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF757575),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Unread indicator
                    if (notification.isUnread)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFF9800),
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Announcement title
                Text(
                  fullLobbyData.announcementTitle,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF2C2C2C),
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                
                // Participant count display
                _buildParticipantCountSection(fullLobbyData),
                const SizedBox(height: 16),
                
                // Game details row (time, date, location)
                _buildGameDetailsRow(fullLobbyData),
                const SizedBox(height: 16),
                
                // Action button
                _buildActionButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildParticipantCountSection(FullLobbyNotificationData fullLobbyData) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.group,
            size: 16,
            color: Color(0xFF4CAF50),
          ),
          const SizedBox(width: 4),
          Text(
            fullLobbyData.participantCountDisplay,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF4CAF50),
            ),
          ),
          const SizedBox(width: 8),
          const Icon(
            Icons.check_circle,
            size: 16,
            color: Color(0xFF4CAF50),
          ),
        ],
      ),
    );
  }

  Widget _buildGameDetailsRow(FullLobbyNotificationData fullLobbyData) {
    final time = TimeOfDay.fromDateTime(fullLobbyData.gameDateTime);
    
    return Row(
      children: [
        // Time
        _buildDetailItem(
          Icons.access_time,
          '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
        ),
        const SizedBox(width: 16),
        
        // Date
        _buildDetailItem(
          Icons.calendar_today,
          _formatDate(fullLobbyData.gameDateTime),
        ),
        const SizedBox(width: 16),
        
        // Location
        Expanded(
          child: _buildDetailItem(
            Icons.location_on,
            fullLobbyData.stadium,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 20,
          color: const Color(0xFF757575),
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF757575),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton() {
    return NotificationActionButtons(
      isLoading: isLoading,
      loadingText: 'Carregando...',
      actions: [
        NotificationAction(
          text: 'Ver Detalhes',
          onPressed: onViewDetails,
          type: NotificationActionType.viewDetails,
          isEnabled: !isLoading,
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDate = DateTime(date.year, date.month, date.day);
    
    if (targetDate == today) {
      return 'Hoje';
    } else if (targetDate == today.add(const Duration(days: 1))) {
      return 'Amanhã';
    } else {
      return '${date.day}/${date.month}';
    }
  }
}
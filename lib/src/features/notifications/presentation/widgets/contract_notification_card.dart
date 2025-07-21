import 'package:flutter/material.dart';
import 'package:goalkeeper/src/features/notifications/data/models/models.dart';
import 'notification_action_buttons.dart';

class ContractNotificationCard extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  final VoidCallback onTap;
  final bool isLoading;

  const ContractNotificationCard({
    super.key,
    required this.notification,
    required this.onAccept,
    required this.onDecline,
    required this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final contractData = notification.contractData;
    if (contractData == null) {
      return const SizedBox.shrink();
    }

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
                // Contractor profile header
                Row(
                  children: [
                    // Contractor avatar
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: const Color(0xFF2C2C2C),
                      ),
                      child: contractData.contractorAvatarUrl != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                contractData.contractorAvatarUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(
                                  Icons.person,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                            )
                          : const Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 24,
                            ),
                    ),
                    const SizedBox(width: 12),
                    
                    // Contractor info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            contractData.contractorName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2C2C2C),
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'quer contratá-lo para um jogo',
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
                const SizedBox(width: 16),
                
                // Announcement title
                Text(
                  contractData.announcementTitle,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF2C2C2C),
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                
                // Game details row (time, date, location)
                _buildGameDetailsRow(contractData),
                
                // Offered amount section
                if (contractData.offeredAmount != null) ...[
                  const SizedBox(height: 16),
                  _buildOfferedAmountSection(contractData.offeredAmount!),
                ],
                
                // Additional notes
                if (contractData.additionalNotes != null && 
                    contractData.additionalNotes!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    contractData.additionalNotes!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF757575),
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                
                const SizedBox(height: 16),
                
                // Action buttons
                _buildActionButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGameDetailsRow(ContractNotificationData contractData) {
    final time = TimeOfDay.fromDateTime(contractData.gameDateTime);
    
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
          _formatDate(contractData.gameDateTime),
        ),
        const SizedBox(width: 16),
        
        // Location
        Expanded(
          child: _buildDetailItem(
            Icons.location_on,
            contractData.stadium,
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

  Widget _buildOfferedAmountSection(double amount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF00A85A).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.attach_money,
            size: 16,
            color: Color(0xFF00A85A),
          ),
          const SizedBox(width: 4),
          Text(
            'R\$ ${amount.toStringAsFixed(0)}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF00A85A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return NotificationActionButtons(
      isLoading: isLoading,
      loadingText: 'Processando...',
      actions: [
        NotificationAction(
          text: 'Recusar',
          onPressed: onDecline,
          type: NotificationActionType.decline,
          isEnabled: !isLoading,
        ),
        NotificationAction(
          text: 'Aceitar',
          onPressed: onAccept,
          type: NotificationActionType.accept,
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
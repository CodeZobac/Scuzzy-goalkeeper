import 'package:flutter/material.dart';
import 'notification_action_buttons.dart';

/// Example usage of NotificationActionButtons component
class NotificationActionButtonsExample extends StatefulWidget {
  const NotificationActionButtonsExample({super.key});

  @override
  State<NotificationActionButtonsExample> createState() => _NotificationActionButtonsExampleState();
}

class _NotificationActionButtonsExampleState extends State<NotificationActionButtonsExample> {
  bool _isLoading = false;

  void _handleAccept() {
    setState(() => _isLoading = true);
    
    // Simulate API call
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contrato aceito!')),
        );
      }
    });
  }

  void _handleDecline() {
    setState(() => _isLoading = true);
    
    // Simulate API call
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contrato recusado!')),
        );
      }
    });
  }

  void _handleViewDetails() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Navegando para detalhes...')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NotificationActionButtons Examples'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Contract Notification Actions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            // Contract notification actions (Accept/Decline)
            NotificationActionButtons(
              isLoading: _isLoading,
              loadingText: 'Processando...',
              actions: [
                NotificationAction(
                  text: 'Recusar',
                  onPressed: _handleDecline,
                  type: NotificationActionType.decline,
                  isEnabled: !_isLoading,
                ),
                NotificationAction(
                  text: 'Aceitar',
                  onPressed: _handleAccept,
                  type: NotificationActionType.accept,
                  isEnabled: !_isLoading,
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            const Text(
              'Full Lobby Notification Action',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            // Full lobby notification action (View Details)
            NotificationActionButtons(
              actions: [
                NotificationAction(
                  text: 'Ver Detalhes',
                  onPressed: _handleViewDetails,
                  type: NotificationActionType.viewDetails,
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            const Text(
              'Custom Action',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            // Custom action button
            NotificationActionButtons(
              actions: [
                NotificationAction(
                  text: 'Ação Personalizada',
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Ação personalizada executada!')),
                    );
                  },
                  type: NotificationActionType.custom,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
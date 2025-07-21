import 'package:flutter/material.dart';

enum NotificationCategory {
  contracts('Contratos', Icons.handshake),
  fullLobbies('Lobbies Completos', Icons.group),
  general('Geral', Icons.notifications);

  const NotificationCategory(this.title, this.icon);
  final String title;
  final IconData icon;

  static NotificationCategory fromString(String value) {
    switch (value) {
      case 'contracts':
        return NotificationCategory.contracts;
      case 'full_lobbies':
        return NotificationCategory.fullLobbies;
      case 'general':
      default:
        return NotificationCategory.general;
    }
  }

  String get value {
    switch (this) {
      case NotificationCategory.contracts:
        return 'contracts';
      case NotificationCategory.fullLobbies:
        return 'full_lobbies';
      case NotificationCategory.general:
        return 'general';
    }
  }
}
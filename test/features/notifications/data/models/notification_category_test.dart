import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goalkeeper/src/features/notifications/data/models/notification_category.dart';

void main() {
  group('NotificationCategory', () {
    test('should have correct titles and icons', () {
      expect(NotificationCategory.contracts.title, 'Contratos');
      expect(NotificationCategory.contracts.icon, Icons.handshake);

      expect(NotificationCategory.fullLobbies.title, 'Lobbies Completos');
      expect(NotificationCategory.fullLobbies.icon, Icons.group);

      expect(NotificationCategory.general.title, 'Geral');
      expect(NotificationCategory.general.icon, Icons.notifications);
    });

    test('should convert from string correctly', () {
      expect(NotificationCategory.fromString('contracts'), NotificationCategory.contracts);
      expect(NotificationCategory.fromString('full_lobbies'), NotificationCategory.fullLobbies);
      expect(NotificationCategory.fromString('general'), NotificationCategory.general);
      expect(NotificationCategory.fromString('invalid'), NotificationCategory.general);
      expect(NotificationCategory.fromString(''), NotificationCategory.general);
    });

    test('should convert to string value correctly', () {
      expect(NotificationCategory.contracts.value, 'contracts');
      expect(NotificationCategory.fullLobbies.value, 'full_lobbies');
      expect(NotificationCategory.general.value, 'general');
    });

    test('should handle round-trip conversion', () {
      for (final category in NotificationCategory.values) {
        final stringValue = category.value;
        final convertedBack = NotificationCategory.fromString(stringValue);
        expect(convertedBack, category);
      }
    });
  });
}
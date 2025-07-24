import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goalkeeper/src/features/notifications/data/models/notification_category.dart';

void main() {
  group('NotificationCategory', () {
    test('should have correct enum values', () {
      expect(NotificationCategory.values, hasLength(3));
      expect(NotificationCategory.values, contains(NotificationCategory.contracts));
      expect(NotificationCategory.values, contains(NotificationCategory.fullLobbies));
      expect(NotificationCategory.values, contains(NotificationCategory.general));
    });

    test('should have correct titles', () {
      expect(NotificationCategory.contracts.title, equals('Contratos'));
      expect(NotificationCategory.fullLobbies.title, equals('Lobbies Completos'));
      expect(NotificationCategory.general.title, equals('Geral'));
    });

    test('should have correct icons', () {
      expect(NotificationCategory.contracts.icon, equals(Icons.handshake));
      expect(NotificationCategory.fullLobbies.icon, equals(Icons.group));
      expect(NotificationCategory.general.icon, equals(Icons.notifications));
    });

    test('should convert from notification type correctly', () {
      expect(NotificationCategory.fromNotificationType('contract_request'), 
             equals(NotificationCategory.contracts));
      expect(NotificationCategory.fromNotificationType('full_lobby'), 
             equals(NotificationCategory.fullLobbies));
      expect(NotificationCategory.fromNotificationType('general'), 
             equals(NotificationCategory.general));
      expect(NotificationCategory.fromNotificationType('unknown'), 
             equals(NotificationCategory.general));
    });

    test('should have correct name property', () {
      expect(NotificationCategory.contracts.name, equals('contracts'));
      expect(NotificationCategory.fullLobbies.name, equals('fullLobbies'));
      expect(NotificationCategory.general.name, equals('general'));
    });

    test('should support equality comparison', () {
      expect(NotificationCategory.contracts, equals(NotificationCategory.contracts));
      expect(NotificationCategory.contracts, isNot(equals(NotificationCategory.fullLobbies)));
    });

    test('should support switch statements', () {
      String getDescription(NotificationCategory category) {
        switch (category) {
          case NotificationCategory.contracts:
            return 'Contract notifications';
          case NotificationCategory.fullLobbies:
            return 'Full lobby notifications';
          case NotificationCategory.general:
            return 'General notifications';
        }
      }

      expect(getDescription(NotificationCategory.contracts), equals('Contract notifications'));
      expect(getDescription(NotificationCategory.fullLobbies), equals('Full lobby notifications'));
      expect(getDescription(NotificationCategory.general), equals('General notifications'));
    });

    test('should be serializable', () {
      final category = NotificationCategory.contracts;
      final serialized = category.toString();
      
      expect(serialized, contains('contracts'));
    });

    test('should have consistent ordering', () {
      final categories = NotificationCategory.values;
      
      expect(categories[0], equals(NotificationCategory.contracts));
      expect(categories[1], equals(NotificationCategory.fullLobbies));
      expect(categories[2], equals(NotificationCategory.general));
    });

    group('Category filtering', () {
      test('should filter contract notifications correctly', () {
        const notificationTypes = ['contract_request', 'full_lobby', 'general', 'unknown'];
        
        final contractTypes = notificationTypes
            .where((type) => NotificationCategory.fromNotificationType(type) == NotificationCategory.contracts)
            .toList();
            
        expect(contractTypes, equals(['contract_request']));
      });

      test('should filter full lobby notifications correctly', () {
        const notificationTypes = ['contract_request', 'full_lobby', 'general', 'unknown'];
        
        final lobbyTypes = notificationTypes
            .where((type) => NotificationCategory.fromNotificationType(type) == NotificationCategory.fullLobbies)
            .toList();
            
        expect(lobbyTypes, equals(['full_lobby']));
      });

      test('should filter general notifications correctly', () {
        const notificationTypes = ['contract_request', 'full_lobby', 'general', 'unknown'];
        
        final generalTypes = notificationTypes
            .where((type) => NotificationCategory.fromNotificationType(type) == NotificationCategory.general)
            .toList();
            
        expect(generalTypes, equals(['general', 'unknown']));
      });
    });

    group('UI Integration', () {
      test('should provide tab data for UI', () {
        final tabData = NotificationCategory.values.map((category) => {
          'title': category.title,
          'icon': category.icon,
          'category': category,
        }).toList();

        expect(tabData, hasLength(3));
        expect(tabData[0]['title'], equals('Contratos'));
        expect(tabData[0]['icon'], equals(Icons.handshake));
        expect(tabData[0]['category'], equals(NotificationCategory.contracts));
      });

      test('should support badge count display', () {
        final categories = NotificationCategory.values;
        final mockCounts = {
          NotificationCategory.contracts: 5,
          NotificationCategory.fullLobbies: 2,
          NotificationCategory.general: 0,
        };

        for (final category in categories) {
          final count = mockCounts[category] ?? 0;
          expect(count, isA<int>());
          expect(count, greaterThanOrEqualTo(0));
        }
      });
    });

    group('Localization Support', () {
      test('should support title localization', () {
        // This test demonstrates how titles could be localized
        final localizedTitles = {
          NotificationCategory.contracts: {
            'pt': 'Contratos',
            'en': 'Contracts',
            'es': 'Contratos',
          },
          NotificationCategory.fullLobbies: {
            'pt': 'Lobbies Completos',
            'en': 'Full Lobbies',
            'es': 'Lobbies Completos',
          },
          NotificationCategory.general: {
            'pt': 'Geral',
            'en': 'General',
            'es': 'General',
          },
        };

        expect(localizedTitles[NotificationCategory.contracts]!['pt'], equals('Contratos'));
        expect(localizedTitles[NotificationCategory.contracts]!['en'], equals('Contracts'));
      });
    });
  });
}
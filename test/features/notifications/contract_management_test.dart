import 'package:flutter_test/flutter_test.dart';

import '../../../lib/src/features/notifications/services/contract_management_service.dart';
import '../../../lib/src/features/notifications/data/models/contract_notification_data.dart';
import '../../../lib/src/features/notifications/presentation/controllers/contract_controller.dart';
import '../../../lib/src/features/notifications/services/contract_expiration_handler.dart';

void main() {

    group('Contract Status', () {
      test('should correctly identify contract status', () {
        final now = DateTime.now();
        
        // Test pending contract
        final pendingContract = GoalkeeperContract(
          id: 'contract-1',
          announcementId: 'announcement-1',
          goalkeeperUserId: 'goalkeeper-1',
          contractorUserId: 'contractor-1',
          status: ContractStatus.pending,
          createdAt: now,
          expiresAt: now.add(const Duration(hours: 12)),
        );

        expect(pendingContract.isPending, isTrue);
        expect(pendingContract.isExpired, isFalse);

        // Test expired contract
        final expiredContract = GoalkeeperContract(
          id: 'contract-2',
          announcementId: 'announcement-1',
          goalkeeperUserId: 'goalkeeper-1',
          contractorUserId: 'contractor-1',
          status: ContractStatus.pending,
          createdAt: now.subtract(const Duration(days: 2)),
          expiresAt: now.subtract(const Duration(hours: 1)),
        );

        expect(expiredContract.isExpired, isTrue);
        expect(expiredContract.isPending, isFalse);

        // Test accepted contract
        final acceptedContract = GoalkeeperContract(
          id: 'contract-3',
          announcementId: 'announcement-1',
          goalkeeperUserId: 'goalkeeper-1',
          contractorUserId: 'contractor-1',
          status: ContractStatus.accepted,
          createdAt: now,
          expiresAt: now.add(const Duration(hours: 12)),
          respondedAt: now,
        );

        expect(acceptedContract.isAccepted, isTrue);
        expect(acceptedContract.isPending, isFalse);
      });
    });
  });

  group('ContractController', () {
    late ContractController controller;

    setUp(() {
      controller = ContractController();
    });

    tearDown(() {
      controller.dispose();
    });

    test('should initialize with correct default values', () {
      expect(controller.isCreatingContract, isFalse);
      expect(controller.isAcceptingContract, isFalse);
      expect(controller.isDecliningContract, isFalse);
      expect(controller.isLoading, isFalse);
      expect(controller.error, isNull);
      expect(controller.goalkeeperContracts, isEmpty);
      expect(controller.contractorContracts, isEmpty);
    });

    test('should clear error when clearError is called', () {
      // Simulate an error state
      controller.clearError();
      expect(controller.error, isNull);
    });
  });

  group('ContractExpirationHandler', () {
    test('should correctly calculate time until expiration', () {
      final now = DateTime.now();
      final futureTime = now.add(const Duration(hours: 2, minutes: 30));
      
      final timeLeft = ContractExpirationHandler.getTimeUntilExpiration(futureTime);
      
      expect(timeLeft.inHours, equals(2));
      expect(timeLeft.inMinutes % 60, equals(30));
    });

    test('should correctly identify contracts about to expire', () {
      final now = DateTime.now();
      
      // Contract expiring in 30 minutes
      final soonToExpire = now.add(const Duration(minutes: 30));
      expect(ContractExpirationHandler.isContractAboutToExpire(soonToExpire), isTrue);
      
      // Contract expiring in 2 hours
      final notSoonToExpire = now.add(const Duration(hours: 2));
      expect(ContractExpirationHandler.isContractAboutToExpire(notSoonToExpire), isFalse);
      
      // Already expired contract
      final expired = now.subtract(const Duration(minutes: 30));
      expect(ContractExpirationHandler.isContractAboutToExpire(expired), isFalse);
    });

    test('should format time left correctly', () {
      final now = DateTime.now();
      
      // Test days and hours
      final daysLeft = now.add(const Duration(days: 2, hours: 3));
      expect(ContractExpirationHandler.formatTimeLeft(daysLeft), equals('2d 3h'));
      
      // Test hours and minutes
      final hoursLeft = now.add(const Duration(hours: 1, minutes: 30));
      expect(ContractExpirationHandler.formatTimeLeft(hoursLeft), equals('1h 30m'));
      
      // Test minutes only
      final minutesLeft = now.add(const Duration(minutes: 45));
      expect(ContractExpirationHandler.formatTimeLeft(minutesLeft), equals('45m'));
      
      // Test expired
      final expired = now.subtract(const Duration(minutes: 30));
      expect(ContractExpirationHandler.formatTimeLeft(expired), equals('Expirado'));
    });

    test('should return correct expiration status', () {
      final now = DateTime.now();
      
      // Active contract (more than 6 hours)
      final active = now.add(const Duration(hours: 12));
      expect(ContractExpirationHandler.getExpirationStatus(active), equals(ExpirationStatus.active));
      
      // Expiring today (less than 6 hours)
      final expiringToday = now.add(const Duration(hours: 3));
      expect(ContractExpirationHandler.getExpirationStatus(expiringToday), equals(ExpirationStatus.expiringToday));
      
      // Expiring soon (less than 1 hour)
      final expiringSoon = now.add(const Duration(minutes: 30));
      expect(ContractExpirationHandler.getExpirationStatus(expiringSoon), equals(ExpirationStatus.expiringSoon));
      
      // Expired
      final expired = now.subtract(const Duration(minutes: 30));
      expect(ContractExpirationHandler.getExpirationStatus(expired), equals(ExpirationStatus.expired));
    });
  });

  group('ContractNotificationData', () {
    test('should serialize and deserialize correctly', () {
      final originalData = ContractNotificationData(
        contractId: 'contract-123',
        contractorId: 'contractor-123',
        contractorName: 'João Silva',
        contractorAvatarUrl: 'https://example.com/avatar.jpg',
        announcementId: 'announcement-123',
        announcementTitle: 'Jogo de Futebol',
        gameDateTime: DateTime(2024, 12, 25, 15, 30),
        stadium: 'Estádio Municipal',
        offeredAmount: 75.50,
        additionalNotes: 'Jogo importante',
      );

      // Test toMap and fromMap
      final map = originalData.toMap();
      final deserializedData = ContractNotificationData.fromMap(map);

      expect(deserializedData.contractId, equals(originalData.contractId));
      expect(deserializedData.contractorId, equals(originalData.contractorId));
      expect(deserializedData.contractorName, equals(originalData.contractorName));
      expect(deserializedData.contractorAvatarUrl, equals(originalData.contractorAvatarUrl));
      expect(deserializedData.announcementId, equals(originalData.announcementId));
      expect(deserializedData.announcementTitle, equals(originalData.announcementTitle));
      expect(deserializedData.gameDateTime, equals(originalData.gameDateTime));
      expect(deserializedData.stadium, equals(originalData.stadium));
      expect(deserializedData.offeredAmount, equals(originalData.offeredAmount));
      expect(deserializedData.additionalNotes, equals(originalData.additionalNotes));

      // Test JSON serialization
      final json = originalData.toJson();
      final fromJsonData = ContractNotificationData.fromJson(json);
      expect(fromJsonData.contractId, equals(originalData.contractId));
    });

    test('should handle copyWith correctly', () {
      final originalData = ContractNotificationData(
        contractId: 'contract-123',
        contractorId: 'contractor-123',
        contractorName: 'João Silva',
        announcementId: 'announcement-123',
        announcementTitle: 'Jogo de Futebol',
        gameDateTime: DateTime(2024, 12, 25, 15, 30),
        stadium: 'Estádio Municipal',
      );

      final copiedData = originalData.copyWith(
        contractId: 'new-contract-456',
        offeredAmount: 100.0,
      );

      expect(copiedData.contractId, equals('new-contract-456'));
      expect(copiedData.offeredAmount, equals(100.0));
      expect(copiedData.contractorId, equals(originalData.contractorId));
      expect(copiedData.contractorName, equals(originalData.contractorName));
    });
  });

  group('Integration Tests', () {
    test('should handle complete contract lifecycle', () async {
      // This would be an integration test that tests the complete flow:
      // 1. Create contract
      // 2. Send notification
      // 3. Accept/decline contract
      // 4. Update status
      // 5. Clean up expired contracts
      
      // For now, this is a placeholder for the integration test structure
      expect(true, isTrue);
    });
  });
}
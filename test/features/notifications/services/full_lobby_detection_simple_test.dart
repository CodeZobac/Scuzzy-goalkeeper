import 'package:flutter_test/flutter_test.dart';
import 'package:goalkeeper/src/features/notifications/services/full_lobby_detection_service.dart';

void main() {
  group('FullLobbyDetectionService - Core Logic', () {
    late FullLobbyDetectionService service;

    setUp(() {
      // Create service with null repository and supabase client for testing core logic only
      service = FullLobbyDetectionService(null, null);
    });

    group('announcement status tracking', () {
      test('should track announcement status correctly', () {
        expect(service.getAnnouncementStatus(123), isNull);
        expect(service.isAnnouncementProcessed(123), isFalse);
      });

      test('should provide accurate statistics', () {
        final stats = service.getStatistics();
        
        expect(stats['processed_full_lobbies'], isA<int>());
        expect(stats['tracked_announcements'], isA<int>());
        expect(stats['full_announcements'], isA<int>());
        expect(stats['active_announcements'], isA<int>());
        
        // Initially should be zero
        expect(stats['processed_full_lobbies'], equals(0));
        expect(stats['tracked_announcements'], equals(0));
        expect(stats['full_announcements'], equals(0));
        expect(stats['active_announcements'], equals(0));
      });
    });

    group('AnnouncementStatus enum', () {
      test('should have correct enum values', () {
        expect(AnnouncementStatus.active, isA<AnnouncementStatus>());
        expect(AnnouncementStatus.full, isA<AnnouncementStatus>());
        expect(AnnouncementStatus.expired, isA<AnnouncementStatus>());
        
        expect(AnnouncementStatus.values.length, equals(3));
      });
    });

    group('disposal', () {
      test('should dispose resources properly', () {
        // Should not throw when disposed
        expect(() => service.dispose(), returnsNormally);
        
        // Should not throw when disposed multiple times
        expect(() => service.dispose(), returnsNormally);
      });
    });
  });
}
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:goalkeeper/src/features/notifications/services/full_lobby_detection_service.dart';
import 'package:goalkeeper/src/features/notifications/data/repositories/notification_repository.dart';
import 'package:goalkeeper/src/features/announcements/data/repositories/announcement_repository_impl.dart';
import 'package:goalkeeper/src/features/announcements/data/models/announcement.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Full Lobby Detection Integration Tests', () {
    late FullLobbyDetectionService fullLobbyService;
    late NotificationRepository notificationRepository;
    late AnnouncementRepositoryImpl announcementRepository;
    late SupabaseClient supabaseClient;

    setUpAll(() async {
      // Initialize Supabase (you'll need to configure this with your test environment)
      await Supabase.initialize(
        url: 'YOUR_SUPABASE_URL',
        anonKey: 'YOUR_SUPABASE_ANON_KEY',
      );
      
      supabaseClient = Supabase.instance.client;
      notificationRepository = NotificationRepository();
      announcementRepository = AnnouncementRepositoryImpl(supabaseClient);
      fullLobbyService = FullLobbyDetectionService(notificationRepository);
    });

    setUp(() async {
      // Clean up test data before each test
      await _cleanupTestData();
    });

    tearDown(() async {
      // Clean up test data after each test
      await _cleanupTestData();
    });

    testWidgets('should detect full lobby and send notification', (WidgetTester tester) async {
      // Create a test announcement
      final testAnnouncement = Announcement(
        id: 0, // Will be set by database
        createdBy: 'test-user-123',
        title: 'Test Game for Full Lobby',
        description: 'Integration test announcement',
        date: DateTime.now().add(const Duration(days: 1)),
        time: const TimeOfDay(hour: 18, minute: 0),
        price: 50.0,
        stadium: 'Test Stadium',
        createdAt: DateTime.now(),
        maxParticipants: 3, // Small number for easier testing
      );

      // Create the announcement
      await announcementRepository.createAnnouncement(testAnnouncement);
      
      // Get the created announcement to get its ID
      final announcements = await announcementRepository.getAnnouncements();
      final createdAnnouncement = announcements.firstWhere(
        (a) => a.title == 'Test Game for Full Lobby',
      );

      // Initialize the full lobby detection service
      await fullLobbyService.initialize();

      // Add participants to fill the announcement
      await announcementRepository.joinAnnouncement(createdAnnouncement.id, 'participant-1');
      await announcementRepository.joinAnnouncement(createdAnnouncement.id, 'participant-2');
      
      // Wait a moment for real-time processing
      await Future.delayed(const Duration(seconds: 2));
      
      // Check that announcement is not yet full
      expect(fullLobbyService.getAnnouncementStatus(createdAnnouncement.id), 
             equals(AnnouncementStatus.active));
      expect(fullLobbyService.isAnnouncementProcessed(createdAnnouncement.id), isFalse);

      // Add the final participant to make it full
      await announcementRepository.joinAnnouncement(createdAnnouncement.id, 'participant-3');
      
      // Wait for the full lobby detection to process
      await Future.delayed(const Duration(seconds: 5));
      
      // Manually trigger check to ensure it's processed
      await fullLobbyService.checkAnnouncement(createdAnnouncement.id);

      // Verify that the announcement is now marked as full
      expect(fullLobbyService.getAnnouncementStatus(createdAnnouncement.id), 
             equals(AnnouncementStatus.full));
      expect(fullLobbyService.isAnnouncementProcessed(createdAnnouncement.id), isTrue);

      // Verify that a notification was created
      final notifications = await notificationRepository.getUserNotifications('test-user-123');
      final fullLobbyNotifications = notifications.where((n) => n.type == 'full_lobby').toList();
      
      expect(fullLobbyNotifications.length, equals(1));
      
      final notification = fullLobbyNotifications.first;
      expect(notification.title, equals('Lobby Completo!'));
      expect(notification.body, contains('Test Game for Full Lobby'));
      expect(notification.body, contains('(3/3)'));
      
      // Verify notification data
      final fullLobbyData = notification.fullLobbyData;
      expect(fullLobbyData, isNotNull);
      expect(fullLobbyData!.announcementId, equals(createdAnnouncement.id.toString()));
      expect(fullLobbyData.announcementTitle, equals('Test Game for Full Lobby'));
      expect(fullLobbyData.participantCount, equals(3));
      expect(fullLobbyData.maxParticipants, equals(3));
      expect(fullLobbyData.stadium, equals('Test Stadium'));
    });

    testWidgets('should not send duplicate notifications', (WidgetTester tester) async {
      // Create a test announcement
      final testAnnouncement = Announcement(
        id: 0,
        createdBy: 'test-user-456',
        title: 'Test Duplicate Prevention',
        description: 'Test for duplicate notification prevention',
        date: DateTime.now().add(const Duration(days: 1)),
        time: const TimeOfDay(hour: 19, minute: 0),
        price: 40.0,
        stadium: 'Test Stadium 2',
        createdAt: DateTime.now(),
        maxParticipants: 2,
      );

      await announcementRepository.createAnnouncement(testAnnouncement);
      
      final announcements = await announcementRepository.getAnnouncements();
      final createdAnnouncement = announcements.firstWhere(
        (a) => a.title == 'Test Duplicate Prevention',
      );

      await fullLobbyService.initialize();

      // Fill the announcement
      await announcementRepository.joinAnnouncement(createdAnnouncement.id, 'participant-1');
      await announcementRepository.joinAnnouncement(createdAnnouncement.id, 'participant-2');
      
      // Wait and trigger check
      await Future.delayed(const Duration(seconds: 2));
      await fullLobbyService.checkAnnouncement(createdAnnouncement.id);

      // Get initial notification count
      final initialNotifications = await notificationRepository.getUserNotifications('test-user-456');
      final initialFullLobbyCount = initialNotifications.where((n) => n.type == 'full_lobby').length;

      // Try to trigger another check (should not create duplicate)
      await fullLobbyService.checkAnnouncement(createdAnnouncement.id);
      
      // Wait a bit more
      await Future.delayed(const Duration(seconds: 2));

      // Verify no duplicate notification was created
      final finalNotifications = await notificationRepository.getUserNotifications('test-user-456');
      final finalFullLobbyCount = finalNotifications.where((n) => n.type == 'full_lobby').length;
      
      expect(finalFullLobbyCount, equals(initialFullLobbyCount));
      expect(finalFullLobbyCount, equals(1)); // Should still be 1
    });

    testWidgets('should handle real-time participant changes', (WidgetTester tester) async {
      // Create a test announcement
      final testAnnouncement = Announcement(
        id: 0,
        createdBy: 'test-user-789',
        title: 'Test Real-time Detection',
        description: 'Test for real-time participant monitoring',
        date: DateTime.now().add(const Duration(days: 1)),
        time: const TimeOfDay(hour: 20, minute: 0),
        price: 60.0,
        stadium: 'Test Stadium 3',
        createdAt: DateTime.now(),
        maxParticipants: 4,
      );

      await announcementRepository.createAnnouncement(testAnnouncement);
      
      final announcements = await announcementRepository.getAnnouncements();
      final createdAnnouncement = announcements.firstWhere(
        (a) => a.title == 'Test Real-time Detection',
      );

      await fullLobbyService.initialize();

      // Add participants one by one with delays to test real-time detection
      await announcementRepository.joinAnnouncement(createdAnnouncement.id, 'participant-1');
      await Future.delayed(const Duration(seconds: 1));
      
      await announcementRepository.joinAnnouncement(createdAnnouncement.id, 'participant-2');
      await Future.delayed(const Duration(seconds: 1));
      
      await announcementRepository.joinAnnouncement(createdAnnouncement.id, 'participant-3');
      await Future.delayed(const Duration(seconds: 1));
      
      // Verify not full yet
      expect(fullLobbyService.getAnnouncementStatus(createdAnnouncement.id), 
             anyOf(equals(AnnouncementStatus.active), isNull));

      // Add final participant
      await announcementRepository.joinAnnouncement(createdAnnouncement.id, 'participant-4');
      
      // Wait for real-time processing (should be within 30 seconds as per requirement)
      await Future.delayed(const Duration(seconds: 10));

      // Verify that the announcement was detected as full
      expect(fullLobbyService.getAnnouncementStatus(createdAnnouncement.id), 
             equals(AnnouncementStatus.full));
      expect(fullLobbyService.isAnnouncementProcessed(createdAnnouncement.id), isTrue);

      // Verify notification was created
      final notifications = await notificationRepository.getUserNotifications('test-user-789');
      final fullLobbyNotifications = notifications.where((n) => n.type == 'full_lobby').toList();
      
      expect(fullLobbyNotifications.length, equals(1));
    });
  });

  /// Helper function to clean up test data
  Future<void> _cleanupTestData() async {
    try {
      final supabase = Supabase.instance.client;
      
      // Clean up test announcements
      await supabase
          .from('announcements')
          .delete()
          .like('title', '%Test%');
      
      // Clean up test notifications
      await supabase
          .from('notifications')
          .delete()
          .like('title', '%Test%');
      
      // Clean up test participants
      await supabase
          .from('announcement_participants')
          .delete()
          .like('user_id', 'participant-%');
          
      // Clean up test users if needed
      await supabase
          .from('announcement_participants')
          .delete()
          .like('user_id', 'test-user-%');
          
    } catch (e) {
      print('Error cleaning up test data: $e');
    }
  }
}
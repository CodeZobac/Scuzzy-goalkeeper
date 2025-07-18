import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:goalkeeper/src/features/announcements/presentation/controllers/announcement_controller.dart';
import 'package:goalkeeper/src/features/announcements/data/repositories/announcement_repository.dart';
import 'package:goalkeeper/src/features/announcements/data/models/announcement.dart';

// Simple mock repository for widget testing
class MockAnnouncementRepository implements AnnouncementRepository {
  final Map<int, Announcement> _announcements = {};
  final Map<int, List<String>> _participants = {};
  
  @override
  Future<List<Announcement>> getAnnouncements() async => _announcements.values.toList();

  @override
  Future<void> createAnnouncement(Announcement announcement) async {
    _announcements[announcement.id] = announcement;
  }

  @override
  Future<void> joinAnnouncement(int announcementId, String userId) async {
    final announcement = _announcements[announcementId];
    if (announcement == null) throw Exception('Announcement not found');
    
    final participants = _participants[announcementId] ?? [];
    if (participants.contains(userId)) {
      throw Exception('User is already a participant in this announcement');
    }
    
    if (participants.length >= announcement.maxParticipants) {
      throw Exception('This announcement is full. Cannot join.');
    }
    
    _participants[announcementId] = [...participants, userId];
  }

  @override
  Future<void> leaveAnnouncement(int announcementId, String userId) async {
    final participants = _participants[announcementId] ?? [];
    if (!participants.contains(userId)) {
      throw Exception('You are not a participant in this announcement.');
    }
    
    _participants[announcementId] = participants.where((id) => id != userId).toList();
  }

  @override
  Future<List<String>> getAnnouncementParticipants(int announcementId) async {
    return _participants[announcementId] ?? [];
  }

  @override
  Future<Announcement> getAnnouncementById(int id) async {
    final announcement = _announcements[id];
    if (announcement == null) throw Exception('Announcement not found');
    
    final participantCount = _participants[id]?.length ?? 0;
    return Announcement(
      id: announcement.id,
      title: announcement.title,
      description: announcement.description,
      date: announcement.date,
      time: announcement.time,
      createdAt: announcement.createdAt,
      createdBy: announcement.createdBy,
      price: announcement.price,
      stadium: announcement.stadium,
      organizerName: announcement.organizerName,
      organizerAvatarUrl: announcement.organizerAvatarUrl,
      organizerRating: announcement.organizerRating,
      stadiumImageUrl: announcement.stadiumImageUrl,
      distanceKm: announcement.distanceKm,
      participantCount: participantCount,
      maxParticipants: announcement.maxParticipants,
      participants: announcement.participants,
    );
  }

  @override
  Future<List<AnnouncementParticipant>> getParticipants(int announcementId) async {
    final participants = _participants[announcementId] ?? [];
    return participants.map((userId) => AnnouncementParticipant(
      userId: userId,
      name: 'User $userId',
      joinedAt: DateTime.now(),
    )).toList();
  }

  @override
  Future<bool> isUserParticipant(int announcementId, String userId) async {
    final participants = _participants[announcementId] ?? [];
    return participants.contains(userId);
  }

  @override
  Future<Map<String, dynamic>> getOrganizerInfo(String userId) async {
    return {'name': 'Test Organizer', 'avatar_url': null, 'rating': 4.5};
  }

  @override
  Future<Map<String, dynamic>> getStadiumInfo(String stadiumName) async {
    return {
      'name': stadiumName,
      'image_url': null,
      'distance_km': null,
      'photo_count': 0,
    };
  }

  void addAnnouncement(Announcement announcement) {
    _announcements[announcement.id] = announcement;
  }
}

void main() {
  group('Join/Leave Button Widget Tests', () {
    late MockAnnouncementRepository mockRepository;
    late AnnouncementController controller;

    setUp(() {
      mockRepository = MockAnnouncementRepository();
      controller = AnnouncementController(mockRepository);
    });

    Widget createTestWidget({
      required int announcementId,
      required int participantCount,
      required int maxParticipants,
      bool isJoined = false,
      bool isLoading = false,
    }) {
      // Set up controller state properly
      if (isJoined) {
        mockRepository._participants[announcementId] = ['test_user'];
      }

      return MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider<AnnouncementController>.value(
            value: controller,
            child: Consumer<AnnouncementController>(
              builder: (context, controller, child) {
                final isLoading = controller.isJoinLeaveLoading(announcementId);
                final isJoined = controller.isUserParticipant(announcementId);
                final isFull = participantCount >= maxParticipants;
                
                return SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: (isLoading || (isFull && !isJoined)) ? null : () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isJoined 
                          ? const Color(0xFF757575) 
                          : (isFull && !isJoined)
                              ? const Color(0xFFBDBDBD)
                              : const Color(0xFFFF9800),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            isJoined 
                                ? 'Leave Event' 
                                : (isFull && !isJoined)
                                    ? 'Event Full'
                                    : 'Join Event',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                );
              },
            ),
          ),
        ),
      );
    }

    testWidgets('should display "Join Event" when user is not participant', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget(
        announcementId: 1,
        participantCount: 5,
        maxParticipants: 22,
        isJoined: false,
      ));

      // Assert
      expect(find.text('Join Event'), findsOneWidget);
      expect(find.text('Leave Event'), findsNothing);
      expect(find.text('Event Full'), findsNothing);
      
      // Button should be enabled (orange color)
      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNotNull);
    });

    testWidgets('should display "Leave Event" when user is participant', (tester) async {
      // Arrange - Set up participation status properly
      const announcementId = 1;
      mockRepository._participants[announcementId] = ['test_user'];
      await controller.checkUserParticipation(announcementId, 'test_user');
      
      // Act
      await tester.pumpWidget(createTestWidget(
        announcementId: announcementId,
        participantCount: 5,
        maxParticipants: 22,
        isJoined: true,
      ));

      // Assert
      expect(find.text('Leave Event'), findsOneWidget);
      expect(find.text('Join Event'), findsNothing);
      expect(find.text('Event Full'), findsNothing);
      
      // Button should be enabled (gray color)
      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNotNull);
    });

    testWidgets('should display "Event Full" when announcement is at capacity', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget(
        announcementId: 1,
        participantCount: 22,
        maxParticipants: 22,
        isJoined: false,
      ));

      // Assert
      expect(find.text('Event Full'), findsOneWidget);
      expect(find.text('Join Event'), findsNothing);
      expect(find.text('Leave Event'), findsNothing);
      
      // Button should be disabled
      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('should allow leave when user is participant even if event is full', (tester) async {
      // Arrange - Set up participation status properly
      const announcementId = 1;
      mockRepository._participants[announcementId] = ['test_user'];
      await controller.checkUserParticipation(announcementId, 'test_user');
      
      // Act
      await tester.pumpWidget(createTestWidget(
        announcementId: announcementId,
        participantCount: 22,
        maxParticipants: 22,
        isJoined: true,
      ));

      // Assert
      expect(find.text('Leave Event'), findsOneWidget);
      expect(find.text('Event Full'), findsNothing);
      expect(find.text('Join Event'), findsNothing);
      
      // Button should be enabled even when full
      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNotNull);
    });

    testWidgets('should have correct button styling for different states', (tester) async {
      // Test Join Event button styling
      await tester.pumpWidget(createTestWidget(
        announcementId: 1,
        participantCount: 5,
        maxParticipants: 22,
        isJoined: false,
      ));

      final joinButton = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(joinButton.style?.backgroundColor?.resolve({}), const Color(0xFFFF9800));
      expect(find.text('Join Event'), findsOneWidget);

      // Test Event Full button styling
      await tester.pumpWidget(createTestWidget(
        announcementId: 2,
        participantCount: 22,
        maxParticipants: 22,
        isJoined: false,
      ));

      final fullButton = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(fullButton.style?.backgroundColor?.resolve({}), const Color(0xFFBDBDBD));
      expect(find.text('Event Full'), findsOneWidget);
      expect(fullButton.onPressed, isNull);
    });
  });
}
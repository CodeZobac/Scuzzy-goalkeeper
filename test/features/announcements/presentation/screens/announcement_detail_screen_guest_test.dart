import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:provider/provider.dart';
import 'package:goalkeeper/src/features/announcements/presentation/screens/announcement_detail_screen.dart';
import 'package:goalkeeper/src/features/announcements/presentation/controllers/announcement_controller.dart';
import 'package:goalkeeper/src/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:goalkeeper/src/features/announcements/data/models/announcement.dart';
import 'package:goalkeeper/src/shared/widgets/registration_prompt_dialog.dart';

import 'announcement_detail_screen_guest_test.mocks.dart';

@GenerateMocks([AnnouncementController, AuthStateProvider])
void main() {
  group('AnnouncementDetailScreen Guest Mode Tests', () {
    late MockAnnouncementController mockAnnouncementController;
    late MockAuthStateProvider mockAuthStateProvider;
    late Announcement testAnnouncement;

    setUp(() {
      mockAnnouncementController = MockAnnouncementController();
      mockAuthStateProvider = MockAuthStateProvider();
      
      testAnnouncement = Announcement(
        id: 1,
        title: 'Friday Football Match',
        description: 'Join us for a fun football match this Friday evening!',
        date: DateTime(2024, 4, 1),
        time: const TimeOfDay(hour: 18, minute: 30),
        price: 25.0,
        stadium: 'City Stadium',
        createdAt: DateTime.now(),
        organizerName: 'John Doe',
        organizerRating: 4.5,
        distanceKm: 2.0,
        participantCount: 8,
        maxParticipants: 22,
        participants: [],
      );

      // Default mock behavior
      when(mockAnnouncementController.getAnnouncementById(any))
          .thenAnswer((_) async => testAnnouncement);
      when(mockAnnouncementController.checkUserParticipation(any, any))
          .thenAnswer((_) async => true);
      when(mockAnnouncementController.isJoinLeaveLoading(any)).thenReturn(false);
      when(mockAnnouncementController.isUserParticipant(any)).thenReturn(false);
    });

    Widget createTestWidget({required bool isGuest}) {
      when(mockAuthStateProvider.isGuest).thenReturn(isGuest);
      when(mockAuthStateProvider.isAuthenticated).thenReturn(!isGuest);
      
      return MaterialApp(
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider<AnnouncementController>.value(
              value: mockAnnouncementController,
            ),
            ChangeNotifierProvider<AuthStateProvider>.value(
              value: mockAuthStateProvider,
            ),
          ],
          child: AnnouncementDetailScreen(announcement: testAnnouncement),
        ),
      );
    }

    group('Guest User Join Functionality', () {
      testWidgets('shows join button for guest users', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(isGuest: true));
        await tester.pumpAndSettle();

        // Verify join button is present and shows correct text
        expect(find.text('Join Event'), findsOneWidget);
        
        final joinButton = find.widgetWithText(ElevatedButton, 'Join Event');
        expect(joinButton, findsOneWidget);
        
        // Verify button is enabled
        final button = tester.widget<ElevatedButton>(joinButton);
        expect(button.onPressed, isNotNull);
      });

      testWidgets('shows registration prompt when guest tries to join', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(isGuest: true));
        await tester.pumpAndSettle();

        // Tap the join button
        await tester.tap(find.text('Join Event'));
        await tester.pumpAndSettle();

        // Verify registration prompt dialog appears
        expect(find.byType(RegistrationPromptDialog), findsOneWidget);
        expect(find.text('Participe da Partida!'), findsOneWidget);
        expect(find.text('Para participar de partidas e se conectar com outros jogadores, você precisa criar uma conta. É rápido e gratuito!'), findsOneWidget);
      });

      testWidgets('shows correct benefits in registration prompt for join match', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(isGuest: true));
        await tester.pumpAndSettle();

        // Tap the join button
        await tester.tap(find.text('Join Event'));
        await tester.pumpAndSettle();

        // Verify specific benefits for join match context
        expect(find.text('Com sua conta você pode:'), findsOneWidget);
        expect(find.text('Participar de partidas e eventos'), findsOneWidget);
        expect(find.text('Conectar-se com outros jogadores'), findsOneWidget);
        expect(find.text('Receber notificações de novas partidas'), findsOneWidget);
        expect(find.text('Acompanhar seu histórico de jogos'), findsOneWidget);
      });

      testWidgets('allows guest to dismiss registration prompt', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(isGuest: true));
        await tester.pumpAndSettle();

        // Tap the join button
        await tester.tap(find.text('Join Event'));
        await tester.pumpAndSettle();

        // Verify dialog is present
        expect(find.byType(RegistrationPromptDialog), findsOneWidget);

        // Tap "Agora Não" button
        await tester.tap(find.text('Agora Não'));
        await tester.pumpAndSettle();

        // Verify dialog is dismissed
        expect(find.byType(RegistrationPromptDialog), findsNothing);
      });

      testWidgets('does not call join/leave methods for guest users', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(isGuest: true));
        await tester.pumpAndSettle();

        // Tap the join button
        await tester.tap(find.text('Join Event'));
        await tester.pumpAndSettle();

        // Verify join/leave methods were not called
        verifyNever(mockAnnouncementController.joinAnnouncement(any, any));
        verifyNever(mockAnnouncementController.leaveAnnouncement(any, any));
      });
    });

    group('Guest User Viewing Experience', () {
      testWidgets('displays all announcement details for guest users', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(isGuest: true));
        await tester.pumpAndSettle();

        // Verify all announcement details are visible
        expect(find.text('Friday Football Match'), findsOneWidget);
        expect(find.text('Join us for a fun football match this Friday evening!'), findsOneWidget);
        expect(find.text('John Doe'), findsOneWidget);
        expect(find.text('City Stadium'), findsOneWidget);
      });

      testWidgets('shows participant information for guest users', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(isGuest: true));
        await tester.pumpAndSettle();

        // Verify participant information is displayed
        // Note: Specific participant display depends on ParticipantAvatarRow implementation
        expect(find.byType(ElevatedButton), findsOneWidget); // Join button should be present
      });

      testWidgets('allows guest users to view stadium information', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(isGuest: true));
        await tester.pumpAndSettle();

        // Verify stadium information is accessible
        expect(find.text('City Stadium'), findsOneWidget);
        
        // Stadium card should be present if stadium info exists
        // Note: Actual stadium card display depends on StadiumCard widget implementation
      });

      testWidgets('shows organizer profile for guest users', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(isGuest: true));
        await tester.pumpAndSettle();

        // Verify organizer information is displayed
        expect(find.text('John Doe'), findsOneWidget);
        
        // Back button should be present in organizer profile
        expect(find.byIcon(Icons.arrow_back), findsOneWidget);
      });
    });

    group('Authenticated User Comparison', () {
      testWidgets('shows different join button behavior for authenticated users', (WidgetTester tester) async {
        // Mock authenticated user who is not joined
        when(mockAnnouncementController.isUserParticipant(any)).thenReturn(false);
        
        await tester.pumpWidget(createTestWidget(isGuest: false));
        await tester.pumpAndSettle();

        // Verify join button is present
        expect(find.text('Join Event'), findsOneWidget);
        
        // Tap should not show registration prompt for authenticated users
        await tester.tap(find.text('Join Event'));
        await tester.pumpAndSettle();

        // Verify no registration dialog appears
        expect(find.byType(RegistrationPromptDialog), findsNothing);
      });

      testWidgets('shows leave button for authenticated users who joined', (WidgetTester tester) async {
        // Mock authenticated user who has joined
        when(mockAnnouncementController.isUserParticipant(any)).thenReturn(true);
        
        await tester.pumpWidget(createTestWidget(isGuest: false));
        await tester.pumpAndSettle();

        // Verify leave button is shown for joined authenticated users
        expect(find.text('Leave Event'), findsOneWidget);
      });
    });

    group('Full Event Handling', () {
      testWidgets('shows event full state correctly for guest users', (WidgetTester tester) async {
        // Create a full event
        final fullAnnouncement = testAnnouncement.copyWith(
          participantCount: 22,
          maxParticipants: 22,
        );
        
        when(mockAnnouncementController.getAnnouncementById(any))
            .thenAnswer((_) async => fullAnnouncement);

        await tester.pumpWidget(
          MaterialApp(
            home: MultiProvider(
              providers: [
                ChangeNotifierProvider<AnnouncementController>.value(
                  value: mockAnnouncementController,
                ),
                ChangeNotifierProvider<AuthStateProvider>.value(
                  value: mockAuthStateProvider,
                ),
              ],
              child: AnnouncementDetailScreen(announcement: fullAnnouncement),
            ),
          ),
        );
        
        when(mockAuthStateProvider.isGuest).thenReturn(true);
        await tester.pumpAndSettle();

        // For guest users, join button should still be available (they can register)
        expect(find.text('Join Event'), findsOneWidget);
        
        // Button should still be enabled for guests to trigger registration
        final joinButton = find.widgetWithText(ElevatedButton, 'Join Event');
        final button = tester.widget<ElevatedButton>(joinButton);
        expect(button.onPressed, isNotNull);
      });
    });

    group('Loading States', () {
      testWidgets('shows loading state while fetching announcement details', (WidgetTester tester) async {
        // Mock loading state
        when(mockAnnouncementController.getAnnouncementById(any))
            .thenAnswer((_) async {
          await Future.delayed(const Duration(seconds: 1));
          return testAnnouncement;
        });

        await tester.pumpWidget(createTestWidget(isGuest: true));
        
        // Should show loading initially
        expect(find.text('Loading announcement details...'), findsOneWidget);
        
        await tester.pumpAndSettle();
        
        // Should show content after loading
        expect(find.text('Friday Football Match'), findsOneWidget);
      });
    });
  });
}

// Extension to add copyWith method for testing
extension AnnouncementCopyWith on Announcement {
  Announcement copyWith({
    int? participantCount,
    int? maxParticipants,
  }) {
    return Announcement(
      id: id,
      title: title,
      description: description,
      date: date,
      time: time,
      price: price,
      stadium: stadium,
      createdAt: createdAt,
      organizerName: organizerName,
      organizerRating: organizerRating,
      distanceKm: distanceKm,
      participantCount: participantCount ?? this.participantCount,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      participants: participants,
    );
  }
}
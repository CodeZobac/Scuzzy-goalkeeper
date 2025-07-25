import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:provider/provider.dart';
import 'package:goalkeeper/src/features/announcements/presentation/screens/announcements_screen.dart';
import 'package:goalkeeper/src/features/announcements/presentation/controllers/announcement_controller.dart';
import 'package:goalkeeper/src/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:goalkeeper/src/features/announcements/data/models/announcement.dart';
import 'package:goalkeeper/src/features/announcements/presentation/widgets/announcement_card.dart';

import 'announcements_screen_guest_test.mocks.dart';

@GenerateMocks([AnnouncementController, AuthStateProvider])
void main() {
  group('AnnouncementsScreen Guest Mode Tests', () {
    late MockAnnouncementController mockAnnouncementController;
    late MockAuthStateProvider mockAuthStateProvider;
    late List<Announcement> testAnnouncements;

    setUp(() {
      mockAnnouncementController = MockAnnouncementController();
      mockAuthStateProvider = MockAuthStateProvider();
      
      testAnnouncements = [
        Announcement(
          id: 1,
          title: 'Friday Football Match',
          description: 'Join us for a fun match!',
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
        ),
      ];

      // Default mock behavior
      when(mockAnnouncementController.isLoading).thenReturn(false);
      when(mockAnnouncementController.hasError).thenReturn(false);
      when(mockAnnouncementController.announcements).thenReturn(testAnnouncements);
      when(mockAnnouncementController.fetchAnnouncements()).thenAnswer((_) async {});
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
          child: const AnnouncementsScreen(),
        ),
      );
    }

    group('Guest User Experience', () {
      testWidgets('hides create announcement FAB for guest users', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(isGuest: true));
        await tester.pumpAndSettle();

        // Verify FAB is not present for guest users
        expect(find.byType(FloatingActionButton), findsNothing);
        expect(find.byIcon(Icons.add), findsNothing);
      });

      testWidgets('shows create announcement FAB for authenticated users', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(isGuest: false));
        await tester.pumpAndSettle();

        // Verify FAB is present for authenticated users
        expect(find.byType(FloatingActionButton), findsOneWidget);
        expect(find.byIcon(Icons.add), findsOneWidget);
      });

      testWidgets('displays announcements list for guest users', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(isGuest: true));
        await tester.pumpAndSettle();

        // Verify announcements are displayed (they appear in AnnouncementCard widgets)
        expect(find.byType(AnnouncementCard), findsOneWidget);
        
        // Verify the announcement data is accessible through the widget
        final announcementCard = tester.widget<AnnouncementCard>(find.byType(AnnouncementCard));
        expect(announcementCard.announcement.title, equals('Friday Football Match'));
        expect(announcementCard.announcement.description, equals('Join us for a fun match!'));
        expect(announcementCard.announcement.stadium, equals('City Stadium'));
        expect(announcementCard.announcement.organizerName, equals('John Doe'));
      });

      testWidgets('allows guest users to view announcement details', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(isGuest: true));
        await tester.pumpAndSettle();

        // Verify announcement cards are present and accessible
        final announcementCard = find.byType(AnnouncementCard);
        expect(announcementCard, findsOneWidget);
        
        // Verify the card has the correct announcement data
        final cardWidget = tester.widget<AnnouncementCard>(announcementCard);
        expect(cardWidget.announcement.title, equals('Friday Football Match'));
        
        // Note: We don't test navigation here as it would require setting up routes
        // The actual navigation is handled by NavigationService in the real app
      });

      testWidgets('shows filter functionality for guest users', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(isGuest: true));
        await tester.pumpAndSettle();

        // Verify filter button is present and accessible
        expect(find.byIcon(Icons.tune), findsOneWidget);
        
        // Tap filter button
        await tester.tap(find.byIcon(Icons.tune));
        await tester.pumpAndSettle();

        // Verify filter bottom sheet appears
        expect(find.text('Filter Announcements'), findsOneWidget);
        expect(find.text('All Announcements'), findsOneWidget);
        expect(find.text('Today'), findsOneWidget);
        expect(find.text('This Week'), findsOneWidget);
        expect(find.text('Free Games'), findsOneWidget);
        expect(find.text('Paid Games'), findsOneWidget);
      });

      testWidgets('shows empty state for guest users when no announcements', (WidgetTester tester) async {
        when(mockAnnouncementController.announcements).thenReturn([]);
        
        await tester.pumpWidget(createTestWidget(isGuest: true));
        await tester.pumpAndSettle();

        // Verify empty state is shown
        expect(find.text('No announcements yet'), findsOneWidget);
        expect(find.text('Be the first to create an announcement'), findsOneWidget);
        expect(find.byIcon(Icons.campaign_outlined), findsOneWidget);
      });

      testWidgets('shows loading state for guest users', (WidgetTester tester) async {
        when(mockAnnouncementController.isLoading).thenReturn(true);
        
        await tester.pumpWidget(createTestWidget(isGuest: true));
        await tester.pump(); // Use pump instead of pumpAndSettle for loading state

        // Verify loading state is shown
        expect(find.text('Loading announcements...'), findsOneWidget);
      });

      testWidgets('shows error state for guest users', (WidgetTester tester) async {
        when(mockAnnouncementController.hasError).thenReturn(true);
        when(mockAnnouncementController.errorMessage).thenReturn('Network error');
        
        await tester.pumpWidget(createTestWidget(isGuest: true));
        await tester.pumpAndSettle();

        // Verify error state is shown
        expect(find.text('Network error'), findsOneWidget);
      });

      testWidgets('allows pull-to-refresh for guest users', (WidgetTester tester) async {
        when(mockAnnouncementController.refreshAnnouncements()).thenAnswer((_) async {});
        
        await tester.pumpWidget(createTestWidget(isGuest: true));
        await tester.pumpAndSettle();

        // Find the RefreshIndicator and trigger refresh
        await tester.fling(find.byType(ListView), const Offset(0, 300), 1000);
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));

        // Verify refresh was called
        verify(mockAnnouncementController.refreshAnnouncements()).called(1);
      });
    });

    group('Authentication State Comparison', () {
      testWidgets('shows different UI for guest vs authenticated users', (WidgetTester tester) async {
        // Test guest user first
        await tester.pumpWidget(createTestWidget(isGuest: true));
        await tester.pumpAndSettle();
        expect(find.byType(FloatingActionButton), findsNothing);

        // Create a fresh mock for authenticated user test
        final freshMockAuthProvider = MockAuthStateProvider();
        when(freshMockAuthProvider.isGuest).thenReturn(false);
        when(freshMockAuthProvider.isAuthenticated).thenReturn(true);
        
        // Test authenticated user with fresh widget
        await tester.pumpWidget(
          MaterialApp(
            home: MultiProvider(
              providers: [
                ChangeNotifierProvider<AnnouncementController>.value(
                  value: mockAnnouncementController,
                ),
                ChangeNotifierProvider<AuthStateProvider>.value(
                  value: freshMockAuthProvider,
                ),
              ],
              child: const AnnouncementsScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(FloatingActionButton), findsOneWidget);
      });

      testWidgets('both guest and authenticated users can view announcements', (WidgetTester tester) async {
        // Test guest user
        await tester.pumpWidget(createTestWidget(isGuest: true));
        await tester.pumpAndSettle();
        expect(find.byType(AnnouncementCard), findsOneWidget);

        // Test authenticated user
        await tester.pumpWidget(createTestWidget(isGuest: false));
        await tester.pumpAndSettle();
        expect(find.byType(AnnouncementCard), findsOneWidget);
      });
    });

    group('Accessibility', () {
      testWidgets('maintains accessibility for guest users', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(isGuest: true));
        await tester.pumpAndSettle();

        // Verify semantic labels are present
        expect(find.text('Recruitment'), findsOneWidget);
        expect(find.text('Today, ${DateTime.now().day} ${_getMonthName(DateTime.now().month)}'), findsOneWidget);
        
        // Verify filter button has proper semantics
        final filterButton = find.byIcon(Icons.tune);
        expect(filterButton, findsOneWidget);
      });
    });
  });
}

String _getMonthName(int month) {
  const months = [
    '', 'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];
  return months[month];
}
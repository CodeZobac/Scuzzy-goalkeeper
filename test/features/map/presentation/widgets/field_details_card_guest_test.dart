import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:goalkeeper/src/features/map/presentation/widgets/field_details_card.dart';
import 'package:goalkeeper/src/features/map/domain/models/map_field.dart';
import 'package:goalkeeper/src/core/utils/guest_mode_utils.dart';
import 'package:goalkeeper/src/shared/widgets/registration_prompt_dialog.dart';

import 'field_details_card_guest_test.mocks.dart';

@GenerateMocks([
  SupabaseClient,
  GotrueClient,
  Session,
  User,
])
void main() {
  group('FieldDetailsCard Guest Mode Tests', () {
    late MockSupabaseClient mockSupabaseClient;
    late MockGotrueClient mockGotrueClient;
    late MapField testField;

    setUp(() {
      mockSupabaseClient = MockSupabaseClient();
      mockGotrueClient = MockGotrueClient();

      // Set up mock client for guest mode
      when(mockSupabaseClient.auth).thenReturn(mockGotrueClient);
      when(mockGotrueClient.currentSession).thenReturn(null); // Guest mode
      when(mockGotrueClient.currentUser).thenReturn(null);

      // Set test client for GuestModeUtils
      GuestModeUtils.setTestClient(mockSupabaseClient);

      // Create test field
      testField = MapField(
        id: 'test_field_1',
        name: 'Test Football Field',
        latitude: 38.7223,
        longitude: -9.1393,
        status: 'approved',
        createdAt: DateTime.now(),
        city: 'Lisboa',
        surfaceType: 'natural',
        dimensions: '11v11',
        description: 'A beautiful football field for testing',
        photoUrl: 'https://example.com/field.jpg',
      );
    });

    tearDown(() {
      // Reset test client
      GuestModeUtils.setTestClient(null);
    });

    Widget createTestWidget({VoidCallback? onClose}) {
      return MaterialApp(
        home: Scaffold(
          body: FieldDetailsCard(
            field: testField,
            onClose: onClose,
          ),
        ),
        routes: {
          '/signup': (context) => const Scaffold(
            body: Center(child: Text('Signup Screen')),
          ),
        },
      );
    }

    testWidgets('should display field details for guest users', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verify field details are displayed
      expect(find.text('Test Football Field'), findsOneWidget);
      expect(find.text('Lisboa'), findsOneWidget);
      expect(find.text('A beautiful football field for testing'), findsOneWidget);
      expect(find.text('€24 / hour'), findsOneWidget);
      expect(find.text('Availability'), findsOneWidget);
    });

    testWidgets('should show registration prompt when guest taps availability button', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verify guest mode is active
      expect(GuestModeUtils.isGuest, isTrue);

      // Tap availability button
      await tester.tap(find.text('Availability'));
      await tester.pumpAndSettle();

      // Verify registration prompt dialog is shown
      expect(find.byType(RegistrationPromptDialog), findsOneWidget);
      expect(find.text('Contrate um Goleiro!'), findsOneWidget);
    });

    testWidgets('should navigate to signup when register button is pressed from availability', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tap availability button to show prompt
      await tester.tap(find.text('Availability'));
      await tester.pumpAndSettle();

      // Tap register button in the prompt
      await tester.tap(find.text('Criar Conta'));
      await tester.pumpAndSettle();

      // Verify navigation to signup screen
      expect(find.text('Signup Screen'), findsOneWidget);
    });

    testWidgets('should dismiss prompt when cancel button is pressed', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tap availability button to show prompt
      await tester.tap(find.text('Availability'));
      await tester.pumpAndSettle();

      // Tap cancel button
      await tester.tap(find.text('Agora Não'));
      await tester.pumpAndSettle();

      // Verify prompt is dismissed and we're back to field details
      expect(find.byType(RegistrationPromptDialog), findsNothing);
      expect(find.text('Test Football Field'), findsOneWidget);
    });

    testWidgets('should maintain existing visual design for guest users', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verify all visual elements are present
      expect(find.byType(DraggableScrollableSheet), findsOneWidget);
      expect(find.text('Upcoming events (9)'), findsOneWidget);
      expect(find.text('Friday Free Tournament'), findsOneWidget);
      
      // Verify rating display
      expect(find.byIcon(Icons.star), findsOneWidget);
      expect(find.text('4.5'), findsOneWidget);
      
      // Verify tags are displayed
      expect(find.text('Natural'), findsOneWidget);
      expect(find.text('11v11'), findsOneWidget);
      expect(find.text('Outdoor'), findsOneWidget);
    });

    testWidgets('should handle close callback properly', (WidgetTester tester) async {
      bool closeCalled = false;
      
      await tester.pumpWidget(createTestWidget(
        onClose: () => closeCalled = true,
      ));
      await tester.pumpAndSettle();

      // Find and tap the back button
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // Verify close callback was called
      expect(closeCalled, isTrue);
    });

    testWidgets('should display field information correctly for different field types', (WidgetTester tester) async {
      // Test with different field configuration
      final artificialField = MapField(
        id: 'test_field_2',
        name: 'Artificial Field',
        latitude: 38.7223,
        longitude: -9.1393,
        status: 'approved',
        createdAt: DateTime.now(),
        city: 'Porto',
        surfaceType: 'artificial',
        dimensions: '7v7',
        description: 'Modern artificial turf field',
        photoUrl: null,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FieldDetailsCard(field: artificialField),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify field-specific information is displayed
      expect(find.text('Artificial Field'), findsOneWidget);
      expect(find.text('Porto'), findsOneWidget);
      expect(find.text('Modern artificial turf field'), findsOneWidget);
      expect(find.text('Artificial'), findsOneWidget);
      expect(find.text('7v7'), findsOneWidget);
    });

    group('Authenticated User Tests', () {
      setUp(() {
        // Set up mock for authenticated user
        final mockSession = MockSession();
        final mockUser = MockUser();
        
        when(mockGotrueClient.currentSession).thenReturn(mockSession);
        when(mockGotrueClient.currentUser).thenReturn(mockUser);
      });

      testWidgets('should show booking functionality for authenticated users', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Verify authenticated mode
        expect(GuestModeUtils.isGuest, isFalse);

        // Tap availability button
        await tester.tap(find.text('Availability'));
        await tester.pumpAndSettle();

        // Should show snackbar instead of registration prompt
        expect(find.byType(RegistrationPromptDialog), findsNothing);
        expect(find.text('Booking functionality coming soon!'), findsOneWidget);
      });
    });
  });
}
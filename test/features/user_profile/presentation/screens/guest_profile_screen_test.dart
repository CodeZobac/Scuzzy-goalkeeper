import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goalkeeper/src/features/user_profile/presentation/screens/guest_profile_screen.dart';

void main() {
  group('GuestProfileScreen', () {
    testWidgets('should render guest profile screen with all components', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: const GuestProfileScreen(),
          routes: {
            '/signup': (context) => const Scaffold(body: Text('Signup Screen')),
          },
        ),
      );
      
      // Wait for animations to complete
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Perfil'), findsOneWidget);
      expect(find.text('Você não está logado'), findsOneWidget);
      expect(find.text('Crie uma conta para acessar recursos exclusivos e personalizar seu perfil'), findsOneWidget);
      expect(find.byIcon(Icons.person_outline), findsOneWidget);
    });

    testWidgets('should display feature cards with correct content', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: const GuestProfileScreen(),
          routes: {
            '/signup': (context) => const Scaffold(body: Text('Signup Screen')),
          },
        ),
      );
      
      // Wait for animations to complete
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Participe de Partidas'), findsOneWidget);
      expect(find.text('Encontre e participe de jogos na sua região'), findsOneWidget);
      expect(find.text('Contrate Goleiros'), findsOneWidget);
      expect(find.text('Encontre goleiros profissionais disponíveis'), findsOneWidget);
      expect(find.text('Perfil Personalizado'), findsOneWidget);
      expect(find.text('Crie seu perfil e mostre suas habilidades'), findsOneWidget);
      
      // Check feature card icons
      expect(find.byIcon(Icons.sports_soccer), findsWidgets);
      expect(find.byIcon(Icons.person_search), findsOneWidget);
      expect(find.byIcon(Icons.account_circle), findsOneWidget);
    });

    testWidgets('should display registration card structure', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: const GuestProfileScreen(),
          routes: {
            '/signup': (context) => const Scaffold(body: Text('Signup Screen')),
          },
        ),
      );
      
      // Wait for animations to complete
      await tester.pumpAndSettle();

      // Assert - Check that the registration card container exists
      final containers = find.byType(Container);
      expect(containers, findsWidgets);
      
      // Check that we have the expected number of text widgets (basic content should be there)
      final textWidgets = find.byType(Text);
      expect(textWidgets.evaluate().length, greaterThan(8));
      
      // Check that the screen has the basic structure with multiple containers
      expect(containers.evaluate().length, greaterThan(5));
    });

    testWidgets('should display register button', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: const GuestProfileScreen(),
          routes: {
            '/signup': (context) => const Scaffold(body: Text('Signup Screen')),
          },
        ),
      );
      
      // Wait for animations to complete
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Criar Conta'), findsOneWidget);
      expect(find.byIcon(Icons.person_add), findsOneWidget);
    });

    testWidgets('should navigate to signup when register button is tapped', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: const GuestProfileScreen(),
          routes: {
            '/signup': (context) => const Scaffold(body: Text('Signup Screen')),
          },
        ),
      );
      
      // Wait for animations to complete
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.text('Criar Conta'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Signup Screen'), findsOneWidget);
    });

    testWidgets('should have proper styling and theme consistency', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: const GuestProfileScreen(),
          routes: {
            '/signup': (context) => const Scaffold(body: Text('Signup Screen')),
          },
        ),
      );
      
      // Wait for animations to complete
      await tester.pumpAndSettle();

      // Assert - Check that containers with proper styling exist
      final containers = find.byType(Container);
      expect(containers, findsWidgets);
      
      // Check that the screen has proper background
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, equals(Colors.white));
    });

    testWidgets('should handle animations properly', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: const GuestProfileScreen(),
          routes: {
            '/signup': (context) => const Scaffold(body: Text('Signup Screen')),
          },
        ),
      );

      // Check initial state (before animations)
      expect(find.text('Perfil'), findsOneWidget);
      
      // Pump a few frames to let animations start
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 600));
      
      // Wait for all animations to complete
      await tester.pumpAndSettle();

      // Assert - All content should be visible after animations
      expect(find.text('Você não está logado'), findsOneWidget);
      expect(find.text('Criar Conta'), findsOneWidget);
    });

    testWidgets('should display guest avatar with proper styling', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: const GuestProfileScreen(),
          routes: {
            '/signup': (context) => const Scaffold(body: Text('Signup Screen')),
          },
        ),
      );
      
      // Wait for animations to complete
      await tester.pumpAndSettle();

      // Assert
      expect(find.byIcon(Icons.person_outline), findsOneWidget);
      
      // Check that the avatar container exists
      final avatarContainers = find.byType(Container);
      expect(avatarContainers, findsWidgets);
    });

    testWidgets('should be scrollable for different screen sizes', (WidgetTester tester) async {
      // Arrange - Set a small screen size
      tester.view.physicalSize = const Size(400, 600);
      tester.view.devicePixelRatio = 1.0;
      
      await tester.pumpWidget(
        MaterialApp(
          home: const GuestProfileScreen(),
          routes: {
            '/signup': (context) => const Scaffold(body: Text('Signup Screen')),
          },
        ),
      );
      
      // Wait for animations to complete
      await tester.pumpAndSettle();

      // Act - Try to scroll
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -200));
      await tester.pumpAndSettle();

      // Assert - Check that CustomScrollView exists and is scrollable
      expect(find.byType(CustomScrollView), findsOneWidget);
      
      // Reset window size
      addTearDown(() => tester.view.resetPhysicalSize());
    });
  });
}
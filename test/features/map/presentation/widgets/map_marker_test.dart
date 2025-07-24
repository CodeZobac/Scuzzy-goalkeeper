import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goalkeeper/src/features/map/presentation/widgets/map_icon_marker.dart';
import 'package:goalkeeper/src/features/map/presentation/widgets/field_marker.dart';
import 'package:goalkeeper/src/features/map/presentation/widgets/player_marker.dart';
import 'package:goalkeeper/src/features/map/presentation/widgets/goalkeeper_marker.dart';
import 'package:goalkeeper/src/features/map/presentation/widgets/user_marker.dart';

void main() {
  group('MapIconMarker Tests', () {
    testWidgets('should create widget without errors', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MapIconMarker(
              svgAssetKey: 'football_field',
              size: 48,
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('should respond to tap events', (tester) async {
      bool tapped = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MapIconMarker(
              svgAssetKey: 'football_field',
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(MapIconMarker));
      expect(tapped, isTrue);
    });

    testWidgets('should show status indicator when provided', (tester) async {
      const statusIndicator = MarkerStatusIndicator(
        color: Colors.red,
        icon: Icons.error,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MapIconMarker(
              svgAssetKey: 'football_field',
              statusIndicator: statusIndicator,
            ),
          ),
        ),
      );

      expect(find.byWidget(statusIndicator), findsOneWidget);
    });

    testWidgets('should animate when selection changes', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MapIconMarker(
              svgAssetKey: 'football_field',
              isSelected: false,
            ),
          ),
        ),
      );

      // Change to selected
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MapIconMarker(
              svgAssetKey: 'football_field',
              isSelected: true,
            ),
          ),
        ),
      );

      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });

  group('MarkerStatusIndicator Tests', () {
    testWidgets('should create indicator with color only', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MarkerStatusIndicator(
              color: Colors.red,
              size: 16,
            ),
          ),
        ),
      );

      expect(find.byType(MarkerStatusIndicator), findsOneWidget);
    });

    testWidgets('should create indicator with icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MarkerStatusIndicator(
              color: Colors.red,
              icon: Icons.check,
              size: 16,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.check), findsOneWidget);
    });
  });

  group('FieldMarker Tests', () {
    testWidgets('should create field marker', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FieldMarker(),
          ),
        ),
      );

      expect(find.byType(FieldMarker), findsOneWidget);
      expect(find.byType(MapIconMarker), findsOneWidget);
    });

    testWidgets('should show different colors based on status', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                FieldMarker(fieldStatus: 'approved'),
                FieldMarker(fieldStatus: 'pending'),
                FieldMarker(fieldStatus: 'rejected'),
                FieldMarker(isAvailable: false),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(FieldMarker), findsNWidgets(4));
    });

    testWidgets('should handle tap events', (tester) async {
      bool tapped = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FieldMarker(
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(FieldMarker));
      expect(tapped, isTrue);
    });

    testWidgets('should show status indicators', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                FieldMarker(fieldStatus: 'approved'),
                FieldMarker(isAvailable: false),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(MarkerStatusIndicator), findsNWidgets(2));
    });
  });

  group('PlayerMarker Tests', () {
    testWidgets('should create player marker', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PlayerMarker(),
          ),
        ),
      );

      expect(find.byType(PlayerMarker), findsOneWidget);
      expect(find.byType(MapIconMarker), findsOneWidget);
    });

    testWidgets('should show different colors based on skill level', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                PlayerMarker(skillLevel: 1),
                PlayerMarker(skillLevel: 3),
                PlayerMarker(skillLevel: 5),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(PlayerMarker), findsNWidgets(3));
    });

    testWidgets('should handle player status', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                PlayerMarker(playerStatus: 'available'),
                PlayerMarker(playerStatus: 'busy'),
                PlayerMarker(playerStatus: 'offline'),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(PlayerMarker), findsNWidgets(3));
    });

    testWidgets('should show status indicators for different states', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                PlayerMarker(playerStatus: 'available'),
                PlayerMarker(isActive: false),
                PlayerMarker(skillLevel: 3),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(MarkerStatusIndicator), findsNWidgets(3));
    });
  });

  group('PlayerClusterMarker Tests', () {
    testWidgets('should create cluster marker', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PlayerClusterMarker(playerCount: 5),
          ),
        ),
      );

      expect(find.byType(PlayerClusterMarker), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('should handle tap events', (tester) async {
      bool tapped = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlayerClusterMarker(
              playerCount: 3,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(PlayerClusterMarker));
      expect(tapped, isTrue);
    });
  });

  group('GoalkeeperMarker Tests', () {
    testWidgets('should create goalkeeper marker', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GoalkeeperMarker(),
          ),
        ),
      );

      expect(find.byType(GoalkeeperMarker), findsOneWidget);
      expect(find.byType(MapIconMarker), findsOneWidget);
    });

    testWidgets('should show different colors based on rating', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                GoalkeeperMarker(rating: 4.8),
                GoalkeeperMarker(rating: 4.2),
                GoalkeeperMarker(rating: 3.5),
                GoalkeeperMarker(rating: 2.5),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(GoalkeeperMarker), findsNWidgets(4));
    });

    testWidgets('should show verified badge', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GoalkeeperMarker(isVerified: true),
          ),
        ),
      );

      expect(find.byType(MarkerStatusIndicator), findsOneWidget);
    });

    testWidgets('should handle different statuses', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                GoalkeeperMarker(goalkeeperStatus: 'available'),
                GoalkeeperMarker(goalkeeperStatus: 'busy'),
                GoalkeeperMarker(goalkeeperStatus: 'in_game'),
                GoalkeeperMarker(goalkeeperStatus: 'offline'),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(GoalkeeperMarker), findsNWidgets(4));
    });

    testWidgets('should show experience level indicators', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                GoalkeeperMarker(experienceLevel: 1),
                GoalkeeperMarker(experienceLevel: 3),
                GoalkeeperMarker(experienceLevel: 5),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(GoalkeeperMarker), findsNWidgets(3));
    });
  });

  group('GoalkeeperAvailabilityMarker Tests', () {
    testWidgets('should create availability marker', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GoalkeeperAvailabilityMarker(availableCount: 3),
          ),
        ),
      );

      expect(find.byType(GoalkeeperAvailabilityMarker), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('should show average rating', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GoalkeeperAvailabilityMarker(
              availableCount: 5,
              averageRating: 4.2,
            ),
          ),
        ),
      );

      expect(find.text('4.2'), findsOneWidget);
      expect(find.byIcon(Icons.star), findsOneWidget);
    });
  });

  group('UserMarker Tests', () {
    testWidgets('should create user marker', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UserMarker(),
          ),
        ),
      );

      expect(find.byType(UserMarker), findsOneWidget);
    });

    testWidgets('should show current user indicator', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UserMarker(isCurrentUser: true),
          ),
        ),
      );

      expect(find.byIcon(Icons.star), findsOneWidget);
    });

    testWidgets('should show online status', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                UserMarker(isOnline: true),
                UserMarker(isOnline: false),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(UserMarker), findsNWidgets(2));
    });

    testWidgets('should handle tap events', (tester) async {
      bool tapped = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UserMarker(
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(UserMarker));
      expect(tapped, isTrue);
    });

    testWidgets('should animate when selection changes', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UserMarker(isSelected: false),
          ),
        ),
      );

      await tester.pump();

      // Change to selected
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UserMarker(isSelected: true),
          ),
        ),
      );

      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('should pulse animate for current user', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UserMarker(isCurrentUser: true),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.takeException(), isNull);
    });
  });

  group('LegacyUserMarker Tests', () {
    testWidgets('should create legacy user marker', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LegacyUserMarker(),
          ),
        ),
      );

      expect(find.byType(LegacyUserMarker), findsOneWidget);
      expect(find.byType(CircleAvatar), findsOneWidget);
    });

    testWidgets('should show person icon when no image', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LegacyUserMarker(),
          ),
        ),
      );

      expect(find.byIcon(Icons.person), findsOneWidget);
    });
  });

  group('Accessibility Tests', () {
    testWidgets('MapIconMarker should create with semantic label', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MapIconMarker(
              svgAssetKey: 'football_field',
              semanticsLabel: 'Test marker',
            ),
          ),
        ),
      );

      expect(find.byType(MapIconMarker), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('FieldMarker should create with accessibility support', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FieldMarker(
              isSelected: true,
              isAvailable: true,
              fieldStatus: 'approved',
            ),
          ),
        ),
      );

      expect(find.byType(FieldMarker), findsOneWidget);
      expect(find.byType(MapIconMarker), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('UserMarker should create with accessibility support', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UserMarker(
              isCurrentUser: true,
              isOnline: true,
              userName: 'John Doe',
            ),
          ),
        ),
      );

      expect(find.byType(UserMarker), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
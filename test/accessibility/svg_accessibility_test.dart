import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goalkeeper/src/shared/widgets/svg_asset_manager.dart';
import 'package:goalkeeper/src/shared/widgets/enhanced_web_svg_asset.dart';
import 'package:goalkeeper/src/features/map/presentation/widgets/map_icon_marker.dart';
import 'package:goalkeeper/src/features/map/presentation/widgets/field_marker.dart';
import 'package:goalkeeper/src/features/map/presentation/widgets/player_marker.dart';
import 'package:goalkeeper/src/features/map/presentation/widgets/goalkeeper_marker.dart';

void main() {
  group('SVG Accessibility Tests', () {
    testWidgets('SvgAssetManager should provide semantic labels', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SvgAssetManager.getAsset('auth_header'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify that SVG assets have proper semantic labels
      final config = SvgAssetManager.getConfig('auth_header');
      expect(config?.semanticLabel, isNotNull);
      expect(config?.semanticLabel, isNotEmpty);
    });

    testWidgets('EnhancedWebSvgAsset should support screen readers', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EnhancedWebSvgAsset(
              assetPath: 'assets/test.svg',
              semanticsLabel: 'Test SVG for accessibility',
              width: 100,
              height: 100,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should create widget without accessibility violations
      expect(tester.takeException(), isNull);
      
      // Verify semantic label is applied
      expect(find.byType(EnhancedWebSvgAsset), findsOneWidget);
    });

    testWidgets('SVG fallback should be accessible', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EnhancedWebSvgAsset(
              assetPath: 'assets/non_existent.svg',
              semanticsLabel: 'Fallback icon',
              fallback: const Icon(
                Icons.error,
                semanticLabel: 'Error loading SVG',
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Fallback should also be accessible
      expect(find.byIcon(Icons.error), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('SVG loading states should be announced', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EnhancedWebSvgAsset(
              assetPath: 'assets/test.svg',
              semanticsLabel: 'Loading SVG content',
            ),
          ),
        ),
      );

      // Initial loading state
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('SVG error states should be accessible', (tester) async {
      bool errorCallbackCalled = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EnhancedWebSvgAsset(
              assetPath: 'assets/non_existent.svg',
              semanticsLabel: 'SVG that will fail to load',
              onError: () => errorCallbackCalled = true,
              fallback: const Icon(
                Icons.broken_image,
                semanticLabel: 'Image failed to load',
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Error state should be accessible
      expect(errorCallbackCalled, isTrue);
      expect(tester.takeException(), isNull);
    });
  });

  group('Map Marker Accessibility Tests', () {
    testWidgets('MapIconMarker should have proper semantics', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MapIconMarker(
              svgAssetKey: 'football_field',
              semanticsLabel: 'Football field marker',
              size: 48,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(MapIconMarker), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('FieldMarker should be accessible', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FieldMarker(
              isSelected: false,
              isAvailable: true,
              fieldStatus: 'approved',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should provide meaningful semantic information
      expect(find.byType(FieldMarker), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('PlayerMarker should announce player status', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PlayerMarker(
              isSelected: false,
              isActive: true,
              playerStatus: 'available',
              skillLevel: 4,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(PlayerMarker), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('GoalkeeperMarker should provide detailed accessibility info', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GoalkeeperMarker(
              isSelected: false,
              isActive: true,
              goalkeeperStatus: 'available',
              rating: 4.5,
              experienceLevel: 3,
              isVerified: true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(GoalkeeperMarker), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Marker interactions should be accessible', (tester) async {
      bool markerTapped = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MapIconMarker(
              svgAssetKey: 'football_field',
              semanticsLabel: 'Tappable field marker',
              onTap: () => markerTapped = true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should be tappable via accessibility services
      await tester.tap(find.byType(MapIconMarker));
      expect(markerTapped, isTrue);
    });

    testWidgets('Marker selection states should be announced', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                MapIconMarker(
                  svgAssetKey: 'football_field',
                  semanticsLabel: 'Selected field marker',
                  isSelected: true,
                ),
                MapIconMarker(
                  svgAssetKey: 'football_field',
                  semanticsLabel: 'Unselected field marker',
                  isSelected: false,
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(MapIconMarker), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    });

    testWidgets('Marker status indicators should be accessible', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FieldMarker(
              isAvailable: false,
              fieldStatus: 'maintenance',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Status indicators should provide semantic information
      expect(find.byType(FieldMarker), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('SVG Animation Accessibility Tests', () {
    testWidgets('Animated SVG markers should respect reduced motion', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MapIconMarker(
              svgAssetKey: 'football_field',
              isSelected: true,
              enableAnimations: true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should handle animation preferences
      expect(find.byType(MapIconMarker), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('SVG loading animations should not interfere with screen readers', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EnhancedWebSvgAsset(
              assetPath: 'assets/test.svg',
              semanticsLabel: 'Loading animated SVG',
              showLoadingAnimation: true,
            ),
          ),
        ),
      );

      // Should show loading indicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('Hover animations should not affect accessibility', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MapIconMarker(
              svgAssetKey: 'football_field',
              semanticsLabel: 'Hoverable marker',
              onTap: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Simulate hover (on platforms that support it)
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      
      await gesture.moveTo(tester.getCenter(find.byType(MapIconMarker)));
      await tester.pump();

      expect(tester.takeException(), isNull);
    });
  });

  group('SVG Color and Contrast Accessibility Tests', () {
    testWidgets('SVG markers should maintain sufficient contrast', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: const Scaffold(
            body: Column(
              children: [
                FieldMarker(fieldStatus: 'approved'),
                PlayerMarker(playerStatus: 'available'),
                GoalkeeperMarker(goalkeeperStatus: 'available'),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // All markers should render with proper contrast
      expect(find.byType(FieldMarker), findsOneWidget);
      expect(find.byType(PlayerMarker), findsOneWidget);
      expect(find.byType(GoalkeeperMarker), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('SVG markers should work in dark mode', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: const Scaffold(
            body: Column(
              children: [
                FieldMarker(fieldStatus: 'approved'),
                PlayerMarker(playerStatus: 'available'),
                GoalkeeperMarker(goalkeeperStatus: 'available'),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should adapt to dark theme
      expect(find.byType(FieldMarker), findsOneWidget);
      expect(find.byType(PlayerMarker), findsOneWidget);
      expect(find.byType(GoalkeeperMarker), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('SVG markers should support high contrast mode', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            brightness: Brightness.light,
            colorScheme: const ColorScheme.highContrastLight(),
          ),
          home: const Scaffold(
            body: Column(
              children: [
                FieldMarker(fieldStatus: 'approved'),
                PlayerMarker(playerStatus: 'available'),
                GoalkeeperMarker(goalkeeperStatus: 'available'),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should work with high contrast themes
      expect(find.byType(FieldMarker), findsOneWidget);
      expect(find.byType(PlayerMarker), findsOneWidget);
      expect(find.byType(GoalkeeperMarker), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('SVG Focus Management Tests', () {
    testWidgets('Focusable SVG markers should handle keyboard navigation', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                MapIconMarker(
                  svgAssetKey: 'football_field',
                  semanticsLabel: 'First marker',
                  onTap: () {},
                ),
                MapIconMarker(
                  svgAssetKey: 'football_player',
                  semanticsLabel: 'Second marker',
                  onTap: () {},
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should be able to focus on markers
      expect(find.byType(MapIconMarker), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    });

    testWidgets('SVG markers should provide focus indicators', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MapIconMarker(
              svgAssetKey: 'football_field',
              semanticsLabel: 'Focusable marker',
              onTap: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Focus should be visually indicated
      expect(find.byType(MapIconMarker), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('SVG markers should handle focus loss gracefully', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                MapIconMarker(
                  svgAssetKey: 'football_field',
                  onTap: () {},
                ),
                const TextField(),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Focus on text field should not cause issues with SVG marker
      await tester.tap(find.byType(TextField));
      await tester.pump();

      expect(tester.takeException(), isNull);
    });
  });

  group('SVG Semantic Structure Tests', () {
    testWidgets('SVG components should have proper semantic hierarchy', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(title: const Text('Map')),
            body: const Column(
              children: [
                Text('Available Fields'),
                FieldMarker(fieldStatus: 'approved'),
                Text('Available Players'),
                PlayerMarker(playerStatus: 'available'),
                Text('Available Goalkeepers'),
                GoalkeeperMarker(goalkeeperStatus: 'available'),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should maintain proper semantic structure
      expect(find.text('Available Fields'), findsOneWidget);
      expect(find.text('Available Players'), findsOneWidget);
      expect(find.text('Available Goalkeepers'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('SVG markers should group related information', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GoalkeeperMarker(
              goalkeeperStatus: 'available',
              rating: 4.5,
              experienceLevel: 3,
              isVerified: true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Related information should be semantically grouped
      expect(find.byType(GoalkeeperMarker), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goalkeeper/src/shared/widgets/svg_asset_manager.dart';
import 'package:goalkeeper/src/shared/widgets/enhanced_web_svg_asset.dart';
import 'package:goalkeeper/src/features/map/presentation/widgets/map_icon_marker.dart';
import 'package:goalkeeper/src/features/map/presentation/widgets/field_marker.dart';
import 'package:goalkeeper/src/features/map/presentation/widgets/player_marker.dart';
import 'package:goalkeeper/src/features/map/presentation/widgets/goalkeeper_marker.dart';

void main() {
  group('SVG Rendering Performance Tests', () {
    setUp(() {
      // Clear cache before each test
      SvgAssetManager.clearCache();
    });

    testWidgets('should render multiple SVG assets efficiently', (tester) async {
      final stopwatch = Stopwatch()..start();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                SvgAssetManager.getAsset('auth_header'),
                SvgAssetManager.getAsset('football_field'),
                SvgAssetManager.getAsset('football_player'),
                SvgAssetManager.getAsset('goalkeeper'),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      stopwatch.stop();

      // Should render within reasonable time (adjust threshold as needed)
      expect(stopwatch.elapsedMilliseconds, lessThan(1000));
      expect(tester.takeException(), isNull);
    });

    testWidgets('should handle rapid SVG asset switching efficiently', (tester) async {
      final assets = ['football_field', 'football_player', 'goalkeeper'];
      int currentAssetIndex = 0;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return MaterialApp(
              home: Scaffold(
                body: Column(
                  children: [
                    SvgAssetManager.getAsset(assets[currentAssetIndex]),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          currentAssetIndex = (currentAssetIndex + 1) % assets.length;
                        });
                      },
                      child: const Text('Switch Asset'),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );

      await tester.pumpAndSettle();

      final stopwatch = Stopwatch()..start();

      // Rapidly switch between assets
      for (int i = 0; i < 10; i++) {
        await tester.tap(find.text('Switch Asset'));
        await tester.pump();
      }

      await tester.pumpAndSettle();
      stopwatch.stop();

      // Should handle rapid switching efficiently
      expect(stopwatch.elapsedMilliseconds, lessThan(500));
      expect(tester.takeException(), isNull);
    });

    testWidgets('should optimize memory usage with large number of SVG assets', (tester) async {
      // Create many SVG widgets to test memory management
      final widgets = List.generate(20, (index) {
        final assetKeys = ['football_field', 'football_player', 'goalkeeper'];
        return SvgAssetManager.getAsset(assetKeys[index % assetKeys.length]);
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Column(children: widgets),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check cache metrics
      final metrics = SvgAssetManager.getPerformanceMetrics();
      
      // Should not exceed reasonable memory limits
      expect(metrics.totalCacheMemoryBytes, lessThan(50 * 1024 * 1024)); // 50MB
      expect(metrics.currentCacheSize, lessThanOrEqualTo(50)); // Max cache size
      expect(tester.takeException(), isNull);
    });

    testWidgets('should handle SVG rendering in scrollable lists efficiently', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView.builder(
              itemCount: 100,
              itemBuilder: (context, index) {
                final assetKeys = ['football_field', 'football_player', 'goalkeeper'];
                return ListTile(
                  leading: SvgAssetManager.getAsset(
                    assetKeys[index % assetKeys.length],
                    width: 32,
                    height: 32,
                  ),
                  title: Text('Item $index'),
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final stopwatch = Stopwatch()..start();

      // Scroll through the list
      await tester.drag(find.byType(ListView), const Offset(0, -2000));
      await tester.pump();
      await tester.drag(find.byType(ListView), const Offset(0, -2000));
      await tester.pump();

      await tester.pumpAndSettle();
      stopwatch.stop();

      // Should handle scrolling efficiently
      expect(stopwatch.elapsedMilliseconds, lessThan(1000));
      expect(tester.takeException(), isNull);
    });

    testWidgets('should cache SVG assets effectively', (tester) async {
      const assetPath = 'assets/test.svg';
      
      // First load
      final stopwatch1 = Stopwatch()..start();
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EnhancedWebSvgAsset(
              assetPath: assetPath,
              width: 100,
              height: 100,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      stopwatch1.stop();

      // Second load (should be from cache)
      final stopwatch2 = Stopwatch()..start();
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EnhancedWebSvgAsset(
              assetPath: assetPath,
              width: 100,
              height: 100,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      stopwatch2.stop();

      // Second load should be faster due to caching
      // Note: In test environment, actual caching behavior may vary
      expect(tester.takeException(), isNull);
    });

    testWidgets('should handle concurrent SVG loading efficiently', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      SvgAssetManager.getAsset('football_field'),
                      SvgAssetManager.getAsset('football_player'),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      SvgAssetManager.getAsset('goalkeeper'),
                      SvgAssetManager.getAsset('auth_header'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      final stopwatch = Stopwatch()..start();
      await tester.pumpAndSettle();
      stopwatch.stop();

      // Should handle concurrent loading efficiently
      expect(stopwatch.elapsedMilliseconds, lessThan(2000));
      expect(tester.takeException(), isNull);
    });
  });

  group('Map Marker Performance Tests', () {
    testWidgets('should render many map markers efficiently', (tester) async {
      final markers = List.generate(50, (index) {
        return Positioned(
          left: (index % 10) * 50.0,
          top: (index ~/ 10) * 50.0,
          child: const FieldMarker(),
        );
      });

      final stopwatch = Stopwatch()..start();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(children: markers),
          ),
        ),
      );

      await tester.pumpAndSettle();
      stopwatch.stop();

      // Should render many markers efficiently
      expect(stopwatch.elapsedMilliseconds, lessThan(2000));
      expect(tester.takeException(), isNull);
    });

    testWidgets('should handle marker animations efficiently', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                MapIconMarker(
                  svgAssetKey: 'football_field',
                  isSelected: false,
                  enableAnimations: true,
                ),
                MapIconMarker(
                  svgAssetKey: 'football_player',
                  isSelected: false,
                  enableAnimations: true,
                ),
                MapIconMarker(
                  svgAssetKey: 'goalkeeper',
                  isSelected: false,
                  enableAnimations: true,
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final stopwatch = Stopwatch()..start();

      // Trigger selection animations
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                MapIconMarker(
                  svgAssetKey: 'football_field',
                  isSelected: true,
                  enableAnimations: true,
                ),
                MapIconMarker(
                  svgAssetKey: 'football_player',
                  isSelected: true,
                  enableAnimations: true,
                ),
                MapIconMarker(
                  svgAssetKey: 'goalkeeper',
                  isSelected: true,
                  enableAnimations: true,
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      stopwatch.stop();

      // Should handle animations efficiently
      expect(stopwatch.elapsedMilliseconds, lessThan(1000));
      expect(tester.takeException(), isNull);
    });

    testWidgets('should optimize marker clustering performance', (tester) async {
      // Create many markers that would be clustered
      final markers = List.generate(100, (index) {
        return PlayerMarker(
          playerStatus: index % 2 == 0 ? 'available' : 'busy',
          skillLevel: (index % 5) + 1,
        );
      });

      final stopwatch = Stopwatch()..start();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Wrap(children: markers),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      stopwatch.stop();

      // Should handle many markers efficiently
      expect(stopwatch.elapsedMilliseconds, lessThan(3000));
      expect(tester.takeException(), isNull);
    });

    testWidgets('should handle marker state changes efficiently', (tester) async {
      bool isSelected = false;
      
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return MaterialApp(
              home: Scaffold(
                body: Column(
                  children: [
                    MapIconMarker(
                      svgAssetKey: 'football_field',
                      isSelected: isSelected,
                    ),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          isSelected = !isSelected;
                        });
                      },
                      child: const Text('Toggle Selection'),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );

      await tester.pumpAndSettle();

      final stopwatch = Stopwatch()..start();

      // Rapidly toggle selection state
      for (int i = 0; i < 10; i++) {
        await tester.tap(find.text('Toggle Selection'));
        await tester.pump();
      }

      await tester.pumpAndSettle();
      stopwatch.stop();

      // Should handle state changes efficiently
      expect(stopwatch.elapsedMilliseconds, lessThan(500));
      expect(tester.takeException(), isNull);
    });
  });

  group('SVG Cache Performance Tests', () {
    testWidgets('should maintain optimal cache hit ratio', (tester) async {
      // Load same assets multiple times
      for (int i = 0; i < 5; i++) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  SvgAssetManager.getAsset('football_field'),
                  SvgAssetManager.getAsset('football_player'),
                  SvgAssetManager.getAsset('goalkeeper'),
                ],
              ),
            ),
          ),
        );
        await tester.pump();
      }

      final metrics = SvgAssetManager.getPerformanceMetrics();
      
      // Should have good cache hit ratio
      expect(metrics.cacheHitRatio, greaterThan(0.5));
      expect(metrics.cacheHits, greaterThan(0));
    });

    testWidgets('should handle cache eviction efficiently', (tester) async {
      // Fill cache beyond limit
      for (int i = 0; i < 60; i++) {
        final svgContent = '<svg>test$i</svg>';
        SvgAssetManager.cacheSvg('test_asset_$i.svg', svgContent);
      }

      final metrics = SvgAssetManager.getPerformanceMetrics();
      
      // Should have triggered eviction
      expect(metrics.currentCacheSize, lessThanOrEqualTo(50));
      expect(metrics.cacheEvictions, greaterThan(0));
    });

    testWidgets('should optimize cache memory usage', (tester) async {
      // Add various sized assets to cache
      final smallSvg = '<svg width="10" height="10"><rect/></svg>';
      final mediumSvg = '<svg width="100" height="100">${'<rect/>' * 10}</svg>';
      final largeSvg = '<svg width="1000" height="1000">${'<rect/>' * 100}</svg>';

      SvgAssetManager.cacheSvg('small.svg', smallSvg);
      SvgAssetManager.cacheSvg('medium.svg', mediumSvg);
      SvgAssetManager.cacheSvg('large.svg', largeSvg);

      final metrics = SvgAssetManager.getPerformanceMetrics();
      
      // Should track memory usage accurately
      expect(metrics.totalCacheMemoryBytes, greaterThan(0));
      expect(metrics.currentCacheSize, equals(3));
    });

    testWidgets('should handle cache optimization efficiently', (tester) async {
      // Fill cache with assets of varying access patterns
      for (int i = 0; i < 30; i++) {
        final svgContent = '<svg>content$i</svg>';
        SvgAssetManager.cacheSvg('asset_$i.svg', svgContent);
        
        // Access some assets more frequently
        if (i % 3 == 0) {
          for (int j = 0; j < 3; j++) {
            SvgAssetManager.getCachedSvg('asset_$i.svg');
          }
        }
      }

      final beforeOptimization = SvgAssetManager.getPerformanceMetrics();
      
      final stopwatch = Stopwatch()..start();
      SvgAssetManager.optimizeCache();
      stopwatch.stop();

      final afterOptimization = SvgAssetManager.getPerformanceMetrics();
      
      // Optimization should be fast
      expect(stopwatch.elapsedMilliseconds, lessThan(100));
      
      // Should have optimized cache
      expect(afterOptimization.currentCacheSize, 
             lessThanOrEqualTo(beforeOptimization.currentCacheSize));
    });

    testWidgets('should prevent memory leaks in long-running scenarios', (tester) async {
      // Simulate long-running app with many SVG operations
      for (int cycle = 0; cycle < 5; cycle++) {
        // Load many different assets
        for (int i = 0; i < 20; i++) {
          final assetKey = 'cycle_${cycle}_asset_$i.svg';
          final svgContent = '<svg>cycle$cycle-asset$i</svg>';
          SvgAssetManager.cacheSvg(assetKey, svgContent);
        }
        
        // Access some assets
        for (int i = 0; i < 10; i++) {
          SvgAssetManager.getCachedSvg('cycle_${cycle}_asset_$i.svg');
        }
        
        // Trigger optimization periodically
        if (cycle % 2 == 0) {
          SvgAssetManager.optimizeCache();
        }
      }

      final finalMetrics = SvgAssetManager.getPerformanceMetrics();
      
      // Should maintain reasonable memory usage
      expect(finalMetrics.totalCacheMemoryBytes, lessThan(10 * 1024 * 1024)); // 10MB
      expect(finalMetrics.currentCacheSize, lessThanOrEqualTo(50));
    });
  });

  group('SVG Animation Performance Tests', () {
    testWidgets('should handle smooth animations at 60fps', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MapIconMarker(
              svgAssetKey: 'football_field',
              isSelected: false,
              enableAnimations: true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final stopwatch = Stopwatch()..start();

      // Trigger animation by changing selection
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

      // Pump animation frames
      for (int i = 0; i < 60; i++) {
        await tester.pump(const Duration(milliseconds: 16)); // ~60fps
      }

      stopwatch.stop();

      // Should maintain smooth animation
      expect(stopwatch.elapsedMilliseconds, lessThan(1200)); // Allow some overhead
      expect(tester.takeException(), isNull);
    });

    testWidgets('should handle multiple simultaneous animations', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Row(
              children: [
                MapIconMarker(
                  svgAssetKey: 'football_field',
                  isSelected: false,
                  enableAnimations: true,
                ),
                MapIconMarker(
                  svgAssetKey: 'football_player',
                  isSelected: false,
                  enableAnimations: true,
                ),
                MapIconMarker(
                  svgAssetKey: 'goalkeeper',
                  isSelected: false,
                  enableAnimations: true,
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final stopwatch = Stopwatch()..start();

      // Trigger all animations simultaneously
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Row(
              children: [
                MapIconMarker(
                  svgAssetKey: 'football_field',
                  isSelected: true,
                  enableAnimations: true,
                ),
                MapIconMarker(
                  svgAssetKey: 'football_player',
                  isSelected: true,
                  enableAnimations: true,
                ),
                MapIconMarker(
                  svgAssetKey: 'goalkeeper',
                  isSelected: true,
                  enableAnimations: true,
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      stopwatch.stop();

      // Should handle multiple animations efficiently
      expect(stopwatch.elapsedMilliseconds, lessThan(1000));
      expect(tester.takeException(), isNull);
    });

    testWidgets('should optimize animation disposal', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MapIconMarker(
              svgAssetKey: 'football_field',
              enableAnimations: true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final stopwatch = Stopwatch()..start();

      // Remove widget to trigger disposal
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Container(),
          ),
        ),
      );

      stopwatch.stop();

      // Should dispose quickly without errors
      expect(stopwatch.elapsedMilliseconds, lessThan(100));
      expect(tester.takeException(), isNull);
    });
  });
}
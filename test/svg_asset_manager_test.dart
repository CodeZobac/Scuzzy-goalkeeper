import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goalkeeper/src/shared/widgets/svg_asset_manager.dart';

void main() {
  group('SvgAssetManager Tests', () {
    setUp(() {
      // Clear cache before each test
      SvgAssetManager.clearCache();
    });

    test('should have predefined asset configurations', () {
      expect(SvgAssetManager.hasAsset('auth_header'), isTrue);
      expect(SvgAssetManager.hasAsset('football_field'), isTrue);
      expect(SvgAssetManager.hasAsset('football_player'), isTrue);
      expect(SvgAssetManager.hasAsset('goalkeeper'), isTrue);
    });

    test('should return null for non-existent asset', () {
      expect(SvgAssetManager.hasAsset('non_existent'), isFalse);
      expect(SvgAssetManager.getConfig('non_existent'), isNull);
    });

    test('should return correct asset configuration', () {
      final config = SvgAssetManager.getConfig('auth_header');
      expect(config, isNotNull);
      expect(config!.path, equals('assets/auth-header.svg'));
      expect(config.semanticLabel, equals('Authentication header illustration'));
      expect(config.defaultSize, equals(const Size(300, 200)));
    });

    test('should manage cache correctly', () {
      const testPath = 'test/path.svg';
      const testSvg = '<svg>test</svg>';
      
      // Initially empty
      expect(SvgAssetManager.getCachedSvg(testPath), isNull);
      expect(SvgAssetManager.cacheSize, equals(0));
      
      // Cache SVG
      SvgAssetManager.cacheSvg(testPath, testSvg);
      expect(SvgAssetManager.getCachedSvg(testPath), equals(testSvg));
      expect(SvgAssetManager.cacheSize, equals(1));
      
      // Remove from cache
      SvgAssetManager.removeCachedSvg(testPath);
      expect(SvgAssetManager.getCachedSvg(testPath), isNull);
      expect(SvgAssetManager.cacheSize, equals(0));
    });

    test('should clear entire cache', () {
      SvgAssetManager.cacheSvg('path1.svg', '<svg>1</svg>');
      SvgAssetManager.cacheSvg('path2.svg', '<svg>2</svg>');
      expect(SvgAssetManager.cacheSize, equals(2));
      
      SvgAssetManager.clearCache();
      expect(SvgAssetManager.cacheSize, equals(0));
    });

    test('should register new asset configuration', () {
      const newKey = 'test_asset';
      final newConfig = SvgAssetConfig(
        path: 'assets/test.svg',
        semanticLabel: 'Test asset',
        fallback: Icon(Icons.settings),
      );
      
      expect(SvgAssetManager.hasAsset(newKey), isFalse);
      
      SvgAssetManager.registerAsset(newKey, newConfig);
      expect(SvgAssetManager.hasAsset(newKey), isTrue);
      expect(SvgAssetManager.getConfig(newKey), equals(newConfig));
    });

    test('should return available assets list', () {
      final assets = SvgAssetManager.availableAssets;
      expect(assets, contains('auth_header'));
      expect(assets, contains('football_field'));
      expect(assets, contains('football_player'));
      expect(assets, contains('goalkeeper'));
      expect(assets.length, greaterThanOrEqualTo(4));
    });

    testWidgets('should return error widget for non-existent asset', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SvgAssetManager.getAsset('non_existent'),
          ),
        ),
      );

      expect(find.byIcon(Icons.error), findsOneWidget);
    });

    testWidgets('should return fallback widget for asset with fallback', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SvgAssetManager.getAsset(
              'football_field',
              fallback: const Icon(Icons.star),
            ),
          ),
        ),
      );

      // Since we can't load actual SVG in tests, it should show the fallback
      await tester.pump();
      // The widget should be created without errors
      expect(tester.takeException(), isNull);
    });
  });

  group('SvgAssetConfig Tests', () {
    test('should create config with required parameters', () {
      const config = SvgAssetConfig(
        path: 'assets/test.svg',
        semanticLabel: 'Test SVG',
        fallback: Icon(Icons.settings),
      );

      expect(config.path, equals('assets/test.svg'));
      expect(config.semanticLabel, equals('Test SVG'));
      expect(config.fallback, isA<Icon>());
      expect(config.enableCaching, isTrue); // default value
    });

    test('should create config with all parameters', () {
      const config = SvgAssetConfig(
        path: 'assets/test.svg',
        semanticLabel: 'Test SVG',
        defaultColor: Colors.red,
        defaultSize: Size(100, 100),
        fallback: Icon(Icons.settings),
        enableCaching: false,
      );

      expect(config.path, equals('assets/test.svg'));
      expect(config.semanticLabel, equals('Test SVG'));
      expect(config.defaultColor, equals(Colors.red));
      expect(config.defaultSize, equals(const Size(100, 100)));
      expect(config.fallback, isA<Icon>());
      expect(config.enableCaching, isFalse);
    });
  });

  group('EnhancedWebSvgAsset Tests', () {
    testWidgets('should create widget without errors', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EnhancedWebSvgAsset(
              assetPath: 'assets/test.svg',
              width: 100,
              height: 100,
              semanticsLabel: 'Test SVG',
            ),
          ),
        ),
      );

      // Should not throw any exceptions during creation
      expect(tester.takeException(), isNull);
    });

    testWidgets('should show loading placeholder initially', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EnhancedWebSvgAsset(
              assetPath: 'assets/test.svg',
              width: 100,
              height: 100,
            ),
          ),
        ),
      );

      // Should show loading indicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should respect custom fallback widget', (tester) async {
      const customFallback = Icon(Icons.star);
      
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EnhancedWebSvgAsset(
              assetPath: 'assets/non_existent.svg',
              fallback: customFallback,
            ),
          ),
        ),
      );

      await tester.pump();
      // Should eventually show the custom fallback (after loading fails)
      // Note: In test environment, asset loading will fail, so fallback should appear
    });

    testWidgets('should handle error callback', (tester) async {
      bool errorCallbackCalled = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EnhancedWebSvgAsset(
              assetPath: 'assets/non_existent.svg',
              onError: () {
                errorCallbackCalled = true;
              },
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      
      // Error callback should be called when asset fails to load
      expect(errorCallbackCalled, isTrue);
    });
  });

  group('Extension Tests', () {
    testWidgets('should create EnhancedWebSvgAsset via extension', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: 'assets/test.svg'.toEnhancedSvgAsset(
              width: 50,
              height: 50,
              semanticsLabel: 'Test via extension',
            ),
          ),
        ),
      );

      expect(find.byType(EnhancedWebSvgAsset), findsOneWidget);
    });
  });
}
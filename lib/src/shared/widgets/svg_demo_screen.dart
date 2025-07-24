import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'svg_asset_manager.dart';
import 'svg_performance_monitor.dart';

/// Demo screen to showcase the enhanced SVG infrastructure with performance monitoring
/// This is for testing and demonstration purposes
class SvgDemoScreen extends StatefulWidget {
  const SvgDemoScreen({super.key});

  @override
  State<SvgDemoScreen> createState() => _SvgDemoScreenState();
}

class _SvgDemoScreenState extends State<SvgDemoScreen> {
  Timer? _metricsTimer;
  SvgPerformanceMetrics? _currentMetrics;
  bool _showDebugOverlay = kDebugMode;

  @override
  void initState() {
    super.initState();
    _startMetricsUpdates();
    _preloadAssets();
  }

  @override
  void dispose() {
    _metricsTimer?.cancel();
    super.dispose();
  }

  void _startMetricsUpdates() {
    _metricsTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (mounted) {
        setState(() {
          _currentMetrics = SvgAssetManager.getPerformanceMetrics();
        });
      }
    });
  }

  Future<void> _preloadAssets() async {
    try {
      await SvgAssetManager.preloadCriticalAssets();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Critical SVG assets preloaded successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to preload assets: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SvgPerformanceMonitor(
      enableAutoOptimization: true,
      showDebugOverlay: _showDebugOverlay,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('SVG Infrastructure Demo'),
          backgroundColor: Colors.blue.shade600,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: Icon(_showDebugOverlay ? Icons.visibility_off : Icons.visibility),
              onPressed: () {
                setState(() {
                  _showDebugOverlay = !_showDebugOverlay;
                });
              },
              tooltip: 'Toggle Debug Overlay',
            ),
            IconButton(
              icon: const Icon(Icons.analytics),
              onPressed: () => _showPerformanceDialog(),
              tooltip: 'Performance Metrics',
            ),
          ],
        ),
        body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              'SvgAssetManager Usage',
              [
                _buildAssetDemo('Auth Header', 'auth_header', width: 300, height: 200),
                _buildAssetDemo('Football Field', 'football_field', width: 64, height: 64),
                _buildAssetDemo('Football Player', 'football_player', width: 56, height: 56),
                _buildAssetDemo('Goalkeeper', 'goalkeeper', width: 64, height: 64),
              ],
            ),
            const SizedBox(height: 32),
            _buildSection(
              'Enhanced WebSvgAsset Features',
              [
                _buildFeatureDemo('Custom Color', 'football_field', color: Colors.red),
                _buildFeatureDemo('Custom Fallback', 'non_existent', 
                  fallback: const Icon(Icons.error, color: Colors.orange, size: 48)),
                _buildFeatureDemo('Error Handling', 'invalid_asset'),
                _buildFeatureDemo('Caching Disabled', 'football_player', enableCaching: false),
              ],
            ),
            const SizedBox(height: 32),
            _buildSection(
              'Extension Usage',
              [
                _buildExtensionDemo(),
              ],
            ),
            const SizedBox(height: 32),
            _buildCacheInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }

  Widget _buildAssetDemo(String label, String assetKey, {double? width, double? height}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: SvgAssetManager.getAsset(
                assetKey,
                width: width,
                height: height,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Key: $assetKey',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                if (SvgAssetManager.getConfig(assetKey) != null)
                  Text(
                    'Path: ${SvgAssetManager.getConfig(assetKey)!.path}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureDemo(String label, String assetKey, {
    Color? color,
    Widget? fallback,
    bool enableCaching = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: SvgAssetManager.getAsset(
                assetKey,
                width: 48,
                height: 48,
                color: color,
                fallback: fallback,
                enableCaching: enableCaching,
                onError: () {
                  debugPrint('Error loading $assetKey in demo');
                },
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Asset: $assetKey',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                if (color != null)
                  Text(
                    'Custom color applied',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade600,
                    ),
                  ),
                if (!enableCaching)
                  Text(
                    'Caching disabled',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange.shade600,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExtensionDemo() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: 'assets/icons8-football.svg'.toEnhancedSvgAsset(
                width: 48,
                height: 48,
                color: Colors.purple,
                semanticsLabel: 'Purple football via extension',
              ),
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Extension Method',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Using .toEnhancedSvgAsset()',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  'Purple color + custom semantics',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.purple,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCacheInfo() {
    final metrics = _currentMetrics ?? SvgPerformanceMetrics(
      cacheHits: 0,
      cacheMisses: 0,
      totalLoads: 0,
      cacheEvictions: 0,
      currentCacheSize: SvgAssetManager.cacheSize,
      totalCacheMemoryBytes: SvgAssetManager.cacheMemoryUsage,
      averageLoadTime: 0.0,
      assetLoadCounts: {},
      assetAverageLoadTimes: {},
    );

    return Column(
      children: [
        // Performance Metrics Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Performance Metrics',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade800,
                ),
              ),
              const SizedBox(height: 8),
              _buildMetricRow('Cache Hit Ratio', '${(metrics.cacheHitRatio * 100).toStringAsFixed(1)}%'),
              _buildMetricRow('Cache Hits', '${metrics.cacheHits}'),
              _buildMetricRow('Cache Misses', '${metrics.cacheMisses}'),
              _buildMetricRow('Cache Evictions', '${metrics.cacheEvictions}'),
              _buildMetricRow('Memory Usage', '${(metrics.totalCacheMemoryBytes / 1024 / 1024).toStringAsFixed(2)} MB'),
              _buildMetricRow('Avg Load Time', '${metrics.averageLoadTime.toStringAsFixed(1)} ms'),
              const SizedBox(height: 12),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: () => _runPerformanceTest(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Run Performance Test'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => SvgAssetManager.optimizeCache(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade600,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Optimize Cache'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Cache Information Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Cache Information',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Available Assets: ${SvgAssetManager.availableAssets.length}',
                style: TextStyle(color: Colors.blue.shade700),
              ),
              Text(
                'Cached Items: ${metrics.currentCacheSize}',
                style: TextStyle(color: Colors.blue.shade700),
              ),
              const SizedBox(height: 8),
              Text(
                'Assets: ${SvgAssetManager.availableAssets.join(', ')}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.blue.shade600,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: () {
                      SvgAssetManager.clearCache();
                      setState(() {
                        _currentMetrics = SvgAssetManager.getPerformanceMetrics();
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Clear Cache'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => _preloadAssets(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple.shade600,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Preload Assets'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetricRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.green.shade700),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.green.shade800,
            ),
          ),
        ],
      ),
    );
  }

  void _showPerformanceDialog() {
    showDialog(
      context: context,
      builder: (context) => SvgMetricsDialog(),
    );
  }

  Future<void> _runPerformanceTest() async {
    final stopwatch = Stopwatch()..start();
    
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Running performance test...'),
          ],
        ),
      ),
    );

    try {
      // Clear cache to start fresh
      SvgAssetManager.clearCache();
      
      // Load all assets multiple times to test caching
      final assets = SvgAssetManager.availableAssets;
      for (int round = 0; round < 3; round++) {
        for (final assetKey in assets) {
          final config = SvgAssetManager.getConfig(assetKey);
          if (config != null) {
            try {
              await SvgAssetManager.loadSvgWithTracking(config.path);
            } catch (e) {
              // Ignore individual asset loading errors for the test
            }
          }
        }
      }
      
      stopwatch.stop();
      
      // Get final metrics
      final metrics = SvgAssetManager.getPerformanceMetrics();
      final recommendations = SvgPerformanceOptimizer.analyzePerformance();
      
      // Close loading dialog
      if (mounted) Navigator.of(context).pop();
      
      // Show results
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Performance Test Results'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Test Duration: ${stopwatch.elapsedMilliseconds}ms'),
                  Text('Performance Score: ${recommendations.overallScore.toStringAsFixed(1)}/100'),
                  Text('Grade: ${recommendations.performanceGrade}'),
                  const SizedBox(height: 16),
                  Text('Cache Hit Ratio: ${(metrics.cacheHitRatio * 100).toStringAsFixed(1)}%'),
                  Text('Total Loads: ${metrics.totalLoads}'),
                  Text('Cache Size: ${metrics.currentCacheSize}'),
                  Text('Memory Usage: ${(metrics.totalCacheMemoryBytes / 1024 / 1024).toStringAsFixed(2)} MB'),
                  if (recommendations.recommendations.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text('Recommendations:', style: TextStyle(fontWeight: FontWeight.bold)),
                    ...recommendations.recommendations.map((rec) => Text('• $rec')),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }
      
      // Update metrics display
      setState(() {
        _currentMetrics = metrics;
      });
      
    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.of(context).pop();
      
      // Show error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Performance test failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
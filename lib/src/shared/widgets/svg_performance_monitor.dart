import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'svg_asset_manager.dart';
import '../../core/logging/error_logger.dart';

/// Performance monitoring widget for SVG assets
/// Provides real-time metrics and cache management tools
class SvgPerformanceMonitor extends StatefulWidget {
  final Widget child;
  final bool enableAutoOptimization;
  final Duration optimizationInterval;
  final bool showDebugOverlay;

  const SvgPerformanceMonitor({
    super.key,
    required this.child,
    this.enableAutoOptimization = true,
    this.optimizationInterval = const Duration(minutes: 5),
    this.showDebugOverlay = false,
  });

  @override
  State<SvgPerformanceMonitor> createState() => _SvgPerformanceMonitorState();
}

class _SvgPerformanceMonitorState extends State<SvgPerformanceMonitor> {
  Timer? _optimizationTimer;
  SvgPerformanceMetrics? _lastMetrics;

  @override
  void initState() {
    super.initState();
    _startAutoOptimization();
    _preloadCriticalAssets();
  }

  @override
  void dispose() {
    _optimizationTimer?.cancel();
    super.dispose();
  }

  void _startAutoOptimization() {
    if (!widget.enableAutoOptimization) return;

    _optimizationTimer = Timer.periodic(widget.optimizationInterval, (_) {
      _performOptimization();
    });
  }

  void _performOptimization() {
    final metrics = SvgAssetManager.getPerformanceMetrics();
    
    // Auto-optimize cache if hit ratio is low or memory usage is high
    if (metrics.cacheHitRatio < 0.7 || 
        metrics.totalCacheMemoryBytes > 8 * 1024 * 1024) { // 8MB threshold
      SvgAssetManager.optimizeCache();
      
      ErrorLogger.logInfo(
        'Auto-optimization triggered',
        context: 'SVG_AUTO_OPTIMIZATION',
        additionalData: {
          'hit_ratio': metrics.cacheHitRatio,
          'memory_mb': (metrics.totalCacheMemoryBytes / 1024 / 1024).toStringAsFixed(2),
          'cache_size': metrics.currentCacheSize,
        },
      );
    }

    setState(() {
      _lastMetrics = metrics;
    });
  }

  Future<void> _preloadCriticalAssets() async {
    try {
      await SvgAssetManager.preloadCriticalAssets();
      ErrorLogger.logInfo(
        'Critical SVG assets preloaded successfully',
        context: 'SVG_PRELOAD_COMPLETE',
      );
    } catch (e) {
      ErrorLogger.logError(
        'Failed to preload critical SVG assets',
        StackTrace.current,
        context: 'SVG_PRELOAD_FAILED',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget child = widget.child;

    if (widget.showDebugOverlay && kDebugMode) {
      child = Stack(
        children: [
          child,
          Positioned(
            top: 50,
            right: 10,
            child: _buildDebugOverlay(),
          ),
        ],
      );
    }

    return child;
  }

  Widget _buildDebugOverlay() {
    final metrics = SvgAssetManager.getPerformanceMetrics();
    
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'SVG Cache Stats',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Hit Ratio: ${(metrics.cacheHitRatio * 100).toStringAsFixed(1)}%',
            style: const TextStyle(color: Colors.white, fontSize: 10),
          ),
          Text(
            'Cache Size: ${metrics.currentCacheSize}',
            style: const TextStyle(color: Colors.white, fontSize: 10),
          ),
          Text(
            'Memory: ${(metrics.totalCacheMemoryBytes / 1024 / 1024).toStringAsFixed(1)}MB',
            style: const TextStyle(color: Colors.white, fontSize: 10),
          ),
          Text(
            'Avg Load: ${metrics.averageLoadTime.toStringAsFixed(1)}ms',
            style: const TextStyle(color: Colors.white, fontSize: 10),
          ),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: () => _showDetailedMetrics(context),
            child: const Text(
              'Tap for details',
              style: TextStyle(
                color: Colors.blue,
                fontSize: 9,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDetailedMetrics(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => SvgMetricsDialog(),
    );
  }
}

/// Dialog showing detailed SVG performance metrics
class SvgMetricsDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final metrics = SvgAssetManager.getPerformanceMetrics();
    
    return AlertDialog(
      title: const Text('SVG Performance Metrics'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildMetricRow('Cache Hits', '${metrics.cacheHits}'),
            _buildMetricRow('Cache Misses', '${metrics.cacheMisses}'),
            _buildMetricRow('Hit Ratio', '${(metrics.cacheHitRatio * 100).toStringAsFixed(1)}%'),
            _buildMetricRow('Cache Size', '${metrics.currentCacheSize}'),
            _buildMetricRow('Memory Usage', '${(metrics.totalCacheMemoryBytes / 1024 / 1024).toStringAsFixed(2)} MB'),
            _buildMetricRow('Evictions', '${metrics.cacheEvictions}'),
            _buildMetricRow('Avg Load Time', '${metrics.averageLoadTime.toStringAsFixed(1)} ms'),
            
            const SizedBox(height: 16),
            const Text(
              'Asset Load Counts:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            
            ...metrics.assetLoadCounts.entries.map((entry) =>
              _buildMetricRow(entry.key, '${entry.value} loads')
            ),
            
            const SizedBox(height: 16),
            const Text(
              'Asset Avg Load Times:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            
            ...metrics.assetAverageLoadTimes.entries.map((entry) =>
              _buildMetricRow(entry.key, '${entry.value.toStringAsFixed(1)} ms')
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            SvgAssetManager.optimizeCache();
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Cache optimized')),
            );
          },
          child: const Text('Optimize Cache'),
        ),
        TextButton(
          onPressed: () {
            SvgAssetManager.clearCache();
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Cache cleared')),
            );
          },
          child: const Text('Clear Cache'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
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
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

/// Utility class for SVG performance optimization
class SvgPerformanceOptimizer {
  /// Warm up the cache by preloading commonly used assets
  static Future<void> warmUpCache({
    List<String>? specificAssets,
    bool preloadAll = false,
  }) async {
    if (preloadAll) {
      final allAssets = SvgAssetManager.availableAssets;
      await SvgAssetManager.preloadAssets(allAssets);
    } else if (specificAssets != null) {
      await SvgAssetManager.preloadAssets(specificAssets);
    } else {
      await SvgAssetManager.preloadCriticalAssets();
    }
  }

  /// Analyze cache performance and provide recommendations
  static SvgOptimizationRecommendations analyzePerformance() {
    final metrics = SvgAssetManager.getPerformanceMetrics();
    final recommendations = <String>[];
    
    if (metrics.cacheHitRatio < 0.5) {
      recommendations.add('Low cache hit ratio (${(metrics.cacheHitRatio * 100).toStringAsFixed(1)}%). Consider preloading more assets.');
    }
    
    if (metrics.totalCacheMemoryBytes > 15 * 1024 * 1024) { // 15MB
      recommendations.add('High memory usage (${(metrics.totalCacheMemoryBytes / 1024 / 1024).toStringAsFixed(1)}MB). Consider reducing cache size or optimizing assets.');
    }
    
    if (metrics.averageLoadTime > 100) { // 100ms
      recommendations.add('Slow average load time (${metrics.averageLoadTime.toStringAsFixed(1)}ms). Consider optimizing SVG files or preloading.');
    }
    
    if (metrics.cacheEvictions > metrics.currentCacheSize) {
      recommendations.add('High cache eviction rate. Consider increasing cache size or optimizing usage patterns.');
    }
    
    // Find assets that are loaded frequently but have slow load times
    final slowFrequentAssets = <String>[];
    for (final entry in metrics.assetAverageLoadTimes.entries) {
      final loadCount = metrics.assetLoadCounts[entry.key] ?? 0;
      if (loadCount > 5 && entry.value > 50) { // Loaded more than 5 times and takes >50ms
        slowFrequentAssets.add('${entry.key} (${entry.value.toStringAsFixed(1)}ms, ${loadCount} loads)');
      }
    }
    
    if (slowFrequentAssets.isNotEmpty) {
      recommendations.add('Consider optimizing these frequently used slow assets: ${slowFrequentAssets.join(', ')}');
    }
    
    return SvgOptimizationRecommendations(
      metrics: metrics,
      recommendations: recommendations,
      overallScore: _calculatePerformanceScore(metrics),
    );
  }
  
  static double _calculatePerformanceScore(SvgPerformanceMetrics metrics) {
    double score = 100.0;
    
    // Penalize low hit ratio
    if (metrics.cacheHitRatio < 0.8) {
      score -= (0.8 - metrics.cacheHitRatio) * 50;
    }
    
    // Penalize high memory usage
    final memoryMB = metrics.totalCacheMemoryBytes / 1024 / 1024;
    if (memoryMB > 10) {
      score -= (memoryMB - 10) * 2;
    }
    
    // Penalize slow load times
    if (metrics.averageLoadTime > 50) {
      score -= (metrics.averageLoadTime - 50) * 0.5;
    }
    
    return score.clamp(0.0, 100.0);
  }
}

/// Recommendations for SVG performance optimization
class SvgOptimizationRecommendations {
  final SvgPerformanceMetrics metrics;
  final List<String> recommendations;
  final double overallScore;

  const SvgOptimizationRecommendations({
    required this.metrics,
    required this.recommendations,
    required this.overallScore,
  });

  String get performanceGrade {
    if (overallScore >= 90) return 'A';
    if (overallScore >= 80) return 'B';
    if (overallScore >= 70) return 'C';
    if (overallScore >= 60) return 'D';
    return 'F';
  }

  @override
  String toString() {
    return 'SVG Performance: ${performanceGrade} (${overallScore.toStringAsFixed(1)}/100)\n'
           'Recommendations: ${recommendations.isEmpty ? 'None' : recommendations.join('; ')}';
  }
}
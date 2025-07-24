import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:async';
import 'dart:collection';
import '../../core/error_handling/error_boundary.dart';
import '../../core/logging/error_logger.dart';
import 'fallback_components.dart';

/// Configuration for SVG assets with metadata and fallback options
class SvgAssetConfig {
  final String path;
  final String semanticLabel;
  final Color? defaultColor;
  final Size? defaultSize;
  final Widget fallback;
  final bool enableCaching;

  const SvgAssetConfig({
    required this.path,
    required this.semanticLabel,
    this.defaultColor,
    this.defaultSize,
    required this.fallback,
    this.enableCaching = true,
  });
}

/// Cache entry with metadata for LRU eviction and memory management
class _CacheEntry {
  final String svgString;
  final DateTime lastAccessed;
  final int accessCount;
  final int sizeInBytes;

  _CacheEntry({
    required this.svgString,
    required this.lastAccessed,
    this.accessCount = 1,
    required this.sizeInBytes,
  });

  _CacheEntry copyWith({
    DateTime? lastAccessed,
    int? accessCount,
  }) {
    return _CacheEntry(
      svgString: svgString,
      lastAccessed: lastAccessed ?? this.lastAccessed,
      accessCount: accessCount ?? this.accessCount,
      sizeInBytes: sizeInBytes,
    );
  }
}

/// Performance metrics for monitoring SVG loading and caching
class SvgPerformanceMetrics {
  final int cacheHits;
  final int cacheMisses;
  final int totalLoads;
  final int cacheEvictions;
  final int currentCacheSize;
  final int totalCacheMemoryBytes;
  final double averageLoadTime;
  final Map<String, int> assetLoadCounts;
  final Map<String, double> assetAverageLoadTimes;

  const SvgPerformanceMetrics({
    required this.cacheHits,
    required this.cacheMisses,
    required this.totalLoads,
    required this.cacheEvictions,
    required this.currentCacheSize,
    required this.totalCacheMemoryBytes,
    required this.averageLoadTime,
    required this.assetLoadCounts,
    required this.assetAverageLoadTimes,
  });

  double get cacheHitRatio => totalLoads > 0 ? cacheHits / totalLoads : 0.0;
  
  @override
  String toString() {
    return 'SvgPerformanceMetrics(hits: $cacheHits, misses: $cacheMisses, '
           'hitRatio: ${(cacheHitRatio * 100).toStringAsFixed(1)}%, '
           'cacheSize: $currentCacheSize, memoryMB: ${(totalCacheMemoryBytes / 1024 / 1024).toStringAsFixed(2)})';
  }
}

/// Centralized manager for all SVG assets in the application
/// Provides consistent loading, caching, and fallback mechanisms with advanced performance optimizations
class SvgAssetManager {
  // Advanced LRU cache with memory management
  static final LinkedHashMap<String, _CacheEntry> _cache = LinkedHashMap<String, _CacheEntry>();
  static const int _maxCacheSize = 50; // Maximum number of cached SVGs
  static const int _maxCacheMemoryBytes = 10 * 1024 * 1024; // 10MB memory limit
  
  // Performance tracking
  static int _cacheHits = 0;
  static int _cacheMisses = 0;
  static int _cacheEvictions = 0;
  static final Map<String, int> _assetLoadCounts = <String, int>{};
  static final Map<String, List<double>> _assetLoadTimes = <String, List<double>>{};
  
  // Preloading and batch loading
  static final Set<String> _preloadingAssets = <String>{};
  static final Map<String, Completer<String>> _loadingCompleters = <String, Completer<String>>{};
  
  static final Map<String, SvgAssetConfig> _assetConfigs = {
    'auth_header': SvgAssetConfig(
      path: 'assets/auth-header.svg',
      semanticLabel: 'Authentication header illustration',
      defaultSize: const Size(300, 200),
      fallback: FallbackComponents.authHeaderFallback(
        width: 300,
        height: 200,
        showMessage: true,
      ),
    ),
    'football_field': SvgAssetConfig(
      path: 'assets/icons8-football-field.svg',
      semanticLabel: 'Football field marker',
      defaultColor: Colors.green,
      defaultSize: const Size(32, 32),
      fallback: FallbackComponents.footballFieldFallback(
        size: 32,
        color: Colors.green,
        showLabel: true,
      ),
    ),
    'football_player': SvgAssetConfig(
      path: 'assets/icons8-football.svg',
      semanticLabel: 'Football player marker',
      defaultColor: Colors.orange,
      defaultSize: const Size(28, 28),
      fallback: FallbackComponents.footballPlayerFallback(
        size: 28,
        color: Colors.orange,
        showLabel: true,
      ),
    ),
    'goalkeeper': SvgAssetConfig(
      path: 'assets/icons8-goalkeeper-o-mais-baddy.svg',
      semanticLabel: 'Goalkeeper marker',
      defaultColor: Colors.blue,
      defaultSize: const Size(32, 32),
      fallback: FallbackComponents.goalkeeperFallback(
        size: 32,
        color: Colors.blue,
        showLabel: true,
      ),
    ),
  };

  /// Get an SVG asset widget by key with optional customization
  static Widget getAsset(
    String key, {
    double? width,
    double? height,
    Color? color,
    Widget? fallback,
    BoxFit fit = BoxFit.contain,
    Alignment alignment = Alignment.center,
    bool enableCaching = true,
    VoidCallback? onError,
  }) {
    final config = _assetConfigs[key];
    if (config == null) {
      ErrorLogger.logError(
        'SVG asset key "$key" not found in SvgAssetManager',
        StackTrace.current,
        context: 'SVG_ASSET_MANAGER',
        additionalData: {'requested_key': key, 'available_keys': _assetConfigs.keys.toList()},
      );
      return fallback ?? FallbackComponents.genericSvgFallback(
        width: width,
        height: height,
        color: color,
        label: 'Asset not found',
      );
    }

    return SvgErrorBoundary(
      assetPath: config.path,
      fallback: fallback ?? config.fallback,
      child: EnhancedWebSvgAsset(
        assetPath: config.path,
        width: width ?? config.defaultSize?.width,
        height: height ?? config.defaultSize?.height,
        color: color ?? config.defaultColor,
        fit: fit,
        fallback: fallback ?? config.fallback,
        alignment: alignment,
        semanticsLabel: config.semanticLabel,
        enableCaching: enableCaching && config.enableCaching,
        onError: () {
          ErrorLogger.logError(
            'SVG asset failed to load: ${config.path}',
            StackTrace.current,
            context: 'SVG_LOADING_ERROR',
            additionalData: {
              'asset_key': key,
              'asset_path': config.path,
              'cache_enabled': enableCaching && config.enableCaching,
            },
          );
          onError?.call();
        },
      ),
    );
  }

  /// Get the configuration for a specific asset
  static SvgAssetConfig? getConfig(String key) {
    return _assetConfigs[key];
  }

  /// Get all available asset keys
  static List<String> get availableAssets => _assetConfigs.keys.toList();

  /// Check if an asset exists
  static bool hasAsset(String key) => _assetConfigs.containsKey(key);

  /// Register a new asset configuration
  static void registerAsset(String key, SvgAssetConfig config) {
    _assetConfigs[key] = config;
  }

  /// Preload critical SVG assets for better performance
  static Future<void> preloadCriticalAssets() async {
    final criticalAssets = ['auth_header', 'football_field', 'goalkeeper'];
    await preloadAssets(criticalAssets);
  }

  /// Preload specific assets by keys
  static Future<void> preloadAssets(List<String> assetKeys) async {
    final futures = <Future<void>>[];
    
    for (final key in assetKeys) {
      final config = _assetConfigs[key];
      if (config != null && !_cache.containsKey(config.path)) {
        futures.add(_preloadSingleAsset(config.path));
      }
    }
    
    await Future.wait(futures);
  }

  /// Preload a single asset
  static Future<void> _preloadSingleAsset(String assetPath) async {
    if (_preloadingAssets.contains(assetPath) || _cache.containsKey(assetPath)) {
      return;
    }

    _preloadingAssets.add(assetPath);
    
    try {
      final stopwatch = Stopwatch()..start();
      final svgString = await rootBundle.loadString(assetPath);
      stopwatch.stop();
      
      _recordLoadTime(assetPath, stopwatch.elapsedMilliseconds.toDouble());
      _cacheSvgInternal(assetPath, svgString);
      
      ErrorLogger.logInfo(
        'Preloaded SVG asset: $assetPath',
        context: 'SVG_PRELOAD',
        additionalData: {
          'load_time_ms': stopwatch.elapsedMilliseconds,
          'size_bytes': svgString.length * 2, // Approximate UTF-16 size
        },
      );
    } catch (e) {
      ErrorLogger.logError(
        'Failed to preload SVG asset: $assetPath',
        StackTrace.current,
        context: 'SVG_PRELOAD_ERROR',
        additionalData: {'asset_path': assetPath},
      );
    } finally {
      _preloadingAssets.remove(assetPath);
    }
  }

  /// Get cached SVG string with LRU management
  static String? getCachedSvg(String path) {
    final entry = _cache[path];
    if (entry != null) {
      _cacheHits++;
      // Update access time and count for LRU
      final updatedEntry = entry.copyWith(
        lastAccessed: DateTime.now(),
        accessCount: entry.accessCount + 1,
      );
      _cache[path] = updatedEntry;
      // Move to end (most recently used)
      _cache.remove(path);
      _cache[path] = updatedEntry;
      return entry.svgString;
    }
    _cacheMisses++;
    return null;
  }

  /// Cache SVG string with advanced memory management
  static void cacheSvg(String path, String svgString) {
    _cacheSvgInternal(path, svgString);
  }

  static void _cacheSvgInternal(String path, String svgString) {
    final sizeInBytes = svgString.length * 2; // Approximate UTF-16 size
    final entry = _CacheEntry(
      svgString: svgString,
      lastAccessed: DateTime.now(),
      sizeInBytes: sizeInBytes,
    );

    // Remove existing entry if present
    _cache.remove(path);
    
    // Add new entry
    _cache[path] = entry;
    
    // Enforce cache limits
    _enforceCacheLimits();
  }

  /// Enforce cache size and memory limits with LRU eviction
  static void _enforceCacheLimits() {
    // Check memory limit first
    int totalMemory = _cache.values.fold(0, (sum, entry) => sum + entry.sizeInBytes);
    
    while (totalMemory > _maxCacheMemoryBytes && _cache.isNotEmpty) {
      final oldestKey = _cache.keys.first;
      final removedEntry = _cache.remove(oldestKey);
      if (removedEntry != null) {
        totalMemory -= removedEntry.sizeInBytes;
        _cacheEvictions++;
      }
    }
    
    // Check size limit
    while (_cache.length > _maxCacheSize) {
      final oldestKey = _cache.keys.first;
      _cache.remove(oldestKey);
      _cacheEvictions++;
    }
  }

  /// Remove specific asset from cache
  static void removeCachedSvg(String path) {
    _cache.remove(path);
  }

  /// Clear the entire SVG cache
  static void clearCache() {
    _cache.clear();
    _cacheHits = 0;
    _cacheMisses = 0;
    _cacheEvictions = 0;
    _assetLoadCounts.clear();
    _assetLoadTimes.clear();
  }

  /// Get current cache size
  static int get cacheSize => _cache.length;

  /// Get total cache memory usage in bytes
  static int get cacheMemoryUsage {
    return _cache.values.fold(0, (sum, entry) => sum + entry.sizeInBytes);
  }

  /// Get performance metrics
  static SvgPerformanceMetrics getPerformanceMetrics() {
    final totalLoads = _cacheHits + _cacheMisses;
    final assetAverageLoadTimes = <String, double>{};
    
    for (final entry in _assetLoadTimes.entries) {
      if (entry.value.isNotEmpty) {
        assetAverageLoadTimes[entry.key] = 
            entry.value.reduce((a, b) => a + b) / entry.value.length;
      }
    }
    
    final allLoadTimes = _assetLoadTimes.values
        .expand((times) => times)
        .toList();
    final averageLoadTime = allLoadTimes.isNotEmpty
        ? allLoadTimes.reduce((a, b) => a + b) / allLoadTimes.length
        : 0.0;

    return SvgPerformanceMetrics(
      cacheHits: _cacheHits,
      cacheMisses: _cacheMisses,
      totalLoads: totalLoads,
      cacheEvictions: _cacheEvictions,
      currentCacheSize: _cache.length,
      totalCacheMemoryBytes: cacheMemoryUsage,
      averageLoadTime: averageLoadTime,
      assetLoadCounts: Map.from(_assetLoadCounts),
      assetAverageLoadTimes: assetAverageLoadTimes,
    );
  }

  /// Record load time for performance tracking
  static void _recordLoadTime(String assetPath, double loadTimeMs) {
    _assetLoadCounts[assetPath] = (_assetLoadCounts[assetPath] ?? 0) + 1;
    _assetLoadTimes.putIfAbsent(assetPath, () => <double>[]).add(loadTimeMs);
    
    // Keep only last 10 load times per asset to prevent memory bloat
    final times = _assetLoadTimes[assetPath]!;
    if (times.length > 10) {
      times.removeRange(0, times.length - 10);
    }
  }

  /// Optimize cache by removing least used entries
  static void optimizeCache() {
    if (_cache.length <= _maxCacheSize ~/ 2) return;
    
    // Sort by access count and last accessed time
    final sortedEntries = _cache.entries.toList()
      ..sort((a, b) {
        final accessCountComparison = a.value.accessCount.compareTo(b.value.accessCount);
        if (accessCountComparison != 0) return accessCountComparison;
        return a.value.lastAccessed.compareTo(b.value.lastAccessed);
      });
    
    // Remove bottom 25% of entries
    final removeCount = _cache.length ~/ 4;
    for (int i = 0; i < removeCount && i < sortedEntries.length; i++) {
      _cache.remove(sortedEntries[i].key);
      _cacheEvictions++;
    }
    
    ErrorLogger.logInfo(
      'Cache optimized: removed $removeCount entries',
      context: 'SVG_CACHE_OPTIMIZATION',
      additionalData: {
        'removed_count': removeCount,
        'remaining_count': _cache.length,
        'memory_usage_mb': (cacheMemoryUsage / 1024 / 1024).toStringAsFixed(2),
      },
    );
  }

  /// Load SVG with performance tracking and deduplication
  static Future<String> loadSvgWithTracking(String assetPath) async {
    // Check if already loading
    if (_loadingCompleters.containsKey(assetPath)) {
      return _loadingCompleters[assetPath]!.future;
    }

    // Check cache first
    final cached = getCachedSvg(assetPath);
    if (cached != null) {
      return cached;
    }

    // Start loading
    final completer = Completer<String>();
    _loadingCompleters[assetPath] = completer;

    try {
      final stopwatch = Stopwatch()..start();
      final svgString = await rootBundle.loadString(assetPath);
      stopwatch.stop();

      _recordLoadTime(assetPath, stopwatch.elapsedMilliseconds.toDouble());
      _cacheSvgInternal(assetPath, svgString);
      
      completer.complete(svgString);
      return svgString;
    } catch (e) {
      completer.completeError(e);
      rethrow;
    } finally {
      _loadingCompleters.remove(assetPath);
    }
  }
}

/// Enhanced WebSvgAsset widget with improved error handling and caching
class EnhancedWebSvgAsset extends StatefulWidget {
  final String assetPath;
  final double? width;
  final double? height;
  final Color? color;
  final BoxFit fit;
  final Widget? fallback;
  final Alignment alignment;
  final String? semanticsLabel;
  final bool enableCaching;
  final VoidCallback? onError;
  final Duration? loadingTimeout;

  const EnhancedWebSvgAsset({
    super.key,
    required this.assetPath,
    this.width,
    this.height,
    this.color,
    this.fit = BoxFit.contain,
    this.fallback,
    this.alignment = Alignment.center,
    this.semanticsLabel,
    this.enableCaching = true,
    this.onError,
    this.loadingTimeout = const Duration(seconds: 10),
  });

  @override
  State<EnhancedWebSvgAsset> createState() => _EnhancedWebSvgAssetState();
}

class _EnhancedWebSvgAssetState extends State<EnhancedWebSvgAsset> {
  bool _hasError = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return _buildFallback();
    }

    // Check cache first if caching is enabled
    if (widget.enableCaching) {
      final cachedSvg = SvgAssetManager.getCachedSvg(widget.assetPath);
      if (cachedSvg != null) {
        return _buildSvgWidget(cachedSvg);
      }
    }

    return FutureBuilder<String>(
      future: _loadSvgWithTimeout(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          // Cache the loaded SVG if caching is enabled
          if (widget.enableCaching) {
            SvgAssetManager.cacheSvg(widget.assetPath, snapshot.data!);
          }
          return _buildSvgWidget(snapshot.data!);
        } else if (snapshot.hasError) {
          _handleError('Error loading SVG: ${snapshot.error}');
          return _buildFallback();
        }
        
        // Loading state
        return _buildLoadingPlaceholder();
      },
    );
  }

  Future<String> _loadSvgWithTimeout() async {
    try {
      // Use the performance tracking loader if caching is enabled
      if (widget.enableCaching) {
        return await SvgAssetManager.loadSvgWithTracking(widget.assetPath);
      }
      
      // Fallback to direct loading without tracking
      final future = DefaultAssetBundle.of(context).loadString(widget.assetPath);
      if (widget.loadingTimeout != null) {
        return await future.timeout(widget.loadingTimeout!);
      }
      return await future;
    } catch (e) {
      throw Exception('Failed to load SVG asset: $e');
    }
  }

  Widget _buildSvgWidget(String svgString) {
    try {
      return SvgPicture.string(
        svgString,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        colorFilter: widget.color != null 
            ? ColorFilter.mode(widget.color!, BlendMode.srcIn)
            : null,
        alignment: widget.alignment,
        semanticsLabel: widget.semanticsLabel,
        placeholderBuilder: (_) => _buildLoadingPlaceholder(),
      );
    } catch (e) {
      _handleError('Error parsing SVG: $e');
      return _buildFallback();
    }
  }

  void _handleError(String message) {
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _hasError = true;
            _errorMessage = message;
          });
        }
      });
    }
    
    debugPrint('EnhancedWebSvgAsset Error: $message for asset ${widget.assetPath}');
    widget.onError?.call();
    
    // Remove corrupted cache entry
    if (widget.enableCaching) {
      SvgAssetManager.removeCachedSvg(widget.assetPath);
    }
  }

  Widget _buildFallback() {
    return widget.fallback ?? _buildDefaultFallback();
  }

  Widget _buildDefaultFallback() {
    return Container(
      width: widget.width,
      height: widget.height,
      alignment: widget.alignment,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.broken_image,
            size: (widget.width != null && widget.height != null) 
                ? (widget.width! + widget.height!) / 4 
                : 24,
            color: Colors.grey.shade400,
          ),
          if (widget.semanticsLabel != null) ...[
            const SizedBox(height: 4),
            Text(
              'Image unavailable',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingPlaceholder() {
    return Container(
      width: widget.width,
      height: widget.height,
      alignment: widget.alignment,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.grey.shade400),
        ),
      ),
    );
  }
}

/// Extension for easier SVG asset loading with enhanced features
extension EnhancedSvgAssetExtension on String {
  /// Load this string as an SVG asset path with enhanced features
  Widget toEnhancedSvgAsset({
    double? width,
    double? height,
    Color? color,
    BoxFit fit = BoxFit.contain,
    Widget? fallback,
    Alignment alignment = Alignment.center,
    String? semanticsLabel,
    bool enableCaching = true,
    VoidCallback? onError,
  }) {
    return EnhancedWebSvgAsset(
      assetPath: this,
      width: width,
      height: height,
      color: color,
      fit: fit,
      fallback: fallback,
      alignment: alignment,
      semanticsLabel: semanticsLabel,
      enableCaching: enableCaching,
      onError: onError,
    );
  }
}
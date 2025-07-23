import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'svg_asset_manager.dart';

/// A widget that loads SVG assets properly for web compatibility
/// Uses DefaultAssetBundle.loadString for web compatibility
/// 
/// This is the legacy version maintained for backward compatibility.
/// For new implementations, consider using EnhancedWebSvgAsset or SvgAssetManager.
class WebSvgAsset extends StatefulWidget {
  final String assetPath;
  final double? width;
  final double? height;
  final BoxFit fit;
  final ColorFilter? colorFilter;
  final Widget? placeholder;
  final Alignment alignment;
  final String? semanticsLabel;
  final bool enableCaching;
  final VoidCallback? onError;
  final Duration? loadingTimeout;

  const WebSvgAsset({
    super.key,
    required this.assetPath,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.colorFilter,
    this.placeholder,
    this.alignment = Alignment.center,
    this.semanticsLabel,
    this.enableCaching = true,
    this.onError,
    this.loadingTimeout = const Duration(seconds: 10),
  });

  @override
  State<WebSvgAsset> createState() => _WebSvgAssetState();
}

class _WebSvgAssetState extends State<WebSvgAsset> {
  bool _hasError = false;
  String? _errorMessage;
  int _retryCount = 0;
  static const int _maxRetries = 2;

  @override
  Widget build(BuildContext context) {
    if (_hasError && _retryCount >= _maxRetries) {
      return _buildFallback();
    }

    // Check cache first if caching is enabled
    if (widget.enableCaching) {
      final cachedSvg = SvgAssetManager.getCachedSvg(widget.assetPath);
      if (cachedSvg != null && !_hasError) {
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
          
          // Reset error state on successful load
          if (_hasError) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _hasError = false;
                  _errorMessage = null;
                });
              }
            });
          }
          
          return _buildSvgWidget(snapshot.data!);
        } else if (snapshot.hasError) {
          _handleError('Error loading SVG: ${snapshot.error}');
          return _buildFallback();
        }
        
        // Loading state
        return widget.placeholder ?? _buildLoadingPlaceholder();
      },
    );
  }

  Future<String> _loadSvgWithTimeout() async {
    try {
      final future = DefaultAssetBundle.of(context).loadString(widget.assetPath);
      if (widget.loadingTimeout != null) {
        return await future.timeout(widget.loadingTimeout!);
      }
      return await future;
    } catch (e) {
      // Implement retry logic for network-related failures
      if (_retryCount < _maxRetries && _isRetryableError(e)) {
        _retryCount++;
        await Future.delayed(Duration(milliseconds: 500 * _retryCount));
        return _loadSvgWithTimeout();
      }
      throw Exception('Failed to load SVG asset after $_retryCount retries: $e');
    }
  }

  bool _isRetryableError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('network') || 
           errorString.contains('timeout') || 
           errorString.contains('connection');
  }

  Widget _buildSvgWidget(String svgString) {
    try {
      return SvgPicture.string(
        svgString,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        colorFilter: widget.colorFilter,
        alignment: widget.alignment,
        semanticsLabel: widget.semanticsLabel ?? _generateSemanticLabel(),
        placeholderBuilder: widget.placeholder != null ? (_) => widget.placeholder! : null,
      );
    } catch (e) {
      _handleError('Error parsing SVG: $e');
      return _buildFallback();
    }
  }

  String? _generateSemanticLabel() {
    if (widget.semanticsLabel != null) return widget.semanticsLabel;
    
    // Generate semantic label from asset path
    final fileName = widget.assetPath.split('/').last.split('.').first;
    return fileName.replaceAll('-', ' ').replaceAll('_', ' ');
  }

  void _handleError(String message) {
    if (mounted) {
      setState(() {
        _hasError = true;
        _errorMessage = message;
      });
    }
    
    debugPrint('WebSvgAsset Error: $message for asset ${widget.assetPath}');
    widget.onError?.call();
    
    // Remove corrupted cache entry
    if (widget.enableCaching) {
      SvgAssetManager.removeCachedSvg(widget.assetPath);
    }
  }

  Widget _buildFallback() {
    return widget.placeholder ?? _buildEnhancedFallback();
  }

  Widget _buildEnhancedFallback() {
    return Container(
      width: widget.width,
      height: widget.height,
      alignment: widget.alignment,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300, width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_not_supported_outlined,
            size: _calculateFallbackIconSize(),
            color: Colors.grey.shade400,
          ),
          if (widget.semanticsLabel != null || _shouldShowErrorText()) ...[
            const SizedBox(height: 4),
            Text(
              widget.semanticsLabel ?? 'Image unavailable',
              style: TextStyle(
                fontSize: _calculateFallbackTextSize(),
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  double _calculateFallbackIconSize() {
    if (widget.width != null && widget.height != null) {
      return (widget.width! + widget.height!) / 4;
    }
    return 24;
  }

  double _calculateFallbackTextSize() {
    if (widget.width != null && widget.height != null) {
      final avgSize = (widget.width! + widget.height!) / 2;
      return (avgSize / 8).clamp(8.0, 12.0);
    }
    return 10;
  }

  bool _shouldShowErrorText() {
    return widget.width != null && widget.height != null && 
           widget.width! > 40 && widget.height! > 40;
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

/// Extension for easier SVG asset loading
extension SvgAssetExtension on String {
  /// Load this string as an SVG asset path with web compatibility
  Widget toSvgAsset({
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
    ColorFilter? colorFilter,
    Widget? placeholder,
    Alignment alignment = Alignment.center,
    String? semanticsLabel,
  }) {
    return WebSvgAsset(
      assetPath: this,
      width: width,
      height: height,
      fit: fit,
      colorFilter: colorFilter,
      placeholder: placeholder,
      alignment: alignment,
      semanticsLabel: semanticsLabel,
    );
  }
}

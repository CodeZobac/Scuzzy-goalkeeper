import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// A widget that loads SVG assets properly for web compatibility
/// Uses DefaultAssetBundle.loadString for web compatibility
class WebSvgAsset extends StatelessWidget {
  final String assetPath;
  final double? width;
  final double? height;
  final BoxFit fit;
  final ColorFilter? colorFilter;
  final Widget? placeholder;
  final Alignment alignment;
  final String? semanticsLabel;

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
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: DefaultAssetBundle.of(context).loadString(assetPath),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          try {
            return SvgPicture.string(
              snapshot.data!,
              width: width,
              height: height,
              fit: fit,
              colorFilter: colorFilter,
              alignment: alignment,
              semanticsLabel: semanticsLabel,
              placeholderBuilder: placeholder != null ? (_) => placeholder! : null,
            );
          } catch (e) {
            // If SVG parsing fails, show placeholder or fallback
            return _buildFallback();
          }
        } else if (snapshot.hasError) {
          debugPrint('Error loading SVG asset $assetPath: ${snapshot.error}');
          return _buildFallback();
        }
        
        // Loading state
        return placeholder ?? _buildLoadingPlaceholder();
      },
    );
  }

  Widget _buildFallback() {
    return placeholder ?? _buildLoadingPlaceholder();
  }

  Widget _buildLoadingPlaceholder() {
    return Container(
      width: width,
      height: height,
      alignment: alignment,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
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

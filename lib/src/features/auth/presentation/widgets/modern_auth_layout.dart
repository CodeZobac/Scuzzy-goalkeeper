import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import '../theme/app_theme.dart';

class ModernAuthLayout extends StatefulWidget {
  final Widget child;
  final String title;
  final String subtitle;
  final bool showBackButton;
  final String? heroImagePath;

  const ModernAuthLayout({
    super.key,
    required this.child,
    required this.title,
    required this.subtitle,
    this.showBackButton = false,
    this.heroImagePath,
  });

  @override
  State<ModernAuthLayout> createState() => _ModernAuthLayoutState();
}

class _ModernAuthLayoutState extends State<ModernAuthLayout>
    with TickerProviderStateMixin {
  late AnimationController _headerController;
  late AnimationController _cardController;
  late AnimationController _contentController;
  
  late Animation<double> _headerFadeAnimation;
  late Animation<Offset> _headerSlideAnimation;
  late Animation<double> _cardScaleAnimation;
  late Animation<double> _cardFadeAnimation;
  late Animation<double> _contentFadeAnimation;
  late Animation<Offset> _contentSlideAnimation;

  @override
  void initState() {
    super.initState();
    
    _headerController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _cardController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _contentController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _headerFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _headerController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    _headerSlideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _headerController,
      curve: const Interval(0.0, 0.8, curve: Curves.easeOutBack),
    ));

    _cardScaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _cardController,
      curve: Curves.easeOutBack,
    ));

    _cardFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _cardController,
      curve: Curves.easeOut,
    ));

    _contentFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _contentController,
      curve: Curves.easeOut,
    ));

    _contentSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _contentController,
      curve: Curves.easeOutCubic,
    ));

    // Start animations with staggered delays
    _headerController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _cardController.forward();
    });
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _contentController.forward();
    });
  }

  @override
  void dispose() {
    _headerController.dispose();
    _cardController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isDesktop = screenSize.width > 900; // Fullscreen/desktop
    final isTablet = screenSize.width > 600;
    final isMobile = screenSize.width <= 600;

    return Scaffold(
      backgroundColor: AppTheme.authBackground,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.authBackground,
              Color(0xFFF0F4F3),
            ],
          ),
        ),
        child: SafeArea(
          child: isDesktop 
            ? _buildDesktopLayout(context)
            : _buildMobileLayout(context, isTablet),
        ),
      ),
    );
  }

  /// Desktop layout with image on the left side, form on the right
  Widget _buildDesktopLayout(BuildContext context) {
    return AnimatedBuilder(
      animation: _headerController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _headerFadeAnimation,
          child: Row(
            children: [
              // Left side - Image
              Expanded(
                flex: 5,
                child: _buildResponsiveAuthImage(context, isDesktop: true),
              ),
              // Right side - Form
              Expanded(
                flex: 4,
                child: Container(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Back button if needed
                      if (widget.showBackButton) ...[
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.authPrimaryGreen.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppTheme.authPrimaryGreen.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: Icon(
                              Icons.arrow_back_ios_new,
                              color: AppTheme.authPrimaryGreen,
                              size: 18,
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                      
                      // Title
                      Text(
                        widget.title,
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.authPrimaryGreen,
                          height: 1.2,
                          letterSpacing: -0.5,
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Subtitle
                      Text(
                        widget.subtitle,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w400,
                          color: AppTheme.authPrimaryGreen.withOpacity(0.7),
                          height: 1.5,
                          letterSpacing: 0.1,
                        ),
                      ),
                      
                      const SizedBox(height: 40),
                      
                      // Form content
                      Flexible(
                        child: _buildFormCard(context, isDesktop: true),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Mobile layout with image on top, form below
  Widget _buildMobileLayout(BuildContext context, bool isTablet) {
    return Column(
      children: [
        _buildHeader(context, isTablet),
        Expanded(
          child: _buildContent(context, isTablet),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, bool isTablet) {
    return AnimatedBuilder(
      animation: _headerController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _headerFadeAnimation,
          child: SlideTransition(
            position: _headerSlideAnimation,
            child: Stack(
              children: [
                // PNG Header with enhanced integration and responsive sizing
                _buildResponsiveAuthImage(context, isDesktop: false),
                
                // Overlay content
                SizedBox(
                  height: isTablet ? 280 : 240,
                  width: double.infinity,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      32, 
                      isTablet ? 50 : 40, // top ajustado
                      32, 
                      isTablet ? 28 : 24  // bottom reduzido
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Back button if needed
                        if (widget.showBackButton) ...[
                          GestureDetector(
                            onTap: () => Navigator.of(context).pop(),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.1),
                                  width: 1,
                                ),
                              ),
                              child: const Icon(
                                Icons.arrow_back_ios_new,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                        
                        const Spacer(),
                        
                        // Title with better typography
                        Text(
                          widget.title,
                          style: TextStyle(
                            fontSize: isTablet ? 34 : 28,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            height: 1.2,
                            letterSpacing: -0.5,
                          ),
                        ),
                        
                        const SizedBox(height: 12),
                        
                        // Subtitle with improved styling
                        Text(
                          widget.subtitle,
                          style: TextStyle(
                            fontSize: isTablet ? 18 : 16,
                            fontWeight: FontWeight.w400,
                            color: Colors.white.withOpacity(0.9),
                            height: 1.5,
                            letterSpacing: 0.1,
                          ),
                        ),
                        
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Builds a responsive authentication image with PNG
  /// Handles different screen sizes and provides graceful fallback
  Widget _buildResponsiveAuthImage(BuildContext context, {required bool isDesktop}) {
    final screenSize = MediaQuery.of(context).size;
    final imageHeight = isDesktop ? double.infinity : (screenSize.width > 600 ? 280.0 : 240.0);
    
    debugPrint('🖼️ Attempting to load auth header PNG for ${isDesktop ? 'desktop' : 'mobile'}');
    debugPrint('📏 Screen size: ${screenSize.width}x${screenSize.height}');
    
    return Container(
      height: isDesktop ? null : imageHeight,
      width: double.infinity,
      child: _buildImageWithFallback(imageHeight, screenSize.width, isDesktop),
    );
  }

  /// Builds the form card for desktop layout
  Widget _buildFormCard(BuildContext context, {required bool isDesktop}) {
    return AnimatedBuilder(
      animation: _cardController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _cardFadeAnimation,
          child: ScaleTransition(
            scale: _cardScaleAnimation,
            child: Material(
              elevation: isDesktop ? 8 : 12,
              shadowColor: AppTheme.authPrimaryGreen.withOpacity(0.2),
              borderRadius: BorderRadius.circular(24),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppTheme.authCardBackground,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppTheme.authPrimaryGreen.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: AnimatedBuilder(
                  animation: _contentController,
                  builder: (context, child) {
                    return FadeTransition(
                      opacity: _contentFadeAnimation,
                      child: SlideTransition(
                        position: _contentSlideAnimation,
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: widget.child,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildImageWithFallback(double height, double width, bool isDesktop) {
    debugPrint('🎨 Loading image for ${isDesktop ? 'desktop' : 'mobile'} layout');
    debugPrint('🌐 Running on web: ${kIsWeb}');
    
    // Different fit strategies for desktop vs mobile
    final BoxFit imageFit = isDesktop ? BoxFit.cover : BoxFit.cover;
    
    return ClipRRect(
      borderRadius: isDesktop 
        ? const BorderRadius.only(
            topRight: Radius.circular(24),
            bottomRight: Radius.circular(24),
          )
        : BorderRadius.zero,
      child: kIsWeb 
        ? _buildWebImage(height, width, isDesktop, imageFit)
        : _buildNativeImage(height, width, isDesktop, imageFit),
    );
  }

  /// Web-specific image loading with better error handling
  Widget _buildWebImage(double height, double width, bool isDesktop, BoxFit imageFit) {
    debugPrint('🌐 Attempting web image load');
    
    // Try PNG first with detailed debugging
    debugPrint('🎯 Attempting PNG load on web');
    debugPrint('📍 Asset path: assets/auth-header-original.png');
    debugPrint('📐 Dimensions: ${width}x${isDesktop ? 'auto' : height}');
    
    return Image.asset(
      'assets/auth-header-original.png',
      width: width,
      height: isDesktop ? null : height,
      fit: imageFit,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          debugPrint('✅ PNG loaded successfully on web!');
          return child;
        }
        debugPrint('⏳ PNG loading progress: ${loadingProgress.cumulativeBytesLoaded}/${loadingProgress.expectedTotalBytes}');
        return _buildLoadingContainer(height, width, isDesktop);
      },
      errorBuilder: (context, pngError, pngStackTrace) {
        debugPrint('❌ PNG failed on web: $pngError');
        debugPrint('📚 Stack trace: $pngStackTrace');
        
        // Fallback to SVG
        debugPrint('🔄 Falling back to SVG');
        return Image.asset(
          'assets/auth-header.svg',
          width: width,
          height: isDesktop ? null : height,
          fit: imageFit,
          errorBuilder: (context, svgError, svgStackTrace) {
            debugPrint('❌ SVG also failed: $svgError');
            return _buildFallbackWithMessage(isDesktop ? 400 : height, isDesktop);
          },
        );
      },
    );
  }

  /// Native platform image loading
  Widget _buildNativeImage(double height, double width, bool isDesktop, BoxFit imageFit) {
    return Image.asset(
      'assets/auth-header-original.png',
      width: width,
      height: isDesktop ? null : height,
      fit: imageFit,
      errorBuilder: (context, error, stackTrace) {
        debugPrint('❌ Native Image.asset failed: $error');
        return _buildFallbackWithMessage(isDesktop ? 400 : height, isDesktop);
      },
    );
  }

  /// Loading container with spinner
  Widget _buildLoadingContainer(double height, double width, bool isDesktop) {
    return Container(
      height: isDesktop ? 400 : height,
      width: width,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.authPrimaryGreen.withOpacity(0.1),
            AppTheme.authSecondaryGreen.withOpacity(0.1),
          ],
        ),
      ),
      child: const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.authPrimaryGreen),
        ),
      ),
    );
  }



  /// Builds a graceful fallback when auth-header.png fails to load
  Widget _buildHeaderFallback(double height, bool isDesktop) {
    return Container(
      height: isDesktop ? null : height,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.authPrimaryGreen,
            AppTheme.authSecondaryGreen,
          ],
        ),
        borderRadius: isDesktop 
          ? const BorderRadius.only(
              topRight: Radius.circular(24),
              bottomRight: Radius.circular(24),
            )
          : BorderRadius.zero,
      ),
      child: CustomPaint(
        painter: BackgroundPatternPainter(),
        child: const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Color(0x1A4CAF50), // AppTheme.authPrimaryGreen with 0.1 alpha
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  /// Builds a fallback with debug message
  Widget _buildFallbackWithMessage(double height, bool isDesktop) {
    return Container(
      height: isDesktop ? null : height,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.authPrimaryGreen,
            AppTheme.authSecondaryGreen,
          ],
        ),
        borderRadius: isDesktop 
          ? const BorderRadius.only(
              topRight: Radius.circular(24),
              bottomRight: Radius.circular(24),
            )
          : BorderRadius.zero,
      ),
      child: Stack(
        children: [
          CustomPaint(
            painter: BackgroundPatternPainter(),
            child: const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Color(0x1A4CAF50),
                  ],
                ),
              ),
            ),
          ),
          if (kDebugMode)
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'PNG Image loading failed\nUsing fallback design\n${isDesktop ? 'Desktop' : 'Mobile'} layout',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, bool isTablet) {
    return AnimatedBuilder(
      animation: _cardController,
      builder: (context, child) {
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            isTablet ? 40 : 24, // left
            12, // top - minimal spacing
            isTablet ? 40 : 24, // right
            24, // bottom
          ),
          child: FadeTransition(
            opacity: _cardFadeAnimation,
            child: ScaleTransition(
              scale: _cardScaleAnimation,
              child: Material(
                elevation: 12,
                shadowColor: AppTheme.authPrimaryGreen.withOpacity(0.2),
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppTheme.authCardBackground,
                    borderRadius: BorderRadius.circular(24),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.authCardBackground,
                        AppTheme.authCardBackground.withOpacity(0.98),
                      ],
                    ),
                    border: Border.all(
                      color: AppTheme.authPrimaryGreen.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: AnimatedBuilder(
                    animation: _contentController,
                    builder: (context, child) {
                      return FadeTransition(
                        opacity: _contentFadeAnimation,
                        child: SlideTransition(
                          position: _contentSlideAnimation,
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(
                              isTablet ? 32 : 28, // left - more padding
                              isTablet ? 32 : 28, // top - more padding
                              isTablet ? 32 : 28, // right - more padding
                              isTablet ? 32 : 28, // bottom - consistent padding
                            ),
                            child: widget.child,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// Custom painter for background pattern
class BackgroundPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..style = PaintingStyle.fill;

    // Draw subtle geometric pattern
    for (int i = 0; i < 6; i++) {
      for (int j = 0; j < 4; j++) {
        final x = (size.width / 6) * i + (j % 2) * 30;
        final y = (size.height / 4) * j;
        
        // Draw hexagon pattern
        final path = Path();
        const radius = 15.0;
        for (int k = 0; k < 6; k++) {
          final angle = (k * 60) * (3.14159 / 180);
          final px = x + radius * cos(angle);
          final py = y + radius * sin(angle);
          if (k == 0) {
            path.moveTo(px, py);
          } else {
            path.lineTo(px, py);
          }
        }
        path.close();
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

import 'package:flutter/material.dart';
import 'dart:math';
import '../theme/app_theme.dart';
import '../../../../shared/widgets/svg_asset_manager.dart';
import '../../../../shared/utils/responsive_utils.dart';

class ResponsiveAuthLayout extends StatefulWidget {
  final Widget child;
  final String title;
  final String subtitle;
  final bool showBackButton;
  final String? heroImagePath;

  const ResponsiveAuthLayout({
    super.key,
    required this.child,
    required this.title,
    required this.subtitle,
    this.showBackButton = false,
    this.heroImagePath,
  });

  @override
  State<ResponsiveAuthLayout> createState() => _ResponsiveAuthLayoutState();
}

class _ResponsiveAuthLayoutState extends State<ResponsiveAuthLayout>
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

    _setupAnimations();
    _startAnimations();
  }

  void _setupAnimations() {
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
  }

  void _startAnimations() {
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
          child: _buildResponsiveLayout(context),
        ),
      ),
    );
  }

  Widget _buildResponsiveLayout(BuildContext context) {
    if (context.isDesktop) {
      return _buildDesktopLayout(context);
    } else if (context.isTablet) {
      return _buildTabletLayout(context);
    } else {
      return _buildMobileLayout(context);
    }
  }

  /// Desktop layout with side-by-side header and form
  Widget _buildDesktopLayout(BuildContext context) {
    return Row(
      children: [
        // Left side - Header
        Expanded(
          flex: 3,
          child: _buildHeader(context),
        ),
        // Right side - Form
        Expanded(
          flex: 2,
          child: Container(
            padding: const EdgeInsets.all(40),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: _buildFormCard(context),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Tablet layout with stacked header and form
  Widget _buildTabletLayout(BuildContext context) {
    return Column(
      children: [
        _buildHeader(context),
        Expanded(
          child: SingleChildScrollView(
            padding: context.authPadding,
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: context.authContentWidth),
                child: _buildFormCard(context),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Mobile layout optimized for small screens
  Widget _buildMobileLayout(BuildContext context) {
    return Column(
      children: [
        _buildHeader(context),
        Expanded(
          child: SingleChildScrollView(
            padding: context.authPadding.copyWith(
              // Reduce top padding when keyboard is visible
              top: context.isKeyboardVisible ? 8 : context.authPadding.top,
            ),
            child: _buildFormCard(context),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, {double? height}) {
    final screenWidth = MediaQuery.of(context).size.width;
    final headerHeight = height ?? (screenWidth * 9 / 16); // Assuming 16:9 aspect ratio

    return AnimatedBuilder(
      animation: _headerController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _headerFadeAnimation,
          child: SlideTransition(
            position: _headerSlideAnimation,
            child: _buildResponsiveAuthHeader(context, headerHeight),
          ),
        );
      },
    );
  }

  Widget _buildResponsiveAuthHeader(BuildContext context, double headerHeight) {
    final screenSize = MediaQuery.of(context).size;
    
    return SizedBox(
      width: double.infinity,
      height: headerHeight,
      child: Image.asset(
        'assets/auth-header-original.png',
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _buildHeaderFallback(double height) {
    return Container(
      height: height,
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
                Color(0x1A4CAF50),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderOverlay(BuildContext context, double headerHeight) {
    return SizedBox(
      height: headerHeight,
      width: double.infinity,
      child: Padding(
        padding: ResponsiveUtils.getResponsiveValue(
          context,
          mobile: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          tablet: const EdgeInsets.fromLTRB(40, 30, 40, 32),
          desktop: const EdgeInsets.fromLTRB(60, 40, 60, 40),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.showBackButton) ...[
              _buildBackButton(context),
              SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, mobile: 20)),
            ],
            const Spacer(),
            _buildHeaderText(context),
            SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, mobile: 24)),
          ],
        ),
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Container(
        padding: ResponsiveUtils.getResponsiveValue(
          context,
          mobile: const EdgeInsets.all(12),
          tablet: const EdgeInsets.all(14),
          desktop: const EdgeInsets.all(16),
        ),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Icon(
          Icons.arrow_back_ios_new,
          color: Colors.white,
          size: ResponsiveUtils.getResponsiveValue(
            context,
            mobile: 18.0,
            tablet: 20.0,
            desktop: 22.0,
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderText(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.title,
          style: TextStyle(
            fontSize: ResponsiveUtils.getResponsiveFontSize(
              context,
              mobile: 28,
              tablet: 34,
              desktop: 40,
            ),
            fontWeight: FontWeight.w700,
            color: Colors.white,
            height: 1.2,
            letterSpacing: -0.5,
          ),
        ),
        SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, mobile: 12)),
        Text(
          widget.subtitle,
          style: TextStyle(
            fontSize: ResponsiveUtils.getResponsiveFontSize(
              context,
              mobile: 16,
              tablet: 18,
              desktop: 20,
            ),
            fontWeight: FontWeight.w400,
            color: Colors.white.withOpacity(0.9),
            height: 1.5,
            letterSpacing: 0.1,
          ),
        ),
      ],
    );
  }

  Widget _buildFormCard(BuildContext context) {
    return AnimatedBuilder(
      animation: _cardController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _cardFadeAnimation,
          child: ScaleTransition(
            scale: _cardScaleAnimation,
            child: Material(
              elevation: ResponsiveUtils.getResponsiveElevation(context),
              shadowColor: AppTheme.authPrimaryGreen.withOpacity(0.2),
              borderRadius: context.responsiveBorderRadius,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppTheme.authCardBackground,
                  borderRadius: context.responsiveBorderRadius,
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
                          padding: ResponsiveUtils.getResponsiveValue(
                            context,
                            mobile: const EdgeInsets.all(28),
                            tablet: const EdgeInsets.all(32),
                            desktop: const EdgeInsets.all(40),
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
        );
      },
    );
  }
}

class BackgroundPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 6; i++) {
      for (int j = 0; j < 4; j++) {
        final x = (size.width / 6) * i + (j % 2) * 30;
        final y = (size.height / 4) * j;
        
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

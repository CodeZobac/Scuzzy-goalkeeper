import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../../../../shared/utils/responsive_utils.dart';

class MobileAnimatedAuthLayout extends StatefulWidget {
  final Widget child;
  final String title;
  final String subtitle;
  final bool showBackButton;

  const MobileAnimatedAuthLayout({
    super.key,
    required this.child,
    required this.title,
    required this.subtitle,
    this.showBackButton = false,
  });

  @override
  State<MobileAnimatedAuthLayout> createState() => _MobileAnimatedAuthLayoutState();
}

class _MobileAnimatedAuthLayoutState extends State<MobileAnimatedAuthLayout> {
  bool _showHeader = true;

  @override
  void initState() {
    super.initState();
    _startHeaderAnimation();
  }

  void _startHeaderAnimation() async {
    // Wait a bit for the widget to be built
    await Future.delayed(const Duration(milliseconds: 100));
    
    // Wait for 3 seconds while header is visible
    await Future.delayed(const Duration(seconds: 3));
    
    // Start the fade out process
    setState(() {
      _showHeader = false;
    });
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
        child: _buildMobileLayout(context),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    final headerHeight = context.authHeaderHeight;
    
    return Stack(
      children: [
        // Main content column
        Column(
          children: [
            // Header section with smooth height and fade animation
            AnimatedContainer(
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeInOutCubic,
              height: _showHeader ? headerHeight : 0,
              child: ClipRect(
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeInOut,
                  opacity: _showHeader ? 1.0 : 0.0,
                  child: _showHeader 
                    ? _buildAnimatedHeader(context)
                    : SizedBox(
                        width: double.infinity,
                        height: headerHeight,
                        child: Image.asset(
                          'assets/auth-header-original.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                ),
              ),
            ),
            
            // Form section that expands smoothly
            Expanded(
              child: SafeArea(
                child: AnimatedPadding(
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeInOutCubic,
                  padding: EdgeInsets.only(
                    left: 24,
                    right: 24,
                    top: _showHeader ? 16 : 32,
                    bottom: 24,
                  ),
                  child: SingleChildScrollView(
                    child: _buildFormCard(context),
                  ),
                ),
              ),
            ),
          ],
        ),
        
        // Back button overlay (if needed)
        if (widget.showBackButton)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  _buildBackButton(context),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAnimatedHeader(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: context.authHeaderHeight,
      child: Image.asset(
        'assets/auth-header-original.png',
        fit: BoxFit.cover,
      ),
    )
      .animate()
      .fadeIn(
        duration: 800.ms,
        curve: Curves.easeOut,
      )
      .slideY(
        begin: -0.3,
        end: 0,
        duration: 800.ms,
        curve: Curves.easeOutBack,
      );
  }

  Widget _buildBackButton(BuildContext context) {
    return GestureDetector(
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
    )
      .animate()
      .fadeIn(
        delay: 200.ms,
        duration: 400.ms,
      )
      .slideX(
        begin: -0.5,
        end: 0,
        delay: 200.ms,
        duration: 400.ms,
        curve: Curves.easeOut,
      );
  }

  Widget _buildFormCard(BuildContext context) {
    return Material(
      elevation: 12,
      shadowColor: AppTheme.authPrimaryGreen.withOpacity(0.2),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppTheme.authCardBackground,
          borderRadius: BorderRadius.circular(20),
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
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: widget.child,
        ),
      ),
    )
      .animate()
      .fadeIn(
        delay: 1000.ms, // Show after header starts appearing
        duration: 600.ms,
        curve: Curves.easeOut,
      )
      .slideY(
        begin: 0.2,
        end: 0,
        delay: 1000.ms,
        duration: 600.ms,
        curve: Curves.easeOutCubic,
      )
      .scaleXY(
        begin: 0.95,
        end: 1,
        delay: 1000.ms,
        duration: 600.ms,
        curve: Curves.easeOutBack,
      );
  }
}
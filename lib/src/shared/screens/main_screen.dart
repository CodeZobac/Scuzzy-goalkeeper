import 'package:flutter/material.dart';
import 'package:goalkeeper/src/shared/screens/main_screen_content.dart';
import '../../features/auth/presentation/theme/app_theme.dart';
import '../../features/user_profile/presentation/screens/profile_screen.dart';
import '../widgets/app_navbar.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  NavbarItem _selectedItem = NavbarItem.home;
  late AnimationController _contentAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _contentAnimationController = AnimationController(
      duration: AppTheme.mediumAnimation,
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _contentAnimationController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.3, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _contentAnimationController,
      curve: Curves.easeOutCubic,
    ));
    
    _contentAnimationController.forward();
  }

  @override
  void dispose() {
    _contentAnimationController.dispose();
    super.dispose();
  }

  void _onNavbarTap(NavbarItem item) {
    if (item != _selectedItem) {
      _contentAnimationController.reverse().then((_) {
        setState(() {
          _selectedItem = item;
        });
        _contentAnimationController.forward();
      });
    }
  }

  Widget _buildContent() {
    switch (_selectedItem) {
      case NavbarItem.home:
        return HomeContent();
      case NavbarItem.search:
        return SearchContent();
      case NavbarItem.team:
        return TeamContent();
      case NavbarItem.profile:
        return const ProfileScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBackground,
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.primaryGradient,
        ),
        child: SafeArea(
          child: AnimatedBuilder(
            animation: _contentAnimationController,
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: _buildContent(),
                ),
              );
            },
          ),
        ),
      ),
      bottomNavigationBar: AppNavbar(
        selectedItem: _selectedItem,
        onItemSelected: _onNavbarTap,
      ),
    );
  }
}

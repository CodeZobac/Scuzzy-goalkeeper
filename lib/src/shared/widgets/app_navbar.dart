import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../features/auth/presentation/theme/app_theme.dart';

enum NavbarItem { home, search, map, team, profile }

class AppNavbar extends StatefulWidget {
  final NavbarItem selectedItem;
  final Function(NavbarItem) onItemSelected;

  const AppNavbar({
    super.key,
    required this.selectedItem,
    required this.onItemSelected,
  });

  @override
  State<AppNavbar> createState() => _AppNavbarState();
}

class _AppNavbarState extends State<AppNavbar>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    _slideController = AnimationController(
      duration: AppTheme.mediumAnimation,
      vsync: this,
    );
    
    _scaleController = AnimationController(
      duration: AppTheme.shortAnimation,
      vsync: this,
    );
    
    _slideAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.elasticOut,
    ));
    
    // Start animations
    _slideController.forward();
    _scaleController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  void _onItemTap(NavbarItem item) {
    if (item != widget.selectedItem) {
      // Haptic feedback for better user experience
      HapticFeedback.lightImpact();
      
      // Scale animation on tap
      _scaleController.forward().then((_) {
        _scaleController.reverse();
      });
      
      widget.onItemSelected(item);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 100 * (1 - _slideAnimation.value)),
          child: Container(
            height: 90 + MediaQuery.of(context).padding.bottom,
            // Completely transparent - no decoration at all
            decoration: null,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _NavbarIcon(
                      icon: Icons.home_rounded,
                      label: 'Home',
                      isSelected: widget.selectedItem == NavbarItem.home,
                      onTap: () => _onItemTap(NavbarItem.home),
                      index: 0,
                    ),
                    _NavbarIcon(
                      icon: Icons.search_rounded,
                      label: 'Search',
                      isSelected: widget.selectedItem == NavbarItem.search,
                      onTap: () => _onItemTap(NavbarItem.search),
                      index: 1,
                    ),
                    _NavbarIcon(
                      icon: Icons.map_rounded,
                      label: 'Map',
                      isSelected: widget.selectedItem == NavbarItem.map,
                      onTap: () => _onItemTap(NavbarItem.map),
                      index: 2,
                    ),
                    _NavbarIcon(
                      icon: Icons.groups_rounded,
                      label: 'Team',
                      isSelected: widget.selectedItem == NavbarItem.team,
                      onTap: () => _onItemTap(NavbarItem.team),
                      index: 3,
                    ),
                    _NavbarIcon(
                      icon: Icons.person_rounded,
                      label: 'Profile',
                      isSelected: widget.selectedItem == NavbarItem.profile,
                      onTap: () => _onItemTap(NavbarItem.profile),
                      index: 4,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _NavbarIcon extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final int index;

  const _NavbarIcon({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.index,
  });

  @override
  State<_NavbarIcon> createState() => _NavbarIconState();
}

class _NavbarIconState extends State<_NavbarIcon>
    with TickerProviderStateMixin {
  late AnimationController _pressController;
  late AnimationController _selectedController;
  late AnimationController _rippleController;
  late Animation<double> _pressAnimation;
  late Animation<double> _selectedAnimation;
  late Animation<double> _rippleAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    
    _pressController = AnimationController(
      duration: AppTheme.shortAnimation,
      vsync: this,
    );
    
    _selectedController = AnimationController(
      duration: AppTheme.mediumAnimation,
      vsync: this,
    );
    
    _rippleController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _pressAnimation = Tween<double>(
      begin: 1.0,
      end: 0.9,
    ).animate(CurvedAnimation(
      parent: _pressController,
      curve: Curves.easeInOut,
    ));
    
    _selectedAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _selectedController,
      curve: Curves.elasticOut,
    ));
    
    _rippleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _rippleController,
      curve: Curves.easeOut,
    ));
    
    _colorAnimation = ColorTween(
      begin: Colors.white.withOpacity(0.7), // Better contrast on green background
      end: Colors.white, // White for selected state on green background
    ).animate(CurvedAnimation(
      parent: _selectedController,
      curve: Curves.easeInOut,
    ));
    
    // Initialize selected state
    if (widget.isSelected) {
      _selectedController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(_NavbarIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.isSelected != oldWidget.isSelected) {
      if (widget.isSelected) {
        _selectedController.forward();
        _rippleController.forward().then((_) {
          _rippleController.reset();
        });
      } else {
        _selectedController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _pressController.dispose();
    _selectedController.dispose();
    _rippleController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _pressController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _pressController.reverse();
  }

  void _onTapCancel() {
    _pressController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _pressAnimation,
        _selectedAnimation,
        _colorAnimation,
        _rippleAnimation,
      ]),
      builder: (context, child) {
        return Transform.scale(
          scale: _pressAnimation.value,
          child: GestureDetector(
            onTapDown: _onTapDown,
            onTapUp: _onTapUp,
            onTapCancel: _onTapCancel,
            onTap: widget.onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  // Ripple effect
                  if (_rippleAnimation.value > 0)
                    Positioned(
                      child: Container(
                        width: 50 * _rippleAnimation.value,
                        height: 50 * _rippleAnimation.value,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.accentColor.withOpacity(
                            0.2 * (1 - _rippleAnimation.value),
                          ),
                        ),
                      ),
                    ),
                  
                  // Background glow for selected item
                  if (widget.isSelected)
                    Positioned(
                      child: Transform.scale(
                        scale: _selectedAnimation.value,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                AppTheme.accentColor.withOpacity(0.3),
                                AppTheme.accentColor.withOpacity(0.1),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  
                  // Icon and label
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Transform.scale(
                        scale: 1.0 + (0.1 * _selectedAnimation.value),
                        child: Icon(
                          widget.icon,
                          size: 24,
                          color: _colorAnimation.value,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.5),
                              offset: const Offset(0, 1),
                              blurRadius: 3,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      AnimatedDefaultTextStyle(
                        duration: AppTheme.shortAnimation,
                        style: AppTheme.bodyMedium.copyWith(
                          fontSize: 10,
                          color: _colorAnimation.value,
                          fontWeight: widget.isSelected 
                              ? FontWeight.w600 
                              : FontWeight.w400,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.5),
                              offset: const Offset(0, 1),
                              blurRadius: 3,
                            ),
                          ],
                        ),
                        child: Text(widget.label),
                      ),
                    ],
                  ),
                  
                  // Active indicator dot
                  if (widget.isSelected)
                    Positioned(
                      top: -4,
                      child: Transform.scale(
                        scale: _selectedAnimation.value,
                        child: Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.accentColor,
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.accentColor.withOpacity(0.5),
                                blurRadius: 6,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

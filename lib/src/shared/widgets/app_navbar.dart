import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../features/auth/presentation/theme/app_theme.dart';
import '../../features/auth/presentation/providers/auth_state_provider.dart';
import '../../features/announcements/presentation/controllers/announcement_controller.dart';
import '../../features/notifications/presentation/controllers/notification_badge_controller.dart';

enum NavbarItem { home, map, notifications, profile }

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
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    _slideController = AnimationController(
      duration: AppTheme.mediumAnimation,
      vsync: this,
    );
    
    _slideAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.elasticOut,
    ));
    
    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  void _onItemTap(NavbarItem item) {
    if (item != widget.selectedItem) {
      HapticFeedback.lightImpact();
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
            height: 70 + MediaQuery.of(context).padding.bottom,
            decoration: BoxDecoration(
              color: widget.selectedItem == NavbarItem.profile 
                  ? Colors.black.withOpacity(0.25)
                  : Colors.transparent,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Consumer2<AnnouncementController, AuthStateProvider>(
                      builder: (context, announcementController, authProvider, child) {
                        return _NavbarIcon(
                          icon: Icons.campaign,
                          isSelected: widget.selectedItem == NavbarItem.home,
                          onTap: () => _onItemTap(NavbarItem.home),
                          badgeCount: announcementController.announcements.length,
                          currentScreen: widget.selectedItem,
                          isGuestMode: authProvider.isGuest,
                          requiresAuth: false,
                        );
                      },
                    ),
                    Consumer<AuthStateProvider>(
                      builder: (context, authProvider, child) {
                        return _NavbarIcon(
                          icon: Icons.stadium,
                          isSelected: widget.selectedItem == NavbarItem.map,
                          onTap: () => _onItemTap(NavbarItem.map),
                          currentScreen: widget.selectedItem,
                          isGuestMode: authProvider.isGuest,
                          requiresAuth: false,
                        );
                      },
                    ),
                    Consumer2<NotificationBadgeController, AuthStateProvider>(
                      builder: (context, badgeController, authProvider, child) {
                        return _NavbarIcon(
                          icon: Icons.notifications,
                          isSelected: widget.selectedItem == NavbarItem.notifications,
                          onTap: () => _onItemTap(NavbarItem.notifications),
                          badgeCount: authProvider.isGuest ? null : 
                                     (badgeController.hasUnreadNotifications ? badgeController.unreadCount : null),
                          currentScreen: widget.selectedItem,
                          isGuestMode: authProvider.isGuest,
                          requiresAuth: true,
                        );
                      },
                    ),
                    Consumer<AuthStateProvider>(
                      builder: (context, authProvider, child) {
                        return _NavbarIcon(
                          icon: Icons.person,
                          isSelected: widget.selectedItem == NavbarItem.profile,
                          onTap: () => _onItemTap(NavbarItem.profile),
                          currentScreen: widget.selectedItem,
                          isGuestMode: authProvider.isGuest,
                          requiresAuth: false,
                        );
                      },
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

class _NavbarIcon extends StatelessWidget {
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final int? badgeCount;
  final NavbarItem? currentScreen;
  final bool isGuestMode;
  final bool requiresAuth;

  const _NavbarIcon({
    required this.icon,
    required this.isSelected,
    required this.onTap,
    this.badgeCount,
    this.currentScreen,
    this.isGuestMode = false,
    this.requiresAuth = false,
  });

  Color _getIconColor(BuildContext context) {
    // For map and profile screens, use white icons for better visibility
    if (currentScreen == NavbarItem.map || currentScreen == NavbarItem.profile) {
      return Colors.white;
    }
    
    // For guest mode with auth-required features, use muted color with visual feedback
    if (isGuestMode && requiresAuth) {
      return isSelected ? const Color(0xFF0BA95F).withOpacity(0.6) : const Color(0xFF9E9E9E);
    }
    
    // For other screens, use dark icons on light backgrounds
    return isSelected ? const Color(0xFF0BA95F) : const Color(0xFF757575);
  }

  BoxDecoration? _getIconDecoration() {
    if (!isSelected) return null;
    
    // For profile screen, use green background with white text for better visibility
    if (currentScreen == NavbarItem.profile) {
      return BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4CAF50), Color(0xFF45A049)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4CAF50).withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      );
    }
    
    // For map screen, use semi-transparent styling
    if (currentScreen == NavbarItem.map) {
      return BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      );
    }
    
    // Default styling for other screens
    return BoxDecoration(
      color: isGuestMode && requiresAuth 
          ? const Color(0xFF0BA95F).withOpacity(0.1)
          : const Color(0xFF0BA95F).withOpacity(0.2),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: isGuestMode && requiresAuth 
            ? const Color(0xFF0BA95F).withOpacity(0.2)
            : const Color(0xFF0BA95F).withOpacity(0.4),
        width: 1,
      ),
      boxShadow: isGuestMode && requiresAuth ? [] : [
        BoxShadow(
          color: const Color(0xFF0BA95F).withOpacity(0.3),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: _getIconDecoration(),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(
              icon,
              size: 28,
              color: _getIconColor(context),
            ),
            // Show guest indicator for auth-required features
            if (isGuestMode && requiresAuth && isSelected)
              Positioned(
                right: -4,
                top: -4,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF9800),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 1,
                    ),
                  ),
                ),
              ),
            if (badgeCount != null && badgeCount! > 0 && !isGuestMode)
              Positioned(
                right: -6,
                top: -6,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppTheme.errorColor,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    badgeCount! > 99 ? '99+' : badgeCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

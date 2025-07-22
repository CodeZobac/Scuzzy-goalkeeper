import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/auth/presentation/theme/app_theme.dart';
import '../../features/map/data/repositories/field_repository.dart';
import '../../features/map/domain/models/map_field.dart';
import '../../features/announcements/presentation/controllers/announcement_controller.dart';
import '../../features/notifications/services/notification_service.dart';
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
            decoration: const BoxDecoration(
              color: Colors.transparent,
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Consumer<AnnouncementController>(
                      builder: (context, announcementController, child) {
                        return _NavbarIcon(
                          icon: Icons.campaign,
                          isSelected: widget.selectedItem == NavbarItem.home,
                          onTap: () => _onItemTap(NavbarItem.home),
                          badgeCount: announcementController.announcements.length,
                          currentScreen: widget.selectedItem,
                        );
                      },
                    ),
                    _NavbarIcon(
                      icon: Icons.stadium,
                      isSelected: widget.selectedItem == NavbarItem.map,
                      onTap: () => _onItemTap(NavbarItem.map),
                      currentScreen: widget.selectedItem,
                    ),
                    Consumer<NotificationBadgeController>(
                      builder: (context, badgeController, child) {
                        return _NavbarIcon(
                          icon: Icons.notifications,
                          isSelected: widget.selectedItem == NavbarItem.notifications,
                          onTap: () => _onItemTap(NavbarItem.notifications),
                          badgeCount: badgeController.hasUnreadNotifications ? badgeController.unreadCount : null,
                          currentScreen: widget.selectedItem,
                        );
                      },
                    ),
                    _NavbarIcon(
                      icon: Icons.person,
                      isSelected: widget.selectedItem == NavbarItem.profile,
                      onTap: () => _onItemTap(NavbarItem.profile),
                      currentScreen: widget.selectedItem,
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

  const _NavbarIcon({
    required this.icon,
    required this.isSelected,
    required this.onTap,
    this.badgeCount,
    this.currentScreen,
  });

  Color _getIconColor(BuildContext context) {
    // For map screen, always use white icons (dark background)
    if (currentScreen == NavbarItem.map) {
      return Colors.white;
    }
    
    // For other screens, use dark icons on light backgrounds
    return isSelected ? const Color(0xFF0BA95F) : const Color(0xFF757575);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: isSelected ? BoxDecoration(
          color: const Color(0xFF0BA95F).withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF0BA95F).withOpacity(0.4),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0BA95F).withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ) : null,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(
              icon,
              size: 28,
              color: _getIconColor(context),
            ),
            if (badgeCount != null && badgeCount! > 0)
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

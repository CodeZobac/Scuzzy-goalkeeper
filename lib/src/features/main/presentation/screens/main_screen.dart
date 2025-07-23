import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:goalkeeper/src/features/map/presentation/screens/map_screen.dart';
import 'package:goalkeeper/src/features/map/presentation/providers/field_selection_provider.dart';
import 'package:goalkeeper/src/features/announcements/presentation/screens/announcements_screen.dart';
import 'package:goalkeeper/src/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:goalkeeper/src/features/user_profile/presentation/screens/enhanced_profile_screen.dart';
import '../../../../shared/widgets/app_navbar.dart';

class MainScreen extends StatefulWidget {
  final int? initialTabIndex;
  
  const MainScreen({super.key, this.initialTabIndex});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  NavbarItem _selectedItem = NavbarItem.home;

  @override
  void initState() {
    super.initState();
    
    // Set initial tab if provided
    if (widget.initialTabIndex != null) {
      _selectedItem = _getNavbarItemFromIndex(widget.initialTabIndex!);
    }
    
    // Handle route arguments for tab selection
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null && args['selectedTab'] != null) {
        final tabIndex = args['selectedTab'] as int;
        setState(() {
          _selectedItem = _getNavbarItemFromIndex(tabIndex);
        });
      }
    });
  }

  NavbarItem _getNavbarItemFromIndex(int index) {
    switch (index) {
      case 0:
        return NavbarItem.home;
      case 1:
        return NavbarItem.map;
      case 2:
        return NavbarItem.notifications;
      case 3:
        return NavbarItem.profile;
      default:
        return NavbarItem.home;
    }
  }

  Widget _getSelectedScreen() {
    switch (_selectedItem) {
      case NavbarItem.home:
        return const AnnouncementsScreen();
      case NavbarItem.map:
        return const MapScreen();
      case NavbarItem.notifications:
        return const NotificationsScreen();
      case NavbarItem.profile:
        return const EnhancedProfileScreen();
    }
  }

  void _onItemSelected(NavbarItem item) {
    setState(() {
      _selectedItem = item;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Main content
          _getSelectedScreen(),
          // Floating transparent navbar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Consumer<FieldSelectionProvider>(
              builder: (context, fieldSelection, child) {
                final shouldHideNavbar = _selectedItem == NavbarItem.map && fieldSelection.isFieldDetailsVisible;
                return AnimatedOpacity(
                  opacity: shouldHideNavbar ? 0.0 : 1.0,
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                  child: AppNavbar(
                    selectedItem: _selectedItem,
                    onItemSelected: _onItemSelected,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

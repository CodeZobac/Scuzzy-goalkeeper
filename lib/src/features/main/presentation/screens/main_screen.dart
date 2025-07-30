import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:goalkeeper/src/features/map/presentation/screens/map_screen.dart';
import 'package:goalkeeper/src/features/map/presentation/providers/field_selection_provider.dart';
import 'package:goalkeeper/src/features/announcements/presentation/screens/announcements_screen.dart';
import 'package:goalkeeper/src/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:goalkeeper/src/features/user_profile/presentation/screens/enhanced_profile_screen.dart';
import 'package:goalkeeper/src/features/user_profile/presentation/screens/guest_profile_screen.dart';
import 'package:goalkeeper/src/features/auth/presentation/providers/auth_state_provider.dart';
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
    return Consumer<AuthStateProvider>(
      builder: (context, authProvider, child) {
        // Initialize guest context if user is in guest mode
        if (authProvider.isGuest) {
          authProvider.initializeGuestContext();
        }
        
        switch (_selectedItem) {
          case NavbarItem.home:
            // Track guest content viewing for announcements
            if (authProvider.isGuest) {
              authProvider.trackGuestContentView('announcements');
            }
            return const AnnouncementsScreen();
          case NavbarItem.map:
            // Track guest content viewing for map
            if (authProvider.isGuest) {
              authProvider.trackGuestContentView('map');
            }
            return const MapScreen();
          case NavbarItem.notifications:
            // For guest users, redirect to profile screen with registration prompt
            if (authProvider.isGuest) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  setState(() {
                    _selectedItem = NavbarItem.profile;
                  });
                }
              });
              return const GuestProfileScreen();
            }
            return const NotificationsScreen();
          case NavbarItem.profile:
            // Track guest profile access
            if (authProvider.isGuest) {
              authProvider.trackGuestContentView('profile');
            }
            return authProvider.isGuest 
                ? const GuestProfileScreen()
                : const EnhancedProfileScreen();
        }
      },
    );
  }

  void _onItemSelected(NavbarItem item) {
    final authProvider = context.read<AuthStateProvider>();
    
    // Handle guest mode navigation restrictions
    if (authProvider.isGuest && item == NavbarItem.notifications) {
      // For guest users, redirect notifications tap to profile screen
      // This provides a consistent way to prompt for registration
      setState(() {
        _selectedItem = NavbarItem.profile;
      });
      return;
    }
    
    // Track navigation for guest users
    if (authProvider.isGuest) {
      String screenName = '';
      switch (item) {
        case NavbarItem.home:
          screenName = 'announcements';
          break;
        case NavbarItem.map:
          screenName = 'map';
          break;
        case NavbarItem.notifications:
          screenName = 'notifications';
          break;
        case NavbarItem.profile:
          screenName = 'profile';
          break;
      }
      authProvider.trackGuestContentView('navigation_$screenName');
    }
    
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
          // Floating login button for guest users
          Consumer<AuthStateProvider>(
            builder: (context, authProvider, child) {
              // Hide button if user is not a guest or is on the profile tab
              if (!authProvider.isGuest || _selectedItem == NavbarItem.profile) {
                return const SizedBox.shrink();
              }
              
              return Positioned(
                top: MediaQuery.of(context).padding.top + 16,
                right: 16,
                child: _buildGuestLoginButton(),
              );
            },
          ),
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

  Widget _buildGuestLoginButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0BA95F),
            Color(0xFF0A8A4F),
          ],
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0BA95F).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(25),
          onTap: () {
            Navigator.of(context).pushNamed('/signin');
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.login,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Entrar',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

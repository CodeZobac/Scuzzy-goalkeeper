import 'package:flutter/material.dart';
import 'package:goalkeeper/src/features/map/presentation/screens/map_screen.dart';
import '../../../../shared/widgets/app_navbar.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  NavbarItem _selectedItem = NavbarItem.home;

  Widget _getSelectedScreen() {
    switch (_selectedItem) {
      case NavbarItem.home:
        return const Center(
          child: Text('Home Screen', style: TextStyle(fontSize: 24)),
        );
      case NavbarItem.map:
        return const MapScreen();
      case NavbarItem.notifications:
        return const Center(
          child: Text('Notifications Screen', style: TextStyle(fontSize: 24)),
        );
      case NavbarItem.profile:
        return const Center(
          child: Text('Profile Screen', style: TextStyle(fontSize: 24)),
        );
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
            child: AppNavbar(
              selectedItem: _selectedItem,
              onItemSelected: _onItemSelected,
            ),
          ),
        ],
      ),
    );
  }
}

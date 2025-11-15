import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/auth_controller.dart';
import '../design_system/design_system.dart';
import '../widgets/avatar_image.dart';

import 'bookings_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'search_screen.dart';

class NavigationShell extends StatefulWidget {
  const NavigationShell({super.key});

  static const route = '/app';

  @override
  State<NavigationShell> createState() => _NavigationShellState();
}

class _NavigationShellState extends State<NavigationShell> {
  int _currentIndex = 0;

  final _pages = const [
    HomeScreen(),
    SearchScreen(),
    BookingsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final user = auth.user;
    
    // Build profile photo widget
    Widget? profileIcon;
    Widget? profileSelectedIcon;
    
    if (user != null) {
      profileIcon = AvatarImage(
        avatarUrl: user.avatarUrl,
        radius: 14,
      );
      profileSelectedIcon = Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Theme.of(context).colorScheme.primary,
            width: 2,
          ),
        ),
        child: AvatarImage(
          avatarUrl: user.avatarUrl,
          radius: 14,
        ),
      );
    }
    
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) {
          // When back is pressed, ensure we stay on Explore tab (index 0)
          if (_currentIndex != 0) {
            setState(() => _currentIndex = 0);
          }
          // If already on Explore tab, prevent going back to auth screen
          // Just stay on Explore tab
        }
      },
      child: AdaptiveScaffold(
        initialIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: [
        AdaptiveDestination(
          label: 'Explore',
          icon: Icons.home_outlined,
          selectedIcon: Icons.home_filled,
          builder: (_) => _pages[0],
        ),
        AdaptiveDestination(
          label: 'Search',
          icon: Icons.search_outlined,
          selectedIcon: Icons.search,
          builder: (_) => _pages[1],
        ),
        AdaptiveDestination(
          label: 'Tickets',
          icon: Icons.confirmation_number_outlined,
          selectedIcon: Icons.confirmation_number,
          builder: (_) => _pages[2],
        ),
        AdaptiveDestination(
          label: 'Profile',
          icon: Icons.person_outline,
          selectedIcon: Icons.person,
          builder: (_) => _pages[3],
          customIcon: profileIcon,
          customSelectedIcon: profileSelectedIcon,
        ),
      ],
      ),
    );
  }
}

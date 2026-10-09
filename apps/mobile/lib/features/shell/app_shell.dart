import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/widgets/custom_bottom_navigation.dart';

/// AppShell hosting the persistent bottom navigation and branch routing.
class AppShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const AppShell({super.key, required this.navigationShell});

  static const List<BottomNavItem> _navItems = [
    BottomNavItem(
      label: 'Today',
      icon: Icons.calendar_today_outlined,
      activeIcon: Icons.calendar_today_rounded,
    ),
    BottomNavItem(
      label: 'Tasks',
      icon: Icons.check_circle_outline_rounded,
      activeIcon: Icons.check_circle_rounded,
    ),
    BottomNavItem(
      label: 'Calendar',
      icon: Icons.calendar_month_outlined,
      activeIcon: Icons.calendar_month_rounded,
    ),
    BottomNavItem(
      label: 'Finance',
      icon: Icons.account_balance_wallet_outlined,
      activeIcon: Icons.account_balance_wallet_rounded,
    ),
    BottomNavItem(
      label: 'Notes',
      icon: Icons.sticky_note_2_outlined,
      activeIcon: Icons.sticky_note_2_rounded,
    ),
  ];

  void _onTabTapped(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: CustomBottomNavigation(
        currentIndex: navigationShell.currentIndex,
        onTap: _onTabTapped,
        items: _navItems,
      ),
    );
  }
}


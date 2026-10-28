import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_colors.dart';
import 'earnings_screen.dart';
import 'home_screen.dart';
import 'parcel_screen.dart';
import 'profile_screen.dart';

/// Hosts the four main tabs and the sliding-pill bottom navigation.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedTab = 0;

  late final List<Widget> _pages = const [
    HomeScreen(),
    ParcelScreen(),
    EarningsScreen(),
    ProfileScreen(),
  ];

  static const _navItems = <_NavItem>[
    _NavItem(icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: 'Home'),
    _NavItem(
      icon: Icons.inventory_2_outlined,
      activeIcon: Icons.inventory_2_rounded,
      label: 'Parcels',
    ),
    _NavItem(
      icon: Icons.account_balance_wallet_outlined,
      activeIcon: Icons.account_balance_wallet_rounded,
      label: 'Earnings',
    ),
    _NavItem(
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
      label: 'Profile',
    ),
  ];

  void _onTabSelected(int index) {
    if (index == _selectedTab) return;
    HapticFeedback.selectionClick();
    setState(() => _selectedTab = index);
  }

  @override
  Widget build(BuildContext context) {
    // Back goes to Home first, and only leaves the app from Home.
    return PopScope(
      canPop: _selectedTab == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _selectedTab = 0);
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: IndexedStack(index: _selectedTab, children: _pages),
        bottomNavigationBar: _BottomNav(
          selectedIndex: _selectedTab,
          items: _navItems,
          onTap: _onTabSelected,
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

/// Bottom bar with a green pill that slides to the selected tab.
class _BottomNav extends StatelessWidget {
  final int selectedIndex;
  final List<_NavItem> items;
  final ValueChanged<int> onTap;

  const _BottomNav({
    required this.selectedIndex,
    required this.items,
    required this.onTap,
  });

  static const double _pillWidth = 64;
  static const double _pillHeight = 30;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border(top: BorderSide(color: AppColors.border)),
        boxShadow: [
          BoxShadow(color: Color(0x14064E3B), blurRadius: 14, offset: Offset(0, -4)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final cell = constraints.maxWidth / items.length;
            return SizedBox(
              height: 62,
              child: Stack(
                children: [
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 380),
                    curve: Curves.easeOutCubic,
                    left: cell * selectedIndex + (cell - _pillWidth) / 2,
                    top: 8,
                    width: _pillWidth,
                    height: _pillHeight,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(_pillHeight / 2),
                        boxShadow: const [
                          BoxShadow(color: Color(0x3316A34A), blurRadius: 10),
                        ],
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: Row(
                      children: [
                        for (var i = 0; i < items.length; i++)
                          _navCell(cell, i),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _navCell(double cellWidth, int index) {
    final item = items[index];
    final selected = index == selectedIndex;
    return InkWell(
      onTap: () => onTap(index),
      child: SizedBox(
        width: cellWidth,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              selected ? item.activeIcon : item.icon,
              size: 20,
              color: selected ? Colors.white : AppColors.muted,
            ),
            const SizedBox(height: 6),
            Text(
              item.label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                color: selected ? AppColors.primaryDark : AppColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

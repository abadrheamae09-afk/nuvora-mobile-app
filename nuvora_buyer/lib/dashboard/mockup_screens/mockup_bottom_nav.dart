// ============================================================
// mockup_bottom_nav.dart
// Reusable bottom navigation bar (Home, Categories, Wishlist,
// Cart, Profile) used by main browsing screens.
// ============================================================

import 'package:flutter/material.dart';
import 'mockup_theme.dart';

class MockupBottomNav extends StatelessWidget {
  const MockupBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      backgroundColor: MColors.card,
      selectedItemColor: MColors.primary,
      unselectedItemColor: MColors.muted,
      selectedLabelStyle: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
      ),
      unselectedLabelStyle: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
      ),
      elevation: 12,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home_rounded),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.grid_view_outlined),
          activeIcon: Icon(Icons.grid_view_rounded),
          label: 'Categories',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.favorite_outline_rounded),
          activeIcon: Icon(Icons.favorite_rounded),
          label: 'Wishlist',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.shopping_cart_outlined),
          activeIcon: Icon(Icons.shopping_cart_rounded),
          label: 'Cart',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline_rounded),
          activeIcon: Icon(Icons.person_rounded),
          label: 'Profile',
        ),
      ],
    );
  }
}

/// Convenience scaffold that wraps a screen body with the shared bottom nav.
/// Stateful so tabs can navigate among themselves in the preview.
class MockupShell extends StatefulWidget {
  const MockupShell({
    super.key,
    required this.child,
    this.initialIndex = 0,
    this.onIndexChanged,
  });

  final Widget child;
  final int initialIndex;
  final ValueChanged<int>? onIndexChanged;

  @override
  State<MockupShell> createState() => _MockupShellState();
}

class _MockupShellState extends State<MockupShell> {
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: MockupBottomNav(
        currentIndex: _index,
        onTap: (i) {
          setState(() => _index = i);
          widget.onIndexChanged?.call(i);
        },
      ),
    );
  }
}

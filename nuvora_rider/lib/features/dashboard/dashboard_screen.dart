import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/data/rider_work.dart';
import '../../theme/app_colors.dart';
import 'earnings_screen.dart';
import 'home_screen.dart';
import 'notifications_screen.dart';
import 'parcels_screen.dart';
import 'profile_screen.dart';

/// Tab positions, so the code below reads clearly.
class _Tab {
  static const home = 0;
  static const parcels = 1;
  static const notifications = 2;
  static const earnings = 3;
}

/// Hosts the five rider tabs and the floating green navigation bar.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedTab = _Tab.home;
  final _store = RiderWorkStore.instance;

  late final List<Widget> _pages = [
    HomeScreen(
      onOpenParcels: () => _onTabSelected(_Tab.parcels),
      onOpenEarnings: () => _onTabSelected(_Tab.earnings),
      onOpenNotifications: () => _onTabSelected(_Tab.notifications),
    ),
    const ParcelsScreen(),
    const NotificationsScreen(),
    const EarningsScreen(),
    const ProfileScreen(),
  ];

  static const _navItems = <_NavItem>[
    _NavItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: 'Home',
    ),
    _NavItem(
      icon: Icons.inventory_2_outlined,
      activeIcon: Icons.inventory_2_rounded,
      label: 'Parcels',
    ),
    _NavItem(
      icon: Icons.notifications_none_rounded,
      activeIcon: Icons.notifications_rounded,
      label: 'Alerts',
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

  @override
  void initState() {
    super.initState();
    // The first paint shows nothing until the Station Hub answers, so ask for
    // the rider's assigned work as soon as the dashboard opens.
    _store.refresh();
  }

  void _onTabSelected(int index) {
    if (index == _selectedTab) return;
    HapticFeedback.selectionClick();
    setState(() => _selectedTab = index);
  }

  @override
  Widget build(BuildContext context) {
    // Back goes to Home first, and only leaves the app from Home.
    return PopScope(
      canPop: _selectedTab == _Tab.home,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _selectedTab = _Tab.home);
      },
      child: ListenableBuilder(
        listenable: _store,
        builder: (context, _) => Scaffold(
          // The pages continue behind the see-through bar.
          extendBody: true,
          backgroundColor: AppColors.background,
          body: IndexedStack(index: _selectedTab, children: _pages),
          bottomNavigationBar: _BottomNav(
            selectedIndex: _selectedTab,
            items: _navItems,
            unreadCount: _store.unreadCount,
            onTap: _onTabSelected,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom navigation with a green "jelly" indicator.
//
// One pill slides to the tab you tap. While it travels it stretches toward the
// tab (the front edge runs ahead, the back edge follows late), then wobbles and
// settles, like jelly.
// ─────────────────────────────────────────────────────────────────────────────
class _BottomNav extends StatefulWidget {
  final int selectedIndex;
  final int unreadCount;
  final List<_NavItem> items;
  final ValueChanged<int> onTap;

  const _BottomNav({
    required this.selectedIndex,
    required this.unreadCount,
    required this.items,
    required this.onTap,
  });

  @override
  State<_BottomNav> createState() => _BottomNavState();
}

class _BottomNavState extends State<_BottomNav>
    with SingleTickerProviderStateMixin {
  static const _pillWidth = 48.0;
  static const _pillHeight = 30.0;
  static const _duration = Duration(milliseconds: 620);
  static const _squash = 0.12;
  static const _vPad = 9.0;

  late final AnimationController _controller;
  late int _fromIndex;

  static final _leadCurve = Interval(0.0, 0.55, curve: Curves.easeOutCubic);
  static final _trailCurve = Interval(0.1, 1.0, curve: ElasticOutCurve(0.85));

  @override
  void initState() {
    super.initState();
    _fromIndex = widget.selectedIndex;
    _controller = AnimationController(
      vsync: this,
      duration: _duration,
      value: 1.0,
    );
  }

  @override
  void didUpdateWidget(covariant _BottomNav oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      _fromIndex = oldWidget.selectedIndex;
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  _PillShape _pillShape(double cell) {
    final t = _controller.value;
    final from = _fromIndex;
    final to = widget.selectedIndex;

    final fromCenter = cell * (from + 0.5);
    final toCenter = cell * (to + 0.5);
    final half = _pillWidth / 2;

    final movingRight = to >= from;
    final leadT = _leadCurve.transform(t);
    final trailT = _trailCurve.transform(t);

    final leftT = movingRight ? trailT : leadT;
    final rightT = movingRight ? leadT : trailT;

    final left =
        (fromCenter - half) + ((toCenter - half) - (fromCenter - half)) * leftT;
    final right =
        (fromCenter + half) +
        ((toCenter + half) - (fromCenter + half)) * rightT;

    final height = _pillHeight * (1 - _squash * math.sin(math.pi * t));
    final top = (_pillHeight - height) / 2;

    return _PillShape(left: left, right: right, top: top, height: height);
  }

  /// An icon turns white where the pill covers it, muted where it does not.
  Color _iconColor(int index, double cell, _PillShape pill) {
    final center = cell * (index + 0.5);
    const iconHalf = 12.0;
    final overlap =
        (math.min(pill.right, center + iconHalf) -
            math.max(pill.left, center - iconHalf)) /
        (iconHalf * 2);
    final amount = overlap.clamp(0.0, 1.0).toDouble();
    return Color.lerp(AppColors.muted, Colors.white, amount)!;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 6, 14, 6),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(36),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1F064E3B),
                blurRadius: 22,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(36),
            // Frosted glass: the page behind the bar is blurred, not hidden.
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(210),
                  borderRadius: BorderRadius.circular(36),
                  border: Border.all(color: const Color(0x3316A34A)),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final cell = constraints.maxWidth / widget.items.length;

                    return AnimatedBuilder(
                      animation: _controller,
                      builder: (context, _) {
                        final pill = _pillShape(cell);

                        return Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Positioned(
                              left: pill.left,
                              top: pill.top + _vPad,
                              width: math.max(pill.right - pill.left, 0),
                              height: pill.height,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: AppColors.primaryDark,
                                  borderRadius: BorderRadius.circular(
                                    pill.height / 2,
                                  ),
                                ),
                              ),
                            ),
                            Row(
                              children: List.generate(widget.items.length, (i) {
                                return Expanded(
                                  child: _NavButton(
                                    item: widget.items[i],
                                    isActive: i == widget.selectedIndex,
                                    iconColor: _iconColor(i, cell, pill),
                                    iconAreaHeight: _pillHeight,
                                    verticalPadding: _vPad,
                                    badgeCount: i == _Tab.notifications
                                        ? widget.unreadCount
                                        : 0,
                                    onTap: () => widget.onTap(i),
                                  ),
                                );
                              }),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PillShape {
  final double left, right, top, height;

  const _PillShape({
    required this.left,
    required this.right,
    required this.top,
    required this.height,
  });
}

class _NavButton extends StatelessWidget {
  final _NavItem item;
  final bool isActive;
  final Color iconColor;
  final double iconAreaHeight;
  final double verticalPadding;
  final int badgeCount;
  final VoidCallback onTap;

  const _NavButton({
    required this.item,
    required this.isActive,
    required this.iconColor,
    required this.iconAreaHeight,
    required this.verticalPadding,
    this.badgeCount = 0,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isActive,
      label: item.label,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: verticalPadding),
            SizedBox(
              height: iconAreaHeight,
              child: Center(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      transitionBuilder: (child, animation) =>
                          ScaleTransition(scale: animation, child: child),
                      child: Icon(
                        isActive ? item.activeIcon : item.icon,
                        key: ValueKey(isActive),
                        size: 23,
                        color: iconColor,
                      ),
                    ),
                    if (badgeCount > 0)
                      Positioned(
                        right: -11,
                        top: -5,
                        child: Container(
                          constraints: const BoxConstraints(minWidth: 16),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.danger,
                            borderRadius: BorderRadius.circular(9),
                            border: Border.all(color: Colors.white, width: 1.4),
                          ),
                          child: Text(
                            badgeCount > 99 ? '99+' : '$badgeCount',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              height: 1.2,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            SizedBox(height: verticalPadding),
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon, activeIcon;
  final String label;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

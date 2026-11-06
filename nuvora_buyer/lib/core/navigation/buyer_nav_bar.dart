// ============================================================
// buyer_nav_bar.dart
// The ONE bottom navigation bar for every buyer screen.
//
// All tabs and their destinations live in [buyerNavItems] and
// [buyerTabScreen] below: adding or changing a link only needs an
// edit in this file. Screens just render
// `BuyerNavBar(current: BuyerTab.x)`.
//
// The active tab is highlighted, the cart and notification badges
// come from the same data the website uses
// (GET /api/buyer/summary), and the signed-in token is never
// touched when switching tabs, so the login session survives.
// ============================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../api/buyer_api.dart';
import '../../dashboard/mockup_screens/home_screen.dart';
import '../../dashboard/mockup_screens/category_list_screen.dart';
import '../../dashboard/mockup_screens/wishlist_screen.dart';
import '../../dashboard/mockup_screens/cart_screen.dart';
import '../../dashboard/mockup_screens/notifications_screen.dart';
import '../../dashboard/mockup_screens/profile_screen.dart';

// ── Design tokens shared with the redesigned screens ─────────
class _NavColors {
  static const surface = Color(0xF2FCF9F8);
  static const forest = Color(0xFF012114);
  static const inkSoft = Color(0xFF424844);
  static const badge = Color(0xFF173628);
  static const hairline = Color(0x0F173628);
}

/// The buyer app's top-level destinations.
enum BuyerTab { home, categories, wishlist, cart, notifications, account }

class BuyerNavItem {
  const BuyerNavItem({
    required this.tab,
    required this.label,
    required this.icon,
    required this.activeIcon,
  });

  final BuyerTab tab;
  final String label;
  final IconData icon;
  final IconData activeIcon;
}

/// Every bottom-navigation item, in order. Edit this list (and
/// [buyerTabScreen]) to add or change a destination.
const List<BuyerNavItem> buyerNavItems = <BuyerNavItem>[
  BuyerNavItem(
    tab: BuyerTab.home,
    label: 'Home',
    icon: Icons.storefront_outlined,
    activeIcon: Icons.storefront,
  ),
  BuyerNavItem(
    tab: BuyerTab.categories,
    label: 'Categories',
    icon: Icons.grid_view_outlined,
    activeIcon: Icons.grid_view_rounded,
  ),
  BuyerNavItem(
    tab: BuyerTab.wishlist,
    label: 'Wishlist',
    icon: Icons.favorite_border_rounded,
    activeIcon: Icons.favorite_rounded,
  ),
  BuyerNavItem(
    tab: BuyerTab.cart,
    label: 'Cart',
    icon: Icons.shopping_bag_outlined,
    activeIcon: Icons.shopping_bag,
  ),
  BuyerNavItem(
    tab: BuyerTab.notifications,
    label: 'Alerts',
    icon: Icons.notifications_none_rounded,
    activeIcon: Icons.notifications,
  ),
  BuyerNavItem(
    tab: BuyerTab.account,
    label: 'Account',
    icon: Icons.person_outline_rounded,
    activeIcon: Icons.person,
  ),
];

/// The one place that maps a tab to its screen.
Widget buyerTabScreen(BuyerTab tab) {
  switch (tab) {
    case BuyerTab.home:
      return const MockupHomeScreen();
    case BuyerTab.categories:
      return const MockupCategoryListScreen();
    case BuyerTab.wishlist:
      return const MockupWishlistScreen();
    case BuyerTab.cart:
      return const MockupCartScreen();
    case BuyerTab.notifications:
      return const MockupNotificationsScreen();
    case BuyerTab.account:
      return const MockupProfileScreen();
  }
}

/// Opens a tab and keeps the signed-in session (the token lives in
/// SharedPreferences, so no screen rebuild can log the buyer out).
void openBuyerTab(BuildContext context, BuyerTab tab) {
  BuyerNavCounts.refresh();
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute<void>(builder: (_) => buyerTabScreen(tab)),
    (route) => false,
  );
}

/// Cart and notification counts, read from the existing buyer data.
/// One shared notifier means every screen's bar shows the same numbers.
class BuyerNavCounts {
  BuyerNavCounts._();

  static final ValueNotifier<int> cart = ValueNotifier<int>(0);
  static final ValueNotifier<int> notifications = ValueNotifier<int>(0);

  static Future<void> refresh() async {
    try {
      if (!await BuyerApi.instance.hasSession()) {
        cart.value = 0;
        notifications.value = 0;
        return;
      }

      final data = await BuyerApi.instance.summary();
      cart.value = (data['cart_count'] as num?)?.toInt() ?? 0;
      notifications.value =
          (data['notification_count'] as num?)?.toInt() ?? 0;
    } catch (_) {
      // Signed out or offline: the bar simply shows no badges.
      cart.value = 0;
      notifications.value = 0;
    }
  }
}

/// Frosted bottom navigation bar shared by every buyer screen.
class BuyerNavBar extends StatefulWidget {
  const BuyerNavBar({super.key, this.current});

  /// The tab this screen belongs to, used for the active highlight.
  /// Null on detail screens that are not a tab (product, store, ...).
  final BuyerTab? current;

  @override
  State<BuyerNavBar> createState() => _BuyerNavBarState();
}

class _BuyerNavBarState extends State<BuyerNavBar> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => BuyerNavCounts.refresh());
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _NavColors.surface,
        boxShadow: [
          BoxShadow(
            color: _NavColors.hairline,
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Row(
            children: buyerNavItems.map(_buildItem).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildItem(BuyerNavItem item) {
    final active = widget.current == item.tab;
    final color = active ? _NavColors.forest : _NavColors.inkSoft;

    Widget icon = Icon(
      active ? item.activeIcon : item.icon,
      size: 22,
      color: color,
    );

    if (item.tab == BuyerTab.cart) {
      icon = ValueListenableBuilder<int>(
        valueListenable: BuyerNavCounts.cart,
        builder: (_, count, child) => _Badged(icon: child!, count: count),
        child: icon,
      );
    } else if (item.tab == BuyerTab.notifications) {
      icon = ValueListenableBuilder<int>(
        valueListenable: BuyerNavCounts.notifications,
        builder: (_, count, child) => _Badged(icon: child!, count: count),
        child: icon,
      );
    }

    return Expanded(
      child: Semantics(
        selected: active,
        button: true,
        label: item.label,
        child: InkWell(
          onTap: () {
            if (active) return;
            openBuyerTab(context, item.tab);
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                icon,
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    item.label,
                    maxLines: 1,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10.5,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                      color: color,
                      letterSpacing: 0.2,
                    ),
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

class _Badged extends StatelessWidget {
  const _Badged({required this.icon, required this.count});

  final Widget icon;
  final int count;

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return icon;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        icon,
        Positioned(
          top: -4,
          right: -8,
          child: Container(
            constraints: const BoxConstraints(minWidth: 16),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            height: 16,
            decoration: BoxDecoration(
              color: _NavColors.badge,
              borderRadius: BorderRadius.circular(999),
            ),
            alignment: Alignment.center,
            child: Text(
              count > 99 ? '99+' : '$count',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.w700,
                height: 1,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

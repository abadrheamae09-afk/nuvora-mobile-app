// ============================================================
// my_orders_screen.dart
// Buyer orders list with tabs: To Pay, To Ship, To Receive,
// Completed, Cancelled.
// Design: "Botanical Boutique" (Playfair Display + Plus Jakarta Sans,
// forest-green / sage / amber palette).
// Routing and behavior are unchanged — only the visuals were updated.
// ============================================================

import 'package:flutter/material.dart';
import '../../core/navigation/buyer_nav_bar.dart';
import 'mockup_theme.dart';
import 'mockup_widgets.dart';
import 'order_details_screen.dart';
import 'rate_review_screen.dart';

// ── Design tokens (from the redesign) ───────────────────────
class _N {
  static const primary = Color(0xFF173628); // deep forest pine
  static const primaryDeep = Color(0xFF012114);
  static const secondary = Color(0xFF44664B);
  static const sageWash = Color(0xFFE8F0EA);
  static const surface = Color(0xFFFCF9F8);
  static const card = Color(0xFFFFFFFF);
  static const surfaceLow = Color(0xFFF6F3F2);
  static const surfaceContainer = Color(0xFFF0EDED);
  static const outlineVariant = Color(0xFFC1C8C2);
  static const outline = Color(0xFF727973);
  static const onSurface = Color(0xFF1C1B1B);
  static const onSurfaceVariant = Color(0xFF424844);
  static const amber = Color(0xFFFABC4D);
  static const amberSoft = Color(0xFFFFDEAD);
  static const tertiary = Color(0xFF281900);

  static const hairline = Color(0x0D173628); // rgba(23,54,40,.05)
  static const shadow = Color(0x0A173628); // rgba(23,54,40,.04)

  // Register these families in pubspec.yaml (or swap for google_fonts).
  // If they are not registered, Flutter falls back to the default font.
  static const serifFamily = 'PlayfairDisplay';
  static const sansFamily = 'PlusJakartaSans';
}

TextStyle _serif({
  double size = 18,
  FontWeight weight = FontWeight.w600,
  Color color = _N.primary,
  double? height,
  double? letterSpacing,
}) =>
    TextStyle(
      fontFamily: _N.serifFamily,
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );

TextStyle _sans({
  double size = 14,
  FontWeight weight = FontWeight.w400,
  Color color = _N.onSurface,
  double? height,
  double? letterSpacing,
}) =>
    TextStyle(
      fontFamily: _N.sansFamily,
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );

// ── Dummy orders ─────────────────────────────────────────────

class _MockOrder {
  const _MockOrder({
    required this.id,
    required this.seller,
    required this.items,
    required this.total,
    required this.status,
    required this.statusColor,
    required this.tab,
  });

  final String id;
  final String seller;
  final int items;
  final String total;
  final String status;
  final Color statusColor;
  final int tab; // 0=To Pay,1=To Ship,2=To Receive,3=Completed,4=Cancelled
}

const List<_MockOrder> _orders = [
  _MockOrder(
    id: '20261105-001',
    seller: 'TechZone PH',
    items: 2,
    total: '₱3,097',
    status: 'Pending Payment',
    statusColor: MColors.warning,
    tab: 0,
  ),
  _MockOrder(
    id: '20261104-008',
    seller: 'Fashion Hub',
    items: 1,
    total: '₱499',
    status: 'Awaiting Shipment',
    statusColor: MColors.info,
    tab: 1,
  ),
  _MockOrder(
    id: '20261102-015',
    seller: 'SportsPro PH',
    items: 1,
    total: '₱3,499',
    status: 'Out for Delivery',
    statusColor: MColors.primaryLight,
    tab: 2,
  ),
  _MockOrder(
    id: '20261028-033',
    seller: 'TechZone PH',
    items: 3,
    total: '₱5,296',
    status: 'Delivered',
    statusColor: MColors.success,
    tab: 3,
  ),
  _MockOrder(
    id: '20261020-019',
    seller: 'GlowUp Store',
    items: 2,
    total: '₱1,598',
    status: 'Delivered',
    statusColor: MColors.success,
    tab: 3,
  ),
  _MockOrder(
    id: '20261015-044',
    seller: 'Home Depot PH',
    items: 1,
    total: '₱2,199',
    status: 'Cancelled',
    statusColor: MColors.danger,
    tab: 4,
  ),
];

const List<String> _tabLabels = [
  'To Pay',
  'To Ship',
  'To Receive',
  'Completed',
  'Cancelled',
];

class MockupMyOrdersScreen extends StatefulWidget {
  const MockupMyOrdersScreen({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  State<MockupMyOrdersScreen> createState() => _MockupMyOrdersScreenState();
}

class _MockupMyOrdersScreenState extends State<MockupMyOrdersScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(
      length: _tabLabels.length,
      vsync: this,
      initialIndex: widget.initialTab,
    );
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  List<_MockOrder> _ordersForTab(int tab) =>
      _orders.where((o) => o.tab == tab).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: const BuyerNavBar(current: BuyerTab.account),
      backgroundColor: _N.surface,
      appBar: AppBar(
        backgroundColor: _N.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: _N.primary,
        titleSpacing: 0,
        title: Text('My Orders', style: _serif(size: 18, height: 1.3)),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.chat_outlined, size: 20),
          ),
          IconButton(
            onPressed: () {},
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.shopping_bag_outlined, size: 22),
                Positioned(
                  top: -1,
                  right: -1,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: _N.amber,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(46),
          child: Container(
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0x40C1C8C2)),
              ),
            ),
            child: TabBar(
              controller: _tabCtrl,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              labelPadding: const EdgeInsets.symmetric(horizontal: 12),
              labelColor: _N.primary,
              unselectedLabelColor: _N.onSurfaceVariant,
              indicator: const UnderlineTabIndicator(
                borderSide: BorderSide(width: 2.5, color: _N.primary),
              ),
              indicatorSize: TabBarIndicatorSize.label,
              labelStyle: _sans(size: 13, weight: FontWeight.w700),
              unselectedLabelStyle:
                  _sans(size: 13, weight: FontWeight.w500),
              tabs: List.generate(_tabLabels.length, _buildTab),
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: List.generate(
          _tabLabels.length,
          (i) => _buildOrderTab(i),
        ),
      ),
    );
  }

  // Tab label with a small count badge for in-progress tabs.
  Widget _buildTab(int i) {
    final count = i <= 2 ? _ordersForTab(i).length : 0;
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_tabLabels[i]),
          if (count > 0) ...[
            const SizedBox(width: 6),
            Container(
              width: 16,
              height: 16,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: _N.primary,
                shape: BoxShape.circle,
              ),
              child: Text(
                '$count',
                style: _sans(
                  size: 10,
                  weight: FontWeight.w700,
                  color: Colors.white,
                  height: 1,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOrderTab(int tab) {
    final orders = _ordersForTab(tab);
    if (orders.isEmpty) {
      return MEmptyState(
        icon: Icons.inbox_outlined,
        title: 'No orders here',
        subtitle: tab == 0
            ? 'You have no pending payments.'
            : tab == 3
                ? 'No completed orders yet.'
                : 'Nothing in this category yet.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (_, i) => _buildOrderCard(orders[i], tab),
    );
  }

  // ── Order card ──────────────────────────────────────────
  Widget _buildOrderCard(_MockOrder order, int tab) {
    void openDetails() => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MockupOrderDetailsScreen(orderId: order.id),
          ),
        );

    return GestureDetector(
      onTap: openDetails,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _N.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _N.hairline),
          boxShadow: const [
            BoxShadow(
              color: _N.shadow,
              blurRadius: 16,
              spreadRadius: -2,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Merchant bar + status pill
            Row(
              children: [
                const Icon(Icons.storefront_outlined,
                    size: 16, color: _N.secondary),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    order.seller.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _sans(
                      size: 11,
                      weight: FontWeight.w700,
                      color: _N.primary,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.verified, size: 15, color: _N.secondary),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: Color.lerp(Colors.white, order.statusColor, 0.14),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    order.status,
                    style: _sans(
                      size: 11,
                      weight: FontWeight.w700,
                      color: order.statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: _N.surfaceContainer),
            const SizedBox(height: 12),

            // Order meta
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Order #${order.id}',
                    style: _sans(
                      size: 12,
                      weight: FontWeight.w500,
                      color: _N.onSurfaceVariant,
                    ),
                  ),
                ),
                Icon(
                  tab == 0
                      ? Icons.hourglass_empty_rounded
                      : Icons.account_balance_wallet_outlined,
                  size: 14,
                  color: _N.outline,
                ),
                const SizedBox(width: 4),
                Text(
                  tab == 0 ? 'Awaiting payment' : 'Payment received',
                  style: _sans(size: 12, color: _N.outline),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Product block
            Row(
              children: [
                Container(
                  width: 72,
                  height: 88,
                  decoration: BoxDecoration(
                    color: _N.sageWash,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.inventory_2_outlined,
                      size: 30, color: _N.primary),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${order.items} ${order.items == 1 ? 'item' : 'items'}',
                        style: _sans(
                            size: 14, weight: FontWeight.w500, height: 1.3),
                      ),
                      const SizedBox(height: 4),
                      Text('from ${order.seller}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _sans(size: 12, color: _N.outline)),
                      const SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text('Total',
                              style: _sans(size: 12, color: _N.outline)),
                          const Spacer(),
                          Text(
                            order.total,
                            style: _sans(
                              size: 17,
                              weight: FontWeight.w700,
                              color: _N.primary,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Status note
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xB3F6F3F2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0x33C1C8C2)),
              ),
              child: Row(
                children: [
                  Icon(_noteIcon(tab), size: 18, color: _N.secondary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _noteText(tab),
                      style: _sans(
                          size: 12,
                          color: _N.onSurfaceVariant,
                          height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Actions
            if (tab == 3)
              Row(
                children: [
                  Expanded(
                    child: _pillButton(
                      label: 'Rate & Review',
                      outlined: true,
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const MockupRateReviewScreen(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _pillButton(
                      label: 'Buy Again',
                      outlined: false,
                      onPressed: () {},
                    ),
                  ),
                ],
              )
            else
              Row(
                children: [
                  Expanded(
                    child: _pillButton(
                      label: 'Contact Seller',
                      icon: Icons.chat_bubble_outline,
                      outlined: true,
                      onPressed: () {},
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _pillButton(
                      label: 'Order Details',
                      outlined: false,
                      onPressed: openDetails,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _pillButton({
    required String label,
    required bool outlined,
    required VoidCallback onPressed,
    IconData? icon,
  }) {
    final textColor = outlined ? _N.primary : Colors.white;
    final child = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 6),
        ],
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _sans(
                size: 12, weight: FontWeight.w600, color: textColor),
          ),
        ),
      ],
    );

    final padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 11);
    return outlined
        ? OutlinedButton(
            onPressed: onPressed,
            style: OutlinedButton.styleFrom(
              foregroundColor: _N.primary,
              side: const BorderSide(color: _N.primary),
              padding: padding,
              shape: const StadiumBorder(),
            ),
            child: child,
          )
        : FilledButton(
            onPressed: onPressed,
            style: FilledButton.styleFrom(
              backgroundColor: _N.primary,
              foregroundColor: Colors.white,
              padding: padding,
              shape: const StadiumBorder(),
            ),
            child: child,
          );
  }

  IconData _noteIcon(int tab) {
    switch (tab) {
      case 0:
        return Icons.schedule;
      case 1:
        return Icons.inventory_2_outlined;
      case 2:
        return Icons.local_shipping_outlined;
      case 3:
        return Icons.check_circle_outline;
      default:
        return Icons.cancel_outlined;
    }
  }

  String _noteText(int tab) {
    switch (tab) {
      case 0:
        return 'Complete your payment to confirm this order.';
      case 1:
        return 'The seller is preparing your order for shipment.';
      case 2:
        return 'Your parcel is on its way to you.';
      case 3:
        return 'Delivered. Tell others what you think of it!';
      default:
        return 'This order was cancelled.';
    }
  }
}

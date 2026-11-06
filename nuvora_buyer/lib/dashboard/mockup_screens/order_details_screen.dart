// ============================================================
// order_details_screen.dart
// Full detail view for a single order.
// Design: "Botanical Boutique" (Playfair Display + Plus Jakarta Sans,
// forest-green / sage / amber palette).
// Routing is unchanged — only the visuals were updated.
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'mockup_theme.dart';
import 'order_tracking_screen.dart';
import 'cancel_order_screen.dart';

// ── Design tokens (from the redesign) ───────────────────────
class _N {
  static const primary = Color(0xFF173628); // deep forest pine
  static const primaryDeep = Color(0xFF012114);
  static const secondary = Color(0xFF44664B);
  static const secondaryFixed = Color(0xFFC5ECCA);
  static const inversePrimary = Color(0xFFACCEBA);
  static const sageWash = Color(0xFFE8F0EA);
  static const secondaryContainer = Color(0xFFC2E9C7);
  static const surface = Color(0xFFFCF9F8);
  static const card = Color(0xFFFFFFFF);
  static const surfaceLow = Color(0xFFF6F3F2);
  static const surfaceContainer = Color(0xFFF0EDED);
  static const outlineVariant = Color(0xFFC1C8C2);
  static const outline = Color(0xFF727973);
  static const onSurface = Color(0xFF1C1B1B);
  static const onSurfaceVariant = Color(0xFF424844);
  static const amber = Color(0xFFFABC4D);

  static const hairline = Color(0x0D173628); // rgba(23,54,40,.05)
  static const shadow = Color(0x0A173628); // rgba(23,54,40,.04)
  static const divider = Color(0x33C1C8C2); // outline-variant @ 20%

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

class MockupOrderDetailsScreen extends StatelessWidget {
  const MockupOrderDetailsScreen({super.key, required this.orderId});

  final String orderId;

  void _openTracking(BuildContext context) => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => MockupOrderTrackingScreen(orderId: orderId)),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _N.surface,
      appBar: AppBar(
        backgroundColor: _N.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: _N.primary,
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Order Details', style: _serif(size: 18, height: 1.2)),
            Text(
              '#$orderId',
              style: _sans(
                size: 11,
                weight: FontWeight.w500,
                color: _N.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.chat_bubble_outline, size: 20),
                Positioned(
                  top: -1,
                  right: -1,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _N.amber,
                      shape: BoxShape.circle,
                      border: Border.all(color: _N.surface, width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.help_outline, size: 20),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          // ── Status hero ──────────────────────────────────
          _buildStatusBanner(context),
          const SizedBox(height: 14),
          // ── Tracking shortcut ────────────────────────────
          _trackingButton(context),
          const SizedBox(height: 14),
          // ── Delivery address ─────────────────────────────
          _buildAddressCard(),
          const SizedBox(height: 14),
          // ── Items ────────────────────────────────────────
          _buildItemsCard(),
          const SizedBox(height: 14),
          // ── Payment ──────────────────────────────────────
          _buildPaymentCard(),
          const SizedBox(height: 14),
          // ── Order info ───────────────────────────────────
          _buildInfoCard(context),
          const SizedBox(height: 14),
          // ── Support ──────────────────────────────────────
          _buildSupportCard(),
          const SizedBox(height: 20),
          // ── Cancel action ────────────────────────────────
          OutlinedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const MockupCancelOrderScreen()),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: MColors.danger,
              side: const BorderSide(color: MColors.danger),
              minimumSize: const Size(double.infinity, 50),
              shape: const StadiumBorder(),
            ),
            icon: const Icon(Icons.cancel_outlined, size: 18),
            label: Text('Cancel Order',
                style: _sans(
                    size: 14,
                    weight: FontWeight.w600,
                    color: MColors.danger)),
          ),
        ],
      ),
      // ── Sticky dual action bar ─────────────────────────
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color(0xF2FCF9F8),
          border: Border(top: BorderSide(color: Color(0x4DC1C8C2))),
          boxShadow: [
            BoxShadow(
              color: Color(0x0F173628),
              blurRadius: 16,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _N.primary,
                      side: const BorderSide(color: _N.primary),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: const StadiumBorder(),
                    ),
                    icon: const Icon(Icons.chat_bubble_outline, size: 18),
                    label: Text('Contact Seller',
                        style: _sans(
                            size: 14,
                            weight: FontWeight.w600,
                            color: _N.primary)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _openTracking(context),
                    style: FilledButton.styleFrom(
                      backgroundColor: _N.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: const StadiumBorder(),
                    ),
                    icon: const Icon(Icons.navigation_outlined, size: 18),
                    label: Text('Track Courier',
                        style: _sans(
                            size: 14,
                            weight: FontWeight.w600,
                            color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Shared pieces ───────────────────────────────────────
  Widget _card({required Widget child, EdgeInsets? padding}) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(18),
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
      child: child,
    );
  }

  Widget _sectionHeader(IconData? icon, String title, {Widget? trailing}) {
    return Container(
      padding: const EdgeInsets.only(bottom: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _N.divider)),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                color: Color(0x99C2E9C7),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 16, color: _N.primary),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(title, style: _serif(size: 17, height: 1.3)),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  // ── Hero status card ────────────────────────────────────
  Widget _buildStatusBanner(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        color: _N.primary,
        child: Stack(
          children: [
            Positioned(
              right: -32,
              bottom: -32,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border:
                      Border.all(color: const Color(0x1AFFFFFF), width: 14),
                ),
              ),
            ),
            Positioned(
              right: -8,
              top: -8,
              child: Container(
                width: 90,
                height: 90,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0x0DC5ECCA),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0x66012114),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: const Color(0x1AFFFFFF)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.local_shipping_outlined,
                            size: 15, color: _N.secondaryFixed),
                        const SizedBox(width: 6),
                        Text(
                          'NUVORA EXPRESS',
                          style: _sans(
                            size: 10,
                            weight: FontWeight.w700,
                            color: _N.secondaryFixed,
                            letterSpacing: 0.9,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Out for Delivery',
                    style: _serif(
                      size: 24,
                      color: Colors.white,
                      height: 1.3,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.schedule,
                          size: 16, color: _N.amber),
                      const SizedBox(width: 6),
                      Text(
                        'Expected: Today, Nov 5',
                        style: _sans(
                          size: 14,
                          color: const Color(0xF2ACCEBA),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.only(top: 12),
                    decoration: const BoxDecoration(
                      border: Border(
                        top: BorderSide(color: Color(0x26FFFFFF)),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Placed Nov 5, 2026 • 10:32 AM',
                            style: _sans(
                              size: 12,
                              color: const Color(0xB3ACCEBA),
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _openTracking(context),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Live Tracking',
                                style: _sans(
                                  size: 12,
                                  weight: FontWeight.w600,
                                  color: _N.secondaryFixed,
                                ),
                              ),
                              const Icon(Icons.chevron_right,
                                  size: 16, color: _N.secondaryFixed),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Track shipment shortcut ─────────────────────────────
  Widget _trackingButton(BuildContext context) {
    return GestureDetector(
      onTap: () => _openTracking(context),
      child: _card(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0x80C2E9C7),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _N.secondaryContainer),
              ),
              child: const Icon(Icons.map_outlined,
                  color: _N.secondary, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Track Shipment',
                      style: _sans(
                          size: 14,
                          weight: FontWeight.w700,
                          color: _N.primary)),
                  const SizedBox(height: 2),
                  Text('View real-time delivery status',
                      style: _sans(
                          size: 12, color: _N.onSurfaceVariant)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                color: _N.onSurfaceVariant, size: 20),
          ],
        ),
      ),
    );
  }

  // ── Items ───────────────────────────────────────────────
  Widget _buildItemsCard() {
    const items = [
      ('Wireless Earbuds Pro', '₱1,299', Color(0xFF2563EB), 1),
      ('USB-C Hub 7-in-1', '₱899', Color(0xFF475569), 2),
    ];

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Store header
          Container(
            padding: const EdgeInsets.only(bottom: 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: _N.divider)),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: _N.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Text('TZ',
                      style: _serif(size: 12, color: Colors.white)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              'TECHZONE PH',
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
                          const Icon(Icons.verified,
                              size: 15, color: _N.amber),
                        ],
                      ),
                      Text('Seller',
                          style: _sans(
                              size: 11, color: _N.onSurfaceVariant)),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _N.primary,
                    side: const BorderSide(color: Color(0x33173628)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    minimumSize: const Size(0, 30),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: const StadiumBorder(),
                  ),
                  icon: const Icon(Icons.forum_outlined, size: 14),
                  label: Text('Chat Seller',
                      style: _sans(
                          size: 12,
                          weight: FontWeight.w600,
                          color: _N.primary)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // Items
          for (int i = 0; i < items.length; i++) ...[
            if (i > 0)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Divider(height: 1, color: _N.divider),
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: Color.lerp(Colors.white, items[i].$3, 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _N.hairline),
                  ),
                  child: Icon(Icons.inventory_2_outlined,
                      color: items[i].$3, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: SizedBox(
                    height: 72,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          items[i].$1,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: _sans(
                            size: 14,
                            weight: FontWeight.w500,
                            color: _N.primary,
                            height: 1.3,
                          ),
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text('Qty: ${items[i].$4}',
                                style: _sans(
                                    size: 12,
                                    color: _N.onSurfaceVariant)),
                            const Spacer(),
                            Text(
                              items[i].$2,
                              style: _sans(
                                size: 16,
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
                ),
              ],
            ),
          ],
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.only(top: 12),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: _N.divider)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Seller: TechZone PH',
                    style:
                        _sans(size: 12, color: _N.onSurfaceVariant)),
                Text('Total: ₱3,097',
                    style: _sans(
                        size: 14,
                        weight: FontWeight.w700,
                        color: _N.primary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Delivery address ────────────────────────────────────
  Widget _buildAddressCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(Icons.location_on_outlined, 'Delivery Address'),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: Text('Juan Dela Cruz',
                    style: _sans(
                        size: 14,
                        weight: FontWeight.w600,
                        color: _N.primary)),
              ),
              Text('09171234567',
                  style: _sans(size: 12, color: _N.onSurfaceVariant)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '123 Sample Street, Batasan Hills,\nQuezon City, Metro Manila 1126',
            style: _sans(
                size: 14, color: _N.onSurfaceVariant, height: 1.5),
          ),
        ],
      ),
    );
  }

  // ── Payment ─────────────────────────────────────────────
  Widget _buildPaymentCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            null,
            'Payment Summary',
            trailing: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0x4DC2E9C7),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: _N.secondaryContainer),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: _N.secondary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text('Cash on Delivery',
                      style: _sans(
                          size: 11,
                          weight: FontWeight.w600,
                          color: _N.primary)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          _row('Merchandise', '₱2,997'),
          const SizedBox(height: 8),
          _row('Shipping Fee', '₱99'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.only(top: 12),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: _N.divider)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Expanded(
                  child: Text('Grand Total',
                      style: _serif(size: 16, weight: FontWeight.w700)),
                ),
                Text('₱3,096',
                    style: _serif(
                        size: 22,
                        weight: FontWeight.w700,
                        height: 1.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Order information ───────────────────────────────────
  Widget _buildInfoCard(BuildContext context) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            Icons.receipt_long_outlined,
            'Order Information',
            trailing: GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: orderId));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Order ID copied'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _N.surfaceContainer,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.content_copy,
                        size: 13, color: _N.primary),
                    const SizedBox(width: 4),
                    Text('Copy',
                        style: _sans(
                            size: 11,
                            weight: FontWeight.w600,
                            color: _N.primary)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          _row('Order ID', '#$orderId', semibold: true),
          const SizedBox(height: 10),
          _row('Waybill', 'NVR-2026-A4F9G2'),
          const SizedBox(height: 10),
          _row('Order Date', 'Nov 5, 2026 · 10:32 AM'),
          const SizedBox(height: 10),
          _row('Courier', 'Nuvora Express'),
        ],
      ),
    );
  }

  // ── Support strip ───────────────────────────────────────
  Widget _buildSupportCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _N.surfaceLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x4DC1C8C2)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: _N.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.support_agent,
                size: 18, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Need assistance with your package?',
                    style: _sans(
                        size: 12,
                        weight: FontWeight.w600,
                        color: _N.primary)),
                const SizedBox(height: 2),
                Text('Our support team is live',
                    style: _sans(
                        size: 12, color: _N.onSurfaceVariant)),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {},
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Help',
                    style: _sans(
                        size: 12,
                        weight: FontWeight.w600,
                        color: _N.primary)),
                const Icon(Icons.chevron_right,
                    size: 16, color: _N.primary),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value, {bool semibold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: _sans(size: 13, color: _N.onSurfaceVariant)),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: _sans(
              size: 13,
              weight: semibold ? FontWeight.w700 : FontWeight.w500,
              color: _N.primary,
            ),
          ),
        ),
      ],
    );
  }
}
// ============================================================
// order_confirmation_screen.dart
// Success screen shown after placing an order.
// Displays a reference/waybill number and next actions.
// Design: "Botanical Boutique" (Playfair Display + Plus Jakarta Sans,
// forest-green / sage / amber palette) — full redesign layout:
// hero, delivery ETA card, reference card, order summary,
// and sticky actions.
// Routing is unchanged — only the visuals were updated.
// ============================================================

import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'home_screen.dart';
import 'my_orders_screen.dart';
import '../../core/navigation/buyer_nav_bar.dart';

// ── Design tokens (from the redesign) ───────────────────────
class _N {
  static const primary = Color(0xFF173628); // deep forest pine
  static const secondary = Color(0xFF44664B);
  static const secondaryContainer = Color(0xFFC2E9C7);
  static const onSecondaryContainer = Color(0xFF486A4F);
  static const sageWash = Color(0xFFE8F0EA);
  static const surface = Color(0xFFFCF9F8);
  static const card = Color(0xFFFFFFFF);
  static const surfaceLow = Color(0xFFF6F3F2);
  static const surfaceContainer = Color(0xFFF0EDED);
  static const outlineVariant = Color(0xFFC1C8C2);
  static const outline = Color(0xFF727973);
  static const onSurfaceVariant = Color(0xFF424844);
  static const amber = Color(0xFFFABC4D);

  static const border = Color(0x0F173628); // rgba(23,54,40,.06)
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
  Color color = const Color(0xFF1C1B1B),
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

BoxDecoration _cardDecoration() => BoxDecoration(
      color: _N.card,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _N.border),
      boxShadow: const [
        BoxShadow(
          color: _N.shadow,
          blurRadius: 16,
          spreadRadius: -2,
          offset: Offset(0, 4),
        ),
      ],
    );

// Dummy order lines shown in the summary (mockup only).
class _ConfirmItem {
  const _ConfirmItem({
    required this.seller,
    required this.name,
    required this.qty,
    required this.price,
    required this.color,
  });

  final String seller;
  final String name;
  final int qty;
  final String price;
  final Color color;
}

const List<_ConfirmItem> _items = [
  _ConfirmItem(
    seller: 'TechZone PH',
    name: 'Wireless Earbuds Pro',
    qty: 1,
    price: '₱1,299',
    color: Color(0xFF2563EB),
  ),
  _ConfirmItem(
    seller: 'Fashion Hub',
    name: 'Casual Linen Shirt',
    qty: 1,
    price: '₱499',
    color: Color(0xFF16A34A),
  ),
];

class MockupOrderConfirmationScreen extends StatelessWidget {
  const MockupOrderConfirmationScreen({super.key});

  // Dummy waybill / reference
  static const String _waybill = 'NVR-2026-A4F9G2';
  static const String _orderId = 'ORD-20261105-0023';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: const BuyerNavBar(current: BuyerTab.account),
      backgroundColor: _N.surface,
      body: SafeArea(
        child: Column(
          children: [
            // ── Brand header ───────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Color(0x4DC1C8C2)),
                ),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 36),
                  Expanded(
                    child: Text(
                      'NUVORA',
                      textAlign: TextAlign.center,
                      style: _serif(
                        size: 20,
                        letterSpacing: 2.4,
                        height: 1.3,
                      ),
                    ),
                  ),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: _N.surfaceContainer,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.share_outlined,
                        size: 18, color: _N.primary),
                  ),
                ],
              ),
            ),
            // ── Scrollable content ─────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                child: Column(
                  children: [
                    _buildHero(),
                    const SizedBox(height: 24),
                    // Delivery ETA
                    _buildEtaCard(),
                    const SizedBox(height: 14),
                    // Reference / waybill card
                    _buildReferenceCard(context),
                    const SizedBox(height: 14),
                    // Order summary + payment
                    _buildSummaryCard(),
                    const SizedBox(height: 14),
                    // Reassurance note
                    _buildNote(),
                  ],
                ),
              ),
            ),
            // ── Sticky actions ─────────────────────────
            Container(
              decoration: const BoxDecoration(
                color: Color(0xF2FCF9F8),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x0D173628),
                    blurRadius: 16,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () => Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const MockupMyOrdersScreen()),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: _N.primary,
                          foregroundColor: Colors.white,
                          padding:
                              const EdgeInsets.symmetric(vertical: 15),
                          shape: const StadiumBorder(),
                          elevation: 3,
                          shadowColor: const Color(0x40173628),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Track My Order',
                                style: _sans(
                                    size: 14,
                                    weight: FontWeight.w600,
                                    color: Colors.white)),
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward, size: 18),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton.icon(
                        onPressed: () =>
                            Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                              builder: (_) => const MockupHomeScreen()),
                          (route) => false,
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: _N.primary,
                          padding:
                              const EdgeInsets.symmetric(vertical: 12),
                          shape: const StadiumBorder(),
                        ),
                        icon: const Icon(Icons.storefront_outlined,
                            size: 18),
                        label: Text('Continue Shopping',
                            style: _sans(
                                size: 14,
                                weight: FontWeight.w600,
                                color: _N.primary)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Hero: animated check + headline ─────────────────────
  Widget _buildHero() {
    return Column(
      children: [
        // Success mark with animated scale (same animation as before)
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.6, end: 1.0),
          duration: const Duration(milliseconds: 600),
          curve: Curves.elasticOut,
          builder: (_, scale, child) =>
              Transform.scale(scale: scale, child: child),
          child: SizedBox(
            width: 84,
            height: 84,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                    color: Color(0x80C2E9C7),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Container(
                    width: 54,
                    height: 54,
                    decoration: const BoxDecoration(
                      color: _N.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x40173628),
                          blurRadius: 16,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.check_rounded,
                        size: 30, color: Colors.white),
                  ),
                ),
                Positioned(
                  right: 2,
                  bottom: 2,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: _N.card,
                      shape: BoxShape.circle,
                      border:
                          Border.all(color: const Color(0x66C1C8C2)),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x1A000000),
                          blurRadius: 3,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.spa,
                        size: 14, color: _N.amber),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        // Status pill
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0x4DC2E9C7),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: _N.secondaryContainer),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.eco_outlined,
                  size: 13, color: _N.secondary),
              const SizedBox(width: 6),
              Text(
                'ORDER CONFIRMED',
                style: _sans(
                  size: 10,
                  weight: FontWeight.w700,
                  color: _N.onSecondaryContainer,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Order Placed!',
          textAlign: TextAlign.center,
          style: _serif(size: 28, height: 1.3, letterSpacing: -0.3),
        ),
        const SizedBox(height: 8),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 300),
          child: Text(
            'Your order has been placed successfully and is now being processed by the seller.',
            textAlign: TextAlign.center,
            style: _sans(
              size: 14,
              color: _N.onSurfaceVariant,
              height: 1.6,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: _N.surfaceLow,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: const Color(0x4DC1C8C2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text.rich(
                TextSpan(
                  style: _sans(
                    size: 11,
                    weight: FontWeight.w500,
                    color: _N.onSurfaceVariant,
                  ),
                  children: [
                    const TextSpan(text: 'Order '),
                    TextSpan(
                      text: _orderId,
                      style: _sans(
                        size: 11,
                        weight: FontWeight.w700,
                        color: _N.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 4,
                height: 4,
                decoration: const BoxDecoration(
                  color: _N.outline,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Nov 5, 2026 • 10:32 AM',
                style: _sans(
                  size: 11,
                  weight: FontWeight.w500,
                  color: _N.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Delivery ETA card ───────────────────────────────────
  Widget _buildEtaCard() {
    return Container(
      width: double.infinity,
      decoration: _cardDecoration(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Courier header
          Container(
            padding: const EdgeInsets.only(bottom: 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: _N.surfaceContainer)),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Color(0x66C2E9C7),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.directions_bike,
                      size: 20, color: _N.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Nuvora Express',
                          style: _sans(
                              size: 14,
                              weight: FontWeight.w700,
                              color: _N.primary)),
                      Text('Delivery partner',
                          style: _sans(
                              size: 12, color: _N.onSurfaceVariant)),
                    ],
                  ),
                ),
                const Icon(Icons.energy_savings_leaf_outlined,
                    size: 22, color: _N.secondary),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: Text(
                  'ESTIMATED DELIVERY',
                  style: _sans(
                    size: 10,
                    weight: FontWeight.w700,
                    color: _N.outline,
                    letterSpacing: 1,
                  ),
                ),
              ),
              Text('On Schedule',
                  style: _sans(
                      size: 12,
                      weight: FontWeight.w700,
                      color: _N.secondary)),
            ],
          ),
          const SizedBox(height: 6),
          Text('Today, Nov 5',
              style: _serif(size: 20, height: 1.3)),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.schedule,
                  size: 14, color: _N.onSurfaceVariant),
              const SizedBox(width: 6),
              Text('Window: 3:00 PM – 5:00 PM',
                  style: _sans(size: 12, color: _N.onSurfaceVariant)),
            ],
          ),
          const SizedBox(height: 16),
          // Journey progress
          Container(
            padding: const EdgeInsets.only(top: 12),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: _N.surfaceContainer)),
            ),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: SizedBox(
                    height: 6,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 0.4),
                      duration: const Duration(milliseconds: 900),
                      curve: Curves.easeOutCubic,
                      builder: (_, v, __) => LinearProgressIndicator(
                        value: v,
                        backgroundColor: _N.surfaceContainer,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            _N.primary),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Processing',
                        style: _sans(
                            size: 11,
                            weight: FontWeight.w700,
                            color: _N.primary)),
                    Text('Dispatched',
                        style: _sans(size: 11, color: _N.outline)),
                    Text('Delivered',
                        style: _sans(size: 11, color: _N.outline)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Reference / waybill card ────────────────────────────
  Widget _buildReferenceCard(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: _cardDecoration(),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _infoRow('Order ID', _orderId),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(height: 1, color: _N.surfaceContainer),
          ),
          _infoRow('Waybill / Tracking', _waybill),
          const SizedBox(height: 16),
          // Copy button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Clipboard.setData(const ClipboardData(text: _waybill));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Waybill number copied!',
                        style: _sans(
                            size: 13,
                            weight: FontWeight.w600,
                            color: Colors.white)),
                    backgroundColor: _N.primary,
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: _N.primary,
                backgroundColor: _N.surfaceLow,
                side: const BorderSide(color: Color(0x66C1C8C2)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: const StadiumBorder(),
              ),
              icon: const Icon(Icons.content_copy, size: 16),
              label: Text('Copy Waybill',
                  style: _sans(
                      size: 13,
                      weight: FontWeight.w600,
                      color: _N.primary)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Order summary + payment ─────────────────────────────
  Widget _buildSummaryCard() {
    return Container(
      width: double.infinity,
      decoration: _cardDecoration(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.only(bottom: 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: _N.surfaceContainer)),
            ),
            child: Row(
              children: [
                const Icon(Icons.storefront,
                    size: 20, color: _N.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Order Summary',
                      style: _serif(size: 17, height: 1.3)),
                ),
                Text('${_items.length} items',
                    style: _sans(
                        size: 11,
                        weight: FontWeight.w600,
                        color: _N.outline)),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // Items
          for (int i = 0; i < _items.length; i++) ...[
            if (i > 0) const SizedBox(height: 14),
            _buildItem(_items[i]),
          ],
          const SizedBox(height: 14),
          // Financial summary
          Container(
            padding: const EdgeInsets.only(top: 12),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: _N.surfaceContainer)),
            ),
            child: Column(
              children: [
                _moneyRow('Subtotal', '₱1,798'),
                const SizedBox(height: 8),
                _moneyRow('Shipping Fee', '₱73'),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.only(top: 10),
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Color(0x33C1C8C2)),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Expanded(
                        child: Text('Order Total',
                            style: _sans(
                                size: 14,
                                weight: FontWeight.w700,
                                color: _N.primary)),
                      ),
                      Text(
                        '₱1,871',
                        style: _serif(
                            size: 22,
                            weight: FontWeight.w700,
                            height: 1.3),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // Payment + destination
          Row(
            children: [
              Expanded(
                child: _detailTile(
                  'PAYMENT METHOD',
                  Icons.payments_outlined,
                  'Cash on Delivery',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _detailTile(
                  'DESTINATION',
                  Icons.location_on_outlined,
                  'Quezon City',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildItem(_ConfirmItem item) {
    return Row(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: Color.lerp(Colors.white, item.color, 0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0x4DC1C8C2)),
          ),
          child: Icon(Icons.inventory_2_outlined,
              size: 26, color: item.color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.seller.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _sans(
                  size: 10,
                  weight: FontWeight.w700,
                  color: _N.secondary,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                item.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _sans(
                    size: 14,
                    weight: FontWeight.w600,
                    color: _N.primary),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text('Qty: ${item.qty}',
                      style: _sans(size: 11, color: _N.outline)),
                  const Spacer(),
                  Text(
                    item.price,
                    style: _sans(
                      size: 15,
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
    );
  }

  Widget _moneyRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: _sans(size: 12, color: _N.onSurfaceVariant)),
        Text(value,
            style: _sans(
                size: 12, weight: FontWeight.w600, color: _N.primary)),
      ],
    );
  }

  Widget _detailTile(String label, IconData icon, String value) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _N.surfaceLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x33C1C8C2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: _sans(
              size: 9,
              weight: FontWeight.w700,
              color: _N.outline,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(icon, size: 15, color: _N.secondary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _sans(
                      size: 12,
                      weight: FontWeight.w600,
                      color: _N.primary),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Dashed reassurance note ─────────────────────────────
  Widget _buildNote() {
    return CustomPaint(
      painter: const _DashedBorderPainter(
        color: Color(0x99C1C8C2),
        radius: 16,
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0x80FCF9F8),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          "We'll let you know as soon as your parcel is on its way.",
          textAlign: TextAlign.center,
          style: _sans(
              size: 12, color: _N.onSurfaceVariant, height: 1.5),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: _sans(size: 12, color: _N.onSurfaceVariant)),
        const SizedBox(width: 16),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: _sans(
              size: 14,
              weight: FontWeight.w700,
              color: _N.primary,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ],
    );
  }
}

/// Dashed rounded-rectangle outline for the reassurance note.
class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Offset.zero & size,
        Radius.circular(radius),
      ));

    for (final PathMetric metric in path.computeMetrics()) {
      double d = 0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, d + 5), paint);
        d += 9;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter old) =>
      old.color != color || old.radius != radius;
}
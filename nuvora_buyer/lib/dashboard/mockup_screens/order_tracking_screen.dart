// ============================================================
// order_tracking_screen.dart
// Delivery tracking: waybill number, status timeline,
// and rider info card.
// Design: "Botanical Boutique" (Playfair Display + Plus Jakarta Sans,
// forest-green / sage / amber palette).
// Only the visuals were updated.
// ============================================================

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ── Design tokens (from the redesign) ───────────────────────
class _N {
  static const primary = Color(0xFF173628); // deep forest pine
  static const primaryDeep = Color(0xFF012114);
  static const secondary = Color(0xFF44664B);
  static const secondaryFixed = Color(0xFFC5ECCA);
  static const secondaryContainer = Color(0xFFC2E9C7);
  static const onSecondaryContainer = Color(0xFF486A4F);
  static const sageWash = Color(0xFFE8F0EA);
  static const surface = Color(0xFFFCF9F8);
  static const card = Color(0xFFFFFFFF);
  static const surfaceLow = Color(0xFFF6F3F2);
  static const surfaceContainer = Color(0xFFF0EDED);
  static const surfaceHighest = Color(0xFFE5E2E1);
  static const outlineVariant = Color(0xFFC1C8C2);
  static const outline = Color(0xFF727973);
  static const onSurface = Color(0xFF1C1B1B);
  static const onSurfaceVariant = Color(0xFF424844);
  static const amber = Color(0xFFFABC4D);

  static const border = Color(0x4DC1C8C2); // outline-variant @ 30%
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

const String _waybill = 'NVR-2026-A4F9G2';

class MockupOrderTrackingScreen extends StatelessWidget {
  const MockupOrderTrackingScreen({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _N.surface,
      appBar: AppBar(
        backgroundColor: _N.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: _N.primary,
        centerTitle: true,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Track Order', style: _serif(size: 18, height: 1.2)),
            Text(
              '#$orderId',
              style: _sans(
                size: 10,
                weight: FontWeight.w700,
                color: _N.secondary,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.share_outlined, size: 20),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.support_agent, size: 22),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          // ── Live map + ETA / waybill summary ─────────────
          _buildMapCard(),
          const SizedBox(height: 18),
          // ── Rider info ───────────────────────────────────
          _buildRiderCard(),
          const SizedBox(height: 18),
          // ── Status timeline ──────────────────────────────
          _buildTimeline(context),
        ],
      ),
      // ── Sticky action dock ─────────────────────────────
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color(0xF2FCF9F8),
          border: Border(top: BorderSide(color: _N.border)),
          boxShadow: [
            BoxShadow(
              color: Color(0x14173628),
              blurRadius: 24,
              spreadRadius: -4,
              offset: Offset(0, -8),
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
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      backgroundColor: _N.surfaceContainer,
                      foregroundColor: _N.primary,
                      side: const BorderSide(color: Color(0x66C1C8C2)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: const StadiumBorder(),
                    ),
                    child: Text('Delivery Notes',
                        style: _sans(
                            size: 14,
                            weight: FontWeight.w600,
                            color: _N.primary)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {},
                    style: FilledButton.styleFrom(
                      backgroundColor: _N.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: const StadiumBorder(),
                    ),
                    icon: const Icon(Icons.sync, size: 18),
                    label: Text('Refresh Map',
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

  // ── Map hero + ETA drawer ───────────────────────────────
  Widget _buildMapCard() {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMapPlaceholder(),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: _N.card,
              border: Border(top: BorderSide(color: Color(0x33C1C8C2))),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _N.secondaryContainer,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'OUT FOR DELIVERY',
                        style: _sans(
                          size: 10,
                          weight: FontWeight.w700,
                          color: _N.onSecondaryContainer,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('• Nuvora Express',
                        style: _sans(
                            size: 11, color: _N.onSurfaceVariant)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Today, 3:00–5:00 PM',
                  style: _serif(size: 24, height: 1.3, letterSpacing: -0.2),
                ),
                const SizedBox(height: 2),
                Text(
                  'Estimated arrival window',
                  style: _sans(
                    size: 12,
                    weight: FontWeight.w500,
                    color: _N.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapPlaceholder() {
    const mapHeight = 260.0;

    return SizedBox(
      height: mapHeight,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final sx = w / 400;
          final sy = mapHeight / 300;
          Offset pt(double x, double y) => Offset(x * sx, y * sy);

          return Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              Positioned.fill(
                child: CustomPaint(painter: _MapPainter()),
              ),
              // Seller origin pin
              _pin(
                pt(70, 235),
                28,
                _circlePin(
                  size: 28,
                  color: _N.card,
                  borderColor: _N.primary,
                  icon: Icons.storefront_outlined,
                  iconColor: _N.primary,
                  iconSize: 15,
                ),
                'Seller',
                labelBg: const Color(0xE6FFFFFF),
                labelColor: _N.primary,
              ),
              // Destination pin
              _pin(
                pt(330, 105),
                32,
                _circlePin(
                  size: 32,
                  color: _N.primary,
                  borderColor: _N.card,
                  icon: Icons.home_outlined,
                  iconColor: Colors.white,
                  iconSize: 16,
                ),
                'Home',
                labelBg: const Color(0xF2FFFFFF),
                labelColor: _N.primary,
              ),
              // Courier marker
              _pin(
                pt(205, 135),
                48,
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        color: Color(0x4D44664B),
                        shape: BoxShape.circle,
                      ),
                    ),
                    _circlePin(
                      size: 40,
                      color: _N.primary,
                      borderColor: _N.card,
                      icon: Icons.two_wheeler,
                      iconColor: Colors.white,
                      iconSize: 20,
                      shadow: true,
                    ),
                  ],
                ),
                'Roberto C.',
                labelBg: _N.primary,
                labelColor: Colors.white,
                dot: true,
              ),
              // Live pill
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xE6FFFFFF),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: _N.border),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x14173628),
                        blurRadius: 16,
                        spreadRadius: -2,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: _N.secondary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Rider is nearby',
                        style: _sans(
                          size: 11,
                          weight: FontWeight.w700,
                          color: _N.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Placeholder note
              Positioned(
                left: 12,
                bottom: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xB3FFFFFF),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Live map integration coming soon',
                    style: _sans(size: 10, color: _N.onSurfaceVariant),
                  ),
                ),
              ),
              // Recenter button
              Positioned(
                right: 12,
                bottom: 12,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: const BoxDecoration(
                    color: Color(0xF2FFFFFF),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Color(0x26000000), blurRadius: 4),
                    ],
                  ),
                  child: const Icon(Icons.my_location,
                      size: 16, color: _N.primary),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _circlePin({
    required double size,
    required Color color,
    required Color borderColor,
    required IconData icon,
    required Color iconColor,
    required double iconSize,
    bool shadow = false,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: Color(shadow ? 0x40000000 : 0x26000000),
            blurRadius: shadow ? 8 : 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(icon, size: iconSize, color: iconColor),
    );
  }

  // Places a pin so that the middle of its circle sits on [center].
  Widget _pin(
    Offset center,
    double circleSize,
    Widget circle,
    String label, {
    required Color labelBg,
    required Color labelColor,
    bool dot = false,
  }) {
    return Positioned(
      left: center.dx - 45,
      top: center.dy - circleSize / 2,
      width: 90,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          circle,
          const SizedBox(height: 3),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: labelBg,
              borderRadius: BorderRadius.circular(dot ? 999 : 4),
              boxShadow: const [
                BoxShadow(color: Color(0x1A000000), blurRadius: 3),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _sans(
                      size: 10,
                      weight: FontWeight.w700,
                      color: labelColor,
                    ),
                  ),
                ),
                if (dot) ...[
                  const SizedBox(width: 4),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: _N.secondaryFixed,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Rider card ──────────────────────────────────────────
  Widget _buildRiderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: _N.surfaceLow, width: 2),
                    ),
                    child: CircleAvatar(
                      radius: 30,
                      backgroundColor: _N.sageWash,
                      child: Text('R',
                          style: _serif(size: 24, color: _N.primary)),
                    ),
                  ),
                  Positioned(
                    bottom: -4,
                    right: -4,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: _N.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: _N.card, width: 2),
                      ),
                      child: const Icon(Icons.verified,
                          size: 13, color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Roberto Cruz',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: _serif(size: 18, height: 1.3),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _N.surfaceLow,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star_rounded,
                                  size: 14, color: _N.amber),
                              const SizedBox(width: 3),
                              Text('4.9',
                                  style: _sans(
                                      size: 12,
                                      weight: FontWeight.w700)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text('320 deliveries · E-Bike',
                        style: _sans(
                            size: 12, color: _N.onSurfaceVariant)),
                    const SizedBox(height: 6),
                    Text(
                      'PLATE: ABC 1234',
                      style: _sans(
                        size: 11,
                        weight: FontWeight.w700,
                        color: _N.secondary,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    backgroundColor: _N.surfaceLow,
                    foregroundColor: _N.primary,
                    side: const BorderSide(color: Color(0x4DC1C8C2)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: const StadiumBorder(),
                  ),
                  icon: const Icon(Icons.call_outlined, size: 18),
                  label: Text('Call Rider',
                      style: _sans(
                          size: 13,
                          weight: FontWeight.w600,
                          color: _N.primary)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {},
                  style: FilledButton.styleFrom(
                    backgroundColor: _N.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: const StadiumBorder(),
                  ),
                  icon: const Icon(Icons.chat_bubble_outline, size: 18),
                  label: Text('Message Rider',
                      style: _sans(
                          size: 13,
                          weight: FontWeight.w600,
                          color: Colors.white)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Timeline ────────────────────────────────────────────
  Widget _buildTimeline(BuildContext context) {
    const steps = [
      ('Order Placed', 'Nov 5, 2026 · 10:32 AM', true, Icons.check),
      ('Payment Confirmed', 'Nov 5, 2026 · 10:35 AM', true,
          Icons.verified_user_outlined),
      ('Seller Packed Order', 'Nov 5, 2026 · 12:00 PM', true,
          Icons.inventory_2_outlined),
      ('Picked Up by Rider', 'Nov 5, 2026 · 1:45 PM', true,
          Icons.two_wheeler),
      ('Out for Delivery', 'Nov 5, 2026 · 2:10 PM', true,
          Icons.local_shipping_outlined),
      ('Delivered', 'Pending', false, Icons.home_outlined),
    ];

    // The last completed step is the "active" one.
    final activeIndex = steps.lastIndexWhere((s) => s.$3);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with copyable waybill
          Container(
            padding: const EdgeInsets.only(bottom: 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: _N.surfaceHighest)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Delivery Status',
                          style: _serif(size: 17, height: 1.3)),
                      Text('Live logistics milestones',
                          style: _sans(
                              size: 12, color: _N.onSurfaceVariant)),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(const ClipboardData(text: _waybill));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Waybill copied'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _N.surfaceLow,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: const Color(0x66C1C8C2)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _waybill,
                          style: _sans(
                            size: 10,
                            weight: FontWeight.w700,
                            color: _N.primary,
                            letterSpacing: 0.6,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.content_copy,
                            size: 14, color: _N.onSurfaceVariant),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          for (int i = 0; i < steps.length; i++)
            _timelineRow(
              label: steps[i].$1,
              time: steps[i].$2,
              done: steps[i].$3,
              icon: steps[i].$4,
              isActive: i == activeIndex,
              isLast: i == steps.length - 1,
              nextDone: i + 1 < steps.length && steps[i + 1].$3,
            ),
        ],
      ),
    );
  }

  Widget _timelineRow({
    required String label,
    required String time,
    required bool done,
    required IconData icon,
    required bool isActive,
    required bool isLast,
    required bool nextDone,
  }) {
    final nodeSize = isActive ? 26.0 : 22.0;

    Widget node;
    if (isActive) {
      node = Container(
        width: nodeSize,
        height: nodeSize,
        decoration: BoxDecoration(
          color: _N.primary,
          shape: BoxShape.circle,
          border: Border.all(color: _N.secondaryContainer, width: 3),
        ),
        child: Icon(icon, size: 13, color: Colors.white),
      );
    } else if (done) {
      node = Container(
        width: nodeSize,
        height: nodeSize,
        decoration: const BoxDecoration(
          color: _N.secondary,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 12, color: Colors.white),
      );
    } else {
      node = Container(
        width: nodeSize,
        height: nodeSize,
        decoration: BoxDecoration(
          color: _N.surfaceHighest,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0x66C1C8C2)),
        ),
        child: Icon(icon, size: 12, color: _N.outline),
      );
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                node,
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      color: (done && nextDone)
                          ? const Color(0x6644664B)
                          : const Color(0x66C1C8C2),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 20, top: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Expanded(
                        child: Text(
                          label,
                          style: _sans(
                            size: 14,
                            weight:
                                isActive ? FontWeight.w700 : FontWeight.w600,
                            color: isActive
                                ? _N.primary
                                : (done ? _N.onSurface : _N.outline),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        time,
                        style: _sans(
                          size: 11,
                          weight: isActive
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isActive
                              ? _N.secondary
                              : _N.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  if (isActive) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0x66C2E9C7),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.near_me,
                              size: 12, color: _N.onSecondaryContainer),
                          const SizedBox(width: 6),
                          Text(
                            'Rider location updated in real-time',
                            style: _sans(
                              size: 10,
                              weight: FontWeight.w600,
                              color: _N.onSecondaryContainer,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Stylized botanical map background (replaces the plain grid).
class _MapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Draw in a 400x300 design space, stretched to fit.
    canvas.save();
    canvas.scale(size.width / 400, size.height / 300);

    canvas.drawRect(
      const Rect.fromLTWH(0, 0, 400, 300),
      Paint()..color = const Color(0xFFE6EDE7),
    );

    // Water bodies
    final river = Path()
      ..moveTo(-20, 60)
      ..cubicTo(80, 90, 110, 30, 220, 50)
      ..cubicTo(310, 65, 340, 10, 420, 20)
      ..lineTo(420, -10)
      ..lineTo(-20, -10)
      ..close();
    canvas.drawPath(river, Paint()..color = const Color(0xFFD3DFD8));

    final lake = Path()
      ..moveTo(-20, 190)
      ..cubicTo(60, 170, 140, 220, 230, 195)
      ..cubicTo(330, 170, 370, 240, 420, 230)
      ..lineTo(420, 310)
      ..lineTo(-20, 310)
      ..close();
    canvas.drawPath(
        lake, Paint()..color = const Color(0x99D8E4DD)); // ~60% opacity

    // Street grid
    void street(double x1, double y1, double x2, double y2, double w,
        Color c) {
      canvas.drawLine(
        Offset(x1, y1),
        Offset(x2, y2),
        Paint()
          ..color = c
          ..strokeWidth = w,
      );
    }

    const soft = Color(0xFFDFE7E1);
    const white = Color(0xFFFFFFFF);
    street(30, 0, 30, 300, 3, soft);
    street(90, 0, 110, 300, 4, soft);
    street(170, 0, 160, 300, 5, white);
    street(260, 0, 275, 300, 3, soft);
    street(340, 0, 330, 300, 4, white);
    street(0, 70, 400, 90, 3, soft);
    street(0, 135, 400, 135, 6, white);
    street(0, 210, 400, 195, 4, soft);
    street(0, 270, 400, 280, 3, white);

    // Parks
    final park1 = Path()
      ..moveTo(35, 155)
      ..quadraticBezierTo(60, 140, 75, 165)
      ..quadraticBezierTo(90, 190, 100, 200)
      ..quadraticBezierTo(65, 220, 40, 200)
      ..close();
    canvas.drawPath(park1, Paint()..color = const Color(0xCCCAD8CE));

    final park2 = Path()
      ..moveTo(290, 85)
      ..quadraticBezierTo(320, 70, 345, 95)
      ..quadraticBezierTo(370, 120, 370, 140)
      ..quadraticBezierTo(335, 150, 300, 130)
      ..close();
    canvas.drawPath(park2, Paint()..color = const Color(0xB3CAD8CE));

    // Route: seller -> home
    final route = Path()
      ..moveTo(70, 235)
      ..lineTo(120, 235)
      ..lineTo(165, 135)
      ..lineTo(245, 135)
      ..lineTo(285, 105)
      ..lineTo(330, 105);

    canvas.drawPath(
      route,
      Paint()
        ..color = const Color(0xFF173628)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    final dash = Paint()
      ..color = const Color(0xFFC2E9C7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (final metric in route.computeMetrics()) {
      double d = 0;
      while (d < metric.length) {
        canvas.drawPath(
          metric.extractPath(d, math.min(d + 4, metric.length)),
          dash,
        );
        d += 8;
      }
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
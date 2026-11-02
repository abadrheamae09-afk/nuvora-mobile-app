import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/data/rider_session.dart';
import '../../core/data/rider_work.dart';
import '../../theme/app_colors.dart';
import '../scanner/parcel_scanner_screen.dart';
import 'delivery_detail_screen.dart';

const double _radius = 16;

/// Rider home: greeting header with accrued earnings, the scan action, a parcel
/// overview and the next active delivery.
class HomeScreen extends StatefulWidget {
  final VoidCallback? onOpenParcels;
  final VoidCallback? onOpenEarnings;
  final VoidCallback? onOpenNotifications;

  const HomeScreen({
    super.key,
    this.onOpenParcels,
    this.onOpenEarnings,
    this.onOpenNotifications,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final _store = RiderWorkStore.instance;

  // Drives the animated header backdrop (loops forever, 0.0 → 1.0).
  late final AnimationController _bgController;

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();
  }

  @override
  void dispose() {
    _bgController.dispose();
    super.dispose();
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
  }

  String get _today {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final now = DateTime.now();
    return '${days[now.weekday - 1]}, ${now.day} ${months[now.month - 1]}';
  }

  String _money(double value) => '₱${value.toStringAsFixed(2)}';

  Future<void> _openScanner() async {
    HapticFeedback.selectionClick();
    final code = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const ParcelScannerScreen()),
    );
    if (!mounted || code == null) return;

    final parcel = _store.find(code);
    if (parcel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No parcel assigned to you matches "$code".')),
      );
      widget.onOpenParcels?.call();
      return;
    }
    await _openParcel(parcel);
  }

  Future<void> _openParcel(RiderParcel parcel) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DeliveryDetailScreen(parcel: parcel)),
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Light status bar icons because the header is dark.
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: ListenableBuilder(
          listenable: _store,
          builder: (context, _) {
            final active = _store.parcels.isEmpty ? null : _store.parcels.first;
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderPanel(),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      20,
                      24,
                      20,
                      28 + MediaQuery.of(context).padding.bottom,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildScanButton(),
                        const SizedBox(height: 24),
                        _buildSectionTitle('Parcel overview'),
                        const SizedBox(height: 12),
                        _buildStats(),
                        const SizedBox(height: 28),
                        _buildActiveDelivery(active),
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

  // ── Shared flat card ──────────────────────────────────────────────────────
  Widget _card({
    required Widget child,
    VoidCallback? onTap,
    EdgeInsets padding = const EdgeInsets.all(16),
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_radius),
        border: Border.all(color: AppColors.border),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(_radius),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String text) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            color: AppColors.ink,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  // ── Green header: animated backdrop + greeting + earnings ─────────────────
  Widget _buildHeaderPanel() {
    final topInset = MediaQuery.of(context).padding.top;

    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(28),
        bottomRight: Radius.circular(28),
      ),
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.headerBottom, AppColors.headerTop],
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: RepaintBoundary(
                  child: AnimatedBuilder(
                    animation: _bgController,
                    builder: (context, _) => CustomPaint(
                      painter: _HeaderBackdropPainter(_bgController.value),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20, topInset + 20, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderRow(),
                  const SizedBox(height: 20),
                  _buildEarningsCard(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderRow() {
    final session = RiderSession.instance;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _greeting,
                style: const TextStyle(
                  color: Color(0xB3FFFFFF),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                session.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.glass,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.glassBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.gold,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Online',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 1,
                      height: 10,
                      color: const Color(0x40FFFFFF),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _today,
                      style: const TextStyle(
                        color: Color(0xB3FFFFFF),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Semantics(
          button: true,
          label: 'Notifications',
          child: Material(
            color: AppColors.glass,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: widget.onOpenNotifications,
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.glassBorder),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Icon(
                      Icons.notifications_none_rounded,
                      color: Colors.white,
                      size: 25,
                    ),
                    if (_store.unreadCount > 0)
                      Positioned(
                        right: 13,
                        top: 13,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.gold,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEarningsCard() {
    return Material(
      color: AppColors.glass,
      borderRadius: BorderRadius.circular(_radius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: widget.onOpenEarnings,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_radius),
            border: Border.all(color: AppColors.glassBorder),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Accrued earnings',
                      style: TextStyle(
                        color: Color(0xB3FFFFFF),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _money(_store.accruedTotal),
                      style: const TextStyle(
                        color: AppColors.gold,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const Text(
                'Details',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Colors.white,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Main action ───────────────────────────────────────────────────────────
  Widget _buildScanButton() {
    return Material(
      color: AppColors.primary,
      borderRadius: BorderRadius.circular(_radius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: _openScanner,
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          child: Row(
            children: [
              Icon(
                Icons.qr_code_scanner_rounded,
                color: Colors.white,
                size: 30,
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Scan a parcel',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Pick up, move and deliver by scanning',
                      style: TextStyle(color: Color(0xCCFFFFFF), fontSize: 13),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 22),
            ],
          ),
        ),
      ),
    );
  }

  // ── Parcel stats: one card, four cells, thin dividers ─────────────────────
  Widget _buildStats() {
    return _card(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _StatCell(
                  icon: Icons.inventory_2_outlined,
                  value: '${_store.parcels.length}',
                  label: 'Assigned now',
                ),
              ),
              _VDivider(),
              Expanded(
                child: _StatCell(
                  icon: Icons.assignment_turned_in_outlined,
                  value: '${_store.pickupCount}',
                  label: 'Pickup',
                ),
              ),
            ],
          ),
          const Divider(height: 1, thickness: 1, color: AppColors.border),
          Row(
            children: [
              Expanded(
                child: _StatCell(
                  icon: Icons.local_shipping_outlined,
                  value: '${_store.deliveryCount}',
                  label: 'Delivery',
                ),
              ),
              _VDivider(),
              Expanded(
                child: _StatCell(
                  icon: Icons.near_me_outlined,
                  value: '${_store.onTheWayCount}',
                  label: 'On the way',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Active delivery ───────────────────────────────────────────────────────
  Widget _buildActiveDelivery(RiderParcel? parcel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Active delivery'),
        const SizedBox(height: 12),
        if (parcel == null)
          _card(
            onTap: widget.onOpenParcels,
            child: const Text(
              'No active assignments yet. Scan a parcel to start.',
              style: TextStyle(color: AppColors.muted),
            ),
          )
        else
          _card(
            onTap: () => _openParcel(parcel),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        parcel.tracking,
                        style: const TextStyle(
                          color: AppColors.ink,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.mint,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        riderStageBadge(parcel.stage),
                        style: const TextStyle(
                          color: AppColors.primaryDark,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.place_outlined, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        riderStageSubtitle(parcel),
                        style: const TextStyle(
                          color: AppColors.ink,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1, thickness: 1, color: AppColors.border),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(
                      Icons.near_me_outlined,
                      size: 16,
                      color: AppColors.muted,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        riderStageTitle(parcel),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const Text(
                      'View details',
                      style: TextStyle(
                        color: AppColors.primaryDark,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.primaryDark,
                      size: 20,
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Animated header backdrop
//
// `t` loops from 0.0 to 1.0. Every movement uses whole sine cycles or
// wrap-around values, so the loop is seamless.
// ─────────────────────────────────────────────────────────────────────────────
class _HeaderBackdropPainter extends CustomPainter {
  _HeaderBackdropPainter(this.t);

  final double t;

  static const _twoPi = math.pi * 2;

  static const _particles = <_Particle>[
    _Particle(0.12, 0.00, 1, 3.0, AppColors.gold),
    _Particle(0.28, 0.35, 1, 2.0, AppColors.primaryLight),
    _Particle(0.42, 0.70, 1, 2.5, AppColors.gold),
    _Particle(0.58, 0.15, 1, 3.5, AppColors.primaryLight),
    _Particle(0.72, 0.55, 1, 2.0, AppColors.gold),
    _Particle(0.86, 0.85, 1, 3.0, AppColors.primaryLight),
    _Particle(0.94, 0.40, 1, 2.0, AppColors.gold),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    canvas.clipRect(Offset.zero & size);

    final w = size.width;
    final h = size.height;
    final a = t * _twoPi;

    final bigPaint = Paint()..color = Colors.white.withAlpha(16);
    canvas.drawCircle(
      Offset(w * 0.88 + math.sin(a) * 18, h * 0.10 + math.cos(a) * 14),
      88,
      bigPaint,
    );

    final deepPaint = Paint()..color = AppColors.primaryDeep.withAlpha(60);
    canvas.drawCircle(
      Offset(w * 0.08 + math.cos(a) * 16, h * 0.92 + math.sin(a) * 12),
      78,
      deepPaint,
    );

    final smallPaint = Paint()..color = Colors.white.withAlpha(12);
    canvas.drawCircle(
      Offset(w * 0.55 - math.sin(a) * 22, h * 0.50 + math.cos(a * 2) * 10),
      44,
      smallPaint,
    );

    // Two thin rings that expand and fade.
    final ringCenter = Offset(
      w * 0.88 + math.sin(a) * 18,
      h * 0.10 + math.cos(a) * 14,
    );
    for (final phase in const [0.0, 0.5]) {
      final p = (t + phase) % 1.0;
      final radius = 40 + p * 100;
      final alpha = ((1 - p) * 60).round().clamp(0, 255);
      final ringPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = AppColors.gold.withAlpha(alpha);
      canvas.drawCircle(ringCenter, radius, ringPaint);
    }

    // Small dots floating upward, fading in and out.
    for (final p in _particles) {
      final prog = (t * p.speed + p.phase) % 1.0;
      final y = h - prog * h;
      final x = w * p.x + math.sin((t * p.speed + p.phase) * _twoPi) * 10;

      final fade = math.sin(prog * math.pi);
      final alpha = (fade * 140).round().clamp(0, 255);

      canvas.drawCircle(
        Offset(x, y),
        p.size,
        Paint()..color = p.color.withAlpha(alpha),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _HeaderBackdropPainter old) => old.t != t;
}

class _Particle {
  const _Particle(this.x, this.phase, this.speed, this.size, this.color);

  final double x, phase, size;
  final int speed;
  final Color color;
}

class _StatCell extends StatelessWidget {
  final IconData icon;
  final String value, label;

  const _StatCell({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: AppColors.mint,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primaryDark, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.primaryDeep,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VDivider extends StatelessWidget {
  const _VDivider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 44, color: AppColors.border);
  }
}

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/data/rider_session.dart';
import '../../core/data/rider_work.dart';
import '../../theme/app_colors.dart';
import '../scanner/parcel_scanner_screen.dart';
import 'delivery_detail_screen.dart';

const double _radius = 16;

/// Colours taken from the redesign (stitch_mobile_app_redesign).
class _Palette {
  static const forest = Color(0xFF143224);
  static const forestDeep = Color(0xFF001D10);
  static const secondary = Color(0xFF006C49);
  static const secondaryBright = Color(0xFF00895C);
  static const mint = Color(0xFF6FFBBE);
  static const mintSoft = Color(0xFFADCEBA);
  static const background = Color(0xFFF3FCF5);
  static const ink = Color(0xFF151D19);
  static const inkVariant = Color(0xFF424844);
  static const outline = Color(0xFF727973);
  static const border = Color(0xFFDCE5DE);
  static const divider = Color(0xFFE7F0E9);
  static const chipFill = Color(0xFFEDF6EF);
  static const onForestMuted = Color(0xFF9DB9A9);
  static const error = Color(0xFFBA1A1A);
}

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

  // ---------------------------------------------------------------------------
  // Actions & routing: unchanged from the original screen.
  // ---------------------------------------------------------------------------

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

  // ---------------------------------------------------------------------------
  // Design
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Light status bar icons because the header is dark.
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _Palette.background,
        body: ListenableBuilder(
          listenable: _store,
          builder: (context, _) {
            final active = _store.parcels.isEmpty ? null : _store.parcels.first;
            return RefreshIndicator(
              color: _Palette.secondary,
              onRefresh: _store.refresh,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeaderPanel(),
                    // The content slides 14px up so the scan button overlaps
                    // the bottom edge of the header.
                    Transform.translate(
                      offset: const Offset(0, -14),
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          16,
                          0,
                          16,
                          14 + MediaQuery.of(context).padding.bottom,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_store.error != null) ...[
                              _buildSyncBanner(),
                              const SizedBox(height: 20),
                            ],
                            _buildScanButton(),
                            const SizedBox(height: 22),
                            _buildSectionTitle('Parcel overview'),
                            const SizedBox(height: 10),
                            _buildStats(),
                            const SizedBox(height: 22),
                            _buildActiveDelivery(active),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Shown when the Station Hub could not be reached, with a retry action.
  Widget _buildSyncBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.goldSoft,
        borderRadius: BorderRadius.circular(_radius),
        border: Border.all(color: const Color(0xFFE6EFC0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.cloud_off_rounded, color: AppColors.goldInk),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _store.error!,
              style: const TextStyle(
                color: Color(0xFF4B5A50),
                fontSize: 12.5,
                height: 1.35,
              ),
            ),
          ),
          TextButton(
            onPressed: _store.isLoading ? null : _store.refresh,
            style: TextButton.styleFrom(
              foregroundColor: _Palette.secondary,
              textStyle: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
              ),
            ),
            child: Text(_store.isLoading ? 'Retrying…' : 'Retry'),
          ),
        ],
      ),
    );
  }

  // ── Shared white card ─────────────────────────────────────────────────────
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
        border: Border.all(color: _Palette.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A143224),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
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

  Widget _buildSectionTitle(String text, {Widget? trailing}) {
    return Row(
      children: [
        Container(
          width: 6,
          height: 18,
          decoration: BoxDecoration(
            color: _Palette.secondary,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: _Palette.ink,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (trailing != null) trailing,
      ],
    );
  }

  // ── Deep forest header: animated backdrop + brand bar + greeting + earnings
  Widget _buildHeaderPanel() {
    final topInset = MediaQuery.of(context).padding.top;
    const bottomRadius = BorderRadius.only(
      bottomLeft: Radius.circular(32),
      bottomRight: Radius.circular(32),
    );

    return Container(
      decoration: const BoxDecoration(
        borderRadius: bottomRadius,
        boxShadow: [
          BoxShadow(
            color: Color(0x2E001D10),
            blurRadius: 30,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: bottomRadius,
        child: Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_Palette.forest, Color(0xFF0B2619)],
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
                padding: EdgeInsets.fromLTRB(20, topInset + 16, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBrandBar(),
                    const SizedBox(height: 18),
                    _buildGreetingBlock(),
                    const SizedBox(height: 18),
                    _buildEarningsCard(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// NUVORA brand mark on the left, notifications + rider avatar on the right.
  Widget _buildBrandBar() {
    final name = RiderSession.instance.name.trim();
    final initial = name.isEmpty ? 'R' : name.characters.first.toUpperCase();

    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(26),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withAlpha(26)),
          ),
          child: const Icon(
            Icons.local_mall_outlined,
            color: _Palette.mint,
            size: 18,
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'NUVORA',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2.4,
                  height: 1.1,
                ),
              ),
              Text(
                'EXPRESS COURIER',
                style: TextStyle(
                  color: _Palette.onForestMuted,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
        ),
        Semantics(
          button: true,
          label: 'Notifications',
          child: Material(
            color: Colors.white.withAlpha(26),
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: widget.onOpenNotifications,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withAlpha(26)),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Icon(
                      Icons.notifications_none_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                    if (_store.unreadCount > 0)
                      Positioned(
                        right: 11,
                        top: 11,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: _Palette.error,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _Palette.forest,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Rider avatar (initial) with the online dot.
        SizedBox(
          width: 44,
          height: 44,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF1E4A35),
                  border: Border.all(
                    color: _Palette.mint.withAlpha(128),
                    width: 2,
                  ),
                ),
                child: Text(
                  initial,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Positioned(
                right: -1,
                bottom: -1,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: _Palette.mint,
                    shape: BoxShape.circle,
                    border: Border.all(color: _Palette.forest, width: 2),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGreetingBlock() {
    final session = RiderSession.instance;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                _greeting,
                style: const TextStyle(
                  color: _Palette.onForestMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.2,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(26),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withAlpha(38)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: _Palette.mint,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Color(0xCC6FFBBE), blurRadius: 8),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Online',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '·',
                    style: TextStyle(
                      color: Colors.white.withAlpha(102),
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _today,
                    style: TextStyle(
                      color: Colors.white.withAlpha(204),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          session.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
            height: 1.25,
          ),
        ),
      ],
    );
  }

  Widget _buildEarningsCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_radius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white.withAlpha(26), Colors.white.withAlpha(10)],
        ),
        border: Border.all(color: Colors.white.withAlpha(38)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(_radius),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: widget.onOpenEarnings,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Accrued earnings',
                        style: TextStyle(
                          color: _Palette.onForestMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      'Details',
                      style: TextStyle(
                        color: _Palette.mint,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: _Palette.mint,
                      size: 18,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  _money(_store.accruedTotal),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.6,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Main action ───────────────────────────────────────────────────────────
  Widget _buildScanButton() {
    const radius = BorderRadius.all(Radius.circular(_radius));

    return Container(
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [_Palette.secondary, _Palette.secondaryBright],
        ),
        border: Border.all(color: _Palette.mint.withAlpha(77)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x47006C49),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: _openScanner,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(38),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withAlpha(64)),
                  ),
                  child: const Icon(
                    Icons.qr_code_scanner_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Scan a parcel',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Pick up, move and deliver by scanning',
                        style: TextStyle(
                          color: Color(0xD9FFFFFF),
                          fontSize: 12,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withAlpha(51),
                  ),
                  child: const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Parcel stats: one card, four cells, thin dividers ─────────────────────
  Widget _buildStats() {
    final assigned = _store.parcels.length;
    final pickup = _store.pickupCount;
    final delivery = _store.deliveryCount;
    final onTheWay = _store.onTheWayCount;

    return _card(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _StatCell(
                  icon: Icons.inventory_2_outlined,
                  value: '$assigned',
                  label: 'Assigned now',
                  highlighted: assigned > 0,
                ),
              ),
              const _VDivider(),
              Expanded(
                child: _StatCell(
                  icon: Icons.assignment_turned_in_outlined,
                  value: '$pickup',
                  label: 'Pickup',
                  highlighted: pickup > 0,
                ),
              ),
            ],
          ),
          const Divider(height: 1, thickness: 1, color: _Palette.divider),
          Row(
            children: [
              Expanded(
                child: _StatCell(
                  icon: Icons.local_shipping_outlined,
                  value: '$delivery',
                  label: 'Delivery',
                  highlighted: delivery > 0,
                ),
              ),
              const _VDivider(),
              Expanded(
                child: _StatCell(
                  icon: Icons.near_me_outlined,
                  value: '$onTheWay',
                  label: 'On the way',
                  highlighted: onTheWay > 0,
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
        _buildSectionTitle(
          'Active delivery',
          trailing: parcel == null
              ? null
              : Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _Palette.mint.withAlpha(102),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_store.parcels.length} in progress',
                    style: const TextStyle(
                      color: Color(0xFF005236),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
        ),
        const SizedBox(height: 10),
        if (parcel == null)
          _card(
            onTap: widget.onOpenParcels,
            child: const Text(
              'No active assignments yet. Scan a parcel to start.',
              style: TextStyle(color: _Palette.inkVariant, fontSize: 14),
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
                          color: _Palette.ink,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _Palette.chipFill,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _Palette.mint.withAlpha(102),
                        ),
                      ),
                      child: Text(
                        riderStageBadge(parcel.stage),
                        style: const TextStyle(
                          color: _Palette.secondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1, thickness: 1, color: _Palette.divider),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _Palette.secondary.withAlpha(26),
                      ),
                      child: const Icon(
                        Icons.location_on_outlined,
                        color: _Palette.secondary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          riderStageSubtitle(parcel),
                          style: const TextStyle(
                            color: _Palette.ink,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1, thickness: 1, color: _Palette.divider),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(
                      Icons.send_outlined,
                      size: 18,
                      color: _Palette.secondary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        riderStageTitle(parcel),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _Palette.inkVariant,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'View details',
                      style: TextStyle(
                        color: _Palette.secondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: _Palette.secondary,
                      size: 18,
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
    _Particle(0.12, 0.00, 1, 3.0, _Palette.mint),
    _Particle(0.28, 0.35, 1, 2.0, _Palette.mintSoft),
    _Particle(0.42, 0.70, 1, 2.5, _Palette.mint),
    _Particle(0.58, 0.15, 1, 3.5, _Palette.mintSoft),
    _Particle(0.72, 0.55, 1, 2.0, _Palette.mint),
    _Particle(0.86, 0.85, 1, 3.0, _Palette.mintSoft),
    _Particle(0.94, 0.40, 1, 2.0, _Palette.mint),
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

    final deepPaint = Paint()..color = _Palette.forestDeep.withAlpha(90);
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
        ..color = _Palette.mint.withAlpha(alpha);
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

  /// Cells with a count above zero get the mint tint.
  final bool highlighted;

  const _StatCell({
    required this.icon,
    required this.value,
    required this.label,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: highlighted
                  ? _Palette.mint.withAlpha(51)
                  : _Palette.divider,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: highlighted ? _Palette.secondary : _Palette.inkVariant,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: _Palette.ink,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _Palette.inkVariant,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
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
    return Container(width: 1, height: 68, color: _Palette.divider);
  }
}
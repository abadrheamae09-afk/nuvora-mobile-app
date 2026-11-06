import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/data/rider_session.dart';
import '../../core/data/rider_work.dart';

/// Colours taken from the redesign (stitch_mobile_app_redesign).
class _Palette {
  static const forest = Color(0xFF143224);
  static const forestEnd = Color(0xFF0B2619);
  static const forestDeep = Color(0xFF001D10);
  static const secondary = Color(0xFF006C49);
  static const mint = Color(0xFF6FFBBE);
  static const mintDim = Color(0xFF4EDEA3);
  static const background = Color(0xFFF3FCF5);
  static const surfaceLow = Color(0xFFEDF6EF);
  static const surface = Color(0xFFE7F0E9);
  static const border = Color(0xFFDCE5DE);
  static const ink = Color(0xFF151D19);
  static const inkVariant = Color(0xFF424844);
  static const outline = Color(0xFF727973);
  static const warnBg = Color(0xFFFFF6E0);
  static const warnBorder = Color(0xFFF3E1B0);
  static const warnInk = Color(0xFF8A5A00);
}

/// Accrued earnings plus the COD cash the rider is still holding.
class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
  final _store = RiderWorkStore.instance;

  String _money(double value) => '₱${value.toStringAsFixed(2)}';

  @override
  void initState() {
    super.initState();
    // Credits come from the Station Hub, so fetch them when the tab opens.
    _store.refreshEarnings();
  }

  // ---------------------------------------------------------------------------
  // Design
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final store = _store;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _Palette.background,
        body: Column(
          children: [
            const _Header(),
            Expanded(
              child: ListenableBuilder(
                listenable: store,
                builder: (context, _) => RefreshIndicator(
                  color: _Palette.secondary,
                  onRefresh: store.refreshEarnings,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(
                      16,
                      20,
                      16,
                      110 + MediaQuery.of(context).padding.bottom,
                    ),
                    children: [
                      if (store.earningsError != null) ...[
                        _buildErrorCard(store),
                        const SizedBox(height: 6),
                      ],
                      if (store.isEarningsLoading && !store.hasLoadedEarnings)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: _Palette.secondary,
                            ),
                          ),
                        ),
                      _buildAccruedCard(store),
                      const SizedBox(height: 10),
                      const _SectionTitle('Cash on hand'),
                      const SizedBox(height: 10),
                      _buildCashCard(store),
                      const SizedBox(height: 14),
                      const _SectionTitle('Recent earnings'),
                      const SizedBox(height: 10),
                      if (store.earnings.isEmpty)
                        _card(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 28,
                          ),
                          child: const _EmptyNote(
                            icon: Icons.receipt_long_outlined,
                            title: 'No completed deliveries yet.',
                            caption:
                                'Completed deliveries will show up here with '
                                'their earnings.',
                          ),
                        )
                      else
                        ...store.earnings.map(_buildEarningRow),
                      const SizedBox(height: 14),
                      const _SectionTitle('COD collections'),
                      const SizedBox(height: 10),
                      if (store.collections.isEmpty)
                        _card(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 24,
                          ),
                          child: const _EmptyNote(
                            icon: Icons.verified_outlined,
                            title: 'No COD cash waiting to be handed over.',
                          ),
                        )
                      else
                        ...store.collections.map(_buildCollectionRow),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard(RiderWorkStore store) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _Palette.warnBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _Palette.warnBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.cloud_off_rounded, color: _Palette.warnInk),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              store.earningsError!,
              style: const TextStyle(
                color: Color(0xFF4B5A50),
                fontSize: 12.5,
                height: 1.35,
              ),
            ),
          ),
          TextButton(
            onPressed: store.isEarningsLoading ? null : store.refreshEarnings,
            style: TextButton.styleFrom(
              foregroundColor: _Palette.secondary,
              textStyle: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
              ),
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildAccruedCard(RiderWorkStore store) {
    final hasError = store.earningsError != null;

    return _card(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: _Palette.surfaceLow,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.payments_outlined,
                  size: 18,
                  color: _Palette.secondary,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Accrued earnings',
                style: TextStyle(
                  color: _Palette.inkVariant,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _Amount(
            text: hasError ? '—' : _money(store.accruedTotal),
            size: 34,
          ),
          const SizedBox(height: 4),
          Text(
            hasError
                ? 'Waiting for your Station Hub'
                : '${store.earnings.length} completed credits · '
                      'accrued from completed deliveries',
            style: const TextStyle(
              color: _Palette.outline,
              fontSize: 12.5,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _Palette.surfaceLow,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _Palette.surface),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _Palette.secondary.withAlpha(26),
                  ),
                  child: const Icon(
                    Icons.info_outline_rounded,
                    size: 16,
                    color: _Palette.secondary,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text.rich(
                    TextSpan(
                      style: TextStyle(
                        color: _Palette.inkVariant,
                        fontSize: 12.5,
                        height: 1.45,
                      ),
                      children: [
                        TextSpan(
                          text:
                              'Accrued amounts are not a cash or bank payout '
                              'yet. Nuvora will hand these over through your ',
                        ),
                        TextSpan(
                          text: 'Station Hub',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: _Palette.forestDeep,
                          ),
                        ),
                        TextSpan(text: '.'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCashCard(RiderWorkStore store) {
    final hasError = store.earningsError != null;
    final clear = !hasError && store.cashOnHand <= 0;

    return _card(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _Palette.surfaceLow,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _Palette.surface),
                ),
                child: const Icon(
                  Icons.payments_outlined,
                  color: _Palette.secondary,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'COD cash you are holding',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: _Palette.inkVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    _Amount(
                      text: hasError ? '—' : _money(store.cashOnHand),
                      size: 26,
                    ),
                  ],
                ),
              ),
              if (!hasError)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: clear ? _Palette.surfaceLow : _Palette.warnBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: clear ? _Palette.surface : _Palette.warnBorder,
                    ),
                  ),
                  child: Text(
                    clear ? 'Clear' : 'To hand over',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: clear ? _Palette.secondary : _Palette.warnInk,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, thickness: 1, color: _Palette.surface),
          const SizedBox(height: 12),
          const Text(
            'This is not your pay. It leaves this total when your Station '
            'Hub records that it received the cash.',
            style: TextStyle(
              color: _Palette.outline,
              fontSize: 12.5,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEarningRow(dynamic row) {
    return _card(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _Palette.mint.withAlpha(51),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.check_circle_outline_rounded,
              color: _Palette.secondary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row.order,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: _Palette.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${row.hub} · ${row.date}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: _Palette.outline,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _money(row.amount),
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: _Palette.forestDeep,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCollectionRow(dynamic row) {
    return _card(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _Palette.surfaceLow,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.receipt_long_outlined,
              color: _Palette.secondary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row.order,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: _Palette.ink,
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Text(
                      row.date,
                      style: const TextStyle(
                        fontSize: 12,
                        color: _Palette.outline,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _StatusChip(label: row.status),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _money(row.amount),
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: _Palette.forestDeep,
            ),
          ),
        ],
      ),
    );
  }

  Widget _card({
    required Widget child,
    EdgeInsets padding = const EdgeInsets.all(18),
  }) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 10),
    padding: padding,
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: _Palette.border),
      borderRadius: BorderRadius.circular(16),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0D143224),
          blurRadius: 16,
          offset: Offset(0, 4),
        ),
      ],
    ),
    child: child,
  );
}

/// Deep forest masthead: rider identity, screen title and remittance pill.
class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final canPop = Navigator.of(context).canPop();
    final name = RiderSession.instance.name.trim();

    const radius = BorderRadius.only(
      bottomLeft: Radius.circular(32),
      bottomRight: Radius.circular(32),
    );

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        borderRadius: radius,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_Palette.forest, _Palette.forestEnd],
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x2E001D10),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Concentric rings for optical depth.
          Positioned(
            right: -48,
            top: -48,
            child: _Ring(size: 192, alpha: 52),
          ),
          Positioned(
            right: -24,
            top: -24,
            child: _Ring(size: 128, alpha: 40),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(16, top + 12, 16, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (canPop) ...[
                      Semantics(
                        button: true,
                        label: 'Back',
                        child: Tooltip(
                          message: 'Back',
                          child: Material(
                            color: Colors.white.withAlpha(26),
                            shape: const CircleBorder(),
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                              onTap: () => Navigator.of(context).maybePop(),
                              child: const SizedBox(
                                width: 40,
                                height: 40,
                                child: Icon(
                                  Icons.arrow_back_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _Palette.secondary.withAlpha(51),
                        border: Border.all(
                          color: _Palette.mintDim.withAlpha(102),
                        ),
                      ),
                      child: const Icon(
                        Icons.two_wheeler_rounded,
                        color: _Palette.mint,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              _LiveDot(),
                              SizedBox(width: 6),
                              Text(
                                'ONLINE',
                                style: TextStyle(
                                  color: _Palette.mint,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ],
                          ),
                          if (name.isNotEmpty)
                            Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'COURIER BALANCE',
                            style: TextStyle(
                              color: _Palette.mintDim,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.2,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'My Earnings',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.4,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(26),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withAlpha(38)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.account_balance_outlined,
                            color: _Palette.mint,
                            size: 16,
                          ),
                          SizedBox(width: 5),
                          Text(
                            'Hub Remittance',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Ring extends StatelessWidget {
  const _Ring({required this.size, required this.alpha});

  final double size;
  final int alpha;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: _Palette.mintDim.withAlpha(alpha)),
        ),
      ),
    );
  }
}

class _LiveDot extends StatelessWidget {
  const _LiveDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: _Palette.mint,
        boxShadow: [BoxShadow(color: Color(0x996FFBBE), blurRadius: 8)],
      ),
    );
  }
}

/// Money text with the peso sign in the accent colour.
class _Amount extends StatelessWidget {
  const _Amount({required this.text, required this.size});

  final String text;
  final double size;

  @override
  Widget build(BuildContext context) {
    final hasPeso = text.startsWith('₱');

    return Text.rich(
      TextSpan(
        children: [
          if (hasPeso)
            TextSpan(
              text: '₱',
              style: const TextStyle(color: _Palette.secondary),
            ),
          TextSpan(
            text: hasPeso ? text.substring(1) : text,
            style: const TextStyle(color: _Palette.forestDeep),
          ),
        ],
        style: TextStyle(
          fontSize: size,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.6,
          height: 1.2,
        ),
      ),
    );
  }
}

class _EmptyNote extends StatelessWidget {
  const _EmptyNote({required this.icon, required this.title, this.caption});

  final IconData icon;
  final String title;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: _Palette.surfaceLow,
          ),
          child: Icon(icon, color: _Palette.outline, size: 24),
        ),
        const SizedBox(height: 10),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: _Palette.ink,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (caption != null) ...[
          const SizedBox(height: 4),
          Text(
            caption!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _Palette.outline,
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 16,
            decoration: BoxDecoration(
              color: _Palette.secondary,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              color: _Palette.forestDeep,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final received = label.toLowerCase().contains('received');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: received ? _Palette.mint.withAlpha(77) : _Palette.warnBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: received ? _Palette.mint.withAlpha(128) : _Palette.warnBorder,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: received ? _Palette.secondary : _Palette.warnInk,
        ),
      ),
    );
  }
}
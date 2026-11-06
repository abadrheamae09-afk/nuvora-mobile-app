// ============================================================
// address_select_screen.dart
// Address selection during checkout.
// (Botanical Boutique redesign)
// ============================================================

import 'package:flutter/material.dart';
import 'add_edit_address_screen.dart';

class _Address {
  const _Address({
    required this.label,
    required this.name,
    required this.phone,
    required this.full,
    this.isDefault = false,
  });

  final String label;
  final String name;
  final String phone;
  final String full;
  final bool isDefault;
}

const List<_Address> _addresses = [
  _Address(
    label: 'Home',
    name: 'Juan Dela Cruz',
    phone: '09171234567',
    full: '123 Sample Street, Batasan Hills, Quezon City, Metro Manila 1126',
    isDefault: true,
  ),
  _Address(
    label: 'Office',
    name: 'Juan Dela Cruz',
    phone: '09281234567',
    full: '4F Sample Building, Ayala Ave, Makati City, Metro Manila 1200',
  ),
];

// ------------------------------------------------------------
// Design tokens for this screen (Botanical Boutique design
// system). Private so nothing else in the app is affected.
// ------------------------------------------------------------
class _T {
  // Surfaces
  static const background = Color(0xFFFCF9F8);
  static const surfaceLowest = Color(0xFFFFFFFF);
  static const surfaceLow = Color(0xFFF6F3F2);
  static const surfaceContainer = Color(0xFFF0EDED);

  // Text / outline
  static const onSurface = Color(0xFF1C1B1B);
  static const onSurfaceVariant = Color(0xFF424844);
  static const outline = Color(0xFF727973);
  static const outlineVariant = Color(0xFFC1C8C2);

  // Brand
  static const primary = Color(0xFF012114);
  static const primaryContainer = Color(0xFF173628);
  static const secondary = Color(0xFF44664B);
  static const secondaryFixed = Color(0xFFC5ECCA);
  static const onSecondaryFixedVariant = Color(0xFF2C4E35);

  // Shadows
  static const shadow = Color(0x0A173628); // 4%

  // Fonts (add Playfair Display + Plus Jakarta Sans to the project)
  static const serif = 'Playfair Display';
  static const sans = 'Plus Jakarta Sans';

  static const headlineSm = TextStyle(
    fontFamily: serif,
    fontSize: 18,
    height: 24 / 18,
    fontWeight: FontWeight.w600,
    color: primary,
  );
  static const bodyMd = TextStyle(
    fontFamily: sans,
    fontSize: 14,
    height: 20 / 14,
    color: onSurface,
  );
  static const bodySm = TextStyle(
    fontFamily: sans,
    fontSize: 12,
    height: 18 / 12,
    color: onSurfaceVariant,
  );
  static const labelLg = TextStyle(
    fontFamily: sans,
    fontSize: 14,
    height: 18 / 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.14,
  );
  static const labelMd = TextStyle(
    fontFamily: sans,
    fontSize: 12,
    height: 16 / 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.24,
  );
  static const labelSm = TextStyle(
    fontFamily: sans,
    fontSize: 11,
    height: 14 / 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.4,
  );
}

class MockupAddressSelectScreen extends StatefulWidget {
  const MockupAddressSelectScreen({super.key});

  @override
  State<MockupAddressSelectScreen> createState() =>
      _MockupAddressSelectScreenState();
}

class _MockupAddressSelectScreenState
    extends State<MockupAddressSelectScreen> {
  int _selected = 0;

  void _openAddEdit() {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => const MockupAddEditAddressScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _T.background,
      appBar: _buildAppBar(context),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          _buildAddNewCard(),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'SAVED ADDRESSES (${_addresses.length})',
                style: _T.labelSm.copyWith(
                    color: _T.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.9),
              ),
              Text('Tap card to select',
                  style: _T.bodySm.copyWith(color: _T.outline)),
            ],
          ),
          const SizedBox(height: 12),
          for (int i = 0; i < _addresses.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            _buildAddressTile(i),
          ],
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  // ----------------------------------------------------------
  // App bar (+ delivery network banner)
  // ----------------------------------------------------------
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: _T.background,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      toolbarHeight: 60,
      foregroundColor: _T.primary,
      leading: IconButton(
        tooltip: 'Back',
        icon: const Icon(Icons.arrow_back, color: _T.primary),
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      title: const Text('Delivery Addresses', style: _T.headlineSm),
      actions: [
        IconButton(
          tooltip: 'Delivery help',
          icon: const Icon(Icons.help_outline, color: _T.primary),
          onPressed: () {}, // design-only for now
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(36),
        child: Container(
          height: 36,
          color: _T.surfaceLow,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: _T.secondary,
                ),
              ),
              const SizedBox(width: 6),
              Text('NUVORA Delivery Network',
                  style: _T.labelMd.copyWith(color: _T.primary)),
              const SizedBox(width: 6),
              Text('•',
                  style: _T.bodySm.copyWith(color: _T.outline)),
              const SizedBox(width: 6),
              Text('Philippines', style: _T.bodySm),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _T.secondaryFixed.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text('Active',
                    style: _T.labelSm.copyWith(color: _T.secondary)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ----------------------------------------------------------
  // "Add a new delivery address" dashed card
  // (same navigation the app-bar "+" used to trigger)
  // ----------------------------------------------------------
  Widget _buildAddNewCard() {
    return Material(
      color: _T.surfaceLowest,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: _openAddEdit,
        child: CustomPaint(
          foregroundPainter: _DashedBorderPainter(
            color: _T.outlineVariant.withOpacity(0.7),
            radius: 16,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: _T.surfaceLow,
                  ),
                  child: const Icon(Icons.add,
                      size: 22, color: _T.primaryContainer),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Add a New Delivery Address',
                          style: _T.labelLg.copyWith(color: _T.primary)),
                      const SizedBox(height: 2),
                      const Text('Set up express delivery destination',
                          style: _T.bodySm),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right,
                    size: 20, color: _T.outline),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ----------------------------------------------------------
  // Address card
  // ----------------------------------------------------------
  Widget _buildAddressTile(int index) {
    final addr = _addresses[index];
    final selected = _selected == index;

    return GestureDetector(
      onTap: () => setState(() => _selected = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _T.surfaceLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? _T.primaryContainer
                : _T.outlineVariant.withOpacity(0.5),
            width: selected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: selected ? const Color(0x14173628) : _T.shadow,
              blurRadius: selected ? 20 : 16,
              spreadRadius: -2,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Radio
            Container(
              width: 20,
              height: 20,
              margin: const EdgeInsets.only(top: 2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? _T.primaryContainer : Colors.transparent,
                border: Border.all(
                  color: selected ? _T.primaryContainer : _T.outlineVariant,
                  width: 2,
                ),
              ),
              child: selected
                  ? Center(
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: _T.surfaceLowest,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Chips
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      _chip(
                        addr.label,
                        bg: selected
                            ? _T.primaryContainer
                            : _T.surfaceLow,
                        fg: selected ? Colors.white : _T.onSurfaceVariant,
                        horizontal: 10,
                      ),
                      if (addr.isDefault)
                        _chip(
                          'Default',
                          bg: _T.secondaryFixed,
                          fg: _T.onSecondaryFixedVariant,
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Name | phone
                  Text.rich(
                    TextSpan(
                      text: addr.name,
                      style: _T.labelLg.copyWith(color: _T.primary),
                      children: [
                        TextSpan(
                          text: '  |  ',
                          style: _T.bodyMd.copyWith(
                              color: _T.outline,
                              fontWeight: FontWeight.w400),
                        ),
                        TextSpan(
                          text: addr.phone,
                          style: _T.bodyMd.copyWith(
                              color: _T.onSurfaceVariant,
                              fontWeight: FontWeight.w400),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    addr.full,
                    style: _T.bodyMd.copyWith(height: 1.35),
                  ),
                ],
              ),
            ),
            // Edit (same navigation as before)
            SizedBox(
              width: 32,
              height: 32,
              child: IconButton(
                padding: EdgeInsets.zero,
                tooltip: 'Edit address',
                icon: Icon(
                  Icons.edit_outlined,
                  size: 18,
                  color: selected ? _T.primary : _T.outline,
                ),
                onPressed: _openAddEdit,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String text,
      {required Color bg, required Color fg, double horizontal = 8}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: horizontal, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(text, style: _T.labelSm.copyWith(color: fg)),
    );
  }

  // ----------------------------------------------------------
  // Bottom action dock
  // ----------------------------------------------------------
  Widget _buildBottomBar() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xF2FCF9F8), // surface @ 95%
        boxShadow: [
          BoxShadow(
            color: Color(0x0F173628),
            blurRadius: 24,
            offset: Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () =>
                      Navigator.pop(context, _addresses[_selected]),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _T.primaryContainer,
                    foregroundColor: Colors.white,
                    elevation: 3,
                    shadowColor: const Color(0x66173628),
                    padding: const EdgeInsets.symmetric(
                        vertical: 15, horizontal: 24),
                    shape: const StadiumBorder(),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Use Selected Address',
                          style:
                              _T.labelLg.copyWith(color: Colors.white)),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward, size: 18),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock_outline,
                      size: 14, color: _T.secondary),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      '256-bit encrypted address privacy protection',
                      textAlign: TextAlign.center,
                      style: _T.labelSm.copyWith(
                          color: _T.outline, fontWeight: FontWeight.w400),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------
// Dashed rounded border for the "Add new address" card
// ------------------------------------------------------------
class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Offset.zero & size,
        Radius.circular(radius),
      ));

    const dash = 7.0;
    const gap = 5.0;
    for (final metric in path.computeMetrics()) {
      double d = 0;
      while (d < metric.length) {
        final end = (d + dash).clamp(0, metric.length).toDouble();
        canvas.drawPath(metric.extractPath(d, end), paint);
        d += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter old) =>
      old.color != color || old.radius != radius;
}
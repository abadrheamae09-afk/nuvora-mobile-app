// ============================================================
// cancel_order_screen.dart
// Order cancellation: reason selection + confirmation.
// (Botanical Boutique redesign)
// ============================================================

import 'package:flutter/material.dart';
import 'my_orders_screen.dart';

const List<String> _reasons = [
  'I changed my mind',
  'Found a cheaper price elsewhere',
  'Ordered by mistake',
  'Shipping takes too long',
  'Payment issues',
  'Other',
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

  // Status
  static const error = Color(0xFFBA1A1A);
  static const errorContainer = Color(0xFFFFDAD6);
  static const amberSoft = Color(0xFFFDE8B3);
  static const amberDark = Color(0xFF604100);

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

  static final cardDecoration = BoxDecoration(
    color: surfaceLowest,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: outlineVariant.withOpacity(0.4)),
    boxShadow: const [
      BoxShadow(
        color: shadow,
        blurRadius: 16,
        spreadRadius: -2,
        offset: Offset(0, 4),
      ),
    ],
  );
}

class MockupCancelOrderScreen extends StatefulWidget {
  const MockupCancelOrderScreen({super.key});

  @override
  State<MockupCancelOrderScreen> createState() =>
      _MockupCancelOrderScreenState();
}

class _MockupCancelOrderScreenState
    extends State<MockupCancelOrderScreen> {
  int? _selectedReason;
  final _remarksCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _remarksCtrl.dispose();
    super.dispose();
  }

  void _confirm() {
    if (_selectedReason == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a reason.'),
          backgroundColor: _T.error,
        ),
      );
      return;
    }
    _showConfirmDialog();
  }

  void _showConfirmDialog() {
    showDialog(
      context: context,
      barrierColor: const Color(0x73173628), // forest scrim ~45%
      builder: (_) => Dialog(
        backgroundColor: _T.surfaceLowest,
        surfaceTintColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: _T.errorContainer,
                ),
                child: const Icon(Icons.warning_amber_rounded,
                    size: 28, color: _T.error),
              ),
              const SizedBox(height: 12),
              const Text('Cancel Order?', style: _T.headlineSm),
              const SizedBox(height: 8),
              Text(
                'This action cannot be undone. Are you sure you want to cancel this order?',
                textAlign: TextAlign.center,
                style: _T.bodyMd.copyWith(color: _T.onSurfaceVariant),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _cancelOrder();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _T.error,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: const StadiumBorder(),
                  ),
                  child: Text('Yes, Cancel',
                      style: _T.labelLg.copyWith(color: Colors.white)),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    backgroundColor: _T.surfaceContainer,
                    foregroundColor: _T.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: const StadiumBorder(),
                  ),
                  child: Text('Go Back',
                      style: _T.labelLg.copyWith(color: _T.primary)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _cancelOrder() {
    setState(() => _loading = true);
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() => _loading = false);
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const MockupMyOrdersScreen(initialTab: 4),
        ),
        (route) => route.isFirst,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order cancelled successfully.'),
          backgroundColor: _T.secondary,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _T.background,
      appBar: _buildAppBar(context),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          _buildNotice(),
          const SizedBox(height: 16),
          _buildReasonCard(),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(context),
    );
  }

  // ----------------------------------------------------------
  // App bar
  // ----------------------------------------------------------
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: _T.background,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      toolbarHeight: 64,
      foregroundColor: _T.primary,
      leading: IconButton(
        tooltip: 'Back',
        icon: const Icon(Icons.arrow_back, color: _T.primary),
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      title: const Text('Cancel Order', style: _T.headlineSm),
      actions: [
        IconButton(
          tooltip: 'Help',
          icon: const Icon(Icons.help_outline, color: _T.onSurfaceVariant),
          onPressed: () {}, // design-only for now
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          color: const Color(0x0F173628),
        ),
      ),
    );
  }

  // ----------------------------------------------------------
  // Policy notice
  // ----------------------------------------------------------
  Widget _buildNotice() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _T.cardDecoration,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            margin: const EdgeInsets.only(top: 2),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: _T.amberSoft,
            ),
            child: const Icon(Icons.warning_rounded,
                size: 18, color: _T.amberDark),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Cancellation Policy Notice',
                    style: _T.labelMd.copyWith(color: _T.primary)),
                const SizedBox(height: 2),
                Text(
                  'Cancellation may not be possible if the seller has already packed your order.',
                  style: _T.bodySm.copyWith(height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------
  // Reason selection + remarks
  // ----------------------------------------------------------
  Widget _buildReasonCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _T.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Reason for Cancellation',
                  style: _T.labelLg.copyWith(color: _T.primary)),
              Text('* Required',
                  style: _T.labelSm.copyWith(color: _T.error)),
            ],
          ),
          const SizedBox(height: 14),
          ...List.generate(_reasons.length, (i) {
            final selected = _selectedReason == i;
            return Padding(
              padding: EdgeInsets.only(bottom: i == _reasons.length - 1 ? 0 : 10),
              child: _reasonTile(i, selected),
            );
          }),
          const SizedBox(height: 16),
          Text.rich(
            TextSpan(
              text: 'Additional Remarks ',
              style: _T.labelMd.copyWith(color: _T.onSurfaceVariant),
              children: [
                TextSpan(
                  text: '(optional)',
                  style: _T.labelMd.copyWith(
                    color: _T.outline,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _remarksCtrl,
            maxLines: 3,
            style: _T.bodySm.copyWith(color: _T.primary),
            cursorColor: _T.primaryContainer,
            decoration: InputDecoration(
              hintText: 'Tell us more...',
              hintStyle: _T.bodySm.copyWith(color: _T.outline),
              filled: true,
              fillColor: _T.background,
              contentPadding: const EdgeInsets.all(12),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    BorderSide(color: _T.outlineVariant.withOpacity(0.6)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: _T.primaryContainer, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _reasonTile(int i, bool selected) {
    return Material(
      color: selected ? _T.background.withOpacity(0.5) : _T.surfaceLowest,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => setState(() => _selectedReason = i),
        child: Ink(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected
                  ? _T.primaryContainer
                  : _T.outlineVariant.withOpacity(0.4),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.transparent,
                  border: Border.all(
                    color: selected ? _T.primaryContainer : _T.outline,
                    width: 1.5,
                  ),
                ),
                child: selected
                    ? Center(
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: _T.primaryContainer,
                          ),
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _reasons[i],
                  style: _T.bodyMd.copyWith(
                    fontWeight: FontWeight.w500,
                    color: _T.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ----------------------------------------------------------
  // Fixed bottom action area
  // ----------------------------------------------------------
  Widget _buildBottomBar(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xF2FCF9F8), // surface @ 95%
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Primary: Submit cancellation
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x4DBA1A1A),
                      blurRadius: 16,
                      spreadRadius: -2,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _confirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _T.error,
                      disabledBackgroundColor: _T.error.withOpacity(0.7),
                      foregroundColor: Colors.white,
                      disabledForegroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                          vertical: 15, horizontal: 24),
                      shape: const StadiumBorder(),
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.cancel_outlined, size: 20),
                              const SizedBox(width: 8),
                              Text('Submit Cancellation',
                                  style: _T.labelLg
                                      .copyWith(color: Colors.white)),
                            ],
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // Secondary: keep order (same as the back button)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed:
                      _loading ? null : () => Navigator.of(context).maybePop(),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: _T.surfaceLow,
                    foregroundColor: _T.primary,
                    side: BorderSide(
                        color: _T.outlineVariant.withOpacity(0.5)),
                    padding: const EdgeInsets.symmetric(
                        vertical: 13, horizontal: 24),
                    shape: const StadiumBorder(),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.shopping_bag_outlined, size: 18),
                      const SizedBox(width: 8),
                      Text("Don't Cancel (Keep My Order)",
                          style: _T.labelLg.copyWith(color: _T.primary)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.verified_user_outlined,
                      size: 14, color: _T.secondary),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'Secure transaction • Instant confirmation email will be sent',
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
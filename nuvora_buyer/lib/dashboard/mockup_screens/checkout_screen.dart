// ============================================================
// checkout_screen.dart
// Checkout: delivery address, items per seller, shipping fee
// by location, payment method selection, and place order CTA.
// Design: "Botanical Boutique" (Playfair Display + Plus Jakarta Sans,
// forest-green / sage / amber palette).
// Routing and logic are unchanged — only the visuals were updated.
// ============================================================

import 'package:flutter/material.dart';
import 'address_select_screen.dart';
import 'order_confirmation_screen.dart';

// ── Design tokens (from the redesign) ───────────────────────
class _N {
  static const primary = Color(0xFF173628); // deep forest pine
  static const primaryDeep = Color(0xFF012114);
  static const secondary = Color(0xFF44664B);
  static const secondaryContainer = Color(0xFFC2E9C7);
  static const sageWash = Color(0xFFE8F0EA);
  static const surface = Color(0xFFFCF9F8);
  static const card = Color(0xFFFFFFFF);
  static const surfaceLow = Color(0xFFF6F3F2);
  static const surfaceContainerHigh = Color(0xFFEAE7E7);
  static const outlineVariant = Color(0xFFC1C8C2);
  static const outline = Color(0xFF727973);
  static const onSurface = Color(0xFF1C1B1B);
  static const onSurfaceVariant = Color(0xFF424844);

  static const border = Color(0x4DC1C8C2); // outline-variant @ 30%
  static const divider = Color(0x33C1C8C2); // outline-variant @ 20%
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

// ── Dummy order lines ────────────────────────────────────────

class _OrderLine {
  const _OrderLine({
    required this.name,
    required this.price,
    required this.qty,
    required this.color,
    required this.seller,
    this.shippingFee = 99.0,
  });

  final String name;
  final double price;
  final int qty;
  final Color color;
  final String seller;
  final double shippingFee;

  double get subtotal => price * qty;
}

const List<_OrderLine> _lines = [
  _OrderLine(
    name: 'Wireless Earbuds Pro',
    price: 1299,
    qty: 1,
    color: Color(0xFF2563EB),
    seller: 'TechZone PH',
    shippingFee: 99,
  ),
  _OrderLine(
    name: 'USB-C Hub 7-in-1',
    price: 899,
    qty: 2,
    color: Color(0xFF475569),
    seller: 'TechZone PH',
    shippingFee: 0, // same seller, already counted once
  ),
  _OrderLine(
    name: 'Casual Linen Shirt',
    price: 499,
    qty: 1,
    color: Color(0xFF16A34A),
    seller: 'Fashion Hub',
    shippingFee: 75,
  ),
];

const List<Map<String, dynamic>> _paymentMethods = [
  {
    'id': 'cod',
    'label': 'Cash on Delivery',
    'sub': 'Pay upon parcel receipt',
    'icon': Icons.payments_outlined,
  },
  {
    'id': 'gcash',
    'label': 'GCash',
    'sub': 'Pay with your e-wallet',
    'icon': Icons.account_balance_wallet_outlined,
  },
  {
    'id': 'card',
    'label': 'Debit / Credit Card',
    'sub': 'Visa, Mastercard',
    'icon': Icons.credit_card_outlined,
  },
  {
    'id': 'bank',
    'label': 'Online Banking',
    'sub': 'Pay through your bank',
    'icon': Icons.account_balance_outlined,
  },
];

class MockupCheckoutScreen extends StatefulWidget {
  const MockupCheckoutScreen({super.key});

  @override
  State<MockupCheckoutScreen> createState() => _MockupCheckoutScreenState();
}

class _MockupCheckoutScreenState extends State<MockupCheckoutScreen> {
  String _paymentId = 'cod';
  bool _loading = false;

  String _address =
      '123 Sample Street, Batasan Hills,\nQuezon City, Metro Manila 1126';

  double get _itemsTotal =>
      _lines.fold(0, (s, l) => s + l.subtotal);

  double get _shippingTotal =>
      _lines.fold(0, (s, l) => s + l.shippingFee);

  double get _grandTotal => _itemsTotal + _shippingTotal;

  // Group lines by seller
  Map<String, List<_OrderLine>> get _bySeller {
    final map = <String, List<_OrderLine>>{};
    for (final l in _lines) {
      map.putIfAbsent(l.seller, () => []).add(l);
    }
    return map;
  }

  void _placeOrder() {
    setState(() => _loading = true);
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() => _loading = false);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (_) => const MockupOrderConfirmationScreen()),
      );
    });
  }

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
        title: Text('Checkout', style: _serif(size: 20, height: 1.3)),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: Icon(Icons.verified_user_outlined,
                size: 22, color: _N.secondary),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                // ── Delivery address ─────────────────────
                _buildAddressCard(),
                const SizedBox(height: 14),
                // ── Items per seller ─────────────────────
                ..._bySeller.entries
                    .map((e) => _buildSellerBlock(e.key, e.value)),
                // ── Payment method ───────────────────────
                _buildPaymentSelector(),
                const SizedBox(height: 14),
                // ── Order summary ────────────────────────
                _buildSummaryCard(),
                const SizedBox(height: 16),
                _buildTrustRow(),
              ],
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  // ── Shared pieces ───────────────────────────────────────
  Widget _card({required Widget child, EdgeInsets? padding}) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
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
      ),
      child: child,
    );
  }

  Widget _cardTitle(String title, IconData icon, {String? trailing}) {
    return Row(
      children: [
        Icon(icon, size: 20, color: _N.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(title,
              style: _sans(
                  size: 14, weight: FontWeight.w700, color: _N.primary)),
        ),
        if (trailing != null)
          Text(trailing,
              style: _sans(
                  size: 11,
                  weight: FontWeight.w600,
                  color: _N.secondary)),
      ],
    );
  }

  // ── Delivery address ────────────────────────────────────
  Widget _buildAddressCard() {
    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => const MockupAddressSelectScreen()),
        );
        if (result != null) setState(() => _address = result.toString());
      },
      child: _card(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: Color(0x99C2E9C7),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.location_on,
                  size: 20, color: _N.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text('Juan Dela Cruz',
                          style: _sans(
                              size: 14,
                              weight: FontWeight.w600,
                              color: _N.primary)),
                      Text('(09171234567)',
                          style: _sans(
                              size: 12,
                              weight: FontWeight.w500,
                              color: _N.onSurfaceVariant)),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _N.primary,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text('HOME',
                            style: _sans(
                              size: 10,
                              weight: FontWeight.w700,
                              color: _N.surface,
                              letterSpacing: 0.8,
                            )),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _address,
                    style: _sans(size: 12, height: 1.5),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Icon(Icons.chevron_right,
                  size: 20, color: _N.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  // ── Seller block ────────────────────────────────────────
  Widget _buildSellerBlock(String seller, List<_OrderLine> lines) {
    final sellerShipping =
        lines.fold(0.0, (s, l) => s + l.shippingFee);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: _card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Seller header
            Container(
              padding: const EdgeInsets.only(bottom: 12),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: _N.divider)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.storefront,
                      size: 20, color: _N.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(seller,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _serif(size: 17, height: 1.3)),
                  ),
                  Text('${lines.length} ${lines.length == 1 ? 'item' : 'items'}',
                      style: _sans(
                          size: 11,
                          weight: FontWeight.w600,
                          color: _N.outline)),
                ],
              ),
            ),
            const SizedBox(height: 14),
            // Lines
            for (int i = 0; i < lines.length; i++) ...[
              if (i > 0)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1, color: _N.divider),
                ),
              _buildLine(lines[i]),
            ],
            const SizedBox(height: 14),
            // Seller note
            TextField(
              style: _sans(size: 12),
              decoration: InputDecoration(
                isDense: true,
                filled: true,
                fillColor: _N.surfaceLow,
                hintText: 'Leave a note for the seller...',
                hintStyle: _sans(size: 12, color: _N.outline),
                prefixIcon: const Icon(Icons.mode_comment_outlined,
                    size: 18, color: _N.outline),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 12),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _N.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: _N.primary, width: 1),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Shipping fee
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xB3F6F3F2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _N.secondaryContainer),
              ),
              child: Row(
                children: [
                  const Icon(Icons.local_shipping_outlined,
                      size: 18, color: _N.secondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('Shipping fee',
                        style: _sans(
                            size: 13,
                            weight: FontWeight.w500,
                            color: _N.onSurfaceVariant)),
                  ),
                  Text(
                    sellerShipping == 0
                        ? 'FREE'
                        : '₱${sellerShipping.toStringAsFixed(0)}',
                    style: _sans(
                      size: 13,
                      weight: FontWeight.w700,
                      color: sellerShipping == 0
                          ? _N.secondary
                          : _N.primary,
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

  Widget _buildLine(_OrderLine l) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: Color.lerp(Colors.white, l.color, 0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _N.border),
          ),
          child: Icon(Icons.inventory_2_outlined,
              color: l.color, size: 26),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SizedBox(
            height: 72,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: _sans(
                    size: 14,
                    weight: FontWeight.w600,
                    color: _N.primary,
                    height: 1.3,
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      '₱${l.subtotal.toStringAsFixed(0)}',
                      style: _sans(
                        size: 17,
                        weight: FontWeight.w700,
                        color: _N.primary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _N.surfaceLow,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('Qty: ${l.qty}',
                          style: _sans(
                              size: 12,
                              weight: FontWeight.w600,
                              color: _N.onSurfaceVariant)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Payment method ──────────────────────────────────────
  Widget _buildPaymentSelector() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardTitle('Payment Method', Icons.account_balance_wallet,
              trailing: 'Instant Verification'),
          const SizedBox(height: 12),
          for (int i = 0; i < _paymentMethods.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            _paymentOption(_paymentMethods[i]),
          ],
        ],
      ),
    );
  }

  Widget _paymentOption(Map<String, dynamic> method) {
    final id = method['id'] as String;
    final selected = _paymentId == id;

    return GestureDetector(
      onTap: () => setState(() => _paymentId = id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? _N.sageWash : _N.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? _N.primary : _N.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 30,
              decoration: BoxDecoration(
                color: _N.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(method['icon'] as IconData,
                  size: 18, color: _N.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    method['label'] as String,
                    style: _sans(
                      size: 14,
                      weight: FontWeight.w600,
                      color: selected ? _N.primary : _N.onSurface,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(method['sub'] as String,
                      style: _sans(size: 12, color: _N.outline)),
                ],
              ),
            ),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? _N.primary : Colors.transparent,
                border: Border.all(
                  color: selected ? _N.primary : _N.outlineVariant,
                  width: 2,
                ),
              ),
              child: selected
                  ? const Icon(Icons.check, size: 12, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  // ── Summary ─────────────────────────────────────────────
  Widget _buildSummaryCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Payment Summary',
              style: _sans(
                  size: 14, weight: FontWeight.w700, color: _N.primary)),
          const SizedBox(height: 12),
          _row('Merchandise Total',
              '₱${_itemsTotal.toStringAsFixed(0)}'),
          const SizedBox(height: 10),
          _row('Total Shipping Fee',
              '₱${_shippingTotal.toStringAsFixed(0)}'),
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
                  child: Text('Order Total',
                      style: _sans(
                          size: 14,
                          weight: FontWeight.w700,
                          color: _N.primary)),
                ),
                Text(
                  '₱${_grandTotal.toStringAsFixed(0)}',
                  style: _serif(
                      size: 22, weight: FontWeight.w700, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: _sans(size: 13, color: _N.onSurfaceVariant)),
        Text(value,
            style: _sans(size: 13, weight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildTrustRow() {
    Widget item(IconData icon, String text) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: _N.secondary),
            const SizedBox(width: 6),
            Text(text, style: _sans(size: 12, color: _N.outline)),
          ],
        );

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        item(Icons.lock_outline, 'Secure checkout'),
        const SizedBox(width: 24),
        item(Icons.verified_user_outlined, 'Buyer protection'),
      ],
    );
  }

  // ── Bottom bar ──────────────────────────────────────────
  Widget _buildBottomBar() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xF2FCF9F8),
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
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Total Payment:',
                      style: _sans(
                          size: 12, color: _N.onSurfaceVariant)),
                  Text(
                    '₱${_grandTotal.toStringAsFixed(0)}',
                    style: _serif(
                        size: 20, weight: FontWeight.w700, height: 1.3),
                  ),
                ],
              ),
              const SizedBox(width: 20),
              Expanded(
                child: FilledButton(
                  onPressed: _loading ? null : _placeOrder,
                  style: FilledButton.styleFrom(
                    backgroundColor: _N.primary,
                    disabledBackgroundColor: _N.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: const StadiumBorder(),
                    elevation: 3,
                    shadowColor: const Color(0x40173628),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Colors.white,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Place Order',
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
            ],
          ),
        ),
      ),
    );
  }
}
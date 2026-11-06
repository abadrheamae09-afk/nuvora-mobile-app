// ============================================================
// cart_screen.dart
// Shopping cart: items grouped per seller, quantity editing,
// remove item, order total, and checkout CTA.
// Shows empty state when cart is empty.
// ============================================================

import 'package:flutter/material.dart';
import 'mockup_theme.dart';
import 'mockup_widgets.dart';
import '../../core/navigation/buyer_nav_bar.dart';
import 'checkout_screen.dart';

// ── Dummy data ──────────────────────────────────────────────

class _CartItem {
  _CartItem({
    required this.name,
    required this.unitPrice,
    required this.color,
    required this.seller,
    this.qty = 1,
  });

  final String name;
  final double unitPrice;
  final Color color;
  final String seller;
  int qty;

  double get subtotal => unitPrice * qty;
  String get priceStr => '₱${unitPrice.toStringAsFixed(0)}';
  String get subtotalStr => '₱${subtotal.toStringAsFixed(0)}';
}

class MockupCartScreen extends StatefulWidget {
  const MockupCartScreen({super.key});

  @override
  State<MockupCartScreen> createState() => _MockupCartScreenState();
}

class _MockupCartScreenState extends State<MockupCartScreen> {


  final List<_CartItem> _items = [
    _CartItem(
      name: 'Wireless Earbuds Pro',
      unitPrice: 1299,
      color: const Color(0xFF2563EB),
      seller: 'TechZone PH',
      qty: 1,
    ),
    _CartItem(
      name: 'USB-C Hub 7-in-1',
      unitPrice: 899,
      color: const Color(0xFF475569),
      seller: 'TechZone PH',
      qty: 2,
    ),
    _CartItem(
      name: 'Casual Linen Shirt',
      unitPrice: 499,
      color: const Color(0xFF16A34A),
      seller: 'Fashion Hub',
      qty: 1,
    ),
    _CartItem(
      name: 'Running Shoes X3',
      unitPrice: 3499,
      color: const Color(0xFFDC2626),
      seller: 'SportsPro PH',
      qty: 1,
    ),
  ];

  final Set<int> _selected = {0, 1, 2, 3}; // all checked by default

  double get _shippingFee => _selected.isEmpty ? 0 : 99;

  double get _itemsTotal =>
      _selected.fold(0, (sum, i) => sum + _items[i].subtotal);

  double get _grandTotal => _itemsTotal + _shippingFee;

  void _remove(int index) {
    final name = _items[index].name;
    setState(() {
      _selected.remove(index);
      _items.removeAt(index);
      // Re-map selected indices
      final updated = <int>{};
      for (final s in _selected) {
        if (s < index) updated.add(s);
        // indices above removed item shift down by 1
        if (s > index) updated.add(s - 1);
      }
      _selected
        ..clear()
        ..addAll(updated);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$name removed')),
    );
  }

  // Group items by seller name
  Map<String, List<int>> get _bySeller {
    final map = <String, List<int>>{};
    for (var i = 0; i < _items.length; i++) {
      map.putIfAbsent(_items[i].seller, () => []).add(i);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MColors.background,
      appBar: AppBar(
        backgroundColor: MColors.background,
        elevation: 0,
        foregroundColor: MColors.ink,
        automaticallyImplyLeading: false,
        title: Text(
          'My Cart (${_items.length})',
          style: MTextStyles.title,
        ),
      ),
      body: _items.isEmpty
          ? MEmptyState(
              icon: Icons.shopping_cart_outlined,
              title: 'Your cart is empty',
              subtitle: 'Browse products and add them to your cart.',
              actionLabel: 'Shop Now',
              action: () => Navigator.pop(context),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      ..._bySeller.entries.map(
                        (entry) => _buildSellerGroup(
                          entry.key,
                          entry.value,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildOrderSummary(),
                    ],
                  ),
                ),
                _buildCheckoutBar(),
              ],
            ),
      bottomNavigationBar: const BuyerNavBar(current: BuyerTab.cart),
    );
  }

  Widget _buildSellerGroup(String seller, List<int> indices) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: MDecorations.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Seller header
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
            child: Row(
              children: [
                const Icon(Icons.storefront_outlined,
                    size: 16, color: MColors.primary),
                const SizedBox(width: 6),
                Text(seller, style: MTextStyles.subtitle),
              ],
            ),
          ),
          const Divider(height: 16, color: MColors.divider),
          // Items
          ...indices.map((i) => _buildCartItem(i)),
        ],
      ),
    );
  }

  Widget _buildCartItem(int index) {
    final item = _items[index];
    final checked = _selected.contains(index);

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Checkbox
          Checkbox(
            value: checked,
            onChanged: (v) => setState(() {
              if (v == true) {
                _selected.add(index);
              } else {
                _selected.remove(index);
              }
            }),
            activeColor: MColors.primary,
          ),
          // Image
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 70,
              height: 70,
              color: item.color.withAlpha(30),
              child: Icon(Icons.inventory_2_outlined,
                  color: item.color, size: 30),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: MTextStyles.subtitle.copyWith(fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(item.priceStr,
                    style: MTextStyles.price.copyWith(fontSize: 14)),
                const SizedBox(height: 8),
                // Quantity + remove row
                Row(
                  children: [
                    _qtyBtn(Icons.remove_rounded, () {
                      if (item.qty > 1) setState(() => item.qty--);
                    }),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text('${item.qty}',
                          style: MTextStyles.subtitle),
                    ),
                    _qtyBtn(Icons.add_rounded,
                        () => setState(() => item.qty++)),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded,
                          size: 18, color: MColors.muted),
                      onPressed: () => _remove(index),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
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

  Widget _qtyBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: MColors.primarySoft,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: MColors.primary),
      ),
    );
  }

  Widget _buildOrderSummary() {
    return Container(
      decoration: MDecorations.card(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Order Summary', style: MTextStyles.subtitle),
          const Divider(height: 16, color: MColors.divider),
          _summaryRow('Items (${_selected.length})',
              '₱${_itemsTotal.toStringAsFixed(0)}'),
          const SizedBox(height: 8),
          _summaryRow('Shipping fee',
              _shippingFee == 0 ? 'FREE' : '₱${_shippingFee.toStringAsFixed(0)}'),
          const Divider(height: 16, color: MColors.divider),
          _summaryRow(
            'Total',
            '₱${_grandTotal.toStringAsFixed(0)}',
            bold: true,
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool bold = false}) {
    final style = bold
        ? MTextStyles.subtitle.copyWith(color: MColors.primary)
        : MTextStyles.body.copyWith(color: MColors.muted);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        Text(value, style: style),
      ],
    );
  }

  Widget _buildCheckoutBar() {
    return Container(
      decoration: const BoxDecoration(
        color: MColors.card,
        border: Border(top: BorderSide(color: MColors.border)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total', style: MTextStyles.caption),
                Text(
                  '₱${_grandTotal.toStringAsFixed(0)}',
                  style: MTextStyles.priceLarge,
                ),
              ],
            ),
            const SizedBox(width: 20),
            Expanded(
              child: MPrimaryButton(
                label: 'Checkout (${_selected.length})',
                onPressed: _selected.isEmpty
                    ? null
                    : () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const MockupCheckoutScreen(),
                          ),
                        ),
                icon: Icons.arrow_forward_rounded,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

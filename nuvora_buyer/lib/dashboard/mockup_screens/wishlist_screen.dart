// ============================================================
// wishlist_screen.dart
// Buyer wishlist: saved products with remove and add-to-cart.
// Shows empty state when list is empty.
// Redesigned UI: "Botanical Boutique" (NUVORA) to match the
// buyer login / home / categories screens. Routing/logic is
// unchanged: tapping a tile opens MockupProductDetailsScreen,
// "Start Shopping" pops, bottom-nav taps only set the index.
// ============================================================

import 'package:flutter/material.dart';
import '../../core/navigation/buyer_nav_bar.dart';
import 'package:google_fonts/google_fonts.dart';
import 'product_details_screen.dart';

// ── Design tokens for this screen (from the redesign) ───────
class _WColors {
  static const background = Color(0xFFFCF9F8);
  static const forest = Color(0xFF173628); // primary-container
  static const forestDeep = Color(0xFF012114); // primary
  static const sage = Color(0xFFC2E9C7); // secondary-container
  static const sageText = Color(0xFF2C4E35);
  static const secondary = Color(0xFF44664B);
  static const amber = Color(0xFFE9C176); // tertiary-fixed-dim
  static const amberSoft = Color(0xFFFFDEAD); // tertiary-fixed
  static const amberText = Color(0xFF281900);
  static const amberChipText = Color(0xFF5D4201);
  static const lowSurface = Color(0xFFF6F3F2);
  static const container = Color(0xFFF0EDED);
  static const containerHighest = Color(0xFFE5E2E1);
  static const imageBg = Color(0xFFF8FAF8);
  static const ink = Color(0xFF1C1B1B);
  static const inkSoft = Color(0xFF424844);
  static const outline = Color(0xFF727973);
  static const outlineSoft = Color(0xFFC1C8C2);
  static const hairline = Color(0x0D173628); // 5% forest
  static const shadow = Color(0x0A173628); // 4% forest
  static const danger = Color(0xFFBA1A1A);
  static const dangerSoft = Color(0xFFFFDAD6);
}

TextStyle _jakarta({
  double size = 14,
  FontWeight weight = FontWeight.w400,
  Color color = _WColors.ink,
  double? letterSpacing,
  double? height,
}) =>
    GoogleFonts.plusJakartaSans(
      fontSize: size,
      fontWeight: weight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
    );

TextStyle _playfair({
  double size = 18,
  FontWeight weight = FontWeight.w600,
  Color color = _WColors.forestDeep,
  double? letterSpacing,
  double? height,
}) =>
    GoogleFonts.playfairDisplay(
      fontSize: size,
      fontWeight: weight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
    );

String _peso(double v) {
  final parts = v.toStringAsFixed(2).split('.');
  final whole = parts[0]
      .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');
  return '₱$whole.${parts[1]}';
}

// How the stock / status chip under the product name looks.
enum _StatusStyle { inStock, fewLeft, neutral }

// How the small badge on the product image looks.
enum _BadgeStyle { light, amber, sale, muted }

class _WishlistItem {
  _WishlistItem({
    required this.name,
    required this.price,
    required this.color,
    required this.seller,
    required this.icon,
    required this.badge,
    required this.badgeStyle,
    required this.status,
    required this.statusStyle,
    this.extra,
    this.oldPrice,
    this.inStock = true,
  });

  final String name;
  final double price;
  final Color color;
  final String seller;
  final IconData icon;
  final String badge;
  final _BadgeStyle badgeStyle;
  final String status;
  final _StatusStyle statusStyle;
  final String? extra;
  final double? oldPrice;
  final bool inStock;

  bool get onSale => oldPrice != null;
}

enum _Filter { all, inStock, onSale }

class MockupWishlistScreen extends StatefulWidget {
  const MockupWishlistScreen({super.key});

  @override
  State<MockupWishlistScreen> createState() => _MockupWishlistScreenState();
}

class _MockupWishlistScreenState extends State<MockupWishlistScreen> {

  _Filter _filter = _Filter.all; // view-only filter
  bool _showBanner = true; // design-only banner dismiss

  final List<_WishlistItem> _items = [
    _WishlistItem(
      name: 'Ceramic Plant Pot',
      price: 349,
      color: const Color(0xFF16A34A),
      seller: 'Ria Clothing Store',
      icon: Icons.local_florist_outlined,
      badge: 'NEW',
      badgeStyle: _BadgeStyle.light,
      status: 'In Stock',
      statusStyle: _StatusStyle.inStock,
    ),
    _WishlistItem(
      name: 'Wrap Midi Dress — Rose',
      price: 1199,
      color: const Color(0xFFEC4899),
      seller: 'Ria Clothing Store',
      icon: Icons.checkroom_outlined,
      badge: 'FEW LEFT',
      badgeStyle: _BadgeStyle.amber,
      status: 'Only 2 left',
      statusStyle: _StatusStyle.fewLeft,
      extra: 'Size: M',
    ),
    _WishlistItem(
      name: 'Alpha Arbutin 2% + HA Serum',
      price: 649,
      oldPrice: 750,
      color: const Color(0xFFA855F7),
      seller: 'The Ordinary',
      icon: Icons.spa_outlined,
      badge: '-13% OFF',
      badgeStyle: _BadgeStyle.sale,
      status: 'Price Dropped',
      statusStyle: _StatusStyle.inStock,
    ),
    _WishlistItem(
      name: 'Hand-thrown Terracotta Planter',
      price: 480,
      color: const Color(0xFFF59E0B),
      seller: 'Green Haven',
      icon: Icons.yard_outlined,
      badge: 'HANDMADE',
      badgeStyle: _BadgeStyle.muted,
      status: 'Low Stock',
      statusStyle: _StatusStyle.neutral,
      extra: 'Diameter: 18cm',
      inStock: false,
    ),
  ];

  void _remove(int index) {
    setState(() => _items.removeAt(index));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Removed from wishlist'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {},
        ),
      ),
    );
  }

  void _addToCart(int index) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${_items[index].name} added to cart'),
        backgroundColor: _WColors.forest,
      ),
    );
  }

  void _addAllToCart() {
    final n = _items.where((e) => e.inStock).length;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$n in-stock items added to cart'),
        backgroundColor: _WColors.forest,
      ),
    );
  }

  List<_WishlistItem> get _visible {
    switch (_filter) {
      case _Filter.all:
        return _items;
      case _Filter.inStock:
        return _items.where((e) => e.inStock).toList();
      case _Filter.onSale:
        return _items.where((e) => e.onSale).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final inStock = _items.where((e) => e.inStock).toList();
    final inStockTotal = inStock.fold<double>(0, (s, e) => s + e.price);

    return Scaffold(
      backgroundColor: _WColors.background,
      appBar: _buildAppBar(),
      body: _items.isEmpty
          ? _buildEmptyState()
          : _buildList(),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (inStock.isNotEmpty)
            _buildBatchStrip(inStock.length, inStockTotal),
          const BuyerNavBar(current: BuyerTab.wishlist),
        ],
      ),
    );
  }

  // ── Top app bar: menu · My Wishlist [n] · chat / bag ──────
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _WColors.background,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 2,
      shadowColor: _WColors.shadow,
      automaticallyImplyLeading: false,
      centerTitle: true,
      toolbarHeight: 60,
      leading: IconButton(
        onPressed: () {},
        icon: const Icon(Icons.menu_rounded,
            size: 22, color: _WColors.forestDeep),
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('My Wishlist', style: _playfair(size: 18, letterSpacing: -0.2)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: _WColors.sage,
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              '${_items.length}',
              style: _jakarta(
                size: 11,
                weight: FontWeight.w700,
                letterSpacing: 0.4,
                color: _WColors.sageText,
              ),
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.chat_bubble_outline_rounded,
              size: 20, color: _WColors.forestDeep),
        ),
        IconButton(
          onPressed: () {},
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(Icons.shopping_bag,
                  size: 20, color: _WColors.forestDeep),
              Positioned(
                top: -1,
                right: -2,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: _WColors.secondary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  // ── Main scrolling list ───────────────────────────────────
  Widget _buildList() {
    final visible = _visible;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        if (_showBanner && _items.any((e) => e.onSale)) ...[
          _buildPriceDropBanner(),
          const SizedBox(height: 16),
        ],
        _buildFilterRow(),
        const SizedBox(height: 12),
        _buildReservedNote(),
        const SizedBox(height: 16),
        if (visible.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Text(
                'No items match this filter.',
                style: _jakarta(size: 13, color: _WColors.inkSoft),
              ),
            ),
          )
        else
          for (final item in visible) ...[
            _buildWishlistTile(_items.indexOf(item)),
            const SizedBox(height: 14),
          ],
        const SizedBox(height: 6),
        _buildSimilarTeaser(),
      ],
    );
  }

  // ── Price-drop notification pill ──────────────────────────
  Widget _buildPriceDropBanner() {
    final drops = _items.where((e) => e.onSale).toList();
    final first = drops.first;
    final saved = first.oldPrice! - first.price;
    final n = drops.length;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _WColors.sage.withAlpha(128),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _WColors.sage.withAlpha(102)),
        boxShadow: const [
          BoxShadow(
            color: _WColors.shadow,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            margin: const EdgeInsets.only(top: 2),
            decoration: const BoxDecoration(
              color: _WColors.sage,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.trending_down_rounded,
                size: 17, color: _WColors.secondary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Good news: $n ${n == 1 ? 'item' : 'items'} on your '
                  'wishlist dropped in price!',
                  style: _jakarta(
                    size: 12,
                    weight: FontWeight.w500,
                    color: _WColors.forestDeep,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Save ${_peso(saved)} on ${first.name.split(' ').take(2).join(' ')}',
                  style: _jakarta(
                    size: 11,
                    weight: FontWeight.w700,
                    letterSpacing: 0.4,
                    color: _WColors.secondary,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _showBanner = false),
            child: const Padding(
              padding: EdgeInsets.only(top: 2, left: 6),
              child: Icon(Icons.close_rounded,
                  size: 16, color: _WColors.outline),
            ),
          ),
        ],
      ),
    );
  }

  // ── Filter chips + sort pill ──────────────────────────────
  Widget _buildFilterRow() {
    final all = _items.length;
    final stock = _items.where((e) => e.inStock).length;
    final sale = _items.where((e) => e.onSale).length;
    final chips = <MapEntry<_Filter, String>>[
      MapEntry(_Filter.all, 'All Items ($all)'),
      MapEntry(_Filter.inStock, 'In Stock ($stock)'),
      MapEntry(_Filter.onSale, 'On Sale ($sale)'),
    ];
    return Row(
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final c in chips) ...[
                  GestureDetector(
                    onTap: () => setState(() => _filter = c.key),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: _filter == c.key
                            ? _WColors.forest
                            : _WColors.lowSurface,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        c.value,
                        style: _jakarta(
                          size: 11,
                          weight: FontWeight.w700,
                          letterSpacing: 0.6,
                          color: _filter == c.key
                              ? Colors.white
                              : _WColors.forestDeep,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: _WColors.lowSurface,
            borderRadius: BorderRadius.circular(99),
            border: Border.all(color: _WColors.outlineSoft.withAlpha(77)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Sort:',
                  style: _jakarta(size: 11, color: _WColors.inkSoft)),
              const SizedBox(width: 4),
              Text(
                'Recent',
                style: _jakarta(
                  size: 11,
                  weight: FontWeight.w600,
                  color: _WColors.forestDeep,
                ),
              ),
              const Icon(Icons.expand_more_rounded,
                  size: 14, color: _WColors.outline),
            ],
          ),
        ),
      ],
    );
  }

  // ── Reserved-items note ───────────────────────────────────
  // "Clear all" keeps its original behaviour, just restyled.
  Widget _buildReservedNote() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _WColors.lowSurface.withAlpha(178),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _WColors.outlineSoft.withAlpha(51)),
      ),
      child: Row(
        children: [
          const Icon(Icons.schedule_rounded,
              size: 16, color: _WColors.secondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Wishlist items reserved for 24h upon price drop notification.',
              style: _jakarta(
                size: 11,
                color: _WColors.inkSoft,
                height: 1.3,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => setState(() => _items.clear()),
            child: Text(
              'Clear all',
              style: _jakarta(
                size: 11,
                weight: FontWeight.w700,
                color: _WColors.danger,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── One wishlist card ─────────────────────────────────────
  Widget _buildWishlistTile(int index) {
    final item = _items[index];

    return Dismissible(
      key: ValueKey(item.name),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: _WColors.dangerSoft,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_outline_rounded,
            color: _WColors.danger),
      ),
      onDismissed: (_) => _remove(_items.indexOf(item)),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => const MockupProductDetailsScreen()),
        ),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: item.onSale
                ? Border.all(color: _WColors.sage.withAlpha(153), width: 2)
                : Border.all(color: _WColors.hairline),
            boxShadow: const [
              BoxShadow(
                color: _WColors.shadow,
                blurRadius: 16,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image placeholder + badge
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 104,
                  height: 128,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Container(
                          color: _WColors.imageBg,
                          padding: const EdgeInsets.all(8),
                          child: Container(
                            decoration: BoxDecoration(
                              color: item.color.withAlpha(36),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              item.icon,
                              size: 40,
                              color: item.color.withAlpha(200),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 6,
                        left: 6,
                        child: _buildImageBadge(item),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              item.seller.toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: _jakarta(
                                size: 10,
                                weight: FontWeight.w700,
                                letterSpacing: 0.8,
                                color: _WColors.inkSoft,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        // Remove (filled heart disc)
                        GestureDetector(
                          onTap: () => _remove(_items.indexOf(item)),
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: const BoxDecoration(
                              color: _WColors.lowSurface,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.favorite_rounded,
                                size: 18, color: _WColors.forestDeep),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _jakarta(
                        size: 14,
                        weight: FontWeight.w500,
                        color: _WColors.forestDeep,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _buildStatusChip(item),
                        if (item.extra != null) ...[
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              item.extra!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: _jakarta(
                                size: 10,
                                color: _WColors.inkSoft,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.only(top: 8),
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(color: _WColors.lowSurface),
                        ),
                      ),
                      child: Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                _peso(item.price),
                                style: _jakarta(
                                  size: 17,
                                  weight: FontWeight.w700,
                                  letterSpacing: -0.17,
                                  color: _WColors.forestDeep,
                                ),
                              ),
                              if (item.oldPrice != null) ...[
                                const SizedBox(width: 6),
                                Text(
                                  _peso(item.oldPrice!),
                                  style: _jakarta(
                                    size: 11,
                                    color: _WColors.outline,
                                  ).copyWith(
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          GestureDetector(
                            onTap: () => _addToCart(_items.indexOf(item)),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 7),
                              decoration: BoxDecoration(
                                color: _WColors.forest,
                                borderRadius: BorderRadius.circular(99),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x1F173628),
                                    blurRadius: 4,
                                    offset: Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.shopping_bag_outlined,
                                      size: 15, color: Colors.white),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Move to Cart',
                                    style: _jakarta(
                                      size: 11,
                                      weight: FontWeight.w700,
                                      letterSpacing: 0.4,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
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
      ),
    );
  }

  Widget _buildImageBadge(_WishlistItem item) {
    Color bg;
    Color fg;
    FontWeight w = FontWeight.w700;
    switch (item.badgeStyle) {
      case _BadgeStyle.light:
        bg = Colors.white.withAlpha(230);
        fg = _WColors.forestDeep;
        w = FontWeight.w600;
        break;
      case _BadgeStyle.amber:
        bg = _WColors.amber.withAlpha(230);
        fg = _WColors.amberText;
        break;
      case _BadgeStyle.sale:
        bg = _WColors.secondary;
        fg = Colors.white;
        break;
      case _BadgeStyle.muted:
        bg = _WColors.containerHighest;
        fg = _WColors.inkSoft;
        w = FontWeight.w600;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        item.badge,
        style: _jakarta(size: 10, weight: w, letterSpacing: 0.6, color: fg),
      ),
    );
  }

  Widget _buildStatusChip(_WishlistItem item) {
    Color bg;
    Color fg;
    bool dot = false;
    switch (item.statusStyle) {
      case _StatusStyle.inStock:
        bg = _WColors.sage.withAlpha(102);
        fg = _WColors.sageText;
        dot = true;
        break;
      case _StatusStyle.fewLeft:
        bg = _WColors.amberSoft.withAlpha(77);
        fg = _WColors.amberChipText;
        break;
      case _StatusStyle.neutral:
        bg = _WColors.container;
        fg = _WColors.inkSoft;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot) ...[
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: _WColors.secondary,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
          ],
          Text(
            item.status,
            style: _jakarta(
              size: 10,
              weight: FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }

  // ── "Similar Botanical Finds" teaser ──────────────────────
  Widget _buildSimilarTeaser() {
    return Container(
      padding: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: _WColors.outlineSoft.withAlpha(77)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Similar Botanical Finds', style: _playfair(size: 18)),
                const SizedBox(height: 2),
                Text(
                  'Curated based on your saved aesthetics',
                  style: _jakarta(size: 12, color: _WColors.inkSoft),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Explore',
                style: _jakarta(
                  size: 11,
                  weight: FontWeight.w700,
                  letterSpacing: 0.4,
                  color: _WColors.secondary,
                ),
              ),
              const SizedBox(width: 2),
              const Icon(Icons.arrow_forward_rounded,
                  size: 14, color: _WColors.secondary),
            ],
          ),
        ],
      ),
    );
  }

  // ── Floating "Move All to Cart" strip ─────────────────────
  Widget _buildBatchStrip(int count, double total) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: _WColors.background.withAlpha(242),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _WColors.forest.withAlpha(26)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x26173628),
              blurRadius: 24,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 6),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ready to order?',
                        style: _jakarta(
                          size: 11,
                          weight: FontWeight.w500,
                          letterSpacing: 0.3,
                          color: _WColors.inkSoft,
                        ),
                      ),
                      Text.rich(
                        TextSpan(
                          text: _peso(total),
                          style: _jakarta(
                            size: 15,
                            weight: FontWeight.w700,
                            color: _WColors.forestDeep,
                          ),
                          children: [
                            TextSpan(
                              text: ' ($count in-stock)',
                              style: _jakarta(
                                size: 12,
                                color: _WColors.inkSoft,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: _addAllToCart,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: _WColors.forest,
                  borderRadius: BorderRadius.circular(99),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x33173628),
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add_shopping_cart_rounded,
                        size: 18, color: Colors.white),
                    const SizedBox(width: 6),
                    Text(
                      'Move All to Cart',
                      style: _jakarta(
                        size: 14,
                        weight: FontWeight.w600,
                        letterSpacing: 0.14,
                        color: Colors.white,
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

  // ── Empty state ───────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: const BoxDecoration(
                color: _WColors.sage,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.favorite_outline_rounded,
                  size: 44, color: _WColors.forest),
            ),
            const SizedBox(height: 24),
            Text('Your wishlist is empty',
                textAlign: TextAlign.center, style: _playfair(size: 22)),
            const SizedBox(height: 8),
            Text(
              'Save products you love by tapping the heart icon.',
              textAlign: TextAlign.center,
              style: _jakarta(size: 13, color: _WColors.inkSoft, height: 1.5),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: _WColors.forest,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  'Start Shopping',
                  style: _jakarta(
                    size: 14,
                    weight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


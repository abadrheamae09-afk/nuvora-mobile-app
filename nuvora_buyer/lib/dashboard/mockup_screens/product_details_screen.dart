// ============================================================
// product_details_screen.dart
// Full product detail: image, price, description, stock,
// seller info, add to cart, buy now, add to wishlist.
//
// Restyled with the "Botanical Boutique" design (NUVORA):
// pine/sage palette, Playfair Display headlines, Plus Jakarta Sans
// body, pill buttons, soft cards, variation thumbnails and a
// variant / quantity bottom sheet.
//
// Routing is unchanged:
//   • SnackBar "View Cart"  -> MockupCartScreen
//   • Buy Now (confirmed)   -> MockupCartScreen
//   • Seller card / Visit   -> MockupSellerStoreScreen
// ============================================================

import 'package:flutter/material.dart';
import '../../core/navigation/buyer_nav_bar.dart';
import 'seller_store_screen.dart';
import 'cart_screen.dart';

// ------------------------------------------------------------
// Design tokens (from the redesign's DESIGN.md)
// If you use the google_fonts package, swap the font names in
// _headline()/_body() for GoogleFonts.playfairDisplay() and
// GoogleFonts.plusJakartaSans().
// ------------------------------------------------------------
class _T {
  // surfaces
  static const surface = Color(0xFFFCF9F8);
  static const card = Color(0xFFFFFFFF);
  static const containerLow = Color(0xFFF6F3F2);
  static const container = Color(0xFFF0EDED);
  static const containerHigh = Color(0xFFEAE7E7);

  // text
  static const primary = Color(0xFF012114);
  static const onSurfaceVariant = Color(0xFF424844);
  static const outline = Color(0xFF727973);
  static const outlineVariant = Color(0xFFC1C8C2);

  // brand
  static const primaryContainer = Color(0xFF173628);
  static const primaryFixed = Color(0xFFC7EBD6);
  static const secondary = Color(0xFF44664B);
  static const secondaryContainer = Color(0xFFC2E9C7);
  static const tertiary = Color(0xFF281900);
  static const tertiaryFixedDim = Color(0xFFFABC4D);
  static const featuredBadge = Color(0xFFFDE8B3);

  // status
  static const error = Color(0xFFBA1A1A);
  static const errorContainer = Color(0xFFFFDAD6);
  static const onErrorContainer = Color(0xFF93000A);

  static const shadow = Color(0x0F173628); // ~6% pine

  static const headlineFont = 'Playfair Display';
  static const bodyFont = 'Plus Jakarta Sans';
}

TextStyle _headline(double size, {FontWeight w = FontWeight.w600}) =>
    TextStyle(
      fontFamily: _T.headlineFont,
      fontSize: size,
      fontWeight: w,
      color: _T.primary,
      letterSpacing: -0.2,
      height: 1.25,
    );

TextStyle _body(double size,
        {FontWeight w = FontWeight.w400,
        Color color = _T.onSurfaceVariant,
        double? height,
        double letterSpacing = 0}) =>
    TextStyle(
      fontFamily: _T.bodyFont,
      fontSize: size,
      fontWeight: w,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );

BoxDecoration _cardDecoration() => BoxDecoration(
      color: _T.card,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: _T.primary.withOpacity(0.05)),
      boxShadow: const [
        BoxShadow(
          color: _T.shadow,
          blurRadius: 16,
          spreadRadius: -2,
          offset: Offset(0, 4),
        ),
      ],
    );

String _peso(int v) {
  final s = v.toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
    b.write(s[i]);
  }
  return '₱$b';
}

enum _SheetMode { select, cart, buy }

class MockupProductDetailsScreen extends StatefulWidget {
  const MockupProductDetailsScreen({super.key, this.product});

  /// A real product from the catalogue; null keeps the demo product.
  final Map<String, dynamic>? product;

  @override
  State<MockupProductDetailsScreen> createState() =>
      _MockupProductDetailsScreenState();
}

class _MockupProductDetailsScreenState
    extends State<MockupProductDetailsScreen> {
  static const int _basePrice = 1299;
  static const int _originalPrice = 2499;
  static const int _maxPerPurchase = 5;

  int _qty = 1;
  bool _inWishlist = false;
  int _imageIndex = 0;
  String _selectedVariant = 'Black';
  String _selectedCase = 'Standard (USB-C)';
  bool _addedToCart = false;

  // Dummy colour variants
  final _variants = ['Black', 'White', 'Navy', 'Rose Gold'];

  // Swatch colour for each variant
  final _variantColors = const {
    'Black': Color(0xFF1C1B1B),
    'White': Color(0xFFF3EFE6),
    'Navy': Color(0xFF1E3A5F),
    'Rose Gold': Color(0xFFC98B7B),
  };

  // Dummy stock per variant
  final _variantStock = const {
    'Black': 48,
    'White': 32,
    'Navy': 18,
    'Rose Gold': 6,
  };

  // Dummy second option group (price delta in pesos)
  final _cases = const {
    'Standard (USB-C)': 0,
    'Wireless Case': 200,
  };

  // Dummy image accent colours (acts as placeholder for real images)
  final _imageColors = [
    const Color(0xFF466555),
    const Color(0xFF44664B),
    const Color(0xFF2E4D3E),
    const Color(0xFF173628),
  ];

  int get _unitPrice => _basePrice + (_cases[_selectedCase] ?? 0);
  int get _stock => _variantStock[_selectedVariant] ?? 0;
  int get _maxQty => _stock < _maxPerPurchase ? _stock : _maxPerPurchase;
  String get _summary => '$_selectedVariant, $_selectedCase';

  void _selectVariant(String v) {
    setState(() {
      _selectedVariant = v;
      _imageIndex = _variants.indexOf(v).clamp(0, _imageColors.length - 1);
      if (_qty > _maxQty) _qty = _maxQty;
    });
  }

  void _addToCart() {
    setState(() => _addedToCart = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 90),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999)),
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline_rounded,
                size: 18, color: Color(0xFFC7EBD6)),
            const SizedBox(width: 8),
            Text('Added to cart!',
                style: _body(13, w: FontWeight.w600, color: Colors.white)),
          ],
        ),
        action: SnackBarAction(
          label: 'View Cart',
          textColor: const Color(0xFFACCEBA),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MockupCartScreen()),
          ),
        ),
        backgroundColor: _T.primaryContainer,
      ),
    );
  }

  // Buy Now: adds the item, then opens the cart (existing route).
  // Swap MockupCartScreen for your checkout screen if you have one.
  void _buyNow() {
    setState(() => _addedToCart = true);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MockupCartScreen()),
    );
  }

  // ----------------------------------------------------------
  // VARIANT / QUANTITY BOTTOM SHEET
  // ----------------------------------------------------------
  void _openVariantSheet(_SheetMode mode) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          void update(VoidCallback fn) {
            setState(fn);
            setSheet(() {});
          }

          return _buildSheet(ctx, mode, update);
        },
      ),
    );
  }

  Widget _buildSheet(
      BuildContext sheetCtx, _SheetMode mode, void Function(VoidCallback) update) {
    final total = _unitPrice * _qty;
    final confirmLabel = switch (mode) {
      _SheetMode.cart => 'Confirm Add to Cart (${_peso(total)})',
      _SheetMode.buy => 'Confirm Buy Now (${_peso(total)})',
      _SheetMode.select => 'Confirm Selection',
    };

    Widget chip({
      required String label,
      required bool selected,
      required VoidCallback onTap,
      Color? dot,
    }) {
      return GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: selected ? _T.primaryFixed.withOpacity(0.2) : _T.card,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? _T.primary
                  : _T.outlineVariant.withOpacity(0.6),
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (dot != null) ...[
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: dot,
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: _T.outlineVariant.withOpacity(0.6)),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: _body(12,
                    w: selected ? FontWeight.w700 : FontWeight.w600,
                    color: selected ? _T.primary : _T.onSurfaceVariant,
                    letterSpacing: 0.2),
              ),
            ],
          ),
        ),
      );
    }

    Widget sectionTitle(String left, String right) => Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(left.toUpperCase(),
                style: _body(11,
                    w: FontWeight.w700,
                    color: _T.primary,
                    letterSpacing: 1.0)),
            Text(right,
                style: _body(12, w: FontWeight.w600, color: _T.secondary)),
          ],
        );

    final divider = Divider(
        height: 1, color: _T.outlineVariant.withOpacity(0.3), thickness: 1);

    return Container(
      constraints: BoxConstraints(
          maxHeight: MediaQuery.of(sheetCtx).size.height * 0.85),
      decoration: const BoxDecoration(
        color: _T.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 40,
            offset: Offset(0, -12),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _T.outlineVariant.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              // header: thumb, price, stock, close
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Color.alphaBlend(
                          _imageColors[_imageIndex].withAlpha(36), _T.card),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _T.primary.withOpacity(0.1)),
                    ),
                    child: Icon(Icons.headphones_rounded,
                        size: 40, color: _imageColors[_imageIndex]),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(_peso(widget.product?['price'] is num ? (widget.product!['price'] as num).toInt() : _unitPrice),
                                style: _body(22,
                                    w: FontWeight.w700,
                                    color: _T.primary,
                                    letterSpacing: -0.3)),
                            const SizedBox(width: 8),
                            Text(_peso(widget.product?['old_price'] is num ? (widget.product!['old_price'] as num).toInt() : _originalPrice),
                                style: _body(12, color: _T.outline).copyWith(
                                    decoration: TextDecoration.lineThrough)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                  color: _T.secondary,
                                  shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 6),
                            Text('Stock: $_stock pieces',
                                style: _body(12,
                                    w: FontWeight.w500,
                                    color: _T.secondary)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text.rich(
                          TextSpan(
                            text: 'Selected: ',
                            style: _body(11, w: FontWeight.w500),
                            children: [
                              TextSpan(
                                text: _summary,
                                style: _body(11,
                                    w: FontWeight.w700, color: _T.primary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(sheetCtx).pop(),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                          color: _T.container, shape: BoxShape.circle),
                      child: const Icon(Icons.close_rounded,
                          size: 18, color: _T.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              divider,
              // color options
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    sectionTitle('Color Option', _selectedVariant),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _variants
                          .map((v) => chip(
                                label: v,
                                dot: _variantColors[v],
                                selected: _selectedVariant == v,
                                onTap: () => update(() {
                                  _selectedVariant = v;
                                  _imageIndex = _variants
                                      .indexOf(v)
                                      .clamp(0, _imageColors.length - 1);
                                  if (_qty > _maxQty) _qty = _maxQty;
                                }),
                              ))
                          .toList(),
                    ),
                  ],
                ),
              ),
              divider,
              // case / specification options
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    sectionTitle('Charging Case', _selectedCase),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _cases.entries.map((e) {
                        final label = e.value == 0
                            ? e.key
                            : '${e.key} (+${_peso(e.value)})';
                        return chip(
                          label: label,
                          selected: _selectedCase == e.key,
                          onTap: () => update(() => _selectedCase = e.key),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              divider,
              // quantity
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('QUANTITY',
                            style: _body(11,
                                w: FontWeight.w700,
                                color: _T.primary,
                                letterSpacing: 1.0)),
                        const SizedBox(height: 2),
                        Text('Max per purchase: $_maxPerPurchase',
                            style: _body(11, color: _T.outline)),
                      ],
                    ),
                    _qtyStepper(
                      onMinus: () => update(() {
                        if (_qty > 1) _qty--;
                      }),
                      onPlus: () => update(() {
                        if (_qty < _maxQty) _qty++;
                      }),
                    ),
                  ],
                ),
              ),
              // confirm
              GestureDetector(
                onTap: () {
                  Navigator.of(sheetCtx).pop();
                  switch (mode) {
                    case _SheetMode.cart:
                      _addToCart();
                      break;
                    case _SheetMode.buy:
                      _buyNow();
                      break;
                    case _SheetMode.select:
                      break;
                  }
                },
                child: Container(
                  width: double.infinity,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _T.primaryContainer,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x40173628),
                        blurRadius: 16,
                        spreadRadius: -2,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(confirmLabel,
                      style: _body(14,
                          w: FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: 0.2)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ----------------------------------------------------------
  // BUILD
  // ----------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: const BuyerNavBar(),
      backgroundColor: _T.surface,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // ── Top bar ─────────────────────────────────
              SliverAppBar(
                pinned: true,
                backgroundColor: _T.surface,
                surfaceTintColor: Colors.transparent,
                foregroundColor: _T.primary,
                elevation: 0,
                scrolledUnderElevation: 0,
                centerTitle: true,
                shadowColor: _T.shadow,
                title: Text(
                  (widget.product?['store'] is Map
                          ? (widget.product?['store']['name'] ?? 'NUVORA Store')
                              .toString()
                              .toUpperCase()
                          : 'TECHZONE PH'),
                  style: _body(11,
                      w: FontWeight.w600,
                      letterSpacing: 1.4,
                      color: _T.onSurfaceVariant),
                ),
                actions: [
                  _circleAction(
                    icon: _inWishlist
                        ? Icons.favorite_rounded
                        : Icons.favorite_outline_rounded,
                    color: _inWishlist ? _T.error : _T.primary,
                    onPressed: () =>
                        setState(() => _inWishlist = !_inWishlist),
                  ),
                  _circleAction(
                    icon: Icons.share_outlined,
                    onPressed: () {},
                  ),
                  const SizedBox(width: 8),
                ],
              ),
              // ── Image gallery (square) ──────────────────
              SliverToBoxAdapter(child: _buildGallery()),
              // ── Variation thumbnails ────────────────────
              SliverToBoxAdapter(child: _buildVariantStrip()),
              // ── Details ──────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category
                      Text(
                        'AUDIO • EARBUDS',
                        style: _body(11,
                            w: FontWeight.w700,
                            color: _T.secondary,
                            letterSpacing: 1.2),
                      ),
                      const SizedBox(height: 12),
                      // Product name
                      Text(
                        (widget.product?['name']?.toString() ??
                            'Wireless Earbuds Pro – Active Noise Cancellation, 30-hr Battery'),
                        style: _headline(24),
                      ),
                      const SizedBox(height: 14),
                      // Rating + See All
                      _buildRatingRow(),
                      const SizedBox(height: 16),
                      // Pricing bar
                      _buildPriceBar(),
                      const SizedBox(height: 16),
                      // Seller card
                      _buildSellerCard(),
                      const SizedBox(height: 16),
                      // Variations entry row
                      _buildVariationRow(),
                      const SizedBox(height: 16),
                      // Shipping snippet
                      _buildShippingSnippet(),
                      const SizedBox(height: 22),
                      // Description
                      Container(
                        padding: const EdgeInsets.only(top: 18),
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(
                                color: _T.outlineVariant.withOpacity(0.3)),
                          ),
                        ),
                        width: double.infinity,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Description', style: _headline(18)),
                            const SizedBox(height: 10),
                            Text(
                              'Experience premium sound quality with the Wireless Earbuds Pro. Featuring active noise cancellation, crystal-clear audio drivers, and up to 30 hours of battery life with the charging case. IPX5 water resistant, touch controls, and instant pairing with any Bluetooth device.\n\n• Active Noise Cancellation\n• 30-hour total battery life\n• IPX5 water resistance\n• Wireless charging case\n• Touch controls',
                              style: _body(14, height: 1.6),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      // Reviews
                      Text('Reviews', style: _headline(18)),
                      const SizedBox(height: 12),
                      _buildReviewSnippet(),
                      // Bottom CTA padding
                      const SizedBox(height: 110),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // ── Fixed bottom CTA ────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: _T.surface.withOpacity(0.97),
                border: Border(
                  top: BorderSide(color: _T.primary.withOpacity(0.05)),
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x14173628),
                    blurRadius: 24,
                    offset: Offset(0, -8),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    // Wishlist (round icon button)
                    GestureDetector(
                      onTap: () =>
                          setState(() => _inWishlist = !_inWishlist),
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: _T.card,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: _T.outlineVariant.withOpacity(0.4)),
                          boxShadow: const [
                            BoxShadow(
                              color: _T.shadow,
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          _inWishlist
                              ? Icons.favorite_rounded
                              : Icons.favorite_outline_rounded,
                          size: 22,
                          color: _inWishlist ? _T.error : _T.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Add to cart (ghost pill) -> opens sheet
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _openVariantSheet(_SheetMode.cart),
                        child: Container(
                          height: 48,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF4F6F4),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: _T.primaryContainer),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _addedToCart
                                    ? Icons.check_rounded
                                    : Icons.shopping_bag_outlined,
                                size: 18,
                                color: _T.primaryContainer,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  _addedToCart ? 'Added ✓' : 'Add to Cart',
                                  overflow: TextOverflow.ellipsis,
                                  style: _body(14,
                                      w: FontWeight.w600,
                                      color: _T.primaryContainer,
                                      letterSpacing: 0.2),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Buy now (primary pill) -> opens sheet
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _openVariantSheet(_SheetMode.buy),
                        child: Container(
                          height: 48,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: _T.primaryContainer,
                            borderRadius: BorderRadius.circular(999),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x40173628),
                                blurRadius: 16,
                                spreadRadius: -2,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Text(
                            'Buy Now',
                            style: _body(14,
                                w: FontWeight.w600,
                                color: Colors.white,
                                letterSpacing: 0.2),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------
  // TOP BAR
  // ----------------------------------------------------------
  Widget _circleAction({
    required IconData icon,
    required VoidCallback onPressed,
    Color color = _T.primary,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: Center(
        child: GestureDetector(
          onTap: onPressed,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _T.card.withOpacity(0.8),
              shape: BoxShape.circle,
              boxShadow: const [
                BoxShadow(
                  color: _T.shadow,
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, size: 20, color: color),
          ),
        ),
      ),
    );
  }

  // ----------------------------------------------------------
  // GALLERY
  // ----------------------------------------------------------
  Widget _buildGallery() {
    return AspectRatio(
      aspectRatio: 1,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Main image placeholder
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            color: Color.alphaBlend(
              _imageColors[_imageIndex].withAlpha(36),
              _T.card,
            ),
            child: Center(
              child: Icon(
                Icons.headphones_rounded,
                size: 120,
                color: _imageColors[_imageIndex],
              ),
            ),
          ),
          // Floating badge (top-left)
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _T.featuredBadge,
                borderRadius: BorderRadius.circular(999),
                boxShadow: const [
                  BoxShadow(
                    color: _T.shadow,
                    blurRadius: 4,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: Text(
                'HOT',
                style: _body(11,
                    w: FontWeight.w700,
                    color: _T.tertiary,
                    letterSpacing: 0.9),
              ),
            ),
          ),
          // Counter pill + dots (bottom)
          Positioned(
            bottom: 12,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                  decoration: BoxDecoration(
                    color: _T.primary.withOpacity(0.75),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${_imageIndex + 1} / ${_imageColors.length}',
                    style: _body(11,
                        w: FontWeight.w600,
                        color: _T.surface,
                        letterSpacing: 0.6),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_imageColors.length, (i) {
                    final active = _imageIndex == i;
                    return GestureDetector(
                      onTap: () => _selectVariant(_variants[i]),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: active ? 10 : 7,
                        height: active ? 10 : 7,
                        decoration: BoxDecoration(
                          color: active
                              ? _T.primary
                              : Colors.white.withOpacity(0.7),
                          shape: BoxShape.circle,
                          border: active
                              ? Border.all(color: Colors.white, width: 2)
                              : null,
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------
  // VARIATION THUMBNAIL STRIP
  // ----------------------------------------------------------
  Widget _buildVariantStrip() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: _T.outlineVariant.withOpacity(0.2)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_variants.length} VARIATIONS AVAILABLE',
                style: _body(12,
                    w: FontWeight.w700,
                    color: _T.primary,
                    letterSpacing: 0.8),
              ),
              Row(
                children: [
                  Text('Tap to view',
                      style: _body(11, w: FontWeight.w500)),
                  const Icon(Icons.chevron_right_rounded,
                      size: 14, color: _T.onSurfaceVariant),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _variants.map((v) {
                final sel = _selectedVariant == v;
                final swatch = _variantColors[v]!;
                final isLight = v == 'White';
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => _selectVariant(v),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: sel
                            ? _T.primary.withOpacity(0.05)
                            : _T.containerLow,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: sel
                              ? _T.primary
                              : _T.outlineVariant.withOpacity(0.4),
                          width: sel ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: swatch,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                  color:
                                      _T.outlineVariant.withOpacity(0.3)),
                            ),
                            child: Icon(Icons.headphones_rounded,
                                size: 26,
                                color: isLight
                                    ? _T.primaryContainer
                                    : Colors.white),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            v,
                            style: _body(10,
                                w: sel ? FontWeight.w700 : FontWeight.w500,
                                color: sel ? _T.primary : _T.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------
  // INFO BLOCKS
  // ----------------------------------------------------------
  Widget _buildRatingRow() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _T.containerLow.withOpacity(0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _T.outlineVariant.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.star_rounded,
                        size: 18, color: _T.tertiaryFixedDim),
                    Icon(Icons.star_rounded,
                        size: 18, color: _T.tertiaryFixedDim),
                    Icon(Icons.star_rounded,
                        size: 18, color: _T.tertiaryFixedDim),
                    Icon(Icons.star_rounded,
                        size: 18, color: _T.tertiaryFixedDim),
                    Icon(Icons.star_half_rounded,
                        size: 18, color: _T.tertiaryFixedDim),
                  ],
                ),
                Text('4.8',
                    style: _body(12, w: FontWeight.w700, color: _T.primary)),
                Text('•', style: _body(12, color: _T.outline)),
                Text('350+ sold',
                    style: _body(12,
                        w: FontWeight.w500, color: _T.secondary)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.fromLTRB(10, 5, 6, 5),
            decoration: BoxDecoration(
              color: _T.card,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: _T.primary.withOpacity(0.1)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('See All (230)',
                    style: _body(11,
                        w: FontWeight.w700,
                        color: _T.primary,
                        letterSpacing: 0.3)),
                const Icon(Icons.chevron_right_rounded,
                    size: 14, color: _T.primary),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(_peso(widget.product?['price'] is num ? (widget.product!['price'] as num).toInt() : _unitPrice),
                    style: _body(26,
                        w: FontWeight.w700,
                        color: _T.primary,
                        letterSpacing: -0.3)),
                const SizedBox(width: 10),
                Text(
                  _peso(widget.product?['old_price'] is num ? (widget.product!['old_price'] as num).toInt() : _originalPrice),
                  style: _body(14, color: _T.outline).copyWith(
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _T.errorContainer,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '48% OFF',
              style: _body(11,
                  w: FontWeight.w700,
                  color: _T.onErrorContainer,
                  letterSpacing: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  // Variations entry row -> opens the bottom sheet
  Widget _buildVariationRow() {
    return GestureDetector(
      onTap: () => _openVariantSheet(_SheetMode.select),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _T.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _T.primary.withOpacity(0.1)),
          boxShadow: const [
            BoxShadow(
              color: _T.shadow,
              blurRadius: 12,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Text('VARIATIONS',
                style: _body(11,
                    w: FontWeight.w600,
                    color: _T.onSurfaceVariant,
                    letterSpacing: 0.8)),
            const SizedBox(width: 12),
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: _variantColors[_selectedVariant],
                shape: BoxShape.circle,
                border: Border.all(color: _T.primary.withOpacity(0.2)),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                _summary,
                overflow: TextOverflow.ellipsis,
                style: _body(12, w: FontWeight.w700, color: _T.primary),
              ),
            ),
            Text('Choose', style: _body(12, color: _T.outline)),
            const Icon(Icons.chevron_right_rounded,
                size: 18, color: _T.onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  Widget _qtyStepper(
      {required VoidCallback onMinus, required VoidCallback onPlus}) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _T.containerLow,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _T.outlineVariant.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _qtyButton(Icons.remove_rounded, onMinus),
          SizedBox(
            width: 40,
            child: Text(
              '$_qty',
              textAlign: TextAlign.center,
              style: _body(14, w: FontWeight.w700, color: _T.primary),
            ),
          ),
          _qtyButton(Icons.add_rounded, onPlus),
        ],
      ),
    );
  }

  Widget _qtyButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: _T.card,
          shape: BoxShape.circle,
          boxShadow: const [
            BoxShadow(
              color: _T.shadow,
              blurRadius: 4,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Icon(icon, size: 16, color: _T.primary),
      ),
    );
  }

  Widget _buildShippingSnippet() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _T.containerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _T.outlineVariant.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: _T.card,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _T.shadow,
                  blurRadius: 4,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: const Icon(Icons.local_shipping_outlined,
                size: 18, color: _T.secondary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Free standard shipping',
                    style: _body(12, w: FontWeight.w700, color: _T.primary)),
                const SizedBox(height: 2),
                Text('Estimated delivery within 2–4 business days.',
                    style: _body(12, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------
  // SELLER
  // ----------------------------------------------------------
  Widget _buildSellerCard() {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const MockupSellerStoreScreen()),
      ),
      child: Container(
        decoration: _cardDecoration(),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _T.secondaryContainer.withOpacity(0.6),
                shape: BoxShape.circle,
                border: Border.all(color: _T.primary.withOpacity(0.1)),
              ),
              child: const Icon(Icons.storefront_rounded,
                  color: _T.primaryContainer),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text('TechZone PH',
                            overflow: TextOverflow.ellipsis,
                            style: _body(13,
                                w: FontWeight.w700, color: _T.primary)),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.verified_rounded,
                          size: 16, color: _T.secondary),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          size: 14, color: _T.tertiaryFixedDim),
                      const SizedBox(width: 4),
                      Text('4.9 · 1,240 sales', style: _body(12)),
                    ],
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const MockupSellerStoreScreen()),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: _T.primaryContainer),
                ),
                child: Text('Visit Shop',
                    style: _body(11,
                        w: FontWeight.w700,
                        color: _T.primaryContainer,
                        letterSpacing: 0.4)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------------
  // REVIEWS
  // ----------------------------------------------------------
  Widget _buildReviewSnippet() {
    const reviews = [
      {
        'name': 'Maria S.',
        'rating': 5,
        'comment': 'Amazing sound quality! The noise cancellation works great.',
        'date': '2 days ago',
      },
      {
        'name': 'Carlo T.',
        'rating': 4,
        'comment': 'Great earbuds, comfortable fit. Battery life is excellent.',
        'date': '5 days ago',
      },
    ];

    return Column(
      children: reviews.map((r) {
        final rating = r['rating'] as int;
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: _T.card.withOpacity(0.85),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _T.outlineVariant.withOpacity(0.4)),
            boxShadow: const [
              BoxShadow(
                color: _T.shadow,
                blurRadius: 16,
                spreadRadius: -2,
                offset: Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: _T.secondaryContainer.withOpacity(0.7),
                    child: Text(
                      (r['name'] as String)[0],
                      style: _body(14,
                          w: FontWeight.w700, color: _T.primaryContainer),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r['name'] as String,
                            style: _body(13,
                                w: FontWeight.w700, color: _T.primary)),
                        const SizedBox(height: 2),
                        Row(
                          children: List.generate(
                            5,
                            (i) => Icon(
                              i < rating
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              size: 14,
                              color: i < rating
                                  ? _T.tertiaryFixedDim
                                  : _T.outlineVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(r['date'] as String,
                      style: _body(12, color: _T.outline)),
                ],
              ),
              const SizedBox(height: 10),
              Text(r['comment'] as String, style: _body(14, height: 1.5)),
            ],
          ),
        );
      }).toList(),
    );
  }
}

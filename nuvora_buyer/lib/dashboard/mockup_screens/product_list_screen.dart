// ============================================================
// product_list_screen.dart
// "See all" grid for Featured Products.
//
// Reads the same real data as the website's Featured section
// (/api/landing/featured + /api/landing/new-arrivals, newest
// first, no duplicates) and opens the real product.
// ============================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/api/buyer_api.dart';
import '../../core/navigation/buyer_nav_bar.dart';
import 'product_details_screen.dart';

class _Colors {
  static const surface = Color(0xFFFCF9F8);
  static const card = Colors.white;
  static const forest = Color(0xFF173628);
  static const secondary = Color(0xFF44664B);
  static const inkSoft = Color(0xFF424844);
  static const outline = Color(0xFF727973);
  static const hairline = Color(0x0F173628);
  static const imageBg = Color(0xFFF8FAF8);
  static const error = Color(0xFFBA1A1A);
}

TextStyle _jakarta({
  double size = 14,
  FontWeight weight = FontWeight.w400,
  Color color = _Colors.inkSoft,
}) =>
    GoogleFonts.plusJakartaSans(
      fontSize: size,
      fontWeight: weight,
      color: color,
    );

TextStyle _playfair({double size = 20}) => GoogleFonts.playfairDisplay(
      fontSize: size,
      fontWeight: FontWeight.w600,
      color: const Color(0xFF012114),
    );

String _money(num value) {
  final hasCents = value % 1 != 0;
  final parts = value.toStringAsFixed(hasCents ? 2 : 0).split('.');
  final digits = parts.first;
  final buffer = StringBuffer();

  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
    buffer.write(digits[i]);
  }

  return '₱$buffer${parts.length > 1 ? '.${parts.last}' : ''}';
}

class MockupProductListScreen extends StatefulWidget {
  const MockupProductListScreen({
    super.key,
    this.title = 'Featured Products',
  });

  final String title;

  @override
  State<MockupProductListScreen> createState() =>
      _MockupProductListScreenState();
}

class _MockupProductListScreenState extends State<MockupProductListScreen> {
  List<Map<String, dynamic>> _products = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final rows = await Future.wait([
        BuyerApi.instance.featuredProducts(),
        BuyerApi.instance.newArrivals(),
      ]);

      final merged = <String, Map<String, dynamic>>{};
      for (final product in [...rows[1], ...rows[0]]) {
        final id = (product['id'] ?? '').toString();
        if (id.isEmpty) continue;
        merged.putIfAbsent(id, () => product);
      }

      if (!mounted) return;
      setState(() {
        _products = merged.values.toList();
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error is BuyerApiException
            ? error.message
            : 'Could not load products. Check your connection.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _Colors.surface,
      appBar: AppBar(
        backgroundColor: _Colors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        foregroundColor: const Color(0xFF012114),
        title: Text(widget.title, style: _playfair()),
      ),
      body: _buildBody(),
      bottomNavigationBar: const BuyerNavBar(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: _Colors.forest),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded,
                  size: 36, color: _Colors.secondary),
              const SizedBox(height: 10),
              Text('Products could not load', style: _playfair(size: 18)),
              const SizedBox(height: 6),
              Text(_error!, textAlign: TextAlign.center, style: _jakarta()),
              const SizedBox(height: 14),
              OutlinedButton(
                onPressed: _load,
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
      );
    }

    if (_products.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.inventory_2_outlined,
                  size: 36, color: _Colors.secondary),
              const SizedBox(height: 10),
              Text('No products yet', style: _playfair(size: 18)),
              const SizedBox(height: 6),
              Text(
                'Products appear here as soon as sellers publish them.',
                textAlign: TextAlign.center,
                style: _jakarta(),
              ),
            ],
          ),
        ),
      );
    }

    // Responsive cells: square image + a text block sized from the real card
    // width and the buyer's text scale, so nothing overflows on small phones
    // or wide tablets.
    final media = MediaQuery.of(context);
    final columns = media.size.width >= 700 ? 3 : 2;
    const gridPadding = 16.0;
    const gridSpacing = 12.0;
    final cardWidth =
        (media.size.width - gridPadding * 2 - gridSpacing * (columns - 1)) /
            columns;
    final textScale = media.textScaler.scale(1).clamp(1.0, 2.0);

    return GridView.builder(
      padding: const EdgeInsets.all(gridPadding),
      itemCount: _products.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        mainAxisSpacing: gridSpacing,
        crossAxisSpacing: gridSpacing,
        mainAxisExtent: cardWidth + 126.0 * textScale,
      ),
      itemBuilder: (_, index) {
        final product = _products[index];
        return _ProductTile(
          product: product,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MockupProductDetailsScreen(product: product),
            ),
          ),
        );
      },
    );
  }
}

class _ProductTile extends StatelessWidget {
  const _ProductTile({required this.product, required this.onTap});

  final Map<String, dynamic> product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final store = product['store'];
    final storeName = store is Map
        ? (store['name']?.toString() ?? 'NUVORA Store')
        : 'NUVORA Store';
    final price = product['price'];
    final oldPrice = product['old_price'];
    final stock = (product['stock'] as num?)?.toInt() ?? 0;
    final image = product['image']?.toString() ?? '';
    final discount = (product['discount_percent'] as num?)?.toInt() ?? 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: _Colors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _Colors.hairline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Container(
                      color: _Colors.imageBg,
                      child: image.isEmpty
                          ? const Icon(Icons.image_outlined,
                              size: 36, color: _Colors.outline)
                          : Image.network(
                              image,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.image_not_supported_outlined,
                                size: 32,
                                color: _Colors.outline,
                              ),
                            ),
                    ),
                  ),
                  if (discount > 0)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFDEAD),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          '-$discount%',
                          style: _jakarta(
                            size: 10,
                            weight: FontWeight.w700,
                            color: const Color(0xFF281900),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 9, 12, 9),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          storeName.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _jakarta(
                            size: 10,
                            weight: FontWeight.w700,
                            color: _Colors.secondary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          product['name']?.toString() ?? 'Product',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: _jakarta(
                            size: 13,
                            weight: FontWeight.w500,
                            color: const Color(0xFF1C1B1B),
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                price is num ? _money(price) : '',
                                style: _jakarta(
                                  size: 15,
                                  weight: FontWeight.w700,
                                  color: const Color(0xFF012114),
                                ),
                              ),
                            ),
                            if (oldPrice is num &&
                                price is num &&
                                oldPrice > price) ...[
                              const SizedBox(width: 6),
                              Text(
                                _money(oldPrice),
                                style: _jakarta(
                                  size: 10,
                                  color: _Colors.outline,
                                ).copyWith(
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          stock <= 0
                              ? 'Sold out'
                              : stock <= 5
                                  ? 'Only $stock left'
                                  : 'In stock',
                          style: _jakarta(
                            size: 10,
                            weight: FontWeight.w600,
                            color: stock <= 0
                                ? _Colors.error
                                : _Colors.secondary,
                          ),
                        ),
                      ],
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
}

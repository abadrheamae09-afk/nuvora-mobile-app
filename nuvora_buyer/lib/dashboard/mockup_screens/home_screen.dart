// ============================================================
// home_screen.dart
// Buyer home screen.
//
// Products are REAL: the Featured row is loaded from the same
// public endpoints the buyer website uses
// (/api/landing/featured and /api/landing/new-arrivals, newest
// first, no duplicates). The retired "New Arrivals" section lives
// inside Featured Products now.
//
// Navigation lives in lib/core/navigation/buyer_nav_bar.dart.
// ============================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/api/buyer_api.dart';
import '../../core/navigation/buyer_nav_bar.dart';
import 'category_list_screen.dart';
import 'product_details_screen.dart';
import 'product_list_screen.dart';
import 'search_results_screen.dart';
import 'seller_store_screen.dart';

// ── Design tokens for this screen (from the redesign) ───────
class _HColors {
  static const background = Color(0xFFFCF9F8);
  static const surface = Color(0xFFFCF9F8);
  static const card = Colors.white;
  static const forest = Color(0xFF173628); // primary-container
  static const forestDeep = Color(0xFF012114); // primary
  static const sage = Color(0xFFC2E9C7); // secondary-container
  static const secondary = Color(0xFF44664B);
  static const amber = Color(0xFFFFDEAD); // tertiary-fixed
  static const amberText = Color(0xFF281900);
  static const searchFill = Color(0xFFF3F4F3);
  static const pillInactive = Color(0xFFF6F3F2);
  static const imageBg = Color(0xFFF8FAF8);
  static const ink = Color(0xFF1C1B1B);
  static const inkSoft = Color(0xFF424844);
  static const outline = Color(0xFF727973);
  static const outlineSoft = Color(0xFFC1C8C2);
  static const hairline = Color(0x0F173628); // 6% forest
  static const shadow = Color(0x0A173628); // 4% forest
  static const error = Color(0xFFBA1A1A);
}

TextStyle _jakarta({
  double size = 14,
  FontWeight weight = FontWeight.w400,
  Color color = _HColors.ink,
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
  double size = 22,
  FontWeight weight = FontWeight.w600,
  Color color = _HColors.forestDeep,
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

// ── Category shortcuts (labels only; products are always live) ─
const List<Map<String, dynamic>> _categories = [
  {'label': 'Electronics', 'icon': Icons.devices_other_outlined},
  {'label': 'Fashion', 'icon': Icons.checkroom_outlined},
  {'label': 'Food', 'icon': Icons.lunch_dining_outlined},
  {'label': 'Beauty', 'icon': Icons.spa_outlined},
  {'label': 'Sports', 'icon': Icons.sports_basketball_outlined},
  {'label': 'Home', 'icon': Icons.weekend_outlined},
  {'label': 'Books', 'icon': Icons.menu_book_outlined},
  {'label': 'More', 'icon': Icons.grid_view_rounded},
];

const List<Map<String, dynamic>> _banners = [
  {
    'tag': 'Super Sale',
    'title': 'Super Sale 11.11',
    'subtitle': 'Up to 80% off storewide',
  },
  {
    'tag': 'Free Shipping',
    'title': 'Free Shipping',
    'subtitle': 'No minimum purchase required',
  },
  {
    'tag': 'Curated Pick',
    'title': 'Featured Products',
    'subtitle': 'Handpicked from our sellers',
  },
];

/// Responsive product grid. Each card's image is square, so the cell height
/// is the computed card width plus the text block below it. Deriving both
/// from the real screen width (instead of one fixed aspect ratio) stops the
/// cards from overflowing on narrow phones, wide tablets and large-text
/// settings.
SliverGridDelegateWithFixedCrossAxisCount _productGridDelegate(
    BuildContext context) {
  final media = MediaQuery.of(context);
  final columns = media.size.width >= 700 ? 3 : 2;
  const padding = 16.0;
  const spacing = 12.0;
  final cardWidth =
      (media.size.width - padding * 2 - spacing * (columns - 1)) / columns;
  final textScale = media.textScaler.scale(1).clamp(1.0, 2.0);

  return SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: columns,
    mainAxisSpacing: spacing,
    crossAxisSpacing: spacing,
    mainAxisExtent: cardWidth + 126.0 * textScale,
  );
}

class MockupHomeScreen extends StatefulWidget {
  const MockupHomeScreen({super.key});

  @override
  State<MockupHomeScreen> createState() => _MockupHomeScreenState();
}

class _MockupHomeScreenState extends State<MockupHomeScreen> {
  final PageController _bannerCtrl = PageController(viewportFraction: 0.92);

  List<Map<String, dynamic>> _products = const [];
  bool _loading = true;
  String? _error;
  int _requestId = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _bannerCtrl.dispose();
    super.dispose();
  }

  /// Featured + newest products, newest first, no duplicates — the
  /// same two public endpoints the website's Home reads.
  Future<void> _load() async {
    final requestId = ++_requestId;

    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final rows = await Future.wait([
        BuyerApi.instance.featuredProducts(),
        BuyerApi.instance.newArrivals(),
      ]);

      final merged = <String, Map<String, dynamic>>{};

      // Newest first (the retired New Arrivals row), then the
      // remaining curated featured picks.
      for (final product in [...rows[1], ...rows[0]]) {
        final id = (product['id'] ?? '').toString();
        if (id.isEmpty) continue;
        merged.putIfAbsent(id, () => product);
      }

      if (!mounted || requestId != _requestId) return;

      setState(() {
        _products = merged.values.take(8).toList();
        _loading = false;
      });
    } catch (error) {
      if (!mounted || requestId != _requestId) return;

      setState(() {
        _error = error is BuyerApiException
            ? error.message
            : 'Could not load products. Check your connection.';
        _loading = false;
      });
    }
  }

  void _openProduct(Map<String, dynamic> product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MockupProductDetailsScreen(product: product),
      ),
    );
  }

  void _openStore(Map<String, dynamic> product) {
    final store = product['store'];
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MockupSellerStoreScreen(
          storeName: store is Map ? store['name']?.toString() : null,
        ),
      ),
    );
  }

  Future<void> _addToCart(Map<String, dynamic> product) async {
    final messenger = ScaffoldMessenger.of(context);

    if (product['has_variants'] == true) {
      _openProduct(product);
      return;
    }

    try {
      final result =
          await BuyerApi.instance.addToCart((product['id'] as num).toInt());
      await BuyerNavCounts.refresh();

      messenger.showSnackBar(
        SnackBar(
          content: Text(result['message']?.toString() ?? 'Added to your cart.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on BuyerApiException catch (error) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(error.message),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Could not add this item to your cart.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _HColors.background,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: _HColors.forest,
          onRefresh: _load,
          child: CustomScrollView(
            slivers: [
              _buildTopBar(),
              SliverToBoxAdapter(child: _buildSearch()),
              SliverToBoxAdapter(child: _buildCategoryPills()),
              SliverToBoxAdapter(child: _buildBanners()),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 28, 16, 14),
                  child: _SectionHeader(
                    eyebrow: 'HANDPICKED',
                    title: 'Featured Products',
                    subtitle: 'Standout items from our sellers',
                    actionLabel: 'See all',
                    onAction: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const MockupProductListScreen(
                          title: 'Featured Products',
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              ..._buildProductSlivers(),
              SliverToBoxAdapter(child: _buildMerchantsTeaser()),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const BuyerNavBar(current: BuyerTab.home),
    );
  }

  List<Widget> _buildProductSlivers() {
    if (_loading) {
      return [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverGrid(
            delegate: SliverChildBuilderDelegate(
              (_, __) => const _ProductSkeleton(),
              childCount: 4,
            ),
            gridDelegate: _productGridDelegate(context),
          ),
        ),
      ];
    }

    if (_error != null) {
      return [
        SliverToBoxAdapter(
          child: _FriendlyState(
            icon: Icons.cloud_off_rounded,
            title: 'Products could not load',
            message: _error!,
            actionLabel: 'Try again',
            onAction: _load,
          ),
        ),
      ];
    }

    if (_products.isEmpty) {
      return [
        const SliverToBoxAdapter(
          child: _FriendlyState(
            icon: Icons.inventory_2_outlined,
            title: 'No products yet',
            message:
                'New products will appear here as soon as sellers publish them.',
          ),
        ),
      ];
    }

    return [
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverGrid(
          delegate: SliverChildBuilderDelegate(
            (_, index) => _LiveProductCard(
              product: _products[index],
              onOpen: () => _openProduct(_products[index]),
              onOpenStore: () => _openStore(_products[index]),
              onAdd: () => _addToCart(_products[index]),
            ),
            childCount: _products.length,
          ),
          gridDelegate: _productGridDelegate(context),
        ),
      ),
    ];
  }

  // ── Top app bar: wordmark + cart / alerts ─────────────────
  Widget _buildTopBar() {
    return SliverAppBar(
      pinned: true,
      automaticallyImplyLeading: false,
      backgroundColor: _HColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 2,
      shadowColor: _HColors.shadow,
      toolbarHeight: 60,
      titleSpacing: 16,
      title: Row(
        children: [
          const Icon(Icons.shopping_bag_outlined,
              size: 24, color: _HColors.forest),
          const SizedBox(width: 4),
          Text(
            'NUVORA',
            style: _playfair(
              size: 20,
              weight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
      actions: [
        ValueListenableBuilder<int>(
          valueListenable: BuyerNavCounts.notifications,
          builder: (_, count, child) => IconButton(
            tooltip: 'Alerts',
            onPressed: () => openBuyerTab(context, BuyerTab.notifications),
            icon: count > 0
                ? Badge(
                    label: Text('$count'),
                    backgroundColor: _HColors.forest,
                    child: const Icon(Icons.notifications_none_rounded,
                        size: 22, color: _HColors.ink),
                  )
                : const Icon(Icons.notifications_none_rounded,
                    size: 22, color: _HColors.ink),
          ),
        ),
        ValueListenableBuilder<int>(
          valueListenable: BuyerNavCounts.cart,
          builder: (_, count, child) => IconButton(
            tooltip: 'Cart',
            onPressed: () => openBuyerTab(context, BuyerTab.cart),
            icon: count > 0
                ? Badge(
                    label: Text('$count'),
                    backgroundColor: _HColors.forest,
                    child: const Icon(Icons.shopping_cart_outlined,
                        size: 22, color: _HColors.ink),
                  )
                : const Icon(Icons.shopping_cart_outlined,
                    size: 22, color: _HColors.ink),
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  // ── Search pill ───────────────────────────────────────────
  Widget _buildSearch() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => const MockupSearchResultsScreen()),
        ),
        child: Container(
          height: 44,
          decoration: BoxDecoration(
            color: _HColors.searchFill,
            borderRadius: BorderRadius.circular(99),
          ),
          child: Row(
            children: [
              const SizedBox(width: 16),
              const Icon(Icons.search_rounded,
                  color: _HColors.outline, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Search products & stores...',
                  style: _jakarta(color: _HColors.outline),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Category pills (horizontal) ───────────────────────────
  Widget _buildCategoryPills() {
    final labels = <String>[
      'Home',
      'Categories',
      ..._categories
          .map((c) => c['label'] as String)
          .where((l) => l != 'More' && l != 'Home'),
    ];
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: labels.length,
        separatorBuilder: (_, __) => const SizedBox(width: 4),
        itemBuilder: (_, i) {
          final active = i == 0;
          return Center(
            child: GestureDetector(
              onTap: active
                  ? null
                  : () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const MockupCategoryListScreen(),
                        ),
                      ),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                decoration: BoxDecoration(
                  color: active ? _HColors.forest : _HColors.pillInactive,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  labels[i],
                  style: _jakarta(
                    size: 12,
                    weight: FontWeight.w600,
                    letterSpacing: 0.2,
                    color: active ? Colors.white : _HColors.inkSoft,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Curated banners ───────────────────────────────────────
  Widget _buildBanners() {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: SizedBox(
        height: 150,
        child: PageView.builder(
          controller: _bannerCtrl,
          padEnds: false,
          itemCount: _banners.length,
          itemBuilder: (_, i) {
            final b = _banners[i];
            return Container(
              margin: EdgeInsets.only(
                left: i == 0 ? 16 : 6,
                right: i == _banners.length - 1 ? 16 : 6,
              ),
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFF0F4F1),
                    Color(0xFFF6F8F5),
                    Color(0xFFF6F3F2),
                  ],
                ),
                border: Border.all(color: _HColors.hairline),
                boxShadow: const [
                  BoxShadow(
                    color: _HColors.shadow,
                    blurRadius: 16,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -24,
                    bottom: -40,
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFAAD0AF).withAlpha(70),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _HColors.sage,
                                  borderRadius: BorderRadius.circular(99),
                                ),
                                child: Text(
                                  (b['tag'] as String).toUpperCase(),
                                  style: _jakarta(
                                    size: 10,
                                    weight: FontWeight.w700,
                                    letterSpacing: 0.8,
                                    color: const Color(0xFF00210C),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                b['title'] as String,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: _playfair(size: 20, height: 1.2),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                b['subtitle'] as String,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: _jakarta(
                                  size: 12,
                                  color: _HColors.inkSoft,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const MockupProductListScreen(
                                title: 'Featured Products',
                              ),
                            ),
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 9),
                            decoration: BoxDecoration(
                              color: _HColors.forest,
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Text(
                              'Shop Now',
                              style: _jakarta(
                                size: 12,
                                weight: FontWeight.w600,
                                letterSpacing: 0.2,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
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

  // ── Certified merchants teaser ────────────────────────────
  Widget _buildMerchantsTeaser() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 36, 16, 32),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _HColors.pillInactive,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _HColors.hairline),
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: _HColors.forest,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.verified_outlined,
                      color: Colors.white, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Certified Independent Merchants',
                        style: _playfair(size: 18, height: 1.3),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Every vendor is personally vetted for authentic '
                        'craftsmanship and ethical sourcing.',
                        style: _jakarta(
                          size: 12,
                          color: _HColors.inkSoft,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const MockupSellerStoreScreen(),
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: _HColors.forestDeep,
                side: const BorderSide(color: _HColors.forestDeep),
                shape: const StadiumBorder(),
                padding:
                    const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
              ),
              child: Text(
                'Explore Directory',
                style: _jakarta(
                  size: 12,
                  weight: FontWeight.w600,
                  color: _HColors.forestDeep,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Section header (eyebrow + serif title + pill action) ────
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.eyebrow,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final String eyebrow;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                eyebrow,
                style: _jakarta(
                  size: 11,
                  weight: FontWeight.w700,
                  letterSpacing: 0.9,
                  color: _HColors.inkSoft,
                ),
              ),
              const SizedBox(height: 4),
              Text(title, style: _playfair(size: 24, height: 1.25)),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: _jakarta(size: 13, color: _HColors.inkSoft),
                ),
              ],
            ],
          ),
        ),
        if (actionLabel != null)
          GestureDetector(
            onTap: onAction,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(99),
                border: Border.all(color: _HColors.forestDeep),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    actionLabel!,
                    style: _jakarta(
                      size: 12,
                      weight: FontWeight.w600,
                      color: _HColors.forestDeep,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_forward_rounded,
                      size: 15, color: _HColors.forestDeep),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

// ── Live product card (real image, store, name, price, stock) ─
class _LiveProductCard extends StatefulWidget {
  const _LiveProductCard({
    required this.product,
    required this.onOpen,
    required this.onOpenStore,
    required this.onAdd,
  });

  final Map<String, dynamic> product;
  final VoidCallback onOpen;
  final VoidCallback onOpenStore;
  final Future<void> Function() onAdd;

  @override
  State<_LiveProductCard> createState() => _LiveProductCardState();
}

class _LiveProductCardState extends State<_LiveProductCard> {
  bool _liked = false;
  bool _adding = false;

  Map<String, dynamic>? get _store {
    final store = widget.product['store'];
    return store is Map ? Map<String, dynamic>.from(store) : null;
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final name = product['name']?.toString() ?? 'Product';
    final image = product['image']?.toString() ?? '';
    final price = product['price'];
    final oldPrice = product['old_price'];
    final stock = (product['stock'] as num?)?.toInt() ?? 0;
    final discount = (product['discount_percent'] as num?)?.toInt() ?? 0;
    final storeName = _store?['name']?.toString() ?? 'NUVORA Store';

    final stockLabel = stock <= 0
        ? 'Sold out'
        : stock <= 5
            ? 'Only $stock left'
            : 'In stock';

    return GestureDetector(
      onTap: widget.onOpen,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: _HColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _HColors.hairline),
          boxShadow: const [
            BoxShadow(
              color: _HColors.shadow,
              blurRadius: 16,
              offset: Offset(0, 4),
            ),
          ],
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
                      color: _HColors.imageBg,
                      child: image.isEmpty
                          ? const Icon(Icons.image_outlined,
                              size: 40, color: _HColors.outlineSoft)
                          : Image.network(
                              image,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.image_not_supported_outlined,
                                size: 36,
                                color: _HColors.outlineSoft,
                              ),
                              loadingBuilder: (_, child, progress) =>
                                  progress == null
                                      ? child
                                      : const Center(
                                          child: SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: _HColors.forest,
                                            ),
                                          ),
                                        ),
                            ),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _HColors.amber,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        discount > 0 ? '-$discount%' : '✦ Featured',
                        style: _jakarta(
                          size: 10,
                          weight: FontWeight.w700,
                          color: _HColors.amberText,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: GestureDetector(
                      onTap: () => setState(() => _liked = !_liked),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Color(0x1F173628),
                              blurRadius: 16,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          _liked
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          size: 18,
                          color: _liked ? _HColors.error : _HColors.inkSoft,
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
                        GestureDetector(
                          onTap: widget.onOpenStore,
                          child: Text(
                            storeName.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: _jakarta(
                              size: 10,
                              weight: FontWeight.w700,
                              letterSpacing: 0.8,
                              color: _HColors.secondary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: _jakarta(
                            size: 13,
                            weight: FontWeight.w500,
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                price is num ? _money(price) : '',
                                style: _jakarta(
                                  size: 15,
                                  weight: FontWeight.w700,
                                  letterSpacing: -0.2,
                                  color: _HColors.forestDeep,
                                ),
                              ),
                            ),
                            if (oldPrice is num &&
                                price is num &&
                                oldPrice > price)
                              Text(
                                _money(oldPrice),
                                style: _jakarta(
                                  size: 10,
                                  color: _HColors.outline,
                                ).copyWith(
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                stockLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: _jakarta(
                                  size: 10,
                                  weight: FontWeight.w600,
                                  color: stock <= 0
                                      ? _HColors.error
                                      : _HColors.secondary,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: stock <= 0 || _adding
                                  ? null
                                  : () async {
                                      setState(() => _adding = true);
                                      await widget.onAdd();
                                      if (mounted) {
                                        setState(() => _adding = false);
                                      }
                                    },
                              child: Container(
                                width: 26,
                                height: 26,
                                decoration: BoxDecoration(
                                  color: stock <= 0
                                      ? _HColors.pillInactive
                                      : _HColors.forest,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.add_shopping_cart_rounded,
                                  size: 14,
                                  color: stock <= 0
                                      ? _HColors.outlineSoft
                                      : Colors.white,
                                ),
                              ),
                            ),
                          ],
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

// ── Loading / empty / error states ──────────────────────────
class _ProductSkeleton extends StatelessWidget {
  const _ProductSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _HColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _HColors.hairline),
      ),
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: Container(
              decoration: const BoxDecoration(
                color: _HColors.imageBg,
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 8, width: 70, color: _HColors.searchFill),
                const SizedBox(height: 8),
                Container(height: 10, color: _HColors.searchFill),
                const SizedBox(height: 6),
                Container(height: 10, width: 90, color: _HColors.searchFill),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FriendlyState extends StatelessWidget {
  const _FriendlyState({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: _HColors.pillInactive,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _HColors.hairline),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: _HColors.secondary),
            const SizedBox(height: 10),
            Text(title, style: _playfair(size: 18)),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: _jakarta(size: 12, color: _HColors.inkSoft, height: 1.5),
            ),
            if (actionLabel != null) ...[
              const SizedBox(height: 14),
              OutlinedButton(
                onPressed: onAction,
                style: OutlinedButton.styleFrom(
                  foregroundColor: _HColors.forestDeep,
                  side: const BorderSide(color: _HColors.forestDeep),
                  shape: const StadiumBorder(),
                ),
                child: Text(
                  actionLabel!,
                  style: _jakarta(
                    size: 12,
                    weight: FontWeight.w600,
                    color: _HColors.forestDeep,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

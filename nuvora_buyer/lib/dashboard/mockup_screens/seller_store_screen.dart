// ============================================================
// seller_store_screen.dart
// Seller's public storefront showing their info and products.
// Design: "Botanical Boutique" (Playfair Display + Plus Jakarta Sans,
// forest-green / sage / amber palette).
// Routing and structure are unchanged — only the visuals were updated.
// ============================================================

import 'package:flutter/material.dart';
import '../../core/navigation/buyer_nav_bar.dart';
import 'mockup_widgets.dart';
import 'product_details_screen.dart';

// ── Design tokens (from the redesign) ───────────────────────
class _N {
  static const primary = Color(0xFF173628); // deep forest pine
  static const primaryDeep = Color(0xFF012114);
  static const secondary = Color(0xFF44664B);
  static const sageWash = Color(0xFFE8F0EA);
  static const secondaryContainer = Color(0xFFC2E9C7);
  static const surface = Color(0xFFFCF9F8);
  static const card = Color(0xFFFFFFFF);
  static const surfaceLow = Color(0xFFF6F3F2);
  static const outlineVariant = Color(0xFFC1C8C2);
  static const outline = Color(0xFF727973);
  static const onSurface = Color(0xFF1C1B1B);
  static const onSurfaceVariant = Color(0xFF424844);
  static const amber = Color(0xFFFABC4D);
  static const amberSoft = Color(0xFFFFDEAD);
  static const tertiary = Color(0xFF281900);
  static const error = Color(0xFFBA1A1A);
  static const errorContainer = Color(0xFFFFDAD6);

  static const hairline = Color(0x0F173628); // rgba(23,54,40,.06)
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

BoxDecoration _cardDecoration({double radius = 16}) => BoxDecoration(
      color: _N.card,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: _N.hairline),
      boxShadow: const [
        BoxShadow(
          color: _N.shadow,
          blurRadius: 16,
          spreadRadius: -2,
          offset: Offset(0, 4),
        ),
      ],
    );

const List<Map<String, dynamic>> _sellerProducts = [
  {
    'name': 'Wireless Earbuds Pro',
    'price': '₱1,299',
    'oldPrice': '₱1,599',
    'discount': '-19%',
    'color': Color(0xFF2563EB),
    'rating': 4.8,
    'sold': 350,
    'badge': 'HOT',
  },
  {
    'name': 'Gaming Headset RGB',
    'price': '₱2,499',
    'oldPrice': '₱2,999',
    'discount': '-17%',
    'color': Color(0xFFDC2626),
    'rating': 4.7,
    'sold': 200,
    'badge': null,
  },
  {
    'name': 'USB-C Hub 7-in-1',
    'price': '₱899',
    'oldPrice': null,
    'discount': null,
    'color': Color(0xFF475569),
    'rating': 4.5,
    'sold': 120,
    'badge': null,
  },
  {
    'name': 'Mechanical Keyboard',
    'price': '₱3,299',
    'oldPrice': null,
    'discount': null,
    'color': Color(0xFF16A34A),
    'rating': 4.9,
    'sold': 85,
    'badge': 'TOP',
  },
  {
    'name': 'Portable SSD 1TB',
    'price': '₱3,999',
    'oldPrice': '₱4,499',
    'discount': '-11%',
    'color': Color(0xFF0891B2),
    'rating': 4.8,
    'sold': 60,
    'badge': null,
  },
  {
    'name': 'Webcam 1080p',
    'price': '₱1,499',
    'oldPrice': '₱1,999',
    'discount': '-25%',
    'color': Color(0xFFF59E0B),
    'rating': 4.4,
    'sold': 95,
    'badge': 'SALE',
  },
];

class MockupSellerStoreScreen extends StatefulWidget {
  const MockupSellerStoreScreen({super.key, this.storeName});

  /// Name of the store opened from a real product; null keeps the demo store.
  final String? storeName;

  @override
  State<MockupSellerStoreScreen> createState() =>
      _MockupSellerStoreScreenState();
}

class _MockupSellerStoreScreenState
    extends State<MockupSellerStoreScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;
  int _filterIndex = 0;
  final Set<int> _wishlist = <int>{};

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: const BuyerNavBar(),
      backgroundColor: _N.surface,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          // ── Store header ──────────────────────────────
          SliverToBoxAdapter(child: _buildStoreHeader()),
          // ── Stats row ─────────────────────────────────
          SliverToBoxAdapter(child: _buildStatsRow()),
          // ── Tab bar ───────────────────────────────────
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabBarDelegate(
              TabBar(
                controller: _tabCtrl,
                labelColor: _N.primary,
                unselectedLabelColor: _N.onSurfaceVariant,
                indicator: const UnderlineTabIndicator(
                  borderSide: BorderSide(width: 2.5, color: _N.primary),
                  insets: EdgeInsets.symmetric(horizontal: 16),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelStyle: _sans(size: 14, weight: FontWeight.w700),
                unselectedLabelStyle:
                    _sans(size: 14, weight: FontWeight.w500),
                tabs: const [
                  Tab(text: 'Shop'),
                  Tab(text: 'Products'),
                  Tab(text: 'Reviews'),
                  Tab(text: 'About'),
                ],
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabCtrl,
          children: [
            _buildProductsTab(isShop: true),
            _buildProductsTab(isShop: false),
            _buildReviewsTab(),
            _buildAboutTab(),
          ],
        ),
      ),
    );
  }

  // ── Header: banner + floating merchant card ─────────────
  Widget _buildStoreHeader() {
    final top = MediaQuery.of(context).padding.top;
    final bannerH = top + 170;
    const overlap = 40.0;

    return Stack(
      children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: bannerH,
          child: _buildBanner(),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(16, bannerH - overlap, 16, 0),
          child: _buildMerchantCard(),
        ),
      ],
    );
  }

  Widget _buildBanner() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1D3A2C), _N.primary, _N.primaryDeep],
        ),
      ),
      child: Stack(
        children: [
          // soft atmospheric shapes
          Positioned(
            top: -40,
            right: -30,
            child: Container(
              width: 160,
              height: 160,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0x0FFFFFFF),
              ),
            ),
          ),
          Positioned(
            bottom: 30,
            left: -50,
            child: Container(
              width: 140,
              height: 140,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0x0AACCEBA),
              ),
            ),
          ),
          Column(
            children: [
              AppBar(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                elevation: 0,
                scrolledUnderElevation: 0,
                centerTitle: false,
                titleSpacing: 0,
                title: Text(
                  'NUVORA',
                  style: _serif(
                    size: 20,
                    color: Colors.white,
                    letterSpacing: 1.6,
                  ),
                ),
                actions: [
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.share_outlined, size: 20),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        const Icon(Icons.shopping_bag_outlined, size: 22),
                        Positioned(
                          top: -1,
                          right: -1,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: _N.error,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.more_vert, size: 20),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Container(
                  height: 42,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xE6FCF9F8),
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x1F000000),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search, size: 18, color: _N.outline),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          style: _sans(size: 12),
                          decoration: InputDecoration.collapsed(
                            hintText: 'Search in TechZone PH...',
                            hintStyle:
                                _sans(size: 12, color: _N.outline),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMerchantCard() {
    return Container(
      decoration: _cardDecoration(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar + "Preferred" badge
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: _N.card, width: 2),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x1A173628),
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const CircleAvatar(
                      radius: 32,
                      backgroundColor: _N.sageWash,
                      child: Icon(Icons.storefront_rounded,
                          size: 30, color: _N.primary),
                    ),
                  ),
                  Positioned(
                    bottom: -6,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _N.primaryDeep,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: _N.card),
                        ),
                        child: Text(
                          'PREFERRED',
                          style: _sans(
                            size: 8,
                            weight: FontWeight.w700,
                            color: const Color(0xFFC7EBD6),
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            widget.storeName ?? 'TECHZONE PH',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: _serif(size: 18, height: 1.2),
                          ),
                        ),
                        const SizedBox(width: 5),
                        const Icon(Icons.verified,
                            size: 16, color: _N.primary),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 13, color: _N.onSurfaceVariant),
                        const SizedBox(width: 2),
                        Flexible(
                          child: Text(
                            'Quezon City, Metro Manila',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: _sans(
                                size: 12, color: _N.onSurfaceVariant),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {},
                  style: FilledButton.styleFrom(
                    backgroundColor: _N.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: const StadiumBorder(),
                  ),
                  icon: const Icon(Icons.add, size: 18),
                  label: Text('Follow',
                      style: _sans(
                          size: 14,
                          weight: FontWeight.w600,
                          color: Colors.white)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    backgroundColor: _N.surfaceLow,
                    foregroundColor: _N.primary,
                    side: const BorderSide(color: Color(0x66C1C8C2)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: const StadiumBorder(),
                  ),
                  icon: const Icon(Icons.chat_bubble_outline, size: 18),
                  label: Text('Chat',
                      style: _sans(
                          size: 14,
                          weight: FontWeight.w600,
                          color: _N.primary)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Stats chips ─────────────────────────────────────────
  Widget _buildStatsRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          _statChip('4.9', 'Rating', star: true),
          const SizedBox(width: 8),
          _statChip('1,240', 'Sales'),
          const SizedBox(width: 8),
          _statChip('98%', 'Positive'),
          const SizedBox(width: 8),
          _statChip('2 yrs', 'Active'),
        ],
      ),
    );
  }

  Widget _statChip(String value, String label, {bool star = false}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: _cardDecoration(radius: 14),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (star) ...[
                  const Icon(Icons.star_rounded,
                      size: 15, color: _N.amber),
                  const SizedBox(width: 2),
                ],
                Text(
                  value,
                  style: _sans(
                      size: 13, weight: FontWeight.w700, color: _N.primary),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(label,
                style: _sans(
                    size: 11,
                    weight: FontWeight.w500,
                    color: _N.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }

  // ── Products tab ────────────────────────────────────────
  Widget _buildProductsTab({required bool isShop}) {
    const filters = ['Popular', 'Latest', 'Top Sales'];

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Filter pills (Products tab)
              if (!isShop)
              SizedBox(
                height: 52,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  children: [
                    for (int i = 0; i < filters.length; i++) ...[
                      _filterPill(filters[i], i == _filterIndex,
                          () => setState(() => _filterIndex = i)),
                      const SizedBox(width: 8),
                    ],
                    _filterPill(
                      'Price',
                      _filterIndex == filters.length,
                      () => setState(() => _filterIndex = filters.length),
                      trailing: Icons.swap_vert,
                    ),
                  ],
                ),
              ),
              // Voucher strip (Shop tab)
              if (isShop)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                  child: _buildVoucherStrip(),
                ),
            ],
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.5,
            ),
            delegate: SliverChildBuilderDelegate(
              (_, i) {
                final p = _sellerProducts[i];
                return _StoreProductCard(
                  storeName: widget.storeName,
                  name: p['name'] as String,
                  price: p['price'] as String,
                  oldPrice: p['oldPrice'] as String?,
                  discount: p['discount'] as String?,
                  imageColor: p['color'] as Color,
                  rating: p['rating'] as double,
                  sold: p['sold'] as int,
                  badgeLabel: p['badge'] as String?,
                  isWishlisted: _wishlist.contains(i),
                  onWishlist: () => setState(() {
                    _wishlist.contains(i)
                        ? _wishlist.remove(i)
                        : _wishlist.add(i);
                  }),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const MockupProductDetailsScreen()),
                  ),
                );
              },
              childCount: _sellerProducts.length,
            ),
          ),
        ),
      ],
    );
  }

  Widget _filterPill(String label, bool active, VoidCallback onTap,
      {IconData? trailing}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? _N.primary : const Color(0xFFF0F4F1),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: _sans(
                size: 12,
                weight: FontWeight.w600,
                color: active ? Colors.white : _N.primary,
                letterSpacing: 0.2,
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 4),
              Icon(trailing,
                  size: 16, color: active ? Colors.white : _N.outline),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildVoucherStrip() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0x4DFFDEAD),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x66FABC4D)),
      ),
      child: Row(
        children: [
          const Icon(Icons.redeem_outlined, size: 22, color: _N.tertiary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Collect ₱50 Off Store Voucher',
                    style: _sans(
                        size: 12,
                        weight: FontWeight.w700,
                        color: _N.tertiary)),
                const SizedBox(height: 2),
                Text('Orders above ₱899 • Valid for 7 days',
                    style: _sans(
                        size: 11, color: _N.onSurfaceVariant)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {},
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: _N.tertiary,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                'CLAIM',
                style: _sans(
                  size: 11,
                  weight: FontWeight.w700,
                  color: _N.amberSoft,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Reviews tab ─────────────────────────────────────────
  Widget _buildReviewsTab() {
    const reviews = [
      {
        'name': 'Anna L.',
        'rating': 5,
        'comment': 'Fast shipping and authentic products. Highly recommended!',
        'date': '1 week ago',
      },
      {
        'name': 'Ben R.',
        'rating': 5,
        'comment': 'Great seller, items were well-packed.',
        'date': '2 weeks ago',
      },
      {
        'name': 'Cathy V.',
        'rating': 4,
        'comment': 'Good quality products, slight delay in shipping.',
        'date': '3 weeks ago',
      },
    ];

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: reviews.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        final r = reviews[i];
        return Container(
          decoration: _cardDecoration(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: _N.sageWash,
                    child: Text(
                      (r['name'] as String)[0],
                      style: _serif(size: 16, color: _N.primary),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r['name'] as String,
                            style: _sans(
                                size: 13, weight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        MStarRating(
                            rating: r['rating'] as int, size: 14),
                      ],
                    ),
                  ),
                  Text(r['date'] as String,
                      style: _sans(size: 11, color: _N.outline)),
                ],
              ),
              const SizedBox(height: 10),
              Text(r['comment'] as String,
                  style: _sans(
                      size: 13,
                      color: _N.onSurfaceVariant,
                      height: 1.5)),
            ],
          ),
        );
      },
    );
  }

  // ── About tab ───────────────────────────────────────────
  Widget _buildAboutTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          decoration: _cardDecoration(),
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('About TechZone PH',
                  style: _serif(size: 18, height: 1.3)),
              const SizedBox(height: 10),
              Text(
                'TechZone PH is your one-stop shop for authentic gadgets, accessories, and electronics. We carry top brands at competitive prices with fast and reliable delivery nationwide.',
                style: _sans(
                    size: 14, color: _N.onSurfaceVariant, height: 1.6),
              ),
              const Divider(height: 28, color: Color(0x40C1C8C2)),
              _infoRow(Icons.calendar_today_outlined, 'Member since',
                  'January 2024'),
              const SizedBox(height: 12),
              _infoRow(Icons.local_shipping_outlined, 'Ships from',
                  'Quezon City'),
              const SizedBox(height: 12),
              _infoRow(Icons.schedule_outlined, 'Response time',
                  'Within 1 hour'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: const BoxDecoration(
            color: _N.sageWash,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 16, color: _N.primary),
        ),
        const SizedBox(width: 10),
        Text(label,
            style: _sans(size: 12, color: _N.onSurfaceVariant)),
        const Spacer(),
        Text(value,
            style: _sans(size: 13, weight: FontWeight.w600)),
      ],
    );
  }
}

// ── Product card (redesign) ─────────────────────────────────
class _StoreProductCard extends StatelessWidget {
  const _StoreProductCard({
    required this.name,
    required this.price,
    required this.imageColor,
    required this.rating,
    required this.sold,
    required this.onTap,
    required this.onWishlist,
    required this.isWishlisted,
    this.oldPrice,
    this.discount,
    this.badgeLabel,
    this.storeName,
  });

  final String name;
  final String price;
  final String? oldPrice;
  final String? discount;
  final Color imageColor;
  final double rating;
  final int sold;
  final String? badgeLabel;
  final String? storeName;
  final bool isWishlisted;
  final VoidCallback onTap;
  final VoidCallback onWishlist;

  @override
  Widget build(BuildContext context) {
    final isSale = badgeLabel == 'SALE';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: _cardDecoration(),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image area
            AspectRatio(
              aspectRatio: 1,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color.lerp(imageColor, Colors.white, 0.35)!,
                          imageColor,
                        ],
                      ),
                    ),
                    child: const Center(
                      child: Icon(Icons.devices_other_rounded,
                          size: 48, color: Colors.white70),
                    ),
                  ),
                  if (badgeLabel != null)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isSale ? _N.secondaryContainer : _N.amberSoft,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          badgeLabel!,
                          style: _sans(
                            size: 10,
                            weight: FontWeight.w700,
                            color: isSale
                                ? const Color(0xFF2C4E35)
                                : const Color(0xFF281900),
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: onWishlist,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: const BoxDecoration(
                          color: Color(0xE6FFFFFF),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Color(0x1A000000),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Icon(
                          isWishlisted
                              ? Icons.favorite
                              : Icons.favorite_border,
                          size: 16,
                          color: isWishlisted
                              ? _N.error
                              : _N.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Metadata
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      storeName ?? 'TECHZONE PH',
                      style: _sans(
                        size: 10,
                        weight: FontWeight.w600,
                        color: _N.secondary,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: _sans(size: 13, height: 1.3),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0x80C2E9C7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text('New',
                          style: _sans(
                              size: 10,
                              weight: FontWeight.w500,
                              color: _N.secondary)),
                    ),
                    const Spacer(),
                    Container(
                      height: 1,
                      color: const Color(0x66E5E2E1),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          price,
                          style: _sans(
                            size: 17,
                            weight: FontWeight.w700,
                            color: _N.primary,
                            letterSpacing: -0.2,
                          ),
                        ),
                        if (oldPrice != null) ...[
                          const SizedBox(width: 6),
                          Text(
                            oldPrice!,
                            style: _sans(size: 11, color: _N.outline)
                                .copyWith(
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ],
                        if (discount != null) ...[
                          const SizedBox(width: 6),
                          Text(
                            discount!,
                            style: _sans(
                                size: 10,
                                weight: FontWeight.w700,
                                color: _N.error),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded,
                            size: 14, color: _N.amber),
                        const SizedBox(width: 2),
                        Text('$rating',
                            style: _sans(
                                size: 11, weight: FontWeight.w600)),
                        const Spacer(),
                        Text('$sold+ sold',
                            style: _sans(size: 11, color: _N.outline)),
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

// SliverPersistentHeaderDelegate for the TabBar
class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  const _TabBarDelegate(this.tabBar);

  final TabBar tabBar;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      decoration: const BoxDecoration(
        color: _N.surface,
        border: Border(
          bottom: BorderSide(color: Color(0x40C1C8C2)),
        ),
      ),
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_TabBarDelegate oldDelegate) => false;
}

// ============================================================
// search_results_screen.dart
// Live search mockup with results, recent searches, and
// empty / loading states.
// Design: "Botanical Boutique" (Playfair Display + Plus Jakarta Sans,
// forest-green / sage / amber palette).
// Routing and search logic are unchanged — only the visuals were updated.
// ============================================================

import 'package:flutter/material.dart';
import '../../core/navigation/buyer_nav_bar.dart';
import 'mockup_widgets.dart';
import 'product_details_screen.dart';

// ── Design tokens (from the redesign) ───────────────────────
class _N {
  static const primary = Color(0xFF173628); // deep forest pine
  static const secondary = Color(0xFF44664B);
  static const secondaryContainer = Color(0xFFC2E9C7);
  static const onSecondaryContainer = Color(0xFF486A4F);
  static const sageWash = Color(0xFFE8F0EA);
  static const surface = Color(0xFFFCF9F8);
  static const card = Color(0xFFFFFFFF);
  static const surfaceLow = Color(0xFFF6F3F2);
  static const surfaceContainer = Color(0xFFF0EDED);
  static const outlineVariant = Color(0xFFC1C8C2);
  static const outline = Color(0xFF727973);
  static const onSurface = Color(0xFF1C1B1B);
  static const onSurfaceVariant = Color(0xFF424844);
  static const amber = Color(0xFFFABC4D);
  static const error = Color(0xFFBA1A1A);

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

const List<String> _recentSearches = [
  'wireless earbuds',
  'linen shirt',
  'cookware set',
  'running shoes',
  'face serum',
];

const List<String> _trending = [
  'Sale items',
  'New arrivals',
  'Free shipping',
  'Electronics',
  'Fashion',
  'Beauty',
];

const List<Map<String, dynamic>> _results = [
  {
    'name': 'Wireless Earbuds Pro',
    'price': '₱1,299',
    'color': Color(0xFF2563EB),
    'rating': 4.8,
    'sold': 350,
  },
  {
    'name': 'Wireless Gaming Headset',
    'price': '₱2,499',
    'color': Color(0xFFDC2626),
    'rating': 4.7,
    'sold': 200,
  },
  {
    'name': 'True Wireless Buds Lite',
    'price': '₱799',
    'color': Color(0xFF16A34A),
    'rating': 4.3,
    'sold': 95,
  },
];

class MockupSearchResultsScreen extends StatefulWidget {
  const MockupSearchResultsScreen({super.key});

  @override
  State<MockupSearchResultsScreen> createState() =>
      _MockupSearchResultsScreenState();
}

class _MockupSearchResultsScreenState
    extends State<MockupSearchResultsScreen> {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();
  bool _searching = false;
  bool _hasResults = false;

  // Design-only UI state
  final Set<int> _activeFilters = <int>{0};
  final Set<int> _wishlist = <int>{};

  @override
  void initState() {
    super.initState();
    // Auto focus on open
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _search(String q) {
    if (q.trim().isEmpty) {
      setState(() {
        _searching = false;
        _hasResults = false;
      });
      return;
    }
    setState(() => _searching = true);
    Future.delayed(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      setState(() {
        _searching = false;
        _hasResults = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: const BuyerNavBar(),
      backgroundColor: _N.surface,
      appBar: AppBar(
        backgroundColor: _N.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: _N.primary,
        titleSpacing: 0,
        title: _buildSearchField(),
        actions: [
          IconButton(
            onPressed: () {},
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.shopping_bag_outlined, size: 23),
                Positioned(
                  top: -1,
                  right: -1,
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: _N.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: _N.surface, width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: _searching
          ? const Center(
              child: CircularProgressIndicator(
                  color: _N.primary, strokeWidth: 2.5))
          : _hasResults
              ? _buildResults()
              : _buildInitialState(),
    );
  }

  // ── Pill search field ───────────────────────────────────
  Widget _buildSearchField() {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: _N.surfaceLow,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _N.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, size: 19, color: _N.secondary),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _ctrl,
              focusNode: _focus,
              onChanged: _search,
              onSubmitted: _search,
              cursorColor: _N.primary,
              style: _sans(size: 14, color: _N.onSurface),
              decoration: InputDecoration.collapsed(
                hintText: 'Search products, brands...',
                hintStyle: _sans(size: 14, color: _N.outline),
              ),
            ),
          ),
          if (_ctrl.text.isNotEmpty)
            GestureDetector(
              onTap: () {
                _ctrl.clear();
                _search('');
              },
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.close, size: 17, color: _N.outline),
              ),
            ),
          Container(
            width: 1,
            height: 14,
            margin: const EdgeInsets.symmetric(horizontal: 6),
            color: const Color(0x99C1C8C2),
          ),
          const Icon(Icons.photo_camera_outlined,
              size: 18, color: _N.primary),
        ],
      ),
    );
  }

  // ── Initial state: recent + trending ────────────────────
  Widget _buildInitialState() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Text('Recent Searches', style: _serif(size: 18, height: 1.3)),
        const SizedBox(height: 8),
        Container(
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
          child: Column(
            children: List.generate(_recentSearches.length, (i) {
              final term = _recentSearches[i];
              return Column(
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      _ctrl.text = term;
                      _search(term);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: const BoxDecoration(
                              color: _N.sageWash,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.history_rounded,
                                size: 17, color: _N.secondary),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(term,
                                style: _sans(
                                    size: 14,
                                    weight: FontWeight.w500,
                                    color: _N.primary)),
                          ),
                          const Icon(Icons.north_west_rounded,
                              size: 16, color: _N.outline),
                        ],
                      ),
                    ),
                  ),
                  if (i < _recentSearches.length - 1)
                    const Divider(
                        height: 1, indent: 58, color: _N.divider),
                ],
              );
            }),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Text('Trending Now', style: _serif(size: 18, height: 1.3)),
            const SizedBox(width: 6),
            const Icon(Icons.local_fire_department,
                size: 18, color: _N.amber),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _trending.map(_tagChip).toList(),
        ),
      ],
    );
  }

  Widget _tagChip(String t) {
    return GestureDetector(
      onTap: () {
        _ctrl.text = t;
        _search(t);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: _N.surfaceContainer,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          t,
          style: _sans(
            size: 12,
            weight: FontWeight.w600,
            color: _N.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  // ── Results ─────────────────────────────────────────────
  Widget _buildResults() {
    if (_results.isEmpty) {
      return const MEmptyState(
        icon: Icons.search_off_rounded,
        title: 'No results found',
        subtitle: 'Try different keywords or check your spelling.',
      );
    }

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _buildResultsHeader()),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.62,
            ),
            delegate: SliverChildBuilderDelegate(
              (_, i) {
                final p = _results[i];
                return _ResultCard(
                  name: p['name'] as String,
                  price: p['price'] as String,
                  imageColor: p['color'] as Color,
                  rating: p['rating'] as double,
                  sold: p['sold'] as int,
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
              childCount: _results.length,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultsHeader() {
    const filters = [
      ('Sort: Popularity', Icons.expand_more),
      ('Price: Low to High', null),
      ('Eco-Friendly', Icons.eco_outlined),
      ('Preferred', Icons.verified),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 0, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title + filters trigger
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Search Results',
                          style: _serif(size: 18, height: 1.3)),
                      const SizedBox(height: 2),
                      Text.rich(
                        TextSpan(
                          style: _sans(
                              size: 12, color: _N.onSurfaceVariant),
                          children: [
                            TextSpan(
                                text: '${_results.length} items found for '),
                            TextSpan(
                              text: '“${_ctrl.text}”',
                              style: _sans(
                                size: 12,
                                weight: FontWeight.w600,
                                color: _N.primary,
                              ).copyWith(fontStyle: FontStyle.italic),
                            ),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: _N.card,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: const Color(0x80C1C8C2)),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0F173628),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.tune, size: 16, color: _N.primary),
                      const SizedBox(width: 6),
                      Text('Filters',
                          style: _sans(
                              size: 12,
                              weight: FontWeight.w600,
                              color: _N.primary)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Filter chips strip
          SizedBox(
            height: 34,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(right: 16),
              itemCount: filters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) => _filterChip(
                i,
                filters[i].$1,
                filters[i].$2,
              ),
            ),
          ),
          const SizedBox(height: 14),
          // Related searches
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.explore_outlined,
                        size: 14, color: _N.secondary),
                    const SizedBox(width: 6),
                    Text(
                      'RELATED SEARCHES',
                      style: _sans(
                        size: 10,
                        weight: FontWeight.w700,
                        color: _N.outline,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _trending.take(5).map(_tagChip).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],
      ),
    );
  }

  Widget _filterChip(int index, String label, IconData? icon) {
    final active = _activeFilters.contains(index);
    final isEco = index == 2;

    final Color bg;
    final Color fg;
    final Color borderColor;
    if (active && isEco) {
      bg = const Color(0x66C2E9C7);
      fg = _N.onSecondaryContainer;
      borderColor = const Color(0x3344664B);
    } else if (active) {
      bg = _N.primary;
      fg = Colors.white;
      borderColor = _N.primary;
    } else {
      bg = _N.surfaceLow;
      fg = _N.onSurfaceVariant;
      borderColor = const Color(0x4DC1C8C2);
    }

    return GestureDetector(
      onTap: () => setState(() {
        _activeFilters.contains(index)
            ? _activeFilters.remove(index)
            : _activeFilters.add(index);
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null && icon != Icons.expand_more) ...[
              Icon(
                icon,
                size: 14,
                color: index == 3 ? _N.amber : _N.secondary,
              ),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: _sans(
                size: 12,
                weight: FontWeight.w600,
                color: fg,
              ),
            ),
            if (icon == Icons.expand_more) ...[
              const SizedBox(width: 3),
              Icon(icon, size: 15, color: fg),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Result card (redesign) ──────────────────────────────────
class _ResultCard extends StatelessWidget {
  const _ResultCard({
    required this.name,
    required this.price,
    required this.imageColor,
    required this.rating,
    required this.sold,
    required this.isWishlisted,
    required this.onWishlist,
    required this.onTap,
  });

  final String name;
  final String price;
  final Color imageColor;
  final double rating;
  final int sold;
  final bool isWishlisted;
  final VoidCallback onWishlist;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image frame
            AspectRatio(
              aspectRatio: 1,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
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
                            size: 44, color: Colors.white70),
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
                            color: isWishlisted ? _N.error : _N.primary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Text(
                name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: _sans(
                  size: 13,
                  weight: FontWeight.w500,
                  color: _N.primary,
                  height: 1.3,
                ),
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Row(
                children: [
                  const Icon(Icons.star_rounded, size: 14, color: _N.amber),
                  const SizedBox(width: 3),
                  Text('$rating',
                      style: _sans(
                          size: 11,
                          weight: FontWeight.w600)),
                  const SizedBox(width: 4),
                  Text('· $sold sold',
                      style: _sans(size: 11, color: _N.outline)),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.fromLTRB(2, 0, 2, 2),
              child: Text(
                price,
                style: _sans(
                  size: 17,
                  weight: FontWeight.w700,
                  color: _N.primary,
                  letterSpacing: -0.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

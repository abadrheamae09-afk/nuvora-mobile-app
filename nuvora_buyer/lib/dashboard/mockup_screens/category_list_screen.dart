// ============================================================
// category_list_screen.dart
// Browse all product categories with icons and sub-categories.
// Redesigned UI: "Botanical Boutique" (NUVORA) to match the
// buyer login + home screens. Routing/logic is unchanged:
// every sub-category still opens
// MockupProductListScreen(categoryName: <sub-category>).
// ============================================================

import 'package:flutter/material.dart';
import '../../core/navigation/buyer_nav_bar.dart';
import 'package:google_fonts/google_fonts.dart';
import 'product_list_screen.dart';

// ── Design tokens for this screen (from the redesign) ───────
class _CColors {
  static const background = Color(0xFFFCF9F8);
  static const forest = Color(0xFF173628); // primary-container
  static const forestDeep = Color(0xFF012114); // primary
  static const sage = Color(0xFFC2E9C7); // secondary-container
  static const sageChip = Color(0xFFE8F0EA);
  static const secondary = Color(0xFF44664B);
  static const amber = Color(0xFFFDE8B3);
  static const amberText = Color(0xFF281900);
  static const searchFill = Color(0xFFF3F4F3);
  static const lowSurface = Color(0xFFF6F3F2);
  static const ink = Color(0xFF1C1B1B);
  static const inkSoft = Color(0xFF424844);
  static const outline = Color(0xFF727973);
  static const outlineSoft = Color(0xFFC1C8C2);
  static const shadow = Color(0x0A173628); // 4% forest
}

TextStyle _jakarta({
  double size = 14,
  FontWeight weight = FontWeight.w400,
  Color color = _CColors.ink,
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
  Color color = _CColors.forestDeep,
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

// ── Dummy data (unchanged) ──────────────────────────────────

const List<Map<String, dynamic>> _allCategories = [
  {
    'label': 'Electronics',
    'icon': Icons.devices_other_outlined,
    'count': '2,340',
    'color': Color(0xFF2563EB),
    'subs': ['Phones', 'Laptops', 'Accessories', 'Cameras'],
  },
  {
    'label': 'Fashion',
    'icon': Icons.checkroom_outlined,
    'count': '5,120',
    'color': Color(0xFFEC4899),
    'subs': ["Men's Wear", "Women's Wear", 'Shoes', 'Bags'],
  },
  {
    'label': 'Food & Grocery',
    'icon': Icons.lunch_dining_outlined,
    'count': '890',
    'color': Color(0xFF16A34A),
    'subs': ['Fresh Produce', 'Snacks', 'Beverages', 'Pantry'],
  },
  {
    'label': 'Beauty & Health',
    'icon': Icons.spa_outlined,
    'count': '1,580',
    'color': Color(0xFFA855F7),
    'subs': ['Skincare', 'Makeup', 'Hair Care', 'Vitamins'],
  },
  {
    'label': 'Sports',
    'icon': Icons.sports_basketball_outlined,
    'count': '740',
    'color': Color(0xFFF59E0B),
    'subs': ['Gym', 'Outdoor', 'Team Sports', 'Fitness'],
  },
  {
    'label': 'Home & Living',
    'icon': Icons.weekend_outlined,
    'count': '1,230',
    'color': Color(0xFF0891B2),
    'subs': ['Furniture', 'Decor', 'Kitchen', 'Bedding'],
  },
  {
    'label': 'Books & Media',
    'icon': Icons.menu_book_outlined,
    'count': '420',
    'color': Color(0xFF854D0E),
    'subs': ['Fiction', 'Non-fiction', 'Academic', 'Comics'],
  },
  {
    'label': 'Toys & Games',
    'icon': Icons.toys_outlined,
    'count': '650',
    'color': Color(0xFFDC2626),
    'subs': ['Kids', 'Board Games', 'Action Figures', 'Puzzles'],
  },
  {
    'label': 'Automotive',
    'icon': Icons.directions_car_outlined,
    'count': '310',
    'color': Color(0xFF475569),
    'subs': ['Accessories', 'Tools', 'Parts', 'Detailing'],
  },
  {
    'label': 'Pets',
    'icon': Icons.pets_outlined,
    'count': '290',
    'color': Color(0xFF0F766E),
    'subs': ['Food', 'Grooming', 'Toys', 'Housing'],
  },
];

// Design-only "Trending Now" strip (no navigation).
const List<Map<String, dynamic>> _trending = [
  {'label': 'Rare Monsteras', 'icon': Icons.eco_outlined},
  {'label': 'Linen Dresses', 'icon': Icons.checkroom_outlined},
  {'label': 'Serums & Oils', 'icon': Icons.spa_outlined},
  {'label': 'Terracotta', 'icon': Icons.local_florist_outlined},
  {'label': 'Wild Herbs', 'icon': Icons.grass_outlined},
];

class MockupCategoryListScreen extends StatefulWidget {
  const MockupCategoryListScreen({super.key});

  @override
  State<MockupCategoryListScreen> createState() =>
      _MockupCategoryListScreenState();
}

class _MockupCategoryListScreenState
    extends State<MockupCategoryListScreen> {

  int _filter = -1; // -1 = All, otherwise index in _allCategories (view only)

  List<int> get _visible => _filter == -1
      ? List<int>.generate(_allCategories.length, (i) => i)
      : [_filter];

  @override
  Widget build(BuildContext context) {
    final visible = _visible;
    return Scaffold(
      backgroundColor: _CColors.background,
      appBar: _buildAppBar(),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildTrustPill()),
          SliverToBoxAdapter(child: _buildSearch()),
          SliverToBoxAdapter(child: _buildFilterChips()),
          SliverToBoxAdapter(child: _buildHero()),
          SliverToBoxAdapter(child: _buildTrending()),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('All Departments', style: _playfair(size: 18)),
                  Text(
                    '${visible.length} Curated '
                    '${visible.length == 1 ? 'Realm' : 'Realms'}',
                    style: _jakarta(size: 12, color: _CColors.inkSoft),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (_, i) => _buildCategoryCard(visible[i]),
                childCount: visible.length,
              ),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.6,
              ),
            ),
          ),
          SliverToBoxAdapter(child: _buildStandardCard()),
        ],
      ),
      bottomNavigationBar: const BuyerNavBar(current: BuyerTab.categories),
    );
  }

  // ── Top app bar: menu · NUVORA / CATEGORIES · bag ─────────
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _CColors.background,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 2,
      shadowColor: _CColors.shadow,
      automaticallyImplyLeading: false,
      centerTitle: true,
      toolbarHeight: 60,
      leading: IconButton(
        onPressed: () {},
        icon: const Icon(Icons.menu_rounded,
            size: 24, color: _CColors.forestDeep),
      ),
      title: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'NUVORA',
            style: _playfair(size: 20, letterSpacing: 1.4, height: 1.1),
          ),
          Text(
            'CATEGORIES',
            style: _jakarta(
              size: 10,
              weight: FontWeight.w700,
              letterSpacing: 1.6,
              color: _CColors.secondary,
              height: 1.2,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: () {},
          icon: Badge(
            label: const Text('2'),
            backgroundColor: _CColors.forest,
            child: const Icon(Icons.shopping_bag_outlined,
                size: 24, color: _CColors.forestDeep),
          ),
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  // ── Zero-emission trust pill ──────────────────────────────
  Widget _buildTrustPill() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: _CColors.lowSurface,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: _CColors.outlineSoft.withAlpha(77)),
        ),
        child: Row(
          children: [
            const Icon(Icons.eco, size: 16, color: _CColors.secondary),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                '100% Zero-Emission Artisan Delivery',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _jakarta(
                  size: 11,
                  weight: FontWeight.w600,
                  color: _CColors.forestDeep,
                ),
              ),
            ),
            Text(
              'Learn More',
              style: _jakarta(
                size: 11,
                weight: FontWeight.w700,
                color: _CColors.secondary,
              ).copyWith(decoration: TextDecoration.underline),
            ),
          ],
        ),
      ),
    );
  }

  // ── Search pill with filter button ────────────────────────
  Widget _buildSearch() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: _CColors.searchFill,
          borderRadius: BorderRadius.circular(99),
        ),
        child: Row(
          children: [
            const SizedBox(width: 16),
            const Icon(Icons.search_rounded,
                size: 20, color: _CColors.outline),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Search 2,400+ curated goods...',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _jakarta(color: _CColors.inkSoft.withAlpha(178)),
              ),
            ),
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(right: 7),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x0F173628),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.tune_rounded,
                  size: 18, color: _CColors.forestDeep),
            ),
          ],
        ),
      ),
    );
  }

  // ── Horizontal filter chips (view-only filter) ────────────
  Widget _buildFilterChips() {
    final labels = <String>[
      'All',
      ..._allCategories.map((c) => c['label'] as String),
    ];
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: SizedBox(
        height: 38,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: labels.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final active = (i - 1) == _filter;
            return Center(
              child: GestureDetector(
                onTap: () => setState(() => _filter = i - 1),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                  decoration: BoxDecoration(
                    color: active ? _CColors.forest : _CColors.sageChip,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    labels[i],
                    style: _jakarta(
                      size: 12,
                      weight: FontWeight.w600,
                      letterSpacing: 0.2,
                      color: active ? Colors.white : _CColors.forest,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ── Featured hero banner ──────────────────────────────────
  Widget _buildHero() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Container(
        height: 190,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2E4D3E), Color(0xFF173628), Color(0xFF012114)],
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1F173628),
              blurRadius: 24,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -20,
              top: -10,
              child: Icon(
                Icons.eco,
                size: 170,
                color: const Color(0xFFACCEBA).withAlpha(36),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _CColors.amber,
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.auto_awesome,
                                size: 13, color: _CColors.amberText),
                            const SizedBox(width: 4),
                            Text(
                              'NEW CURATIONS',
                              style: _jakarta(
                                size: 10,
                                weight: FontWeight.w700,
                                letterSpacing: 0.9,
                                color: _CColors.amberText,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _CColors.forestDeep.withAlpha(153),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          'Volume IV',
                          style: _jakarta(
                            size: 10,
                            weight: FontWeight.w700,
                            letterSpacing: 0.6,
                            color: const Color(0xFFC7EBD6),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Spring Botanical Edit',
                              style: _playfair(
                                size: 24,
                                color: Colors.white,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Sustainably sourced indoor flora & artisanal planters',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: _jakarta(
                                size: 12,
                                color: const Color(0xFFACCEBA),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.arrow_forward_rounded,
                            size: 20, color: _CColors.forestDeep),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Trending strip ────────────────────────────────────────
  Widget _buildTrending() {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Trending Now', style: _playfair(size: 18)),
                Text(
                  'Explore All',
                  style: _jakarta(
                    size: 11,
                    weight: FontWeight.w700,
                    color: _CColors.secondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 96,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _trending.length,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (_, i) {
                final t = _trending[i];
                return Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: _CColors.secondary.withAlpha(77)),
                      ),
                      child: Container(
                        decoration: const BoxDecoration(
                          color: _CColors.sageChip,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          t['icon'] as IconData,
                          size: 26,
                          color: _CColors.forest,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      t['label'] as String,
                      style: _jakarta(size: 11, weight: FontWeight.w600),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── Category card (tap → sub-category sheet) ──────────────
  Widget _buildCategoryCard(int i) {
    final cat = _allCategories[i];
    final color = cat['color'] as Color;
    final popular = i < 2; // Electronics + Fashion (largest catalogs)

    return GestureDetector(
      onTap: () => _openSubCategories(i),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _CColors.outlineSoft.withAlpha(77)),
          boxShadow: const [
            BoxShadow(
              color: _CColors.shadow,
              blurRadius: 16,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 4 / 5,
              child: Container(
                decoration: BoxDecoration(
                  color: color.withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Icon(
                        cat['icon'] as IconData,
                        size: 52,
                        color: color.withAlpha(210),
                      ),
                    ),
                    if (popular)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(230),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(
                            'Popular',
                            style: _jakarta(
                              size: 10,
                              weight: FontWeight.w700,
                              color: _CColors.forestDeep,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          cat['label'] as String,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: _playfair(size: 15, height: 1.2),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${cat['count']} products',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _jakarta(size: 12, color: _CColors.inkSoft),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_forward_rounded,
                      size: 18, color: _CColors.outline),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Bottom sheet listing the sub-categories. Each chip goes to
  // MockupProductListScreen(categoryName: s), same as before.
  void _openSubCategories(int i) {
    final cat = _allCategories[i];
    final color = cat['color'] as Color;
    final subs = cat['subs'] as List<String>;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: _CColors.background,
      barrierColor: const Color(0x73173628),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: _CColors.outlineSoft,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: color.withAlpha(30),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(cat['icon'] as IconData,
                          color: color, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(cat['label'] as String,
                              style: _playfair(size: 20)),
                          const SizedBox(height: 2),
                          Text(
                            '${cat['count']} products',
                            style: _jakarta(
                                size: 12, color: _CColors.inkSoft),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  'SHOP BY SUB-CATEGORY',
                  style: _jakarta(
                    size: 11,
                    weight: FontWeight.w700,
                    letterSpacing: 0.9,
                    color: _CColors.inkSoft,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: subs.map((s) {
                    return ActionChip(
                      label: Text(s),
                      labelStyle: _jakarta(
                        size: 12,
                        weight: FontWeight.w600,
                        color: _CColors.forest,
                      ),
                      backgroundColor: _CColors.sageChip,
                      side: BorderSide.none,
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 6),
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MockupProductListScreen(
                              title: s,
                            ),
                          ),
                        );
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Nuvora Standard card ──────────────────────────────────
  Widget _buildStandardCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFEEF3EF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _CColors.outlineSoft.withAlpha(77)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: _CColors.sage,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.verified_outlined,
                  size: 20, color: _CColors.forest),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'The Nuvora Standard',
                    style: _jakarta(
                      size: 14,
                      weight: FontWeight.w700,
                      color: _CColors.forestDeep,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Every artisan partner is vetted for fair labor, '
                    'plastic-free circular packaging, and pure botanical '
                    'provenance.',
                    style: _jakarta(
                      size: 12,
                      color: _CColors.inkSoft,
                      height: 1.5,
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
}


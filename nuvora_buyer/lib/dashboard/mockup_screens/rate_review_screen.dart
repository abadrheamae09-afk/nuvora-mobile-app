// ============================================================
// rate_review_screen.dart
// Rate and review a completed order: star rating per product,
// review text, and optional photo upload placeholder.
// Design: "Botanical Boutique" (Playfair Display + Plus Jakarta Sans,
// forest-green / sage / amber palette).
// Routing and logic are unchanged — only the visuals were updated.
// ============================================================

import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';
import 'my_orders_screen.dart';
import '../../core/navigation/buyer_nav_bar.dart';

// ── Design tokens (from the redesign) ───────────────────────
class _N {
  static const primary = Color(0xFF173628); // deep forest pine
  static const secondary = Color(0xFF44664B);
  static const secondaryContainer = Color(0xFFC2E9C7);
  static const onSecondaryFixed = Color(0xFF00210E);
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

  static const border = Color(0x4DC1C8C2); // outline-variant @ 30%
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

BoxDecoration _cardDecoration() => BoxDecoration(
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
    );

const List<String> _highlightTags = [
  'True to description',
  'Well-packaged',
  'Great value',
  'Fast shipping',
];

class _ReviewItem {
  _ReviewItem({required this.name, required this.color});

  final String name;
  final Color color;
  int rating = 5;
  final TextEditingController commentCtrl = TextEditingController();
  final Set<String> tags = <String>{}; // design-only highlight chips
}

class MockupRateReviewScreen extends StatefulWidget {
  const MockupRateReviewScreen({super.key});

  @override
  State<MockupRateReviewScreen> createState() =>
      _MockupRateReviewScreenState();
}

class _MockupRateReviewScreenState extends State<MockupRateReviewScreen> {
  final List<_ReviewItem> _items = [
    _ReviewItem(
        name: 'Wireless Earbuds Pro', color: const Color(0xFF2563EB)),
    _ReviewItem(
        name: 'USB-C Hub 7-in-1', color: const Color(0xFF475569)),
  ];

  int _sellerRating = 5;
  bool _loading = false;
  bool _anonymous = false; // post the review without showing the name

  @override
  void dispose() {
    for (final item in _items) {
      item.commentCtrl.dispose();
    }
    super.dispose();
  }

  void _submit() {
    setState(() => _loading = true);
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() => _loading = false);
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const MockupMyOrdersScreen(initialTab: 3),
        ),
        (route) => route.isFirst,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Thank you for your review!',
            style: _sans(
                size: 13, weight: FontWeight.w600, color: Colors.white),
          ),
          backgroundColor: _N.primary,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: const BuyerNavBar(current: BuyerTab.account),
      backgroundColor: _N.surface,
      appBar: AppBar(
        backgroundColor: _N.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: _N.primary,
        centerTitle: true,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Rate & Review', style: _serif(size: 18, height: 1.2)),
            const SizedBox(height: 2),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'COMPLETED ORDER',
                  style: _sans(
                    size: 10,
                    weight: FontWeight.w600,
                    color: _N.onSurfaceVariant,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  width: 4,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: _N.secondary,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.help_outline,
                size: 20, color: _N.onSurfaceVariant),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                // Products to review
                ..._items.asMap().entries.map(
                      (e) => _buildProductReview(e.key, e.value),
                    ),
                const SizedBox(height: 6),
                // Seller rating
                _buildSellerRating(),
                const SizedBox(height: 6),
                // Post anonymously
                _buildAnonymousToggle(),
              ],
            ),
          ),
          // Submit button
          Container(
            decoration: const BoxDecoration(
              color: Color(0xF2FCF9F8),
              border: Border(top: BorderSide(color: _N.border)),
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
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _loading ? null : _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: _N.primary,
                      disabledBackgroundColor: _N.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
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
                              Text('Submit Review',
                                  style: _sans(
                                      size: 14,
                                      weight: FontWeight.w600,
                                      color: Colors.white)),
                              const SizedBox(width: 8),
                              const Icon(Icons.send_rounded, size: 18),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Small shared pieces ─────────────────────────────────
  Widget _label(String text) {
    return Text(
      text.toUpperCase(),
      style: _sans(
        size: 10,
        weight: FontWeight.w700,
        color: _N.onSurfaceVariant,
        letterSpacing: 1,
      ),
    );
  }

  Widget _stars({
    required int value,
    required double size,
    required double spacing,
    required ValueChanged<int> onChanged,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (s) {
        return GestureDetector(
          onTap: () => onChanged(s + 1),
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: spacing / 2),
            child: Icon(
              s < value ? Icons.star_rounded : Icons.star_outline_rounded,
              size: size,
              color: _N.amber,
            ),
          ),
        );
      }),
    );
  }

  // ── Product review card ─────────────────────────────────
  Widget _buildProductReview(int index, _ReviewItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: _cardDecoration(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product row
          Container(
            padding: const EdgeInsets.only(bottom: 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: _N.surfaceContainer)),
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Color.lerp(Colors.white, item.color, 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _N.border),
                  ),
                  child: Icon(Icons.inventory_2_outlined,
                      color: item.color, size: 26),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TECHZONE PH',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _sans(
                          size: 10,
                          weight: FontWeight.w700,
                          color: _N.secondary,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: _sans(
                          size: 14,
                          weight: FontWeight.w600,
                          color: _N.primary,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Star rating
          Center(
            child: Column(
              children: [
                Text('Your Rating',
                    style: _sans(
                      size: 12,
                      weight: FontWeight.w500,
                      color: _N.onSurfaceVariant,
                    )),
                const SizedBox(height: 8),
                _stars(
                  value: item.rating,
                  size: 36,
                  spacing: 8,
                  onChanged: (v) => setState(() => item.rating = v),
                ),
                const SizedBox(height: 8),
                Text(
                  _ratingLabel(item.rating),
                  style: _sans(
                    size: 13,
                    weight: FontWeight.w700,
                    color: _N.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          // Highlight chips
          _label('Highlight Features'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _highlightTags.map((t) => _tagChip(item, t)).toList(),
          ),
          const SizedBox(height: 18),
          // Comment field
          Row(
            children: [
              Expanded(child: _label('Detailed Feedback')),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: item.commentCtrl,
                builder: (_, v, __) => Text(
                  '${v.text.length} / 500',
                  style: _sans(
                    size: 11,
                    weight: FontWeight.w500,
                    color: _N.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: item.commentCtrl,
            maxLines: 4,
            maxLength: 500,
            cursorColor: _N.primary,
            style: _sans(size: 14, color: _N.primary, height: 1.4),
            decoration: InputDecoration(
              counterText: '',
              hintText: 'Write your review...',
              hintStyle: _sans(size: 14, color: _N.outline),
              filled: true,
              fillColor: _N.surfaceLow,
              contentPadding: const EdgeInsets.all(14),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: _N.primary, width: 1.2),
              ),
            ),
          ),
          const SizedBox(height: 18),
          // Photo upload placeholder
          Row(
            children: [
              Expanded(child: _label('Photos & Video Clips')),
              Text('0 of 5 uploaded',
                  style: _sans(size: 11, color: _N.onSurfaceVariant)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              SizedBox(
                width: 96,
                height: 96,
                child: GestureDetector(
                  onTap: () {},
                  child: CustomPaint(
                    painter: _DashedBorderPainter(
                      color: _N.outlineVariant,
                      radius: 14,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0x80F6F3F2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: const BoxDecoration(
                              color: _N.card,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0x14000000),
                                  blurRadius: 4,
                                  offset: Offset(0, 1),
                                ),
                              ],
                            ),
                            child: const Icon(
                                Icons.add_photo_alternate_outlined,
                                size: 18,
                                color: _N.primary),
                          ),
                          const SizedBox(height: 6),
                          Text('Add Photos',
                              textAlign: TextAlign.center,
                              style: _sans(
                                size: 10,
                                weight: FontWeight.w600,
                                color: _N.onSurfaceVariant,
                              )),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tagChip(_ReviewItem item, String tag) {
    final selected = item.tags.contains(tag);
    return GestureDetector(
      onTap: () => setState(() {
        selected ? item.tags.remove(tag) : item.tags.add(tag);
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? _N.primary : _N.secondaryContainer,
          borderRadius: BorderRadius.circular(999),
          boxShadow: selected
              ? const [
                  BoxShadow(
                    color: Color(0x1A000000),
                    blurRadius: 3,
                    offset: Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selected ? Icons.check : Icons.add,
              size: 14,
              color: selected ? Colors.white : _N.onSecondaryFixed,
            ),
            const SizedBox(width: 6),
            Text(
              tag,
              style: _sans(
                size: 12,
                weight: FontWeight.w600,
                color: selected ? Colors.white : _N.onSecondaryFixed,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Seller rating card ──────────────────────────────────
  Widget _buildSellerRating() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
          child: _label('Seller Experience'),
        ),
        Container(
          decoration: _cardDecoration(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: const BoxDecoration(
                      color: Color(0x80C2E9C7),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.storefront_outlined,
                        size: 18, color: _N.secondary),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('TechZone PH',
                            style: _sans(
                                size: 14,
                                weight: FontWeight.w700,
                                color: _N.primary)),
                        Text('Rate the Seller',
                            style: _sans(
                                size: 12, color: _N.onSurfaceVariant)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: _N.secondaryContainer,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      _ratingLabel(_sellerRating),
                      style: _sans(
                        size: 11,
                        weight: FontWeight.w600,
                        color: _N.onSecondaryFixed,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Center(
                child: _stars(
                  value: _sellerRating,
                  size: 32,
                  spacing: 8,
                  onChanged: (v) => setState(() => _sellerRating = v),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  // ── Post anonymously toggle ─────────────────────────────
  Widget _buildAnonymousToggle() {
    return GestureDetector(
      onTap: () => setState(() => _anonymous = !_anonymous),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _anonymous ? _N.sageWash : _N.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _anonymous ? _N.primary : _N.border,
            width: _anonymous ? 1.5 : 1,
          ),
          boxShadow: const [
            BoxShadow(
              color: _N.shadow,
              blurRadius: 16,
              spreadRadius: -2,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _anonymous
                    ? _N.primary
                    : const Color(0x80C2E9C7),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _anonymous
                    ? Icons.visibility_off_outlined
                    : Icons.person_outline,
                size: 18,
                color: _anonymous ? Colors.white : _N.secondary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Post anonymously',
                      style: _sans(
                          size: 14,
                          weight: FontWeight.w700,
                          color: _N.primary)),
                  const SizedBox(height: 2),
                  Text(
                    _anonymous
                        ? 'Your name will be hidden, e.g. J***n D.'
                        : 'Your name will be shown with your review',
                    style: _sans(
                        size: 12,
                        color: _N.onSurfaceVariant,
                        height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Switch(
              value: _anonymous,
              onChanged: (v) => setState(() => _anonymous = v),
              activeColor: Colors.white,
              activeTrackColor: _N.primary,
              inactiveThumbColor: Colors.white,
              inactiveTrackColor: _N.outlineVariant,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ],
        ),
      ),
    );
  }

  String _ratingLabel(int r) {
    switch (r) {
      case 1:
        return 'Terrible';
      case 2:
        return 'Bad';
      case 3:
        return 'Okay';
      case 4:
        return 'Good';
      case 5:
        return 'Excellent!';
      default:
        return '';
    }
  }
}

/// Dashed rounded-rectangle outline for the "add photo" tile.
class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Offset.zero & size,
        Radius.circular(radius),
      ));

    for (final PathMetric metric in path.computeMetrics()) {
      double d = 0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, d + 5), paint);
        d += 9;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter old) =>
      old.color != color || old.radius != radius;
}
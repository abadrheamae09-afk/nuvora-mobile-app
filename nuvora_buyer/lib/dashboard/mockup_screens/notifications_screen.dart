// ============================================================
// notifications_screen.dart
// Buyer notifications: order updates, promos, system alerts.
// Supports mark-as-read and clear-all.
//
// Restyled with the "Botanical Boutique" design (NUVORA):
// pine/sage palette, Playfair Display headlines, Plus Jakarta Sans
// body, unread accent ribbons, inline action rows, filter chips,
// and Today / Yesterday / Earlier sections.
// Routing and screen/class names are unchanged.
// ============================================================

import 'package:flutter/material.dart';
import '../../core/navigation/buyer_nav_bar.dart';
import 'mockup_widgets.dart';

// ------------------------------------------------------------
// Design tokens (from the redesign's DESIGN.md)
// If you use the google_fonts package, swap _Fonts to
// GoogleFonts.playfairDisplay() / GoogleFonts.plusJakartaSans().
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
  static const onSurface = Color(0xFF1C1B1B);
  static const onSurfaceVariant = Color(0xFF424844);
  static const outline = Color(0xFF727973);
  static const outlineVariant = Color(0xFFC1C8C2);

  // brand
  static const primaryContainer = Color(0xFF173628);
  static const secondary = Color(0xFF44664B);
  static const secondaryContainer = Color(0xFFC2E9C7);
  static const onSecondaryContainer = Color(0xFF486A4F);
  static const tertiary = Color(0xFF281900);
  static const tertiaryFixed = Color(0xFFFFDEAD);
  static const tertiaryFixedDim = Color(0xFFFABC4D);
  static const onTertiaryContainer = Color(0xFFC68E21);
  static const shadow = Color(0x0A173628); // ~4% pine
  static const hairline = Color(0x0F173628); // ~6% pine

  static const headlineFont = 'Playfair Display';
  static const bodyFont = 'Plus Jakarta Sans';
}

TextStyle _headline(double size, {FontWeight w = FontWeight.w600}) =>
    TextStyle(
      fontFamily: _T.headlineFont,
      fontSize: size,
      fontWeight: w,
      color: _T.primaryContainer,
      letterSpacing: -0.2,
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

enum _Category { orders, promos }

enum _Section { today, yesterday, earlier }

class _Notif {
  _Notif({
    required this.id,
    required this.title,
    required this.body,
    required this.time,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.tag,
    required this.category,
    required this.section,
    this.subject,
    this.subjectNote,
    this.subjectIcon = Icons.inventory_2_outlined,
    this.actionLabel,
    this.actionOutlined = false,
    this.isRead = false,
  });

  final String id;
  final String title;
  final String body;
  final String time;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String tag; // kept for data; not shown in the new layout
  final _Category category;
  final _Section section;

  // Inline row under the message (design-only; actions are no-ops)
  final String? subject;
  final String? subjectNote;
  final IconData subjectIcon;
  final String? actionLabel;
  final bool actionOutlined;

  bool isRead;
}

class MockupNotificationsScreen extends StatefulWidget {
  const MockupNotificationsScreen({super.key});

  @override
  State<MockupNotificationsScreen> createState() =>
      _MockupNotificationsScreenState();
}

class _MockupNotificationsScreenState
    extends State<MockupNotificationsScreen> {
  // null = All
  _Category? _filter;

  final List<_Notif> _notifs = [
    _Notif(
      id: 'n1',
      title: 'Order Out for Delivery 🚴',
      body: 'Your order #20261102-015 is on its way. Expected today, 3–5 PM.',
      time: '2 mins ago',
      icon: Icons.local_shipping_outlined,
      iconColor: _T.primaryContainer,
      iconBg: _T.secondaryContainer,
      tag: 'Order in transit',
      category: _Category.orders,
      section: _Section.today,
      subject: 'Order #20261102-015',
      subjectNote: 'SportsPro PH',
      actionLabel: 'Track Shipment',
    ),
    _Notif(
      id: 'n2',
      title: 'Flash Sale — 11.11 Mega Sale!',
      body: 'Up to 80% off on electronics, fashion, and more. Ends tonight!',
      time: '1 hour ago',
      icon: Icons.local_offer_outlined,
      iconColor: _T.tertiary,
      iconBg: _T.tertiaryFixed,
      tag: 'Promotion',
      category: _Category.promos,
      section: _Section.today,
      subject: '11.11 Mega Sale',
      subjectNote: 'Ends tonight',
      subjectIcon: Icons.bolt_rounded,
      actionLabel: 'Shop Now',
    ),
    _Notif(
      id: 'n3',
      title: 'Order Confirmed ✓',
      body: 'TechZone PH confirmed your order #20261105-001.',
      time: '3 hours ago',
      icon: Icons.check_circle_outline_rounded,
      iconColor: _T.secondary,
      iconBg: _T.secondaryContainer,
      tag: 'Order update',
      category: _Category.orders,
      section: _Section.today,
      isRead: true,
      subject: 'TechZone PH',
      subjectNote: 'Order #20261105-001',
      subjectIcon: Icons.storefront_outlined,
      actionLabel: 'View Order',
    ),
    _Notif(
      id: 'n4',
      title: 'Payment Successful',
      body: 'Your GCash payment of ₱3,097 was processed successfully.',
      time: '3 hours ago',
      icon: Icons.payments_outlined,
      iconColor: _T.primary,
      iconBg: _T.containerHigh,
      tag: 'Payment',
      category: _Category.orders,
      section: _Section.today,
      isRead: true,
    ),
    _Notif(
      id: 'n5',
      title: 'New Arrival: Running Shoes X4',
      body: 'SportsPro PH just dropped the latest Running Shoes X4. Check it out!',
      time: 'Yesterday',
      icon: Icons.new_releases_outlined,
      iconColor: _T.onTertiaryContainer,
      iconBg: _T.tertiaryFixed,
      tag: 'New arrival',
      category: _Category.promos,
      section: _Section.yesterday,
      isRead: true,
      subject: 'Running Shoes X4',
      subjectNote: 'SportsPro PH',
      subjectIcon: Icons.directions_run_rounded,
      actionLabel: 'View Item',
    ),
    _Notif(
      id: 'n6',
      title: 'Rate Your Recent Order',
      body: 'How was your experience with TechZone PH? Share your review.',
      time: '2 days ago',
      icon: Icons.star_outline_rounded,
      iconColor: _T.onTertiaryContainer,
      iconBg: _T.tertiaryFixed,
      tag: 'Review',
      category: _Category.orders,
      section: _Section.earlier,
      isRead: true,
      subject: 'TechZone PH',
      subjectNote: 'Delivered on time',
      subjectIcon: Icons.verified_outlined,
      actionLabel: 'Rate & Review',
      actionOutlined: true,
    ),
  ];

  int get _unreadCount => _notifs.where((n) => !n.isRead).length;

  int _countFor(_Category? c) =>
      c == null ? _notifs.length : _notifs.where((n) => n.category == c).length;

  bool _hasUnreadIn(_Category c) =>
      _notifs.any((n) => n.category == c && !n.isRead);

  List<_Notif> get _visible => _filter == null
      ? _notifs
      : _notifs.where((n) => n.category == _filter).toList();

  void _markAllRead() {
    setState(() {
      for (final n in _notifs) {
        n.isRead = true;
      }
    });
  }

  void _clearAll() {
    setState(() => _notifs.clear());
  }

  // ----------------------------------------------------------
  // BUILD
  // ----------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final visible = _visible;

    return Scaffold(
      bottomNavigationBar: const BuyerNavBar(current: BuyerTab.notifications),
      backgroundColor: _T.surface,
      appBar: AppBar(
        backgroundColor: _T.surface,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        foregroundColor: _T.primaryContainer,
        title: Text(
          'NUVORA',
          style: _headline(20).copyWith(letterSpacing: 2.2),
        ),
        actions: [
          if (_notifs.isNotEmpty) ...[
            _buildMarkReadPill(),
            const SizedBox(width: 8),
            _buildTuneMenu(),
            const SizedBox(width: 12),
          ],
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(92),
          child: Container(
            decoration: const BoxDecoration(
              color: _T.surface,
              boxShadow: [
                BoxShadow(
                  color: _T.shadow,
                  blurRadius: 16,
                  spreadRadius: -2,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildTitleRow(),
                _buildFilterChips(),
              ],
            ),
          ),
        ),
      ),
      body: _notifs.isEmpty
          ? const MEmptyState(
              icon: Icons.notifications_none_rounded,
              title: 'No notifications',
              subtitle: 'You\'re all caught up! Check back later.',
            )
          : visible.isEmpty
              ? const MEmptyState(
                  icon: Icons.notifications_none_rounded,
                  title: 'Nothing here',
                  subtitle: 'No notifications in this category yet.',
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  children: [
                    ..._buildSections(visible),
                    const SizedBox(height: 20),
                    _buildArchiveHint(),
                  ],
                ),
    );
  }

  // ----------------------------------------------------------
  // APP BAR PIECES
  // ----------------------------------------------------------
  Widget _buildTitleRow() {
    return SizedBox(
      height: 44,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
        child: Row(
          children: [
            Text('Notifications', style: _headline(24)),
            const SizedBox(width: 10),
            if (_unreadCount > 0)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _T.secondaryContainer,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$_unreadCount Unread',
                  style: _body(11,
                      w: FontWeight.w700,
                      color: _T.onSecondaryContainer,
                      letterSpacing: 0.2),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMarkReadPill() {
    final allRead = _unreadCount == 0;
    return Material(
      color: _T.containerLow,
      shape: const StadiumBorder(),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: allRead ? null : _markAllRead,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(allRead ? Icons.check_rounded : Icons.done_all_rounded,
                  size: 16, color: allRead ? _T.outline : _T.primaryContainer),
              const SizedBox(width: 4),
              Text(
                allRead ? 'All read' : 'Mark all read',
                style: _body(11,
                    w: FontWeight.w600,
                    color: allRead ? _T.outline : _T.primaryContainer,
                    letterSpacing: 0.2),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // The "tune" button opens the existing menu (Clear all).
  Widget _buildTuneMenu() {
    return PopupMenuButton<String>(
      padding: EdgeInsets.zero,
      color: _T.card,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (v) {
        if (v == 'clear') _clearAll();
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'clear',
          child: Row(
            children: [
              const Icon(Icons.delete_sweep_outlined,
                  size: 18, color: _T.primaryContainer),
              const SizedBox(width: 10),
              Text('Clear all',
                  style: _body(14,
                      w: FontWeight.w600, color: _T.primaryContainer)),
            ],
          ),
        ),
      ],
      child: Container(
        width: 32,
        height: 32,
        decoration: const BoxDecoration(
          color: _T.containerLow,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.tune_rounded,
            size: 19, color: _T.onSurfaceVariant),
      ),
    );
  }

  Widget _buildFilterChips() {
    Widget chip(String label, _Category? value) {
      final selected = _filter == value;
      final showCount = value == null;
      final showDot = value != null && _hasUnreadIn(value);

      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: GestureDetector(
          onTap: () => setState(() => _filter = value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? _T.primaryContainer : _T.containerLow,
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
                Text(
                  label,
                  style: _body(
                    12,
                    w: FontWeight.w600,
                    letterSpacing: 0.2,
                    color: selected ? Colors.white : _T.onSurfaceVariant,
                  ),
                ),
                if (showCount) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: selected
                          ? const Color(0x33FFFFFF)
                          : _T.container,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${_countFor(value)}',
                      style: _body(10,
                          w: FontWeight.w700,
                          color:
                              selected ? Colors.white : _T.onSurfaceVariant),
                    ),
                  ),
                ],
                if (showDot) ...[
                  const SizedBox(width: 6),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: selected ? Colors.white : _T.secondary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 0, 8, 12),
        children: [
          chip('All', null),
          chip('Orders & Delivery', _Category.orders),
          chip('Promos & Rewards', _Category.promos),
        ],
      ),
    );
  }

  // ----------------------------------------------------------
  // SECTIONS
  // ----------------------------------------------------------
  List<Widget> _buildSections(List<_Notif> items) {
    const titles = {
      _Section.today: 'Today',
      _Section.yesterday: 'Yesterday',
      _Section.earlier: 'Earlier this week',
    };

    final widgets = <Widget>[];
    for (final section in _Section.values) {
      final group = items.where((n) => n.section == section).toList();
      if (group.isEmpty) continue;

      final unread = group.where((n) => !n.isRead).length;

      widgets.add(Padding(
        padding: EdgeInsets.only(
            top: widgets.isEmpty ? 0 : 22, bottom: 12, left: 2, right: 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              titles[section]!.toUpperCase(),
              style: _body(11,
                  w: FontWeight.w700,
                  color: _T.outline,
                  letterSpacing: 1.2),
            ),
            Text(
              unread > 0
                  ? '$unread new'
                  : '${group.length} ${group.length == 1 ? 'update' : 'updates'}',
              style: _body(11,
                  w: FontWeight.w600,
                  color: unread > 0 ? _T.secondary : _T.outline),
            ),
          ],
        ),
      ));

      for (var i = 0; i < group.length; i++) {
        widgets.add(_buildTile(group[i]));
        if (i != group.length - 1) widgets.add(const SizedBox(height: 12));
      }
    }
    return widgets;
  }

  // ----------------------------------------------------------
  // TILE
  // ----------------------------------------------------------
  Widget _buildTile(_Notif n) {
    return Dismissible(
      key: ValueKey('notif_${n.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFFFDAD6),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline_rounded,
            color: Color(0xFFBA1A1A)),
      ),
      onDismissed: (_) => setState(() => _notifs.remove(n)),
      child: GestureDetector(
        onTap: () => setState(() => n.isRead = true),
        child: Container(
          width: double.infinity,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: _T.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _T.hairline),
            boxShadow: const [
              BoxShadow(
                color: _T.shadow,
                blurRadius: 16,
                spreadRadius: -2,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Unread accent ribbon (left edge)
              if (!n.isRead)
                const Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: 4,
                  child: ColoredBox(color: _T.primaryContainer),
                ),
              Padding(
                padding: EdgeInsets.fromLTRB(n.isRead ? 14 : 18, 14, 14, 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon badge
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: n.iconBg,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(n.icon, color: n.iconColor, size: 20),
                    ),
                    const SizedBox(width: 12),
                    // Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        n.title,
                                        style: _body(
                                          14,
                                          w: n.isRead
                                              ? FontWeight.w600
                                              : FontWeight.w700,
                                          color: n.isRead
                                              ? _T.onSurface
                                              : _T.primaryContainer,
                                          height: 1.35,
                                        ),
                                      ),
                                    ),
                                    if (!n.isRead) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          color: _T.secondary,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  n.time,
                                  style: _body(11,
                                      w: FontWeight.w500,
                                      color: _T.outline),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            n.body,
                            style: _body(12, height: 1.55),
                          ),
                          if (n.actionLabel != null) ...[
                            const SizedBox(height: 10),
                            _buildActionRow(n),
                          ],
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

  // Inline subject + action pill row (design-only; actions are no-ops)
  Widget _buildActionRow(_Notif n) {
    final filled = !n.isRead && !n.actionOutlined;

    Widget pill;
    if (n.actionOutlined) {
      pill = Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: _T.primaryContainer),
        ),
        child: Text(n.actionLabel!,
            style: _body(11,
                w: FontWeight.w600, color: _T.primaryContainer)),
      );
    } else {
      pill = Container(
        padding: EdgeInsets.fromLTRB(12, 6, filled ? 8 : 12, 6),
        decoration: BoxDecoration(
          color: filled ? _T.primaryContainer : _T.container,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              n.actionLabel!,
              style: _body(
                11,
                w: FontWeight.w600,
                color: filled ? Colors.white : _T.primaryContainer,
              ),
            ),
            if (filled) ...[
              const SizedBox(width: 2),
              const Icon(Icons.chevron_right_rounded,
                  size: 14, color: Colors.white),
            ],
          ],
        ),
      );
    }

    return Row(
      children: [
        if (n.subject != null)
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _T.containerLow,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0x4DC1C8C2)),
                  ),
                  child: Icon(n.subjectIcon,
                      size: 18, color: _T.secondary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        n.subject!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _body(11,
                            w: FontWeight.w600, color: _T.onSurface),
                      ),
                      if (n.subjectNote != null)
                        Text(
                          n.subjectNote!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _body(10, color: _T.outline),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),
          )
        else
          const Spacer(),
        pill,
      ],
    );
  }

  // ----------------------------------------------------------
  // FOOTER HINT
  // ----------------------------------------------------------
  Widget _buildArchiveHint() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: _T.containerLow,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.info_outline_rounded,
                size: 15, color: _T.outline),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                'Notifications older than 30 days are automatically archived.',
                style: _body(11, color: _T.outline, height: 1.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

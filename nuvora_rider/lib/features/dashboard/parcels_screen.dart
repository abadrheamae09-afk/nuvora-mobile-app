import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/data/rider_work.dart';
import 'delivery_detail_screen.dart';

const double _radius = 16;

/// Colours taken from the redesign (stitch_mobile_app_redesign).
class _Palette {
  static const forest = Color(0xFF143224);
  static const forestEnd = Color(0xFF0B2619);
  static const forestDeep = Color(0xFF001D10);
  static const secondary = Color(0xFF006C49);
  static const mint = Color(0xFF6FFBBE);
  static const mintInk = Color(0xFF005236);
  static const mintStrong = Color(0xFFA7F3D0);
  static const background = Color(0xFFF3FCF5);
  static const surfaceLow = Color(0xFFEDF6EF);
  static const surface = Color(0xFFE7F0E9);
  static const border = Color(0xFFDCE5DE);
  static const ink = Color(0xFF151D19);
  static const inkVariant = Color(0xFF424844);
  static const outline = Color(0xFF727973);
  static const onForestMuted = Color(0xFF9DB9A9);
  static const blue = Color(0xFF2563EB);
  static const blueSoft = Color(0xFFE3EDFF);
  static const warnBg = Color(0xFFFFF6E0);
  static const warnInk = Color(0xFF8A5A00);
  static const error = Color(0xFFBA1A1A);
  static const errorContainer = Color(0xFFFFDAD6);
}

/// Filter chips offered above the parcel list.
const _filters = ['All', 'Pickup', 'On the way', 'Delivery', 'Failed'];

/// How the parcel list is ordered. `newest` keeps the order from the hub.
enum _SortMode { newest, tracking, seller }

/// What the sort & filter sheet hands back.
class _ParcelOptions {
  const _ParcelOptions({required this.sort, required this.codOnly});

  final _SortMode sort;
  final bool codOnly;
}

/// The rider's assigned parcels, grouped by the stage each parcel is in.
class ParcelsScreen extends StatefulWidget {
  const ParcelsScreen({super.key});

  @override
  State<ParcelsScreen> createState() => _ParcelsScreenState();
}

class _ParcelsScreenState extends State<ParcelsScreen> {
  final _store = RiderWorkStore.instance;
  String _activeFilter = 'All';

  // Search and sort/filter options (applied before the status pills).
  final _searchCtrl = TextEditingController();
  String _query = '';
  _SortMode _sort = _SortMode.newest;
  bool _codOnly = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // The list is read from the Station Hub API, so ask for it when the tab is
    // first built instead of showing anything local.
    _store.refreshParcels();
  }

  // ---------------------------------------------------------------------------
  // Logic & routing: unchanged from the original screen.
  // ---------------------------------------------------------------------------

  bool _matches(RiderParcel parcel, String filter) => switch (filter) {
    'Pickup' => parcel.stage == RiderStage.readyForPickup,
    'On the way' =>
      parcel.stage == RiderStage.onTheWayToHub ||
          parcel.stage == RiderStage.onTheWayToBuyer,
    'Delivery' => parcel.stage == RiderStage.forDelivery,
    'Failed' => parcel.stage == RiderStage.deliveryFailed,
    _ => true,
  };

  int _count(List<RiderParcel> parcels, String filter) =>
      parcels.where((parcel) => _matches(parcel, filter)).length;

  bool get _hasSearchOrOptions => _query.trim().isNotEmpty || _codOnly;

  bool get _hasCustomOptions => _sort != _SortMode.newest || _codOnly;

  /// Search text + cash-on-delivery switch + sort order.
  List<RiderParcel> _applyOptions(List<RiderParcel> parcels) {
    final query = _query.trim().toLowerCase();

    final result = parcels.where((parcel) {
      if (_codOnly && !parcel.isCod) return false;
      if (query.isEmpty) return true;
      final fields = <Object?>[
        parcel.tracking,
        parcel.labelCode,
        parcel.seller,
        parcel.buyer,
        parcel.address,
        parcel.sellerAddress,
        parcel.items,
      ];
      return fields.any(
        (field) => '${field ?? ''}'.toLowerCase().contains(query),
      );
    }).toList();

    switch (_sort) {
      case _SortMode.newest:
        break;
      case _SortMode.tracking:
        result.sort((a, b) => '${a.tracking}'.compareTo('${b.tracking}'));
      case _SortMode.seller:
        result.sort(
          (a, b) => '${a.seller}'.toLowerCase().compareTo(
            '${b.seller}'.toLowerCase(),
          ),
        );
    }
    return result;
  }

  void _clearSearchAndOptions() {
    _searchCtrl.clear();
    setState(() {
      _query = '';
      _codOnly = false;
    });
  }

  Future<void> _openOptions() async {
    HapticFeedback.selectionClick();
    FocusManager.instance.primaryFocus?.unfocus();
    final result = await showModalBottomSheet<_ParcelOptions>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          _OptionsSheet(initial: _ParcelOptions(sort: _sort, codOnly: _codOnly)),
    );
    if (result == null || !mounted) return;
    setState(() {
      _sort = result.sort;
      _codOnly = result.codOnly;
    });
  }

  Future<void> _openDetails(RiderParcel parcel) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DeliveryDetailScreen(parcel: parcel)),
    );
    if (mounted) setState(() {});
  }

  // ---------------------------------------------------------------------------
  // Design
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _Palette.background,
        body: ListenableBuilder(
          listenable: _store,
          builder: (context, _) {
            final parcels = _store.parcels;
            // Search / COD / sort first, then the status pills on top.
            final base = _applyOptions(parcels);
            final filters = _filters
                .where(
                  (filter) => filter == 'All' || _count(parcels, filter) > 0,
                )
                .toList();
            final active = filters.contains(_activeFilter)
                ? _activeFilter
                : 'All';
            final visible = base
                .where((parcel) => _matches(parcel, active))
                .toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(parcels),
                const SizedBox(height: 16),
                _buildSearchBar(),
                const SizedBox(height: 12),
                if (filters.length > 1) _buildFilters(filters, base, active),
                const SizedBox(height: 12),
                Expanded(child: _buildList(visible)),
              ],
            );
          },
        ),
      ),
    );
  }

  // ── Deep forest header: title + summary ───────────────────────────────────
  Widget _buildHeader(List<RiderParcel> parcels) {
    final topInset = MediaQuery.of(context).padding.top;

    const radius = BorderRadius.only(
      bottomLeft: Radius.circular(36),
      bottomRight: Radius.circular(36),
    );

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        borderRadius: radius,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_Palette.forest, _Palette.forestEnd],
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x2E001D10),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Concentric rings for optical depth.
          const Positioned(
            right: -64,
            top: -64,
            child: _Ring(size: 224, alpha: 13),
          ),
          const Positioned(
            right: -24,
            top: -24,
            child: _Ring(size: 144, alpha: 26),
          ),
          const Positioned(
            left: 90,
            bottom: -110,
            child: _Glow(size: 250, color: Color(0x146FFBBE)),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(20, topInset + 20, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'My Deliveries',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${parcels.length} ${parcels.length == 1 ? 'parcel' : 'parcels'} in your list',
                  style: const TextStyle(
                    color: _Palette.onForestMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(26),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.white.withAlpha(26)),
                  ),
                  child: Row(
                    children: [
                      _SummaryItem(
                        value: '${_count(parcels, 'Pickup')}',
                        label: 'Pickup',
                        accent: true,
                      ),
                      const _SummaryDivider(),
                      _SummaryItem(
                        value: '${_count(parcels, 'On the way')}',
                        label: 'On the way',
                      ),
                      const _SummaryDivider(),
                      _SummaryItem(
                        value: '${_count(parcels, 'Delivery')}',
                        label: 'Delivery',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Search field + sort/filter button ─────────────────────────────────────
  Widget _buildSearchBar() {
    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(26),
          borderSide: BorderSide(color: color, width: width),
        );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 48,
              child: TextField(
                controller: _searchCtrl,
                textInputAction: TextInputAction.search,
                onChanged: (value) => setState(() => _query = value),
                style: const TextStyle(
                  color: _Palette.ink,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: 'Search order ID, seller or destination…',
                  hintStyle: const TextStyle(
                    color: _Palette.outline,
                    fontSize: 13,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    size: 20,
                    color: _Palette.outline,
                  ),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear search',
                          icon: const Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: _Palette.outline,
                          ),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _query = '');
                          },
                        ),
                  filled: true,
                  fillColor: Colors.white,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  border: border(_Palette.border),
                  enabledBorder: border(_Palette.border),
                  focusedBorder: border(_Palette.secondary, 1.5),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Semantics(
            button: true,
            label: 'Sort and filter',
            child: Tooltip(
              message: 'Sort and filter',
              child: Material(
                color: _hasCustomOptions ? _Palette.secondary : Colors.white,
                shape: CircleBorder(
                  side: BorderSide(
                    color: _hasCustomOptions
                        ? _Palette.secondary
                        : _Palette.border,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: _openOptions,
                  child: SizedBox(
                    width: 48,
                    height: 48,
                    child: Icon(
                      Icons.tune_rounded,
                      size: 20,
                      color: _hasCustomOptions ? Colors.white : _Palette.ink,
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

  Widget _buildFilters(
    List<String> filters,
    List<RiderParcel> parcels,
    String active,
  ) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, index) {
          final filter = filters[index];
          final isActive = filter == active;

          return GestureDetector(
            onTap: () {
              if (filter == active) return;
              HapticFeedback.selectionClick();
              setState(() => _activeFilter = filter);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isActive ? _Palette.secondary : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isActive ? _Palette.secondary : _Palette.border,
                ),
                boxShadow: isActive
                    ? const [
                        BoxShadow(
                          color: Color(0x33006C49),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    filter,
                    style: TextStyle(
                      color: isActive ? Colors.white : _Palette.ink,
                      fontSize: 13,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: isActive
                          ? Colors.white.withAlpha(51)
                          : _Palette.surface,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${_count(parcels, filter)}',
                      style: TextStyle(
                        color: isActive
                            ? Colors.white
                            : _Palette.inkVariant,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildList(List<RiderParcel> items) {
    return RefreshIndicator(
      color: _Palette.secondary,
      onRefresh: _store.refreshParcels,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.fromLTRB(
          16,
          4,
          16,
          110 + MediaQuery.of(context).padding.bottom,
        ),
        itemCount: items.isEmpty ? 1 : items.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (_, index) {
          if (items.isEmpty) return _buildEmptyState();
          final parcel = items[index];
          return _ParcelCard(parcel: parcel, onTap: () => _openDetails(parcel));
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    if (_store.isLoading && !_store.hasLoaded) {
      return Container(
        padding: const EdgeInsets.all(32),
        child: const Center(
          child: CircularProgressIndicator(color: _Palette.secondary),
        ),
      );
    }

    final hasError = _store.error != null;
    final noMatches = !hasError && _hasSearchOrOptions;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_radius),
        border: Border.all(color: _Palette.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A143224),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: hasError ? _Palette.warnBg : _Palette.surfaceLow,
            child: Icon(
              hasError
                  ? Icons.cloud_off_rounded
                  : (noMatches
                        ? Icons.search_off_rounded
                        : Icons.inventory_2_outlined),
              color: hasError ? _Palette.warnInk : _Palette.secondary,
              size: 28,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            hasError
                ? 'Station Hub unavailable'
                : (noMatches ? 'No matching parcels' : 'No parcels here'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _Palette.ink,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _store.error ??
                (noMatches
                    ? 'Try a different search or clear your filters.'
                    : 'No assignments in this group yet. Pull down to refresh.'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _Palette.outline,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          if (noMatches) ...[
            const SizedBox(height: 12),
            TextButton(
              onPressed: _clearSearchAndOptions,
              style: TextButton.styleFrom(
                foregroundColor: _Palette.secondary,
                textStyle: const TextStyle(fontWeight: FontWeight.w700),
              ),
              child: const Text('Clear search and filters'),
            ),
          ],
          if (hasError) ...[
            const SizedBox(height: 12),
            TextButton(
              onPressed: _store.isLoading ? null : _store.refresh,
              style: TextButton.styleFrom(
                foregroundColor: _Palette.secondary,
                textStyle: const TextStyle(fontWeight: FontWeight.w700),
              ),
              child: const Text('Retry'),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// One assigned parcel card
// ─────────────────────────────────────────────────────────────────────────────
class _ParcelCard extends StatelessWidget {
  const _ParcelCard({required this.parcel, required this.onTap});

  final RiderParcel parcel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final style = _StageStyle.of(parcel.stage);
    final onTheWay =
        parcel.stage == RiderStage.onTheWayToHub ||
        parcel.stage == RiderStage.onTheWayToBuyer;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_radius),
        border: Border.all(
          color: onTheWay ? _Palette.secondary.withAlpha(90) : _Palette.border,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A143224),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(_radius),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: style.bg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(style.icon, color: style.fg, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            parcel.tracking,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _Palette.outline,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            riderStageTitle(parcel),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: onTheWay
                                  ? _Palette.secondary
                                  : _Palette.ink,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: style.bg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: style.fg.withAlpha(40)),
                      ),
                      child: Text(
                        riderStageBadge(parcel.stage),
                        style: TextStyle(
                          color: style.fg,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1, thickness: 1, color: _Palette.surface),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      onTheWay
                          ? Icons.local_shipping_outlined
                          : Icons.location_on_outlined,
                      size: 20,
                      color: _Palette.secondary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        riderStageSubtitle(parcel),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _Palette.ink,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1, thickness: 1, color: _Palette.surface),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        riderAssignmentLabel(parcel),
                        style: const TextStyle(
                          color: _Palette.inkVariant,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Text(
                      'View details',
                      style: TextStyle(
                        color: _Palette.secondary,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: _Palette.secondary,
                      size: 20,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StageStyle {
  const _StageStyle(this.fg, this.bg, this.icon);

  final Color fg, bg;
  final IconData icon;

  static _StageStyle of(RiderStage stage) => switch (stage) {
    RiderStage.readyForPickup => const _StageStyle(
      _Palette.warnInk,
      _Palette.warnBg,
      Icons.shopping_bag_outlined,
    ),
    RiderStage.onTheWayToHub => const _StageStyle(
      _Palette.mintInk,
      _Palette.surfaceLow,
      Icons.local_shipping_rounded,
    ),
    RiderStage.forDelivery => const _StageStyle(
      _Palette.blue,
      _Palette.blueSoft,
      Icons.inventory_2_outlined,
    ),
    RiderStage.onTheWayToBuyer => const _StageStyle(
      _Palette.mintInk,
      _Palette.surfaceLow,
      Icons.near_me_rounded,
    ),
    RiderStage.linehaul => const _StageStyle(
      _Palette.forestDeep,
      _Palette.mintStrong,
      Icons.local_shipping_outlined,
    ),
    RiderStage.deliveryFailed => const _StageStyle(
      _Palette.error,
      _Palette.errorContainer,
      Icons.timer_off_outlined,
    ),
    RiderStage.delivered => const _StageStyle(
      _Palette.mintInk,
      _Palette.surfaceLow,
      Icons.check_circle_outline,
    ),
  };
}

/// Bottom sheet behind the tune button: sort order + cash-on-delivery filter.
class _OptionsSheet extends StatefulWidget {
  const _OptionsSheet({required this.initial});

  final _ParcelOptions initial;

  @override
  State<_OptionsSheet> createState() => _OptionsSheetState();
}

class _OptionsSheetState extends State<_OptionsSheet> {
  late _SortMode _sort = widget.initial.sort;
  late bool _codOnly = widget.initial.codOnly;

  static const _sortLabels = {
    _SortMode.newest: 'Hub order (default)',
    _SortMode.tracking: 'Tracking number',
    _SortMode.seller: 'Seller name (A–Z)',
  };

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: _Palette.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Sort & filter',
                    style: TextStyle(
                      color: _Palette.forestDeep,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() {
                    _sort = _SortMode.newest;
                    _codOnly = false;
                  }),
                  style: TextButton.styleFrom(
                    foregroundColor: _Palette.secondary,
                    textStyle: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  child: const Text('Reset'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'SORT BY',
              style: TextStyle(
                color: _Palette.outline,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 4),
            for (final mode in _SortMode.values)
              _OptionRow(
                label: _sortLabels[mode]!,
                selected: _sort == mode,
                icon: _sort == mode
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_unchecked_rounded,
                onTap: () => setState(() => _sort = mode),
              ),
            const SizedBox(height: 8),
            const Divider(height: 1, color: _Palette.surface),
            const SizedBox(height: 8),
            const Text(
              'SHOW ONLY',
              style: TextStyle(
                color: _Palette.outline,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 4),
            _OptionRow(
              label: 'Cash on delivery parcels',
              selected: _codOnly,
              icon: _codOnly
                  ? Icons.check_box_rounded
                  : Icons.check_box_outline_blank_rounded,
              onTap: () => setState(() => _codOnly = !_codOnly),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                onPressed: () => Navigator.pop(
                  context,
                  _ParcelOptions(sort: _sort, codOnly: _codOnly),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: _Palette.secondary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: const Text('Apply'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionRow extends StatelessWidget {
  const _OptionRow({
    required this.label,
    required this.selected,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(
              icon,
              size: 22,
              color: selected ? _Palette.secondary : _Palette.outline,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: _Palette.ink,
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Ring extends StatelessWidget {
  const _Ring({required this.size, required this.alpha});

  final double size;
  final int alpha;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withAlpha(alpha)),
        ),
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, color.withAlpha(0)]),
        ),
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({
    required this.value,
    required this.label,
    this.accent = false,
  });

  final String value, label;

  /// Highlights the value in mint (used for the first column).
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: accent ? _Palette.mint : Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _Palette.onForestMuted,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryDivider extends StatelessWidget {
  const _SummaryDivider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 34, color: const Color(0x26FFFFFF));
  }
}
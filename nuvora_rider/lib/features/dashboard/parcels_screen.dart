import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/data/rider_work.dart';
import '../../theme/app_colors.dart';
import 'delivery_detail_screen.dart';

const double _radius = 16;

/// Filter chips offered above the parcel list.
const _filters = ['All', 'Pickup', 'On the way', 'Delivery', 'Failed'];

/// The rider's assigned parcels, grouped by the stage each parcel is in.
class ParcelsScreen extends StatefulWidget {
  const ParcelsScreen({super.key});

  @override
  State<ParcelsScreen> createState() => _ParcelsScreenState();
}

class _ParcelsScreenState extends State<ParcelsScreen> {
  final _store = RiderWorkStore.instance;
  String _activeFilter = 'All';

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

  Future<void> _openDetails(RiderParcel parcel) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DeliveryDetailScreen(parcel: parcel)),
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: ListenableBuilder(
          listenable: _store,
          builder: (context, _) {
            final parcels = _store.parcels;
            final filters = _filters
                .where(
                  (filter) => filter == 'All' || _count(parcels, filter) > 0,
                )
                .toList();
            final active = filters.contains(_activeFilter)
                ? _activeFilter
                : 'All';
            final visible = parcels
                .where((parcel) => _matches(parcel, active))
                .toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(parcels),
                const SizedBox(height: 16),
                if (filters.length > 1) _buildFilters(filters, parcels, active),
                const SizedBox(height: 12),
                Expanded(child: _buildList(visible)),
              ],
            );
          },
        ),
      ),
    );
  }

  // ── Green header: title + summary ─────────────────────────────────────────
  Widget _buildHeader(List<RiderParcel> parcels) {
    final topInset = MediaQuery.of(context).padding.top;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, topInset + 16, 12, 22),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.headerBottom, AppColors.headerTop],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'My Deliveries',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${parcels.length} ${parcels.length == 1 ? 'parcel' : 'parcels'} in your list',
            style: const TextStyle(color: Color(0xB3FFFFFF), fontSize: 13),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.glass,
              borderRadius: BorderRadius.circular(_radius),
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: Row(
              children: [
                _SummaryItem(
                  value: '${_count(parcels, 'Pickup')}',
                  label: 'Pickup',
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
        padding: const EdgeInsets.symmetric(horizontal: 20),
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
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isActive ? AppColors.primaryDark : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isActive ? AppColors.primaryDark : AppColors.border,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    filter,
                    style: TextStyle(
                      color: isActive ? Colors.white : AppColors.ink,
                      fontSize: 13,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${_count(parcels, filter)}',
                    style: TextStyle(
                      color: isActive ? AppColors.gold : AppColors.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
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
      color: AppColors.primary,
      onRefresh: () async => setState(() {}),
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          20,
          4,
          20,
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
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_radius),
        border: Border.all(color: AppColors.border),
      ),
      child: const Column(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.mint,
            child: Icon(
              Icons.inventory_2_outlined,
              color: AppColors.primaryDark,
              size: 28,
            ),
          ),
          SizedBox(height: 14),
          Text(
            'No parcels here',
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'No assignments in this group yet. Pull down to refresh.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.muted, fontSize: 13, height: 1.4),
          ),
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
          color: onTheWay ? AppColors.primary.withAlpha(90) : AppColors.border,
        ),
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
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: style.bg,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(style.icon, color: style.fg, size: 22),
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
                              color: AppColors.muted,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            riderStageTitle(parcel),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: onTheWay
                                  ? AppColors.primaryDark
                                  : AppColors.ink,
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
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      onTheWay
                          ? Icons.local_shipping_outlined
                          : Icons.location_on_outlined,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        riderStageSubtitle(parcel),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.ink,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1, thickness: 1, color: AppColors.border),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        riderAssignmentLabel(parcel),
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Text(
                      'View details',
                      style: TextStyle(
                        color: AppColors.primaryDark,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.primaryDark,
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
      AppColors.goldInk,
      AppColors.goldSoft,
      Icons.shopping_bag_outlined,
    ),
    RiderStage.onTheWayToHub => const _StageStyle(
      AppColors.primaryDark,
      AppColors.mint,
      Icons.local_shipping_rounded,
    ),
    RiderStage.forDelivery => const _StageStyle(
      AppColors.blue,
      AppColors.blueSoft,
      Icons.inventory_2_outlined,
    ),
    RiderStage.onTheWayToBuyer => const _StageStyle(
      AppColors.primaryDark,
      AppColors.mint,
      Icons.near_me_rounded,
    ),
    RiderStage.linehaul => const _StageStyle(
      AppColors.primaryDeep,
      AppColors.mintStrong,
      Icons.local_shipping_outlined,
    ),
    RiderStage.deliveryFailed => const _StageStyle(
      AppColors.danger,
      AppColors.dangerSoft,
      Icons.timer_off_outlined,
    ),
    RiderStage.delivered => const _StageStyle(
      AppColors.primaryDark,
      AppColors.mint,
      Icons.check_circle_outline,
    ),
  };
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({required this.value, required this.label});

  final String value, label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.gold,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Color(0xB3FFFFFF), fontSize: 12),
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
    return Container(width: 1, height: 32, color: const Color(0x26FFFFFF));
  }
}

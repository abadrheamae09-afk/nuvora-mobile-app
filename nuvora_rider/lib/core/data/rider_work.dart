import 'package:flutter/foundation.dart';

import '../api/rider_api.dart';

/// Rider-facing stage of one assigned parcel.
///
/// The server sends this stage for every parcel, so the screens never guess a
/// stage from the clock.
enum RiderStage {
  readyForPickup,
  onTheWayToHub,
  forDelivery,
  onTheWayToBuyer,
  linehaul,
  deliveryFailed,
  delivered,
}

/// One parcel assigned to the rider.
class RiderParcel {
  RiderParcel({
    required this.id,
    required this.tracking,
    this.labelCode = '',
    required this.assignment,
    required this.seller,
    required this.sellerAddress,
    required this.buyer,
    required this.address,
    required this.items,
    required this.fee,
    required this.etaLabel,
    required this.stage,
    this.contact = '',
    this.notes = '',
    this.cashToCollect,
    this.cutoffLabel = '5:00 PM',
    this.deliveredAt,
  });

  final int id;
  final String tracking;

  /// The number printed inside the label's QR code and barcode. It can differ
  /// from [tracking] when the waybill was printed after the parcel row was
  /// opened, so the scanner accepts either.
  final String labelCode;

  /// `pickup`, `delivery` or `linehaul`.
  final String assignment;

  final String seller;
  final String sellerAddress;
  final String buyer;
  final String address;
  final String items;
  final double fee;
  final String etaLabel;
  final String contact;
  final String notes;
  final double? cashToCollect;
  final String cutoffLabel;

  RiderStage stage;
  DateTime? deliveredAt;

  bool get isCod => cashToCollect != null;

  String get addressLine => address;
}

/// One line in the rider's notification feed.
class RiderNotice {
  RiderNotice({
    required this.id,
    required this.title,
    required this.message,
    required this.timeAgo,
    this.read = false,
  });

  final int id;
  final String title;
  final String message;
  final String timeAgo;
  bool read;
}

/// A completed parcel that was credited to the rider.
class RiderEarning {
  const RiderEarning({
    required this.order,
    required this.hub,
    required this.amount,
    required this.date,
  });

  final String order;
  final String hub;
  final double amount;
  final String date;
}

/// COD cash the rider collected and has not handed over yet.
class CodCollection {
  const CodCollection({
    required this.order,
    required this.amount,
    required this.date,
    required this.status,
  });

  final String order;
  final double amount;
  final String date;
  final String status;
}

/// Everything the rider screens show, loaded from the rider's Station Hub.
///
/// Parcels, scans, delivery proofs, earnings and notifications all go through
/// [RiderApi]; the store only keeps the last server answer so every tab reads
/// the same thing without another round trip.
class RiderWorkStore extends ChangeNotifier {
  RiderWorkStore._();

  static final RiderWorkStore instance = RiderWorkStore._();

  final List<RiderParcel> _parcels = [];
  final List<RiderNotice> _notices = [];
  final List<RiderEarning> _earnings = [];
  final List<CodCollection> _collections = [];

  bool _loadingParcels = false;
  bool _loadedParcels = false;
  String? _parcelError;

  bool _loadingEarnings = false;
  bool _loadedEarnings = false;
  String? _earningsError;

  double _accruedTotal = 0;
  double _cashOnHand = 0;

  List<RiderParcel> get parcels => List.unmodifiable(_parcels);
  List<RiderNotice> get notices => List.unmodifiable(_notices);
  List<RiderEarning> get earnings => List.unmodifiable(_earnings);
  List<CodCollection> get collections => List.unmodifiable(_collections);

  /// True while the parcel list is being fetched.
  bool get isLoading => _loadingParcels;

  /// True once the parcel list has been fetched at least once.
  bool get hasLoaded => _loadedParcels;

  /// Why the last parcel fetch failed, or null when it worked.
  String? get error => _parcelError;

  /// True while the earnings are being fetched.
  bool get isEarningsLoading => _loadingEarnings;

  /// True once the earnings have been fetched at least once.
  bool get hasLoadedEarnings => _loadedEarnings;

  /// Why the last earnings fetch failed, or null when it worked.
  String? get earningsError => _earningsError;

  int get unreadCount => _notices.where((notice) => !notice.read).length;

  double get accruedTotal => _accruedTotal;

  double get cashOnHand => _cashOnHand;

  int get pickupCount => _parcels
      .where((parcel) => parcel.stage == RiderStage.readyForPickup)
      .length;

  int get onTheWayCount => _parcels
      .where(
        (parcel) =>
            parcel.stage == RiderStage.onTheWayToHub ||
            parcel.stage == RiderStage.onTheWayToBuyer,
      )
      .length;

  int get deliveryCount =>
      _parcels.where((parcel) => parcel.stage == RiderStage.forDelivery).length;

  int get linehaulCount =>
      _parcels.where((parcel) => parcel.stage == RiderStage.linehaul).length;

  int get failedCount => _parcels
      .where((parcel) => parcel.stage == RiderStage.deliveryFailed)
      .length;

  RiderParcel? find(String tracking) {
    for (final parcel in _parcels) {
      if (parcel.tracking == tracking) return parcel;
    }
    return null;
  }

  /// Reloads everything the dashboard shows.
  Future<void> refresh() async {
    await Future.wait([refreshParcels(), refreshEarnings()]);
    await refreshNotifications();
  }

  /// The Parcels tab's own fetch: assigned pickups, deliveries and transfers.
  Future<void> refreshParcels() async {
    if (_loadingParcels) return;

    _loadingParcels = true;
    _parcelError = null;
    notifyListeners();

    try {
      final data = await RiderApi.instance.parcels();
      _applyAssignments(data);
      _loadedParcels = true;
    } on RiderApiException catch (error) {
      _parcelError = error.message;
    } catch (_) {
      _parcelError =
          'Could not reach your Station Hub. Check your connection and retry.';
    } finally {
      _loadingParcels = false;
      notifyListeners();
    }
  }

  /// The Earnings tab's own fetch: credits and the COD cash still held.
  Future<void> refreshEarnings() async {
    if (_loadingEarnings) return;

    _loadingEarnings = true;
    _earningsError = null;
    notifyListeners();

    try {
      final data = await RiderApi.instance.earnings();
      _applyEarnings(data);
      _loadedEarnings = true;
    } on RiderApiException catch (error) {
      _earningsError = error.message;
    } catch (_) {
      _earningsError =
          'Could not reach your Station Hub. Check your connection and retry.';
    } finally {
      _loadingEarnings = false;
      notifyListeners();
    }
  }

  /// Alerts are secondary: a hiccup there must not blank out the parcel list.
  Future<void> refreshNotifications() async {
    try {
      _applyNotifications(await RiderApi.instance.notifications());
      notifyListeners();
    } catch (_) {
      // The next refresh retries them.
    }
  }

  /// Moves the parcel to the stage the scan confirmed.
  ///
  /// A delivery scan is completed with the handover photo and, for COD
  /// parcels, the exact cash the rider collected.
  Future<void> completeScan(
    RiderParcel parcel,
    String scanType, {
    String? recipientName,
    String? photoPath,
    double? cashCollected,
  }) async {
    if (scanType == 'delivered') {
      if (recipientName == null ||
          recipientName.trim().isEmpty ||
          photoPath == null ||
          photoPath.isEmpty) {
        throw const RiderApiException(
          'Add the proof of delivery before scanning this parcel.',
        );
      }

      await RiderApi.instance.submitProof(
        deliveryId: parcel.id,
        recipientName: recipientName,
        photoPath: photoPath,
        cashCollected: cashCollected,
      );
    } else {
      await RiderApi.instance.scan(
        trackingNumber: parcel.tracking,
        scanType: scanType,
        scanKey:
            '${parcel.assignment}:${parcel.id}:$scanType:'
            '${DateTime.now().millisecondsSinceEpoch}',
      );
    }

    await refresh();
  }

  /// Reports a failed delivery. The Station Hub sees it as a parcel exception.
  Future<void> markFailed(RiderParcel parcel, String reason) async {
    await RiderApi.instance.reportFailure(parcel.id, reason);
    await refresh();
  }

  /// Books the next delivery attempt after a failed one.
  Future<void> reschedule(RiderParcel parcel) async {
    await RiderApi.instance.rescheduleDelivery(parcel.id);
    await refresh();
  }

  Future<void> markNoticeRead(RiderNotice notice) async {
    if (notice.read) return;
    notice.read = true;
    notifyListeners();

    try {
      await RiderApi.instance.markNotificationRead(notice.id);
    } catch (_) {
      // The next refresh restores the server's read state.
    }
  }

  Future<void> markAllNoticesRead() async {
    var changed = false;
    for (final notice in _notices) {
      if (!notice.read) {
        notice.read = true;
        changed = true;
      }
    }
    if (changed) notifyListeners();

    try {
      await RiderApi.instance.markAllNotificationsRead();
    } catch (_) {
      // The next refresh restores the server's read state.
    }
  }

  /// Clears everything when the rider signs out.
  void reset() {
    _parcels.clear();
    _notices.clear();
    _earnings.clear();
    _collections.clear();

    _accruedTotal = 0;
    _cashOnHand = 0;
    _parcelError = null;
    _earningsError = null;
    _loadedParcels = false;
    _loadedEarnings = false;
    _loadingParcels = false;
    _loadingEarnings = false;
    notifyListeners();
  }

  void _applyAssignments(Map<String, dynamic> data) {
    final rows = (data['assignments'] as List<dynamic>? ?? [])
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row));

    _parcels
      ..clear()
      ..addAll(rows.map(_parcelFrom));
  }

  void _applyEarnings(Map<String, dynamic> data) {
    final summary = data['summary'] is Map
        ? Map<String, dynamic>.from(data['summary'] as Map)
        : <String, dynamic>{};

    _accruedTotal = _money(summary['accrued_total']);
    _cashOnHand = _money(summary['cash_on_hand']);

    _earnings
      ..clear()
      ..addAll(
        (data['earnings'] as List<dynamic>? ?? []).whereType<Map>().map(
          (row) => RiderEarning(
            order: row['order']?.toString() ?? '',
            hub: row['hub']?.toString() ?? '',
            amount: _money(row['amount']),
            date: row['date']?.toString() ?? '',
          ),
        ),
      );

    _collections
      ..clear()
      ..addAll(
        (data['collections'] as List<dynamic>? ?? []).whereType<Map>().map(
          (row) => CodCollection(
            order: row['order']?.toString() ?? '',
            amount: _money(row['amount']),
            date: row['date']?.toString() ?? '',
            status: row['status']?.toString() ?? 'Still with you',
          ),
        ),
      );
  }

  void _applyNotifications(Map<String, dynamic> data) {
    _notices
      ..clear()
      ..addAll(
        (data['notifications'] as List<dynamic>? ?? []).whereType<Map>().map(
          (row) => RiderNotice(
            id: int.tryParse('${row['id'] ?? ''}') ?? 0,
            title: row['title']?.toString() ?? 'Parcel update',
            message: row['message']?.toString() ?? '',
            timeAgo: row['time_ago']?.toString() ?? 'Just now',
            read: row['read'] == true,
          ),
        ),
      );
  }

  static RiderParcel _parcelFrom(Map<String, dynamic> row) {
    final cash = row['cash_to_collect'];

    return RiderParcel(
      id: int.tryParse('${row['id'] ?? ''}') ?? 0,
      tracking: row['tracking']?.toString() ?? '',
      labelCode: row['label_code']?.toString() ?? '',
      assignment: row['assignment']?.toString() ?? 'delivery',
      seller: row['seller']?.toString() ?? '',
      sellerAddress: row['seller_address']?.toString() ?? '',
      buyer: row['buyer']?.toString() ?? '',
      address: row['address']?.toString() ?? '',
      items: row['items']?.toString() ?? '',
      fee: _money(row['fee']),
      etaLabel: row['eta_label']?.toString() ?? '',
      contact: row['contact']?.toString() ?? '',
      notes: row['notes']?.toString() ?? '',
      cashToCollect: cash == null ? null : _money(cash),
      cutoffLabel: row['cutoff_label']?.toString() ?? '5:00 PM',
      stage: _stageFrom(row['stage']?.toString()),
      deliveredAt: DateTime.tryParse(row['delivered_at']?.toString() ?? ''),
    );
  }

  static RiderStage _stageFrom(String? value) => switch (value) {
    'ready_for_pickup' => RiderStage.readyForPickup,
    'on_the_way_to_hub' => RiderStage.onTheWayToHub,
    'for_delivery' => RiderStage.forDelivery,
    'on_the_way_to_buyer' => RiderStage.onTheWayToBuyer,
    'linehaul' => RiderStage.linehaul,
    'delivery_failed' => RiderStage.deliveryFailed,
    _ => RiderStage.delivered,
  };

  static double _money(dynamic value) =>
      double.tryParse(value?.toString() ?? '') ?? 0;
}

// ─────────────────────────────────────────────────────────────────────────────
// Stage helpers shared by Home, Parcels and the parcel detail screen
// ─────────────────────────────────────────────────────────────────────────────

String riderStageBadge(RiderStage stage) => switch (stage) {
  RiderStage.readyForPickup => 'For pickup',
  RiderStage.onTheWayToHub => 'On the way',
  RiderStage.forDelivery => 'For delivery',
  RiderStage.onTheWayToBuyer => 'On the way',
  RiderStage.linehaul => 'Linehaul',
  RiderStage.deliveryFailed => 'Failed',
  RiderStage.delivered => 'Delivered',
};

String riderStageTitle(RiderParcel parcel) => switch (parcel.stage) {
  RiderStage.readyForPickup => 'Pick up from ${parcel.seller}',
  RiderStage.onTheWayToHub => 'On the way to the ${parcel.seller} hub',
  RiderStage.forDelivery => 'Deliver to ${parcel.buyer}',
  RiderStage.onTheWayToBuyer => 'On the way to ${parcel.buyer}',
  RiderStage.linehaul => 'Truck linehaul',
  RiderStage.deliveryFailed => 'Delivery failed',
  RiderStage.delivered => 'Delivered',
};

String riderStageSubtitle(RiderParcel parcel) => switch (parcel.stage) {
  RiderStage.readyForPickup => parcel.sellerAddress,
  RiderStage.onTheWayToHub =>
    'Bring the parcel to the ${parcel.seller} hub for sorting.',
  RiderStage.forDelivery || RiderStage.onTheWayToBuyer => parcel.address,
  RiderStage.linehaul => 'Next checkpoint: ${parcel.address}',
  RiderStage.deliveryFailed =>
    'The ${parcel.cutoffLabel} delivery window closed. Reschedule to try again.',
  RiderStage.delivered => 'Handed to ${parcel.buyer}.',
};

String riderAssignmentLabel(RiderParcel parcel) => switch (parcel.assignment) {
  'pickup' => 'Pickup',
  'linehaul' => 'Truck linehaul',
  _ => 'Delivery',
};

/// The scan the next stage needs, or null when nothing is due.
String? riderScanTypeFor(RiderParcel parcel) {
  if (parcel.assignment == 'linehaul') {
    return parcel.stage == RiderStage.linehaul ? 'hub_arrival' : null;
  }
  if (parcel.assignment == 'pickup') {
    if (parcel.stage == RiderStage.readyForPickup) return 'pickup';
    if (parcel.stage == RiderStage.onTheWayToHub) return 'origin_arrival';
    return null;
  }
  if (parcel.stage == RiderStage.forDelivery) return 'out_for_delivery';
  if (parcel.stage == RiderStage.onTheWayToBuyer) return 'delivered';
  return null;
}

String riderScanLabelFor(String type) => switch (type) {
  'pickup' => 'Scan seller pickup',
  'origin_arrival' => 'Scan at the hub',
  'delivered' => 'Scan after handing over parcel',
  'hub_arrival' => 'Scan checkpoint',
  _ => 'Scan out for delivery',
};

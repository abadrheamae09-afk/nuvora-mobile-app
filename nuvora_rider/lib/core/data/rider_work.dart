import 'package:flutter/foundation.dart';

/// Rider-facing stage of one assigned parcel.
///
/// The screens only read this value — they never guess a stage from the clock.
/// In Vendo the stage came from the server status; here the rider app keeps the
/// same stage names so the Nuvora API can drive them unchanged later.
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

  /// Stage changes as the rider scans. Kept on the parcel so every screen
  /// shows the same thing without another round trip.
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

/// Everything the rider screens show.
///
/// The data lives on the device for now: the Nuvora site only exposes rider
/// login and applications yet, so the assignments, notifications and earnings
/// below are the sample work the screens were built against. Swap the bodies of
/// the methods for the API calls when the rider endpoints exist.
class RiderWorkStore extends ChangeNotifier {
  RiderWorkStore._();

  static final RiderWorkStore instance = RiderWorkStore._();

  final List<RiderParcel> _parcels = [
    RiderParcel(
      id: 1,
      tracking: 'NV-10243',
      assignment: 'pickup',
      seller: 'Green Mart',
      sellerAddress: '120 Aurora Blvd, Cubao, Quezon City',
      buyer: 'Maria Santos',
      address: 'M. Rodriguez St., Pasig City',
      items: '2 parcels · 3.4 km',
      fee: 85,
      etaLabel: 'ETA 10:40 AM',
      contact: '+63 917 555 0142',
      notes: 'Handle with care. Fragile items inside.',
      stage: RiderStage.readyForPickup,
    ),
    RiderParcel(
      id: 2,
      tracking: 'NV-10244',
      assignment: 'pickup',
      seller: 'Nuvora Home',
      sellerAddress: '8 Sct. Borromeo, Quezon City',
      buyer: 'Ana Reyes',
      address: '15 Camia St., Mandaluyong City',
      items: '1 parcel · 2.1 km',
      fee: 70,
      etaLabel: 'ETA 11:20 AM',
      contact: '+63 918 224 7781',
      stage: RiderStage.readyForPickup,
    ),
    RiderParcel(
      id: 3,
      tracking: 'NV-10251',
      assignment: 'delivery',
      seller: 'Nuvora Station Hub · Pasig',
      sellerAddress: 'Pasig Station Hub, Pasig City',
      buyer: 'Jose Cruz',
      address: '22 Narra St., Kapitolyo, Pasig City',
      items: '1 parcel · 1.6 km',
      fee: 70,
      etaLabel: 'Due 3:00 PM',
      contact: '+63 916 300 1188',
      notes: 'Leave at the guard house if nobody answers.',
      cashToCollect: 1250,
      stage: RiderStage.forDelivery,
    ),
    RiderParcel(
      id: 4,
      tracking: 'NV-10252',
      assignment: 'delivery',
      seller: 'Nuvora Station Hub · Pasig',
      sellerAddress: 'Pasig Station Hub, Pasig City',
      buyer: 'Liza Mercado',
      address: '7 Emerald Ave., Ortigas Center, Pasig City',
      items: '3 parcels · 2.8 km',
      fee: 95,
      etaLabel: 'Due 4:15 PM',
      contact: '+63 995 118 4402',
      stage: RiderStage.onTheWayToBuyer,
    ),
  ];

  final List<RiderNotice> _notices = [
    RiderNotice(
      id: 1,
      title: 'New parcel assigned',
      message: 'NV-10244 from Nuvora Home was added to your pickups.',
      timeAgo: '5 minutes ago',
    ),
    RiderNotice(
      id: 2,
      title: 'Delivery window',
      message: 'NV-10251 must be delivered before 5:00 PM today.',
      timeAgo: '42 minutes ago',
    ),
    RiderNotice(
      id: 3,
      title: 'Cash on hand',
      message: '₱1,250 COD for NV-10251 must be handed to your Station Hub.',
      timeAgo: '2 hours ago',
      read: true,
    ),
  ];

  final List<RiderEarning> _earnings = [
    const RiderEarning(
      order: 'NV-10239',
      hub: 'Pasig Station Hub',
      amount: 85,
      date: 'Nov 1, 2026',
    ),
    const RiderEarning(
      order: 'NV-10231',
      hub: 'Pasig Station Hub',
      amount: 70,
      date: 'Nov 1, 2026',
    ),
    const RiderEarning(
      order: 'NV-10222',
      hub: 'Cubao Station Hub',
      amount: 95,
      date: 'Oct 31, 2026',
    ),
  ];

  final List<CodCollection> _collections = [
    const CodCollection(
      order: 'NV-10251',
      amount: 1250,
      date: 'Nov 2, 2026',
      status: 'Still with you',
    ),
    const CodCollection(
      order: 'NV-10238',
      amount: 890,
      date: 'Nov 1, 2026',
      status: 'Received by hub',
    ),
  ];

  List<RiderParcel> get parcels => List.unmodifiable(_parcels);
  List<RiderNotice> get notices => List.unmodifiable(_notices);
  List<RiderEarning> get earnings => List.unmodifiable(_earnings);
  List<CodCollection> get collections => List.unmodifiable(_collections);

  int get unreadCount => _notices.where((notice) => !notice.read).length;

  double get accruedTotal =>
      _earnings.fold<double>(0, (sum, row) => sum + row.amount);

  double get cashOnHand => _collections
      .where((row) => row.status == 'Still with you')
      .fold<double>(0, (sum, row) => sum + row.amount);

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

  /// Moves the parcel to the stage the scan confirmed, and tells the rider what
  /// changed for the buyer and the seller.
  void completeScan(RiderParcel parcel, String scanType) {
    switch (scanType) {
      case 'pickup':
        parcel.stage = RiderStage.onTheWayToHub;
        _notify(
          'Parcel picked up',
          '${parcel.tracking} is on the way to the ${parcel.seller} hub.',
        );
      case 'origin_arrival':
        parcel.stage = RiderStage.forDelivery;
        _notify(
          'Parcel at the hub',
          '${parcel.tracking} was received and is ready for delivery.',
        );
      case 'out_for_delivery':
        parcel.stage = RiderStage.onTheWayToBuyer;
        _notify(
          'Out for delivery',
          '${parcel.buyer} now sees ${parcel.tracking} as on the way.',
        );
      case 'delivered':
        _completeDelivery(parcel);
      case 'hub_arrival':
        _notify(
          'Checkpoint scanned',
          '${parcel.tracking} reached the next linehaul checkpoint.',
        );
      default:
        break;
    }
    notifyListeners();
  }

  void _completeDelivery(RiderParcel parcel) {
    parcel.stage = RiderStage.delivered;
    parcel.deliveredAt = DateTime.now();
    _parcels.remove(parcel);

    final date = _dateLabel(parcel.deliveredAt!);
    _earnings.insert(
      0,
      RiderEarning(
        order: parcel.tracking,
        hub: parcel.seller,
        amount: parcel.fee,
        date: date,
      ),
    );

    if (parcel.cashToCollect != null) {
      // One COD row per order, so the cash on hand never doubles up when the
      // same parcel is delivered again after a reschedule.
      _collections.removeWhere((row) => row.order == parcel.tracking);
      _collections.insert(
        0,
        CodCollection(
          order: parcel.tracking,
          amount: parcel.cashToCollect!,
          date: date,
          status: 'Still with you',
        ),
      );
    }

    _notify(
      'Parcel delivered',
      '${parcel.tracking} was handed to ${parcel.buyer}. The buyer, '
          'the seller and your Station Hub now see it as delivered.',
    );
  }

  void markFailed(RiderParcel parcel, String reason) {
    parcel.stage = RiderStage.deliveryFailed;
    _notify(
      'Delivery failed',
      '${parcel.tracking} could not be delivered. Reason: $reason',
    );
    notifyListeners();
  }

  void reschedule(RiderParcel parcel) {
    parcel.stage = RiderStage.forDelivery;
    _notify(
      'Delivery rescheduled',
      '${parcel.tracking} is booked for tomorrow\'s delivery run. '
          'The buyer and seller were told the new date.',
    );
    notifyListeners();
  }

  void markNoticeRead(RiderNotice notice) {
    if (notice.read) return;
    notice.read = true;
    notifyListeners();
  }

  void markAllNoticesRead() {
    var changed = false;
    for (final notice in _notices) {
      if (!notice.read) {
        notice.read = true;
        changed = true;
      }
    }
    if (changed) notifyListeners();
  }

  void _notify(String title, String message) {
    _notices.insert(
      0,
      RiderNotice(
        id: (_notices.isEmpty ? 0 : _notices.first.id) + 1,
        title: title,
        message: message,
        timeAgo: 'Just now',
      ),
    );
  }

  static String _dateLabel(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
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

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api/rider_api.dart';
import '../../core/data/rider_work.dart';
import '../scanner/parcel_scanner_screen.dart';
import 'route_map_screen.dart';

const double _radius = 16;

/// Colours taken from the redesign (stitch_mobile_app_redesign).
class _Palette {
  static const forest = Color(0xFF143224);
  static const forestEnd = Color(0xFF0B2619);
  static const forestDeep = Color(0xFF001D10);
  static const secondary = Color(0xFF006C49);
  static const mint = Color(0xFF6FFBBE);
  static const mintInk = Color(0xFF005236);
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
  static const warnBorder = Color(0xFFF3E1B0);
  static const warnInk = Color(0xFF8A5A00);
  static const error = Color(0xFFBA1A1A);
  static const errorContainer = Color(0xFFFFDAD6);
}

BoxDecoration _cardDecoration() => BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(_radius),
  border: Border.all(color: _Palette.border),
  boxShadow: const [
    BoxShadow(color: Color(0x0A143224), blurRadius: 16, offset: Offset(0, 4)),
  ],
);

/// One parcel, start to finish: what it is, where it goes, the proof the buyer
/// needs, and the scan that moves it to the next stage.
class DeliveryDetailScreen extends StatefulWidget {
  const DeliveryDetailScreen({super.key, required this.parcel});

  final RiderParcel parcel;

  @override
  State<DeliveryDetailScreen> createState() => _DeliveryDetailScreenState();
}

class _DeliveryDetailScreenState extends State<DeliveryDetailScreen> {
  late RiderParcel _parcel;

  // Inline proof of delivery: the rider fills this on the parcel page, not in a
  // dialog, so the photo and recipient stay visible while they work.
  final _recipient = TextEditingController();
  final _cash = TextEditingController();
  final _proofFormKey = GlobalKey();
  XFile? _photo;
  String? _photoError;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _parcel = widget.parcel;
  }

  @override
  void dispose() {
    _recipient.dispose();
    _cash.dispose();
    super.dispose();
  }

  bool get _needsProof =>
      riderScanTypeFor(_parcel) == 'delivered' &&
      _parcel.stage != RiderStage.deliveryFailed;

  String _money(double value) => '₱${value.toStringAsFixed(2)}';

  // ---------------------------------------------------------------------------
  // Logic & routing: unchanged from the original screen.
  // ---------------------------------------------------------------------------

  // ── Contact and navigation ────────────────────────────────────────────────
  Future<void> _callBuyer() async {
    final uri = Uri(scheme: 'tel', path: _parcel.contact);
    if (!await launchUrl(uri) && mounted) {
      _snack('Could not open the phone app.');
    }
  }

  Future<void> _openMap() async {
    final query = Uri.encodeComponent(_parcel.address);
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$query',
    );
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) &&
        mounted) {
      _snack('Could not open the map app.');
    }
  }

  void _openRoute() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => RouteMapScreen(parcel: _parcel)),
    );
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  // ── Proof of delivery ─────────────────────────────────────────────────────
  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final captured = await ImagePicker().pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1600,
        maxHeight: 1600,
      );
      if (captured == null || !mounted) return;
      final bytes = await captured.length();
      if (!mounted) return;
      if (bytes > 5 * 1024 * 1024) {
        setState(() => _photoError = 'Photo must be 5 MB or smaller.');
        return;
      }
      setState(() {
        _photo = captured;
        _photoError = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _photoError = source == ImageSource.camera
            ? 'Could not open the camera. Check camera permission and retry.'
            : 'Could not open the gallery. Check photo permission and retry.';
      });
    }
  }

  /// Everything the proof needs is checked before the camera opens, so the
  /// rider is not left holding a scan they cannot submit.
  String? _proofProblem() {
    if (_recipient.text.trim().length < 2) {
      return 'Enter the recipient name in Proof of delivery.';
    }
    if (_photo == null) {
      return 'Take or choose a delivery photo in Proof of delivery.';
    }
    if (_parcel.cashToCollect != null) {
      final due = _parcel.cashToCollect!;
      final entered = double.tryParse(_cash.text.trim());
      if (entered == null || (entered - due).abs() >= 0.005) {
        return 'Enter exactly ${_money(due)} cash collected.';
      }
    }
    return null;
  }

  void _showProofProblem(String message) {
    _snack(message);
    final formContext = _proofFormKey.currentContext;
    if (formContext != null) {
      Scrollable.ensureVisible(
        formContext,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
        alignment: 0.1,
      );
    }
  }

  // ── Scanning ──────────────────────────────────────────────────────────────
  Future<void> _scan() async {
    final type = riderScanTypeFor(_parcel);
    if (type == null || _busy) return;

    if (type == 'delivered') {
      final problem = _proofProblem();
      if (problem != null) {
        _showProofProblem(problem);
        return;
      }
    }

    final scanned = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => ParcelScannerScreen(
          expectedCode: _parcel.tracking,
          // The printed label can carry the waybill number while the parcel
          // row still holds the order number; both identify this parcel.
          expectedCodes: [_parcel.labelCode],
          actionLabel: riderScanLabelFor(type),
        ),
      ),
    );
    if (!mounted || scanned == null) return;

    setState(() => _busy = true);
    try {
      await RiderWorkStore.instance.completeScan(
        _parcel,
        type,
        recipientName: _recipient.text,
        photoPath: _photo?.path,
        cashCollected: _parcel.cashToCollect == null
            ? null
            : double.tryParse(_cash.text.trim()),
      );
      if (!mounted) return;

      setState(() {
        _photo = null;
        _recipient.clear();
        _cash.clear();
      });

      if (type == 'delivered') {
        _snack(
          'Delivered. The buyer, the seller and your Station Hub now show this '
          'parcel as delivered.',
        );
        Navigator.pop(context);
        return;
      }

      final updated = RiderWorkStore.instance.find(_parcel.tracking);

      if (updated == null) {
        // The parcel is now at the hub (or with the next hub) and no longer
        // this rider's task, so there is nothing left on this page.
        _snack('Scan saved. The parcel is no longer assigned to you.');
        Navigator.pop(context);
        return;
      }

      setState(() => _parcel = updated);
      _snack('Scan saved. Seller and buyer tracking is updated.');
    } on RiderApiException catch (error) {
      if (mounted) _snack(error.message);
    } catch (_) {
      if (mounted) {
        _snack('Could not save the scan. Check your connection and retry.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reschedule() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radius + 8),
        ),
        title: const Text(
          'Reschedule delivery?',
          style: TextStyle(
            color: _Palette.forestDeep,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: const Text(
          'This parcel will be booked for tomorrow\'s delivery run. The buyer '
          'and seller will be told the new date.',
          style: TextStyle(color: _Palette.inkVariant, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            style: TextButton.styleFrom(foregroundColor: _Palette.outline),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(
              backgroundColor: _Palette.secondary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reschedule'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await RiderWorkStore.instance.reschedule(_parcel);
      final updated = RiderWorkStore.instance.find(_parcel.tracking);
      if (!mounted) return;
      if (updated != null) setState(() => _parcel = updated);
      _snack('Delivery rescheduled for tomorrow.');
    } on RiderApiException catch (error) {
      if (mounted) _snack(error.message);
    } catch (_) {
      if (mounted) {
        _snack('Could not reschedule. Check your connection and retry.');
      }
    }
  }

  Future<void> _reportIssue() async {
    final reason = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const _IssueSheet(),
    );
    if (reason == null || !mounted) return;

    try {
      await RiderWorkStore.instance.markFailed(_parcel, reason);
      final updated = RiderWorkStore.instance.find(_parcel.tracking);
      if (!mounted) return;
      if (updated != null) setState(() => _parcel = updated);
      _snack('Issue sent to your Station Hub. The parcel is marked as failed.');
    } on RiderApiException catch (error) {
      if (mounted) _snack(error.message);
    } catch (_) {
      if (mounted) {
        _snack('Could not report the issue. Check your connection and retry.');
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Design
  // ---------------------------------------------------------------------------

  // ── Screen ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final stage = _parcel.stage;
    final scanType = riderScanTypeFor(_parcel);
    final failed = stage == RiderStage.deliveryFailed;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _Palette.background,
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(stage),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_parcel.isCod) ...[
                      _buildCashCard(),
                      const SizedBox(height: 16),
                    ],
                    if (!failed) ...[
                      _buildDeliveryWindowCard(),
                      const SizedBox(height: 16),
                    ],
                    _buildRouteSection(),
                    const SizedBox(height: 22),
                    _buildStopSection(),
                    const SizedBox(height: 22),
                    _buildMapSection(),
                    const SizedBox(height: 22),
                    if (_needsProof) ...[
                      _buildProofSection(),
                      const SizedBox(height: 22),
                    ],
                    _buildStageSteps(stage),
                    if (failed) ...[
                      const SizedBox(height: 20),
                      FilledButton.icon(
                        onPressed: _reschedule,
                        style: FilledButton.styleFrom(
                          backgroundColor: _Palette.secondary,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        icon: const Icon(Icons.event_repeat_rounded, size: 20),
                        label: const Text('Reschedule for tomorrow'),
                      ),
                    ],
                    // A failed delivery is reported against the delivery the
                    // Station Hub queued; pickups have no delivery row yet.
                    if (!failed && _parcel.assignment == 'delivery') ...[
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: _busy ? null : _reportIssue,
                          style: TextButton.styleFrom(
                            foregroundColor: _Palette.error,
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          icon: const Icon(Icons.report_problem_outlined),
                          label: const Text('Report an issue'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: scanType == null
            ? null
            : _buildBottomBar(scanType),
      ),
    );
  }

  // ── Deep forest header ────────────────────────────────────────────────────
  Widget _buildHeader(RiderStage stage) {
    final topInset = MediaQuery.of(context).padding.top;
    final style = _stageStyle(stage);

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
            padding: EdgeInsets.fromLTRB(16, topInset + 10, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Semantics(
                      button: true,
                      label: 'Back',
                      child: Tooltip(
                        message: 'Back',
                        child: Material(
                          color: Colors.white.withAlpha(26),
                          shape: const CircleBorder(),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: () => Navigator.pop(context),
                            child: const SizedBox(
                              width: 40,
                              height: 40,
                              child: Icon(
                                Icons.arrow_back_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: style.bg,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        riderStageBadge(stage),
                        style: TextStyle(
                          color: style.fg,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _parcel.tracking,
                        style: const TextStyle(
                          color: _Palette.onForestMuted,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        riderStageTitle(_parcel),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        riderStageSubtitle(_parcel),
                        style: const TextStyle(
                          color: Color(0xFFADCEBA),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _HeaderChip(
                            icon: Icons.schedule_rounded,
                            label: _parcel.etaLabel,
                          ),
                          _HeaderChip(
                            icon: Icons.inventory_2_outlined,
                            label: _parcel.items,
                          ),
                        ],
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

  /// The scan action, docked at the bottom under the thumb.
  Widget _buildBottomBar(String scanType) {
    const radius = BorderRadius.all(Radius.circular(18));

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _Palette.surface)),
        boxShadow: [
          BoxShadow(
            color: Color(0x0F143224),
            blurRadius: 20,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Opacity(
            opacity: _busy ? 0.85 : 1,
            child: Container(
              height: 56,
              decoration: const BoxDecoration(
                borderRadius: radius,
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [_Palette.secondary, _Palette.forest],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x40006C49),
                    blurRadius: 20,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: radius,
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: _busy ? null : _scan,
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _busy
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(
                                Icons.qr_code_scanner_rounded,
                                color: _Palette.mint,
                                size: 24,
                              ),
                        const SizedBox(width: 10),
                        Text(
                          _busy ? 'Saving…' : riderScanLabelFor(scanType),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── COD cash the rider must collect at handover ───────────────────────────
  Widget _buildCashCard() {
    final amount = _money(_parcel.cashToCollect!);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _Palette.warnBg,
        borderRadius: BorderRadius.circular(_radius),
        border: Border.all(color: _Palette.warnBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.payments_outlined, color: _Palette.warnInk),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Collect $amount cash',
                  style: const TextStyle(
                    color: _Palette.forestDeep,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Ask the buyer for the exact amount. You will enter it when you '
                  'submit the delivery proof.',
                  style: TextStyle(
                    color: Color(0xFF4B5A50),
                    fontSize: 12.5,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryWindowCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _Palette.surfaceLow,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _Palette.secondary.withAlpha(26)),
            ),
            child: const Icon(Icons.timer_outlined, color: _Palette.secondary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Delivery window',
                  style: TextStyle(
                    color: _Palette.ink,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text.rich(
                  TextSpan(
                    style: const TextStyle(
                      color: _Palette.inkVariant,
                      fontSize: 12.5,
                    ),
                    children: [
                      const TextSpan(text: 'Deliver before '),
                      TextSpan(
                        text: _parcel.cutoffLabel,
                        style: const TextStyle(
                          color: _Palette.secondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const TextSpan(text: ' today'),
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

  // ── Route: pickup point → drop-off ────────────────────────────────────────
  Widget _buildRouteSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('Route'),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: _cardDecoration(),
          child: Column(
            children: [
              _RouteStop(
                icon: Icons.store_mall_directory_outlined,
                color: _Palette.secondary,
                label: 'Pickup',
                name: _parcel.seller,
                address: _parcel.sellerAddress,
                last: false,
              ),
              const SizedBox(height: 8),
              _RouteStop(
                icon: Icons.flag_outlined,
                color: _Palette.blue,
                label: 'Drop-off',
                name: _parcel.buyer,
                address: _parcel.address,
                last: true,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _openRoute,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _Palette.ink,
                        backgroundColor: _Palette.surfaceLow,
                        side: const BorderSide(color: _Palette.border),
                        minimumSize: const Size(0, 46),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(23),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      icon: const Icon(
                        Icons.map_outlined,
                        size: 18,
                        color: _Palette.secondary,
                      ),
                      label: const Text('View route'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _openMap,
                      style: FilledButton.styleFrom(
                        backgroundColor: _Palette.secondary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 46),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(23),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      icon: const Icon(Icons.navigation_outlined, size: 18),
                      label: const Text('Navigate'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStopSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('Recipient'),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
          decoration: _cardDecoration(),
          child: Column(
            children: [
              _DetailRow(
                icon: Icons.person_outline_rounded,
                label: 'Name',
                value: _parcel.buyer,
              ),
              const Divider(height: 1, color: _Palette.surface),
              _DetailRow(
                icon: Icons.call_outlined,
                label: 'Contact',
                value: _parcel.contact,
                actionLabel: 'Call',
                onAction: _callBuyer,
              ),
              const Divider(height: 1, color: _Palette.surface),
              _DetailRow(
                icon: Icons.location_on_outlined,
                label: 'Address',
                value: _parcel.address,
                actionLabel: 'Map',
                onAction: _openMap,
              ),
              if (_parcel.notes.isNotEmpty) ...[
                const Divider(height: 1, color: _Palette.surface),
                _DetailRow(
                  icon: Icons.sticky_note_2_outlined,
                  label: 'Note',
                  value: _parcel.notes,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMapSection() {
    return GestureDetector(
      onTap: _openRoute,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_Palette.forestDeep, _Palette.forest],
          ),
          borderRadius: BorderRadius.circular(_radius),
          boxShadow: const [
            BoxShadow(
              color: Color(0x26001D10),
              blurRadius: 16,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(26),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.route_outlined, color: _Palette.mint),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Open the route',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Stops, distance and estimated time',
                    style: TextStyle(
                      color: _Palette.onForestMuted,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withAlpha(26),
              ),
              child: const Icon(
                Icons.arrow_forward_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration({
    required String label,
    required String hint,
    required IconData icon,
  }) {
    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: color, width: width),
        );

    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(color: _Palette.outline, fontSize: 14),
      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13.5),
      floatingLabelStyle: const TextStyle(
        color: _Palette.secondary,
        fontWeight: FontWeight.w700,
      ),
      prefixIcon: Icon(icon, size: 20, color: _Palette.outline),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: border(_Palette.border),
      enabledBorder: border(_Palette.border),
      focusedBorder: border(_Palette.secondary, 1.5),
    );
  }

  Widget _buildProofSection() {
    return Container(
      key: _proofFormKey,
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle('Proof of delivery'),
          const SizedBox(height: 6),
          const Text(
            'Fill this in before scanning the parcel at the buyer\'s door.',
            style: TextStyle(
              color: _Palette.outline,
              fontSize: 12.5,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _recipient,
            textCapitalization: TextCapitalization.words,
            style: const TextStyle(
              color: _Palette.ink,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            decoration: _fieldDecoration(
              label: 'Received by',
              hint: 'Name of the person who took the parcel',
              icon: Icons.person_outline_rounded,
            ),
          ),
          if (_parcel.cashToCollect != null) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _cash,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: const TextStyle(
                color: _Palette.ink,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              decoration: _fieldDecoration(
                label: 'Cash collected',
                hint: _money(_parcel.cashToCollect!),
                icon: Icons.payments_outlined,
              ),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _PhotoButton(
                  icon: Icons.photo_camera_outlined,
                  label: 'Take photo',
                  onTap: () => _pickPhoto(ImageSource.camera),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _PhotoButton(
                  icon: Icons.photo_library_outlined,
                  label: 'Choose photo',
                  onTap: () => _pickPhoto(ImageSource.gallery),
                ),
              ),
            ],
          ),
          if (_photoError != null) ...[
            const SizedBox(height: 10),
            Text(
              _photoError!,
              style: const TextStyle(color: _Palette.error, fontSize: 12.5),
            ),
          ],
          if (_photo != null) ...[
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Stack(
                children: [
                  Image.file(
                    File(_photo!.path),
                    width: double.infinity,
                    height: 168,
                    fit: BoxFit.cover,
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Material(
                      color: Colors.black54,
                      shape: const CircleBorder(),
                      clipBehavior: Clip.antiAlias,
                      child: IconButton(
                        tooltip: 'Remove photo',
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                        onPressed: () => setState(() => _photo = null),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Stage steps: where the parcel is in the run ───────────────────────────
  Widget _buildStageSteps(RiderStage stage) {
    final steps = <String>[
      'Pick up from the seller',
      'Drop at the station hub',
      'Out for delivery',
      'Delivered to the buyer',
    ];
    final current = switch (stage) {
      RiderStage.readyForPickup => 0,
      RiderStage.onTheWayToHub => 1,
      RiderStage.forDelivery => 2,
      RiderStage.onTheWayToBuyer => 3,
      _ => 0,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('Progress'),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: _cardDecoration(),
          child: Column(
            children: [
              for (var index = 0; index < steps.length; index++)
                _StepRow(
                  label: steps[index],
                  done: index < current,
                  active: index == current,
                  last: index == steps.length - 1,
                ),
            ],
          ),
        ),
      ],
    );
  }

  _StageStyle _stageStyle(RiderStage stage) => switch (stage) {
    RiderStage.readyForPickup => const _StageStyle(
      _Palette.warnInk,
      _Palette.warnBg,
    ),
    RiderStage.forDelivery => const _StageStyle(
      _Palette.blue,
      _Palette.blueSoft,
    ),
    RiderStage.deliveryFailed => const _StageStyle(
      _Palette.error,
      _Palette.errorContainer,
    ),
    _ => const _StageStyle(_Palette.mintInk, _Palette.mint),
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// Small widgets
// ─────────────────────────────────────────────────────────────────────────────

class _StageStyle {
  const _StageStyle(this.fg, this.bg);

  final Color fg, bg;
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 5,
          height: 16,
          decoration: BoxDecoration(
            color: _Palette.secondary,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            color: _Palette.forestDeep,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _HeaderChip extends StatelessWidget {
  const _HeaderChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(26),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withAlpha(38)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: _Palette.mint),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _RouteStop extends StatelessWidget {
  const _RouteStop({
    required this.icon,
    required this.color,
    required this.label,
    required this.name,
    required this.address,
    required this.last,
  });

  final IconData icon;
  final Color color;
  final String label, name, address;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: color.withAlpha(26),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            if (!last)
              Container(
                width: 2,
                height: 30,
                decoration: BoxDecoration(
                  color: _Palette.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(top: last ? 0 : 3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: const TextStyle(
                    color: _Palette.outline,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _Palette.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  address,
                  style: const TextStyle(
                    fontSize: 12,
                    color: _Palette.inkVariant,
                    height: 1.35,
                  ),
                ),
                if (!last) const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String label, value;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              color: _Palette.surfaceLow,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: _Palette.secondary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: _Palette.outline,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: _Palette.ink,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(width: 8),
            Material(
              color: _Palette.surface,
              borderRadius: BorderRadius.circular(18),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onAction,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  child: Text(
                    actionLabel!,
                    style: const TextStyle(
                      color: _Palette.secondary,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PhotoButton extends StatelessWidget {
  const _PhotoButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: _Palette.ink,
        side: const BorderSide(color: _Palette.border),
        backgroundColor: _Palette.surfaceLow,
        minimumSize: const Size(0, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        textStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
      ),
      icon: Icon(icon, size: 18, color: _Palette.secondary),
      label: Text(label),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.label,
    required this.done,
    required this.active,
    required this.last,
  });

  final String label;
  final bool done, active, last;

  @override
  Widget build(BuildContext context) {
    final color = done || active ? _Palette.secondary : _Palette.border;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: done ? _Palette.secondary : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 2),
              ),
              child: done
                  ? const Icon(
                      Icons.check_rounded,
                      size: 13,
                      color: Colors.white,
                    )
                  : active
                  ? Center(
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: _Palette.secondary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    )
                  : null,
            ),
            if (!last)
              Container(
                width: 2,
                height: 26,
                color: done ? _Palette.secondary : _Palette.border,
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: active || done ? FontWeight.w700 : FontWeight.w500,
                color: active || done ? _Palette.ink : _Palette.outline,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Reasons a delivery could not be completed.
class _IssueSheet extends StatelessWidget {
  const _IssueSheet();

  static const _reasons = [
    'Buyer not at home',
    'Buyer did not answer',
    'Wrong or incomplete address',
    'Buyer refused the parcel',
    'Parcel damaged',
  ];

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
            const Text(
              'What happened?',
              style: TextStyle(
                color: _Palette.forestDeep,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'The buyer, the seller and your Station Hub will see this reason.',
              style: TextStyle(color: _Palette.outline, fontSize: 12.5),
            ),
            const SizedBox(height: 8),
            for (final reason in _reasons)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 34,
                  height: 34,
                  decoration: const BoxDecoration(
                    color: _Palette.errorContainer,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.error_outline_rounded,
                    color: _Palette.error,
                    size: 18,
                  ),
                ),
                title: Text(
                  reason,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _Palette.ink,
                  ),
                ),
                trailing: const Icon(
                  Icons.chevron_right_rounded,
                  color: _Palette.outline,
                  size: 20,
                ),
                onTap: () => Navigator.pop(context, reason),
              ),
          ],
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/data/rider_work.dart';
import '../../theme/app_colors.dart';

/// The rider's route for one parcel: pickup point, drop-off and the trip in
/// between. The map itself opens in the phone's map app, so the rider screen
/// stays fast and needs no map tiles of its own.
class RouteMapScreen extends StatelessWidget {
  const RouteMapScreen({super.key, required this.parcel});

  final RiderParcel parcel;

  String get _distance {
    final match = RegExp(r'([\d.]+)\s*km').firstMatch(parcel.items);
    return match == null ? '2.0 km' : '${match.group(1)} km';
  }

  Future<void> _openMaps(BuildContext context, String query) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(query)}',
    );
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the map app.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMapCard(context),
                    const SizedBox(height: 20),
                    _buildSummary(),
                    const SizedBox(height: 20),
                    _buildStops(context),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 52,
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => _openMaps(context, parcel.address),
                        icon: const Icon(Icons.navigation_rounded, size: 20),
                        label: const Text('Start navigation'),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 48,
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            _openMaps(context, parcel.sellerAddress),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.ink,
                          side: const BorderSide(color: AppColors.border),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const Icon(Icons.storefront_outlined, size: 18),
                        label: const Text('Open pickup point'),
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

  Widget _buildHeader(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(12, topInset + 8, 20, 20),
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
          Row(
            children: [
              IconButton(
                tooltip: 'Back',
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              ),
              const Spacer(),
              Text(
                parcel.tracking,
                style: const TextStyle(
                  color: Color(0xB3FFFFFF),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
          const SizedBox(height: 4),
          const Padding(
            padding: EdgeInsets.only(left: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Route',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Pickup point to the buyer’s door',
                  style: TextStyle(color: Color(0xD9FFFFFF), fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapCard(BuildContext context) {
    return Container(
      height: 210,
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.primaryDeep,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _RouteSketchPainter())),
          Positioned(
            left: 16,
            top: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.circle, size: 8, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text(
                    '${parcel.seller} → ${parcel.buyer}',
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Positioned(
            left: 16,
            bottom: 16,
            child: Text(
              'Tap “Start navigation” to open\nthis route in your map app.',
              style: TextStyle(
                color: Color(0xCCFFFFFF),
                fontSize: 11.5,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          _summaryCell(_distance, 'Distance'),
          _summaryDivider(),
          _summaryCell(parcel.etaLabel.replaceFirst('ETA ', ''), 'ETA'),
          _summaryDivider(),
          _summaryCell(_parcelFee(), 'Rider fee'),
        ],
      ),
    );
  }

  String _parcelFee() => '₱${parcel.fee.toStringAsFixed(0)}';

  Widget _summaryCell(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.primaryDeep,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: AppColors.muted, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _summaryDivider() =>
      Container(width: 1, height: 32, color: AppColors.border);

  Widget _buildStops(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _stop(
            context,
            color: AppColors.primary,
            icon: Icons.store_mall_directory_outlined,
            label: 'Pickup',
            name: parcel.seller,
            address: parcel.sellerAddress,
            last: false,
          ),
          _stop(
            context,
            color: AppColors.blue,
            icon: Icons.flag_outlined,
            label: 'Drop-off',
            name: parcel.buyer,
            address: parcel.address,
            last: true,
          ),
        ],
      ),
    );
  }

  Widget _stop(
    BuildContext context, {
    required Color color,
    required IconData icon,
    required String label,
    required String name,
    required String address,
    required bool last,
  }) {
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
            if (!last) Container(width: 2, height: 40, color: AppColors.border),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                name,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                address,
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
              if (!last) const SizedBox(height: 18),
            ],
          ),
        ),
      ],
    );
  }
}

/// A simple stylised route so the card reads as a map without loading tiles.
class _RouteSketchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = Colors.white.withAlpha(14)
      ..strokeWidth = 1;

    for (var x = 0.0; x < size.width; x += 28) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (var y = 0.0; y < size.height; y += 28) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    final path = Path()
      ..moveTo(size.width * 0.12, size.height * 0.78)
      ..cubicTo(
        size.width * 0.34,
        size.height * 0.62,
        size.width * 0.40,
        size.height * 0.86,
        size.width * 0.58,
        size.height * 0.58,
      )
      ..cubicTo(
        size.width * 0.74,
        size.height * 0.34,
        size.width * 0.82,
        size.height * 0.46,
        size.width * 0.90,
        size.height * 0.22,
      );

    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round
        ..color = AppColors.primary.withAlpha(90),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..color = AppColors.gold,
    );

    final start = Offset(size.width * 0.12, size.height * 0.78);
    final end = Offset(size.width * 0.90, size.height * 0.22);

    canvas.drawCircle(start, 9, Paint()..color = Colors.white);
    canvas.drawCircle(start, 5, Paint()..color = AppColors.primary);

    canvas.drawCircle(end, 11, Paint()..color = Colors.white);
    canvas.drawCircle(end, 6, Paint()..color = AppColors.blue);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../theme/app_colors.dart';

/// Scans a parcel QR code or barcode and pops with the raw value.
///
/// The caller decides what the code means: Home opens the matching parcel, the
/// parcel page advances the stage. When a code is expected, a different code
/// keeps the camera open and explains the mismatch.
class ParcelScannerScreen extends StatefulWidget {
  const ParcelScannerScreen({
    super.key,
    this.expectedCode,
    this.expectedCodes = const [],
    this.actionLabel,
  });

  /// Tracking number this scan is for, when the rider opened the scanner from a
  /// parcel page.
  final String? expectedCode;

  /// Other codes the same parcel's label may carry, such as the waybill number
  /// inside the QR code when the parcel row still holds the order number.
  final List<String> expectedCodes;

  /// What the scan will do, shown under the viewfinder.
  final String? actionLabel;

  @override
  State<ParcelScannerScreen> createState() => _ParcelScannerScreenState();
}

class _ParcelScannerScreenState extends State<ParcelScannerScreen> {
  final MobileScannerController _camera = MobileScannerController(
    formats: const [
      BarcodeFormat.qrCode,
      BarcodeFormat.code128,
      BarcodeFormat.code39,
    ],
  );

  bool _found = false;
  String? _mismatch;

  Future<void> _handleCode(String code) async {
    if (_found) return;

    final expected = widget.expectedCode;
    if (expected != null && !_matchesAny(code)) {
      if (!mounted) return;
      setState(() {
        _mismatch = 'This is not $expected. Scan the label of this parcel.';
      });
      return;
    }

    _found = true;
    await _camera.stop();
    if (!mounted) return;
    Navigator.pop(context, code);
  }

  bool _matchesAny(String scanned) {
    final code = scanned.trim().toLowerCase();

    return [widget.expectedCode, ...widget.expectedCodes]
        .whereType<String>()
        .where((value) => value.trim().isNotEmpty)
        .any((value) {
          final wanted = value.trim().toLowerCase();
          return code.contains(wanted) || wanted.contains(code);
        });
  }

  Future<void> _enterManually() async {
    final controller = TextEditingController(text: widget.expectedCode ?? '');

    final code = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          'Enter the code',
          style: TextStyle(
            color: AppColors.ink,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(
            hintText: 'NV-10243',
            labelText: 'Tracking number',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('Use code'),
          ),
        ],
      ),
    );

    controller.dispose();
    if (code == null || code.isEmpty) return;
    await _handleCode(code);
  }

  @override
  void dispose() {
    _camera.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: AppColors.headerTop,
        foregroundColor: Colors.white,
        title: Text(
          widget.actionLabel ?? 'Scan parcel',
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: 'Toggle flashlight',
            icon: const Icon(Icons.flashlight_on_outlined),
            onPressed: _camera.toggleTorch,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                MobileScanner(
                  controller: _camera,
                  onDetect: (capture) {
                    for (final barcode in capture.barcodes) {
                      final raw = barcode.rawValue;
                      if (raw != null && raw.isNotEmpty) {
                        _handleCode(raw);
                        return;
                      }
                    }
                  },
                ),
                CustomPaint(
                  size: const Size(220, 220),
                  painter: _ScanOverlayPainter(),
                ),
                if (_mismatch != null)
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 24,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.dangerSoft,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            color: AppColors.danger,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _mismatch!,
                              style: const TextStyle(
                                color: AppColors.danger,
                                fontSize: 12.5,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            color: AppColors.primaryDeep,
            padding: EdgeInsets.fromLTRB(
              24,
              16,
              24,
              16 + MediaQuery.of(context).padding.bottom,
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.qr_code_scanner_rounded,
                  color: Colors.white,
                  size: 26,
                ),
                const SizedBox(height: 8),
                Text(
                  widget.expectedCode == null
                      ? 'Align the QR code or barcode inside the frame'
                      : 'Scan the label for ${widget.expectedCode}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Scanning happens automatically',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xAAFFFFFF), fontSize: 12),
                ),
                const SizedBox(height: 6),
                TextButton(
                  onPressed: _enterManually,
                  style: TextButton.styleFrom(foregroundColor: AppColors.gold),
                  child: const Text('Enter the code manually'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Corner bracket overlay around the scan area.
class _ScanOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.gold
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const len = 28.0;
    final w = size.width;
    final h = size.height;

    canvas.drawLine(Offset(0, len), Offset(0, 0), paint);
    canvas.drawLine(Offset(0, 0), Offset(len, 0), paint);
    canvas.drawLine(Offset(w - len, 0), Offset(w, 0), paint);
    canvas.drawLine(Offset(w, 0), Offset(w, len), paint);
    canvas.drawLine(Offset(0, h - len), Offset(0, h), paint);
    canvas.drawLine(Offset(0, h), Offset(len, h), paint);
    canvas.drawLine(Offset(w - len, h), Offset(w, h), paint);
    canvas.drawLine(Offset(w, h - len), Offset(w, h), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

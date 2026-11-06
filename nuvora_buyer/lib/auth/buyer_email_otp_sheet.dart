// ============================================================
// buyer_email_otp_sheet.dart
// Inline email-verification sheet used by buyer registration.
// Same behaviour as the rider's RiderEmailOtpSheet: six digit
// boxes, paste support, resend, and pop(true) once the code is
// accepted by `email/otp/verify`.
// ============================================================

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/api/buyer_api.dart';

/// Local design tokens, matching the registration screen it opens over
/// (Botanical Boutique palette).
class _S {
  static const surfaceLow = Color(0xFFF6F3F2);

  static const onSurface = Color(0xFF1C1B1B);
  static const onSurfaceVariant = Color(0xFF424844);
  static const outline = Color(0xFF727973);
  static const outlineVariant = Color(0xFFC1C8C2);

  static const primary = Color(0xFF012114);
  static const primaryContainer = Color(0xFF173628);
  static const secondary = Color(0xFF44664B);
  static const error = Color(0xFFBA1A1A);

  static const serif = 'Playfair Display';
  static const sans = 'Plus Jakarta Sans';

  static const headlineSm = TextStyle(
    fontFamily: serif,
    fontSize: 18,
    height: 24 / 18,
    fontWeight: FontWeight.w600,
    color: primary,
  );
  static const bodyMd = TextStyle(
    fontFamily: sans,
    fontSize: 14,
    height: 20 / 14,
    color: onSurface,
  );
  static const bodySm = TextStyle(
    fontFamily: sans,
    fontSize: 12,
    height: 18 / 12,
    color: onSurfaceVariant,
  );
  static const labelLg = TextStyle(
    fontFamily: sans,
    fontSize: 14,
    height: 18 / 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.14,
  );
}

class BuyerEmailOtpSheet extends StatefulWidget {
  const BuyerEmailOtpSheet({required this.email, super.key});

  final String email;

  @override
  State<BuyerEmailOtpSheet> createState() => _BuyerEmailOtpSheetState();
}

class _BuyerEmailOtpSheetState extends State<BuyerEmailOtpSheet> {
  final List<TextEditingController> _digits =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focus = List.generate(6, (_) => FocusNode());
  bool _busy = false;
  String? _message;
  bool _messageIsError = false;

  // Short wait between code sends, mirroring the web modal's countdown.
  Timer? _resendTimer;
  int _resendIn = 0;

  @override
  void initState() {
    super.initState();
    // The registration screen already sent the first code.
    _startCooldown();
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    for (final c in _digits) {
      c.dispose();
    }
    for (final n in _focus) {
      n.dispose();
    }
    super.dispose();
  }

  void _startCooldown([int seconds = 30]) {
    _resendTimer?.cancel();
    setState(() => _resendIn = seconds);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _resendIn -= 1;
        if (_resendIn <= 0) {
          _resendIn = 0;
          timer.cancel();
        }
      });
    });
  }

  String get _code => _digits.map((c) => c.text).join();

  Future<void> _verify() async {
    if (_code.length != 6 || _busy) {
      setState(() {
        _message = 'Enter the 6-digit code from your email.';
        _messageIsError = true;
      });
      return;
    }

    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await BuyerApi.instance.verifyEmailCode(widget.email, _code);
      if (mounted) Navigator.of(context).pop(true);
    } on BuyerApiException catch (error) {
      if (!mounted) return;
      final expired = error.message.toLowerCase().contains('expired') ||
          error.message.toLowerCase().contains('invalid');
      setState(() {
        _message = expired
            ? 'That code is invalid or has expired. Tap "Resend code" for a '
                  'new one.'
            : error.message;
        _messageIsError = true;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _message = 'Could not verify the code: $error';
        _messageIsError = true;
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resend() async {
    if (_busy || _resendIn > 0) return;

    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await BuyerApi.instance.sendEmailCode(widget.email);
      if (!mounted) return;
      for (final c in _digits) {
        c.clear();
      }
      _focus.first.requestFocus();
      setState(() {
        _message = 'A new code was sent to ${widget.email}.';
        _messageIsError = false;
      });
      _startCooldown();
    } on BuyerApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _message = error.message;
        _messageIsError = true;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _message = 'Could not resend the code: $error';
        _messageIsError = true;
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _onDigitChanged(String value, int index) {
    if (_messageIsError) setState(() => _message = null);
    if (value.isEmpty && index > 0) {
      _focus[index - 1].requestFocus();
    } else if (value.isNotEmpty && index < _focus.length - 1) {
      _focus[index + 1].requestFocus();
    } else if (value.isNotEmpty) {
      _focus[index].unfocus();
    }
  }

  /// A pasted code fills the remaining boxes instead of just one.
  Future<void> _pasteCode(int index) async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final digits = (data?.text ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.length < 2) return;

    setState(() {
      for (var i = index; i < _digits.length; i++) {
        final digitIndex = i - index;
        if (digitIndex < digits.length) {
          _digits[i].text = digits[digitIndex];
        }
      }
      _message = null;
    });
    final next = (index + digits.length).clamp(0, _focus.length - 1);
    _focus[next].requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          12,
          20,
          MediaQuery.viewInsetsOf(context).bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: _S.outlineVariant,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Verify your email', style: _S.headlineSm),
            const SizedBox(height: 6),
            Text(
              'Enter the 6-digit code sent to ${widget.email}.',
              style: _S.bodyMd.copyWith(color: _S.onSurfaceVariant),
            ),
            const SizedBox(height: 18),
            Row(
              children: List.generate(6, (index) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: SizedBox(
                      height: 54,
                      child: TextField(
                        controller: _digits[index],
                        focusNode: _focus[index],
                        autofocus: index == 0,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        maxLength: 1,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(1),
                        ],
                        style: _S.labelLg.copyWith(
                          fontSize: 20,
                          color: _S.primary,
                        ),
                        cursorColor: _S.primaryContainer,
                        decoration: InputDecoration(
                          counterText: '',
                          filled: true,
                          fillColor: _S.surfaceLow,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 14),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: _S.outlineVariant,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: _S.primaryContainer,
                              width: 1.5,
                            ),
                          ),
                        ),
                        onChanged: (value) => _onDigitChanged(value, index),
                        onTap: () => _pasteCode(index),
                        onSubmitted: (_) => _verify(),
                      ),
                    ),
                  ),
                );
              }),
            ),
            if (_message != null) ...[
              const SizedBox(height: 10),
              Text(
                _message!,
                style: _S.bodySm.copyWith(
                  color: _messageIsError ? _S.error : _S.secondary,
                ),
              ),
            ],
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x40173628),
                    blurRadius: 16,
                    spreadRadius: -2,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _busy ? null : _verify,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _S.primaryContainer,
                  disabledBackgroundColor: _S.primaryContainer.withOpacity(0.7),
                  foregroundColor: Colors.white,
                  disabledForegroundColor: Colors.white,
                  elevation: 0,
                  minimumSize: const Size(double.infinity, 48),
                  shape: const StadiumBorder(),
                ),
                child: _busy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'Verify email',
                        style: _S.labelLg.copyWith(color: Colors.white),
                      ),
              ),
            ),
            Center(
              child: TextButton(
                onPressed: (_busy || _resendIn > 0) ? null : _resend,
                style: TextButton.styleFrom(
                  foregroundColor: _S.primary,
                  disabledForegroundColor: _S.outline,
                  textStyle: _S.labelLg,
                ),
                child: Text(
                  _resendIn > 0
                      ? 'Resend code in 0:${_resendIn.toString().padLeft(2, '0')}'
                      : 'Resend code',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

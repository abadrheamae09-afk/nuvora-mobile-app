// ============================================================
// otp_verification_screen.dart
// Email verification code screen used after buyer registration.
// Verifies through the Nuvora API (`email/otp/verify`); the caller
// creates the account once this screen returns true.
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/api/buyer_api.dart';
import '../dashboard/mockup_screens/mockup_theme.dart';
import '../dashboard/mockup_screens/mockup_widgets.dart';

class MockupOtpVerificationScreen extends StatefulWidget {
  const MockupOtpVerificationScreen({
    super.key,
    required this.email,
    this.isPasswordReset = false,
  });

  final String email;

  /// True when arriving from forgot-password flow.
  final bool isPasswordReset;

  @override
  State<MockupOtpVerificationScreen> createState() =>
      _MockupOtpVerificationScreenState();
}

class _MockupOtpVerificationScreenState
    extends State<MockupOtpVerificationScreen> {
  final List<TextEditingController> _ctrls =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _nodes = List.generate(6, (_) => FocusNode());
  bool _loading = false;
  int _resendCountdown = 30;
  bool _canResend = false;
  String? _message;
  bool _messageIsError = false;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    for (final c in _ctrls) {
      c.dispose();
    }
    for (final n in _nodes) {
      n.dispose();
    }
    super.dispose();
  }

  void _startCountdown() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() {
        _resendCountdown--;
        if (_resendCountdown <= 0) _canResend = true;
      });
      return _resendCountdown > 0;
    });
  }

  void _onDigitChanged(String value, int index) {
    if (_messageIsError) setState(() => _message = null);
    if (value.length == 1 && index < 5) {
      _nodes[index + 1].requestFocus();
    }
    if (value.isEmpty && index > 0) {
      _nodes[index - 1].requestFocus();
    }
  }

  String get _otp => _ctrls.map((c) => c.text).join();

  /// A pasted code fills the boxes instead of being squeezed into one.
  Future<void> _pasteCode(int index) async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final digits = (data?.text ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.length < 2) return;

    setState(() {
      for (var i = 0; i < _ctrls.length; i++) {
        final digitIndex = i - index;
        _ctrls[i].text =
            digitIndex >= 0 && digitIndex < digits.length
                ? digits[digitIndex]
                : _ctrls[i].text;
      }
      _message = null;
    });
    final next = (index + digits.length).clamp(0, _nodes.length - 1);
    _nodes[next].requestFocus();
  }

  Future<void> _verify() async {
    if (_otp.length < 6 || _loading) {
      setState(() {
        _message = 'Enter the 6-digit code from your email.';
        _messageIsError = true;
      });
      return;
    }

    setState(() {
      _loading = true;
      _message = null;
    });
    try {
      await BuyerApi.instance.verifyEmailCode(widget.email, _otp);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on BuyerApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _message = error.message;
        _messageIsError = true;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _message = 'Could not verify the code: $error';
        _messageIsError = true;
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resend() async {
    if (!_canResend || _loading) return;

    setState(() {
      _loading = true;
      _message = null;
    });
    try {
      await BuyerApi.instance.sendEmailCode(widget.email);
      if (!mounted) return;
      for (final c in _ctrls) {
        c.clear();
      }
      _nodes.first.requestFocus();
      setState(() {
        _canResend = false;
        _resendCountdown = 30;
        _message = 'A new code was sent to ${widget.email}.';
        _messageIsError = false;
      });
      _startCountdown();
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
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MColors.background,
      appBar: AppBar(
        backgroundColor: MColors.background,
        elevation: 0,
        foregroundColor: MColors.ink,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              Container(
                width: 90,
                height: 90,
                decoration: const BoxDecoration(
                  color: MColors.primarySoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.mark_email_unread_outlined,
                  size: 44,
                  color: MColors.primary,
                ),
              ),
              const SizedBox(height: 28),
              Text(
                widget.isPasswordReset
                    ? 'Reset Password'
                    : 'Verify Your Email',
                style: MTextStyles.headline,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'Enter the 6-digit code sent to\n${widget.email}',
                style: MTextStyles.body.copyWith(color: MColors.muted),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 36),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (i) => _buildBox(i)),
              ),
              if (_message != null) ...[
                const SizedBox(height: 12),
                Text(
                  _message!,
                  textAlign: TextAlign.center,
                  style: MTextStyles.caption.copyWith(
                    fontSize: 13,
                    color: _messageIsError ? MColors.danger : MColors.primary,
                  ),
                ),
              ],
              const SizedBox(height: 28),
              MPrimaryButton(
                label: 'Verify',
                onPressed: _verify,
                isLoading: _loading,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Didn't receive code? ",
                    style: MTextStyles.caption.copyWith(fontSize: 13),
                  ),
                  GestureDetector(
                    onTap: _canResend && !_loading ? _resend : null,
                    child: Text(
                      _canResend
                          ? 'Resend'
                          : 'Resend in ${_resendCountdown}s',
                      style: MTextStyles.caption.copyWith(
                        fontSize: 13,
                        color: _canResend && !_loading
                            ? MColors.primary
                            : MColors.muted,
                        fontWeight: _canResend && !_loading
                            ? FontWeight.w700
                            : FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBox(int index) {
    return SizedBox(
      width: 48,
      height: 58,
      child: TextFormField(
        controller: _ctrls[index],
        focusNode: _nodes[index],
        autofocus: index == 0,
        textAlign: TextAlign.center,
        maxLength: 1,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: MTextStyles.title.copyWith(fontSize: 22),
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: MColors.primarySoft,
          contentPadding: EdgeInsets.zero,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: MColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: MColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: MColors.primary, width: 2),
          ),
        ),
        onChanged: (v) => _onDigitChanged(v, index),
        onTap: () => _pasteCode(index),
        onFieldSubmitted: (_) => _verify(),
      ),
    );
  }
}

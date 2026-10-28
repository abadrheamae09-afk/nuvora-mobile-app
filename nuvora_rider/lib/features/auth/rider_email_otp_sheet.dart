import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/api/rider_api.dart';
import '../../theme/app_colors.dart';

class RiderEmailOtpSheet extends StatefulWidget {
  const RiderEmailOtpSheet({required this.email, super.key});

  final String email;

  @override
  State<RiderEmailOtpSheet> createState() => _RiderEmailOtpSheetState();
}

class _RiderEmailOtpSheetState extends State<RiderEmailOtpSheet> {
  late final List<TextEditingController> _digits;
  late final List<FocusNode> _digitFocus;
  bool _busy = false;
  String? _message;
  bool _messageIsError = false;

  @override
  void initState() {
    super.initState();
    _digits = List.generate(6, (_) => TextEditingController());
    _digitFocus = List.generate(6, (_) => FocusNode());
  }

  @override
  void dispose() {
    for (final controller in _digits) {
      controller.dispose();
    }
    for (final node in _digitFocus) {
      node.dispose();
    }
    super.dispose();
  }

  String get _enteredCode => _digits.map((digit) => digit.text).join();

  Future<void> _verify() async {
    if (_enteredCode.length != 6 || _busy) {
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
      await RiderApi.instance.verifyEmailCode(widget.email, _enteredCode);
      if (mounted) Navigator.of(context).pop(true);
    } on RiderApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _message = error.message;
        _messageIsError = true;
      });
    } on FormatException catch (error) {
      if (!mounted) return;
      setState(() {
        _message = 'Server returned an invalid response: ${error.message}';
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

  void _fillFrom(int start, String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return;
    for (var index = start; index < _digits.length; index++) {
      final digitIndex = index - start;
      _digits[index].text = digitIndex < digits.length
          ? digits[digitIndex]
          : '';
    }
    final nextIndex = (start + digits.length).clamp(0, _digitFocus.length - 1);
    _digitFocus[nextIndex].requestFocus();
  }

  Future<void> _pasteCodeFromClipboard(int index) async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final pasted = data?.text ?? '';
    if (pasted.replaceAll(RegExp(r'\D'), '').length > 1) {
      _fillFrom(index, pasted);
    }
  }

  Future<void> _resend() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await RiderApi.instance.sendEmailCode(widget.email);
      if (!mounted) return;
      for (final digit in _digits) {
        digit.clear();
      }
      _digitFocus.first.requestFocus();
      setState(() {
        _message = 'A new verification code was sent.';
        _messageIsError = false;
      });
    } on RiderApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _message = error.message;
        _messageIsError = true;
      });
    } on FormatException catch (error) {
      if (!mounted) return;
      setState(() {
        _message = 'Server returned an invalid response: ${error.message}';
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
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Verify your email',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Enter the 6-digit code sent to ${widget.email}.',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.muted,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(6, (index) {
                return SizedBox(
                  width: 46,
                  child: TextField(
                    controller: _digits[index],
                    focusNode: _digitFocus[index],
                    autofocus: index == 0,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 1,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(1),
                    ],
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                    ),
                    decoration: const InputDecoration(
                      counterText: '',
                      contentPadding: EdgeInsets.symmetric(vertical: 12),
                    ),
                    onChanged: (value) {
                      if (_messageIsError) setState(() => _message = null);
                      if (value.length > 1) {
                        _fillFrom(index, value);
                      } else if (value.isNotEmpty &&
                          index < _digitFocus.length - 1) {
                        _digitFocus[index + 1].requestFocus();
                      } else if (value.isEmpty && index > 0) {
                        _digitFocus[index - 1].requestFocus();
                      } else if (value.isNotEmpty && index == 5) {
                        _digitFocus[index].unfocus();
                      }
                    },
                    onTap: () => _pasteCodeFromClipboard(index),
                    onSubmitted: (_) => _verify(),
                  ),
                );
              }),
            ),
            if (_message != null) ...[
              const SizedBox(height: 8),
              Text(
                _message!,
                style: TextStyle(
                  fontSize: 12.5,
                  color: _messageIsError
                      ? AppColors.danger
                      : AppColors.primaryDark,
                ),
              ),
            ],
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _busy ? null : _verify,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _busy
                    ? const SizedBox(
                        width: 19,
                        height: 19,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Verify email',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
              ),
            ),
            Center(
              child: TextButton(
                onPressed: _busy ? null : _resend,
                child: const Text('Resend code'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

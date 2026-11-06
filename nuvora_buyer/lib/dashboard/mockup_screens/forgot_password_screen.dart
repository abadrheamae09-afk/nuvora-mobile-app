// ============================================================
// forgot_password_screen.dart
// Forgot-password flow mockup (email entry step).
// ============================================================

import 'package:flutter/material.dart';
import 'mockup_theme.dart';
import 'mockup_widgets.dart';
import '../../../auth/otp_verification_screen.dart';

class MockupForgotPasswordScreen extends StatefulWidget {
  const MockupForgotPasswordScreen({super.key});

  @override
  State<MockupForgotPasswordScreen> createState() =>
      _MockupForgotPasswordScreenState();
}

class _MockupForgotPasswordScreenState
    extends State<MockupForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController(text: 'juan@example.com');
  bool _loading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  void _send() {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() => _loading = false);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MockupOtpVerificationScreen(
            email: _emailCtrl.text,
            isPasswordReset: true,
          ),
        ),
      );
    });
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
        child: Form(
          key: _formKey,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                // Illustration
                Center(
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: MColors.primarySoft,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lock_reset_rounded,
                      size: 44,
                      color: MColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                const Text(
                  'Forgot Password?',
                  style: MTextStyles.headline,
                ),
                const SizedBox(height: 8),
                Text(
                  "Enter the email address linked to your account. We'll send you a verification code.",
                  style: MTextStyles.body.copyWith(color: MColors.muted),
                ),
                const SizedBox(height: 32),
                MTextField(
                  controller: _emailCtrl,
                  label: 'Email Address',
                  hint: 'you@example.com',
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) =>
                      (v == null || !v.contains('@'))
                          ? 'Enter a valid email'
                          : null,
                ),
                const SizedBox(height: 32),
                MPrimaryButton(
                  label: 'Send Code',
                  onPressed: _send,
                  isLoading: _loading,
                  icon: Icons.send_outlined,
                ),
                const SizedBox(height: 24),
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      foregroundColor: MColors.muted,
                    ),
                    child: const Text('Back to Sign In'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

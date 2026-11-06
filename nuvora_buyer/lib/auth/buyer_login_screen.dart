// ============================================================
// buyer_login_screen.dart
// Buyer-only login screen mockup.
// Hardcoded dummy data. No real auth logic.
// Redesigned UI: "Botanical Boutique" (forest green header,
// floating white card, pill buttons). Routing/logic unchanged.
// ============================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/api/buyer_api.dart';
import 'buyer_register_screen.dart';
import '../dashboard/mockup_screens/forgot_password_screen.dart';
import '../dashboard/mockup_screens/home_screen.dart';

// ── Design tokens for this screen (from the redesign) ───────
class _LColors {
  static const forest = Color(0xFF143628);
  static const forestDark = Color(0xFF0D251B);
  static const forestLight = Color(0xFF1E4837);
  static const pageBg = Color(0xFFF3F7F4);
  static const fieldBg = Color(0xFFF1F6F3);
  static const footerChipBg = Color(0xFFE4ECE6);
  static const footerChipBorder = Color(0xFFD2DED5);
  static const mintText = Color(0xFFA7F3D0); // emerald-200
  static const mintIcon = Color(0xFF6EE7B7); // emerald-300
  static const mintDot = Color(0xFF34D399); // emerald-400
  static const label = Color(0xFF374151);
  static const hint = Color(0xFF9CA3AF);
  static const border = Color(0xFFE5E7EB);
  static const title = Color(0xFF111827);
  static const subtitle = Color(0xFF6B7280);
}

class MockupBuyerLoginScreen extends StatefulWidget {
  const MockupBuyerLoginScreen({super.key});

  @override
  State<MockupBuyerLoginScreen> createState() => _MockupBuyerLoginScreenState();
}

class _MockupBuyerLoginScreenState extends State<MockupBuyerLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _error;
  bool _remember = true; // design-only checkbox state

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await BuyerApi.instance.login(_emailCtrl.text, _passwordCtrl.text);
      if (!mounted) return;
      setState(() => _loading = false);
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MockupHomeScreen()),
      );
    } on BuyerApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.message;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not sign in: $error';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _LColors.pageBg,
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(context),
                // Floating login card overlapping the header
                Transform.translate(
                  offset: const Offset(0, -12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _buildCard(),
                  ),
                ),
                _buildFooter(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Header (forest green, rounded bottom) ─────────────────
  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 40,
        bottom: 48,
        left: 24,
        right: 24,
      ),
      decoration: const BoxDecoration(
        color: _LColors.forest,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(40)),
        boxShadow: [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Small pill indicator
          Container(
            width: 28,
            height: 6,
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.3),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(height: 24),
          // Logo + wordmark
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _LColors.forestLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.shopping_bag_outlined,
                  size: 20,
                  color: _LColors.mintIcon,
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'NUVORA',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                          height: 1,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: _LColors.mintDot,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'CURATED MARKETPLACE',
                    style: GoogleFonts.plusJakartaSans(
                      color: _LColors.mintText.withOpacity(0.8),
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.6,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Tagline
          Text(
            'Shop mindfully.',
            textAlign: TextAlign.center,
            style: GoogleFonts.playfairDisplay(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Discover rare.',
            textAlign: TextAlign.center,
            style: GoogleFonts.playfairDisplay(
              color: _LColors.mintText,
              fontSize: 20,
              fontWeight: FontWeight.w600,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  // ── White login card ──────────────────────────────────────
  Widget _buildCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0x0D022C22)),
        boxShadow: [
          BoxShadow(
            color: _LColors.forest.withOpacity(0.06),
            blurRadius: 30,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome back buyer',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: _LColors.title,
              letterSpacing: -0.4,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Enter your credentials to access your account',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: _LColors.subtitle,
            ),
          ),
          const SizedBox(height: 20),

          // Email field
          _fieldLabel('Email address'),
          const SizedBox(height: 6),
          _buildField(
            controller: _emailCtrl,
            hint: 'you@example.com',
            prefixIcon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Enter your email' : null,
          ),
          const SizedBox(height: 16),

          // Password field
          _fieldLabel('Password'),
          const SizedBox(height: 6),
          _buildField(
            controller: _passwordCtrl,
            hint: '••••••••',
            prefixIcon: Icons.lock_outline_rounded,
            obscureText: _obscure,
            suffixIcon: IconButton(
              icon: Icon(
                _obscure
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: 18,
                color: _obscure ? _LColors.hint : _LColors.forest,
              ),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
            validator: (v) =>
                (v == null || v.isEmpty) ? 'Enter your password' : null,
          ),
          const SizedBox(height: 14),

          // Remember me + Forgot password
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () => setState(() => _remember = !_remember),
                behavior: HitTestBehavior.opaque,
                child: Row(
                  children: [
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: Checkbox(
                        value: _remember,
                        onChanged: (v) =>
                            setState(() => _remember = v ?? false),
                        activeColor: _LColors.forest,
                        checkColor: Colors.white,
                        side: const BorderSide(
                            color: Color(0xFFD1D5DB), width: 1.2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Remember me',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: _LColors.label,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const MockupForgotPasswordScreen(),
                  ),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: _LColors.forest,
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Forgot password?',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 14),
            Text(
              _error!,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFBA1A1A),
              ),
            ),
          ],
          const SizedBox(height: 18),

          // Sign in button (pill)
          _buildSignInButton(),
          const SizedBox(height: 20),

          // Divider
          Row(
            children: [
              const Expanded(child: Divider(color: _LColors.border)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'OR CONTINUE WITH',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.4,
                    color: _LColors.hint,
                  ),
                ),
              ),
              const Expanded(child: Divider(color: _LColors.border)),
            ],
          ),
          const SizedBox(height: 20),

          // Social buttons (mockup only)
          Row(
            children: [
              Expanded(
                child: _socialButton(
                  label: 'Google',
                  icon: Text(
                    'G',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF4285F4),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _socialButton(
                  label: 'Apple',
                  icon: const Icon(Icons.apple, size: 18, color: Colors.black),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Footer ────────────────────────────────────────────────
  Widget _buildFooter(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        20,
        24,
        MediaQuery.of(context).padding.bottom + 24,
      ),
      child: Column(
        children: [
          // Register link
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'New to Nuvora? ',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF4B5563),
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const MockupBuyerRegisterScreen(),
                  ),
                ),
                child: Text(
                  'Create an account',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _LColors.forest,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Zero-emission badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: _LColors.footerChipBg,
              border: Border.all(color: _LColors.footerChipBorder),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🌱', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    '100% Zero-emission courier delivery powered by Nuvora Fleet',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _LColors.forestDark,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Reusable pieces ───────────────────────────────────────
  Widget _fieldLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: _LColors.label,
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData prefixIcon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c, width: w),
        );

    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      cursorColor: _LColors.forest,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: const Color(0xFF1F2937),
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: _LColors.hint,
        ),
        filled: true,
        fillColor: _LColors.fieldBg,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        prefixIcon: Icon(prefixIcon, size: 18, color: _LColors.hint),
        prefixIconConstraints:
            const BoxConstraints(minWidth: 44, minHeight: 20),
        suffixIcon: suffixIcon,
        suffixIconConstraints:
            const BoxConstraints(minWidth: 44, minHeight: 20),
        enabledBorder: border(_LColors.border),
        focusedBorder: border(_LColors.forest, 1.5),
        errorBorder: border(const Color(0xFFBA1A1A)),
        focusedErrorBorder: border(const Color(0xFFBA1A1A), 1.5),
      ),
    );
  }

  Widget _buildSignInButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _loading ? null : _login,
        style: ElevatedButton.styleFrom(
          backgroundColor: _LColors.forest,
          disabledBackgroundColor: _LColors.forest.withOpacity(0.7),
          foregroundColor: Colors.white,
          elevation: 6,
          shadowColor: _LColors.forest.withOpacity(0.3),
          shape: const StadiumBorder(),
        ),
        child: _loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Sign in to Shop',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded, size: 18),
                ],
              ),
      ),
    );
  }

  Widget _socialButton({required String label, required Widget icon}) {
    return OutlinedButton(
      onPressed: () {},
      style: OutlinedButton.styleFrom(
        foregroundColor: _LColors.label,
        backgroundColor: Colors.white,
        side: const BorderSide(color: _LColors.border),
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          icon,
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _LColors.label,
            ),
          ),
        ],
      ),
    );
  }
}
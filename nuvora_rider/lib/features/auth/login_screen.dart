import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/api/rider_api.dart';
import '../../core/data/rider_session.dart';
import '../dashboard/dashboard_screen.dart';
import 'register_screen.dart';

/// Colours taken from the redesign (stitch_mobile_app_redesign).
class _Palette {
  static const forest = Color(0xFF143224);
  static const forestMid = Color(0xFF17412E);
  static const emerald = Color(0xFF15803D);
  static const mint = Color(0xFF6EE7B7);
  static const tint = Color(0xFFF3FCF5);
  static const darkText = Color(0xFF102217);
  static const muted = Color(0xFF627C6E);
  static const fieldBorder = Color(0xFFE2E8F0);
  static const hint = Color(0xFF94A3B8);
  static const error = Color(0xFFBA1A1A);
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.animateEntrance = true});

  /// The splash screen hands over without a second entrance animation.
  final bool animateEntrance;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;
  bool _signingIn = false;

  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  String? _emailError;
  String? _passwordError;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Logic & routing: unchanged from the original screen.
  // ---------------------------------------------------------------------------

  Future<void> _signIn() async {
    final email = _emailCtrl.text.trim();
    setState(() {
      _emailError = email.isEmpty
          ? 'Enter your email address.'
          : (!_emailPattern.hasMatch(email)
                ? 'Enter a valid email address.'
                : null);
      _passwordError = _passwordCtrl.text.isEmpty
          ? 'Enter your password.'
          : null;
    });
    if (_emailError != null || _passwordError != null) return;

    setState(() => _signingIn = true);
    try {
      final rider = await RiderApi.instance.login(email, _passwordCtrl.text);
      RiderSession.instance.adopt(rider);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    } on RiderApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(
            content: Text('Could not connect to Nuvora. Please try again.'),
          ),
        );
    } finally {
      if (mounted) setState(() => _signingIn = false);
    }
  }

  void _goToRegister() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const RegisterScreen()));
  }

  void _forgotPassword() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Password reset will be available soon.')),
    );
  }

  void _continueWithGoogle() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Google sign-in will be connected to your backend.'),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Design
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final form = _buildForm();

    return Scaffold(
      backgroundColor: _Palette.tint,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: widget.animateEntrance
            ? TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: 1),
                duration: const Duration(milliseconds: 420),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) => Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 18 * (1 - value)),
                    child: child,
                  ),
                ),
                child: form,
              )
            : form,
      ),
    );
  }

  Widget _buildForm() {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Header(),
          Padding(
            padding: EdgeInsets.fromLTRB(24, 28, 24, 20 + bottomInset),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Welcome back',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    color: _Palette.darkText,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Sign in to start accepting deliveries.',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _Palette.muted,
                  ),
                ),
                const SizedBox(height: 24),
                _label('Email address'),
                const SizedBox(height: 8),
                TextField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  style: _inputTextStyle,
                  decoration: _fieldDecoration(
                    hint: 'rider@email.com',
                    icon: Icons.mail_outline_rounded,
                    error: _emailError,
                  ),
                ),
                const SizedBox(height: 16),
                _label('Password'),
                const SizedBox(height: 8),
                TextField(
                  controller: _passwordCtrl,
                  obscureText: _obscure,
                  style: _inputTextStyle,
                  decoration: _fieldDecoration(
                    hint: '••••••••',
                    icon: Icons.lock_outline_rounded,
                    error: _passwordError,
                    suffix: IconButton(
                      tooltip: _obscure ? 'Show password' : 'Hide password',
                      onPressed: () => setState(() => _obscure = !_obscure),
                      icon: Icon(
                        _obscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: 20,
                        color: _Palette.hint,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _forgotPassword,
                    style: TextButton.styleFrom(
                      foregroundColor: _Palette.emerald,
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    child: const Text('Forgot password?'),
                  ),
                ),
                const SizedBox(height: 8),
                _buildSignInButton(),
                const SizedBox(height: 22),
                const _OrDivider(),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: OutlinedButton.icon(
                    onPressed: _continueWithGoogle,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _Palette.darkText,
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: _Palette.fieldBorder),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    icon: const _GoogleMark(),
                    label: const Text('Continue with Google'),
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'New rider?',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: _Palette.muted,
                      ),
                    ),
                    TextButton(
                      onPressed: _goToRegister,
                      style: TextButton.styleFrom(
                        foregroundColor: _Palette.forest,
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                      child: const Text('Create an account'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.verified_user_outlined,
                      size: 15,
                      color: _Palette.emerald,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Secure Rider Portal',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _Palette.hint,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignInButton() {
    const radius = BorderRadius.all(Radius.circular(16));

    return Opacity(
      opacity: _signingIn ? 0.85 : 1,
      child: Container(
        height: 54,
        decoration: const BoxDecoration(
          borderRadius: radius,
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [_Palette.forest, _Palette.emerald],
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0x33052E16),
              blurRadius: 16,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: radius,
            onTap: _signingIn ? null : _signIn,
            child: Center(
              child: _signingIn
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Sign in',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 18,
                          color: Colors.white,
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  static const _inputTextStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: _Palette.darkText,
  );

  InputDecoration _fieldDecoration({
    required String hint,
    required IconData icon,
    String? error,
    Widget? suffix,
  }) {
    OutlineInputBorder border(Color color, [double width = 1]) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: color, width: width),
      );
    }

    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: _Palette.hint,
      ),
      prefixIcon: Icon(icon, size: 20, color: _Palette.hint),
      suffixIcon: suffix,
      errorText: error,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: border(_Palette.fieldBorder),
      enabledBorder: border(_Palette.fieldBorder),
      focusedBorder: border(_Palette.forest, 1.5),
      errorBorder: border(_Palette.error),
      focusedErrorBorder: border(_Palette.error, 1.5),
    );
  }

  Widget _label(String text) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.8,
        color: _Palette.darkText,
      ),
    );
  }
}

/// Deep forest masthead with the rider brand, full-bleed to the top edge.
class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_Palette.forest, _Palette.forestMid, _Palette.emerald],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x33143224),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          const Positioned(
            right: -70,
            top: -70,
            child: _Glow(size: 240, color: Color(0x4034D399)),
          ),
          const Positioned(
            left: -60,
            bottom: -50,
            child: _Glow(size: 190, color: Color(0x3310B981)),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(24, top + 28, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(38),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withAlpha(64)),
                      ),
                      child: const Icon(
                        Icons.pedal_bike_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Nuvora Rider',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFF34D399),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'ZERO EMISSION FLEET',
                          style: TextStyle(
                            color: const Color(0xFFA7F3D0).withAlpha(230),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 26),
                const Text(
                  'Deliver more.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    height: 1.2,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.6,
                  ),
                ),
                const Text(
                  'Earn greener.',
                  style: TextStyle(
                    color: _Palette.mint,
                    fontSize: 32,
                    height: 1.2,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.6,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Track parcels and payouts in one unified hub.',
                  style: TextStyle(
                    color: const Color(0xFFD1FAE5).withAlpha(217),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
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
}

/// Soft radial glow used as a decorative blob in the header.
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

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(child: Divider(color: _Palette.fieldBorder)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'OR',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: _Palette.hint,
            ),
          ),
        ),
        Expanded(child: Divider(color: _Palette.fieldBorder)),
      ],
    );
  }
}

/// Multicolour "G" mark. Swap for an SVG/PNG asset if you have the official one.
class _GoogleMark extends StatelessWidget {
  const _GoogleMark();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 22,
      height: 22,
      child: Center(
        child: ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) => const SweepGradient(
            colors: [
              Color(0xFF4285F4),
              Color(0xFF34A853),
              Color(0xFFFBBC05),
              Color(0xFFEA4335),
              Color(0xFF4285F4),
            ],
            stops: [0.0, 0.3, 0.5, 0.75, 1.0],
          ).createShader(bounds),
          child: const Text(
            'G',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1,
            ),
          ),
        ),
      ),
    );
  }
}
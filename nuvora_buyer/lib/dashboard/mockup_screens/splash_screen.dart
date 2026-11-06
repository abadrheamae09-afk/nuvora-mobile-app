// ============================================================
// splash_screen.dart
// Nuvora Buyer splash / brand intro screen.
// Shows the logo and tagline with a brief animation, then
// navigates to the login screen.
// Design: "Botanical Boutique" (deep forest green, sage halos,
// Playfair Display wordmark).
// Routing is unchanged — only the visuals and timing were updated.
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../auth/buyer_login_screen.dart';
import '../../../core/api/buyer_api.dart';
import 'home_screen.dart';

// How long the splash stays up before going to the login screen.
// The staggered entrance takes ~3.2 s; the rest is hold time so the
// loader bar (2.5 s per sweep, 3 full sweeps) and glow can finish
// smoothly before navigating.
const Duration _kSplashDuration = Duration(milliseconds: 7500);
const Duration _kEntranceDuration = Duration(milliseconds: 3200);

// ── Design tokens (from the redesign) ───────────────────────
class _N {
  static const primaryContainer = Color(0xFF173628); // deep forest pine
  static const primary = Color(0xFF012114);
  static const secondary = Color(0xFF44664B);
  static const secondaryFixed = Color(0xFFC5ECCA);
  static const primaryFixed = Color(0xFFC7EBD6);
  static const primaryFixedDim = Color(0xFFACCEBA);

  // Register these families in pubspec.yaml (or swap for google_fonts).
  // If they are not registered, Flutter falls back to the default font.
  static const serifFamily = 'PlayfairDisplay';
  static const sansFamily = 'PlusJakartaSans';
}

class MockupSplashScreen extends StatefulWidget {
  const MockupSplashScreen({super.key});

  @override
  State<MockupSplashScreen> createState() => _MockupSplashScreenState();
}

class _MockupSplashScreenState extends State<MockupSplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _ctrl; // one-shot staggered entrance
  late final AnimationController _halo; // slow ambient pulse (loops)
  late final AnimationController _bar; // loader sweep + ping dot (loops)

  late final Animation<double> _emblem;
  late final Animation<double> _wordmark;
  late final Animation<double> _badge;
  late final Animation<double> _tagline;
  late final Animation<double> _footer;

  Animation<double> _interval(double begin, double end) => CurvedAnimation(
        parent: _ctrl,
        curve: Interval(begin, end, curve: Curves.easeOutCubic),
      );

  @override
  void initState() {
    super.initState();

    _ctrl = AnimationController(vsync: this, duration: _kEntranceDuration)
      ..forward();
    _halo = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3750),
    )..repeat(reverse: true);
    _bar = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();

    _emblem = _interval(0.00, 0.45);
    _wordmark = _interval(0.22, 0.60);
    _badge = _interval(0.40, 0.75);
    _tagline = _interval(0.52, 0.88);
    _footer = _interval(0.65, 1.00);

    // Auto-navigate once the animations have had time to play
    Future.delayed(_kSplashDuration, _openNextScreen);
  }

  /// Opens the dashboard for a buyer who is still signed in, otherwise login.
  Future<void> _openNextScreen() async {
    if (!mounted) return;

    Map<String, dynamic>? saved;
    try {
      saved = await BuyerApi.instance.restoreSession();
    } catch (_) {
      saved = null;
    }
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => saved != null
            ? const MockupHomeScreen()
            : const MockupBuyerLoginScreen(),
      ),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _halo.dispose();
    _bar.dispose();
    super.dispose();
  }

  // Fade + gentle upward slide for a staggered entrance step.
  Widget _reveal(Animation<double> anim, Widget child,
      {double dy = 0.25}) {
    return FadeTransition(
      opacity: anim,
      child: SlideTransition(
        position: Tween<Offset>(begin: Offset(0, dy), end: Offset.zero)
            .animate(anim),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _N.primaryContainer,
        body: SizedBox.expand(
          child: Stack(
            children: [
              // ── Atmospheric background ─────────────────
              const Positioned.fill(
                child: ColoredBox(color: _N.primaryContainer),
              ),
              _buildGlow(
                top: -112,
                right: -96,
                size: 320,
                color: _N.secondary,
                alpha: 0.30,
                pulse: true,
              ),
              _buildGlow(
                top: MediaQuery.of(context).size.height * 0.33,
                left: -128,
                size: 384,
                color: _N.primary,
                alpha: 0.40,
              ),
              _buildGlow(
                bottom: -80,
                left: MediaQuery.of(context).size.width * 0.25,
                size: 288,
                color: const Color(0xFFC2E9C7),
                alpha: 0.10,
              ),
              const Positioned.fill(
                child: CustomPaint(painter: _DotPatternPainter()),
              ),

              // ── Content ────────────────────────────────
              SafeArea(
                child: Column(
                  children: [
                    Expanded(
                      child: Center(
                        child: Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _reveal(_emblem, _buildEmblem(), dy: 0.15),
                              const SizedBox(height: 24),
                              _reveal(_wordmark, _buildWordmark()),
                              const SizedBox(height: 14),
                              _reveal(_badge, _buildBadge()),
                              const SizedBox(height: 20),
                              _reveal(_tagline, _buildTagline()),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Loader
                    FadeTransition(
                      opacity: _footer,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 40),
                        child: _buildLoaderBar(),
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

  // Soft radial glow (stand-in for the design's blurred circles).
  Widget _buildGlow({
    double? top,
    double? bottom,
    double? left,
    double? right,
    required double size,
    required Color color,
    required double alpha,
    bool pulse = false,
  }) {
    Widget glow = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withOpacity(alpha),
            color.withOpacity(0),
          ],
        ),
      ),
    );

    if (pulse) {
      glow = AnimatedBuilder(
        animation: _halo,
        builder: (_, child) => Opacity(
          opacity: 0.55 + 0.45 * _halo.value,
          child: Transform.scale(
            scale: 0.98 + 0.04 * _halo.value,
            child: child,
          ),
        ),
        child: glow,
      );
    }

    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: IgnorePointer(child: glow),
    );
  }

  // ── Emblem: ringed disc with shopping bag + leaf accent ──
  Widget _buildEmblem() {
    return SizedBox(
      width: 150,
      height: 150,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Pulsing halo
          AnimatedBuilder(
            animation: _halo,
            builder: (_, __) => Transform.scale(
              scale: 1.1 + 0.1 * _halo.value,
              child: Container(
                width: 112,
                height: 112,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      _N.secondaryFixed
                          .withOpacity(0.12 + 0.14 * _halo.value),
                      _N.secondaryFixed.withOpacity(0),
                    ],
                    stops: const [0.5, 1.0],
                  ),
                ),
              ),
            ),
          ),
          // Outer ring
          Container(
            width: 112,
            height: 112,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _N.primaryContainer.withOpacity(0.8),
              border: Border.all(
                color: _N.secondaryFixed.withOpacity(0.25),
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x99012114),
                  blurRadius: 36,
                  offset: Offset(0, 12),
                ),
              ],
            ),
            alignment: Alignment.center,
            // Inner disc
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    _N.secondary.withOpacity(0.4),
                    _N.primaryContainer,
                  ],
                ),
                border: Border.all(
                  color: _N.secondaryFixed.withOpacity(0.3),
                ),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  const Icon(
                    Icons.shopping_bag_outlined,
                    size: 38,
                    color: _N.secondaryFixed,
                    shadows: [
                      Shadow(
                        color: Color(0x59C5ECCA),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  // Leaf accent dot
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        color: _N.primaryFixed,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x40000000),
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.eco,
                          size: 14, color: _N.primary),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWordmark() {
    return const Padding(
      // balances the trailing letter-spacing so the word looks centered
      padding: EdgeInsets.only(left: 6.6),
      child: Text(
        'NUVORA',
        style: TextStyle(
          fontFamily: _N.serifFamily,
          fontSize: 30,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          letterSpacing: 6.6,
          height: 1.3,
          shadows: [Shadow(color: Color(0x33000000), blurRadius: 2)],
        ),
      ),
    );
  }

  Widget _buildBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: _N.secondary.withOpacity(0.2),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: _N.secondaryFixed.withOpacity(0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // "Ping" dot
          SizedBox(
            width: 12,
            height: 12,
            child: AnimatedBuilder(
              animation: _bar,
              builder: (_, __) {
                final t = (_bar.value * 2) % 1.0; // ~1.3 s cycle
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    Transform.scale(
                      scale: 1 + t * 1.6,
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _N.secondaryFixed
                              .withOpacity(0.7 * (1 - t)),
                        ),
                      ),
                    ),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: _N.secondaryFixed,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'CURATED MARKETPLACE',
            style: TextStyle(
              fontFamily: _N.sansFamily,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: _N.secondaryFixed,
              letterSpacing: 2.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagline() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 280),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: 'Everything You Need,\n',
              style: TextStyle(
                fontFamily: _N.sansFamily,
                fontSize: 15,
                color: _N.primaryFixedDim.withOpacity(0.9),
                height: 1.6,
              ),
            ),
            const TextSpan(
              text: 'All in One Place',
              style: TextStyle(
                fontFamily: _N.serifFamily,
                fontSize: 18,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w500,
                color: _N.secondaryFixed,
                height: 1.5,
              ),
            ),
          ],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  // Sweeping light bar (replaces the circular spinner).
  Widget _buildLoaderBar() {
    const trackW = 160.0;
    const glowW = 64.0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: trackW,
        height: 3,
        color: _N.secondary.withOpacity(0.3),
        child: AnimatedBuilder(
          animation: _bar,
          builder: (_, __) {
            final t = Curves.easeInOut.transform(_bar.value);
            final dx = -glowW + t * (trackW + glowW);
            return Stack(
              children: [
                Positioned(
                  left: dx,
                  top: 0,
                  bottom: 0,
                  width: glowW,
                  child: const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0x00C5ECCA),
                          _N.secondaryFixed,
                          Color(0x00C5ECCA),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Very subtle dotted texture over the background.
class _DotPatternPainter extends CustomPainter {
  const _DotPatternPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _N.primaryFixed.withOpacity(0.04);
    const step = 24.0;
    for (double y = 0; y < size.height; y += step) {
      for (double x = 0; x < size.width; x += step) {
        canvas.drawCircle(Offset(x, y), 0.8, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
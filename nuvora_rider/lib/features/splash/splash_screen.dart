import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/api/rider_api.dart';
import '../../core/data/rider_session.dart';
import '../../theme/app_colors.dart';
import '../auth/login_screen.dart';
import '../dashboard/dashboard_screen.dart';

/// Colours taken from the redesign (stitch_mobile_app_redesign).
class _Palette {
  static const primary = Color(0xFF001D10); // deep forest background
  static const secondary = Color(0xFF006C49);
  static const mint = Color(0xFF6FFBBE);
  static const emblemFill = Color(0xFF0C1C14);
  static const pillFill = Color(0xFF11271B);
  static const motto = Color(0xFFE2EAE4);
  static const metaText = Color(0xFF7B9B88);
  static const metaFaint = Color(0xFFC2C8C2);
}

/// How long the splash stays on screen before moving on.
const Duration _kSplashDuration = Duration(milliseconds: 8000);

/// How long the progress bar takes to fill. Shorter than the splash so the
/// full bar and "READY TO RIDE" stay visible for a moment before moving on.
const Duration _kProgressDuration = Duration(milliseconds: 6800);

/// Minimal cool botanical splash screen for Nuvora Courier & Rider.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _controller;

  /// Looping animation for the sliding progress bar and the pulsing dots.
  late final AnimationController _loop;

  /// Fills the progress bar over the whole splash duration.
  late final AnimationController _progress;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..forward();

    _loop = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();

    _progress = AnimationController(vsync: this, duration: _kProgressDuration)
      ..forward();

    _timer = Timer(_kSplashDuration, _openNextScreen);
  }

  /// Restores session if authenticated, otherwise opens login screen.
  Future<void> _openNextScreen() async {
    final saved = await RiderApi.instance.restoreSession();
    if (!mounted) return;

    if (saved != null) {
      RiderSession.instance.adopt(saved);
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => const LoginScreen(animateEntrance: false),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    _loop.dispose();
    _progress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _Palette.primary,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // Soft botanical glows behind the content.
            Align(
              alignment: Alignment.topCenter,
              child: Transform.translate(
                offset: const Offset(0, -150),
                child: const _Glow(size: 480, color: Color(0x33006C49)),
              ),
            ),
            const Center(child: _Glow(size: 420, color: Color(0x286FFBBE))),

            SafeArea(
              child: Column(
                children: [
                  // Center stage hero.
                  Expanded(
                    child: Center(
                      child: FadeTransition(
                        opacity: CurvedAnimation(
                          parent: _controller,
                          curve: const Interval(0.0, 0.65, curve: Curves.easeOut),
                        ),
                        child: ScaleTransition(
                          scale: Tween<double>(begin: 0.90, end: 1.0).animate(
                            CurvedAnimation(
                              parent: _controller,
                              curve: const Interval(
                                0.0,
                                0.65,
                                curve: Curves.easeOutCubic,
                              ),
                            ),
                          ),
                          child: _buildHero(),
                        ),
                      ),
                    ),
                  ),

                  // Bottom progress + status.
                  FadeTransition(
                    opacity: CurvedAnimation(
                      parent: _controller,
                      curve: const Interval(0.2, 1.0, curve: Curves.easeIn),
                    ),
                    child: _buildFooter(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHero() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Emblem with gradient ring and the EV FLEET pill overlapping it.
        SizedBox(
          width: 96,
          height: 96,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(1.5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [_Palette.mint, _Palette.secondary, Colors.transparent],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _Palette.mint.withAlpha(46),
                      blurRadius: 36,
                      spreadRadius: 4,
                    ),
                    const BoxShadow(
                      color: Colors.black45,
                      blurRadius: 20,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _Palette.emblemFill,
                    border: Border.all(color: Colors.white.withAlpha(18)),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.two_wheeler_rounded,
                      color: _Palette.mint,
                      size: 40,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: -10,
                child: Center(child: _buildFleetPill()),
              ),
            ],
          ),
        ),
        const SizedBox(height: 44),

        // Brand wordmark (left padding balances the trailing letter-spacing).
        const Padding(
          padding: EdgeInsets.only(left: 8),
          child: Text(
            'NUVORA',
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w800,
              letterSpacing: 8,
              height: 1.25,
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Category subtitle.
        Padding(
          padding: const EdgeInsets.only(left: 3.3),
          child: Text(
            'RIDER & COURIER',
            style: TextStyle(
              color: _Palette.mint.withAlpha(230),
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 3.3,
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Motto.
        Text(
          'Deliver more. Earn greener.',
          style: TextStyle(
            color: _Palette.motto.withAlpha(230),
            fontSize: 15,
            fontWeight: FontWeight.w500,
            letterSpacing: -0.1,
          ),
        ),
      ],
    );
  }

  Widget _buildFleetPill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: _Palette.pillFill,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _Palette.mint.withAlpha(77)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black38,
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PulsingDot(animation: _loop),
          const SizedBox(width: 5),
          const Text(
            'EV FLEET',
            style: TextStyle(
              color: _Palette.mint,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  String _statusLabel(double t) {
    if (t < 0.3) return 'INITIALIZING FLEET';
    if (t < 0.6) return 'SYNCING ROUTES';
    if (t < 0.85) return 'CHECKING SESSION';
    return 'READY TO RIDE';
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 0, 32, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Thin progress bar that fills over the whole splash.
          SizedBox(
            width: 200,
            height: 3,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: ColoredBox(
                color: Colors.white.withAlpha(26),
                child: AnimatedBuilder(
                  animation: _progress,
                  builder: (context, _) {
                    final t = Curves.easeInOut.transform(_progress.value);
                    return Align(
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: t,
                        child: const DecoratedBox(
                          decoration: BoxDecoration(
                            color: _Palette.mint,
                            borderRadius: BorderRadius.all(Radius.circular(2)),
                          ),
                          child: SizedBox.expand(),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Heartbeat status.
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _PulsingDot(animation: _loop),
              const SizedBox(width: 8),
              AnimatedBuilder(
                animation: _progress,
                builder: (context, _) {
                  final label = _statusLabel(_progress.value);
                  return AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Text(
                      label,
                      key: ValueKey(label),
                      style: const TextStyle(
                        color: _Palette.metaText,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.8,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
              Text(
                '•',
                style: TextStyle(
                  color: _Palette.metaText.withAlpha(102),
                  fontSize: 11,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'V2.4',
                style: TextStyle(
                  color: _Palette.metaFaint.withAlpha(204),
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Soft radial glow used as ambient background light.
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

/// Small mint status dot that gently pulses with the looping animation.
class _PulsingDot extends StatelessWidget {
  const _PulsingDot({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 1, end: 0.3).animate(
        CurvedAnimation(parent: animation, curve: Curves.easeInOut),
      ),
      child: Container(
        width: 6,
        height: 6,
        decoration: const BoxDecoration(
          color: _Palette.mint,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
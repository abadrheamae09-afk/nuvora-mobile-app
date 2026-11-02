import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_colors.dart';
import '../auth/login_screen.dart';

/// Green brand splash: the rider mark, the app name and a short loading bar
/// before the login screen appears.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..forward();

    _timer = Timer(const Duration(milliseconds: 1900), _openLogin);
  }

  void _openLogin() {
    if (!mounted) return;
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.headerTop, AppColors.headerBottom],
            ),
          ),
          child: Stack(
            children: [
              // Soft glow behind the mark
              Positioned(
                top: -80,
                right: -60,
                child: _Glow(size: 260, color: Colors.white.withAlpha(18)),
              ),
              Positioned(
                bottom: -100,
                left: -70,
                child: _Glow(
                  size: 300,
                  color: AppColors.primaryDeep.withAlpha(70),
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(28, 24, 28, 32),
                  child: Column(
                    children: [
                      const Spacer(),
                      FadeTransition(
                        opacity: CurvedAnimation(
                          parent: _controller,
                          curve: const Interval(
                            0.0,
                            0.6,
                            curve: Curves.easeOut,
                          ),
                        ),
                        child: ScaleTransition(
                          scale: Tween<double>(begin: 0.86, end: 1).animate(
                            CurvedAnimation(
                              parent: _controller,
                              curve: const Interval(
                                0.0,
                                0.6,
                                curve: Curves.easeOutBack,
                              ),
                            ),
                          ),
                          child: Column(
                            children: [
                              Container(
                                width: 96,
                                height: 96,
                                decoration: BoxDecoration(
                                  color: Colors.white.withAlpha(34),
                                  borderRadius: BorderRadius.circular(28),
                                  border: Border.all(
                                    color: AppColors.glassBorder,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.two_wheeler_rounded,
                                  color: Colors.white,
                                  size: 52,
                                ),
                              ),
                              const SizedBox(height: 22),
                              const Text(
                                'Nuvora Rider',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.2,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Pick up. Deliver. Get paid.',
                                style: TextStyle(
                                  color: Colors.white.withAlpha(210),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Spacer(),
                      FadeTransition(
                        opacity: _controller,
                        child: Column(
                          children: [
                            SizedBox(
                              width: 148,
                              height: 4,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(2),
                                child: AnimatedBuilder(
                                  animation: _controller,
                                  builder: (context, _) =>
                                      LinearProgressIndicator(
                                        value: _controller.value,
                                        backgroundColor: Colors.white.withAlpha(
                                          46,
                                        ),
                                        valueColor:
                                            const AlwaysStoppedAnimation(
                                              AppColors.gold,
                                            ),
                                      ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'Philippine time · PHT (UTC+8)',
                              style: TextStyle(
                                color: Colors.white.withAlpha(170),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/api/rider_api.dart';
import '../../core/data/rider_session.dart';
import '../../core/data/rider_work.dart';
import '../auth/login_screen.dart';

const double _radius = 16;

/// Colours taken from the redesign (stitch_mobile_app_redesign).
class _Palette {
  static const forest = Color(0xFF143224);
  static const forestDeep = Color(0xFF001D10);
  static const secondary = Color(0xFF006C49);
  static const mint = Color(0xFF6FFBBE);
  static const background = Color(0xFFF3FCF5);
  static const surfaceLow = Color(0xFFEDF6EF);
  static const surface = Color(0xFFE7F0E9);
  static const border = Color(0xFFDCE5DE);
  static const ink = Color(0xFF151D19);
  static const inkVariant = Color(0xFF424844);
  static const outline = Color(0xFF727973);
  static const onForestMuted = Color(0xFF9DB9A9);
  static const error = Color(0xFFBA1A1A);
  static const errorContainer = Color(0xFFFFDAD6);
}

/// Rider account: who is signed in, their work summary and account links.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  // ---------------------------------------------------------------------------
  // Logout flow & routing: unchanged from the original screen.
  // ---------------------------------------------------------------------------

  Future<void> _confirmLogout(BuildContext context) async {
    HapticFeedback.selectionClick();
    final shouldLogOut = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radius + 8),
        ),
        title: const Text(
          'Log out?',
          style: TextStyle(
            color: _Palette.forestDeep,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: const Text(
          'You will need to sign in again to see your deliveries.',
          style: TextStyle(color: _Palette.inkVariant, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text(
              'Stay',
              style: TextStyle(
                color: _Palette.outline,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(
              'Log Out',
              style: TextStyle(
                color: _Palette.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (shouldLogOut != true || !context.mounted) return;

    // Revoke the token on the server and drop the saved work.
    await RiderApi.instance.logout();
    RiderSession.instance.clear();
    RiderWorkStore.instance.reset();

    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const LoginScreen(animateEntrance: false),
      ),
      (_) => false,
    );
  }

  // ---------------------------------------------------------------------------
  // Design
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final session = RiderSession.instance;
    final store = RiderWorkStore.instance;
    final initials = session.name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _Palette.background,
        body: SingleChildScrollView(
          child: Column(
            children: [
              _buildHeader(context, session, initials),
              // The content slides 20px up so the first card overlaps the
              // bottom edge of the header.
              Transform.translate(
                offset: const Offset(0, -20),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    0,
                    16,
                    90 + MediaQuery.of(context).padding.bottom,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ProfileSection(
                        title: 'This week',
                        child: ListenableBuilder(
                          listenable: store,
                          builder: (context, _) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                _ProfileStat(
                                  value: '${store.parcels.length}',
                                  label: 'Assigned',
                                ),
                                const _StatDivider(),
                                _ProfileStat(
                                  value: '${store.earnings.length}',
                                  label: 'Completed',
                                ),
                                const _StatDivider(),
                                _ProfileStat(
                                  value:
                                      '₱${store.accruedTotal.toStringAsFixed(0)}',
                                  label: 'Earned',
                                  accent: true,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      _ProfileSection(
                        title: 'Account',
                        child: _MenuGroup(
                          items: [
                            const _MenuItem(
                              icon: Icons.person_outline_rounded,
                              label: 'Personal Information',
                            ),
                            _MenuItem(
                              icon: Icons.two_wheeler_outlined,
                              label: 'Vehicle Details',
                              subtitle: session.vehicle.trim().isEmpty
                                  ? null
                                  : session.vehicle,
                            ),
                            const _MenuItem(
                              icon: Icons.lock_outline_rounded,
                              label: 'Change Password',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),
                      const _ProfileSection(
                        title: 'Support',
                        child: _MenuGroup(
                          items: [
                            _MenuItem(
                              icon: Icons.help_outline_rounded,
                              label: 'Help & FAQ',
                            ),
                            _MenuItem(
                              icon: Icons.headset_mic_outlined,
                              label: 'Contact Support',
                            ),
                            _MenuItem(
                              icon: Icons.star_outline_rounded,
                              label: 'Rate the App',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),
                      const _ProfileSection(
                        title: 'Legal',
                        child: _MenuGroup(
                          items: [
                            _MenuItem(
                              icon: Icons.description_outlined,
                              label: 'Terms & Conditions',
                            ),
                            _MenuItem(
                              icon: Icons.privacy_tip_outlined,
                              label: 'Privacy Policy',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 26),
                      _buildLogoutButton(context),
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

  Widget _buildHeader(
    BuildContext context,
    RiderSession session,
    String initials,
  ) {
    final topInset = MediaQuery.of(context).padding.top;

    const radius = BorderRadius.only(
      bottomLeft: Radius.circular(32),
      bottomRight: Radius.circular(32),
    );

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        borderRadius: radius,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_Palette.forestDeep, _Palette.forest],
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x33001D10),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Concentric rings for optical depth.
          const Positioned(right: -64, top: -64, child: _Ring(size: 224, alpha: 26)),
          const Positioned(right: -112, top: -112, child: _Ring(size: 320, alpha: 13)),
          const Positioned(left: -80, top: 70, child: _Ring(size: 176, alpha: 26)),
          Padding(
            padding: EdgeInsets.fromLTRB(16, topInset + 20, 16, 44),
            child: Column(
              children: [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'NUVORA COURIER',
                    style: TextStyle(
                      color: _Palette.onForestMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.6,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                // Avatar with verified badge.
                SizedBox(
                  width: 88,
                  height: 88,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 88,
                        height: 88,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _Palette.forest,
                          border: Border.all(color: _Palette.mint, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withAlpha(26),
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: Text(
                          initials.isEmpty ? 'NR' : initials,
                          style: const TextStyle(
                            color: _Palette.mint,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: -2,
                        right: -2,
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: _Palette.secondary,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _Palette.forest,
                              width: 2.5,
                            ),
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  session.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(38),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withAlpha(51)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 9,
                        height: 9,
                        decoration: const BoxDecoration(
                          color: _Palette.mint,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: Color(0x996FFBBE), blurRadius: 8),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${session.vehicle} Rider',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '•',
                        style: TextStyle(
                          color: Colors.white.withAlpha(102),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          session.station.isEmpty
                              ? 'Station hub'
                              : session.station,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFFADCEBA),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Material(
      color: _Palette.errorContainer,
      borderRadius: BorderRadius.circular(30),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _confirmLogout(context),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 15),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.logout_rounded, color: _Palette.error, size: 20),
              SizedBox(width: 10),
              Text(
                'Log Out',
                style: TextStyle(
                  color: _Palette.error,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Small widgets
// ─────────────────────────────────────────────────────────────────────────────

class _Ring extends StatelessWidget {
  const _Ring({required this.size, required this.alpha});

  final double size;
  final int alpha;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withAlpha(alpha)),
        ),
      ),
    );
  }
}

class _ProfileSection extends StatelessWidget {
  const _ProfileSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              Container(
                width: 5,
                height: 16,
                decoration: BoxDecoration(
                  color: _Palette.secondary,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: _Palette.ink,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(_radius),
            border: Border.all(color: _Palette.border),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A143224),
                blurRadius: 16,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: child,
        ),
      ],
    );
  }
}

class _MenuGroup extends StatelessWidget {
  const _MenuGroup({required this.items});

  final List<_MenuItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < items.length; index++) ...[
          items[index],
          if (index != items.length - 1)
            const Divider(
              height: 1,
              thickness: 1,
              indent: 68,
              color: _Palette.surface,
            ),
        ],
      ],
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({required this.icon, required this.label, this.subtitle});

  final IconData icon;
  final String label;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(content: Text('$label will be connected to Nuvora soon.')),
        ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: _Palette.surfaceLow,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: _Palette.secondary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: _Palette.ink,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 1),
                    Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _Palette.outline,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: _Palette.outline,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileStat extends StatelessWidget {
  const _ProfileStat({
    required this.label,
    required this.value,
    this.accent = false,
  });

  final String label, value;

  /// Highlights the value in the accent green (used for earnings).
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: accent ? _Palette.secondary : _Palette.ink,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                color: _Palette.outline,
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 36, color: _Palette.surface);
  }
}
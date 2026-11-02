import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/data/rider_session.dart';
import '../../core/data/rider_work.dart';
import '../../theme/app_colors.dart';
import '../auth/login_screen.dart';

const double _radius = 16;

/// Rider account: who is signed in, their work summary and account links.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _confirmLogout(BuildContext context) async {
    HapticFeedback.selectionClick();
    final shouldLogOut = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radius + 4),
        ),
        title: const Text(
          'Log out?',
          style: TextStyle(
            color: AppColors.ink,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: const Text(
          'You will need to sign in again to see your deliveries.',
          style: TextStyle(color: AppColors.muted, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text(
              'Stay',
              style: TextStyle(
                color: AppColors.muted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(
              'Log Out',
              style: TextStyle(
                color: AppColors.danger,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (shouldLogOut != true || !context.mounted) return;

    RiderSession.instance.clear();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const LoginScreen(animateEntrance: false),
      ),
      (_) => false,
    );
  }

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
        backgroundColor: AppColors.background,
        body: SingleChildScrollView(
          child: Column(
            children: [
              _buildHeader(context, session, initials),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  24,
                  20,
                  110 + MediaQuery.of(context).padding.bottom,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ProfileSection(
                      title: 'This week',
                      child: ListenableBuilder(
                        listenable: store,
                        builder: (context, _) => Row(
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
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const _ProfileSection(
                      title: 'Account',
                      child: _MenuGroup(
                        items: [
                          _MenuItem(
                            icon: Icons.person_outline_rounded,
                            label: 'Personal Information',
                          ),
                          _MenuItem(
                            icon: Icons.two_wheeler_outlined,
                            label: 'Vehicle Details',
                          ),
                          _MenuItem(
                            icon: Icons.lock_outline_rounded,
                            label: 'Change Password',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
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
                    const SizedBox(height: 24),
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
                    const SizedBox(height: 28),
                    _buildLogoutButton(context),
                  ],
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

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, topInset + 24, 20, 26),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.headerBottom, AppColors.headerTop],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 92,
                height: 92,
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  color: AppColors.gold,
                  shape: BoxShape.circle,
                ),
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppColors.primaryDark,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    initials.isEmpty ? 'NR' : initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.headerTop, width: 2.5),
                  ),
                  child: const Icon(
                    Icons.verified_rounded,
                    color: Colors.white,
                    size: 15,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            session.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.glass,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.gold,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${session.vehicle} Rider',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                Container(width: 1, height: 10, color: const Color(0x40FFFFFF)),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    session.station.isEmpty ? 'Station hub' : session.station,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xB3FFFFFF),
                      fontSize: 12,
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

  Widget _buildLogoutButton(BuildContext context) {
    return Material(
      color: AppColors.dangerSoft,
      borderRadius: BorderRadius.circular(_radius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _confirmLogout(context),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_radius),
            border: Border.all(color: const Color(0xFFF6CFCF)),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.logout_rounded, color: AppColors.danger, size: 20),
              SizedBox(width: 10),
              Text(
                'Log Out',
                style: TextStyle(
                  color: AppColors.danger,
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

class _ProfileSection extends StatelessWidget {
  const _ProfileSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 3,
              height: 16,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(_radius),
            border: Border.all(color: AppColors.border),
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
              color: AppColors.border,
            ),
        ],
      ],
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(content: Text('$label will be connected to Nuvora soon.')),
        ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: AppColors.mint,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.primaryDark, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.muted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileStat extends StatelessWidget {
  const _ProfileStat({required this.label, required this.value});

  final String label, value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                color: AppColors.primaryDeep,
                fontSize: 19,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(color: AppColors.muted, fontSize: 12),
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
    return Container(width: 1, height: 32, color: AppColors.border);
  }
}

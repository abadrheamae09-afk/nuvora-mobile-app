import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _snack(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _confirmSignOut(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Sign out?', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
        content: const Text(
          'You need to sign in again to accept new deliveries.',
          style: TextStyle(fontSize: 13.5, color: AppColors.muted, height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            style: TextButton.styleFrom(foregroundColor: AppColors.muted),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _header(context),
            const SizedBox(height: 16),
            _statsRow(),
            const SizedBox(height: 22),
            _section(
              'Account',
              [
                (Icons.person_outline_rounded, 'Personal Information', 'Name, email, birthday'),
                (Icons.two_wheeler_outlined, 'Vehicle Details', 'Plate, license, OR / CR'),
                (Icons.lock_outline_rounded, 'Change Password', 'Update your password'),
              ],
              context,
            ),
            const SizedBox(height: 16),
            _section(
              'Support',
              [
                (Icons.help_outline_rounded, 'Help & FAQ', 'Answers to common questions'),
                (Icons.support_agent_outlined, 'Contact Support', 'Chat with the team'),
                (Icons.star_outline_rounded, 'Rate the App', 'Tell us how we are doing'),
              ],
              context,
            ),
            const SizedBox(height: 16),
            _section(
              'Legal',
              [
                (Icons.description_outlined, 'Terms & Conditions', 'Rider terms of service'),
                (Icons.privacy_tip_outlined, 'Privacy Policy', 'How your data is handled'),
              ],
              context,
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: () => _confirmSignOut(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.danger,
                  side: BorderSide(color: AppColors.danger.withAlpha(110)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  textStyle: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800),
                ),
                icon: const Icon(Icons.logout_rounded, size: 19),
                label: const Text('Sign out'),
              ),
            ),
            const SizedBox(height: 12),
            const Center(
              child: Text(
                'Nuvora Rider v1.0.0',
                style: TextStyle(fontSize: 12, color: AppColors.muted),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.headerTop, AppColors.headerBottom],
        ),
        borderRadius: BorderRadius.all(Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            width: 74,
            height: 74,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(45),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withAlpha(120), width: 2),
            ),
            alignment: Alignment.center,
            child: const Text(
              'JD',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Juan Dela Cruz',
            style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            'Rider ID \u00b7 NV-00841',
            style: TextStyle(color: Colors.white.withAlpha(215), fontSize: 13),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(38),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified_rounded, size: 15, color: Color(0xFFB9F6CA)),
                SizedBox(width: 6),
                Text(
                  'Verified rider',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statsRow() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: const Row(
        children: [
          Expanded(child: _Stat(value: '128', label: 'Deliveries')),
          _Divider(),
          Expanded(child: _Stat(value: '4.9', label: 'Rating')),
          _Divider(),
          Expanded(child: _Stat(value: '1 yr', label: 'With Nuvora')),
        ],
      ),
    );
  }

  Widget _section(
    String title,
    List<(IconData, String, String)> items,
    BuildContext context,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryDark,
                letterSpacing: 0.4,
              ),
            ),
          ),
          for (var i = 0; i < items.length; i++) ...[
            ListTile(
              onTap: () => _snack(context, '${items[i].$2} will open here.'),
              leading: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.mint,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(items[i].$1, size: 19, color: AppColors.primaryDark),
              ),
              title: Text(
                items[i].$2,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              subtitle: Text(
                items[i].$3,
                style: const TextStyle(fontSize: 12.5, color: AppColors.muted),
              ),
              trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
            ),
            if (i != items.length - 1)
              const Divider(height: 1, indent: 70, color: AppColors.border),
          ],
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;

  const _Stat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: AppColors.primaryDark,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11.5, color: AppColors.muted),
        ),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 34, color: AppColors.border);
  }
}
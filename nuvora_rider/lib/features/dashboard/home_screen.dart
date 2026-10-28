import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _snack(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
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
            const SizedBox(height: 18),
            _statsCard(),
            const SizedBox(height: 22),
            _sectionTitle('Active assignment', trailing: 'Today'),
            const SizedBox(height: 10),
            _assignmentCard(context),
            const SizedBox(height: 22),
            _sectionTitle('Today\u2019s summary'),
            const SizedBox(height: 10),
            _summaryCard(context),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.headerTop, AppColors.headerBottom],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(40),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Text(
                  'JD',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Good morning,',
                      style: TextStyle(
                        color: Colors.white.withAlpha(215),
                        fontSize: 12.5,
                      ),
                    ),
                    const Text(
                      'Juan Dela Cruz',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              _iconButton(
                Icons.notifications_outlined,
                onTap: () => _snack(context, 'No new notifications.'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(38),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle, size: 8, color: Color(0xFFB9F6CA)),
                    SizedBox(width: 6),
                    Text(
                      'Online \u00b7 Accepting jobs',
                      style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                'Tue, 28 Oct',
                style: TextStyle(color: Colors.white.withAlpha(215), fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _iconButton(IconData icon, {required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(35),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _statsCard() {
    const stats = [
      ('3', 'Deliveries'),
      ('\u20b1420', 'Earned today'),
      ('4.9', 'Rating'),
    ];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(child: _StatCell(value: stats[0].$1, label: stats[0].$2)),
          _VDivider(),
          Expanded(child: _StatCell(value: stats[1].$1, label: stats[1].$2)),
          _VDivider(),
          Expanded(child: _StatCell(value: stats[2].$1, label: stats[2].$2)),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, {String? trailing}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
          ),
        ),
        if (trailing != null)
          Text(trailing, style: const TextStyle(fontSize: 12.5, color: AppColors.muted)),
      ],
    );
  }

  Widget _assignmentCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.amberSoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Pickup',
                  style: TextStyle(
                    color: Color(0xFFB45309),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Order #NV-10243',
                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              const Text(
                'ETA 10:40 AM',
                style: TextStyle(fontSize: 11.5, color: AppColors.muted),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Handle with care \u00b7 2 parcels \u00b7 3.4 km',
            style: TextStyle(fontSize: 12, color: AppColors.muted),
          ),
          const SizedBox(height: 16),
          _routeStop(
            icon: Icons.store_mall_directory_outlined,
            color: AppColors.primary,
            title: 'Green Mart, Cubao',
            subtitle: 'Pickup point · 120 Aurora Blvd',
            first: true,
          ),
          _routeStop(
            icon: Icons.flag_outlined,
            color: AppColors.blue,
            title: 'M. Rodriguez St., Pasig',
            subtitle: 'Drop-off · R. Alcantara',
            first: false,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _snack(context, 'Opening route map\u2026'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.ink,
                    side: const BorderSide(color: AppColors.border),
                    minimumSize: const Size(0, 44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    textStyle: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
                  ),
                  icon: const Icon(Icons.map_outlined, size: 18),
                  label: const Text('View route'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _snack(context, 'Delivery marked as picked up.'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    minimumSize: const Size(0, 44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    textStyle: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800),
                  ),
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: const Text('Picked up'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _routeStop({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required bool first,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(color: color.withAlpha(26), shape: BoxShape.circle),
              child: Icon(icon, size: 17, color: color),
            ),
            if (!first)
              Container(
                width: 2,
                height: 26,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(top: first ? 3 : 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                if (!first) const SizedBox(height: 14),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _summaryCard(BuildContext context) {
    const rows = [
      (Icons.inventory_2_outlined, 'Parcels assigned', '5 of 8 completed'),
      (Icons.schedule_outlined, 'On-time rate', '96% this week'),
      (Icons.payments_outlined, 'Cash collected', '\u20b11,250'),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            ListTile(
              onTap: () => _snack(context, rows[i].$2),
              leading: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.mint,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(rows[i].$1, size: 19, color: AppColors.primaryDark),
              ),
              title: Text(
                rows[i].$2,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              subtitle: Text(
                rows[i].$3,
                style: const TextStyle(fontSize: 12.5, color: AppColors.muted),
              ),
              trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
            ),
            if (i != rows.length - 1)
              const Divider(height: 1, indent: 70, color: AppColors.border),
          ],
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  final String value;
  final String label;

  const _StatCell({required this.value, required this.label});

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
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 11.5, color: AppColors.muted),
        ),
      ],
    );
  }
}

class _VDivider extends StatelessWidget {
  const _VDivider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 34, color: AppColors.border);
  }
}
import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

class EarningsScreen extends StatelessWidget {
  const EarningsScreen({super.key});

  void _snack(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    const transactions = [
      ('Order #NV-10241', 'Today \u00b7 Delivered', '+\u20b1180'),
      ('Order #NV-10238', 'Today \u00b7 Delivered', '+\u20b1150'),
      ('Delivery fee payout', 'Today \u00b7 3 completed trips', '+\u20b1420'),
      ('Order #NV-10235', 'Yesterday \u00b7 Delivered', '+\u20b1220'),
      ('COD remittance fee', 'Yesterday \u00b7 Service fee', '-\u20b135'),
    ];

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'My Earnings',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.ink),
            ),
            const SizedBox(height: 16),
            Container(
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Accrued earnings',
                    style: TextStyle(color: Colors.white.withAlpha(215), fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    '\u20b16,845.00',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      _heroStat('Today', '\u20b1750'),
                      Container(width: 1, height: 28, color: Colors.white.withAlpha(70)),
                      _heroStat('This week', '\u20b13,120'),
                      Container(width: 1, height: 28, color: Colors.white.withAlpha(70)),
                      _heroStat('This month', '\u20b112,480'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _infoCard('Completed trips', '41', Icons.check_circle_outline),
                const SizedBox(width: 10),
                _infoCard('COD collected', '\u20b18,450', Icons.payments_outlined),
                const SizedBox(width: 10),
                _infoCard('Avg. per trip', '\u20b1167', Icons.timeline_outlined),
              ],
            ),
            const SizedBox(height: 22),
            const Text(
              'Recent transactions',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.ink),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  for (var i = 0; i < transactions.length; i++) ...[
                    ListTile(
                      onTap: () => _snack(context, '${transactions[i].$1} \u00b7 ${transactions[i].$2}'),
                      leading: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: transactions[i].$3.startsWith('+')
                              ? AppColors.mint
                              : AppColors.dangerSoft,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          transactions[i].$3.startsWith('+')
                              ? Icons.south_rounded
                              : Icons.north_rounded,
                          size: 18,
                          color: transactions[i].$3.startsWith('+')
                              ? AppColors.primaryDark
                              : AppColors.danger,
                        ),
                      ),
                      title: Text(
                        transactions[i].$1,
                        style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        transactions[i].$2,
                        style: const TextStyle(fontSize: 12, color: AppColors.muted),
                      ),
                      trailing: Text(
                        transactions[i].$3,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: transactions[i].$3.startsWith('+')
                              ? AppColors.primaryDark
                              : AppColors.danger,
                        ),
                      ),
                    ),
                    if (i != transactions.length - 1)
                      const Divider(height: 1, indent: 70, color: AppColors.border),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.mint,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, size: 17, color: AppColors.primaryDark),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Accrued amounts are not a cash or bank payout. Cash out becomes '
                      'available once payouts are enabled for your account.',
                      style: TextStyle(fontSize: 12.5, color: AppColors.primaryDeep, height: 1.45),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _heroStat(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(color: Colors.white.withAlpha(200), fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _infoCard(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 2,
              style: const TextStyle(fontSize: 11, color: AppColors.muted, height: 1.3),
            ),
          ],
        ),
      ),
    );
  }
}
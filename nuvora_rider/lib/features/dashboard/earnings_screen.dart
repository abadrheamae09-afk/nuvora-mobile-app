import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/data/rider_work.dart';
import '../../theme/app_colors.dart';

/// Accrued earnings plus the COD cash the rider is still holding.
class EarningsScreen extends StatelessWidget {
  const EarningsScreen({super.key});

  String _money(double value) => '₱${value.toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    final store = RiderWorkStore.instance;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.headerTop,
          foregroundColor: Colors.white,
          title: const Text(
            'My Earnings',
            style: TextStyle(color: Colors.white),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: ListenableBuilder(
          listenable: store,
          builder: (context, _) => RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {},
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                110 + MediaQuery.of(context).padding.bottom,
              ),
              children: [
                _card(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Accrued earnings',
                        style: TextStyle(color: AppColors.muted),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _money(store.accruedTotal),
                        style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryDeep,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${store.earnings.length} completed credits · accrued from '
                        'completed deliveries',
                        style: const TextStyle(color: AppColors.muted),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Accrued amounts are not a cash or bank payout yet. Nuvora '
                        'will hand these over through your Station Hub.',
                        style: TextStyle(color: AppColors.muted, height: 1.35),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                const _SectionTitle('Cash on hand'),
                const SizedBox(height: 8),
                _card(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: AppColors.goldSoft,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.payments_outlined,
                              color: AppColors.goldInk,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'COD cash you are holding',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: AppColors.muted,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _money(store.cashOnHand),
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primaryDeep,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'This is not your pay. It leaves this total when your Station '
                        'Hub records that it received the cash.',
                        style: TextStyle(color: AppColors.muted, height: 1.35),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                const _SectionTitle('Recent earnings'),
                const SizedBox(height: 8),
                if (store.earnings.isEmpty)
                  _card(
                    const Text(
                      'No completed deliveries yet.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.muted),
                    ),
                  )
                else
                  ...store.earnings.map(
                    (row) => _card(
                      Row(
                        children: [
                          const Icon(
                            Icons.check_circle_outline_rounded,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  row.order,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.ink,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${row.hub} · ${row.date}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            _money(row.amount),
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: AppColors.primaryDeep,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 18),
                const _SectionTitle('COD collections'),
                const SizedBox(height: 8),
                if (store.collections.isEmpty)
                  _card(
                    const Text(
                      'No COD cash waiting to be handed over.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.muted),
                    ),
                  )
                else
                  ...store.collections.map(
                    (row) => _card(
                      Row(
                        children: [
                          const Icon(
                            Icons.receipt_long_outlined,
                            color: AppColors.primaryDark,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  row.order,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.ink,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text(
                                      row.date,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.muted,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    _StatusChip(label: row.status),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _money(row.amount),
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: AppColors.primaryDeep,
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
      ),
    );
  }

  Widget _card(Widget child) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: AppColors.border),
      borderRadius: BorderRadius.circular(16),
    ),
    child: child,
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
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
          text,
          style: const TextStyle(
            color: AppColors.ink,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final received = label.toLowerCase().contains('received');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: received ? AppColors.mint : AppColors.goldSoft,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: received ? AppColors.primaryDark : AppColors.goldInk,
        ),
      ),
    );
  }
}

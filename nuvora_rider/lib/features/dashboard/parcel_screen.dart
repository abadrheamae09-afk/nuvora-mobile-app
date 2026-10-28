import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

class ParcelScreen extends StatefulWidget {
  const ParcelScreen({super.key});

  @override
  State<ParcelScreen> createState() => _ParcelScreenState();
}

class _ParcelScreenState extends State<ParcelScreen> {
  static const _filters = ['All', 'Pending', 'On the way', 'Delivered'];
  String _filter = 'All';

  static const List<Map<String, String>> _parcels = [
    {
      'id': 'NV-10243',
      'recipient': 'R. Alcantara',
      'address': '12 M. Rodriguez St., Pasig',
      'status': 'On the way',
      'time': 'Pickup 10:15 AM',
      'cod': '\u20b1450',
    },
    {
      'id': 'NV-10244',
      'recipient': 'M. Santos',
      'address': '88 Cubao Ave., Quezon City',
      'status': 'Pending',
      'time': 'Pickup 11:00 AM',
      'cod': '\u20b10',
    },
    {
      'id': 'NV-10241',
      'recipient': 'L. Garcia',
      'address': '5 Narra St., Makati',
      'status': 'Delivered',
      'time': 'Delivered 9:02 AM',
      'cod': '\u20b11,120',
    },
    {
      'id': 'NV-10240',
      'recipient': 'A. Reyes',
      'address': '23 P. Burgos St., Calamba',
      'status': 'On the way',
      'time': 'Pickup 8:45 AM',
      'cod': '\u20b1275',
    },
    {
      'id': 'NV-10238',
      'recipient': 'K. Bautista',
      'address': '7 Sampaguita St., Bacoor',
      'status': 'Delivered',
      'time': 'Delivered 8:10 AM',
      'cod': '\u20b1640',
    },
  ];

  List<Map<String, String>> get _visible => _filter == 'All'
      ? _parcels
      : _parcels.where((p) => p['status'] == _filter).toList();

  int _count(String filter) =>
      filter == 'All' ? _parcels.length : _parcels.where((p) => p['status'] == filter).length;

  void _openParcel(Map<String, String> parcel) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.mint,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(
                    Icons.inventory_2_outlined,
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order #${parcel['id']}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                      ),
                      Text(
                        '${parcel['status']} \u00b7 ${parcel['time']}',
                        style: const TextStyle(fontSize: 12.5, color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
                _statusChip(parcel['status']!),
              ],
            ),
            const SizedBox(height: 18),
            _detailRow('Recipient', parcel['recipient']!),
            _detailRow('Address', parcel['address']!),
            _detailRow('COD amount', parcel['cod']!),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  textStyle: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800),
                ),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: AppColors.muted),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  static Color _statusColor(String status) => switch (status) {
    'Delivered' => AppColors.primaryDark,
    'On the way' => AppColors.blue,
    _ => Color(0xFFB45309),
  };

  static Color _statusBg(String status) => switch (status) {
    'Delivered' => AppColors.mint,
    'On the way' => AppColors.blueSoft,
    _ => AppColors.amberSoft,
  };

  static Widget _statusChip(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _statusBg(status),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
          color: _statusColor(status),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalCod = _parcels
        .where((p) => p['status'] == 'Delivered')
        .map((p) => int.parse(p['cod']!.replaceAll(RegExp(r'[^\d]'), '')))
        .fold<int>(0, (sum, v) => sum + v);

    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 14, 20, 6),
            child: Text(
              'Parcels',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.ink),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _summaryTile('${_count('Pending')}', 'Pending', AppColors.amberSoft, Color(0xFFB45309)),
                const SizedBox(width: 10),
                _summaryTile('${_count('On the way')}', 'On the way', AppColors.blueSoft, AppColors.blue),
                const SizedBox(width: 10),
                _summaryTile('${_count('Delivered')}', 'Delivered', AppColors.mint, AppColors.primaryDark),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _filters.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final filter = _filters[index];
                final selected = filter == _filter;
                return InkWell(
                  onTap: () => setState(() => _filter = filter),
                  borderRadius: BorderRadius.circular(19),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selected ? AppColors.primary : AppColors.card,
                      borderRadius: BorderRadius.circular(19),
                      border: Border.all(
                        color: selected ? AppColors.primary : AppColors.border,
                      ),
                    ),
                    child: Text(
                      '$filter (${_count(filter)})',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                        color: selected ? Colors.white : AppColors.muted,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: _visible.isEmpty
                ? const _EmptyState()
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    itemCount: _visible.length + 1,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Text(
                            '${_visible.length} parcels \u00b7 \u20b1$totalCod collected',
                            style: const TextStyle(fontSize: 12.5, color: AppColors.muted),
                          ),
                        );
                      }
                      final parcel = _visible[index - 1];
                      return _ParcelCard(parcel: parcel, onTap: () => _openParcel(parcel));
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _summaryTile(String value, String label, Color bg, Color fg) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: fg),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg),
            ),
          ],
        ),
      ),
    );
  }
}

class _ParcelCard extends StatelessWidget {
  final Map<String, String> parcel;
  final VoidCallback onTap;

  const _ParcelCard({required this.parcel, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.mint,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.inventory_2_outlined,
                    size: 19,
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order #${parcel['id']}',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                      ),
                      Text(
                        '${parcel['recipient']} \u00b7 ${parcel['time']}',
                        style: const TextStyle(fontSize: 12, color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
                _ParcelScreenState._statusChip(parcel['status']!),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.place_outlined, size: 16, color: AppColors.muted),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    parcel['address']!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, color: AppColors.ink),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'COD ${parcel['cod']}',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryDark,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(color: AppColors.mint, shape: BoxShape.circle),
            child: const Icon(Icons.inventory_2_outlined, color: AppColors.primary, size: 30),
          ),
          const SizedBox(height: 14),
          const Text(
            'No parcels in this list.',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          const Text(
            'Switch the filter above to see the rest.',
            style: TextStyle(fontSize: 13, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';

import '../../core/data/rider_work.dart';
import '../../theme/app_colors.dart';

/// Every parcel and delivery update for the rider.
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = RiderWorkStore.instance;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.ink,
        title: const Text('Notifications'),
        actions: [
          ListenableBuilder(
            listenable: store,
            builder: (context, _) {
              if (store.unreadCount == 0) return const SizedBox.shrink();
              return TextButton(
                onPressed: store.markAllNoticesRead,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primaryDark,
                  textStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: const Text('Mark all read'),
              );
            },
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          final notices = store.notices;

          if (notices.isEmpty) {
            return ListView(
              children: const [
                SizedBox(height: 105),
                Icon(
                  Icons.notifications_none_rounded,
                  color: AppColors.muted,
                  size: 46,
                ),
                SizedBox(height: 12),
                Center(
                  child: Text(
                    'You’re all caught up',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                ),
                SizedBox(height: 6),
                Center(
                  child: Text(
                    'Parcel and delivery updates will appear here.',
                    style: TextStyle(color: AppColors.muted),
                  ),
                ),
              ],
            );
          }

          return ListView.separated(
            padding: EdgeInsets.fromLTRB(
              16,
              8,
              16,
              110 + MediaQuery.of(context).padding.bottom,
            ),
            itemCount: notices.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final notice = notices[index];
              return Material(
                color: notice.read ? const Color(0xFFF1F5F2) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => store.markNoticeRead(notice),
                  child: Padding(
                    padding: const EdgeInsets.all(15),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: notice.read
                                ? AppColors.mintSoft
                                : AppColors.mint,
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: const Icon(
                            Icons.notifications_active_outlined,
                            color: AppColors.primaryDark,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      notice.title,
                                      style: const TextStyle(
                                        color: AppColors.ink,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  if (!notice.read)
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: AppColors.primary,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 5),
                              Text(
                                notice.message,
                                style: const TextStyle(
                                  color: Color(0xFF4B5A50),
                                  height: 1.35,
                                ),
                              ),
                              const SizedBox(height: 7),
                              Text(
                                notice.timeAgo,
                                style: const TextStyle(
                                  color: AppColors.muted,
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
              );
            },
          );
        },
      ),
    );
  }
}

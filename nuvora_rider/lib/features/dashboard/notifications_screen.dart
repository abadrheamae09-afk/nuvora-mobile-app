import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/data/rider_work.dart';

/// Colours taken from the redesign (stitch_mobile_app_redesign).
class _Palette {
  static const forest = Color(0xFF143224);
  static const forestMid = Color(0xFF183D2C);
  static const forestDark = Color(0xFF0D2319);
  static const mint = Color(0xFFD1FAE5);
  static const mintLight = Color(0xFFE8F8F0);
  static const sage = Color(0xFFE3EDE7);
  static const surface = Color(0xFFF4FAF6);
  static const surfaceMuted = Color(0xFFEBF4EE);
  static const emerald = Color(0xFF34D399);
  static const emeraldDeep = Color(0xFF059669);
  static const message = Color(0xFF4B5A50);
  static const muted = Color(0xFF627C6E);
  static const subtle = Color(0xFF94A3B8);
}

/// Every parcel and delivery update for the rider.
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = RiderWorkStore.instance;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Light status bar icons because the header is dark.
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _Palette.surface,
        body: Column(
          children: [
            ListenableBuilder(
              listenable: store,
              builder: (context, _) => _Header(
                unreadCount: store.unreadCount,
                onMarkAllRead: store.markAllNoticesRead,
              ),
            ),
            Expanded(
              child: ListenableBuilder(
                listenable: store,
                builder: (context, _) {
                  final notices = store.notices;

                  if (notices.isEmpty) {
                    return ListView(
                      padding: const EdgeInsets.fromLTRB(32, 56, 32, 32),
                      children: const [_EmptyState()],
                    );
                  }

                  return ListView.separated(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      20,
                      16,
                      110 + MediaQuery.of(context).padding.bottom,
                    ),
                    itemCount: notices.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final notice = notices[index];
                      return _NoticeCard(
                        title: notice.title,
                        message: notice.message,
                        timeAgo: notice.timeAgo,
                        read: notice.read,
                        onTap: () => store.markNoticeRead(notice),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Deep forest masthead with title, unread summary and the mark-all-read action.
class _Header extends StatelessWidget {
  const _Header({required this.unreadCount, required this.onMarkAllRead});

  final int unreadCount;
  final VoidCallback onMarkAllRead;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final canPop = Navigator.of(context).canPop();
    final hasUnread = unreadCount > 0;

    const radius = BorderRadius.only(
      bottomLeft: Radius.circular(36),
      bottomRight: Radius.circular(36),
    );

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        borderRadius: radius,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_Palette.forest, _Palette.forestMid],
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x2E143224),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          const Positioned(
            right: -50,
            bottom: -60,
            child: _Glow(size: 190, color: Color(0x2610B981)),
          ),
          const Positioned(
            left: -45,
            top: -30,
            child: _Glow(size: 140, color: Color(0x1A34D399)),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(20, top + 14, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (canPop) ...[
                      _RoundButton(
                        icon: Icons.arrow_back_rounded,
                        label: 'Back',
                        onTap: () => Navigator.of(context).maybePop(),
                      ),
                      const SizedBox(width: 10),
                    ],
                    _StatusPill(unreadCount: unreadCount),
                    const Spacer(),
                    if (hasUnread)
                      _RoundButton(
                        icon: Icons.done_all_rounded,
                        label: 'Mark all read',
                        onTap: onMarkAllRead,
                      ),
                  ],
                ),
                const SizedBox(height: 18),
                const Text(
                  'Notifications',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Parcel and delivery updates, in one place',
                  style: TextStyle(
                    color: const Color(0xFFD1FAE5).withAlpha(191),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Glass pill: live dot + "N unread" (or "All caught up").
class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.unreadCount});

  final int unreadCount;

  @override
  Widget build(BuildContext context) {
    final hasUnread = unreadCount > 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(26),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withAlpha(26)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _Palette.emerald,
              boxShadow: [
                BoxShadow(
                  color: _Palette.emerald.withAlpha(hasUnread ? 170 : 90),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            hasUnread ? '$unreadCount unread' : 'All caught up',
            style: const TextStyle(
              color: Color(0xFFD1FAE5),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Tooltip(
        message: label,
        child: Material(
          color: Colors.white.withAlpha(26),
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: SizedBox(
              width: 40,
              height: 40,
              child: Icon(icon, color: Colors.white, size: 20),
            ),
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

/// One notification. Unread: white card with a mint badge and dot. Read: soft
/// sage card, quieter.
class _NoticeCard extends StatelessWidget {
  const _NoticeCard({
    required this.title,
    required this.message,
    required this.timeAgo,
    required this.read,
    required this.onTap,
  });

  final String title;
  final String message;
  final String timeAgo;
  final bool read;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(18);

    return Container(
      decoration: BoxDecoration(
        borderRadius: radius,
        color: read ? _Palette.surfaceMuted : Colors.white,
        border: Border.all(
          color: read ? Colors.transparent : _Palette.sage,
        ),
        boxShadow: read
            ? null
            : const [
                BoxShadow(
                  color: Color(0x14143224),
                  blurRadius: 20,
                  offset: Offset(0, 8),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(13),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: read
                          ? const [_Palette.mintLight, _Palette.mintLight]
                          : const [_Palette.mintLight, _Palette.mint],
                    ),
                  ),
                  child: Icon(
                    read
                        ? Icons.notifications_none_rounded
                        : Icons.notifications_active_outlined,
                    color: read ? _Palette.muted : _Palette.forest,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: TextStyle(
                                color: _Palette.forest,
                                fontSize: 14,
                                fontWeight:
                                    read ? FontWeight.w600 : FontWeight.w800,
                                letterSpacing: -0.1,
                                height: 1.3,
                              ),
                            ),
                          ),
                          if (!read) ...[
                            const SizedBox(width: 8),
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: _Palette.emeraldDeep,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFFD1FAE5),
                                    width: 2.5,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        message,
                        style: TextStyle(
                          color: read ? _Palette.muted : _Palette.message,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.schedule_rounded,
                            size: 13,
                            color: _Palette.subtle,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            timeAgo,
                            style: const TextStyle(
                              color: _Palette.muted,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "You're all caught up" illustration and copy.
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: 112,
          height: 112,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              // Soft outer glow.
              Container(
                width: 112,
                height: 112,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _Palette.mint.withAlpha(190),
                      blurRadius: 30,
                      spreadRadius: 4,
                    ),
                  ],
                ),
              ),
              // Sage ring with white border.
              Container(
                width: 112,
                height: 112,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [_Palette.mintLight, _Palette.mint],
                  ),
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1F143224),
                      blurRadius: 20,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Center(
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withAlpha(230),
                    ),
                    child: Transform.rotate(
                      angle: -0.05,
                      child: const Icon(
                        Icons.notifications_none_rounded,
                        color: _Palette.forest,
                        size: 36,
                      ),
                    ),
                  ),
                ),
              ),
              // Check badge.
              Positioned(
                right: 4,
                bottom: 4,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _Palette.emeraldDeep,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        const Text(
          'You’re all caught up',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
            color: _Palette.forest,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Parcel and delivery updates will appear here.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13.5,
            height: 1.45,
            color: Color(0xFF64748B),
          ),
        ),
      ],
    );
  }
}
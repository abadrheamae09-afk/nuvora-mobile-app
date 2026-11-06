// ============================================================
// profile_screen.dart
// Buyer profile hub: avatar, stats, orders, settings menu.
// Redesigned UI: "Botanical Boutique" (NUVORA) to match the
// buyer login + home screens. Routing/logic is unchanged:
// every screen this file used to open is still opened from the
// same menu rows, and Sign Out still returns to the login.
// ============================================================

import 'package:flutter/material.dart';
import '../../core/navigation/buyer_nav_bar.dart';
import 'package:google_fonts/google_fonts.dart';
import 'edit_profile_screen.dart';
import 'my_orders_screen.dart';
import 'wishlist_screen.dart';
import 'add_edit_address_screen.dart';
import 'change_password_screen.dart';
import 'notifications_screen.dart';
import 'help_support_screen.dart';
import '../../../auth/buyer_login_screen.dart';
import '../../../core/api/buyer_api.dart';

// ── Design tokens (same palette as home_screen.dart) ────────
class _PColors {
  static const background = Color(0xFFFCF9F8);
  static const card = Colors.white;
  static const forest = Color(0xFF173628); // primary-container
  static const forestDeep = Color(0xFF012114); // primary
  static const sage = Color(0xFFC2E9C7); // secondary-container
  static const sageSoft = Color(0xFFC5ECCA); // secondary-fixed
  static const sageDim = Color(0xFFAAD0AF); // secondary-fixed-dim
  static const secondary = Color(0xFF44664B);
  static const amber = Color(0xFFFABC4D); // tertiary-fixed-dim
  static const amberText = Color(0xFF281900);
  static const tileFill = Color(0xFFF6F3F2); // surface-container-low
  static const divider = Color(0xFFF0EDED); // surface-container
  static const ink = Color(0xFF1C1B1B);
  static const inkSoft = Color(0xFF424844);
  static const outline = Color(0xFF727973);
  static const outlineSoft = Color(0xFFC1C8C2);
  static const shadow = Color(0x0A173628); // 4% forest
  static const error = Color(0xFFBA1A1A);
  static const errorSoft = Color(0xFFFFDAD6);
}

TextStyle _jakarta({
  double size = 14,
  FontWeight weight = FontWeight.w400,
  Color color = _PColors.ink,
  double? letterSpacing,
  double? height,
}) =>
    GoogleFonts.plusJakartaSans(
      fontSize: size,
      fontWeight: weight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
    );

TextStyle _playfair({
  double size = 22,
  FontWeight weight = FontWeight.w600,
  Color color = _PColors.forestDeep,
  double? letterSpacing,
  double? height,
}) =>
    GoogleFonts.playfairDisplay(
      fontSize: size,
      fontWeight: weight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
    );

BoxDecoration _cardDecoration() => BoxDecoration(
      color: _PColors.card,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _PColors.outlineSoft.withAlpha(51)),
      boxShadow: const [
        BoxShadow(
          color: _PColors.shadow,
          blurRadius: 16,
          offset: Offset(0, 4),
        ),
      ],
    );

class MockupProfileScreen extends StatefulWidget {
  const MockupProfileScreen({super.key});

  @override
  State<MockupProfileScreen> createState() => _MockupProfileScreenState();
}

class _MockupProfileScreenState extends State<MockupProfileScreen> {


  // ── Navigation helpers (same destinations as before) ──────
  void _push(Widget screen) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => screen));

  void _openEditProfile() => _push(const MockupEditProfileScreen());
  void _openOrders() => _push(const MockupMyOrdersScreen());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _PColors.background,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            // ── Top app bar ────────────────────────────────
            _buildTopBar(),
            // ── Profile card + stats ───────────────────────
            SliverToBoxAdapter(child: _buildProfileCard()),
            // ── Orders ─────────────────────────────────────
            SliverToBoxAdapter(child: _buildOrdersSection()),
            // ── Menu sections ──────────────────────────────
            SliverToBoxAdapter(child: _buildMenu()),
            // ── Version / logout ───────────────────────────
            SliverToBoxAdapter(child: _buildFooter()),
          ],
        ),
      ),
      bottomNavigationBar: const BuyerNavBar(current: BuyerTab.account),
    );
  }

  // ── Top app bar: "My Account" + cart / chat discs ─────────
  Widget _buildTopBar() {
    return SliverAppBar(
      pinned: true,
      automaticallyImplyLeading: false,
      backgroundColor: _PColors.background,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 2,
      shadowColor: _PColors.shadow,
      toolbarHeight: 60,
      titleSpacing: 16,
      title: Text(
        'My Account',
        style: _playfair(size: 20, letterSpacing: -0.2),
      ),
      actions: [
        _circleAction(Icons.shopping_bag_outlined, () {}),
        const SizedBox(width: 8),
        _circleAction(Icons.chat_bubble_outline_rounded, () {}),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _circleAction(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: const BoxDecoration(
          color: _PColors.tileFill,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 20, color: _PColors.forestDeep),
      ),
    );
  }

  // ── Profile card (avatar, name, tier chip, bento stats) ───
  Widget _buildProfileCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: _cardDecoration(),
        child: Stack(
          children: [
            // soft botanical glow
            Positioned(
              right: -32,
              top: -32,
              child: Container(
                width: 128,
                height: 128,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _PColors.sageSoft.withAlpha(77),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Avatar
                      Container(
                        width: 64,
                        height: 64,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _PColors.sage,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: _PColors.forest.withAlpha(51), width: 2),
                        ),
                        child: Text(
                          'J',
                          style: _playfair(
                            size: 28,
                            weight: FontWeight.w700,
                            color: _PColors.forest,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Juan Dela Cruz',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: _playfair(
                                      size: 22,
                                      weight: FontWeight.w500,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: _openEditProfile,
                                  child: const Padding(
                                    padding: EdgeInsets.only(left: 6),
                                    child: Icon(Icons.edit_outlined,
                                        size: 18, color: _PColors.outline),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'juan@example.com',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: _jakarta(
                                size: 12,
                                color: _PColors.inkSoft,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 2),
                              decoration: BoxDecoration(
                                color: _PColors.sageSoft.withAlpha(102),
                                borderRadius: BorderRadius.circular(99),
                                border: Border.all(
                                    color: _PColors.sageDim.withAlpha(128)),
                              ),
                              child: Text(
                                'Conscious Buyer • Green Tier 🌿',
                                style: _jakarta(
                                  size: 10,
                                  weight: FontWeight.w600,
                                  color: _PColors.forestDeep,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(height: 1, color: _PColors.divider),
                  const SizedBox(height: 16),
                  // Bento stats
                  Row(
                    children: [
                      Expanded(child: _statTile('12', 'Orders')),
                      const SizedBox(width: 8),
                      Expanded(child: _statTile('5', 'Wishlist', accent: true)),
                      const SizedBox(width: 8),
                      Expanded(child: _statTile('3', 'Reviews')),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statTile(String value, String label, {bool accent = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: accent
            ? _PColors.sage.withAlpha(77)
            : _PColors.tileFill.withAlpha(178),
        borderRadius: BorderRadius.circular(12),
        border: accent
            ? Border.all(color: _PColors.sageDim.withAlpha(77))
            : null,
      ),
      child: Column(
        children: [
          Text(
            value,
            style: _jakarta(
              size: 17,
              weight: FontWeight.w700,
              letterSpacing: -0.2,
              color: _PColors.forestDeep,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: _jakarta(
              size: 10,
              weight: accent ? FontWeight.w600 : FontWeight.w500,
              color: accent ? _PColors.secondary : _PColors.inkSoft,
            ),
          ),
        ],
      ),
    );
  }

  // ── My Orders: status shortcuts + active delivery card ────
  Widget _buildOrdersSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                Expanded(
                  child: Text('My Orders', style: _playfair(size: 18)),
                ),
                GestureDetector(
                  onTap: _openOrders,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'View All (12)',
                        style: _jakarta(
                          size: 12,
                          weight: FontWeight.w600,
                          color: _PColors.secondary,
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded,
                          size: 16, color: _PColors.secondary),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Status shortcuts
          Container(
            padding: const EdgeInsets.all(8),
            decoration: _cardDecoration(),
            child: Row(
              children: [
                _statusTile(Icons.account_balance_wallet_outlined, 'To Pay'),
                _statusTile(Icons.inventory_2_outlined, 'To Ship',
                    count: 1,
                    badgeColor: _PColors.forestDeep,
                    badgeText: Colors.white,
                    strong: true),
                _statusTile(Icons.local_shipping_outlined, 'To Receive',
                    count: 2,
                    badgeColor: _PColors.secondary,
                    badgeText: Colors.white,
                    highlighted: true,
                    strong: true),
                _statusTile(Icons.rate_review_outlined, 'To Review',
                    count: 3,
                    badgeColor: _PColors.amber,
                    badgeText: _PColors.amberText),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _buildActiveOrderCard(),
        ],
      ),
    );
  }

  Widget _statusTile(
    IconData icon,
    String label, {
    int? count,
    Color badgeColor = _PColors.forestDeep,
    Color badgeText = Colors.white,
    bool highlighted = false,
    bool strong = false,
  }) {
    return Expanded(
      child: InkWell(
        onTap: _openOrders,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: highlighted
                          ? _PColors.sageSoft.withAlpha(102)
                          : _PColors.tileFill,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 20, color: _PColors.forestDeep),
                  ),
                  if (count != null)
                    Positioned(
                      top: -2,
                      right: -2,
                      child: Container(
                        width: 16,
                        height: 16,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: badgeColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Text(
                          '$count',
                          style: _jakarta(
                            size: 9,
                            weight: FontWeight.w700,
                            color: badgeText,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: _jakarta(
                  size: 11,
                  weight: strong ? FontWeight.w700 : FontWeight.w500,
                  color: strong ? _PColors.forestDeep : _PColors.inkSoft,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveOrderCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.electric_moped_outlined,
                  size: 18, color: _PColors.secondary),
              const SizedBox(width: 6),
              Text(
                'OUT FOR DELIVERY',
                style: _jakarta(
                  size: 11,
                  weight: FontWeight.w700,
                  letterSpacing: 0.9,
                  color: _PColors.secondary,
                ),
              ),
              const Spacer(),
              Text(
                'Arriving Today',
                style: _jakarta(size: 12, color: _PColors.inkSoft),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(height: 1, color: _PColors.divider),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _PColors.tileFill,
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: _PColors.outlineSoft.withAlpha(51)),
                ),
                child: const Icon(Icons.local_florist_outlined,
                    size: 24, color: _PColors.secondary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Handcrafted Ceramic Planter + 1 item',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _playfair(
                        size: 15,
                        weight: FontWeight.w500,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Zero-emission EV Fleet • Metro Manila',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _jakarta(size: 12, color: _PColors.inkSoft),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _openOrders,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _PColors.forest,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      'Track Order',
                      style: _jakarta(
                        size: 12,
                        weight: FontWeight.w600,
                        letterSpacing: 0.2,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _openOrders,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  decoration: BoxDecoration(
                    color: _PColors.tileFill,
                    borderRadius: BorderRadius.circular(99),
                    border:
                        Border.all(color: _PColors.outlineSoft.withAlpha(51)),
                  ),
                  child: Text(
                    'Details',
                    style: _jakarta(
                      size: 12,
                      weight: FontWeight.w600,
                      letterSpacing: 0.2,
                      color: _PColors.forestDeep,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Menu sections (same rows + same destinations) ─────────
  Widget _buildMenu() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _menuSection('My Shopping', [
            _menuItem(
              Icons.receipt_long_outlined,
              'My Orders',
              trailingText: '12',
              onTap: _openOrders,
            ),
            _menuItem(
              Icons.favorite_outline_rounded,
              'Wishlist',
              trailingText: '5 items',
              onTap: () => _push(const MockupWishlistScreen()),
            ),
            _menuItem(
              Icons.location_on_outlined,
              'Saved Addresses',
              onTap: () => _push(const MockupAddEditAddressScreen()),
            ),
          ]),
          const SizedBox(height: 20),
          _menuSection('Account', [
            _menuItem(
              Icons.person_outline_rounded,
              'Edit Profile',
              onTap: _openEditProfile,
            ),
            _menuItem(
              Icons.lock_outline_rounded,
              'Change Password',
              onTap: () => _push(const MockupChangePasswordScreen()),
            ),
            _menuItem(
              Icons.notifications_outlined,
              'Notifications',
              badgeLabel: '3 new',
              onTap: () => _push(const MockupNotificationsScreen()),
            ),
          ]),
          const SizedBox(height: 20),
          _menuSection('Preferences & Support', [
            _menuItem(
              Icons.help_outline_rounded,
              'Help & Support',
              onTap: () => _push(const MockupHelpSupportScreen()),
            ),
            _menuItem(Icons.policy_outlined, 'Privacy Policy'),
            _menuItem(Icons.article_outlined, 'Terms of Service'),
          ]),
        ],
      ),
    );
  }

  Widget _menuSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title.toUpperCase(),
            style: _jakarta(
              size: 11,
              weight: FontWeight.w700,
              letterSpacing: 0.9,
              color: _PColors.inkSoft,
            ),
          ),
        ),
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: _cardDecoration(),
          child: Column(
            children: [
              for (int i = 0; i < items.length; i++) ...[
                items[i],
                if (i < items.length - 1)
                  const Divider(
                    height: 1,
                    thickness: 1,
                    color: _PColors.divider,
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _menuItem(
    IconData icon,
    String label, {
    VoidCallback? onTap,
    String? trailingText,
    String? badgeLabel,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: _PColors.tileFill,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 18, color: _PColors.forestDeep),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: _jakarta(
                  size: 14,
                  weight: FontWeight.w500,
                ),
              ),
            ),
            if (badgeLabel != null)
              Container(
                margin: const EdgeInsets.only(right: 6),
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _PColors.sageSoft,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  badgeLabel,
                  style: _jakarta(
                    size: 11,
                    weight: FontWeight.w700,
                    color: _PColors.forestDeep,
                  ),
                ),
              ),
            if (trailingText != null)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Text(
                  trailingText,
                  style: _jakarta(size: 12, color: _PColors.inkSoft),
                ),
              ),
            const Icon(Icons.chevron_right_rounded,
                size: 18, color: _PColors.outline),
          ],
        ),
      ),
    );
  }

  // ── Version + Sign Out (still returns to the login) ───────
  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () async {
                await BuyerApi.instance.logout();
                if (!mounted) return;
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                      builder: (_) => const MockupBuyerLoginScreen()),
                  (route) => false,
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: _PColors.error,
                side: BorderSide(color: _PColors.error.withAlpha(102)),
                minimumSize: const Size(double.infinity, 48),
                shape: const StadiumBorder(),
              ),
              child: Text(
                'Log Out',
                style: _jakarta(
                  size: 14,
                  weight: FontWeight.w600,
                  letterSpacing: 0.1,
                  color: _PColors.error,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Nuvora Buyer v1.0.0 • Zero-Emission Marketplace',
            textAlign: TextAlign.center,
            style: _jakarta(
              size: 11,
              letterSpacing: 0.2,
              color: _PColors.outline,
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}


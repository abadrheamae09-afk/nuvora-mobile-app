// ============================================================
// mockup_screens_index.dart
// Preview launcher: lists every mockup screen as a tappable
// button so you can open any screen directly during design
// review.
//
// HOW TO USE:
//   In your test entry point (e.g. a temporary main_mockup.dart),
//   set home: const MockupScreensIndex()
//   This file is NOT hooked into main.dart or existing routes.
// ============================================================

import 'package:flutter/material.dart';

import 'mockup_theme.dart';
import 'mockup_widgets.dart';

// ── All mockup screens ──────────────────────────────────────
import 'splash_screen.dart';
import '../../../auth/buyer_login_screen.dart';
import '../../../auth/buyer_register_screen.dart';
import 'forgot_password_screen.dart';
import '../../../auth/otp_verification_screen.dart';
import 'home_screen.dart';
import 'category_list_screen.dart';
import 'product_list_screen.dart';
import 'search_results_screen.dart';
import 'product_details_screen.dart';
import 'seller_store_screen.dart';
import 'wishlist_screen.dart';
import 'cart_screen.dart';
import 'checkout_screen.dart';
import 'address_select_screen.dart';
import 'add_edit_address_screen.dart';
import 'order_confirmation_screen.dart';
import 'my_orders_screen.dart';
import 'order_details_screen.dart';
import 'order_tracking_screen.dart';
import 'cancel_order_screen.dart';
import 'rate_review_screen.dart';
import 'profile_screen.dart';
import 'edit_profile_screen.dart';
import 'change_password_screen.dart';
import 'notifications_screen.dart';
import 'help_support_screen.dart';

// ── Screen catalogue ─────────────────────────────────────────

class _Section {
  const _Section({required this.title, required this.items});

  final String title;
  final List<_Item> items;
}

class _Item {
  const _Item({required this.label, required this.builder});

  final String label;
  final WidgetBuilder builder;
}

final List<_Section> _catalogue = [
  _Section(
    title: '🚀 Onboarding & Account',
    items: [
      _Item(
        label: 'Splash Screen',
        builder: (_) => const MockupSplashScreen(),
      ),
      _Item(
        label: 'Buyer Login',
        builder: (_) => const MockupBuyerLoginScreen(),
      ),
      _Item(
        label: 'Buyer Register',
        builder: (_) => const MockupBuyerRegisterScreen(),
      ),
      _Item(
        label: 'Forgot Password',
        builder: (_) => const MockupForgotPasswordScreen(),
      ),
      _Item(
        label: 'OTP Verification',
        builder: (_) => const MockupOtpVerificationScreen(
          email: 'juan@example.com',
        ),
      ),
    ],
  ),
  _Section(
    title: '🛍️ Browsing & Discovery',
    items: [
      _Item(
        label: 'Home',
        builder: (_) => const MockupHomeScreen(),
      ),
      _Item(
        label: 'Category List',
        builder: (_) => const MockupCategoryListScreen(),
      ),
      _Item(
        label: 'Product List',
        builder: (_) => const MockupProductListScreen(
          title: 'Electronics',
        ),
      ),
      _Item(
        label: 'Search Results',
        builder: (_) => const MockupSearchResultsScreen(),
      ),
      _Item(
        label: 'Product Details',
        builder: (_) => const MockupProductDetailsScreen(),
      ),
      _Item(
        label: 'Seller Store',
        builder: (_) => const MockupSellerStoreScreen(),
      ),
    ],
  ),
  _Section(
    title: '❤️ Wishlist & Cart',
    items: [
      _Item(
        label: 'Wishlist',
        builder: (_) => const MockupWishlistScreen(),
      ),
      _Item(
        label: 'Cart',
        builder: (_) => const MockupCartScreen(),
      ),
    ],
  ),
  _Section(
    title: '💳 Checkout',
    items: [
      _Item(
        label: 'Checkout',
        builder: (_) => const MockupCheckoutScreen(),
      ),
      _Item(
        label: 'Address Select',
        builder: (_) => const MockupAddressSelectScreen(),
      ),
      _Item(
        label: 'Add / Edit Address',
        builder: (_) => const MockupAddEditAddressScreen(),
      ),
      _Item(
        label: 'Order Confirmation',
        builder: (_) => const MockupOrderConfirmationScreen(),
      ),
    ],
  ),
  _Section(
    title: '📦 Orders',
    items: [
      _Item(
        label: 'My Orders (To Pay)',
        builder: (_) =>
            const MockupMyOrdersScreen(initialTab: 0),
      ),
      _Item(
        label: 'My Orders (To Receive)',
        builder: (_) =>
            const MockupMyOrdersScreen(initialTab: 2),
      ),
      _Item(
        label: 'My Orders (Completed)',
        builder: (_) =>
            const MockupMyOrdersScreen(initialTab: 3),
      ),
      _Item(
        label: 'Order Details',
        builder: (_) => const MockupOrderDetailsScreen(
          orderId: '20261102-015',
        ),
      ),
      _Item(
        label: 'Order Tracking',
        builder: (_) => const MockupOrderTrackingScreen(
          orderId: '20261102-015',
        ),
      ),
      _Item(
        label: 'Cancel Order',
        builder: (_) => const MockupCancelOrderScreen(),
      ),
      _Item(
        label: 'Rate & Review',
        builder: (_) => const MockupRateReviewScreen(),
      ),
    ],
  ),
  _Section(
    title: '👤 Profile & Settings',
    items: [
      _Item(
        label: 'Profile',
        builder: (_) => const MockupProfileScreen(),
      ),
      _Item(
        label: 'Edit Profile',
        builder: (_) => const MockupEditProfileScreen(),
      ),
      _Item(
        label: 'Change Password',
        builder: (_) => const MockupChangePasswordScreen(),
      ),
      _Item(
        label: 'Notifications',
        builder: (_) => const MockupNotificationsScreen(),
      ),
      _Item(
        label: 'Help & Support',
        builder: (_) => const MockupHelpSupportScreen(),
      ),
    ],
  ),
];

// ── Index screen ─────────────────────────────────────────────

class MockupScreensIndex extends StatelessWidget {
  const MockupScreensIndex({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MColors.background,
      body: CustomScrollView(
        slivers: [
          // ── Hero header ──────────────────────────────────
          SliverToBoxAdapter(child: _buildHeader()),
          // ── Sections ────────────────────────────────────
          ..._catalogue.map((section) => _buildSection(context, section)),
          // ── Footer ──────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 48),
              child: Text(
                '${_catalogue.fold(0, (s, sec) => s + sec.items.length)} screens total · Nuvora Buyer Mockups',
                style: MTextStyles.caption.copyWith(fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return MGradientHeader(
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(30),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.shopping_bag_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Nuvora Buyer',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.3,
                        ),
                      ),
                      Text(
                        'UI Mockup Preview',
                        style: TextStyle(
                          color: Colors.white.withAlpha(200),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: Colors.white.withAlpha(40)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline,
                        color: Colors.white, size: 16),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Tap any screen to preview. Hardcoded dummy data only — no backend calls.',
                        style: TextStyle(
                          color: Colors.white.withAlpha(220),
                          fontSize: 12,
                          height: 1.4,
                        ),
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
  }

  SliverToBoxAdapter _buildSection(
      BuildContext context, _Section section) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section title
            Text(section.title, style: MTextStyles.title),
            const SizedBox(height: 10),
            // Screen buttons
            Container(
              decoration: MDecorations.card(),
              child: Column(
                children:
                    section.items.asMap().entries.map((entry) {
                  final i = entry.key;
                  final item = entry.value;
                  final isLast = i == section.items.length - 1;

                  return Column(
                    children: [
                      InkWell(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: item.builder),
                        ),
                        borderRadius: BorderRadius.circular(14),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: MColors.primarySoft,
                                  borderRadius:
                                      BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.phone_android_rounded,
                                  size: 18,
                                  color: MColors.primary,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  item.label,
                                  style: MTextStyles.body,
                                ),
                              ),
                              const Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 14,
                                color: MColors.muted,
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (!isLast)
                        const Divider(
                          height: 1,
                          indent: 66,
                          color: MColors.divider,
                        ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

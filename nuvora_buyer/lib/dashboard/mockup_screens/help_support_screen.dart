// ============================================================
// help_support_screen.dart
// Help & Support: FAQs, contact channels, and ticket form.
// ============================================================

import 'package:flutter/material.dart';
import 'mockup_theme.dart';
import 'mockup_widgets.dart';
import '../../core/navigation/buyer_nav_bar.dart';

// ── FAQ data ─────────────────────────────────────────────────

const List<Map<String, String>> _faqs = [
  {
    'q': 'How do I track my order?',
    'a':
        'Go to My Orders, select the order, and tap "Track Shipment" to see real-time delivery status and rider information.',
  },
  {
    'q': 'Can I cancel my order?',
    'a':
        'You can cancel an order while it is still in "To Pay" or "To Ship" status. Once the seller has packed your order, cancellation may no longer be possible.',
  },
  {
    'q': 'How do I request a refund?',
    'a':
        'After receiving your order, you can raise a return/refund request within 7 days. Go to the order in My Orders and tap "Return / Refund".',
  },
  {
    'q': 'What payment methods are accepted?',
    'a':
        'We accept Cash on Delivery (COD), GCash, debit/credit cards, and online banking.',
  },
  {
    'q': 'Why was my order cancelled by the seller?',
    'a':
        'Sellers may cancel if the item is out of stock or if there was a pricing error. You will receive a full refund if payment was made.',
  },
  {
    'q': 'How do I contact the seller?',
    'a':
        'Open the product page or your order details and tap the "Message Seller" button to start a chat.',
  },
  {
    'q': 'How do I change my delivery address?',
    'a':
        'You can change the address during checkout before placing the order. After the order is placed, address changes are not guaranteed.',
  },
];

class MockupHelpSupportScreen extends StatefulWidget {
  const MockupHelpSupportScreen({super.key});

  @override
  State<MockupHelpSupportScreen> createState() =>
      _MockupHelpSupportScreenState();
}

class _MockupHelpSupportScreenState
    extends State<MockupHelpSupportScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;
  int? _expandedFaq;

  // Contact form
  final _formKey = GlobalKey<FormState>();
  final _subjectCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _subjectCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  void _submitTicket() {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      setState(() => _submitting = false);
      _subjectCtrl.clear();
      _messageCtrl.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Support ticket submitted! We\'ll reply within 24 hours.'),
          backgroundColor: MColors.success,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: const BuyerNavBar(current: BuyerTab.account),
      backgroundColor: MColors.background,
      appBar: AppBar(
        backgroundColor: MColors.background,
        elevation: 0,
        foregroundColor: MColors.ink,
        title: const Text('Help & Support', style: MTextStyles.title),
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: MColors.primary,
          unselectedLabelColor: MColors.muted,
          indicatorColor: MColors.primary,
          indicatorWeight: 3,
          labelStyle: MTextStyles.subtitle.copyWith(fontSize: 13),
          unselectedLabelStyle:
              MTextStyles.caption.copyWith(fontSize: 13),
          tabs: const [
            Tab(text: 'FAQs'),
            Tab(text: 'Contact Us'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _buildFaqTab(),
          _buildContactTab(),
        ],
      ),
    );
  }

  // ── FAQ tab ───────────────────────────────────────────────

  Widget _buildFaqTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Search bar (mockup, non-functional)
        Container(
          height: 46,
          decoration: MDecorations.card(),
          child: Row(
            children: [
              const SizedBox(width: 14),
              const Icon(Icons.search, color: MColors.muted, size: 20),
              const SizedBox(width: 10),
              Text(
                'Search FAQs...',
                style: MTextStyles.body.copyWith(color: MColors.muted),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: MDecorations.card(),
          child: Column(
            children: _faqs.asMap().entries.map((entry) {
              final i = entry.key;
              final faq = entry.value;
              final isOpen = _expandedFaq == i;
              final isLast = i == _faqs.length - 1;

              return Column(
                children: [
                  InkWell(
                    onTap: () => setState(
                        () => _expandedFaq = isOpen ? null : i),
                    borderRadius: BorderRadius.circular(14),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              faq['q']!,
                              style: MTextStyles.subtitle.copyWith(
                                fontSize: 14,
                                color: isOpen
                                    ? MColors.primary
                                    : MColors.ink,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          AnimatedRotation(
                            turns: isOpen ? 0.5 : 0,
                            duration:
                                const Duration(milliseconds: 250),
                            child: Icon(
                              Icons.expand_more_rounded,
                              color: isOpen
                                  ? MColors.primary
                                  : MColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    child: isOpen
                        ? Padding(
                            padding: const EdgeInsets.fromLTRB(
                                16, 0, 16, 16),
                            child: Text(
                              faq['a']!,
                              style: MTextStyles.body.copyWith(
                                color: MColors.muted,
                                height: 1.6,
                                fontSize: 13,
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                  if (!isLast)
                    const Divider(
                        height: 1, color: MColors.divider),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // ── Contact tab ───────────────────────────────────────────

  Widget _buildContactTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Channel cards
        _channelCard(
          icon: Icons.chat_bubble_outline_rounded,
          iconColor: MColors.primary,
          iconBg: MColors.primarySoft,
          title: 'Live Chat',
          subtitle: 'Avg. response: < 5 minutes',
          action: 'Start Chat',
          onTap: () {},
        ),
        const SizedBox(height: 10),
        _channelCard(
          icon: Icons.email_outlined,
          iconColor: MColors.info,
          iconBg: MColors.infoSoft,
          title: 'Email Support',
          subtitle: 'support@nuvora.ph',
          action: 'Send Email',
          onTap: () {},
        ),
        const SizedBox(height: 10),
        _channelCard(
          icon: Icons.phone_outlined,
          iconColor: MColors.success,
          iconBg: MColors.successSoft,
          title: 'Phone Hotline',
          subtitle: '(02) 8888-NUVO · Mon–Sat 8AM–8PM',
          action: 'Call Now',
          onTap: () {},
        ),
        const SizedBox(height: 20),
        // Submit ticket form
        const Text('Submit a Ticket', style: MTextStyles.subtitle),
        const SizedBox(height: 12),
        Container(
          decoration: MDecorations.card(),
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                MTextField(
                  controller: _subjectCtrl,
                  label: 'Subject',
                  prefixIcon: Icons.subject_outlined,
                  validator: (v) => (v == null || v.isEmpty)
                      ? 'Enter a subject'
                      : null,
                ),
                const SizedBox(height: 14),
                MTextField(
                  controller: _messageCtrl,
                  label: 'Describe your issue...',
                  maxLines: 5,
                  validator: (v) => (v == null || v.length < 20)
                      ? 'Please provide more detail (min 20 chars)'
                      : null,
                ),
                const SizedBox(height: 16),
                MPrimaryButton(
                  label: 'Submit Ticket',
                  onPressed: _submitTicket,
                  isLoading: _submitting,
                  icon: Icons.send_rounded,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _channelCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    required String action,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: MDecorations.card(),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: MTextStyles.subtitle),
                const SizedBox(height: 2),
                Text(subtitle, style: MTextStyles.caption),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: onTap,
            style: OutlinedButton.styleFrom(
              foregroundColor: MColors.primary,
              side: const BorderSide(color: MColors.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 8),
            ),
            child: Text(action,
                style: const TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

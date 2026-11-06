// ============================================================
// add_edit_address_screen.dart
// Add or edit a delivery address.
// (Botanical Boutique redesign)
// ============================================================

import 'package:flutter/material.dart';

// ------------------------------------------------------------
// Design tokens for this screen (Botanical Boutique design
// system). Private so nothing else in the app is affected.
// ------------------------------------------------------------
class _T {
  // Surfaces
  static const background = Color(0xFFFCF9F8);
  static const surfaceLowest = Color(0xFFFFFFFF);
  static const surfaceLow = Color(0xFFF6F3F2);
  static const surfaceContainer = Color(0xFFF0EDED);
  static const surfaceHighest = Color(0xFFE5E2E1);

  // Text / outline
  static const onSurface = Color(0xFF1C1B1B);
  static const onSurfaceVariant = Color(0xFF424844);
  static const outline = Color(0xFF727973);
  static const outlineVariant = Color(0xFFC1C8C2);

  // Brand
  static const primary = Color(0xFF012114);
  static const primaryContainer = Color(0xFF173628);
  static const primaryFixed = Color(0xFFC7EBD6);
  static const secondary = Color(0xFF44664B);
  static const secondaryFixed = Color(0xFFC5ECCA);

  // Status
  static const error = Color(0xFFBA1A1A);

  // Shadows
  static const shadow = Color(0x0A173628); // 4%
  static const hairline = Color(0x0D012114); // primary @ 5%

  // Fonts (add Playfair Display + Plus Jakarta Sans to the project)
  static const serif = 'Playfair Display';
  static const sans = 'Plus Jakarta Sans';

  static const headlineSm = TextStyle(
    fontFamily: serif,
    fontSize: 18,
    height: 24 / 18,
    fontWeight: FontWeight.w600,
    color: primary,
  );
  static const bodyMd = TextStyle(
    fontFamily: sans,
    fontSize: 14,
    height: 20 / 14,
    color: onSurface,
  );
  static const bodySm = TextStyle(
    fontFamily: sans,
    fontSize: 12,
    height: 18 / 12,
    color: onSurfaceVariant,
  );
  static const labelLg = TextStyle(
    fontFamily: sans,
    fontSize: 14,
    height: 18 / 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.14,
  );
  static const labelMd = TextStyle(
    fontFamily: sans,
    fontSize: 12,
    height: 16 / 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.24,
  );
  static const labelSm = TextStyle(
    fontFamily: sans,
    fontSize: 11,
    height: 14 / 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.88,
  );

  static final cardDecoration = BoxDecoration(
    color: surfaceLowest,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: hairline),
    boxShadow: const [
      BoxShadow(
        color: shadow,
        blurRadius: 16,
        spreadRadius: -2,
        offset: Offset(0, 4),
      ),
    ],
  );
}

class MockupAddEditAddressScreen extends StatefulWidget {
  const MockupAddEditAddressScreen({super.key, this.isEdit = false});

  final bool isEdit;

  @override
  State<MockupAddEditAddressScreen> createState() =>
      _MockupAddEditAddressScreenState();
}

class _MockupAddEditAddressScreenState
    extends State<MockupAddEditAddressScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController(text: 'Juan Dela Cruz');
  final _phoneCtrl = TextEditingController(text: '09171234567');
  final _provinceCtrl = TextEditingController(text: 'Metro Manila');
  final _municipalityCtrl = TextEditingController(text: 'Quezon City');
  final _barangayCtrl = TextEditingController(text: 'Batasan Hills');
  final _streetCtrl = TextEditingController(text: '123 Sample Street');
  final _postalCtrl = TextEditingController(text: '1126');
  final _labelCtrl = TextEditingController(text: 'Home');

  bool _isDefault = true;
  bool _loading = false;

  @override
  void dispose() {
    for (final c in [
      _nameCtrl, _phoneCtrl, _provinceCtrl, _municipalityCtrl,
      _barangayCtrl, _streetCtrl, _postalCtrl, _labelCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      setState(() => _loading = false);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              widget.isEdit ? 'Address updated.' : 'Address saved.'),
          backgroundColor: _T.secondary,
        ),
      );
    });
  }

  String? _required(String? v) => (v == null || v.isEmpty) ? 'Required' : null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _T.background,
      appBar: _buildAppBar(context),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            _buildBreadcrumb(),
            const SizedBox(height: 20),
            _buildContactCard(),
            const SizedBox(height: 20),
            _buildAddressCard(),
            const SizedBox(height: 20),
            _buildLabelCard(),
            const SizedBox(height: 20),
            _buildPreferencesCard(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  // ----------------------------------------------------------
  // App bar
  // ----------------------------------------------------------
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: _T.background,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      toolbarHeight: 64,
      foregroundColor: _T.primary,
      leading: IconButton(
        tooltip: 'Back',
        icon: const Icon(Icons.arrow_back, color: _T.primary),
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      title: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('NUVORA SHIPPING',
              style: _T.labelSm.copyWith(
                  color: _T.secondary, letterSpacing: 1.4)),
          const SizedBox(height: 2),
          Text(
            widget.isEdit ? 'Edit Address' : 'Add New Address',
            style: _T.headlineSm,
          ),
        ],
      ),
      actions: [
        IconButton(
          tooltip: 'Help',
          icon: const Icon(Icons.help_outline, color: _T.primary),
          onPressed: () {}, // design-only for now
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: const Color(0x0F173628)),
      ),
    );
  }

  Widget _buildBreadcrumb() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.spa, size: 16, color: _T.secondary),
              const SizedBox(width: 6),
              Text('Botanical Delivery Network',
                  style: _T.labelMd.copyWith(color: _T.secondary)),
            ],
          ),
          Text('Philippines',
              style: _T.bodySm.copyWith(color: _T.outline)),
        ],
      ),
    );
  }

  // ----------------------------------------------------------
  // Shared pieces
  // ----------------------------------------------------------
  Widget _cardHeader(IconData icon, String title) {
    return Container(
      padding: const EdgeInsets.only(bottom: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _T.surfaceContainer)),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _T.secondaryFixed.withOpacity(0.5),
            ),
            child: Icon(icon, size: 17, color: _T.primary),
          ),
          const SizedBox(width: 10),
          Text(title, style: _T.headlineSm),
        ],
      ),
    );
  }

  OutlineInputBorder _border(Color color, {double width = 1}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color, width: width),
      );

  Widget _field({
    required String label,
    required TextEditingController controller,
    IconData? icon,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(label,
              style: _T.labelMd.copyWith(color: _T.onSurface)),
        ),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: _required,
          style: _T.bodyMd,
          cursorColor: _T.primaryContainer,
          decoration: InputDecoration(
            filled: true,
            fillColor: _T.surfaceLow,
            contentPadding: EdgeInsets.fromLTRB(
                icon == null ? 16 : 0, 14, 16, 14),
            prefixIcon: icon == null
                ? null
                : Icon(icon, size: 20, color: _T.outline),
            enabledBorder: _border(_T.outlineVariant.withOpacity(0.5)),
            focusedBorder: _border(_T.primary, width: 1.5),
            errorBorder: _border(_T.error),
            focusedErrorBorder: _border(_T.error, width: 1.5),
            errorStyle: _T.bodySm.copyWith(color: _T.error),
          ),
        ),
      ],
    );
  }

  // ----------------------------------------------------------
  // Contact card
  // ----------------------------------------------------------
  Widget _buildContactCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _T.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeader(Icons.person_outline, 'Contact Information'),
          const SizedBox(height: 16),
          _field(
            label: 'Full Name',
            controller: _nameCtrl,
            icon: Icons.person_outline,
          ),
          const SizedBox(height: 16),
          _field(
            label: 'Phone Number',
            controller: _phoneCtrl,
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------
  // Address details card
  // ----------------------------------------------------------
  Widget _buildAddressCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _T.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeader(Icons.location_on_outlined, 'Address Details'),
          const SizedBox(height: 16),

          // Use current location (design-only for now)
          Material(
            color: _T.surfaceLow,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {},
              child: Ink(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: _T.outlineVariant.withOpacity(0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.my_location,
                        size: 20, color: _T.secondary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('Use Current Location',
                          style: _T.labelMd.copyWith(color: _T.primary)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _T.secondaryFixed,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.pin_drop_outlined,
                              size: 13, color: _T.primary),
                          const SizedBox(width: 4),
                          Text('Pin on Map',
                              style: _T.labelSm.copyWith(
                                  color: _T.primary, letterSpacing: 0.3)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          _field(
            label: 'Province / Region',
            controller: _provinceCtrl,
            icon: Icons.map_outlined,
          ),
          const SizedBox(height: 16),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _field(
                  label: 'Municipality / City',
                  controller: _municipalityCtrl,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _field(
                  label: 'Barangay',
                  controller: _barangayCtrl,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          _field(
            label: 'Postal Code',
            controller: _postalCtrl,
            icon: Icons.markunread_mailbox_outlined,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),

          _field(
            label: 'Street / House No. / Landmark',
            controller: _streetCtrl,
            icon: Icons.add_road_outlined,
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------
  // Address label picker (same _labelCtrl logic as before)
  // ----------------------------------------------------------
  Widget _buildLabelCard() {
    const options = <(String, IconData, IconData)>[
      ('Home', Icons.cottage_outlined, Icons.cottage),
      ('Office', Icons.apartment_outlined, Icons.apartment),
      ('Other', Icons.place_outlined, Icons.place),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _T.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Address Label', style: _T.headlineSm),
          const SizedBox(height: 8),
          Row(
            children: [
              for (int i = 0; i < options.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(
                  child: _labelTile(
                    options[i].$1,
                    options[i].$2,
                    options[i].$3,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _labelTile(String l, IconData icon, IconData iconFilled) {
    final sel = _labelCtrl.text == l;
    return Material(
      color: sel ? _T.primary : _T.surfaceLow,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => setState(() => _labelCtrl.text = l),
        child: Ink(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: sel
                  ? _T.primary
                  : _T.outlineVariant.withOpacity(0.4),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(sel ? iconFilled : icon,
                  size: 20, color: sel ? Colors.white : _T.outline),
              const SizedBox(height: 4),
              Text(
                l,
                style: _T.labelMd.copyWith(
                    color: sel ? Colors.white : _T.onSurface),
              ),
              const SizedBox(height: 2),
              SizedBox(
                height: 14,
                child: sel
                    ? const Icon(Icons.check_circle_outline,
                        size: 13, color: _T.primaryFixed)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ----------------------------------------------------------
  // Preferences: default toggle + COD notice
  // ----------------------------------------------------------
  Widget _buildPreferencesCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _T.cardDecoration,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Set as default address',
                        style: _T.labelLg.copyWith(color: _T.primary)),
                    const SizedBox(height: 2),
                    const Text(
                      'This address will be pre-selected at checkout.',
                      style: _T.bodySm,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Switch(
                value: _isDefault,
                onChanged: (v) => setState(() => _isDefault = v),
                activeColor: Colors.white,
                activeTrackColor: _T.primary,
                inactiveThumbColor: Colors.white,
                inactiveTrackColor: _T.surfaceHighest,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: _T.surfaceContainer),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _T.surfaceLow,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _T.secondaryFixed),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(Icons.local_shipping_outlined,
                      size: 22, color: _T.secondary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      style: _T.bodySm.copyWith(color: _T.onSurface),
                      children: [
                        const TextSpan(text: 'All NUVORA deliveries support '),
                        TextSpan(
                          text: 'Cash on Delivery (COD)',
                          style: _T.bodySm.copyWith(
                            color: _T.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const TextSpan(
                          text:
                              '. Please ensure your contact number is reachable upon dispatch.',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------
  // Fixed bottom action bar
  // ----------------------------------------------------------
  Widget _buildBottomBar() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xF2FCF9F8), // surface @ 95%
        border: Border(top: BorderSide(color: _T.surfaceContainer)),
        boxShadow: [
          BoxShadow(
            color: Color(0x0F173628),
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _T.primaryContainer,
                    disabledBackgroundColor:
                        _T.primaryContainer.withOpacity(0.7),
                    foregroundColor: Colors.white,
                    disabledForegroundColor: Colors.white,
                    elevation: 2,
                    shadowColor: const Color(0x66173628),
                    padding: const EdgeInsets.symmetric(
                        vertical: 15, horizontal: 24),
                    shape: const StadiumBorder(),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              widget.isEdit
                                  ? 'Update Address'
                                  : 'Save Address',
                              style: _T.labelLg
                                  .copyWith(color: Colors.white),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.check_circle_outline,
                                size: 20),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock_outline,
                      size: 14, color: _T.secondary),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      '256-BIT ENCRYPTED • ADDRESS PRIVACY',
                      textAlign: TextAlign.center,
                      style: _T.labelSm.copyWith(
                        color: _T.outline,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.9,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
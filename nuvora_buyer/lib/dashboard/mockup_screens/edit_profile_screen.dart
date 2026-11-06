// ============================================================
// edit_profile_screen.dart
// Edit buyer profile info: name, phone, birthday, avatar.
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

  // Text / outline
  static const onSurface = Color(0xFF1C1B1B);
  static const onSurfaceVariant = Color(0xFF424844);
  static const outline = Color(0xFF727973);
  static const outlineVariant = Color(0xFFC1C8C2);

  // Brand
  static const primary = Color(0xFF012114);
  static const primaryContainer = Color(0xFF173628);
  static const secondary = Color(0xFF44664B);
  static const secondaryContainer = Color(0xFFC2E9C7);

  // Status
  static const error = Color(0xFFBA1A1A);

  // Shadows
  static const shadow = Color(0x0A173628); // 4%
  static const buttonShadow = Color(0x33173628); // 20%

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
    fontWeight: FontWeight.w700,
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
    fontWeight: FontWeight.w600,
    letterSpacing: 0.4,
  );
}

class MockupEditProfileScreen extends StatefulWidget {
  const MockupEditProfileScreen({super.key});

  @override
  State<MockupEditProfileScreen> createState() =>
      _MockupEditProfileScreenState();
}

class _MockupEditProfileScreenState extends State<MockupEditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final _firstNameCtrl = TextEditingController(text: 'Juan');
  final _lastNameCtrl = TextEditingController(text: 'Dela Cruz');
  final _emailCtrl = TextEditingController(text: 'juan@example.com');
  final _phoneCtrl = TextEditingController(text: '09171234567');
  final _birthdayCtrl = TextEditingController(text: '1995-06-15');

  bool _loading = false;

  @override
  void dispose() {
    for (final c in [
      _firstNameCtrl, _lastNameCtrl, _emailCtrl,
      _phoneCtrl, _birthdayCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickBirthday() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1995, 6, 15),
      firstDate: DateTime(1920),
      lastDate: DateTime(now.year - 18, now.month, now.day),
    );
    if (picked == null) return;
    _birthdayCtrl.text =
        '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    setState(() {});
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      setState(() => _loading = false);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully.'),
          backgroundColor: _T.secondary,
        ),
      );
    });
  }

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
            _buildAvatar(),
            const SizedBox(height: 24),
            _buildPersonalInfoCard(),
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
        icon: const Icon(Icons.chevron_left, size: 28, color: _T.primary),
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      title: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Edit Profile', style: _T.headlineSm),
          Text(
            'NUVORA ACCOUNT',
            style: _T.labelSm.copyWith(
                color: _T.onSurfaceVariant, letterSpacing: 0.9),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: TextButton(
            onPressed: _loading ? null : _save,
            style: TextButton.styleFrom(
              foregroundColor: _T.primaryContainer,
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            child: Text('Save',
                style: _T.labelLg.copyWith(color: _T.primaryContainer)),
          ),
        ),
      ],
    );
  }

  // ----------------------------------------------------------
  // Avatar
  // ----------------------------------------------------------
  Widget _buildAvatar() {
    return Column(
      children: [
        SizedBox(
          width: 112,
          height: 112,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 112,
                height: 112,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _T.surfaceLowest,
                  border:
                      Border.all(color: _T.outlineVariant.withOpacity(0.3)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1F173628),
                      blurRadius: 24,
                      spreadRadius: -4,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: _T.secondaryContainer,
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'J',
                    style: TextStyle(
                      fontFamily: _T.serif,
                      color: _T.primaryContainer,
                      fontSize: 40,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _T.primaryContainer,
                    shape: BoxShape.circle,
                    border: Border.all(color: _T.surfaceLowest, width: 2),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x40173628),
                        blurRadius: 12,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.photo_camera_outlined,
                      size: 18, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Photo actions are design-only for now (no handlers existed)
            GestureDetector(
              onTap: () {},
              child: Text('Change Photo',
                  style: _T.labelMd.copyWith(color: _T.primaryContainer)),
            ),
            const SizedBox(width: 12),
            Container(
              width: 4,
              height: 4,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: _T.outlineVariant,
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () {},
              child: Text(
                'Remove Photo',
                style: _T.labelMd.copyWith(
                  fontWeight: FontWeight.w400,
                  color: _T.onSurfaceVariant.withOpacity(0.8),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ----------------------------------------------------------
  // Personal information card
  // ----------------------------------------------------------
  Widget _buildPersonalInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _T.surfaceLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _T.outlineVariant.withOpacity(0.3)),
        boxShadow: const [
          BoxShadow(
            color: _T.shadow,
            blurRadius: 16,
            spreadRadius: -2,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card header
          Row(
            children: [
              const Icon(Icons.badge_outlined, size: 20, color: _T.primary),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('Personal Information', style: _T.headlineSm),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  color: _T.surfaceLow,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.verified_user_outlined,
                        size: 14, color: _T.secondary),
                    const SizedBox(width: 4),
                    Text('Protected',
                        style: _T.labelSm
                            .copyWith(color: _T.onSurfaceVariant)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(height: 1, color: _T.surfaceContainer),
          const SizedBox(height: 16),

          // First / Last name
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _field(
                  label: 'First Name',
                  controller: _firstNameCtrl,
                  icon: Icons.person_outline,
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Required' : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _field(
                  label: 'Last Name',
                  controller: _lastNameCtrl,
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Required' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Email (read-only per original label)
          _field(
            label: 'Email (read-only)',
            controller: _emailCtrl,
            icon: Icons.mail_outline,
            keyboardType: TextInputType.emailAddress,
            validator: null,
          ),
          const SizedBox(height: 6),
          const Text(
            'To change your email, use the Account Security settings.',
            style: _T.bodySm,
          ),
          const SizedBox(height: 16),

          // Phone
          _field(
            label: 'Phone Number',
            controller: _phoneCtrl,
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            validator: (v) =>
                (v == null || v.isEmpty) ? 'Required' : null,
          ),
          const SizedBox(height: 16),

          // Birthday (tap to open picker – same behaviour as before)
          GestureDetector(
            onTap: _pickBirthday,
            child: AbsorbPointer(
              child: _field(
                label: 'Birthday',
                controller: _birthdayCtrl,
                icon: Icons.calendar_today_outlined,
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Required' : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------
  // Field helper: label on top, soft filled input below
  // ----------------------------------------------------------
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
    required String? Function(String?)? validator,
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
          validator: validator,
          style: _T.bodyMd,
          cursorColor: _T.primaryContainer,
          decoration: InputDecoration(
            filled: true,
            fillColor: _T.background,
            contentPadding:
                EdgeInsets.fromLTRB(icon == null ? 16 : 0, 14, 16, 14),
            prefixIcon: icon == null
                ? null
                : Icon(icon, size: 20, color: _T.onSurfaceVariant),
            enabledBorder: _border(_T.outlineVariant.withOpacity(0.4)),
            focusedBorder: _border(_T.primaryContainer, width: 1.5),
            errorBorder: _border(_T.error),
            focusedErrorBorder: _border(_T.error, width: 1.5),
            errorStyle: _T.bodySm.copyWith(color: _T.error),
          ),
        ),
      ],
    );
  }

  // ----------------------------------------------------------
  // Fixed bottom action bar
  // ----------------------------------------------------------
  Widget _buildBottomBar() {
    return Container(
      decoration: BoxDecoration(
        color: _T.background.withOpacity(0.95),
        border: Border(
          top: BorderSide(color: _T.outlineVariant.withOpacity(0.2)),
        ),
        boxShadow: const [
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
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: const [
                    BoxShadow(
                      color: _T.buttonShadow,
                      blurRadius: 24,
                      spreadRadius: -4,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _T.primaryContainer,
                      disabledBackgroundColor:
                          _T.primaryContainer.withOpacity(0.7),
                      foregroundColor: Colors.white,
                      disabledForegroundColor: Colors.white,
                      elevation: 0,
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
                              const Icon(Icons.check_circle, size: 20),
                              const SizedBox(width: 8),
                              Text('Save Changes',
                                  style: _T.labelLg
                                      .copyWith(color: Colors.white)),
                            ],
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock_outline,
                      size: 13, color: _T.secondary),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      '256-bit secure encryption • Changes sync instantly across devices',
                      textAlign: TextAlign.center,
                      style: _T.labelSm
                          .copyWith(color: _T.onSurfaceVariant),
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
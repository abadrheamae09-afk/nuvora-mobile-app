

// ============================================================
// change_password_screen.dart
// Change account password. (Botanical Boutique redesign)
// ============================================================

import 'package:flutter/material.dart';
import '../../core/navigation/buyer_nav_bar.dart';

// ------------------------------------------------------------
// Design tokens for this screen (from the Botanical Boutique
// design system). Kept private so nothing else in the app is
// affected. Swap these for your shared theme tokens if you
// want to centralise them later.
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
  static const secondary = Color(0xFF44664B);
  static const secondaryContainer = Color(0xFFC2E9C7);
  static const onSecondaryFixedVariant = Color(0xFF2C4E35);

  // Status
  static const error = Color(0xFFBA1A1A);

  // Hairline border + ambient shadow (rgba(23,54,40,0.06 / 0.04))
  static const hairline = Color(0x0F173628);
  static const shadow = Color(0x0A173628);
  static const buttonShadow = Color(0x1F173628);

  // Fonts (add Playfair Display + Plus Jakarta Sans to your project,
  // via pubspec fonts or the google_fonts package)
  static const serif = 'Playfair Display';
  static const sans = 'Plus Jakarta Sans';

  static const headlineSm = TextStyle(
    fontFamily: serif,
    fontSize: 18,
    height: 24 / 18,
    fontWeight: FontWeight.w600,
    color: primary,
  );
  static const cardTitle = TextStyle(
    fontFamily: serif,
    fontSize: 16,
    height: 22 / 16,
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
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: hairline),
    boxShadow: const [
      BoxShadow(color: shadow, blurRadius: 16, spreadRadius: -2, offset: Offset(0, 4)),
    ],
  );
}

class MockupChangePasswordScreen extends StatefulWidget {
  const MockupChangePasswordScreen({super.key});

  @override
  State<MockupChangePasswordScreen> createState() =>
      _MockupChangePasswordScreenState();
}

class _MockupChangePasswordScreenState
    extends State<MockupChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _loading = false;

  // UI-only toggle from the redesign (not sent anywhere yet)
  bool _signOutOtherDevices = true;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  // ---- Password strength (drives the meter + checklist) ----
  bool get _hasLength => _newCtrl.text.length >= 8;
  bool get _hasUpper => RegExp(r'[A-Z]').hasMatch(_newCtrl.text);
  bool get _hasNumOrSpecial =>
      RegExp(r'[0-9]|[^A-Za-z0-9]').hasMatch(_newCtrl.text);

  /// 0 = empty, 1 = Weak, 2 = Fair, 3 = Good, 4 = Strong
  int get _score {
    if (_newCtrl.text.isEmpty) return 0;
    int s = 0;
    if (_hasLength) s++;
    if (_hasUpper) s++;
    if (_hasNumOrSpecial) s++;
    if (_newCtrl.text.length >= 12) s++;
    return s == 0 ? 1 : s;
  }

  String get _strengthLabel {
    switch (_score) {
      case 1:
        return 'Weak';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Strong';
      default:
        return '';
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      setState(() => _loading = false);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password changed successfully.'),
          backgroundColor: _T.secondary,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: const BuyerNavBar(current: BuyerTab.account),
      backgroundColor: _T.background,
      appBar: _buildAppBar(context),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          children: [
            _buildIntroCard(),
            const SizedBox(height: 24),
            _buildCurrentPassword(),
            const SizedBox(height: 24),
            Divider(
                height: 1, color: _T.outlineVariant.withOpacity(0.2)),
            const SizedBox(height: 24),
            _buildNewPassword(),
            const SizedBox(height: 24),
            _buildConfirmPassword(),
            const SizedBox(height: 24),
            _buildSecurityCard(),
            const SizedBox(height: 28),
            _buildActions(context),
            const SizedBox(height: 12),
            _buildFooter(),
            const SizedBox(height: 8),
          ],
        ),
      ),
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
          Text(
            'NUVORA SECURITY',
            style: _T.labelSm.copyWith(
                color: _T.onSurfaceVariant, letterSpacing: 1.1),
          ),
          const SizedBox(height: 2),
          const Text('Change Password', style: _T.headlineSm),
        ],
      ),
      actions: [
        IconButton(
          tooltip: 'Security help',
          icon: const Icon(Icons.help_outline, color: _T.onSurfaceVariant),
          onPressed: () {}, // design-only for now
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          color: _T.hairline,
        ),
      ),
    );
  }

  // ----------------------------------------------------------
  // Intro card
  // ----------------------------------------------------------
  Widget _buildIntroCard() {
    return Container(
      decoration: _T.cardDecoration,
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            right: -16,
            bottom: -16,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _T.secondaryContainer.withOpacity(0.3),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  margin: const EdgeInsets.only(top: 2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _T.secondaryContainer.withOpacity(0.5),
                  ),
                  child: const Icon(Icons.shield_outlined,
                      size: 18, color: _T.secondary),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Account Protection', style: _T.cardTitle),
                      SizedBox(height: 4),
                      Text(
                        'Keep your NUVORA account safe. Choose a strong, unique password with at least 8 characters.',
                        style: _T.bodySm,
                      ),
                    ],
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
  // Field helpers
  // ----------------------------------------------------------
  Widget _fieldHeader(String label, Widget trailing) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: _T.labelMd.copyWith(color: _T.primary)),
          trailing,
        ],
      ),
    );
  }

  Widget _hint(String text) =>
      Text(text, style: _T.labelSm.copyWith(color: _T.outline, letterSpacing: 0.4));

  OutlineInputBorder _border(Color color, {double width = 1}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color, width: width),
      );

  Widget _passwordField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required bool obscure,
    required VoidCallback onToggle,
    required String? Function(String?) validator,
    ValueChanged<String>? onChanged,
    Color? borderColor,
    Color? focusColor,
  }) {
    final base = borderColor ?? _T.outlineVariant.withOpacity(0.6);
    final focus = focusColor ?? _T.primaryContainer;
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      onChanged: onChanged,
      validator: validator,
      style: _T.bodyMd,
      cursorColor: _T.primaryContainer,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: _T.bodyMd.copyWith(color: _T.outline.withOpacity(0.7)),
        filled: true,
        fillColor: _T.surfaceLowest,
        isDense: false,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        prefixIcon: Icon(icon, size: 20, color: _T.outline),
        suffixIcon: IconButton(
          icon: Icon(
            obscure
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            size: 20,
            color: _T.onSurfaceVariant,
          ),
          onPressed: onToggle,
        ),
        enabledBorder: _border(base),
        focusedBorder: _border(focus, width: 1.5),
        errorBorder: _border(_T.error),
        focusedErrorBorder: _border(_T.error, width: 1.5),
        errorStyle: _T.bodySm.copyWith(color: _T.error),
      ),
    );
  }

  // ----------------------------------------------------------
  // 1. Current password
  // ----------------------------------------------------------
  Widget _buildCurrentPassword() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldHeader('Current Password', _hint('Required')),
        const SizedBox(height: 6),
        _passwordField(
          controller: _currentCtrl,
          hint: 'Enter current password',
          icon: Icons.lock_outline,
          obscure: _obscureCurrent,
          onToggle: () => setState(() => _obscureCurrent = !_obscureCurrent),
          validator: (v) =>
              (v == null || v.isEmpty) ? 'Enter current password' : null,
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () {}, // design-only for now
            style: TextButton.styleFrom(
              foregroundColor: _T.secondary,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'Forgot your current password?',
              style: _T.labelMd.copyWith(
                color: _T.secondary,
                decoration: TextDecoration.underline,
                decorationColor: _T.secondary.withOpacity(0.4),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ----------------------------------------------------------
  // 2. New password + strength meter
  // ----------------------------------------------------------
  Widget _buildNewPassword() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldHeader('New Password', _hint('Minimum 8 chars')),
        const SizedBox(height: 6),
        _passwordField(
          controller: _newCtrl,
          hint: 'Create a strong password',
          icon: Icons.key_outlined,
          obscure: _obscureNew,
          onToggle: () => setState(() => _obscureNew = !_obscureNew),
          onChanged: (_) => setState(() {}),
          validator: (v) =>
              (v == null || v.length < 8) ? 'Min 8 characters' : null,
        ),
        const SizedBox(height: 8),
        _buildStrengthCard(),
      ],
    );
  }

  Widget _buildStrengthCard() {
    final score = _score;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _T.surfaceLow.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _T.outlineVariant.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('SECURITY STRENGTH',
                  style: _T.labelSm.copyWith(color: _T.onSurfaceVariant)),
              if (score > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: score >= 3
                        ? _T.secondaryContainer
                        : _T.surfaceContainer,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: score >= 3 ? _T.secondary : _T.outline,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _strengthLabel,
                        style: _T.labelSm.copyWith(
                          letterSpacing: 0.4,
                          color: score >= 3
                              ? _T.onSecondaryFixedVariant
                              : _T.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: List.generate(4, (i) {
              final filled = i < score;
              return Expanded(
                child: Container(
                  height: 6,
                  margin: EdgeInsets.only(right: i == 3 ? 0 : 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: filled
                        ? _T.secondary
                        : _T.outlineVariant.withOpacity(0.4),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          _requirement('At least 8 characters', _hasLength),
          const SizedBox(height: 6),
          _requirement('At least 1 uppercase letter', _hasUpper),
          const SizedBox(height: 6),
          _requirement('At least 1 number or special character',
              _hasNumOrSpecial),
        ],
      ),
    );
  }

  Widget _requirement(String text, bool met) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: met ? _T.secondary : _T.surfaceHighest,
            border: met ? null : Border.all(color: _T.outlineVariant),
          ),
          child: met
              ? const Icon(Icons.check, size: 12, color: Colors.white)
              : Center(
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: _T.outlineVariant,
                    ),
                  ),
                ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: _T.bodySm.copyWith(
              color: met ? _T.onSurface : _T.outline,
            ),
          ),
        ),
      ],
    );
  }

  // ----------------------------------------------------------
  // 3. Confirm password
  // ----------------------------------------------------------
  Widget _buildConfirmPassword() {
    final hasInput = _confirmCtrl.text.isNotEmpty;
    final matches = hasInput && _confirmCtrl.text == _newCtrl.text;

    Widget trailing;
    if (!hasInput) {
      trailing = const SizedBox.shrink();
    } else if (matches) {
      trailing = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_outline,
              size: 14, color: _T.secondary),
          const SizedBox(width: 4),
          Text('Passwords match',
              style: _T.labelSm
                  .copyWith(color: _T.secondary, letterSpacing: 0.4)),
        ],
      );
    } else {
      trailing = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 14, color: _T.error),
          const SizedBox(width: 4),
          Text('Does not match',
              style: _T.labelSm
                  .copyWith(color: _T.error, letterSpacing: 0.4)),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldHeader('Confirm New Password', trailing),
        const SizedBox(height: 6),
        _passwordField(
          controller: _confirmCtrl,
          hint: 'Re-enter your new password',
          icon: Icons.lock_reset,
          obscure: _obscureConfirm,
          onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
          onChanged: (_) => setState(() {}),
          borderColor: matches ? _T.secondary.withOpacity(0.6) : null,
          focusColor: matches ? _T.secondary : null,
          validator: (v) =>
              v != _newCtrl.text ? 'Passwords do not match' : null,
        ),
      ],
    );
  }

  // ----------------------------------------------------------
  // 4. Security card (sign-out toggle + trust note)
  // ----------------------------------------------------------
  Widget _buildSecurityCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _T.cardDecoration,
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                margin: const EdgeInsets.only(top: 2),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: _T.surfaceContainer,
                ),
                child: const Icon(Icons.devices_outlined,
                    size: 18, color: _T.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Sign out of other devices',
                        style: _T.labelLg.copyWith(color: _T.primary)),
                    const SizedBox(height: 2),
                    const Text(
                      'Recommended if you suspect unauthorized access',
                      style: _T.bodySm,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Switch(
                value: _signOutOtherDevices,
                onChanged: (v) => setState(() => _signOutOtherDevices = v),
                activeColor: Colors.white,
                activeTrackColor: _T.primaryContainer,
                inactiveThumbColor: Colors.white,
                inactiveTrackColor: _T.surfaceHighest,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(height: 1, color: _T.outlineVariant.withOpacity(0.2)),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(Icons.verified_user_outlined,
                  size: 16, color: _T.secondary),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  '256-bit encryption • NUVORA will never ask for your password via chat or email.',
                  style: _T.bodySm,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------
  // Actions
  // ----------------------------------------------------------
  Widget _buildActions(BuildContext context) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            boxShadow: const [
              BoxShadow(
                  color: _T.buttonShadow,
                  blurRadius: 16,
                  spreadRadius: -2,
                  offset: Offset(0, 4)),
            ],
          ),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _loading ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: _T.primaryContainer,
                disabledBackgroundColor: _T.primaryContainer.withOpacity(0.7),
                foregroundColor: Colors.white,
                disabledForegroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 24),
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
                        Text('Save & Update Password',
                            style: _T.labelLg.copyWith(color: Colors.white)),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward, size: 18),
                      ],
                    ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => Navigator.of(context).maybePop(),
          style: TextButton.styleFrom(
            foregroundColor: _T.onSurfaceVariant,
            padding: const EdgeInsets.symmetric(vertical: 10),
          ),
          child: Text('Back to Security Settings',
              style: _T.labelMd.copyWith(color: _T.onSurfaceVariant)),
        ),
      ],
    );
  }

  // ----------------------------------------------------------
  // Footer accent
  // ----------------------------------------------------------
  Widget _buildFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.spa_outlined, size: 13, color: _T.outline),
        const SizedBox(width: 6),
        Text(
          'ARTISANAL LIVING & BOTANICALS',
          style: _T.labelSm.copyWith(color: _T.outline, letterSpacing: 0.9),
        ),
      ],
    );
  }
}
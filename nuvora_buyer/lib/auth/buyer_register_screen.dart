// ============================================================
// buyer_register_screen.dart
// Buyer-only registration screen mockup.
// Separate from seller registration. Hardcoded dummy data only.
// (Botanical Boutique redesign)
// ============================================================

import 'package:flutter/material.dart';
import '../core/api/buyer_api.dart';
import '../core/data/ph_address.dart';
import 'buyer_email_otp_sheet.dart';

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
  static const surfaceHigh = Color(0xFFEAE7E7);
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
  static const secondaryContainer = Color(0xFFC2E9C7);

  // Status
  static const error = Color(0xFFBA1A1A);

  // Shadows / borders
  static const shadow = Color(0x0A173628); // 4%
  static const cardBorder = Color(0x1A173628); // 10%

  // Fonts (add Playfair Display + Plus Jakarta Sans to the project)
  static const serif = 'Playfair Display';
  static const sans = 'Plus Jakarta Sans';

  static const headlineLg = TextStyle(
    fontFamily: serif,
    fontSize: 24,
    height: 32 / 24,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.24,
    color: primary,
  );
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
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: cardBorder),
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

class MockupBuyerRegisterScreen extends StatefulWidget {
  const MockupBuyerRegisterScreen({super.key});

  @override
  State<MockupBuyerRegisterScreen> createState() =>
      _MockupBuyerRegisterScreenState();
}

class _MockupBuyerRegisterScreenState
    extends State<MockupBuyerRegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  // Step tracking
  int _step = 0; // 0 = personal info, 1 = address, 2 = password
  bool _loading = false;
  String? _error;

  // Controllers
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _birthdayCtrl = TextEditingController();
  final _provinceCtrl = TextEditingController();
  final _municipalityCtrl = TextEditingController();
  final _barangayCtrl = TextEditingController();
  final _streetCtrl = TextEditingController();
  final _postalCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscure = true;
  bool _obscureConfirm = true;

  // Philippine address options, loaded live from the same PSGC proxy the
  // rider registration uses.
  List<PhPlace> _provinces = const [];
  List<PhPlace> _cities = const [];
  List<PhPlace> _barangays = const [];
  PhPlace? _provincePlace;
  PhPlace? _cityPlace;
  bool _loadingProvinces = false;
  bool _loadingCities = false;
  bool _loadingBarangays = false;
  String? _provinceError;
  String? _cityError;
  String? _barangayError;
  // Set when Continue is pressed on the address step, so empty selectors show
  // a required message.
  bool _validateAddress = false;

  // Email verification (same idea as the rider registration screen: the
  // address has to be confirmed before the form can be submitted).
  bool _emailVerified = false;
  String _verifiedEmail = '';
  bool _sendingCode = false;

  final List<String> _stepTitles = [
    'Personal Info',
    'Address',
    'Set Password',
  ];

  // Card header copy per step (design only)
  static const _cardTitles = [
    'Personal Information',
    'Delivery Address',
    'Set Password',
  ];
  static const _cardSubtitles = [
    'Tell us a bit about yourself',
    'Where should we deliver your orders?',
    'Secure your new account',
  ];
  static const _cardIcons = [
    Icons.person_outline,
    Icons.location_on_outlined,
    Icons.lock_outline,
  ];

  @override
  void dispose() {
    for (final c in [
      _firstNameCtrl, _lastNameCtrl, _emailCtrl, _phoneCtrl, _birthdayCtrl,
      _provinceCtrl, _municipalityCtrl, _barangayCtrl, _streetCtrl,
      _postalCtrl, _passwordCtrl, _confirmCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadProvinces();
  }

  void _next() {
    if (_step == 1) {
      final missingAddress = _provinceCtrl.text.trim().isEmpty ||
          _municipalityCtrl.text.trim().isEmpty ||
          _barangayCtrl.text.trim().isEmpty;
      if (missingAddress) {
        setState(() => _validateAddress = true);
        return;
      }
    }

    if (!_formKey.currentState!.validate()) return;

    if (_step < 2) {
      setState(() => _step++);
      _ensureAddressLoaded();
    } else {
      _submit();
    }
  }

  /// The address step is only usable once its lists are in memory. Retrying
  /// here covers the case where the first fetch ran before the server answered
  /// or failed while the buyer was still on step 1.
  void _ensureAddressLoaded() {
    if (_step != 1) return;

    if (_provinces.isEmpty && !_loadingProvinces) {
      _loadProvinces();
    }

    final province = _provincePlace;
    if (province != null && _cities.isEmpty && !_loadingCities) {
      _loadCities(province);
    }

    final city = _cityPlace;
    if (city != null && _barangays.isEmpty && !_loadingBarangays) {
      _loadBarangays(city);
    }
  }

  /// Opens the same Material calendar the rider registration uses, themed to
  /// this screen. The last selectable date is the legal-age cutoff, so an
  /// under-18 birthday cannot be chosen.
  Future<void> _pickBirthday() async {
    FocusScope.of(context).unfocus();

    final firstAllowed = DateTime(1920, 1, 1);
    final lastAllowed = DateTime(2008, 12, 31); // 18+ only

    final typed = DateTime.tryParse(_birthdayCtrl.text.trim());
    var initial = typed ?? DateTime(2000, 1, 1);
    if (initial.isAfter(lastAllowed)) initial = lastAllowed;
    if (initial.isBefore(firstAllowed)) initial = firstAllowed;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: firstAllowed,
      lastDate: lastAllowed,
      helpText: 'Select your birthday',
      fieldLabelText: 'Birthday',
      fieldHintText: 'YYYY-MM-DD',
      builder: (context, child) {
        final base = Theme.of(context);
        return Theme(
          data: base.copyWith(
            colorScheme: base.colorScheme.copyWith(
              primary: _T.primaryContainer,
              onPrimary: Colors.white,
              surface: _T.background,
            ),
            datePickerTheme: DatePickerThemeData(
              backgroundColor: _T.background,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              headerBackgroundColor: _T.primaryContainer,
              headerForegroundColor: Colors.white,
              todayBorder: const BorderSide(color: _T.primaryContainer),
              dayForegroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return Colors.white;
                }
                if (states.contains(WidgetState.disabled)) {
                  return _T.outlineVariant;
                }
                return _T.onSurface;
              }),
              dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return _T.primaryContainer;
                }
                return Colors.transparent;
              }),
            ),
            dialogTheme: base.dialogTheme.copyWith(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: _T.primaryContainer,
                textStyle: _T.labelLg,
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked == null) return;

    setState(() {
      _birthdayCtrl.text = '${picked.year.toString().padLeft(4, '0')}-'
          '${picked.month.toString().padLeft(2, '0')}-'
          '${picked.day.toString().padLeft(2, '0')}';
    });
    _formKey.currentState?.validate();
  }

  /// Mirrors the rider screen's email "Verify" button: sends the code, opens
  /// the OTP screen, and marks the address verified once the code is accepted.
  Future<void> _verifyEmail() async {
    final email = _emailCtrl.text.trim();
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      setState(() => _error = 'Enter a valid email address to verify.');
      _formKey.currentState?.validate();
      return;
    }
    if (_sendingCode) return;

    setState(() {
      _sendingCode = true;
      _error = null;
    });

    try {
      await BuyerApi.instance.sendEmailCode(email);
      if (!mounted) return;
      setState(() => _sendingCode = false);

      final verified = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: _T.background,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (_) => BuyerEmailOtpSheet(email: email),
      );
      if (!mounted) return;

      // Ignore a stale result if the address was edited meanwhile.
      if (verified == true &&
          _emailCtrl.text.trim().toLowerCase() == email.toLowerCase()) {
        setState(() {
          _emailVerified = true;
          _verifiedEmail = email.toLowerCase();
          _error = null;
        });
        _formKey.currentState?.validate();
      }
    } on BuyerApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _sendingCode = false;
        _error = error.message;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _sendingCode = false;
        _error = 'Could not send the verification code: $error';
      });
    }
  }

  /// The server only accepts the registration once the email code was
  /// verified, so the Verify button on the email field comes first.
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailCtrl.text.trim();
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await BuyerApi.instance.register({
        'first_name': _firstNameCtrl.text.trim(),
        'last_name': _lastNameCtrl.text.trim(),
        'email': email,
        'contact_no': _phoneCtrl.text.trim(),
        'birthday': _birthdayCtrl.text.trim(),
        'password': _passwordCtrl.text,
        'password_confirmation': _confirmCtrl.text,
        'province': _provinceCtrl.text.trim(),
        'municipality': _municipalityCtrl.text.trim(),
        'barangay': _barangayCtrl.text.trim(),
        'street': _streetCtrl.text.trim(),
        if (_postalCtrl.text.trim().isNotEmpty)
          'postal_code': _postalCtrl.text.trim(),
      });

      if (!mounted) return;
      setState(() => _loading = false);

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Registration successful'),
          content: Text(
            data['message']?.toString() ??
                'Your email is verified and your account is active. '
                    'You can log in now.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      if (!mounted) return;

      // Approved accounts can sign in; the buyer is not logged in yet.
      Navigator.of(context).popUntil((route) => route.isFirst);
    } on BuyerApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.message;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not complete registration: $error';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _T.background,
      appBar: _buildAppBar(context),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHero(),
              const SizedBox(height: 16),
              _buildStepper(),
              const SizedBox(height: 24),
              _buildStepCard(),
              const SizedBox(height: 16),
              _buildTrustBadges(),
            ],
          ),
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
      toolbarHeight: 60,
      foregroundColor: _T.primary,
      leadingWidth: 56,
      leading: Padding(
        padding: const EdgeInsets.only(left: 12),
        child: Center(
          child: Material(
            color: _T.surfaceLow.withOpacity(0.6),
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => Navigator.of(context).maybePop(),
              child: const SizedBox(
                width: 40,
                height: 40,
                child: Icon(Icons.arrow_back, size: 22, color: _T.primary),
              ),
            ),
          ),
        ),
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.eco_outlined, size: 18, color: _T.secondary),
          const SizedBox(width: 6),
          Text('NUVORA',
              style: _T.labelSm.copyWith(
                  color: _T.primary,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2)),
        ],
      ),
      actions: [
        IconButton(
          tooltip: 'Help',
          icon: const Icon(Icons.help_outline,
              size: 20, color: _T.onSurfaceVariant),
          onPressed: () {}, // design-only for now
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  // ----------------------------------------------------------
  // Hero
  // ----------------------------------------------------------
  Widget _buildHero() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: _T.secondaryContainer.withOpacity(0.5),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.verified_outlined,
                  size: 14, color: _T.secondary),
              const SizedBox(width: 6),
              Text('NUVORA MEMBERSHIP',
                  style: _T.labelSm.copyWith(color: _T.secondary)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        const Text('Buyer Registration', style: _T.headlineLg),
        const SizedBox(height: 6),
        Text(
          'Create your buyer account to explore conscious botanical living and enjoy secure Cash on Delivery (COD) services.',
          style: _T.bodyMd
              .copyWith(color: _T.onSurfaceVariant, height: 1.55),
        ),
      ],
    );
  }

  // ----------------------------------------------------------
  // Stepper
  // ----------------------------------------------------------
  Widget _buildStepper() {
    final children = <Widget>[];
    for (int i = 0; i < 3; i++) {
      children.add(_stepItem(i));
      if (i < 2) {
        children.add(
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 13, left: 4, right: 4),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 2,
                color:
                    _step > i ? _T.primaryContainer : _T.surfaceHighest,
              ),
            ),
          ),
        );
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _T.cardDecoration,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _stepItem(int i) {
    final active = i == _step;
    final done = i < _step;
    final filled = active || done;

    return SizedBox(
      width: 72,
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: filled ? _T.primaryContainer : _T.surfaceHighest,
              border: filled
                  ? null
                  : Border.all(color: _T.outlineVariant),
              boxShadow: active
                  ? [
                      BoxShadow(
                        color: _T.primaryFixed.withOpacity(0.4),
                        spreadRadius: 4,
                      ),
                    ]
                  : null,
            ),
            alignment: Alignment.center,
            child: done
                ? const Icon(Icons.check, size: 16, color: Colors.white)
                : Text(
                    '${i + 1}',
                    style: _T.labelMd.copyWith(
                      fontWeight:
                          active ? FontWeight.w700 : FontWeight.w500,
                      color: active
                          ? Colors.white
                          : _T.onSurfaceVariant,
                    ),
                  ),
          ),
          const SizedBox(height: 4),
          Text(
            _stepTitles[i],
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _T.labelSm.copyWith(
              letterSpacing: 0.3,
              fontWeight: filled ? FontWeight.w600 : FontWeight.w400,
              color: filled ? _T.primary : _T.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------
  // Step card (header + current step's fields)
  // ----------------------------------------------------------
  Widget _buildStepCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _T.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.only(bottom: 8),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: _T.surfaceHigh)),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _T.secondaryContainer.withOpacity(0.6),
                  ),
                  child: Icon(_cardIcons[_step],
                      size: 20, color: _T.primary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_cardTitles[_step], style: _T.headlineSm),
                      Text(_cardSubtitles[_step], style: _T.bodySm),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text('STEP ${_step + 1}/3',
                    style: _T.labelSm.copyWith(color: _T.secondary)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (_step == 0) _buildPersonalStep(),
          if (_step == 1) _buildAddressStep(),
          if (_step == 2) _buildPasswordStep(),
        ],
      ),
    );
  }

  // ----------------------------------------------------------
  // Field helper
  // ----------------------------------------------------------
  OutlineInputBorder _border(Color color, {double width = 1}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: color, width: width),
      );

  Widget _field({
    required String label,
    required TextEditingController controller,
    IconData? icon,
    TextInputType? keyboardType,
    bool obscure = false,
    bool readOnly = false,
    VoidCallback? onTap,
    String? hint,
    Widget? suffix,
    Widget? labelAction,
    ValueChanged<String>? onChanged,
    required String? Function(String?) validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            children: [
              Expanded(
                child: Text.rich(
                  TextSpan(
                    text: label,
                    style: _T.labelMd.copyWith(color: _T.primary),
                    children: const [
                      TextSpan(text: ' *', style: TextStyle(color: _T.error)),
                    ],
                  ),
                ),
              ),
              if (labelAction != null) labelAction,
            ],
          ),
        ),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscure,
          readOnly: readOnly,
          onTap: onTap,
          onChanged: onChanged,
          validator: validator,
          style: _T.bodyMd,
          cursorColor: _T.primaryContainer,
          decoration: InputDecoration(
            filled: true,
            fillColor: _T.surfaceLow,
            hintText: hint,
            hintStyle: _T.bodySm.copyWith(color: _T.outline),
            contentPadding: EdgeInsets.fromLTRB(
                icon == null ? 14 : 0, 14, suffix == null ? 14 : 0, 14),
            prefixIcon: icon == null
                ? null
                : Icon(icon, size: 20, color: _T.outline),
            suffixIcon: suffix,
            enabledBorder: _border(_T.outlineVariant),
            focusedBorder: _border(_T.primaryContainer, width: 1.5),
            errorBorder: _border(_T.error),
            focusedErrorBorder: _border(_T.error, width: 1.5),
            errorStyle: _T.bodySm.copyWith(color: _T.error),
          ),
        ),
      ],
    );
  }

  String? _required(String? v) => (v == null || v.isEmpty) ? 'Required' : null;

  // ----------------------------------------------------------
  // Step 1: personal
  // ----------------------------------------------------------
  Widget _buildPersonalStep() {
    return Column(
      children: [
                _field(
          label: 'First Name',
          controller: _firstNameCtrl,
          icon: Icons.person_outline,
          validator: _required,
        ),
        const SizedBox(height: 16),
        _field(
          label: 'Last Name',
          controller: _lastNameCtrl,
          icon: Icons.badge_outlined,
          validator: _required,
        ),
        const SizedBox(height: 16),
        _field(
          label: 'Email Address',
          controller: _emailCtrl,
          icon: Icons.mail_outline,
          keyboardType: TextInputType.emailAddress,
          labelAction: _emailVerified
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle,
                        size: 15, color: _T.secondary),
                    const SizedBox(width: 4),
                    Text('Verified',
                        style: _T.labelMd.copyWith(color: _T.secondary)),
                  ],
                )
              : TextButton(
                  key: const Key('buyer-email-verify'),
                  onPressed: _sendingCode ? null : _verifyEmail,
                  style: TextButton.styleFrom(
                    foregroundColor: _T.primary,
                    disabledForegroundColor: _T.outline,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    minimumSize: const Size(56, 32),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    textStyle: _T.labelMd.copyWith(fontWeight: FontWeight.w700),
                  ),
                  child: Text(_sendingCode ? 'Sending…' : 'Verify email'),
                ),
          suffix: _emailVerified
              ? const Icon(Icons.verified_outlined,
                  size: 20, color: _T.secondary)
              : null,
          onChanged: (_) {
            final current = _emailCtrl.text.trim().toLowerCase();
            if (_emailVerified && current != _verifiedEmail) {
              setState(() {
                _emailVerified = false;
                _verifiedEmail = '';
              });
            } else {
              setState(() {});
            }
          },
          validator: (v) {
            final value = v?.trim() ?? '';
            if (value.isEmpty) return 'Required';
            if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value)) {
              return 'Enter valid email';
            }
            if (!_emailVerified || _verifiedEmail != value.toLowerCase()) {
              return 'Verify your email to continue';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _field(
          label: 'Phone Number',
          controller: _phoneCtrl,
          icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          validator: (v) =>
              (v == null || !RegExp(r'^09\d{9}$').hasMatch(v.trim()))
                  ? 'Use 09XXXXXXXXX'
                  : null,
        ),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 2),
              child: Icon(Icons.info_outline,
                  size: 14, color: _T.secondary),
            ),
            const SizedBox(width: 4),
            const Expanded(
              child: Text(
                'Required for COD courier verification and real-time delivery alerts.',
                style: _T.bodySm,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _field(
          label: 'Birthday',
          controller: _birthdayCtrl,
          icon: Icons.calendar_today_outlined,
          readOnly: true,
          onTap: _pickBirthday,
          suffix: const Padding(
            padding: EdgeInsets.only(right: 12),
            child: Icon(Icons.expand_more,
                size: 20, color: _T.outline),
          ),
          validator: (v) =>
              (v == null || !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(v.trim()))
                  ? 'Pick your birthday'
                  : null,
        ),
      ],
    );
  }

  // ----------------------------------------------------------
  // Live PSGC address (same API the rider registration uses)
  // ----------------------------------------------------------
  Future<void> _loadProvinces() async {
    setState(() {
      _loadingProvinces = true;
      _provinceError = null;
    });
    try {
      final provinces = await PhAddressApi.instance.provinces();
      if (!mounted) return;
      setState(() {
        _provinces = provinces;
        _loadingProvinces = false;
      });
    } on BuyerApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _provinceError = error.message;
        _loadingProvinces = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _provinceError = 'Could not load provinces from Nuvora.';
        _loadingProvinces = false;
      });
    }
  }

  Future<void> _loadCities(PhPlace province) async {
    setState(() {
      _loadingCities = true;
      _cityError = null;
      _cities = const [];
    });
    try {
      final cities = await PhAddressApi.instance.cities(province.code);
      if (!mounted) return;
      setState(() {
        _cities = cities;
        _loadingCities = false;
      });
    } on BuyerApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _cityError = error.message;
        _loadingCities = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _cityError = 'Could not load cities and municipalities.';
        _loadingCities = false;
      });
    }
  }

  Future<void> _loadBarangays(PhPlace city) async {
    setState(() {
      _loadingBarangays = true;
      _barangayError = null;
      _barangays = const [];
    });
    try {
      final barangays = await PhAddressApi.instance.barangays(city);
      if (!mounted) return;
      setState(() {
        _barangays = barangays;
        _loadingBarangays = false;
      });
    } on BuyerApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _barangayError = error.message;
        _loadingBarangays = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _barangayError = 'Could not load barangays.';
        _loadingBarangays = false;
      });
    }
  }

  void _chooseProvince(PhPlace place) {
    setState(() {
      _provincePlace = place;
      _provinceCtrl.text = place.name;
      _cityPlace = null;
      _municipalityCtrl.clear();
      _barangayCtrl.clear();
      _cities = const [];
      _barangays = const [];
      _cityError = null;
      _barangayError = null;
    });
    _loadCities(place);
  }

  void _chooseCity(PhPlace place) {
    setState(() {
      _cityPlace = place;
      _municipalityCtrl.text = place.name;
      _barangayCtrl.clear();
      _barangays = const [];
      _barangayError = null;
    });
    _loadBarangays(place);
  }

  void _chooseBarangay(PhPlace place) {
    setState(() => _barangayCtrl.text = place.name);
  }

  /// A read-only, selection-only field: tapping it opens the searchable list
  /// of every option the API returned, and the controller keeps the picked
  /// name so the payload sent on submit is unchanged.
  Widget _addressField({
    required String label,
    required String hint,
    required String sheetTitle,
    required TextEditingController controller,
    required IconData icon,
    required List<PhPlace> options,
    required bool loading,
    required String? error,
    required ValueChanged<PhPlace> onPick,
    required VoidCallback onRetry,
  }) {
    final value = controller.text.trim();
    final showRequired = _validateAddress && value.isEmpty;

    Future<void> open() async {
      FocusScope.of(context).unfocus();
      if (loading) return;

      // Nothing loaded yet (first fetch failed or still in flight): tapping
      // retries instead of doing nothing.
      if (options.isEmpty) {
        onRetry();
        return;
      }

      final picked = await _showPlaceSheet(
        sheetTitle,
        options,
        current: value,
      );
      if (picked != null) onPick(picked);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text.rich(
            TextSpan(
              text: label,
              style: _T.labelMd.copyWith(color: _T.primary),
              children: const [
                TextSpan(text: ' *', style: TextStyle(color: _T.error)),
              ],
            ),
          ),
        ),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: open,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(0, 14, 12, 14),
              decoration: BoxDecoration(
                color: _T.surfaceLow,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: showRequired ? _T.error : _T.outlineVariant,
                ),
              ),
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Icon(icon, size: 20, color: _T.outline),
                  ),
                  Expanded(
                    child: Text(
                      loading
                          ? 'Loading…'
                          : (value.isNotEmpty ? value : hint),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: value.isNotEmpty
                          ? _T.bodyMd
                          : _T.bodySm.copyWith(color: _T.outline),
                    ),
                  ),
                  if (loading)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: _T.primaryContainer,
                      ),
                    )
                  else
                    const Icon(Icons.expand_more,
                        size: 20, color: _T.outline),
                ],
              ),
            ),
          ),
        ),
        if (showRequired) ...[
          const SizedBox(height: 4),
          Text('Required', style: _T.bodySm.copyWith(color: _T.error)),
        ],
        if (error != null) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.error_outline, size: 14, color: _T.error),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  error,
                  style: _T.bodySm.copyWith(color: _T.error),
                ),
              ),
              TextButton(
                onPressed: onRetry,
                style: TextButton.styleFrom(
                  foregroundColor: _T.primaryContainer,
                  minimumSize: const Size(50, 32),
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  textStyle: _T.labelSm,
                ),
                child: const Text('Try again'),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Future<PhPlace?> _showPlaceSheet(
    String title,
    List<PhPlace> options, {
    String? current,
  }) {
    return showModalBottomSheet<PhPlace>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _T.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        var query = '';
        return StatefulBuilder(
          builder: (context, setSheet) {
            final q = query.trim().toLowerCase();
            final shown = q.isEmpty
                ? options
                : [
                    for (final option in options)
                      if (option.name.toLowerCase().contains(q)) option,
                  ];

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.75,
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: _T.outlineVariant,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: _T.headlineSm.copyWith(color: _T.primary),
                            ),
                          ),
                          Text(
                            '${shown.length}',
                            style: _T.bodySm.copyWith(color: _T.outline),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: TextField(
                        autofocus: true,
                        onChanged: (value) => setSheet(() => query = value),
                        style: _T.bodyMd,
                        cursorColor: _T.primaryContainer,
                        decoration: InputDecoration(
                          hintText: 'Search…',
                          hintStyle:
                              _T.bodySm.copyWith(color: _T.outline),
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            size: 19,
                            color: _T.outline,
                          ),
                          filled: true,
                          fillColor: _T.surfaceLow,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 12),
                          enabledBorder: _border(_T.outlineVariant),
                          focusedBorder:
                              _border(_T.primaryContainer, width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: shown.isEmpty
                          ? Center(
                              child: Text(
                                'No matching results.',
                                style: _T.bodySm.copyWith(color: _T.outline),
                              ),
                            )
                          : ListView.builder(
                              padding:
                                  const EdgeInsets.fromLTRB(8, 0, 8, 16),
                              itemCount: shown.length,
                              itemBuilder: (context, index) {
                                final place = shown[index];
                                final selected = place.name == current;
                                return ListTile(
                                  title: Text(
                                    place.name,
                                    style: _T.bodyMd,
                                  ),
                                  trailing: selected
                                      ? const Icon(
                                          Icons.check_rounded,
                                          color: _T.primaryContainer,
                                          size: 18,
                                        )
                                      : null,
                                  onTap: () =>
                                      Navigator.pop(context, place),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ----------------------------------------------------------
  // Step 2: address
  // ----------------------------------------------------------
  Widget _buildAddressStep() {
    return Column(
      children: [
        _addressField(
          label: 'Province',
          hint: 'Select province',
          sheetTitle: 'Search province',
          controller: _provinceCtrl,
          icon: Icons.location_city_outlined,
          options: _provinces,
          loading: _loadingProvinces,
          error: _provinceError,
          onPick: _chooseProvince,
          onRetry: _loadProvinces,
        ),
        const SizedBox(height: 16),
        _addressField(
          label: 'Municipality / City',
          hint: _provincePlace == null
              ? 'Select a province first'
              : 'Select municipality or city',
          sheetTitle: 'Search city or municipality',
          controller: _municipalityCtrl,
          icon: Icons.apartment_outlined,
          options: _cities,
          loading: _loadingCities,
          error: _cityError,
          onPick: _chooseCity,
          onRetry: () {
            final place = _provincePlace;
            if (place != null) _loadCities(place);
          },
        ),
        const SizedBox(height: 16),
        _addressField(
          label: 'Barangay',
          hint: _cityPlace == null
              ? 'Select a city or municipality first'
              : 'Select barangay',
          sheetTitle: 'Search barangay',
          controller: _barangayCtrl,
          icon: Icons.holiday_village_outlined,
          options: _barangays,
          loading: _loadingBarangays,
          error: _barangayError,
          onPick: _chooseBarangay,
          onRetry: () {
            final place = _cityPlace;
            if (place != null) _loadBarangays(place);
          },
        ),
        const SizedBox(height: 16),
        _field(
          label: 'Street / House No.',
          controller: _streetCtrl,
          icon: Icons.add_road_outlined,
          validator: _required,
        ),
        const SizedBox(height: 16),
        _field(
          label: 'Postal Code',
          controller: _postalCtrl,
          icon: Icons.markunread_mailbox_outlined,
          keyboardType: TextInputType.number,
          validator: _required,
        ),
      ],
    );
  }

  // ----------------------------------------------------------
  // Step 3: password
  // ----------------------------------------------------------
  Widget _buildPasswordStep() {
    final hasConfirm = _confirmCtrl.text.isNotEmpty;
    final matches = hasConfirm && _confirmCtrl.text == _passwordCtrl.text;

    return Column(
      children: [
        // Info box
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _T.surfaceLow,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _T.outlineVariant.withOpacity(0.4)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 1),
                child: Icon(Icons.mark_email_read_outlined,
                    size: 18, color: _T.primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Your email is already verified. Set a password to finish your registration.',
                  style: _T.bodySm.copyWith(
                      color: _T.onSurfaceVariant, height: 1.5),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _field(
          label: 'Password',
          controller: _passwordCtrl,
          icon: Icons.lock_outline,
          obscure: _obscure,
          onChanged: (_) => setState(() {}),
          suffix: IconButton(
            icon: Icon(
              _obscure
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              size: 20,
              color: _T.outline,
            ),
            onPressed: () => setState(() => _obscure = !_obscure),
          ),
          validator: (v) =>
              (v == null || v.length < 8) ? 'Min 8 characters' : null,
        ),
        const SizedBox(height: 16),
        _field(
          label: 'Confirm Password',
          controller: _confirmCtrl,
          icon: Icons.lock_reset,
          obscure: _obscureConfirm,
          onChanged: (_) => setState(() {}),
          suffix: IconButton(
            icon: Icon(
              _obscureConfirm
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              size: 20,
              color: _T.outline,
            ),
            onPressed: () =>
                setState(() => _obscureConfirm = !_obscureConfirm),
          ),
          validator: (v) => v != _passwordCtrl.text
              ? 'Passwords do not match'
              : null,
        ),
        if (hasConfirm) ...[
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  matches
                      ? Icons.check_circle_outline
                      : Icons.error_outline,
                  size: 14,
                  color: matches ? _T.secondary : _T.error,
                ),
                const SizedBox(width: 4),
                Text(
                  matches ? 'Passwords match' : 'Passwords do not match',
                  style: _T.bodySm.copyWith(
                      color: matches ? _T.secondary : _T.error),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // ----------------------------------------------------------
  // Trust badges
  // ----------------------------------------------------------
  Widget _buildTrustBadges() {
    return Center(
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 4,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.security, size: 16, color: _T.secondary),
              const SizedBox(width: 4),
              Text('256-Bit SSL Encrypted',
                  style: _T.labelSm.copyWith(
                      color: _T.outline, fontWeight: FontWeight.w500)),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.verified_user_outlined,
                  size: 16, color: _T.secondary),
              const SizedBox(width: 4),
              Text('Data Privacy Act Compliant',
                  style: _T.labelSm.copyWith(
                      color: _T.outline, fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------
  // Bottom action bar (same Back / Continue / Register logic)
  // ----------------------------------------------------------
  Widget _buildBottomBar() {
    return Container(
      decoration: BoxDecoration(
        color: _T.background.withOpacity(0.95),
        border: Border(
          top: BorderSide(color: _T.outlineVariant.withOpacity(0.3)),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F173628),
            blurRadius: 24,
            offset: Offset(0, -8),
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
              if (_error != null) ...[
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: _T.bodySm.copyWith(color: _T.error),
                ),
                const SizedBox(height: 10),
              ],
              Row(
                children: [
                  if (_step > 0) ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _loading
                            ? null
                            : () => setState(() => _step--),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _T.primaryContainer,
                          side: const BorderSide(
                              color: _T.primaryContainer),
                          minimumSize: const Size(double.infinity, 48),
                          shape: const StadiumBorder(),
                        ),
                        child: Text('Back',
                            style: _T.labelLg
                                .copyWith(color: _T.primaryContainer)),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    flex: 2,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x40173628),
                            blurRadius: 16,
                            spreadRadius: -2,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _loading ? null : _next,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _T.primaryContainer,
                          disabledBackgroundColor:
                              _T.primaryContainer.withOpacity(0.7),
                          foregroundColor: Colors.white,
                          disabledForegroundColor: Colors.white,
                          elevation: 0,
                          minimumSize: const Size(double.infinity, 48),
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
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _step < 2 ? 'Continue' : 'Register',
                                    style: _T.labelLg
                                        .copyWith(color: Colors.white),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.arrow_forward,
                                      size: 18),
                                ],
                              ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Design-only: sign-in link has no handler (routing untouched)
              Text.rich(
                TextSpan(
                  text: 'Already have an account? ',
                  style:
                      _T.bodySm.copyWith(color: _T.onSurfaceVariant),
                  children: [
                    TextSpan(
                      text: 'Sign In',
                      style: _T.bodySm.copyWith(
                        color: _T.primary,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
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
}
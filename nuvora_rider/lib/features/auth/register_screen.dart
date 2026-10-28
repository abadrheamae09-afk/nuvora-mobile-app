import 'package:flutter/material.dart';

import '../../core/api/rider_api.dart';
import '../../theme/app_colors.dart';
import 'login_screen.dart';
import 'rider_email_otp_sheet.dart';

/// Rider registration: 4 steps with a segmented progress bar, mirroring the
/// information the rider must supply — personal details, vehicle documents,
/// address, then a review before submitting.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  static const int _totalSteps = 4;
  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  int _currentStep = 0;
  final _scroll = ScrollController();

  // ── Field state ──────────────────────────────────────────────────────────
  final Map<String, TextEditingController> _fields = {};
  final Map<String, GlobalKey> _keys = {};
  final Map<String, String> _files = {};
  final Set<String> _flagged = {};

  String? _sex;
  String? _vehicleType;
  String? _dlCode;
  String? _province;
  String? _city;
  String? _barangay;
  bool _agreed = false;
  bool _submitting = false;
  bool _emailVerified = false;
  bool _sendingEmailCode = false;
  String _verifiedEmail = '';

  final List<String> _sexOptions = const ['Male', 'Female'];
  final List<String> _vehicleOptions = const [
    'Motorcycle',
    'Van',
    'L300',
    'Truck',
  ];
  final List<String> _licenseCodes = const [
    'A — Motorcycle',
    'A1 — Tricycle',
    'B — Up to 4,500 KGS GVW / 8 seats',
  ];

  // Small offline sample of the address cascade.
  final Map<String, Map<String, List<String>>> _locations = const {
    'Metro Manila': {
      'Quezon City': [
        'Barangay Socorro',
        'Barangay Holy Spirit',
        'Barangay Bagong Silangan',
      ],
      'Manila': ['Barangay Malate', 'Barangay Tondo', 'Barangay Ermita'],
      'Makati': ['Barangay Poblacion', 'Barangay Bel-Air'],
    },
    'Cavite': {
      'Bacoor': ['Barangay Molino III', 'Barangay Zapote'],
      'Dasmariñas': ['Barangay Paliparan III', 'Barangay Emilio Aguinaldo'],
    },
    'Laguna': {
      'Calamba': ['Barangay Poblacion', 'Barangay Bucal'],
      'Santa Rosa': ['Barangay Balibago', 'Barangay Tagapo'],
    },
  };

  /// Required field ids per step, in the order they appear on screen.
  static const Map<int, List<String>> _required = {
    0: [
      'lastName',
      'firstName',
      'sex',
      'email',
      'birthday',
      'validId',
      'password',
      'confirm',
    ],
    1: [
      'vehicleType',
      'plate',
      'license',
      'dlLast',
      'dlFirst',
      'dlAddress',
      'dlLicenseNo',
      'dlExpiration',
      'dlNationality',
      'dlCode',
      'orCr',
      'mvFile',
      'orPlate',
      'make',
      'body',
      'year',
      'engine',
      'chassis',
      'owner',
      'ownerAddress',
      'regExp',
    ],
    2: ['phone', 'province', 'city', 'barangay', 'street', 'zip'],
    3: ['agreed'],
  };

  static const List<String> _stepLabels = [
    'Personal Information',
    'Vehicle Details',
    'Contact & Address',
    'Review & Submit',
  ];

  static const List<IconData> _stepIcons = [
    Icons.person_outline_rounded,
    Icons.two_wheeler_outlined,
    Icons.contact_mail_outlined,
    Icons.fact_check_outlined,
  ];

  @override
  void initState() {
    super.initState();
    for (final id in const [
      'lastName',
      'firstName',
      'middleInitial',
      'email',
      'birthday',
      'age',
      'password',
      'confirm',
      'plate',
      'dlLast',
      'dlFirst',
      'dlMiddle',
      'dlAddress',
      'dlLicenseNo',
      'dlExpiration',
      'dlNationality',
      'mvFile',
      'orPlate',
      'make',
      'series',
      'body',
      'color',
      'year',
      'engine',
      'chassis',
      'owner',
      'ownerAddress',
      'regExp',
      'phone',
      'street',
      'zip',
    ]) {
      _fields[id] = TextEditingController();
    }
  }

  @override
  void dispose() {
    for (final c in _fields.values) {
      c.dispose();
    }
    _scroll.dispose();
    super.dispose();
  }

  String _value(String id) => _fields[id]?.text.trim() ?? '';

  GlobalKey _key(String id) => _keys.putIfAbsent(id, () => GlobalKey());

  // ── Validation ───────────────────────────────────────────────────────────
  String? _errorFor(String id) {
    switch (id) {
      case 'email':
        final v = _value('email');
        if (v.isEmpty) return 'Enter your email address.';
        if (!_emailPattern.hasMatch(v)) return 'Enter a valid email address.';
        return _emailVerified && _verifiedEmail == v.toLowerCase()
            ? null
            : 'Verify your email address to continue.';
      case 'password':
        return _value('password').length < 8
            ? 'Password must be at least 8 characters.'
            : null;
      case 'confirm':
        if (_value('confirm').isEmpty) return 'Confirm your password.';
        return _value('confirm') == _value('password')
            ? null
            : 'Passwords do not match.';
      case 'sex':
        return _sex == null ? 'Select an option.' : null;
      case 'vehicleType':
        return _vehicleType == null ? 'Select an option.' : null;
      case 'dlCode':
        return _dlCode == null ? 'Select a license code.' : null;
      case 'province':
        return _province == null ? 'Select a province.' : null;
      case 'city':
        return _city == null ? 'Select a municipality or city.' : null;
      case 'barangay':
        return _barangay == null ? 'Select a barangay.' : null;
      case 'validId':
        return _files['validId'] == null
            ? 'Upload a photo of your valid ID.'
            : null;
      case 'license':
        return _files['license'] == null
            ? "Upload your driver's license."
            : null;
      case 'orCr':
        return _files['orCr'] == null ? 'Upload your OR / CR.' : null;
      case 'agreed':
        return _agreed ? null : 'Please accept the terms to continue.';
      default:
        return _value(id).isEmpty ? 'This field is required.' : null;
    }
  }

  /// Shows an error only after the rider tapped Continue with that field
  /// still empty, and it clears itself as soon as the field becomes valid.
  String? _error(String id) {
    if (!_flagged.contains(id)) return null;
    return _errorFor(id);
  }

  void _validateCurrentStep() {
    final invalid = <String>[];
    for (final id in _required[_currentStep]!) {
      if (_errorFor(id) != null) invalid.add(id);
    }
    setState(
      () => _flagged
        ..removeWhere((id) => _required[_currentStep]!.contains(id))
        ..addAll(invalid),
    );

    if (invalid.isEmpty) return;

    final target = _keys[invalid.first]?.currentContext;
    if (target != null) {
      Scrollable.ensureVisible(
        target,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
        alignment: 0.06,
      );
    }
  }

  void _goBack() {
    if (_currentStep == 0) return;
    setState(() => _currentStep--);
    _scrollToTop();
  }

  void _next() {
    if (_currentStep < _totalSteps - 1) {
      _validateCurrentStep();
      if (_flagged.isNotEmpty &&
          _flagged.any(_required[_currentStep]!.contains)) {
        return;
      }
      setState(() => _currentStep++);
      _scrollToTop();
      return;
    }
    _submit();
  }

  Future<void> _verifyEmail() async {
    final email = _value('email');
    if (!_emailPattern.hasMatch(email)) {
      setState(() => _flagged.add('email'));
      return;
    }
    if (_sendingEmailCode) return;

    setState(() => _sendingEmailCode = true);
    try {
      await RiderApi.instance.sendEmailCode(email);
      if (!mounted) return;
      final verified = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: AppColors.card,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (context) => RiderEmailOtpSheet(email: email),
      );
      if (verified == true &&
          mounted &&
          _value('email').toLowerCase() == email.toLowerCase()) {
        setState(() {
          _emailVerified = true;
          _verifiedEmail = email.toLowerCase();
          _flagged.remove('email');
        });
      }
    } on RiderApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(content: Text(error.message)));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Text(
              'Could not send the verification code: $error\n'
              'Nuvora server: ${RiderApi.baseUrl}',
            ),
          ),
        );
    } finally {
      if (mounted) setState(() => _sendingEmailCode = false);
    }
  }

  Future<void> _submit() async {
    _validateCurrentStep();
    if (_flagged.any(_required[3]!.contains) || _submitting) return;

    setState(() => _submitting = true);
    try {
      final result = await RiderApi.instance.register({
        'first_name': _value('firstName'),
        'last_name': _value('lastName'),
        'middle_initial': _value('middleInitial'),
        'email': _value('email'),
        'password': _value('password'),
        'phone': _value('phone'),
        'municipality': _city ?? '',
        'province': _province ?? '',
        'barangay': _barangay ?? '',
        'vehicle': _vehicleType ?? 'Motorcycle',
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result['message']?.toString() ??
                'Application submitted for review.',
          ),
        ),
      );
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } on RiderApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(
            content: Text('Could not connect to Nuvora. Please try again.'),
          ),
        );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _scrollToTop() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        0,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    });
  }

  // ── Pickers ──────────────────────────────────────────────────────────────
  Future<void> _pickDate(
    String id, {
    required DateTime first,
    required DateTime last,
  }) async {
    final initial = _fields[id]!.text.isEmpty
        ? (id == 'birthday'
              ? DateTime(2000)
              : DateTime.now().add(const Duration(days: 365)))
        : DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(first)
          ? first
          : (initial.isAfter(last) ? last : initial),
      firstDate: first,
      lastDate: last,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(
            context,
          ).colorScheme.copyWith(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() {
      _fields[id]!.text =
          '${picked.month.toString().padLeft(2, '0')}/${picked.day.toString().padLeft(2, '0')}/${picked.year}';
      if (id == 'birthday') {
        final age = DateTime.now().year - picked.year;
        final hadBirthday =
            DateTime.now().month < picked.month ||
            (DateTime.now().month == picked.month &&
                DateTime.now().day < picked.day);
        _fields['age']!.text = (hadBirthday ? age - 1 : age).toString();
      }
    });
  }

  Future<void> _pickDocument(String id) async {
    final source = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
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
              const SizedBox(height: 16),
              const Text(
                'Upload document',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              const Text(
                'JPG or PNG, clear and readable.',
                style: TextStyle(fontSize: 13, color: AppColors.muted),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(
                  Icons.photo_camera_outlined,
                  color: AppColors.primary,
                ),
                title: const Text('Take photo'),
                onTap: () => Navigator.pop(context, 'camera'),
              ),
              ListTile(
                leading: const Icon(
                  Icons.photo_library_outlined,
                  color: AppColors.primary,
                ),
                title: const Text('Choose from gallery'),
                onTap: () => Navigator.pop(context, 'gallery'),
              ),
            ],
          ),
        ),
      ),
    );
    if (source == null || !mounted) return;
    final names = {
      'validId': 'valid_id.jpg',
      'license': 'drivers_license.jpg',
      'orCr': 'or_cr.jpg',
    };
    setState(() => _files[id] = names[id] ?? 'document.jpg');
  }

  // ── Small building blocks ────────────────────────────────────────────────
  Widget _section(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.muted,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _label(String text, {bool required = false}) {
    return RichText(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.ink,
        ),
        children: [
          if (required)
            const TextSpan(
              text: ' *',
              style: TextStyle(
                color: AppColors.danger,
                fontWeight: FontWeight.w800,
              ),
            ),
        ],
      ),
    );
  }

  /// Label + input + inline error, keyed so the page can scroll to it.
  Widget _col(String id, String label, Widget child, {bool required = false}) {
    final error = _error(id);
    return KeyedSubtree(
      key: _key(id),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label(label, required: required),
          const SizedBox(height: 8),
          child,
          if (error != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 14,
                  color: AppColors.danger,
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    error,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.danger,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _row2(Widget a, Widget b) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: a),
        const SizedBox(width: 12),
        Expanded(child: b),
      ],
    );
  }

  Widget _gap() => const SizedBox(height: 16);

  InputDecoration _decoration({String? hint, IconData? icon, Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: icon == null
          ? null
          : Icon(icon, size: 19, color: AppColors.muted),
      suffixIcon: suffix,
      isDense: false,
    );
  }

  Widget _text(
    String id, {
    String? hint,
    IconData? icon,
    TextInputType? keyboard,
    int maxLines = 1,
  }) {
    return TextField(
      controller: _fields[id],
      keyboardType: keyboard,
      maxLines: maxLines,
      onChanged: (_) => setState(() {}),
      decoration: _decoration(hint: hint, icon: icon),
    );
  }

  Widget _dateField(String id, {String hint = 'mm/dd/yyyy'}) {
    return TextField(
      controller: _fields[id],
      readOnly: true,
      onTap: () => _pickDate(
        id,
        first: id == 'birthday' ? DateTime(1900) : DateTime.now(),
        last: id == 'birthday' ? DateTime.now() : DateTime(2060),
      ),
      onChanged: (_) => setState(() {}),
      decoration: _decoration(
        hint: hint,
        icon: Icons.calendar_today_outlined,
        suffix: const Icon(Icons.arrow_drop_down, color: AppColors.muted),
      ),
    );
  }

  Widget _dropdown(
    String id, {
    required String hint,
    required List<String> options,
    required String? value,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      // ignore: deprecated_member_use
      value: value,
      initialValue: value,
      isExpanded: true,
      style: const TextStyle(fontSize: 14, color: AppColors.ink),
      decoration: _decoration(hint: hint),
      items: [
        for (final option in options)
          DropdownMenuItem(
            value: option,
            child: Text(option, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: (v) {
        onChanged(v);
        setState(() {});
      },
    );
  }

  Widget _uploadField(String id, {required String hint}) {
    final file = _files[id];
    final hasError = _error(id) != null;
    return InkWell(
      onTap: () => _pickDocument(id),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          color: file == null ? AppColors.mint : AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: hasError
                ? AppColors.danger
                : (file == null ? AppColors.mintStrong : AppColors.primary),
            width: 1.2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: file == null ? AppColors.primary : AppColors.mint,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(
                file == null
                    ? Icons.upload_file_outlined
                    : Icons.check_circle_outline,
                color: file == null ? Colors.white : AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    file ?? hint,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: file == null
                          ? AppColors.ink
                          : AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    file == null
                        ? 'Tap to attach'
                        : 'Attached · tap to replace',
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: file == null ? AppColors.muted : AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }

  // ── Step progress bar ────────────────────────────────────────────────────
  Widget _stepBar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.headerTop, AppColors.headerBottom],
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(38),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _stepIcons[_currentStep],
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'STEP ${_currentStep + 1} OF $_totalSteps',
                      style: TextStyle(
                        color: Colors.white.withAlpha(215),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _stepLabels[_currentStep],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              if (_currentStep < _totalSteps - 1)
                Flexible(
                  child: Text(
                    'Next:\n${_stepLabels[_currentStep + 1]}',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: Colors.white.withAlpha(200),
                      fontSize: 10.5,
                      height: 1.3,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: List.generate(_totalSteps, (i) {
            final done = i < _currentStep;
            final active = i == _currentStep;
            final color = done
                ? AppColors.primaryDark
                : active
                ? AppColors.primaryLight
                : AppColors.border;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: i < _totalSteps - 1 ? 6 : 0),
                child: Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: 6,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${i + 1}',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: (done || active)
                            ? FontWeight.w800
                            : FontWeight.w500,
                        color: (done || active)
                            ? AppColors.primaryDark
                            : AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  // ── Steps ────────────────────────────────────────────────────────────────
  Widget _emailField() {
    final email = _value('email');
    final verified = _emailVerified && _verifiedEmail == email.toLowerCase();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _label('Email', required: true)),
            if (verified)
              const Text(
                '✓ Verified',
                style: TextStyle(
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              )
            else
              TextButton(
                key: const Key('rider-email-verify'),
                onPressed: _sendingEmailCode ? null : _verifyEmail,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primaryDark,
                  disabledForegroundColor: AppColors.primaryDark,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  minimumSize: const Size(56, 36),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  textStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                child: Text(_sendingEmailCode ? 'Sending…' : 'Verify'),
              ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _fields['email'],
          keyboardType: TextInputType.emailAddress,
          onChanged: (_) {
            final current = _value('email').toLowerCase();
            if (_emailVerified && current != _verifiedEmail) {
              setState(() {
                _emailVerified = false;
                _verifiedEmail = '';
              });
            } else {
              setState(() {});
            }
          },
          decoration: _decoration(
            hint: 'Enter email address',
            icon: Icons.mail_outline_rounded,
            suffix: verified
                ? const Icon(Icons.check_circle, color: AppColors.primary)
                : null,
          ),
        ),
        if (_error('email') case final message?) ...[
          const SizedBox(height: 6),
          Text(
            message,
            style: const TextStyle(fontSize: 12, color: AppColors.danger),
          ),
        ],
      ],
    );
  }

  Widget _step1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _section(
          'Personal Information',
          'Please provide your personal details.',
        ),
        const SizedBox(height: 18),
        _col(
          'lastName',
          'Last Name',
          _text(
            'lastName',
            hint: 'Enter last name',
            icon: Icons.person_outline_rounded,
          ),
          required: true,
        ),
        _gap(),
        _col(
          'firstName',
          'First Name',
          _text(
            'firstName',
            hint: 'Enter first name',
            icon: Icons.person_outline_rounded,
          ),
          required: true,
        ),
        _gap(),
        _col(
          'middleInitial',
          'Middle Initial',
          _text('middleInitial', hint: 'Enter middle initial'),
        ),
        _gap(),
        _col(
          'sex',
          'Sex',
          _dropdown(
            'sex',
            hint: 'Select sex',
            options: _sexOptions,
            value: _sex,
            onChanged: (v) => _sex = v,
          ),
          required: true,
        ),
        _gap(),
        KeyedSubtree(key: _key('email'), child: _emailField()),
        _gap(),
        _row2(
          _col('birthday', 'Birthday', _dateField('birthday'), required: true),
          _col('age', 'Age', _text('age', hint: '--'), required: true),
        ),
        _gap(),
        _col(
          'validId',
          'Valid ID',
          _uploadField('validId', hint: 'Upload valid ID'),
          required: true,
        ),
        const SizedBox(height: 26),
        _section('Account Security', 'Set a password to secure your account.'),
        const SizedBox(height: 18),
        _col(
          'password',
          'Password',
          _text(
            'password',
            hint: 'Create a password',
            icon: Icons.lock_outline_rounded,
          ),
          required: true,
        ),
        const SizedBox(height: 6),
        const Text(
          'Minimum 8 characters with letters and numbers',
          style: TextStyle(color: AppColors.muted, fontSize: 11.5),
        ),
        _gap(),
        _col(
          'confirm',
          'Confirm Password',
          _text(
            'confirm',
            hint: 'Confirm your password',
            icon: Icons.lock_outline_rounded,
          ),
          required: true,
        ),
      ],
    );
  }

  Widget _step2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _section(
          'Vehicle Details',
          'Provide your vehicle and license information.',
        ),
        const SizedBox(height: 18),
        _col(
          'vehicleType',
          'Type of Vehicle',
          _dropdown(
            'vehicleType',
            hint: 'Select vehicle type',
            options: _vehicleOptions,
            value: _vehicleType,
            onChanged: (v) => _vehicleType = v,
          ),
          required: true,
        ),
        _gap(),
        _col(
          'plate',
          'Plate Number',
          _text('plate', hint: 'e.g. ABC 1234'),
          required: true,
        ),
        _gap(),
        _col(
          'license',
          "Driver's License",
          _uploadField('license', hint: "Upload driver's license"),
          required: true,
        ),
        const SizedBox(height: 26),
        _section(
          "Driver's License Information",
          'Fill in the details as shown on your license.',
        ),
        const SizedBox(height: 18),
        _row2(
          _col(
            'dlLast',
            'Last Name',
            _text('dlLast', hint: 'Name on license'),
            required: true,
          ),
          _col(
            'dlFirst',
            'First Name',
            _text('dlFirst', hint: 'Name on license'),
            required: true,
          ),
        ),
        _gap(),
        _col(
          'dlMiddle',
          'Middle Name',
          _text('dlMiddle', hint: 'Name on license'),
        ),
        _gap(),
        _col(
          'dlAddress',
          'Address',
          _text('dlAddress', hint: 'Address on license'),
          required: true,
        ),
        _gap(),
        _row2(
          _col(
            'dlLicenseNo',
            'License No.',
            _text('dlLicenseNo', hint: 'e.g. N01-23-456789'),
            required: true,
          ),
          _col(
            'dlExpiration',
            'Expiration Date',
            _dateField('dlExpiration'),
            required: true,
          ),
        ),
        _gap(),
        _row2(
          _col(
            'dlNationality',
            'Nationality',
            _text('dlNationality', hint: 'e.g. Filipino'),
            required: true,
          ),
          _col(
            'dlCode',
            'License Code',
            _dropdown(
              'dlCode',
              hint: 'Select license code',
              options: _licenseCodes,
              value: _dlCode,
              onChanged: (v) => _dlCode = v,
            ),
            required: true,
          ),
        ),
        const SizedBox(height: 26),
        _section(
          'OR / CR Information',
          'Fill in the details as shown on your OR / CR.',
        ),
        const SizedBox(height: 12),
        _col(
          'orCr',
          'OR / CR',
          _uploadField('orCr', hint: 'Upload OR / CR'),
          required: true,
        ),
        const SizedBox(height: 16),
        _row2(
          _col(
            'mvFile',
            'MV File No.',
            _text('mvFile', hint: 'e.g. 1234567890'),
            required: true,
          ),
          _col(
            'orPlate',
            'Plate No.',
            _text('orPlate', hint: 'e.g. ABC 1234'),
            required: true,
          ),
        ),
        _gap(),
        _row2(
          _col(
            'make',
            'Make',
            _text('make', hint: 'e.g. Honda, Yamaha'),
            required: true,
          ),
          _col(
            'series',
            'Series / Model',
            _text('series', hint: 'e.g. Click 125i'),
          ),
        ),
        _gap(),
        _row2(
          _col(
            'body',
            'Body Type',
            _text('body', hint: 'e.g. Motorcycle'),
            required: true,
          ),
          _col('color', 'Color', _text('color', hint: 'e.g. Black')),
        ),
        _gap(),
        _row2(
          _col(
            'year',
            'Year Model',
            _text('year', hint: 'e.g. 2022', keyboard: TextInputType.number),
            required: true,
          ),
          _col(
            'engine',
            'Engine No.',
            _text('engine', hint: 'Engine number'),
            required: true,
          ),
        ),
        _gap(),
        _col(
          'chassis',
          'Chassis No.',
          _text('chassis', hint: 'Chassis / VIN number'),
          required: true,
        ),
        _gap(),
        _col(
          'owner',
          'Registered Owner',
          _text('owner', hint: 'Full name of registered owner'),
          required: true,
        ),
        _gap(),
        _col(
          'ownerAddress',
          'Owner Address',
          _text('ownerAddress', hint: 'Address of registered owner'),
          required: true,
        ),
        _gap(),
        _col(
          'regExp',
          'Registration Expiration',
          _dateField('regExp'),
          required: true,
        ),
      ],
    );
  }

  Widget _step3() {
    final cities = _province == null
        ? const <String>[]
        : (_locations[_province]!.keys.toList()..sort());
    final barangays = (_province == null || _city == null)
        ? const <String>[]
        : _locations[_province]![_city]!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _section(
          'Contact & Address',
          'Tell us how to reach you and where you live.',
        ),
        const SizedBox(height: 18),
        _col(
          'phone',
          'Phone Number',
          _text(
            'phone',
            hint: 'e.g. 09XX XXX XXXX',
            icon: Icons.phone_outlined,
            keyboard: TextInputType.phone,
          ),
          required: true,
        ),
        _gap(),
        _col(
          'province',
          'Province',
          _dropdown(
            'province',
            hint: 'Select province',
            options: _locations.keys.toList()..sort(),
            value: _province,
            onChanged: (v) {
              _province = v;
              _city = null;
              _barangay = null;
            },
          ),
          required: true,
        ),
        _gap(),
        _col(
          'city',
          'Municipality / City',
          _dropdown(
            'city',
            hint: 'Select municipality or city',
            options: cities,
            value: _city,
            onChanged: (v) {
              _city = v;
              _barangay = null;
            },
          ),
          required: true,
        ),
        _gap(),
        _col(
          'barangay',
          'Barangay',
          _dropdown(
            'barangay',
            hint: 'Select barangay',
            options: barangays,
            value: _barangay,
            onChanged: (v) => _barangay = v,
          ),
          required: true,
        ),
        _gap(),
        _col(
          'street',
          'Street / House No.',
          _text('street', hint: 'Enter street or house number'),
          required: true,
        ),
        _gap(),
        _col(
          'zip',
          'Zip Code',
          _text('zip', hint: 'Enter zip code', keyboard: TextInputType.number),
          required: true,
        ),
      ],
    );
  }

  Widget _step4() {
    final mi = _value('middleInitial');
    final fullName = [
      _value('firstName'),
      if (mi.isNotEmpty) '$mi.',
      _value('lastName'),
    ].join(' ');
    String v(String s) => s.trim().isEmpty ? '—' : s.trim();

    final rows = <(String, String)>[
      ('Full Name', fullName.isEmpty ? '—' : fullName),
      ('Phone Number', v(_value('phone'))),
      ('Province', v(_province ?? '')),
      ('Municipality / City', v(_city ?? '')),
      ('Barangay', v(_barangay ?? '')),
      ('Street / House No.', v(_value('street'))),
      ('Zip Code', v(_value('zip'))),
      ('Email', v(_value('email'))),
      ('Sex', v(_sex ?? '')),
      ('Birthday', v(_value('birthday'))),
      ('Age', v(_value('age'))),
      ('Valid ID', _files['validId'] ?? '—'),
      ('Vehicle Type', v(_vehicleType ?? '')),
      ('Plate Number', v(_value('plate'))),
      ("Driver's License", _files['license'] ?? '—'),
      ('OR / CR', _files['orCr'] ?? '—'),
      ('License No.', v(_value('dlLicenseNo'))),
      ('MV File No.', v(_value('mvFile'))),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _section(
          'Review your Information',
          'Please review all the details below before submitting.',
        ),
        const SizedBox(height: 18),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Rider Information',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                  ),
                  TextButton(
                    onPressed: () => _goToStep(0),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primaryDark,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                      textStyle: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    child: const Text('Edit'),
                  ),
                ],
              ),
              const Divider(color: AppColors.border),
              const SizedBox(height: 6),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 3.1,
                mainAxisSpacing: 10,
                crossAxisSpacing: 12,
                children: [
                  for (final (label, value) in rows) _reviewCell(label, value),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.mint,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.mintStrong),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.description_outlined,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Terms & Conditions',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => _goToStep(0),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primaryDark,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      minimumSize: Size.zero,
                    ),
                    child: const Text('Read'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'By creating an account you agree that the information you provided is true and correct, '
                'and that you accept the rider terms of service and privacy policy.',
                style: TextStyle(
                  fontSize: 12.5,
                  color: AppColors.ink,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              CheckboxListTile(
                value: _agreed,
                onChanged: (v) => setState(() => _agreed = v ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                dense: true,
                activeColor: AppColors.primary,
                title: const Text(
                  'I agree to the terms and conditions.',
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
                ),
              ),
              if (_error('agreed') != null)
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Text(
                    _error('agreed')!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.danger,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  void _goToStep(int step) => setState(() => _currentStep = step);

  Widget _reviewCell(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 11, color: AppColors.muted),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
      ],
    );
  }

  // ── Bottom action bar ────────────────────────────────────────────────────
  Widget _bottomBar() {
    final isLast = _currentStep == _totalSteps - 1;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 22),
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (_currentStep > 0) ...[
              OutlinedButton(
                onPressed: _goBack,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.ink,
                  side: const BorderSide(color: AppColors.border),
                  minimumSize: const Size(96, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: const Text('Back'),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _next,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  child: _submitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(isLast ? 'Create account' : 'Continue'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Create rider account'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () {
            if (_currentStep > 0) {
              _goBack();
            } else {
              Navigator.of(context).maybePop();
            }
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _stepBar(),
                  const SizedBox(height: 24),
                  IndexedStack(
                    index: _currentStep,
                    children: [_step1(), _step2(), _step3(), _step4()],
                  ),
                ],
              ),
            ),
          ),
          _bottomBar(),
        ],
      ),
    );
  }
}

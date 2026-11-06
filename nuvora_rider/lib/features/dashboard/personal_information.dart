import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/data/rider_session.dart';

/// Colours taken from the redesign (stitch_mobile_app_redesign).
class _Palette {
  static const forest = Color(0xFF143224);
  static const forestEnd = Color(0xFF0B2619);
  static const forestDeep = Color(0xFF001D10);
  static const secondary = Color(0xFF006C49);
  static const mint = Color(0xFF6FFBBE);
  static const background = Color(0xFFF3FCF5);
  static const surfaceLow = Color(0xFFEDF6EF);
  static const surface = Color(0xFFE7F0E9);
  static const border = Color(0xFFDCE5DE);
  static const ink = Color(0xFF151D19);
  static const inkVariant = Color(0xFF424844);
  static const outline = Color(0xFF727973);
  static const outlineSoft = Color(0xFFC2C8C2);
  static const onForestMuted = Color(0xFF9DB9A9);
  static const error = Color(0xFFBA1A1A);
  static const errorContainer = Color(0xFFFFDAD6);
}

// ─────────────────────────────────────────────────────────────────────────────
// Data
// ─────────────────────────────────────────────────────────────────────────────

/// The details a rider can edit on this screen.
class RiderPersonalInfo {
  const RiderPersonalInfo({
    this.phone = '',
    this.email = '',
    this.birthDate,
    this.emergencyName = '',
    this.emergencyRelation = '',
    this.emergencyPhone = '',
  });

  final String phone;
  final String email;
  final DateTime? birthDate;
  final String emergencyName;
  final String emergencyRelation;
  final String emergencyPhone;

  bool get hasEmergencyContact =>
      emergencyName.isNotEmpty || emergencyPhone.isNotEmpty;
}

/// Keeps the rider's edited details while the app is open, one entry per rider
/// so a different account never sees someone else's information.
///
/// To save to your backend, call your API from [save] and load from it in
/// [load]. The screen only talks to this class.
class PersonalInfoStore {
  PersonalInfoStore._();

  static final instance = PersonalInfoStore._();

  final Map<String, RiderPersonalInfo> _byRider = {};

  String _key(String riderName) => riderName.trim().toLowerCase();

  RiderPersonalInfo load(String riderName) =>
      _byRider[_key(riderName)] ?? const RiderPersonalInfo();

  void save(String riderName, RiderPersonalInfo info) {
    _byRider[_key(riderName)] = info;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

/// Rider personal information: read-only identity, editable contact details and
/// an emergency contact. Opened from the profile screen.
class PersonalInformationScreen extends StatefulWidget {
  const PersonalInformationScreen({super.key});

  @override
  State<PersonalInformationScreen> createState() =>
      _PersonalInformationScreenState();
}

class _PersonalInformationScreenState extends State<PersonalInformationScreen> {
  final _session = RiderSession.instance;
  final _store = PersonalInfoStore.instance;

  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _ecName = TextEditingController();
  final _ecRelation = TextEditingController();
  final _ecPhone = TextEditingController();
  DateTime? _birthDate;

  late RiderPersonalInfo _info;
  bool _editing = false;

  String? _phoneError;
  String? _emailError;
  String? _ecNameError;
  String? _ecPhoneError;

  static final _mobilePattern = RegExp(r'^(\+?63|0)?9\d{9}$');
  static final _phonePattern = RegExp(r'^\+?\d{7,15}$');
  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static const _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  @override
  void initState() {
    super.initState();
    _info = _store.load(_session.name);
  }

  @override
  void dispose() {
    _phone.dispose();
    _email.dispose();
    _ecName.dispose();
    _ecRelation.dispose();
    _ecPhone.dispose();
    super.dispose();
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  void _startEditing() {
    HapticFeedback.selectionClick();
    _phone.text = _info.phone;
    _email.text = _info.email;
    _ecName.text = _info.emergencyName;
    _ecRelation.text = _info.emergencyRelation;
    _ecPhone.text = _info.emergencyPhone;
    setState(() {
      _birthDate = _info.birthDate;
      _phoneError = _emailError = _ecNameError = _ecPhoneError = null;
      _editing = true;
    });
  }

  void _cancelEditing() {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _editing = false);
  }

  String _digitsOnly(String value) => value.replaceAll(RegExp(r'[\s\-()]'), '');

  bool _validate() {
    final phone = _digitsOnly(_phone.text);
    final email = _email.text.trim();
    final ecName = _ecName.text.trim();
    final ecPhone = _digitsOnly(_ecPhone.text);

    final phoneError = phone.isEmpty
        ? 'Enter your mobile number.'
        : (_mobilePattern.hasMatch(phone)
              ? null
              : 'Enter a valid mobile number, e.g. 0917 123 4567.');
    final emailError = email.isEmpty || _emailPattern.hasMatch(email)
        ? null
        : 'Enter a valid email address.';

    String? ecNameError;
    String? ecPhoneError;
    if (ecName.isNotEmpty || ecPhone.isNotEmpty) {
      if (ecName.length < 2) ecNameError = 'Enter the contact person’s name.';
      if (ecPhone.isEmpty) {
        ecPhoneError = 'Enter the emergency number.';
      } else if (!_phonePattern.hasMatch(ecPhone)) {
        ecPhoneError = 'Enter a valid phone number.';
      }
    }

    setState(() {
      _phoneError = phoneError;
      _emailError = emailError;
      _ecNameError = ecNameError;
      _ecPhoneError = ecPhoneError;
    });

    return phoneError == null &&
        emailError == null &&
        ecNameError == null &&
        ecPhoneError == null;
  }

  void _save() {
    if (!_validate()) {
      _snack('Please fix the highlighted fields.');
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();

    final updated = RiderPersonalInfo(
      phone: _phone.text.trim(),
      email: _email.text.trim(),
      birthDate: _birthDate,
      emergencyName: _ecName.text.trim(),
      emergencyRelation: _ecRelation.text.trim(),
      emergencyPhone: _ecPhone.text.trim(),
    );
    _store.save(_session.name, updated);

    HapticFeedback.mediumImpact();
    setState(() {
      _info = updated;
      _editing = false;
    });
    _snack('Personal information updated.');
  }

  Future<void> _pickBirthDate() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(now.year - 25, 1, 1),
      firstDate: DateTime(1940),
      lastDate: now,
      helpText: 'Date of birth',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(
            context,
          ).colorScheme.copyWith(primary: _Palette.secondary),
        ),
        child: child!,
      ),
    );
    if (picked == null || !mounted) return;
    setState(() => _birthDate = picked);
  }

  Future<void> _call(String number) async {
    final uri = Uri(scheme: 'tel', path: _digitsOnly(number));
    if (!await launchUrl(uri) && mounted) {
      _snack('Could not open the phone app.');
    }
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  // ── Formatting ────────────────────────────────────────────────────────────

  String _formatDate(DateTime date) =>
      '${_months[date.month - 1]} ${date.day}, ${date.year}';

  int _age(DateTime birth) {
    final now = DateTime.now();
    var age = now.year - birth.year;
    if (now.month < birth.month ||
        (now.month == birth.month && now.day < birth.day)) {
      age--;
    }
    return age;
  }

  String get _initials {
    final letters = _session.name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();
    return letters.isEmpty ? 'NR' : letters;
  }

  // ── Screen ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _Palette.background,
        body: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              Padding(
                padding: EdgeInsets.fromLTRB(16, 20, 16, 28 + bottomInset),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SectionTitle('Basic Information'),
                    const SizedBox(height: 10),
                    _buildBasicCard(),
                    const SizedBox(height: 20),
                    const _SectionTitle('Emergency Contact'),
                    const SizedBox(height: 10),
                    _buildEmergencyCard(),
                    const SizedBox(height: 20),
                    const _SectionTitle('Assigned Station & Vehicle'),
                    const SizedBox(height: 10),
                    _buildStationCard(),
                    const SizedBox(height: 16),
                    _buildNote(),
                    if (_editing) ...[
                      const SizedBox(height: 18),
                      _buildSaveButton(),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    final topInset = MediaQuery.of(context).padding.top;
    final station = _session.station.trim();

    const radius = BorderRadius.only(
      bottomLeft: Radius.circular(40),
      bottomRight: Radius.circular(40),
    );

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        borderRadius: radius,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_Palette.forest, _Palette.forestDeep],
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x1F001D10),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          const Positioned(
            right: -48,
            top: -48,
            child: _Ring(size: 192, alpha: 26),
          ),
          const Positioned(
            right: -24,
            top: -24,
            child: _Ring(size: 144, alpha: 38),
          ),
          const Positioned(
            left: -60,
            bottom: -30,
            child: _Glow(size: 224, color: Color(0x1A006C49)),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(16, topInset + 14, 16, 28),
            child: Column(
              children: [
                Row(
                  children: [
                    Semantics(
                      button: true,
                      label: 'Back',
                      child: Tooltip(
                        message: 'Back',
                        child: Material(
                          color: Colors.white.withAlpha(26),
                          shape: const CircleBorder(),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: () => Navigator.of(context).maybePop(),
                            child: const SizedBox(
                              width: 40,
                              height: 40,
                              child: Icon(
                                Icons.arrow_back_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const Expanded(
                      child: Text(
                        'Personal Information',
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    _EditPill(
                      editing: _editing,
                      onTap: _editing ? _cancelEditing : _startEditing,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: 84,
                  height: 84,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 84,
                        height: 84,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _Palette.secondary,
                          border: Border.all(
                            color: _Palette.mint.withAlpha(120),
                            width: 2,
                          ),
                        ),
                        child: Text(
                          _initials,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Positioned(
                        right: -2,
                        bottom: -2,
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(color: Colors.black26, blurRadius: 6),
                            ],
                          ),
                          child: const Icon(
                            Icons.verified_rounded,
                            color: _Palette.secondary,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _session.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(38),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withAlpha(51)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: _Palette.mint,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: Color(0x996FFBBE), blurRadius: 8),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Active Courier',
                        style: TextStyle(
                          color: Color(0xFFC8F7E3),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '•',
                        style: TextStyle(
                          color: Colors.white.withAlpha(102),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          station.isEmpty ? 'Station hub' : station,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
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

  // ── Basic information ─────────────────────────────────────────────────────
  Widget _buildBasicCard() {
    if (_editing) {
      return _Card(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _InfoRow(
              icon: Icons.person_outline_rounded,
              label: 'Full Name',
              value: _session.name,
              trailing: const Icon(
                Icons.lock_outline_rounded,
                size: 18,
                color: _Palette.outlineSoft,
              ),
              padded: false,
            ),
            const SizedBox(height: 4),
            const Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.only(left: 46),
                child: Text(
                  'Your name is set by Nuvora Dispatch.',
                  style: TextStyle(color: _Palette.outline, fontSize: 11.5),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _EditField(
              controller: _phone,
              label: 'Mobile Phone',
              hint: '0917 123 4567',
              icon: Icons.call_outlined,
              keyboardType: TextInputType.phone,
              error: _phoneError,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9+\s\-()]')),
              ],
            ),
            const SizedBox(height: 12),
            _EditField(
              controller: _email,
              label: 'Email Address',
              hint: 'you@email.com',
              icon: Icons.mail_outline_rounded,
              keyboardType: TextInputType.emailAddress,
              error: _emailError,
            ),
            const SizedBox(height: 12),
            _DateField(
              value: _birthDate == null ? null : _formatDate(_birthDate!),
              onTap: _pickBirthDate,
            ),
          ],
        ),
      );
    }

    final birth = _info.birthDate;

    return _Card(
      child: Column(
        children: [
          _InfoRow(
            icon: Icons.person_outline_rounded,
            label: 'Full Name',
            value: _session.name,
            trailing: const Icon(
              Icons.badge_outlined,
              size: 18,
              color: _Palette.outlineSoft,
            ),
          ),
          const _RowDivider(),
          _InfoRow(
            icon: Icons.call_outlined,
            label: 'Mobile Phone',
            value: _info.phone,
            trailing: _info.phone.isEmpty
                ? null
                : _RoundAction(
                    icon: Icons.phone_in_talk_outlined,
                    label: 'Call',
                    onTap: () => _call(_info.phone),
                  ),
          ),
          const _RowDivider(),
          _InfoRow(
            icon: Icons.mail_outline_rounded,
            label: 'Email Address',
            value: _info.email,
            trailing: const Icon(
              Icons.alternate_email_rounded,
              size: 18,
              color: _Palette.outlineSoft,
            ),
          ),
          const _RowDivider(),
          _InfoRow(
            icon: Icons.cake_outlined,
            label: 'Date of Birth',
            value: birth == null ? '' : _formatDate(birth),
            trailing: birth == null
                ? null
                : Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: _Palette.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_age(birth)} yrs',
                      style: const TextStyle(
                        color: _Palette.inkVariant,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ── Emergency contact ─────────────────────────────────────────────────────
  Widget _buildEmergencyCard() {
    if (_editing) {
      return _Card(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _EditField(
              controller: _ecName,
              label: 'Contact Person',
              hint: 'Full name',
              icon: Icons.contacts_outlined,
              textCapitalization: TextCapitalization.words,
              error: _ecNameError,
            ),
            const SizedBox(height: 12),
            _EditField(
              controller: _ecRelation,
              label: 'Relationship',
              hint: 'e.g. Sister, Spouse, Parent',
              icon: Icons.family_restroom_outlined,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 12),
            _EditField(
              controller: _ecPhone,
              label: 'Emergency Number',
              hint: '0920 114 9821',
              icon: Icons.sos_outlined,
              keyboardType: TextInputType.phone,
              error: _ecPhoneError,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9+\s\-()]')),
              ],
            ),
          ],
        ),
      );
    }

    if (!_info.hasEmergencyContact) {
      return _Card(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: _Palette.surfaceLow,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.contact_phone_outlined,
                color: _Palette.outline,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'No emergency contact yet. Tap Edit to add someone Dispatch can '
                'reach if something happens.',
                style: TextStyle(
                  color: _Palette.inkVariant,
                  fontSize: 12.5,
                  height: 1.45,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return _Card(
      child: Column(
        children: [
          _InfoRow(
            icon: Icons.contacts_outlined,
            label: 'Contact Person',
            value: _info.emergencyName,
            chip: _info.emergencyRelation.isEmpty
                ? null
                : _info.emergencyRelation,
            trailing: const Icon(
              Icons.family_restroom_outlined,
              size: 18,
              color: _Palette.outlineSoft,
            ),
          ),
          const _RowDivider(),
          _InfoRow(
            icon: Icons.sos_outlined,
            label: 'Emergency Number',
            value: _info.emergencyPhone,
            danger: true,
            trailing: _info.emergencyPhone.isEmpty
                ? null
                : _CallPill(onTap: () => _call(_info.emergencyPhone)),
          ),
        ],
      ),
    );
  }

  // ── Station & vehicle (managed by Dispatch, read-only) ────────────────────
  Widget _buildStationCard() {
    final station = _session.station.trim();
    final vehicle = _session.vehicle.trim();

    return _Card(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: _Palette.surfaceLow,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.storefront_outlined,
                  size: 20,
                  color: _Palette.secondary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Hub Location',
                      style: TextStyle(
                        color: _Palette.outline,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      station.isEmpty ? 'Station hub' : station,
                      style: const TextStyle(
                        color: _Palette.ink,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _Palette.surfaceLow,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _Palette.surface),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.two_wheeler_outlined,
                  size: 18,
                  color: _Palette.secondary,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Vehicle',
                  style: TextStyle(
                    color: _Palette.secondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Text(
                  vehicle.isEmpty ? 'Not set' : vehicle,
                  style: const TextStyle(
                    color: _Palette.ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNote() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _Palette.surfaceLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _Palette.surface),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.shield_outlined, color: _Palette.secondary, size: 22),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Managed by Nuvora Dispatch',
                  style: TextStyle(
                    color: _Palette.ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Your name, station and vehicle can only be changed by your '
                  'Station Hub. You can update your contact details above.',
                  style: TextStyle(
                    color: _Palette.outline,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton.icon(
        onPressed: _save,
        style: FilledButton.styleFrom(
          backgroundColor: _Palette.forest,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        icon: const Icon(Icons.save_outlined, size: 20),
        label: const Text('Update Personal Info'),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Small widgets
// ─────────────────────────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  const _Card({required this.child, this.padding = EdgeInsets.zero});

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _Palette.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A143224),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) =>
      const Divider(height: 1, thickness: 1, color: _Palette.surface);
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 16,
            decoration: BoxDecoration(
              color: _Palette.secondary,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              color: _Palette.forestDeep,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.1,
            ),
          ),
        ],
      ),
    );
  }
}

/// One read-only line: round icon, small label, value and an optional trailing
/// widget. Empty values show "Not set".
class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.trailing,
    this.chip,
    this.danger = false,
    this.padded = true,
  });

  final IconData icon;
  final String label, value;
  final Widget? trailing;
  final String? chip;
  final bool danger;
  final bool padded;

  @override
  Widget build(BuildContext context) {
    final empty = value.trim().isEmpty;

    return Padding(
      padding: padded
          ? const EdgeInsets.symmetric(horizontal: 14, vertical: 12)
          : EdgeInsets.zero,
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: danger ? _Palette.errorContainer : _Palette.surface,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 19,
              color: danger ? _Palette.error : _Palette.secondary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: _Palette.outline,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  empty ? 'Not set' : value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: empty ? _Palette.outlineSoft : _Palette.ink,
                    fontSize: 14,
                    fontWeight: empty ? FontWeight.w500 : FontWeight.w600,
                  ),
                ),
                if (chip != null) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: _Palette.surface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      chip!,
                      style: const TextStyle(
                        color: _Palette.inkVariant,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 8), trailing!],
        ],
      ),
    );
  }
}

class _RoundAction extends StatelessWidget {
  const _RoundAction({
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
          color: _Palette.surface,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: SizedBox(
              width: 36,
              height: 36,
              child: Icon(icon, size: 18, color: _Palette.secondary),
            ),
          ),
        ),
      ),
    );
  }
}

class _CallPill extends StatelessWidget {
  const _CallPill({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _Palette.errorContainer,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.emergency_outlined, size: 16, color: _Palette.error),
              SizedBox(width: 4),
              Text(
                'Call',
                style: TextStyle(
                  color: _Palette.error,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditPill extends StatelessWidget {
  const _EditPill({required this.editing, required this.onTap});

  final bool editing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: editing ? Colors.white.withAlpha(26) : _Palette.secondary,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                editing ? Icons.close_rounded : Icons.edit_outlined,
                size: 16,
                color: Colors.white,
              ),
              const SizedBox(width: 4),
              Text(
                editing ? 'Cancel' : 'Edit',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

InputDecoration _fieldDecoration({
  required String label,
  required String hint,
  required IconData icon,
  String? error,
}) {
  OutlineInputBorder border(Color color, [double width = 1]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: color, width: width),
      );

  return InputDecoration(
    labelText: label,
    hintText: hint,
    errorText: error,
    labelStyle: const TextStyle(color: _Palette.outline, fontSize: 14),
    hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13.5),
    floatingLabelStyle: const TextStyle(
      color: _Palette.secondary,
      fontWeight: FontWeight.w700,
    ),
    prefixIcon: Icon(icon, size: 20, color: _Palette.outline),
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    border: border(_Palette.border),
    enabledBorder: border(_Palette.border),
    focusedBorder: border(_Palette.secondary, 1.5),
    errorBorder: border(_Palette.error),
    focusedErrorBorder: border(_Palette.error, 1.5),
  );
}

class _EditField extends StatelessWidget {
  const _EditField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.error,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
  });

  final TextEditingController controller;
  final String label, hint;
  final IconData icon;
  final String? error;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      inputFormatters: inputFormatters,
      style: const TextStyle(
        color: _Palette.ink,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      decoration: _fieldDecoration(
        label: label,
        hint: hint,
        icon: icon,
        error: error,
      ),
    );
  }
}

/// Date of birth field: looks like the other inputs and opens a date picker.
class _DateField extends StatelessWidget {
  const _DateField({required this.value, required this.onTap});

  final String? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: InputDecorator(
        isEmpty: value == null,
        decoration:
            _fieldDecoration(
              label: 'Date of Birth',
              hint: 'Select date',
              icon: Icons.cake_outlined,
            ).copyWith(
              suffixIcon: const Icon(
                Icons.calendar_month_outlined,
                size: 20,
                color: _Palette.outline,
              ),
            ),
        child: Text(
          value ?? '',
          style: const TextStyle(
            color: _Palette.ink,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _Ring extends StatelessWidget {
  const _Ring({required this.size, required this.alpha});

  final double size;
  final int alpha;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: _Palette.mint.withAlpha(alpha ~/ 2)),
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
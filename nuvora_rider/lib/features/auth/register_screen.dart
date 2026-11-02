import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/api/rider_api.dart';
import '../../core/data/ph_address.dart';
import '../../core/ocr/document_reader.dart';
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
  final Map<String, XFile> _docs = {};
  final Set<String> _flagged = {};
  bool _scanning = false;

  String? _sex;
  String? _vehicleType;
  String? _dlCode;
  String? _province;
  String? _city;
  String? _barangay;
  PhPlace? _provincePlace;
  PhPlace? _cityPlace;
  List<PhPlace> _provinces = const [];
  List<PhPlace> _cities = const [];
  List<PhPlace> _barangays = const [];
  bool _loadingProvinces = true;
  bool _loadingCities = false;
  bool _loadingBarangays = false;
  String? _provinceError;
  String? _cityError;
  String? _barangayError;
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
  final List<String> _licenseCodes = licenseCodeOptions;

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
    _loadProvinces();
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
        return _docs['validId'] == null
            ? 'Upload a photo of your valid ID.'
            : null;
      case 'license':
        return _docs['license'] == null
            ? "Upload your driver's license."
            : null;
      case 'orCr':
        return _docs['orCr'] == null ? 'Upload your OR / CR.' : null;
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

  /// Opens the camera or the gallery for real, keeps the shot, and — for the
  /// driver's license and the OR / CR — reads the printed details off it.
  Future<void> _pickDocument(String id) async {
    final source = await showModalBottomSheet<ImageSource>(
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
              Text(
                id == 'license' || id == 'orCr'
                    ? 'Take a clear, well-lit photo — the details are filled in '
                          'for you automatically.'
                    : 'JPG or PNG, clear and readable.',
                style: const TextStyle(fontSize: 13, color: AppColors.muted),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(
                  Icons.photo_camera_outlined,
                  color: AppColors.primary,
                ),
                title: const Text('Open camera'),
                subtitle: const Text('Take a photo now'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(
                  Icons.photo_library_outlined,
                  color: AppColors.primary,
                ),
                title: const Text('Choose from gallery'),
                subtitle: const Text('Pick a photo you already have'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );
    if (source == null || !mounted) return;

    XFile? shot;
    try {
      shot = await ImagePicker().pickImage(
        source: source,
        imageQuality: 90,
        maxWidth: 2000,
        maxHeight: 2000,
      );
    } on PlatformException catch (error) {
      if (!mounted) return;
      _toast(
        source == ImageSource.camera
            ? 'Could not open the camera: ${error.message ?? error.code}.'
            : 'Could not open the gallery: ${error.message ?? error.code}.',
      );
      return;
    } catch (error) {
      if (!mounted) return;
      _toast('Could not read that file: $error');
      return;
    }
    if (shot == null || !mounted) return;

    final doc = shot;
    setState(() {
      _docs[id] = doc;
      _flagged.remove(id);
    });

    if (id == 'license' || id == 'orCr') await _readDocument(id, doc);
  }

  /// Runs on-device OCR and fills the matching form fields.
  Future<void> _readDocument(String id, XFile shot) async {
    setState(() => _scanning = true);
    try {
      final scan = id == 'license'
          ? await DocumentReader.license(shot.path)
          : await DocumentReader.orCr(shot.path);
      if (!mounted) return;
      if (scan.isEmpty) {
        _toast(
          'Photo saved, but no details could be read. Please type them in.',
        );
        return;
      }

      var filled = 0;
      setState(() {
        scan.fields.forEach((field, value) {
          final text = value.trim();
          if (text.isEmpty) return;
          if (field == 'vehicleType') {
            _vehicleType = text;
            filled++;
            return;
          }
          if (field == 'dlCode') {
            _dlCode = text;
            filled++;
            return;
          }
          final controller = _fields[field];
          if (controller == null) return;
          controller.text = text;
          filled++;
        });
        _flagged.removeAll(scan.fields.keys.toList());
      });

      _toast(
        filled == 0
            ? 'Photo saved, but no details could be read. Please type them in.'
            : 'Filled $filled fields from your '
                  '${id == 'license' ? "driver's license" : 'OR / CR'}. '
                  'Please check them before continuing.',
      );
    } catch (error) {
      if (!mounted) return;
      debugPrint('Nuvora document scan: $error');
      _toast(
        'Photo saved, but the details could not be read automatically. '
        'Please type them in.',
      );
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  // ── Philippine address (live PSGC data) ──────────────────────────────
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
    } on RiderApiException catch (error) {
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
    } on RiderApiException catch (error) {
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
    } on RiderApiException catch (error) {
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
      _province = place.name;
      _cityPlace = null;
      _city = null;
      _barangay = null;
      _cities = const [];
      _barangays = const [];
      _cityError = null;
      _barangayError = null;
      _flagged.removeAll(const ['province', 'city', 'barangay']);
    });
    _loadCities(place);
  }

  void _chooseCity(PhPlace place) {
    setState(() {
      _cityPlace = place;
      _city = place.name;
      _barangay = null;
      _barangays = const [];
      _barangayError = null;
      _flagged.removeAll(const ['city', 'barangay']);
    });
    _loadBarangays(place);
  }

  void _chooseBarangay(PhPlace place) {
    setState(() {
      _barangay = place.name;
      _flagged.remove('barangay');
    });
  }

  /// A tappable field that opens the searchable list of every option, so all
  /// 82 provinces / all cities / all barangays are reachable, not just a few.
  Widget _addressField({
    required String hint,
    required String searchHint,
    required String? value,
    required List<PhPlace> options,
    required bool loading,
    required String? error,
    required ValueChanged<PhPlace> onPick,
    required VoidCallback onRetry,
  }) {
    final hasError = error != null;
    final enabled = !loading && options.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: enabled
              ? () async {
                  final picked = await _showOptionSheet(
                    searchHint,
                    options,
                    current: value,
                  );
                  if (picked != null) onPick(picked);
                }
              : null,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: hasError ? AppColors.danger : AppColors.border,
                width: 1.2,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    loading ? 'Loading…' : (value ?? hint),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: value == null
                          ? FontWeight.w400
                          : FontWeight.w700,
                      color: value == null ? AppColors.muted : AppColors.ink,
                    ),
                  ),
                ),
                if (loading)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  )
                else
                  const Icon(Icons.expand_more_rounded, color: AppColors.muted),
              ],
            ),
          ),
        ),
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
                  style: const TextStyle(fontSize: 12, color: AppColors.danger),
                ),
              ),
              TextButton(
                onPressed: onRetry,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primaryDark,
                  minimumSize: const Size(50, 32),
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  textStyle: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                child: const Text('Try again'),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Future<PhPlace?> _showOptionSheet(
    String title,
    List<PhPlace> options, {
    String? current,
  }) {
    return showModalBottomSheet<PhPlace>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
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
                bottom: MediaQuery.of(context).viewInsets.bottom,
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
                        color: AppColors.border,
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
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppColors.ink,
                              ),
                            ),
                          ),
                          Text(
                            '${shown.length}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.muted,
                            ),
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
                        decoration: const InputDecoration(
                          hintText: 'Search…',
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            size: 19,
                            color: AppColors.muted,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: shown.isEmpty
                          ? const Center(
                              child: Text(
                                'No matching results.',
                                style: TextStyle(color: AppColors.muted),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
                              itemCount: shown.length,
                              itemBuilder: (context, index) {
                                final place = shown[index];
                                final selected = place.name == current;
                                return ListTile(
                                  title: Text(
                                    place.name,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: AppColors.ink,
                                    ),
                                  ),
                                  trailing: selected
                                      ? const Icon(
                                          Icons.check_rounded,
                                          color: AppColors.primary,
                                          size: 18,
                                        )
                                      : null,
                                  onTap: () => Navigator.pop(context, place),
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

  Widget _uploadField(String id, {required String hint}) {
    final doc = _docs[id];
    final hasError = _error(id) != null;
    final canScan = id == 'license' || id == 'orCr';

    return InkWell(
      onTap: _scanning ? null : () => _pickDocument(id),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          color: doc == null ? AppColors.mint : AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: hasError
                ? AppColors.danger
                : (doc == null ? AppColors.mintStrong : AppColors.primary),
            width: 1.2,
          ),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: doc == null
                  ? Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: const Icon(
                        Icons.upload_file_outlined,
                        color: Colors.white,
                        size: 20,
                      ),
                    )
                  : Image.file(
                      File(doc.path),
                      width: 38,
                      height: 38,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: AppColors.mint,
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: const Icon(
                          Icons.check_circle_outline,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doc?.name ?? hint,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: doc == null
                          ? AppColors.ink
                          : AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    doc == null
                        ? (canScan
                              ? 'Camera or gallery · details fill in'
                              : 'Tap to attach')
                        : (canScan
                              ? 'Attached · details filled in'
                              : 'Attached · tap to replace'),
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
              color: doc == null ? AppColors.muted : AppColors.primary,
            ),
          ],
        ),
      ),
    );
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
          _addressField(
            hint: 'Select province',
            searchHint: 'Search province',
            value: _province,
            options: _provinces,
            loading: _loadingProvinces,
            error: _provinceError,
            onPick: _chooseProvince,
            onRetry: _loadProvinces,
          ),
          required: true,
        ),
        _gap(),
        _col(
          'city',
          'Municipality / City',
          _addressField(
            hint: _province == null
                ? 'Select a province first'
                : 'Select municipality or city',
            searchHint: 'Search city or municipality',
            value: _city,
            options: _cities,
            loading: _loadingCities,
            error: _cityError,
            onPick: _chooseCity,
            onRetry: () {
              final place = _provincePlace;
              if (place != null) _loadCities(place);
            },
          ),
          required: true,
        ),
        _gap(),
        _col(
          'barangay',
          'Barangay',
          _addressField(
            hint: _city == null
                ? 'Select a city or municipality first'
                : 'Select barangay',
            searchHint: 'Search barangay',
            value: _barangay,
            options: _barangays,
            loading: _loadingBarangays,
            error: _barangayError,
            onPick: _chooseBarangay,
            onRetry: () {
              final place = _cityPlace;
              if (place != null) _loadBarangays(place);
            },
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
      ('Valid ID', _docs['validId']?.name ?? '—'),
      ('Vehicle Type', v(_vehicleType ?? '')),
      ('Plate Number', v(_value('plate'))),
      ("Driver's License", _docs['license']?.name ?? '—'),
      ('OR / CR', _docs['orCr']?.name ?? '—'),
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
      body: Stack(
        children: [
          Column(
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
          if (_scanning) Positioned.fill(child: _scanOverlay()),
        ],
      ),
    );
  }

  Widget _scanOverlay() {
    return ColoredBox(
      color: Colors.black.withAlpha(80),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 26,
                height: 26,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: AppColors.primary,
                ),
              ),
              SizedBox(height: 14),
              Text(
                'Reading the document…',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
              ),
              SizedBox(height: 4),
              Text(
                'The details are filled in when it is done.',
                style: TextStyle(fontSize: 12, color: AppColors.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

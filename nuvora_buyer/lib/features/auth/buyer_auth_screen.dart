import 'package:flutter/material.dart';

import '../../core/api/buyer_api.dart';

class BuyerAuthScreen extends StatefulWidget {
  const BuyerAuthScreen({super.key});

  @override
  State<BuyerAuthScreen> createState() => _BuyerAuthScreenState();
}

class _BuyerAuthScreenState extends State<BuyerAuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _fields = {
    for (final field in [
      'first_name',
      'last_name',
      'birthday',
      'email',
      'contact_no',
      'password',
      'password_confirmation',
      'province',
      'municipality',
      'barangay',
      'street',
      'postal_code',
      'otp',
    ])
      field: TextEditingController(),
  };

  bool _isRegistering = false;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _emailVerified = false;
  bool _codeSent = false;
  String? _verifiedEmail;
  String? _signedInName;

  @override
  void dispose() {
    for (final controller in _fields.values) {
      controller.dispose();
    }
    super.dispose();
  }

  String _value(String key) => _fields[key]!.text.trim();

  Future<void> _sendCode() async {
    final email = _value('email');
    if (email.isEmpty || !email.contains('@')) {
      _showMessage('Enter a valid email address first.');
      return;
    }

    await _perform(() async {
      await BuyerApi.instance.sendEmailCode(email);
      if (!mounted) return;
      setState(() {
        _codeSent = true;
        _emailVerified = false;
        _verifiedEmail = null;
      });
      _showMessage('Verification code sent. Check your email.');
    });
  }

  Future<void> _verifyCode() async {
    final email = _value('email');
    final code = _value('otp');
    if (email.isEmpty || code.length != 6) {
      _showMessage('Enter the 6-digit code sent to your email.');
      return;
    }

    await _perform(() async {
      await BuyerApi.instance.verifyEmailCode(email, code);
      if (!mounted) return;
      setState(() {
        _emailVerified = true;
        _verifiedEmail = email.toLowerCase();
      });
      _showMessage('Email verified. You can submit your registration.');
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_isRegistering) {
      if (!_emailVerified || _verifiedEmail != _value('email').toLowerCase()) {
        _showMessage('Verify your email address before registering.');
        return;
      }
      if (_value('password') != _value('password_confirmation')) {
        _showMessage('Passwords do not match.');
        return;
      }

      await _perform(() async {
        final payload = <String, String>{
          for (final key in [
            'first_name',
            'last_name',
            'birthday',
            'email',
            'contact_no',
            'password',
            'password_confirmation',
            'province',
            'municipality',
            'barangay',
            'street',
            'postal_code',
          ])
            key: _value(key),
        };
        final result = await BuyerApi.instance.register(payload);
        if (!mounted) return;
        setState(() {
          _isRegistering = false;
          _emailVerified = false;
          _verifiedEmail = null;
        });
        _showMessage(result['message']?.toString() ?? 'Registration submitted.');
      });
      return;
    }

    await _perform(() async {
      final result = await BuyerApi.instance.login(
        _value('email'),
        _value('password'),
      );
      if (!mounted) return;
      final buyer = result['buyer'];
      setState(() {
        _signedInName = buyer is Map
            ? (buyer['first_name']?.toString().trim().isNotEmpty == true
                  ? buyer['first_name'].toString()
                  : buyer['name']?.toString() ?? _value('email'))
            : _value('email');
      });
    });
  }

  Future<void> _perform(Future<void> Function() action) async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      await action();
    } on BuyerApiException catch (error) {
      if (mounted) _showMessage(error.message);
    } catch (_) {
      if (mounted) {
        _showMessage('Could not connect to Nuvora. Check the server and API URL.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _pickBirthday() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 18),
      firstDate: DateTime(1920),
      lastDate: DateTime(now.year - 18, now.month, now.day),
    );
    if (picked == null) return;
    _fields['birthday']!.text =
        '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    setState(() {});
  }

  Widget _textField(
    String key,
    String label, {
    TextInputType? keyboardType,
    bool required = true,
    bool password = false,
    bool readOnly = false,
    VoidCallback? onTap,
    void Function(String)? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: _fields[key],
        keyboardType: keyboardType,
        obscureText: password && _obscurePassword,
        readOnly: readOnly,
        onTap: onTap,
        onChanged: onChanged,
        validator: (value) {
          final text = value?.trim() ?? '';
          if (required && text.isEmpty) return 'This field is required.';
          if (key == 'email' && text.isNotEmpty && !text.contains('@')) {
            return 'Enter a valid email address.';
          }
          if (key == 'password' && _isRegistering && text.length < 8) {
            return 'Use at least 8 characters.';
          }
          if (key == 'contact_no' &&
              text.isNotEmpty &&
              !RegExp(r'^09\d{9}$').hasMatch(text)) {
            return 'Use the format 09XXXXXXXXX.';
          }
          return null;
        },
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          suffixIcon: password
              ? IconButton(
                  onPressed: () => setState(() {
                    _obscurePassword = !_obscurePassword;
                  }),
                  icon: Icon(
                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                  ),
                )
              : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_signedInName != null) return _signedInView();

    final title = _isRegistering ? 'Create buyer account' : 'Welcome back';
    return Scaffold(
      appBar: AppBar(title: const Text('Nuvora Buyer')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Icon(
                    Icons.shopping_bag_outlined,
                    size: 52,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isRegistering
                        ? 'Register with Nuvora. Your account requires admin approval.'
                        : 'Sign in with your Nuvora buyer account.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  if (_isRegistering) ...[
                    _textField('first_name', 'First name'),
                    _textField('last_name', 'Last name'),
                    _textField(
                      'birthday',
                      'Birthday (18+)',
                      readOnly: true,
                      onTap: _pickBirthday,
                    ),
                  ],
                  _textField(
                    'email',
                    'Email address',
                    keyboardType: TextInputType.emailAddress,
                    onChanged: _isRegistering
                        ? (email) {
                            if (_verifiedEmail != email.trim().toLowerCase()) {
                              setState(() {
                                _emailVerified = false;
                                _verifiedEmail = null;
                              });
                            }
                          }
                        : null,
                  ),
                  if (_isRegistering) ...[
                    OutlinedButton.icon(
                      onPressed: _isLoading ? null : _sendCode,
                      icon: const Icon(Icons.mark_email_read_outlined),
                      label: Text(_codeSent ? 'Resend verification code' : 'Send email code'),
                    ),
                    const SizedBox(height: 12),
                    if (_codeSent) ...[
                      _textField(
                        'otp',
                        '6-digit email code',
                        keyboardType: TextInputType.number,
                      ),
                      OutlinedButton(
                        onPressed: _isLoading ? null : _verifyCode,
                        child: Text(_emailVerified ? 'Email verified' : 'Verify email code'),
                      ),
                      const SizedBox(height: 14),
                    ],
                    _textField(
                      'contact_no',
                      'Mobile number (09XXXXXXXXX)',
                      keyboardType: TextInputType.phone,
                    ),
                  ],
                  _textField('password', 'Password', password: true),
                  if (_isRegistering) ...[
                    _textField(
                      'password_confirmation',
                      'Confirm password',
                      password: true,
                    ),
                    _textField('province', 'Province'),
                    _textField('municipality', 'Municipality / city'),
                    _textField('barangay', 'Barangay'),
                    _textField('street', 'Street / house details'),
                    _textField(
                      'postal_code',
                      'Postal code (optional)',
                      required: false,
                      keyboardType: TextInputType.number,
                    ),
                  ],
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: _isLoading ? null : _submit,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(_isRegistering ? 'Submit registration' : 'Sign in'),
                  ),
                  TextButton(
                    onPressed: _isLoading
                        ? null
                        : () => setState(() {
                            _isRegistering = !_isRegistering;
                            _emailVerified = false;
                            _verifiedEmail = null;
                            _codeSent = false;
                          }),
                    child: Text(
                      _isRegistering
                          ? 'Already registered? Sign in'
                          : 'New to Nuvora? Create an account',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _signedInView() {
    return Scaffold(
      appBar: AppBar(title: const Text('Nuvora Buyer')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle_outline, size: 64),
              const SizedBox(height: 16),
              Text('Welcome, $_signedInName!'),
              const SizedBox(height: 8),
              const Text('You are signed in to your Nuvora buyer account.'),
              const SizedBox(height: 20),
              OutlinedButton(
                onPressed: () => setState(() => _signedInName = null),
                child: const Text('Sign out'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

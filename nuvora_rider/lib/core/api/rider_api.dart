import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Anything the rider can be told about: an unreachable server, a rejected
/// login or a validation error.
class RiderApiException implements Exception {
  const RiderApiException(this.message, [this.statusCode]);

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class RiderApi {
  RiderApi._();

  static final RiderApi instance = RiderApi._();

  /// `--dart-define=NUVORA_API_BASE_URL=http://192.168.1.4:8000/api`
  ///
  /// Pinning the URL is the reliable way to run on a real phone; the automatic
  /// guesses below only cover the usual development cases.
  static const String _configured = String.fromEnvironment(
    'NUVORA_API_BASE_URL',
    defaultValue: '',
  );

  static const Duration _probeTimeout = Duration(milliseconds: 1500);

  /// `10.0.2.2` is the Android emulator's alias for the host PC. A real phone
  /// needs the PC's Wi-Fi address instead. `php artisan serve` listens on 8000
  /// by default; 8001 is used when 8000 is already taken.
  static const List<String> _androidCandidates = [
    'http://10.0.2.2:8000/api',
    'http://10.0.2.2:8001/api',
    'http://192.168.1.4:8000/api',
    'http://192.168.1.4:8001/api',
  ];

  static const List<String> _desktopCandidates = [
    'http://127.0.0.1:8000/api',
    'http://127.0.0.1:8001/api',
    'http://192.168.1.4:8000/api',
  ];

  static String? _resolved;

  /// The URL in use, for the register screen and error messages.
  static String get baseUrl {
    if (_configured.isNotEmpty) return _normalise(_configured);
    final resolved = _resolved;
    if (resolved != null) return resolved;
    final candidates = _candidates;
    return candidates.isEmpty ? '' : candidates.first;
  }

  static List<String> get _candidates {
    if (kReleaseMode) return const [];
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return _androidCandidates;
    }
    return _desktopCandidates;
  }

  /// `http://192.168.1.4/api` (no port) would target port 80, where nothing is
  /// listening in development, so every request would hang until it times out.
  static String _normalise(String url) {
    final trimmed = url.trim().replaceFirst(RegExp(r'/+$'), '');
    final uri = Uri.tryParse(trimmed);
    if (uri == null ||
        uri.scheme != 'http' ||
        !uri.hasAuthority ||
        uri.hasPort) {
      return trimmed;
    }
    return uri.replace(port: 8000).toString();
  }

  static Future<String> _base() async {
    if (_configured.isNotEmpty) return baseUrl;
    final resolved = _resolved;
    if (resolved != null) return resolved;

    final candidates = _candidates;
    if (candidates.isEmpty) {
      throw const RiderApiException(
        'This build needs a server URL. Rebuild with '
        '--dart-define=NUVORA_API_BASE_URL=https://your-nuvora-site/api',
      );
    }

    for (final candidate in candidates) {
      if (await _reachable(candidate)) return _resolved = candidate;
    }

    throw const RiderApiException(
      'Cannot reach the Nuvora server. Start it with '
      '`php artisan serve --host=0.0.0.0 --port=8000`, then run the app with '
      '--dart-define=NUVORA_API_BASE_URL=http://<your PC IP>:8000/api. '
      'This device and the PC must be on the same Wi-Fi.',
    );
  }

  static Future<bool> _reachable(String candidate) async {
    final uri = Uri.tryParse('$candidate/rider/login');
    if (uri == null) return false;
    try {
      // A GET on a POST-only route answers 405, which still proves that the
      // server is running and that this device can see it.
      await http.get(uri).timeout(_probeTimeout);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> sendEmailCode(String email) async {
    await _request('email/otp/send', {'email': email.trim()});
  }

  Future<void> verifyEmailCode(String email, String code) async {
    await _request('email/otp/verify', {
      'email': email.trim(),
      'code': code.trim(),
    });
  }

  Future<Map<String, dynamic>> register(Map<String, String> fields) =>
      _request('rider-applications', fields);

  Future<Map<String, dynamic>> login(String email, String password) =>
      _request('rider/login', {'email': email.trim(), 'password': password});

  /// GET a JSON list from the API — used by the PSGC address proxy behind
  /// the province / city / barangay pickers.
  Future<List<Map<String, dynamic>>> getList(
    String path, {
    Duration timeout = const Duration(seconds: 20),
  }) async {
    final url = '${await _base()}/$path';
    try {
      final response = await http
          .get(Uri.parse(url), headers: const {'Accept': 'application/json'})
          .timeout(timeout);
      final status = response.statusCode;
      final decoded = jsonDecode(response.body);

      if (status >= 400) {
        final message = decoded is Map ? decoded['error']?.toString() : null;
        throw RiderApiException(
          message ?? 'Could not load $url (HTTP $status).',
          status,
        );
      }
      if (decoded is! List) {
        throw RiderApiException('Unexpected response from $url.');
      }

      return [
        for (final item in decoded)
          if (item is Map) Map<String, dynamic>.from(item),
      ];
    } on TimeoutException {
      throw RiderApiException(
        'No answer from $url after ${timeout.inSeconds}s.',
      );
    } on http.ClientException catch (error) {
      debugPrint('Nuvora API: $error ($url)');
      throw const RiderApiException(
        'Cannot reach the Nuvora server. Check that it is running with '
        '--host=0.0.0.0 and that this device is on the same Wi-Fi.',
      );
    } on FormatException {
      throw RiderApiException('Could not read the Nuvora response from $url.');
    }
  }

  Future<Map<String, dynamic>> _request(
    String path,
    Map<String, String> fields, {
    Duration timeout = const Duration(seconds: 25),
  }) async {
    final url = '${await _base()}/$path';
    try {
      final response = await http
          .post(Uri.parse(url), headers: _jsonHeaders, body: jsonEncode(fields))
          .timeout(timeout);
      return _body(response, url);
    } on TimeoutException {
      throw RiderApiException(
        'No answer from $url after ${timeout.inSeconds}s. Is '
        '`php artisan serve --host=0.0.0.0` still running?',
      );
    } on http.ClientException catch (error) {
      debugPrint('Nuvora API: $error ($url)');
      throw RiderApiException(
        'Cannot reach $url. Check the server is running with --host=0.0.0.0, '
        'that this phone and the PC share the same Wi-Fi, and that Windows '
        'Firewall allows port ${Uri.parse(url).port}.',
      );
    }
  }

  static const Map<String, String> _jsonHeaders = {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  Map<String, dynamic> _body(http.Response response, String url) {
    Map<String, dynamic> data;
    try {
      data = Map<String, dynamic>.from(jsonDecode(response.body) as Map);
    } catch (_) {
      throw RiderApiException(
        'Could not read the Nuvora response from $url '
        '(HTTP ${response.statusCode}).',
        response.statusCode,
      );
    }

    if (response.statusCode >= 400) {
      final errors = data['errors'];
      var message = data['message']?.toString();
      if (errors is Map && errors.isNotEmpty) {
        final firstError = errors.values.first;
        if (firstError is List && firstError.isNotEmpty) {
          message = firstError.first.toString();
        }
      }
      throw RiderApiException(
        message ?? 'Request failed. Please try again.',
        response.statusCode,
      );
    }

    return data;
  }
}

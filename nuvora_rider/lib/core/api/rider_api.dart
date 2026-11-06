import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Anything the rider can be told about: an unreachable server, a rejected
/// login or a validation error.
class RiderApiException implements Exception {
  const RiderApiException(this.message, [this.statusCode]);

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

/// Talks to the Nuvora rider API.
///
/// Signing in returns a Bearer token tied to the rider's Station Hub; every
/// assignment, scan, proof, earning and notification below is read from that
/// same hub, so nothing in the app is sample data.
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

  static const String _tokenKey = 'rider_token';
  static const String _profileKey = 'rider_profile';

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

  /* ── Session ── */

  Future<String?> _token() async =>
      (await SharedPreferences.getInstance()).getString(_tokenKey);

  Future<bool> hasSession() async => (await _token()) != null;

  /// Restores the rider who was signed in when the app was closed.
  ///
  /// Returns the login-shaped payload (`{'rider': {...}}`), or null when no
  /// token is stored.
  Future<Map<String, dynamic>?> restoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if ((prefs.getString(_tokenKey) ?? '').isEmpty) return null;

      final raw = prefs.getString(_profileKey);
      if (raw == null || raw.isEmpty) return {'rider': <String, dynamic>{}};

      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          return {'rider': Map<String, dynamic>.from(decoded)};
        }
      } catch (_) {
        // A profile saved by an older build is not worth failing over.
      }
      return {'rider': <String, dynamic>{}};
    } catch (_) {
      // No preferences plugin (e.g. in a widget test): start signed out.
      return null;
    }
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_profileKey);
  }

  Future<void> logout() async {
    try {
      await _post('rider/logout', const {});
    } catch (_) {
      // The token is discarded either way.
    }
    await clearSession();
  }

  /* ── Account ── */

  Future<Map<String, dynamic>> login(String email, String password) async {
    final data = await _post('rider/login', {
      'email': email.trim(),
      'password': password,
      'device_name': 'Nuvora Rider mobile',
    }, authenticated: false);

    final token = data['token']?.toString() ?? '';
    if (token.isEmpty) {
      throw const RiderApiException(
        'The Nuvora server did not return a sign-in token. Please update the '
        'server and try again.',
      );
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    final rider = data['rider'];
    await prefs.setString(
      _profileKey,
      jsonEncode(rider is Map ? Map<String, dynamic>.from(rider) : {}),
    );

    return data;
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

  /* ── Work from the rider's Station Hub ── */

  /// What the Parcels tab shows: seller pickups, final deliveries and
  /// linehaul transfers currently assigned to this rider.
  Future<Map<String, dynamic>> parcels() => _get('rider/parcels');

  Future<Map<String, dynamic>> earnings() => _get('rider/earnings');

  Future<Map<String, dynamic>> notifications() => _get('rider/notifications');

  Future<void> markNotificationRead(int notificationId) =>
      _post('rider/notifications/$notificationId/read', const {});

  Future<void> markAllNotificationsRead() =>
      _post('rider/notifications/read-all', const {});

  /// Records the scan that moves a pickup or linehaul parcel one step forward.
  Future<String> scan({
    required String trackingNumber,
    required String scanType,
    required String scanKey,
  }) async {
    final data = await _post('rider/scans', {
      'tracking_number': trackingNumber,
      'scan_type': scanType,
      'scan_key': scanKey,
    });
    return data['message']?.toString() ?? 'Scan saved.';
  }

  /// Hands a parcel to the buyer: photo, recipient and any COD cash.
  Future<String> submitProof({
    required int deliveryId,
    required String recipientName,
    required String photoPath,
    double? cashCollected,
  }) async {
    final url = '${await _base()}/rider/deliveries/$deliveryId/proof';

    Future<http.Response> send() async {
      final request = http.MultipartRequest('POST', Uri.parse(url));
      request.headers.addAll(await _authHeaders(json: false));
      request.fields['recipient_name'] = recipientName.trim();
      if (cashCollected != null) {
        request.fields['cash_collected'] = cashCollected.toStringAsFixed(2);
      }
      request.files.add(await http.MultipartFile.fromPath('photo', photoPath));

      final streamed = await request.send().timeout(
        const Duration(seconds: 60),
      );
      return http.Response.fromStream(streamed);
    }

    final data = await _guard(url, send, timeout: const Duration(seconds: 60));
    return data['message']?.toString() ?? 'Parcel delivered.';
  }

  Future<String> reportFailure(int deliveryId, String reason) async {
    final data = await _post('rider/deliveries/$deliveryId/fail', {
      'reason': reason,
    });
    return data['message']?.toString() ?? 'Issue sent to your Station Hub.';
  }

  Future<String> rescheduleDelivery(int deliveryId) async {
    final data = await _post(
      'rider/deliveries/$deliveryId/reschedule',
      const {},
    );
    return data['message']?.toString() ?? 'Delivery rescheduled.';
  }

  /* ── Address proxy for the application form ── */

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

  /* ── Requests ── */

  Future<Map<String, dynamic>> _get(String path) async {
    final url = '${await _base()}/$path';
    return _guard(
      url,
      () async =>
          http.get(Uri.parse(url), headers: await _authHeaders(json: false)),
    );
  }

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body, {
    bool authenticated = true,
  }) async {
    final url = '${await _base()}/$path';
    return _guard(
      url,
      () async => http.post(
        Uri.parse(url),
        headers: authenticated ? await _authHeaders() : _jsonHeaders,
        body: jsonEncode(body),
      ),
    );
  }

  /// Application intake and OTP calls, which need no token.
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

  Future<Map<String, dynamic>> _guard(
    String url,
    Future<http.Response> Function() send, {
    Duration timeout = const Duration(seconds: 25),
  }) async {
    try {
      final response = await send().timeout(timeout);
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

  Future<Map<String, String>> _authHeaders({bool json = true}) async {
    final token = await _token();
    if (token == null || token.isEmpty) {
      throw const RiderApiException('Please sign in again.', 401);
    }
    return {
      'Accept': 'application/json',
      if (json) 'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

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

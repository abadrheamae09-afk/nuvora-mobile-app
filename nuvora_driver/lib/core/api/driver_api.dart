import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

/// A failed Driver API call. [applicationStatus] is filled for a valid
/// applicant who is not approved yet, so the sign-in screen can say whether the
/// application is waiting or was rejected instead of "wrong password".
class DriverApiException implements Exception {
  const DriverApiException(
    this.message, {
    this.statusCode,
    this.applicationStatus,
    this.reviewingHub,
    this.rejectionReason,
  });

  final String message;
  final int? statusCode;
  final String? applicationStatus;
  final String? reviewingHub;
  final String? rejectionReason;

  bool get isPending => applicationStatus == 'pending';
  bool get isRejected => applicationStatus == 'rejected';

  /// The saved token is no longer accepted, so the app must sign in again.
  bool get isUnauthenticated => statusCode == 401;

  @override
  String toString() => message;
}

/// Talks to the Nuvora driver API.
///
/// Signing in returns a Bearer token tied to the driver's Station Hub; the trip
/// board, the load scans and the departure/arrival actions below all read and
/// write that same Station Hub, so nothing here is sample data.
class DriverApi {
  DriverApi._();

  static final DriverApi instance = DriverApi._();

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

  /// Full base for the driver endpoints, for the register screen and errors.
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
      throw const DriverApiException(
        'This build needs a server URL. Rebuild with '
        '--dart-define=NUVORA_API_BASE_URL=https://your-nuvora-site/api',
      );
    }

    for (final candidate in candidates) {
      if (await _reachable(candidate)) return _resolved = candidate;
    }

    throw const DriverApiException(
      'Cannot reach the Nuvora server. Start it with '
      '`php artisan serve --host=0.0.0.0 --port=8000`, then run the app with '
      '--dart-define=NUVORA_API_BASE_URL=http://<your PC IP>:8000/api. '
      'This device and the PC must be on the same Wi-Fi.',
    );
  }

  static Future<bool> _reachable(String candidate) async {
    final uri = Uri.tryParse('$candidate/driver/login');
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

  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  Future<bool> hasToken() async =>
      (await _storage.read(key: 'driver_token')) != null;

  Future<String?> driverName() => _storage.read(key: 'driver_name');
  Future<String?> driverApplyLabel() =>
      _storage.read(key: 'driver_apply_label');
  Future<String?> reviewingHubName() =>
      _storage.read(key: 'driver_reviewing_hub');
  Future<String?> stationHubName() => _storage.read(key: 'driver_station_hub');

  /// The last email used to apply, so the status check can prefill it.
  Future<String?> savedApplicationEmail() =>
      _storage.read(key: 'driver_application_email');

  Future<void> saveApplicationEmail(String email) =>
      _storage.write(key: 'driver_application_email', value: email.trim());

  /// Station Hubs and their Province Hubs, for the application's hub step.
  Future<Map<String, dynamic>> hubs() async {
    final response = await http
        .get(
          Uri.parse('${await _base()}/driver/province-hubs'),
          headers: {'Accept': 'application/json'},
        )
        .timeout(const Duration(seconds: 25));
    return _body(response);
  }

  /// Provinces from the same PSGC proxy the Nuvora rider app reads.
  Future<List<Map<String, dynamic>>> provinces() =>
      _addressList('address/provinces');

  /// Cities and municipalities of one province, from the same PSGC proxy.
  Future<List<Map<String, dynamic>>> cities(String provinceCode) =>
      _addressList('address/provinces/$provinceCode/cities-municipalities');

  /// Barangays of a city or municipality. Both address routes read the same
  /// table, so one path covers either place type.
  Future<Map<String, dynamic>> barangays(String cityCode) async {
    final rows = await _addressList('address/cities/$cityCode/barangays');

    return {
      'success': true,
      'barangays': {
        for (final row in rows)
          row['code'].toString(): row['name'].toString(),
      },
    };
  }

  /// A plain JSON list from the Nuvora address API, which needs no token.
  Future<List<Map<String, dynamic>>> _addressList(String path) async {
    final url = '${await _base()}/$path';

    try {
      final response = await http
          .get(Uri.parse(url), headers: const {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 20));
      final decoded = jsonDecode(response.body);

      if (response.statusCode >= 400) {
        final message = decoded is Map ? decoded['error']?.toString() : null;
        throw DriverApiException(
          message ?? 'Could not load $url (HTTP ${response.statusCode}).',
          statusCode: response.statusCode,
        );
      }
      if (decoded is! List) {
        throw DriverApiException('Unexpected response from $url.');
      }

      return [
        for (final item in decoded)
          if (item is Map) Map<String, dynamic>.from(item),
      ];
    } on TimeoutException {
      throw DriverApiException('No answer from $url after 20s.');
    } on http.ClientException {
      throw const DriverApiException(
        'Cannot reach the Nuvora server. Check it is running and that this '
        'device is on the same Wi-Fi.',
      );
    } on FormatException {
      throw DriverApiException('Could not read the Nuvora response from $url.');
    }
  }

  Future<void> sendRegistrationCode(String email) async {
    final response = await http
        .post(
          Uri.parse('${await _base()}/driver/email/otp/send'),
          headers: _jsonHeaders,
          body: jsonEncode({'email': email.trim()}),
        )
        .timeout(const Duration(seconds: 25));
    _body(response);
  }

  /// Nuvora marks the address verified on the server, so the application only
  /// has to prove it used the same address. The address itself is that proof.
  Future<String> verifyRegistrationCode(String email, String code) async {
    final response = await http
        .post(
          Uri.parse('${await _base()}/driver/email/otp/verify'),
          headers: _jsonHeaders,
          body: jsonEncode({'email': email.trim(), 'code': code.trim()}),
        )
        .timeout(const Duration(seconds: 25));
    _body(response);
    return email.trim();
  }

  Future<Map<String, dynamic>> register(
    Map<String, String> fields,
    Map<String, String> documentPaths,
  ) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${await _base()}/driver/register'),
    );
    request.headers['Accept'] = 'application/json';
    request.fields.addAll(fields);
    for (final entry in documentPaths.entries) {
      request.files.add(
        await http.MultipartFile.fromPath(entry.key, entry.value),
      );
    }
    final streamed = await request.send().timeout(const Duration(seconds: 90));
    return _body(await http.Response.fromStream(streamed));
  }

  /// Signs the driver in and keeps the token. Throws a [DriverApiException]
  /// whose [DriverApiException.applicationStatus] is set when the account is
  /// real but not approved yet.
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http
        .post(
          Uri.parse('${await _base()}/driver/login'),
          headers: _jsonHeaders,
          body: jsonEncode({
            'email': email.trim(),
            'password': password,
            'device_name': 'Nuvora Driver mobile',
          }),
        )
        .timeout(const Duration(seconds: 25));
    final data = _decode(response);
    if (response.statusCode >= 400) {
      final reviewingHub = data['reviewing_hub'];
      throw DriverApiException(
        data['message']?.toString() ?? 'Could not sign in.',
        statusCode: response.statusCode,
        applicationStatus: data['status']?.toString(),
        reviewingHub: reviewingHub is Map
            ? reviewingHub['name']?.toString()
            : reviewingHub?.toString(),
        rejectionReason: data['rejection_reason']?.toString(),
      );
    }

    await _storage.write(key: 'driver_token', value: data['token'] as String);
    await _storage.write(
      key: 'driver_name',
      value: (data['driver'] as Map)['name']?.toString(),
    );
    await _storage.write(
      key: 'driver_apply_label',
      value: (data['driver'] as Map)['apply_label']?.toString(),
    );
    await _storage.write(
      key: 'driver_reviewing_hub',
      value: (data['reviewing_hub'] as Map?)?['name']?.toString(),
    );
    await _storage.write(
      key: 'driver_station_hub',
      value: (data['station_hub'] as Map?)?['name']?.toString(),
    );
    await saveProfile(data);
    await saveApplicationEmail(email);
    return data;
  }

  /// Returns the application, or null when there is no application for the
  /// email. Used by the sign-in screen before the first sign-in.
  Future<Map<String, dynamic>?> applicationStatus(String email) async {
    final response = await http
        .post(
          Uri.parse('${await _base()}/driver/application-status'),
          headers: _jsonHeaders,
          body: jsonEncode({'email': email.trim()}),
        )
        .timeout(const Duration(seconds: 25));
    if (response.statusCode == 404) return null;
    final data = _decode(response);
    if (response.statusCode >= 400) {
      throw DriverApiException(
        data['message']?.toString() ?? 'Could not load your application.',
        statusCode: response.statusCode,
      );
    }
    return (data['application'] as Map?) == null
        ? null
        : Map<String, dynamic>.from(data['application'] as Map);
  }

  /// The signed-in driver, as the Station Hub approved them. Throws a
  /// [DriverApiException] with [DriverApiException.isUnauthenticated] for an
  /// expired or revoked token.
  Future<Map<String, dynamic>> me() async {
    final data = await _authorizedGet(
      '/driver/me',
      fallbackMessage: 'Could not load your driver account.',
    );
    await saveProfile(data);
    return data;
  }

  /// A signed-in GET. Every authenticated call goes through here so a revoked
  /// token is reported the same way across the app.
  Future<Map<String, dynamic>> _authorizedGet(
    String path, {
    String fallbackMessage = 'Could not load your trips.',
  }) async {
    final response = await http
        .get(Uri.parse('${await _base()}$path'), headers: await _authHeaders())
        .timeout(const Duration(seconds: 25));
    return _authorizedBody(response, fallbackMessage: fallbackMessage);
  }

  /// A signed-in POST. Used for the trip actions, which answer with a readable
  /// message when the server refuses them.
  Future<Map<String, dynamic>> _authorizedPost(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final response = await http
        .post(
          Uri.parse('${await _base()}$path'),
          headers: await _authHeaders(),
          body: body == null ? null : jsonEncode(body),
        )
        .timeout(const Duration(seconds: 25));
    return _authorizedBody(
      response,
      fallbackMessage: 'Could not update this trip.',
    );
  }

  Future<Map<String, dynamic>> _authorizedBody(
    http.Response response, {
    required String fallbackMessage,
  }) async {
    final data = _decode(response);
    if (response.statusCode >= 400) {
      if (response.statusCode == 401) await clearSession();
      throw DriverApiException(
        data['message']?.toString() ?? fallbackMessage,
        statusCode: response.statusCode,
      );
    }
    return data;
  }

  /// The trips the Station Hub already assigned to the driver: in transit
  /// first, then scheduled. Throws a [DriverApiException] with
  /// [DriverApiException.isUnauthenticated] when the token is no longer
  /// accepted, so the app can ask for a fresh sign-in.
  Future<List<Map<String, dynamic>>> trips() async {
    final data = await _authorizedGet('/driver/trips');
    final raw = data['trips'] as List? ?? const [];
    return raw
        .whereType<Map>()
        .map((trip) => Map<String, dynamic>.from(trip))
        .toList(growable: false);
  }

  /// Starts the trip. The server refuses with a 409 and a readable reason when
  /// a manifest parcel has not been scanned on board yet.
  Future<Map<String, dynamic>> departTrip(int tripId) async {
    final data = await _authorizedPost('/driver/trips/$tripId/depart');
    return Map<String, dynamic>.from(data['trip'] as Map);
  }

  /// Records the driver's load scan for one parcel or for a whole container
  /// label. The answer carries the trip as the server now sees it, so the
  /// screens follow the real scan counts instead of guessing.
  Future<Map<String, dynamic>> scanParcels(
    int tripId,
    List<String> trackingNumbers,
    String scanKey,
  ) async {
    final data = await _authorizedPost(
      '/driver/trips/$tripId/scan',
      body: {
        'tracking_numbers': trackingNumbers
            .map((tracking) => tracking.trim())
            .where((tracking) => tracking.isNotEmpty)
            .toList(),
        'scan_key': scanKey,
      },
    );
    return {
      'trip': Map<String, dynamic>.from(data['trip'] as Map),
      'duplicate': data['duplicate'] == true,
      'message': data['message']?.toString() ?? '',
      'scanned': (data['recorded'] as List? ?? const []).length,
    };
  }

  /// Completes the trip. The server refuses with a 409 and a readable reason
  /// when the trip has not departed yet.
  Future<Map<String, dynamic>> arriveTrip(int tripId) async {
    final data = await _authorizedPost('/driver/trips/$tripId/arrive');
    return Map<String, dynamic>.from(data['trip'] as Map);
  }

  /// Keeps the signed-in driver on the device, so a restart can show the real
  /// profile while [me] refreshes it from Nuvora.
  Future<void> saveProfile(Map<String, dynamic> data) async {
    final copy = Map<String, dynamic>.from(data)
      ..remove('token')
      ..remove('token_type')
      ..remove('expires_at');
    await _storage.write(key: 'driver_profile', value: jsonEncode(copy));
  }

  /// The last profile Nuvora returned, or null before the first sign-in.
  Future<Map<String, dynamic>?> savedProfile() async {
    final raw = await _storage.read(key: 'driver_profile');
    if (raw == null) return null;
    try {
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } on FormatException {
      return null;
    }
  }

  Future<void> sendPasswordResetCode(String email) async {
    final response = await http
        .post(
          Uri.parse('${await _base()}/driver/password/otp/send'),
          headers: _jsonHeaders,
          body: jsonEncode({'email': email.trim()}),
        )
        .timeout(const Duration(seconds: 25));
    _body(response);
  }

  Future<String> verifyPasswordResetCode(String email, String code) async {
    final response = await http
        .post(
          Uri.parse('${await _base()}/driver/password/otp/verify'),
          headers: _jsonHeaders,
          body: jsonEncode({'email': email.trim(), 'code': code.trim()}),
        )
        .timeout(const Duration(seconds: 25));
    return _body(response)['reset_token'] as String;
  }

  Future<void> resetPassword(
    String email,
    String resetToken,
    String password,
    String confirmation,
  ) async {
    final response = await http
        .post(
          Uri.parse('${await _base()}/driver/password/reset'),
          headers: _jsonHeaders,
          body: jsonEncode({
            'email': email.trim(),
            'reset_token': resetToken,
            'password': password,
            'password_confirmation': confirmation,
          }),
        )
        .timeout(const Duration(seconds: 25));
    _body(response);
  }

  Future<void> logout() async {
    if (await hasToken()) {
      try {
        await http
            .post(
              Uri.parse('${await _base()}/driver/logout'),
              headers: await _authHeaders(),
            )
            .timeout(const Duration(seconds: 15));
      } catch (_) {
        // The local session is cleared even when the server is unreachable.
      }
    }
    await clearSession();
  }

  Future<void> clearSession() async {
    await _storage.delete(key: 'driver_token');
    await _storage.delete(key: 'driver_name');
    await _storage.delete(key: 'driver_apply_label');
    await _storage.delete(key: 'driver_reviewing_hub');
    await _storage.delete(key: 'driver_station_hub');
    await _storage.delete(key: 'driver_profile');
  }

  static const Map<String, String> _jsonHeaders = {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  /// Headers for a signed-in call. Throws a 401 [DriverApiException] before
  /// the request when there is no token at all.
  Future<Map<String, String>> _authHeaders() async {
    final token = await _storage.read(key: 'driver_token');
    if (token == null) {
      throw const DriverApiException('Sign in to continue.', statusCode: 401);
    }
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Map<String, dynamic> _body(http.Response response) {
    final data = _decode(response);
    if (response.statusCode >= 400) {
      final errors = data['errors'];
      final detail = errors is Map && errors.isNotEmpty
          ? (errors.values.first as List).first.toString()
          : (data['message']?.toString() ??
                'Request failed. Please try again.');
      throw DriverApiException(detail, statusCode: response.statusCode);
    }
    return data;
  }

  Map<String, dynamic> _decode(http.Response response) {
    try {
      return Map<String, dynamic>.from(jsonDecode(response.body) as Map);
    } on FormatException {
      throw DriverApiException(
        'HTTP ${response.statusCode} from ${response.request?.url ?? baseUrl}. '
        'Check that this Nuvora server is running with the driver API.',
        statusCode: response.statusCode,
      );
    }
  }
}

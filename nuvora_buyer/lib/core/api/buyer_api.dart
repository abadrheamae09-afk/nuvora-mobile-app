import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Anything the buyer can be told about: an unreachable server, a rejected
/// login, a failed OTP or a validation error.
class BuyerApiException implements Exception {
  const BuyerApiException(this.message, [this.statusCode]);

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

/// Talks to the Nuvora buyer API.
///
/// Registration and login mirror the rider app: an email OTP gates account
/// creation, signing in returns a Bearer token, and every later request is
/// made with that token instead of a session cookie.
class BuyerApi {
  BuyerApi._();

  static final BuyerApi instance = BuyerApi._();

  /// `--dart-define=NUVORA_API_BASE_URL=http://192.168.1.4:8000/api`
  ///
  /// Pinning the URL is the reliable way to run on a real phone. Without it,
  /// debug builds fall back to the usual development hosts.
  static const String _configured = String.fromEnvironment(
    'NUVORA_API_BASE_URL',
    defaultValue: '',
  );

  static const String _tokenKey = 'buyer_token';
  static const String _profileKey = 'buyer_profile';

  /// `10.0.2.2` is the Android emulator's alias for the host PC. A real phone
  /// needs the PC's Wi-Fi address instead. `php artisan serve` listens on 8000
  /// by default.
  static String get baseUrl {
    if (_configured.isNotEmpty) {
      return _configured.trim().replaceFirst(RegExp(r'/+$'), '');
    }

    if (kReleaseMode) {
      throw const BuyerApiException(
        'This build needs a server URL. Rebuild with '
        '--dart-define=NUVORA_API_BASE_URL=https://your-nuvora-site/api',
      );
    }

    final host = !kIsWeb && defaultTargetPlatform == TargetPlatform.android
        ? '10.0.2.2'
        : '127.0.0.1';
    return 'http://$host:8000/api';
  }

  /* ── Session ── */

  Future<String?> _token() async =>
      (await SharedPreferences.getInstance()).getString(_tokenKey);

  Future<bool> hasSession() async => (await _token()) != null;

  /// Restores the buyer who was signed in when the app was closed.
  ///
  /// Returns the login-shaped payload (`{'buyer': {...}}`), or null when no
  /// token is stored.
  Future<Map<String, dynamic>?> restoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if ((prefs.getString(_tokenKey) ?? '').isEmpty) return null;

      final raw = prefs.getString(_profileKey);
      if (raw == null || raw.isEmpty) return {'buyer': <String, dynamic>{}};

      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          return {'buyer': Map<String, dynamic>.from(decoded)};
        }
      } catch (_) {
        // A profile saved by an older build is not worth failing over.
      }
      return {'buyer': <String, dynamic>{}};
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
      await _post('buyer/logout', const {});
    } catch (_) {
      // The token is discarded either way.
    }
    await clearSession();
  }

  /* ── Account ── */

  Future<Map<String, dynamic>> login(String email, String password) async {
    final data = await _post(
      'buyer/login',
      {
        'email': email.trim(),
        'password': password,
        'device_name': 'Nuvora Buyer mobile',
      },
      authenticated: false,
    );

    final token = data['token']?.toString() ?? '';
    if (token.isEmpty) {
      throw const BuyerApiException(
        'The Nuvora server did not return a sign-in token. Please update the '
        'server and try again.',
      );
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    final buyer = data['buyer'];
    await prefs.setString(
      _profileKey,
      jsonEncode(buyer is Map ? Map<String, dynamic>.from(buyer) : {}),
    );

    return data;
  }

  /// The signed-in buyer as the server currently sees them.
  Future<Map<String, dynamic>> me() => _get('buyer/me');

  Future<void> sendEmailCode(String email) async {
    await _request('email/otp/send', {'email': email.trim()});
  }

  Future<void> verifyEmailCode(String email, String code) async {
    await _request('email/otp/verify', {
      'email': email.trim(),
      'code': code.trim(),
    });
  }

  /// `buyer/register` only succeeds once the code was verified, so call
  /// [verifyEmailCode] first.
  Future<Map<String, dynamic>> register(Map<String, String> fields) =>
      _request('buyer/register', fields);

  /* ── Home catalogue ── */

  /// Featured Products, from the same public endpoint the buyer website uses.
  /// The endpoint accepts at most 12 cards per request.
  Future<List<Map<String, dynamic>>> featuredProducts({int limit = 12}) =>
      _catalogProducts('landing/featured', limit > 12 ? 12 : limit);

  /// The newest products. These used to be the "New Arrivals" row and now
  /// live under Featured Products. The endpoint accepts at most 8 cards.
  Future<List<Map<String, dynamic>>> newArrivals({int limit = 8}) =>
      _catalogProducts('landing/new-arrivals', limit > 8 ? 8 : limit);

  /// Cart, wishlist and notification counts for the signed-in buyer.
  Future<Map<String, dynamic>> summary() => _get('buyer/summary');

  /// Adds a product to the account cart (same cart table as the website).
  Future<Map<String, dynamic>> addToCart(int productId, {int? variantId}) =>
      _post('buyer/cart', {
        'product_id': productId,
        if (variantId != null) 'variant_id': variantId,
        'qty': 1,
      });

  /// Public landing rows. These answer even when the buyer is signed out, so
  /// the token is attached only when there is one.
  Future<List<Map<String, dynamic>>> _catalogProducts(
      String path, int limit) async {
    final url = '${baseUrl}/$path?limit=$limit';
    final token = await _token();

    late final http.Response response;
    try {
      response = await http.get(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 25));
    } on TimeoutException {
      throw BuyerApiException('No answer from $url. Is the server running?');
    } on http.ClientException catch (error) {
      debugPrint('Nuvora API: $error ($url)');
      throw BuyerApiException('Cannot reach $url. Check your connection.');
    }

    dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      throw BuyerApiException(
        'Could not read the product list (HTTP ${response.statusCode}).',
        response.statusCode,
      );
    }

    if (response.statusCode >= 400) {
      throw BuyerApiException(
        decoded is Map
            ? (decoded['message']?.toString() ?? 'Could not load products.')
            : 'Could not load products.',
        response.statusCode,
      );
    }

    if (decoded is! Map || decoded['products'] is! List) {
      throw BuyerApiException('Unexpected response from $url.');
    }

    return [
      for (final item in decoded['products'] as List)
        if (item is Map) Map<String, dynamic>.from(item),
    ];
  }

  /* ── Requests ── */

  Future<Map<String, dynamic>> _get(String path) async {
    final url = '${baseUrl}/$path';
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
    final url = '${baseUrl}/$path';
    return _guard(
      url,
      () async => http.post(
        Uri.parse(url),
        headers: authenticated ? await _authHeaders() : _jsonHeaders,
        body: jsonEncode(body),
      ),
    );
  }

  /// Address lookups (`address/provinces`, …) answer with a plain JSON array,
  /// which [_body] cannot read, so they go through this instead.
  Future<List<Map<String, dynamic>>> getList(
    String path, {
    Duration timeout = const Duration(seconds: 20),
  }) async {
    final url = '${baseUrl}/$path';

    late final http.Response response;
    try {
      response = await http
          .get(Uri.parse(url), headers: const {'Accept': 'application/json'})
          .timeout(timeout);
    } on TimeoutException {
      throw BuyerApiException(
        'No answer from $url after ${timeout.inSeconds}s. Is the server '
        'running?',
      );
    } on http.ClientException catch (error) {
      debugPrint('Nuvora API: $error ($url)');
      throw BuyerApiException('Cannot reach $url. Check your connection.');
    }

    dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      throw BuyerApiException(
        'Could not read the address list (HTTP ${response.statusCode}).',
        response.statusCode,
      );
    }

    if (response.statusCode >= 400) {
      final message = decoded is Map
          ? (decoded['error']?.toString() ?? decoded['message']?.toString())
          : null;
      throw BuyerApiException(
        message ?? 'Request failed (HTTP ${response.statusCode}).',
        response.statusCode,
      );
    }
    if (decoded is! List) {
      throw BuyerApiException('Unexpected response from $url.');
    }

    return [
      for (final item in decoded)
        if (item is Map) Map<String, dynamic>.from(item),
    ];
  }

  /// Registration and OTP calls, which need no token.
  Future<Map<String, dynamic>> _request(
    String path,
    Map<String, String> fields, {
    Duration timeout = const Duration(seconds: 25),
  }) async {
    final url = '${baseUrl}/$path';
    return _guard(
      url,
      () async =>
          http.post(Uri.parse(url), headers: _jsonHeaders, body: jsonEncode(fields)),
      timeout: timeout,
    );
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
      throw BuyerApiException(
        'No answer from $url after ${timeout.inSeconds}s. Is '
        '`php artisan serve --host=0.0.0.0` still running?',
      );
    } on http.ClientException catch (error) {
      debugPrint('Nuvora API: $error ($url)');
      throw BuyerApiException(
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
      throw const BuyerApiException('Please sign in again.', 401);
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
      throw BuyerApiException(
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
      throw BuyerApiException(
        message ?? 'Request failed. Please try again.',
        response.statusCode,
      );
    }

    return data;
  }
}

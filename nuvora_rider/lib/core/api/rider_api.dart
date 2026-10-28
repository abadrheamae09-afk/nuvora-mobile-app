import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

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
  static String get baseUrl {
    const configuredUrl = String.fromEnvironment('NUVORA_API_BASE_URL');
    if (configuredUrl.isNotEmpty) {
      return configuredUrl.replaceFirst(RegExp(r'/+$'), '');
    }

    if (kReleaseMode) {
      throw const RiderApiException(
        'Set NUVORA_API_BASE_URL to the Nuvora website API URL before building.',
      );
    }

    // 10.0.2.2 only resolves inside an Android emulator. On a real phone the
    // app must reach the PC running `php artisan serve` over the LAN, so the
    // default is the PC's local IP. Pass NUVORA_API_BASE_URL when that IP
    // changes or when running in an emulator (`--dart-define=NUVORA_API_BASE_URL=http://10.0.2.2:8000/api`).
    final host = !kIsWeb && defaultTargetPlatform == TargetPlatform.android
        ? '192.168.1.4'
        : '127.0.0.1';
    return 'http://$host:8000/api';
  }

  Future<void> sendEmailCode(String email) async {
    await _post('email/otp/send', {'email': email.trim()});
  }

  Future<void> verifyEmailCode(String email, String code) async {
    await _post('email/otp/verify', {
      'email': email.trim(),
      'code': code.trim(),
    });
  }

  Future<Map<String, dynamic>> register(Map<String, String> fields) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/rider-applications'),
          headers: _jsonHeaders,
          body: jsonEncode(fields),
        )
        .timeout(const Duration(seconds: 25));
    return _body(response);
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/rider/login'),
          headers: _jsonHeaders,
          body: jsonEncode({'email': email.trim(), 'password': password}),
        )
        .timeout(const Duration(seconds: 20));
    return _body(response);
  }

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, String> fields,
  ) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/$path'),
          headers: _jsonHeaders,
          body: jsonEncode(fields),
        )
        .timeout(const Duration(seconds: 25));
    return _body(response);
  }

  static const Map<String, String> _jsonHeaders = {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  Map<String, dynamic> _body(http.Response response) {
    Map<String, dynamic> data;
    try {
      data = Map<String, dynamic>.from(jsonDecode(response.body) as Map);
    } catch (_) {
      throw RiderApiException(
        'Could not read the Nuvora server response (HTTP ${response.statusCode}).',
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

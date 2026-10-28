import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class BuyerApiException implements Exception {
  const BuyerApiException(this.message, [this.statusCode]);

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class BuyerApi {
  BuyerApi._();

  static final BuyerApi instance = BuyerApi._();

  static String get baseUrl {
    const configuredUrl = String.fromEnvironment('NUVORA_API_BASE_URL');
    if (configuredUrl.isNotEmpty) {
      return configuredUrl.replaceFirst(RegExp(r'/+$'), '');
    }

    if (kReleaseMode) {
      throw const BuyerApiException(
        'Set NUVORA_API_BASE_URL to the Nuvora website API URL before building.',
      );
    }

    final host = !kIsWeb && defaultTargetPlatform == TargetPlatform.android
        ? '10.0.2.2'
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
    return _post('buyer/register', fields);
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    return _post('buyer/login', {
      'email': email.trim(),
      'password': password,
    });
  }

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, String> fields,
  ) async {
    final response = await http
        .post(
          Uri.parse('${baseUrl.replaceFirst(RegExp(r'/+$'), '')}/$path'),
          headers: const {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(fields),
        )
        .timeout(const Duration(seconds: 25));

    Map<String, dynamic> data;
    try {
      data = Map<String, dynamic>.from(jsonDecode(response.body) as Map);
    } catch (_) {
      throw BuyerApiException(
        'Could not read the Nuvora server response (HTTP ${response.statusCode}).',
        response.statusCode,
      );
    }

    if (response.statusCode >= 400 || data['success'] == false) {
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

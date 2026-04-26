import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:http/http.dart' as http;
import 'package:sage/data/sources/auth/auth_token_provider.dart';

class ApiClient {
  final http.Client _client;
  final AuthTokenProvider _tokenProvider;

  ApiClient({
    required http.Client client,
    required AuthTokenProvider tokenProvider,
  })  : _client = client,
        _tokenProvider = tokenProvider;

  Map<String, String> headers({
    bool json = true,
    bool authenticated = true,
    Map<String, String>? extra,
  }) {
    final token = authenticated ? _tokenProvider.getToken() : null;
    return {
      if (json) 'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
      if (extra != null) ...extra,
    };
  }

  Future<Either<String, dynamic>> getJson(
    String url, {
    bool authenticated = true,
  }) async {
    try {
      final response = await _client.get(
        Uri.parse(url),
        headers: headers(authenticated: authenticated),
      );
      return decodeResponse(response, fallback: 'Request failed.');
    } catch (_) {
      return const Left('Unable to connect to the backend.');
    }
  }

  Future<Either<String, dynamic>> postJson(
    String url, {
    Object? body,
    bool authenticated = true,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse(url),
        headers: headers(authenticated: authenticated),
        body: body == null ? null : jsonEncode(body),
      );
      return decodeResponse(response, fallback: 'Request failed.');
    } catch (_) {
      return const Left('Unable to connect to the backend.');
    }
  }

  Future<Either<String, dynamic>> patchJson(
    String url, {
    Object? body,
    bool authenticated = true,
  }) async {
    try {
      final response = await _client.patch(
        Uri.parse(url),
        headers: headers(authenticated: authenticated),
        body: body == null ? null : jsonEncode(body),
      );
      return decodeResponse(response, fallback: 'Request failed.');
    } catch (_) {
      return const Left('Unable to connect to the backend.');
    }
  }

  Future<Either<String, dynamic>> deleteJson(
    String url, {
    bool authenticated = true,
  }) async {
    try {
      final response = await _client.delete(
        Uri.parse(url),
        headers: headers(authenticated: authenticated),
      );
      return decodeResponse(response, fallback: 'Request failed.');
    } catch (_) {
      return const Left('Unable to connect to the backend.');
    }
  }

  Either<String, dynamic> decodeResponse(
    http.Response response, {
    required String fallback,
  }) {
    dynamic decoded;
    try {
      decoded = response.body.isEmpty ? <String, dynamic>{} : jsonDecode(response.body);
    } catch (_) {
      decoded = response.body;
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return Right(decoded);
    }

    if (response.statusCode == 401) {
      _tokenProvider.clearToken();
    }

    final extracted = _extractError(decoded);
    return Left(extracted ?? fallback);
  }

  String? _extractError(dynamic decoded) {
    if (decoded is Map<String, dynamic>) {
      final detail = decoded['detail'];
      if (detail is String && detail.isNotEmpty) return detail;
    }
    return null;
  }
}


import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spotify_with_flutter/core/constants/api_urls.dart';
import 'package:spotify_with_flutter/core/constants/app_urls.dart';
import 'package:spotify_with_flutter/data/models/auth/create_user_req.dart';
import 'package:spotify_with_flutter/data/models/auth/signin_user_req.dart';
import 'package:spotify_with_flutter/data/models/auth/user.dart';
import 'package:spotify_with_flutter/domain/entities/auth/user.dart';

abstract class AuthApiService {
  Future<Either> signup(CreateUserReq createUserReq);
  Future<Either> signin(SigninUserReq signinUserReq);
  Future<Either> getUser();
  Future<void> signout();
}

class AuthApiServiceImpl extends AuthApiService {
  static const _tokenKey = 'auth_token';

  final http.Client _client;
  final SharedPreferences _preferences;

  AuthApiServiceImpl({
    required http.Client client,
    required SharedPreferences preferences,
  })  : _client = client,
        _preferences = preferences;

  @override
  Future<Either> signup(CreateUserReq createUserReq) async {
    try {
      final response = await _client.post(
        Uri.parse(ApiUrls.signup),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'full_name': createUserReq.fullName,
          'email': createUserReq.email,
          'password': createUserReq.password,
        }),
      );

      final body = _decodeResponse(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final token = body['access_token'] as String?;
        if (token != null) {
          await _preferences.setString(_tokenKey, token);
        }
        return const Right('Signup was successful');
      }

      return Left(_extractError(body, fallback: 'Unable to create account.'));
    } catch (_) {
      return const Left('Unable to connect to the server.');
    }
  }

  @override
  Future<Either> signin(SigninUserReq signinUserReq) async {
    try {
      final response = await _client.post(
        Uri.parse(ApiUrls.login),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': signinUserReq.email,
          'password': signinUserReq.password,
        }),
      );

      final body = _decodeResponse(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final token = body['access_token'] as String?;
        if (token != null) {
          await _preferences.setString(_tokenKey, token);
        }
        return const Right('Signin was successful');
      }

      return Left(_extractError(body, fallback: 'Unable to sign in.'));
    } catch (_) {
      return const Left('Unable to connect to the server.');
    }
  }

  @override
  Future<Either> getUser() async {
    try {
      final token = _preferences.getString(_tokenKey);
      if (token == null || token.isEmpty) {
        return const Left('Please sign in first.');
      }

      final response = await _client.get(
        Uri.parse(ApiUrls.me),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final body = _decodeResponse(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final userModel = UserModel.fromApiJson(body);
        if ((userModel.imageURL ?? '').isEmpty) {
          userModel.imageURL = AppUrls.defaultAvatar;
        }
        final userEntity = userModel.toEntity();
        return Right(userEntity);
      }

      if (response.statusCode == 401) {
        await _preferences.remove(_tokenKey);
      }

      return Left(_extractError(body, fallback: 'Unable to fetch profile.'));
    } catch (_) {
      return const Left('Unable to connect to the server.');
    }
  }

  @override
  Future<void> signout() async {
    await _preferences.remove(_tokenKey);
  }

  dynamic _decodeResponse(String body) {
    if (body.isEmpty) {
      return <String, dynamic>{};
    }
    return jsonDecode(body);
  }

  String _extractError(dynamic body, {required String fallback}) {
    if (body is Map<String, dynamic>) {
      final detail = body['detail'];
      if (detail is String && detail.isNotEmpty) {
        return detail;
      }
    }
    return fallback;
  }
}

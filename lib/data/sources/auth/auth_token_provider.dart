import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthTokenProvider {
  static const tokenKey = 'auth_token';
  static String? _webSessionToken;

  final SharedPreferences _preferences;

  AuthTokenProvider({required SharedPreferences preferences})
      : _preferences = preferences;

  String? getToken() {
    if (kIsWeb) {
      return (_webSessionToken == null || _webSessionToken!.isEmpty)
          ? null
          : _webSessionToken;
    }
    final token = _preferences.getString(tokenKey);
    if (token == null || token.isEmpty) return null;
    return token;
  }

  Future<void> setToken(String token) async {
    if (kIsWeb) {
      _webSessionToken = token;
      return;
    }
    await _preferences.setString(tokenKey, token);
  }

  Future<void> clearToken() async {
    if (kIsWeb) {
      _webSessionToken = null;
      return;
    }
    await _preferences.remove(tokenKey);
  }
}


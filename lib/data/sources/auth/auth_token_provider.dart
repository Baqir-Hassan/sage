import 'package:shared_preferences/shared_preferences.dart';

class AuthTokenProvider {
  static const tokenKey = 'auth_token';

  final SharedPreferences _preferences;

  AuthTokenProvider({required SharedPreferences preferences})
      : _preferences = preferences;

  String? getToken() {
    final token = _preferences.getString(tokenKey);
    if (token == null || token.isEmpty) return null;
    return token;
  }

  Future<void> setToken(String token) async {
    await _preferences.setString(tokenKey, token);
  }

  Future<void> clearToken() async {
    await _preferences.remove(tokenKey);
  }
}


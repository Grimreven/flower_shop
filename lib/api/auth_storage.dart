import 'package:shared_preferences/shared_preferences.dart';

class AuthStorage {
  static const String _tokenKey = 'auth_token';
  static const String _legacyTokenKey = 'token';
  static const String _userIdKey = 'user_id';
  static const String _userNameKey = 'user_name';
  static const String _userEmailKey = 'user_email';

  static Future<void> saveAuth({
    required String token,
    required Map<String, dynamic> user,
  }) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    await prefs.setString(_tokenKey, token);
    await prefs.setString(_legacyTokenKey, token);
    await prefs.setInt(_userIdKey, _toInt(user['id']));
    await prefs.setString(_userNameKey, user['name']?.toString() ?? '');
    await prefs.setString(_userEmailKey, user['email']?.toString() ?? '');
  }

  static Future<void> saveToken(String token) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    await prefs.setString(_tokenKey, token);
    await prefs.setString(_legacyTokenKey, token);
  }

  static Future<String?> getToken() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    return prefs.getString(_tokenKey) ?? prefs.getString(_legacyTokenKey);
  }

  static Future<void> clear() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    await prefs.remove(_tokenKey);
    await prefs.remove(_legacyTokenKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_userNameKey);
    await prefs.remove(_userEmailKey);
  }

  static Future<bool> isAuthorized() async {
    final String? token = await getToken();

    return token != null && token.isNotEmpty;
  }

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();

    return int.tryParse(value.toString()) ?? 0;
  }
}
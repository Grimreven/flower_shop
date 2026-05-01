import 'package:get_storage/get_storage.dart';

class AuthStorage {
  static final GetStorage _box = GetStorage();

  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'auth_user';

  static Future<void> saveAuth({
    required String token,
    required Map<String, dynamic> user,
  }) async {
    await _box.write(_tokenKey, token);
    await _box.write(_userKey, user);
  }

  static Future<void> saveUser(Map<String, dynamic> user) async {
    await _box.write(_userKey, user);
  }

  static Future<String?> getToken() async {
    return _box.read<String>(_tokenKey);
  }

  static Future<Map<String, dynamic>?> getUser() async {
    final data = _box.read(_userKey);

    if (data == null) {
      return null;
    }

    return Map<String, dynamic>.from(data as Map);
  }

  static Future<void> clear() async {
    await _box.remove(_tokenKey);
    await _box.remove(_userKey);
  }
}
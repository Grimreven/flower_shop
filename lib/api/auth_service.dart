import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';

class AuthService {
  static const String baseUrl = 'http://127.0.0.1:3000';

  Future<Map<String, dynamic>?> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email.trim(),
          'password': password,
        }),
      );

      final dynamic decoded =
      response.body.isNotEmpty ? jsonDecode(response.body) : null;

      if (response.statusCode == 200) {
        return decoded as Map<String, dynamic>;
      }

      if (decoded is Map<String, dynamic> && decoded['message'] != null) {
        return {
          'message': decoded['message'].toString(),
          'statusCode': response.statusCode,
        };
      }

      return {
        'message': 'Ошибка при входе. Код: ${response.statusCode}',
        'statusCode': response.statusCode,
      };
    } catch (e) {
      return {
        'message': 'Не удалось подключиться к серверу: $e',
      };
    }
  }

  Future<Map<String, dynamic>?> register(
      String name,
      String email,
      String password,
      ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name.trim(),
          'email': email.trim(),
          'password': password,
        }),
      );

      final dynamic decoded =
      response.body.isNotEmpty ? jsonDecode(response.body) : null;

      if (response.statusCode == 200) {
        return decoded as Map<String, dynamic>;
      }

      if (decoded is Map<String, dynamic> && decoded['message'] != null) {
        return {
          'message': decoded['message'].toString(),
          'statusCode': response.statusCode,
        };
      }

      return {
        'message': 'Ошибка при регистрации. Код: ${response.statusCode}',
        'statusCode': response.statusCode,
      };
    } catch (e) {
      return {
        'message': 'Не удалось подключиться к серверу: $e',
      };
    }
  }

  Future<Map<String, dynamic>?> getProfile(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/profile'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }

      if (response.statusCode == 401 || response.statusCode == 403) {
        return {
          'authError': true,
          'message': 'Сессия истекла. Войдите снова.',
          'statusCode': response.statusCode,
        };
      }

      final dynamic decoded =
      response.body.isNotEmpty ? jsonDecode(response.body) : null;

      if (decoded is Map<String, dynamic> && decoded['message'] != null) {
        return {
          'message': decoded['message'].toString(),
          'statusCode': response.statusCode,
        };
      }

      return {
        'message': 'Не удалось загрузить профиль. Код: ${response.statusCode}',
        'statusCode': response.statusCode,
      };
    } catch (e) {
      return {
        'message': 'Ошибка getProfile: $e',
      };
    }
  }

  Future<Map<String, dynamic>?> updateProfile(String token, User user) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/profile'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(user.toJson()),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }

      if (response.statusCode == 401 || response.statusCode == 403) {
        return {
          'authError': true,
          'message': 'Сессия истекла. Войдите снова.',
          'statusCode': response.statusCode,
        };
      }

      final dynamic decoded =
      response.body.isNotEmpty ? jsonDecode(response.body) : null;

      if (decoded is Map<String, dynamic> && decoded['message'] != null) {
        return {
          'message': decoded['message'].toString(),
          'statusCode': response.statusCode,
        };
      }

      return {
        'message': 'Не удалось обновить профиль. Код: ${response.statusCode}',
        'statusCode': response.statusCode,
      };
    } catch (e) {
      return {
        'message': 'Ошибка updateProfile: $e',
      };
    }
  }
}
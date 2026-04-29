import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import 'auth_storage.dart';

class ServerApiService {
  static String get baseUrl => AppConfig.baseUrl;

  static Future<Map<String, String>> _headers({bool auth = false}) async {
    final headers = {
      'Content-Type': 'application/json',
    };

    if (auth) {
      final token = await AuthStorage.getToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: await _headers(),
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      await AuthStorage.saveAuth(
        token: data['token'],
        user: data['user'],
      );

      return data;
    }

    throw Exception(data['message'] ?? 'Ошибка входа');
  }

  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: await _headers(),
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      await AuthStorage.saveAuth(
        token: data['token'],
        user: data['user'],
      );

      return data;
    }

    throw Exception(data['message'] ?? 'Ошибка регистрации');
  }

  static Future<Map<String, dynamic>> getProfile() async {
    final response = await http.get(
      Uri.parse('$baseUrl/profile'),
      headers: await _headers(auth: true),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    }

    throw Exception(data['message'] ?? 'Ошибка получения профиля');
  }

  static Future<void> logout() async {
    try {
      await http.post(
        Uri.parse('$baseUrl/logout'),
        headers: await _headers(auth: true),
      );
    } finally {
      await AuthStorage.clear();
    }
  }

  static Future<List<dynamic>> getProducts() async {
    final response = await http.get(
      Uri.parse('$baseUrl/products'),
      headers: await _headers(),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception('Ошибка загрузки товаров');
  }

  static Future<List<dynamic>> getPopularProducts() async {
    final response = await http.get(
      Uri.parse('$baseUrl/products/popular'),
      headers: await _headers(),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception('Ошибка загрузки популярных товаров');
  }
}
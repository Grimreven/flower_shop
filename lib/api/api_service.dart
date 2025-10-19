// api/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import 'package:flower_shop/models/product.dart';

class ApiService {
  static const String baseUrl = "http://10.0.2.2:3000";

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("token");
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("token", token);
  }

  // ✅ Новый метод
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  static Future<Map<String, dynamic>?> register(String name, String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': name, 'email': email, 'password': password}),
      );

      if (response.headers['content-type']?.contains('application/json') ?? false) {
        return jsonDecode(response.body);
      } else {
        print("Сервер вернул не JSON: ${response.body}");
        return null;
      }
    } catch (e) {
      print("Ошибка регистрации: $e");
      return null;
    }
  }

  static Future<Map<String, dynamic>?> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.headers['content-type']?.contains('application/json') ?? false) {
        return jsonDecode(response.body);
      } else {
        print("Сервер вернул не JSON: ${response.body}");
        return null;
      }
    } catch (e) {
      print("Ошибка входа: $e");
      return null;
    }
  }

  static Future<User?> getProfile() async {
    final token = await getToken();
    if (token == null) return null;

    try {
      final response = await http.get(
        Uri.parse("$baseUrl/profile"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200 &&
          response.headers['content-type'] != null &&
          response.headers['content-type']!.contains('application/json')) {
        return User.fromJson(jsonDecode(response.body));
      } else {
        print("Ошибка получения профиля: ${response.body}");
        return null;
      }
    } catch (e) {
      print("Ошибка запроса профиля: $e");
      return null;
    }
  }

  static Future<User?> updateProfile(User user) async {
    final token = await getToken();
    if (token == null) return null;

    try {
      final response = await http.put(
        Uri.parse("$baseUrl/profile"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json"
        },
        body: jsonEncode(user.toJson()),
      );

      if (response.headers['content-type']?.contains('application/json') ?? false) {
        return User.fromJson(jsonDecode(response.body));
      } else {
        print("Ошибка обновления профиля: ${response.body}");
        return null;
      }
    } catch (e) {
      print("Ошибка запроса обновления профиля: $e");
      return null;
    }
  }

  static Future<void> logout() async {
    final token = await getToken();
    if (token != null) {
      await http.post(
        Uri.parse("$baseUrl/logout"),
        headers: {"Authorization": "Bearer $token"},
      );
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("token");
  }

  // Получение всех товаров
  static Future<List<Product>> fetchAllProducts() async {
    final response = await http.get(Uri.parse('$baseUrl/products'));
    // print("Ответ от сервера /products: ${response.body}");

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => Product.fromJson(e)).toList();
    } else {
      throw Exception('Ошибка загрузки товаров');
    }
  }

  // Получение популярных товаров
  static Future<List<Product>> fetchPopularProducts() async {
    final response = await http.get(Uri.parse('$baseUrl/products/popular'));
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => Product.fromJson(e)).toList();
    } else {
      throw Exception('Ошибка загрузки популярных товаров');
    }
  }
}

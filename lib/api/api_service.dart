import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product.dart';
import '../models/user.dart';

class ApiService {
  // Для эмулятора Android: 10.0.2.2 = localhost
  static const String baseUrl = 'http://10.0.2.2:3000';

  // ПРОДУКТЫ
  static Future<List<Product>> fetchAllProducts() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/products'));
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((e) => Product.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      print('Ошибка загрузки товаров: $e');
      return [];
    }
  }

  static Future<List<Product>> fetchPopularProducts() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/products/popular'));
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((e) => Product.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      print('Ошибка загрузки популярных товаров: $e');
      return [];
    }
  }

  // ПРОФИЛЬ
  static Future<User?> getProfile(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/profile'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        return User.fromJson(jsonDecode(response.body));
      }
      return null;
    } catch (e) {
      print('Ошибка загрузки профиля: $e');
      return null;
    }
  }

  static Future<User?> updateProfile(String token, User user) async {
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
        return User.fromJson(jsonDecode(response.body));
      }
      return null;
    } catch (e) {
      print('Ошибка обновления профиля: $e');
      return null;
    }
  }

  // КОРЗИНА
  static Future<List<dynamic>> getCart(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/cart'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
      return [];
    } catch (e) {
      print('Ошибка корзины: $e');
      return [];
    }
  }

  static Future<void> addToCart(int productId, int quantity, String token) async {
    await http.post(
      Uri.parse('$baseUrl/cart'),
      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      body: jsonEncode({'product_id': productId, 'quantity': quantity}),
    );
  }

  static Future<void> updateCart(int productId, int quantity, String token) async {
    await http.put(
      Uri.parse('$baseUrl/cart/$productId'),
      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      body: jsonEncode({'quantity': quantity}),
    );
  }

  static Future<void> removeFromCart(int productId, String token) async {
    await http.delete(
      Uri.parse('$baseUrl/cart/$productId'),
      headers: {'Authorization': 'Bearer $token'},
    );
  }
}

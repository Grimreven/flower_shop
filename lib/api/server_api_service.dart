import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import 'auth_storage.dart';

class ServerApiService {
  static String get baseUrl => AppConfig.baseUrl;

  static Future<Map<String, String>> _headers({bool auth = false}) async {
    final Map<String, String> headers = <String, String>{
      'Content-Type': 'application/json',
    };

    if (auth) {
      final String? token = await AuthStorage.getToken();

      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  static Future<List<Map<String, dynamic>>> getProducts() async {
    final http.Response response = await http.get(
      Uri.parse('$baseUrl/products'),
      headers: await _headers(),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;

      return data
          .map((dynamic item) => Map<String, dynamic>.from(item as Map))
          .toList();
    }

    throw Exception('Ошибка загрузки товаров: ${response.body}');
  }

  static Future<List<Map<String, dynamic>>> getPopularProducts() async {
    final http.Response response = await http.get(
      Uri.parse('$baseUrl/products/popular'),
      headers: await _headers(),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;

      return data
          .map((dynamic item) => Map<String, dynamic>.from(item as Map))
          .toList();
    }

    throw Exception('Ошибка загрузки популярных товаров: ${response.body}');
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final http.Response response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: await _headers(),
      body: jsonEncode(<String, dynamic>{
        'email': email,
        'password': password,
      }),
    );

    final Map<String, dynamic> data =
    jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 200) {
      await AuthStorage.saveAuth(
        token: data['token'] as String,
        user: Map<String, dynamic>.from(data['user'] as Map),
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
    final http.Response response = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: await _headers(),
      body: jsonEncode(<String, dynamic>{
        'name': name,
        'email': email,
        'password': password,
      }),
    );

    final Map<String, dynamic> data =
    jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 200) {
      await AuthStorage.saveAuth(
        token: data['token'] as String,
        user: Map<String, dynamic>.from(data['user'] as Map),
      );

      return data;
    }

    throw Exception(data['message'] ?? 'Ошибка регистрации');
  }

  static Future<Map<String, dynamic>> getProfile() async {
    final http.Response response = await http.get(
      Uri.parse('$baseUrl/profile'),
      headers: await _headers(auth: true),
    );

    final Map<String, dynamic> data =
    jsonDecode(response.body) as Map<String, dynamic>;

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

  static Future<List<Map<String, dynamic>>> getCart() async {
    final http.Response response = await http.get(
      Uri.parse('$baseUrl/cart'),
      headers: await _headers(auth: true),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;

      return data
          .map((dynamic item) => Map<String, dynamic>.from(item as Map))
          .toList();
    }

    throw Exception('Ошибка загрузки корзины: ${response.body}');
  }

  static Future<void> addToCart(int productId, int quantity) async {
    final http.Response response = await http.post(
      Uri.parse('$baseUrl/cart'),
      headers: await _headers(auth: true),
      body: jsonEncode(<String, dynamic>{
        'product_id': productId,
        'quantity': quantity,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Ошибка добавления в корзину: ${response.body}');
    }
  }

  static Future<void> updateCart(int productId, int quantity) async {
    final http.Response response = await http.put(
      Uri.parse('$baseUrl/cart/$productId'),
      headers: await _headers(auth: true),
      body: jsonEncode(<String, dynamic>{
        'quantity': quantity,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Ошибка обновления корзины: ${response.body}');
    }
  }

  static Future<void> removeFromCart(int productId) async {
    final http.Response response = await http.delete(
      Uri.parse('$baseUrl/cart/$productId'),
      headers: await _headers(auth: true),
    );

    if (response.statusCode != 200) {
      throw Exception('Ошибка удаления из корзины: ${response.body}');
    }
  }

  static Future<void> clearCart() async {
    final http.Response response = await http.delete(
      Uri.parse('$baseUrl/cart'),
      headers: await _headers(auth: true),
    );

    if (response.statusCode != 200 && response.statusCode != 404) {
      throw Exception('Ошибка очистки корзины: ${response.body}');
    }
  }

  static Future<List<int>> getFavorites() async {
    final http.Response response = await http.get(
      Uri.parse('$baseUrl/favorites'),
      headers: await _headers(auth: true),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;

      return data
          .map((dynamic item) => int.tryParse(item.toString()) ?? 0)
          .where((int id) => id > 0)
          .toList();
    }

    throw Exception('Ошибка загрузки избранного: ${response.body}');
  }

  static Future<void> addFavorite(int productId) async {
    final http.Response response = await http.post(
      Uri.parse('$baseUrl/favorites/$productId'),
      headers: await _headers(auth: true),
    );

    if (response.statusCode != 200) {
      throw Exception('Ошибка добавления в избранное: ${response.body}');
    }
  }

  static Future<void> removeFavorite(int productId) async {
    final http.Response response = await http.delete(
      Uri.parse('$baseUrl/favorites/$productId'),
      headers: await _headers(auth: true),
    );

    if (response.statusCode != 200) {
      throw Exception('Ошибка удаления из избранного: ${response.body}');
    }
  }

  static Future<void> clearFavorites() async {
    final http.Response response = await http.delete(
      Uri.parse('$baseUrl/favorites'),
      headers: await _headers(auth: true),
    );

    if (response.statusCode != 200) {
      throw Exception('Ошибка очистки избранного: ${response.body}');
    }
  }

  static Future<Map<String, dynamic>> createOrder({
    required List<Map<String, dynamic>> itemsMaps,
    required Map<String, dynamic> checkoutData,
  }) async {
    final List<Map<String, dynamic>> items = itemsMaps.map((item) {
      final dynamic productId = item['product_id'] ?? item['productId'] ?? item['id'];
      final dynamic quantity = item['quantity'];

      return <String, dynamic>{
        'product_id': productId,
        'quantity': quantity,
      };
    }).toList();

    final response = await http.post(
      Uri.parse('$baseUrl/orders'),
      headers: await _headers(auth: true),
      body: jsonEncode(<String, dynamic>{
        'items': items,
        'checkout': checkoutData,
      }),
    );

    final Map<String, dynamic> data =
    jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 200) {
      return data;
    }

    throw Exception(data['message'] ?? 'Ошибка оформления заказа');
  }

  static Future<List<Map<String, dynamic>>> getOrders() async {
    final response = await http.get(
      Uri.parse('$baseUrl/orders'),
      headers: await _headers(auth: true),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;

      return data
          .map((dynamic item) => Map<String, dynamic>.from(item as Map))
          .toList();
    }

    throw Exception('Ошибка загрузки заказов: ${response.body}');
  }

  static Future<void> updateOrderStatus(int orderId, String status) async {
    final response = await http.put(
      Uri.parse('$baseUrl/orders/$orderId/status'),
      headers: await _headers(auth: true),
      body: jsonEncode(<String, dynamic>{
        'status': status,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Ошибка обновления статуса заказа: ${response.body}');
    }
  }
}
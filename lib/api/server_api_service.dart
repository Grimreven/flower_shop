import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import 'auth_storage.dart';

class ServerApiService {
  static String get baseUrl => AppConfig.baseUrl;

  static Future<Map<String, String>> _headers({bool auth = false}) async {
    final Map<String, String> headers = {
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

  static Map<String, dynamic> _decodeMap(http.Response response) {
    final dynamic data = jsonDecode(response.body);

    if (data is Map<String, dynamic>) {
      return data;
    }

    return Map<String, dynamic>.from(data as Map);
  }

  static List<Map<String, dynamic>> _decodeList(http.Response response) {
    final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;

    return data
        .map((dynamic item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final http.Response response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: await _headers(),
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    final Map<String, dynamic> data = _decodeMap(response);

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
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
      }),
    );

    final Map<String, dynamic> data = _decodeMap(response);

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

    final Map<String, dynamic> data = _decodeMap(response);

    if (response.statusCode == 200) {
      return data;
    }

    throw Exception(data['message'] ?? 'Ошибка получения профиля');
  }

  static Future<Map<String, dynamic>> updateProfile({
    required String name,
    required String email,
    required String phone,
  }) async {
    final http.Response response = await http.put(
      Uri.parse('$baseUrl/profile'),
      headers: await _headers(auth: true),
      body: jsonEncode({
        'name': name,
        'email': email,
        'phone': phone,
      }),
    );

    final Map<String, dynamic> data = _decodeMap(response);

    if (response.statusCode == 200) {
      await AuthStorage.saveUser(data);
      return data;
    }

    throw Exception(data['message'] ?? 'Ошибка при обновлении профиля');
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

  static Future<List<Map<String, dynamic>>> getProducts() async {
    final http.Response response = await http.get(
      Uri.parse('$baseUrl/products'),
      headers: await _headers(),
    );

    if (response.statusCode == 200) {
      return _decodeList(response);
    }

    throw Exception('Ошибка загрузки товаров: ${response.body}');
  }

  static Future<List<Map<String, dynamic>>> getPopularProducts() async {
    final http.Response response = await http.get(
      Uri.parse('$baseUrl/products/popular'),
      headers: await _headers(),
    );

    if (response.statusCode == 200) {
      return _decodeList(response);
    }

    throw Exception('Ошибка загрузки популярных товаров: ${response.body}');
  }

  static Future<List<Map<String, dynamic>>> getCategories() async {
    final http.Response response = await http.get(
      Uri.parse('$baseUrl/categories'),
      headers: await _headers(),
    );

    if (response.statusCode == 200) {
      return _decodeList(response);
    }

    throw Exception('Ошибка загрузки категорий: ${response.body}');
  }

  static Future<List<Map<String, dynamic>>> getCart() async {
    final http.Response response = await http.get(
      Uri.parse('$baseUrl/cart'),
      headers: await _headers(auth: true),
    );

    if (response.statusCode == 200) {
      return _decodeList(response);
    }

    throw Exception('Ошибка загрузки корзины: ${response.body}');
  }

  static Future<void> addToCart(int productId, int quantity) async {
    final http.Response response = await http.post(
      Uri.parse('$baseUrl/cart'),
      headers: await _headers(auth: true),
      body: jsonEncode({
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
      body: jsonEncode({
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

  static Future<List<Map<String, dynamic>>> getAddresses() async {
    final http.Response response = await http.get(
      Uri.parse('$baseUrl/addresses'),
      headers: await _headers(auth: true),
    );

    if (response.statusCode == 200) {
      return _decodeList(response);
    }

    throw Exception('Ошибка загрузки адресов: ${response.body}');
  }

  static Future<Map<String, dynamic>> createAddress(
      Map<String, dynamic> body,
      ) async {
    final http.Response response = await http.post(
      Uri.parse('$baseUrl/addresses'),
      headers: await _headers(auth: true),
      body: jsonEncode(body),
    );

    final Map<String, dynamic> data = _decodeMap(response);

    if (response.statusCode == 200) {
      return data;
    }

    throw Exception(data['message'] ?? 'Ошибка создания адреса');
  }

  static Future<Map<String, dynamic>> updateAddress(
      int id,
      Map<String, dynamic> body,
      ) async {
    final http.Response response = await http.put(
      Uri.parse('$baseUrl/addresses/$id'),
      headers: await _headers(auth: true),
      body: jsonEncode(body),
    );

    final Map<String, dynamic> data = _decodeMap(response);

    if (response.statusCode == 200) {
      return data;
    }

    throw Exception(data['message'] ?? 'Ошибка обновления адреса');
  }

  static Future<void> deleteAddress(int id) async {
    final http.Response response = await http.delete(
      Uri.parse('$baseUrl/addresses/$id'),
      headers: await _headers(auth: true),
    );

    if (response.statusCode != 200) {
      final Map<String, dynamic> data = _decodeMap(response);
      throw Exception(data['message'] ?? 'Ошибка удаления адреса');
    }
  }

  static Future<Map<String, dynamic>> createOrder({
    required List<Map<String, dynamic>> itemsMaps,
    required Map<String, dynamic> checkoutData,
  }) async {
    final List<Map<String, dynamic>> items = itemsMaps.map((item) {
      return {
        'product_id': item['product_id'] ?? item['productId'] ?? item['id'],
        'quantity': item['quantity'],
      };
    }).toList();

    final http.Response response = await http.post(
      Uri.parse('$baseUrl/orders'),
      headers: await _headers(auth: true),
      body: jsonEncode({
        'items': items,
        'checkout': checkoutData,
      }),
    );

    final Map<String, dynamic> data = _decodeMap(response);

    if (response.statusCode == 200) {
      return data;
    }

    throw Exception(data['message'] ?? 'Ошибка оформления заказа');
  }

  static Future<List<Map<String, dynamic>>> getOrders() async {
    final http.Response response = await http.get(
      Uri.parse('$baseUrl/orders'),
      headers: await _headers(auth: true),
    );

    if (response.statusCode == 200) {
      return _decodeList(response);
    }

    throw Exception('Ошибка загрузки заказов: ${response.body}');
  }

  static Future<Map<String, dynamic>> getOrderById(int orderId) async {
    final http.Response response = await http.get(
      Uri.parse('$baseUrl/orders/$orderId'),
      headers: await _headers(auth: true),
    );

    final Map<String, dynamic> data = _decodeMap(response);

    if (response.statusCode == 200) {
      return data;
    }

    throw Exception(data['message'] ?? 'Ошибка загрузки заказа');
  }

  static Future<void> updateOrderStatus(int orderId, String status) async {
    final http.Response response = await http.put(
      Uri.parse('$baseUrl/orders/$orderId/status'),
      headers: await _headers(auth: true),
      body: jsonEncode({
        'status': status,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Ошибка обновления статуса заказа: ${response.body}');
    }
  }

  static Future<Map<String, dynamic>> createProduct({
    required String name,
    String? description,
    required double price,
    String? imageUrl,
    int? categoryId,
    bool inStock = true,
    List? care,
  }) async {
    final http.Response response = await http.post(
      Uri.parse('$baseUrl/products'),
      headers: await _headers(auth: true),
      body: jsonEncode({
        'name': name,
        'description': description ?? '',
        'price': price,
        'image_url': imageUrl ?? '',
        'category_id': categoryId,
        'in_stock': inStock,
        'care': care,
      }),
    );

    final Map<String, dynamic> data = _decodeMap(response);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return data;
    }

    throw Exception(data['message'] ?? 'Ошибка создания товара');
  }

  static Future<void> updateProduct({
    required int productId,
    String? name,
    String? description,
    double? price,
    String? imageUrl,
    int? categoryId,
    bool? inStock,
    List? care,
  }) async {
    final http.Response response = await http.put(
      Uri.parse('$baseUrl/products/$productId'),
      headers: await _headers(auth: true),
      body: jsonEncode({
        'name': name,
        'description': description,
        'price': price,
        'image_url': imageUrl,
        'category_id': categoryId,
        'in_stock': inStock,
        'care': care,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Ошибка обновления товара: ${response.body}');
    }
  }

  static Future<void> deleteProduct(int productId) async {
    final http.Response response = await http.delete(
      Uri.parse('$baseUrl/products/$productId'),
      headers: await _headers(auth: true),
    );

    if (response.statusCode != 200) {
      throw Exception('Ошибка удаления товара: ${response.body}');
    }
  }

  static Future<List<Map<String, dynamic>>> getPriceHistory(int productId) async {
    final http.Response response = await http.get(
      Uri.parse('$baseUrl/products/$productId/price-history'),
      headers: await _headers(),
    );

    if (response.statusCode == 200) {
      return _decodeList(response);
    }

    throw Exception('Ошибка загрузки истории цен: ${response.body}');
  }

  static Future<List<Map<String, dynamic>>> getAdminOrders() async {
    final http.Response response = await http.get(
      Uri.parse('$baseUrl/admin/orders'),
      headers: await _headers(auth: true),
    );

    if (response.statusCode == 200) {
      return _decodeList(response);
    }

    throw Exception('Ошибка загрузки заказов: ${response.body}');
  }

  static Future<void> updateAdminOrderStatus({
    required int orderId,
    required String status,
  }) async {
    final http.Response response = await http.put(
      Uri.parse('$baseUrl/admin/orders/$orderId/status'),
      headers: await _headers(auth: true),
      body: jsonEncode({
        'status': status,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Ошибка обновления статуса: ${response.body}');
    }
  }
}
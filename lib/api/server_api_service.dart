import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';
import 'auth_storage.dart';
import 'local_demo_service.dart';

class ServerApiService {
  static String get baseUrl => AppConfig.baseUrl;

  static final LocalDemoService _localDemoService = LocalDemoService.instance;
  static final _DemoDataStore _demo = _DemoDataStore();

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

  static Future<String> _token() async {
    return await AuthStorage.getToken() ?? '';
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    if (AppConfig.isDemoMode) {
      return _demo.login(email: email, password: password);
    }

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
    if (AppConfig.isDemoMode) {
      return _demo.register(
        name: name,
        email: email,
        password: password,
      );
    }

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
    if (AppConfig.isDemoMode) {
      return _demo.getProfile(await _token());
    }

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
    if (AppConfig.isDemoMode) {
      return _demo.updateProfile(
        token: await _token(),
        name: name,
        email: email,
        phone: phone,
      );
    }

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
      return data;
    }

    throw Exception(data['message'] ?? 'Ошибка при обновлении профиля');
  }

  static Future<void> logout() async {
    if (AppConfig.isDemoMode) {
      await AuthStorage.clear();
      return;
    }

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
    if (AppConfig.isDemoMode) {
      return _demo.getProducts();
    }

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
    if (AppConfig.isDemoMode) {
      return _localDemoService.getPopularProducts();
    }

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
    if (AppConfig.isDemoMode) {
      return _demo.getCategories();
    }

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
    if (AppConfig.isDemoMode) {
      return _localDemoService.getCart(await _token());
    }

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
    if (AppConfig.isDemoMode) {
      await _localDemoService.addToCart(
        await _token(),
        productId,
        quantity,
      );
      return;
    }

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
    if (AppConfig.isDemoMode) {
      await _localDemoService.updateCart(
        await _token(),
        productId,
        quantity,
      );
      return;
    }

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
    if (AppConfig.isDemoMode) {
      await _localDemoService.removeFromCart(
        await _token(),
        productId,
      );
      return;
    }

    final http.Response response = await http.delete(
      Uri.parse('$baseUrl/cart/$productId'),
      headers: await _headers(auth: true),
    );

    if (response.statusCode != 200) {
      throw Exception('Ошибка удаления из корзины: ${response.body}');
    }
  }

  static Future<void> clearCart() async {
    if (AppConfig.isDemoMode) {
      await _localDemoService.clearCart(await _token());
      return;
    }

    final http.Response response = await http.delete(
      Uri.parse('$baseUrl/cart'),
      headers: await _headers(auth: true),
    );

    if (response.statusCode != 200 && response.statusCode != 404) {
      throw Exception('Ошибка очистки корзины: ${response.body}');
    }
  }

  static Future<List<int>> getFavorites() async {
    if (AppConfig.isDemoMode) {
      return _demo.getFavorites(await _token());
    }

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
    if (AppConfig.isDemoMode) {
      await _demo.addFavorite(await _token(), productId);
      return;
    }

    final http.Response response = await http.post(
      Uri.parse('$baseUrl/favorites/$productId'),
      headers: await _headers(auth: true),
    );

    if (response.statusCode != 200) {
      throw Exception('Ошибка добавления в избранное: ${response.body}');
    }
  }

  static Future<void> removeFavorite(int productId) async {
    if (AppConfig.isDemoMode) {
      await _demo.removeFavorite(await _token(), productId);
      return;
    }

    final http.Response response = await http.delete(
      Uri.parse('$baseUrl/favorites/$productId'),
      headers: await _headers(auth: true),
    );

    if (response.statusCode != 200) {
      throw Exception('Ошибка удаления из избранного: ${response.body}');
    }
  }

  static Future<void> clearFavorites() async {
    if (AppConfig.isDemoMode) {
      await _demo.clearFavorites(await _token());
      return;
    }

    final http.Response response = await http.delete(
      Uri.parse('$baseUrl/favorites'),
      headers: await _headers(auth: true),
    );

    if (response.statusCode != 200) {
      throw Exception('Ошибка очистки избранного: ${response.body}');
    }
  }

  static Future<List<Map<String, dynamic>>> getAddresses() async {
    if (AppConfig.isDemoMode) {
      return _demo.getAddresses(await _token());
    }

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
    if (AppConfig.isDemoMode) {
      return _demo.createAddress(await _token(), body);
    }

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
    if (AppConfig.isDemoMode) {
      return _demo.updateAddress(await _token(), id, body);
    }

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
    if (AppConfig.isDemoMode) {
      await _demo.deleteAddress(await _token(), id);
      return;
    }

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
    if (AppConfig.isDemoMode) {
      return _localDemoService.createOrder(
        await _token(),
        itemsMaps,
        checkoutData,
      );
    }

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
    if (AppConfig.isDemoMode) {
      return _localDemoService.getOrdersRaw(await _token());
    }

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
    if (AppConfig.isDemoMode) {
      return _demo.getOrderById(await _token(), orderId);
    }

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
    if (AppConfig.isDemoMode) {
      await _localDemoService.updateOrderStatus(
        await _token(),
        orderId,
        status,
      );
      return;
    }

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
    List<String>? care,
  }) async {
    if (AppConfig.isDemoMode) {
      return _demo.createProduct(
        name: name,
        description: description,
        price: price,
        imageUrl: imageUrl,
        categoryId: categoryId,
        inStock: inStock,
        care: care,
      );
    }

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
        'care': care ?? <String>[],
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
    List<String>? care,
  }) async {
    if (AppConfig.isDemoMode) {
      await _demo.updateProduct(
        productId: productId,
        name: name,
        description: description,
        price: price,
        imageUrl: imageUrl,
        categoryId: categoryId,
        inStock: inStock,
        care: care,
      );
      return;
    }

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
    if (AppConfig.isDemoMode) {
      await _demo.deleteProduct(productId);
      return;
    }

    final http.Response response = await http.delete(
      Uri.parse('$baseUrl/products/$productId'),
      headers: await _headers(auth: true),
    );

    if (response.statusCode != 200) {
      throw Exception('Ошибка удаления товара: ${response.body}');
    }
  }

  static Future<List<Map<String, dynamic>>> getPriceHistory(
      int productId,
      ) async {
    if (AppConfig.isDemoMode) {
      return _demo.getPriceHistory(productId);
    }

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
    if (AppConfig.isDemoMode) {
      return _demo.getAdminOrders();
    }

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
    if (AppConfig.isDemoMode) {
      await _demo.updateAdminOrderStatus(
        orderId: orderId,
        status: status,
      );
      return;
    }

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

  static Future<Map<String, dynamic>> getAdminStats() async {
    if (AppConfig.isDemoMode) {
      return _demo.getAdminStats();
    }

    final http.Response response = await http.get(
      Uri.parse('$baseUrl/admin/stats'),
      headers: await _headers(auth: true),
    );

    final Map<String, dynamic> data = _decodeMap(response);

    if (response.statusCode == 200) {
      return data;
    }

    throw Exception(data['message'] ?? 'Ошибка загрузки статистики');
  }

  static Future<List<Map<String, dynamic>>> getAdminUsers() async {
    if (AppConfig.isDemoMode) {
      return _demo.getAdminUsers();
    }

    final http.Response response = await http.get(
      Uri.parse('$baseUrl/admin/users'),
      headers: await _headers(auth: true),
    );

    if (response.statusCode == 200) {
      return _decodeList(response);
    }

    throw Exception('Ошибка загрузки пользователей: ${response.body}');
  }

  static Future<List<Map<String, dynamic>>> getAdminRoles() async {
    if (AppConfig.isDemoMode) {
      return _demo.getAdminRoles();
    }

    final http.Response response = await http.get(
      Uri.parse('$baseUrl/admin/roles'),
      headers: await _headers(auth: true),
    );

    if (response.statusCode == 200) {
      return _decodeList(response);
    }

    throw Exception('Ошибка загрузки ролей: ${response.body}');
  }

  static Future<Map<String, dynamic>> updateAdminUserRole({
    required int userId,
    required int roleId,
  }) async {
    if (AppConfig.isDemoMode) {
      return _demo.updateAdminUserRole(
        userId: userId,
        roleId: roleId,
      );
    }

    final http.Response response = await http.put(
      Uri.parse('$baseUrl/admin/users/$userId/role'),
      headers: await _headers(auth: true),
      body: jsonEncode({
        'role_id': roleId,
      }),
    );

    final Map<String, dynamic> data = _decodeMap(response);

    if (response.statusCode == 200) {
      return data;
    }

    throw Exception(data['message'] ?? 'Ошибка изменения роли');
  }

  static Future<Map<String, dynamic>> getAdminUserOrders(int userId) async {
    if (AppConfig.isDemoMode) {
      return _demo.getAdminUserOrders(userId);
    }

    final http.Response response = await http.get(
      Uri.parse('$baseUrl/admin/users/$userId/orders'),
      headers: await _headers(auth: true),
    );

    final Map<String, dynamic> data = _decodeMap(response);

    if (response.statusCode == 200) {
      return data;
    }

    throw Exception(data['message'] ?? 'Ошибка загрузки заказов пользователя');
  }
}

class _DemoDataStore {
  static const String _usersKey = 'demo_users_v1';
  static const String _productsKey = 'demo_products_v1';
  static const String _ordersPrefix = 'demo_orders_user_';
  static const String _addressesPrefix = 'demo_addresses_user_';
  static const String _favoritesPrefix = 'demo_favorites_user_';
  static const String _priceHistoryKey = 'demo_price_history_v1';
  static const String _rolesKey = 'demo_roles_v1';
  static const String _categoriesKey = 'demo_categories_v1';

  final LocalDemoService _localDemoService = LocalDemoService.instance;

  Future<void> ensureReady() async {
    await _localDemoService.ensureSeeded();

    final SharedPreferences prefs = await SharedPreferences.getInstance();

    await _ensureRoles(prefs);
    await _ensureUsers(prefs);
    await _ensureCategories(prefs);
    await _ensureProducts(prefs);
    await _ensurePriceHistory(prefs);
    await _ensureAddresses(prefs);
    await _ensureOrders(prefs);
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    await ensureReady();

    final List<Map<String, dynamic>> users = await _getUsers();

    try {
      final Map<String, dynamic> user = users.firstWhere(
            (Map<String, dynamic> item) {
          return item['email'].toString().trim().toLowerCase() ==
              email.trim().toLowerCase() &&
              item['password'].toString() == password;
        },
      );

      return {
        'user': _publicUser(user),
        'token': _makeToken(_toInt(user['id'])),
      };
    } catch (_) {
      throw Exception('Неверный email или пароль');
    }
  }

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    await ensureReady();

    final List<Map<String, dynamic>> users = await _getUsers();

    final bool exists = users.any((Map<String, dynamic> item) {
      return item['email'].toString().trim().toLowerCase() ==
          email.trim().toLowerCase();
    });

    if (exists) {
      throw Exception('Пользователь с таким email уже существует');
    }

    final int newId = users.isEmpty
        ? 1
        : users
        .map((Map<String, dynamic> item) => _toInt(item['id']))
        .reduce((int a, int b) => a > b ? a : b) +
        1;

    final Map<String, dynamic> user = {
      'id': newId,
      'name': name.trim(),
      'email': email.trim(),
      'password': password,
      'phone': '',
      'address': '',
      'role_id': 1,
      'role': 'customer',
      'loyalty_points': 0,
      'total_spent': 0.0,
      'loyalty_level': 'Bronze',
      'loyalty_color': '#CD7F32',
    };

    users.add(user);

    await _saveUsers(users);

    return {
      'user': _publicUser(user),
      'token': _makeToken(newId),
    };
  }

  Future<Map<String, dynamic>> getProfile(String token) async {
    await ensureReady();

    final int? userId = _readUserIdFromToken(token);

    if (userId == null) {
      throw Exception('Сессия истекла. Войдите снова.');
    }

    final List<Map<String, dynamic>> users = await _getUsers();

    final Map<String, dynamic>? user = users
        .where((Map<String, dynamic> item) => _toInt(item['id']) == userId)
        .firstOrNull;

    if (user == null) {
      throw Exception('Пользователь не найден');
    }

    return _publicUser(user);
  }

  Future<Map<String, dynamic>> updateProfile({
    required String token,
    required String name,
    required String email,
    required String phone,
  }) async {
    await ensureReady();

    final int? userId = _readUserIdFromToken(token);

    if (userId == null) {
      throw Exception('Сессия истекла. Войдите снова.');
    }

    final List<Map<String, dynamic>> users = await _getUsers();

    final int index = users.indexWhere(
          (Map<String, dynamic> item) => _toInt(item['id']) == userId,
    );

    if (index == -1) {
      throw Exception('Пользователь не найден');
    }

    users[index] = {
      ...users[index],
      'name': name,
      'email': email,
      'phone': phone,
    };

    await _saveUsers(users);

    return _publicUser(users[index]);
  }

  Future<List<Map<String, dynamic>>> getProducts() async {
    await ensureReady();

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String raw = prefs.getString(_productsKey) ?? '[]';

    final List<Map<String, dynamic>> products = _decodeList(raw);
    final List<Map<String, dynamic>> history = await getAllPriceHistory();

    return products.map((Map<String, dynamic> product) {
      final int productId = _toInt(product['id']);

      return {
        ...product,
        'price_history': history
            .where((Map<String, dynamic> item) {
          return _toInt(item['product_id']) == productId;
        })
            .toList(),
      };
    }).toList();
  }

  Future<List<Map<String, dynamic>>> getCategories() async {
    await ensureReady();

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String raw = prefs.getString(_categoriesKey) ?? '[]';

    return _decodeList(raw);
  }

  Future<Map<String, dynamic>> createProduct({
    required String name,
    String? description,
    required double price,
    String? imageUrl,
    int? categoryId,
    bool inStock = true,
    List<String>? care,
  }) async {
    await ensureReady();

    final List<Map<String, dynamic>> products = await getProducts();
    final List<Map<String, dynamic>> categories = await getCategories();

    final int newId = products.isEmpty
        ? 1
        : products
        .map((Map<String, dynamic> item) => _toInt(item['id']))
        .reduce((int a, int b) => a > b ? a : b) +
        1;

    final Map<String, dynamic>? category = categories
        .where((Map<String, dynamic> item) => _toInt(item['id']) == categoryId)
        .firstOrNull;

    final Map<String, dynamic> product = {
      'id': newId,
      'name': name,
      'description': description ?? '',
      'price': price,
      'image_url': imageUrl?.isNotEmpty == true
          ? imageUrl
          : 'https://images.unsplash.com/photo-1519378058457-4c29a0a2efac',
      'category_id': categoryId ?? 3,
      'category_name': category?['name'] ?? 'Микс',
      'in_stock': inStock,
      'rating': 4.7,
      'review_count': 0,
      'care': care ?? <String>[],
    };

    products.add(product);

    await _saveProducts(products);

    await _addPriceHistory(
      productId: newId,
      oldPrice: price,
      newPrice: price,
    );

    return product;
  }

  Future<void> updateProduct({
    required int productId,
    String? name,
    String? description,
    double? price,
    String? imageUrl,
    int? categoryId,
    bool? inStock,
    List<String>? care,
  }) async {
    await ensureReady();

    final List<Map<String, dynamic>> products = await getProducts();
    final List<Map<String, dynamic>> categories = await getCategories();

    final int index = products.indexWhere(
          (Map<String, dynamic> item) => _toInt(item['id']) == productId,
    );

    if (index == -1) {
      throw Exception('Товар не найден');
    }

    final Map<String, dynamic> oldProduct = products[index];

    final double oldPrice = _toDouble(oldProduct['price']);
    final double? newPrice = price;

    final Map<String, dynamic>? category = categories
        .where((Map<String, dynamic> item) => _toInt(item['id']) == categoryId)
        .firstOrNull;

    products[index] = {
      ...oldProduct,
      'name': name ?? oldProduct['name'],
      'description': description ?? oldProduct['description'],
      'price': price ?? oldProduct['price'],
      'image_url': imageUrl ?? oldProduct['image_url'],
      'category_id': categoryId ?? oldProduct['category_id'],
      'category_name': category?['name'] ?? oldProduct['category_name'],
      'in_stock': inStock ?? oldProduct['in_stock'],
      'care': care ?? oldProduct['care'],
    };

    await _saveProducts(products);

    if (newPrice != null && newPrice != oldPrice) {
      await _addPriceHistory(
        productId: productId,
        oldPrice: oldPrice,
        newPrice: newPrice,
      );
    }
  }

  Future<void> deleteProduct(int productId) async {
    await ensureReady();

    final List<Map<String, dynamic>> products = await getProducts();

    products.removeWhere(
          (Map<String, dynamic> item) => _toInt(item['id']) == productId,
    );

    await _saveProducts(products);
  }

  Future<List<Map<String, dynamic>>> getPriceHistory(int productId) async {
    await ensureReady();

    final List<Map<String, dynamic>> history = await getAllPriceHistory();

    final List<Map<String, dynamic>> result = history
        .where((Map<String, dynamic> item) {
      return _toInt(item['product_id']) == productId;
    })
        .toList();

    result.sort((a, b) {
      return DateTime.parse(a['changed_at'].toString())
          .compareTo(DateTime.parse(b['changed_at'].toString()));
    });

    return result;
  }

  Future<List<Map<String, dynamic>>> getAllPriceHistory() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String raw = prefs.getString(_priceHistoryKey) ?? '[]';

    return _decodeList(raw);
  }

  Future<List<int>> getFavorites(String token) async {
    final int? userId = _readUserIdFromToken(token);

    if (userId == null) {
      return <int>[];
    }

    final SharedPreferences prefs = await SharedPreferences.getInstance();

    final List<String> raw =
        prefs.getStringList('$_favoritesPrefix$userId') ?? <String>[];

    return raw
        .map((String item) => int.tryParse(item) ?? 0)
        .where((int item) => item > 0)
        .toList();
  }

  Future<void> addFavorite(String token, int productId) async {
    final int? userId = _readUserIdFromToken(token);

    if (userId == null) {
      return;
    }

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String key = '$_favoritesPrefix$userId';
    final List<String> current = prefs.getStringList(key) ?? <String>[];

    final String id = productId.toString();

    if (!current.contains(id)) {
      current.add(id);
    }

    await prefs.setStringList(key, current);
  }

  Future<void> removeFavorite(String token, int productId) async {
    final int? userId = _readUserIdFromToken(token);

    if (userId == null) {
      return;
    }

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String key = '$_favoritesPrefix$userId';
    final List<String> current = prefs.getStringList(key) ?? <String>[];

    current.remove(productId.toString());

    await prefs.setStringList(key, current);
  }

  Future<void> clearFavorites(String token) async {
    final int? userId = _readUserIdFromToken(token);

    if (userId == null) {
      return;
    }

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_favoritesPrefix$userId');
  }

  Future<List<Map<String, dynamic>>> getAddresses(String token) async {
    await ensureReady();

    final int? userId = _readUserIdFromToken(token);

    if (userId == null) {
      return <Map<String, dynamic>>[];
    }

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String raw = prefs.getString('$_addressesPrefix$userId') ?? '[]';

    return _decodeList(raw);
  }

  Future<Map<String, dynamic>> createAddress(
      String token,
      Map<String, dynamic> body,
      ) async {
    final int? userId = _readUserIdFromToken(token);

    if (userId == null) {
      throw Exception('Сессия истекла');
    }

    final List<Map<String, dynamic>> addresses = await getAddresses(token);

    final int newId = addresses.isEmpty
        ? 1
        : addresses
        .map((Map<String, dynamic> item) => _toInt(item['id']))
        .reduce((int a, int b) => a > b ? a : b) +
        1;

    final bool makeDefault =
        body['is_default'] == true || body['isPrimary'] == true || addresses.isEmpty;

    final List<Map<String, dynamic>> updatedAddresses = addresses.map((item) {
      if (makeDefault) {
        return {
          ...item,
          'is_default': false,
        };
      }

      return item;
    }).toList();

    final Map<String, dynamic> address = {
      ...body,
      'id': newId,
      'user_id': userId,
      'is_default': makeDefault,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };

    updatedAddresses.add(address);

    await _saveAddresses(userId, updatedAddresses);

    return address;
  }

  Future<Map<String, dynamic>> updateAddress(
      String token,
      int id,
      Map<String, dynamic> body,
      ) async {
    final int? userId = _readUserIdFromToken(token);

    if (userId == null) {
      throw Exception('Сессия истекла');
    }

    final List<Map<String, dynamic>> addresses = await getAddresses(token);

    final int index = addresses.indexWhere(
          (Map<String, dynamic> item) => _toInt(item['id']) == id,
    );

    if (index == -1) {
      throw Exception('Адрес не найден');
    }

    final bool makeDefault =
        body['is_default'] == true || body['isPrimary'] == true;

    final List<Map<String, dynamic>> updated = addresses.map((item) {
      if (makeDefault) {
        return {
          ...item,
          'is_default': false,
        };
      }

      return item;
    }).toList();

    updated[index] = {
      ...updated[index],
      ...body,
      'id': id,
      'user_id': userId,
      'is_default': makeDefault ? true : updated[index]['is_default'],
      'updated_at': DateTime.now().toIso8601String(),
    };

    await _saveAddresses(userId, updated);

    return updated[index];
  }

  Future<void> deleteAddress(String token, int id) async {
    final int? userId = _readUserIdFromToken(token);

    if (userId == null) {
      return;
    }

    final List<Map<String, dynamic>> addresses = await getAddresses(token);

    final bool removedWasDefault = addresses.any((item) {
      return _toInt(item['id']) == id && item['is_default'] == true;
    });

    addresses.removeWhere(
          (Map<String, dynamic> item) => _toInt(item['id']) == id,
    );

    if (removedWasDefault && addresses.isNotEmpty) {
      addresses[0] = {
        ...addresses[0],
        'is_default': true,
      };
    }

    await _saveAddresses(userId, addresses);
  }

  Future<Map<String, dynamic>> getOrderById(String token, int orderId) async {
    final List<Map<String, dynamic>> orders =
    await _localDemoService.getOrdersRaw(token);

    final Map<String, dynamic>? order = orders
        .where((Map<String, dynamic> item) => _toInt(item['id']) == orderId)
        .firstOrNull;

    if (order == null) {
      throw Exception('Заказ не найден');
    }

    return order;
  }

  Future<List<Map<String, dynamic>>> getAdminOrders() async {
    await ensureReady();

    final List<Map<String, dynamic>> users = await _getUsers();
    final List<Map<String, dynamic>> result = <Map<String, dynamic>>[];

    for (final Map<String, dynamic> user in users) {
      final int userId = _toInt(user['id']);

      final List<Map<String, dynamic>> orders =
      await _getOrdersForUserId(userId);

      for (final Map<String, dynamic> order in orders) {
        result.add({
          ...order,
          'customer_name': user['name'],
          'customer_phone': user['phone'],
          'customer_email': user['email'],
        });
      }
    }

    result.sort((a, b) {
      return DateTime.parse(b['created_at'].toString())
          .compareTo(DateTime.parse(a['created_at'].toString()));
    });

    return result;
  }

  Future<void> updateAdminOrderStatus({
    required int orderId,
    required String status,
  }) async {
    await ensureReady();

    final List<Map<String, dynamic>> users = await _getUsers();

    for (final Map<String, dynamic> user in users) {
      final int userId = _toInt(user['id']);
      final List<Map<String, dynamic>> orders =
      await _getOrdersForUserId(userId);

      final int index = orders.indexWhere(
            (Map<String, dynamic> item) => _toInt(item['id']) == orderId,
      );

      if (index != -1) {
        orders[index] = {
          ...orders[index],
          'status': status,
        };

        await _saveOrders(userId, orders);
        return;
      }
    }

    throw Exception('Заказ не найден');
  }

  Future<Map<String, dynamic>> getAdminStats() async {
    await ensureReady();

    final List<Map<String, dynamic>> users = await _getUsers();
    final List<Map<String, dynamic>> products = await getProducts();
    final List<Map<String, dynamic>> orders = await getAdminOrders();

    final double revenue = orders.fold<double>(0, (double sum, order) {
      return sum + _toDouble(order['total']);
    });

    return {
      'products_count': products.length,
      'orders_count': orders.length,
      'customers_count': users.length,
      'revenue': revenue,
    };
  }

  Future<List<Map<String, dynamic>>> getAdminUsers() async {
    await ensureReady();

    final List<Map<String, dynamic>> users = await _getUsers();
    final List<Map<String, dynamic>> result = <Map<String, dynamic>>[];

    for (final Map<String, dynamic> user in users) {
      final int userId = _toInt(user['id']);
      final List<Map<String, dynamic>> orders =
      await _getOrdersForUserId(userId);

      final double total = orders.fold<double>(0, (double sum, order) {
        return sum + _toDouble(order['total']);
      });

      String? lastOrderAt;

      if (orders.isNotEmpty) {
        orders.sort((a, b) {
          return DateTime.parse(b['created_at'].toString())
              .compareTo(DateTime.parse(a['created_at'].toString()));
        });

        lastOrderAt = orders.first['created_at']?.toString();
      }

      result.add({
        ..._publicUser(user),
        'role_id': _toInt(user['role_id']),
        'orders_count': orders.length,
        'orders_total': total,
        'last_order_at': lastOrderAt,
      });
    }

    return result;
  }

  Future<List<Map<String, dynamic>>> getAdminRoles() async {
    await ensureReady();

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String raw = prefs.getString(_rolesKey) ?? '[]';

    return _decodeList(raw);
  }

  Future<Map<String, dynamic>> updateAdminUserRole({
    required int userId,
    required int roleId,
  }) async {
    await ensureReady();

    final List<Map<String, dynamic>> users = await _getUsers();
    final List<Map<String, dynamic>> roles = await getAdminRoles();

    final int index = users.indexWhere(
          (Map<String, dynamic> item) => _toInt(item['id']) == userId,
    );

    if (index == -1) {
      throw Exception('Пользователь не найден');
    }

    final Map<String, dynamic>? role = roles
        .where((Map<String, dynamic> item) => _toInt(item['id']) == roleId)
        .firstOrNull;

    if (role == null) {
      throw Exception('Роль не найдена');
    }

    users[index] = {
      ...users[index],
      'role_id': roleId,
      'role': role['name'],
    };

    await _saveUsers(users);

    return _publicUser(users[index]);
  }

  Future<Map<String, dynamic>> getAdminUserOrders(int userId) async {
    await ensureReady();

    final List<Map<String, dynamic>> users = await _getUsers();

    final Map<String, dynamic>? user = users
        .where((Map<String, dynamic> item) => _toInt(item['id']) == userId)
        .firstOrNull;

    if (user == null) {
      throw Exception('Пользователь не найден');
    }

    final List<Map<String, dynamic>> orders = await _getOrdersForUserId(userId);

    return {
      'user': _publicUser(user),
      'orders': orders,
    };
  }

  Future<void> _ensureRoles(SharedPreferences prefs) async {
    final String? raw = prefs.getString(_rolesKey);

    if (raw != null && raw.isNotEmpty) {
      return;
    }

    final List<Map<String, dynamic>> roles = [
      {
        'id': 1,
        'name': 'customer',
      },
      {
        'id': 2,
        'name': 'admin',
      },
      {
        'id': 3,
        'name': 'courier',
      },
    ];

    await prefs.setString(_rolesKey, jsonEncode(roles));
  }

  Future<void> _ensureUsers(SharedPreferences prefs) async {
    final List<Map<String, dynamic>> users = await _getUsers();

    bool changed = false;

    for (int i = 0; i < users.length; i++) {
      final int roleId = _toInt(users[i]['role_id']);

      if (users[i]['role'] == null) {
        users[i] = {
          ...users[i],
          'role_id': roleId == 0 ? 1 : roleId,
          'role': _roleById(roleId == 0 ? 1 : roleId),
        };

        changed = true;
      }
    }

    if (!users.any((item) => item['email'] == 'admin@flowershop.ru')) {
      users.add({
        'id': _nextId(users),
        'name': 'Администратор',
        'email': 'admin@flowershop.ru',
        'password': 'admin123',
        'phone': '+7 (999) 000-11-22',
        'address': '',
        'role_id': 2,
        'role': 'admin',
        'loyalty_points': 0,
        'total_spent': 0.0,
        'loyalty_level': 'Gold',
        'loyalty_color': '#E0B94A',
      });

      changed = true;
    }

    if (!users.any((item) => item['email'] == 'courier@flowershop.ru')) {
      users.add({
        'id': _nextId(users),
        'name': 'Курьер',
        'email': 'courier@flowershop.ru',
        'password': '123456',
        'phone': '+7 (999) 333-44-55',
        'address': '',
        'role_id': 3,
        'role': 'courier',
        'loyalty_points': 0,
        'total_spent': 0.0,
        'loyalty_level': 'Bronze',
        'loyalty_color': '#CD7F32',
      });

      changed = true;
    }

    if (changed) {
      await _saveUsers(users);
    }
  }

  Future<void> _ensureCategories(SharedPreferences prefs) async {
    final String? raw = prefs.getString(_categoriesKey);

    if (raw != null && raw.isNotEmpty) {
      return;
    }

    final List<Map<String, dynamic>> categories = [
      {
        'id': 1,
        'name': 'Розы',
      },
      {
        'id': 2,
        'name': 'Пионы',
      },
      {
        'id': 3,
        'name': 'Микс',
      },
      {
        'id': 4,
        'name': 'Минимализм',
      },
      {
        'id': 5,
        'name': 'Гортензии',
      },
      {
        'id': 6,
        'name': 'Герберы',
      },
      {
        'id': 7,
        'name': 'Подарочные',
      },
    ];

    await prefs.setString(_categoriesKey, jsonEncode(categories));
  }

  Future<void> _ensureProducts(SharedPreferences prefs) async {
    final String raw = prefs.getString(_productsKey) ?? '[]';
    final List<Map<String, dynamic>> products = _decodeList(raw);

    bool changed = false;

    for (int i = 0; i < products.length; i++) {
      if (products[i]['review_count'] == null) {
        products[i]['review_count'] = 12 + i;
        changed = true;
      }

      if (products[i]['care'] == null) {
        products[i]['care'] = [
          'Менять воду каждый день',
          'Держать вдали от прямого солнца',
          'Подрезать стебли под углом',
        ];
        changed = true;
      }
    }

    if (products.isEmpty) {
      products.addAll([
        {
          'id': 11,
          'name': 'Авторский букет',
          'description': 'Композиция от флориста в нежной палитре.',
          'price': 4300.0,
          'image_url':
          'https://images.unsplash.com/photo-1487070183336-b863922373d4',
          'category_id': 3,
          'category_name': 'Микс',
          'rating': 4.9,
          'review_count': 18,
          'in_stock': true,
          'care': [
            'Менять воду ежедневно',
            'Не ставить рядом с батареей',
            'Подрезать стебли',
          ],
        },
        {
          'id': 12,
          'name': 'Нежная коробка',
          'description': 'Цветочная композиция в подарочной коробке.',
          'price': 3900.0,
          'image_url':
          'https://images.unsplash.com/photo-1563241527-3004b7be0ffd',
          'category_id': 7,
          'category_name': 'Подарочные',
          'rating': 4.8,
          'review_count': 21,
          'in_stock': true,
          'care': [
            'Не переливать губку',
            'Хранить в прохладном месте',
            'Беречь от сквозняка',
          ],
        },
      ]);

      changed = true;
    }

    if (changed) {
      await prefs.setString(_productsKey, jsonEncode(products));
    }
  }

  Future<void> _ensurePriceHistory(SharedPreferences prefs) async {
    final String? raw = prefs.getString(_priceHistoryKey);

    if (raw != null && raw.isNotEmpty) {
      return;
    }

    final DateTime now = DateTime.now();

    final List<Map<String, dynamic>> history = [
      _historyItem(1, 1600, 1700, now.subtract(const Duration(days: 30))),
      _historyItem(1, 1700, 1800, now.subtract(const Duration(days: 12))),
      _historyItem(2, 2800, 3000, now.subtract(const Duration(days: 34))),
      _historyItem(2, 3000, 3200, now.subtract(const Duration(days: 8))),
      _historyItem(3, 2500, 2700, now.subtract(const Duration(days: 20))),
      _historyItem(4, 2200, 2400, now.subtract(const Duration(days: 18))),
      _historyItem(5, 4700, 5100, now.subtract(const Duration(days: 16))),
      _historyItem(6, 2700, 2900, now.subtract(const Duration(days: 14))),
      _historyItem(7, 1900, 2100, now.subtract(const Duration(days: 10))),
      _historyItem(8, 2500, 2600, now.subtract(const Duration(days: 9))),
      _historyItem(9, 3200, 3500, now.subtract(const Duration(days: 7))),
      _historyItem(10, 1800, 1900, now.subtract(const Duration(days: 5))),
      _historyItem(11, 4100, 4300, now.subtract(const Duration(days: 4))),
      _historyItem(12, 3600, 3900, now.subtract(const Duration(days: 3))),
    ];

    await prefs.setString(_priceHistoryKey, jsonEncode(history));
  }

  Future<void> _ensureAddresses(SharedPreferences prefs) async {
    final int userId = 1;
    final String key = '$_addressesPrefix$userId';

    final String? raw = prefs.getString(key);

    if (raw != null && raw.isNotEmpty) {
      return;
    }

    final List<Map<String, dynamic>> addresses = [
      {
        'id': 1,
        'user_id': userId,
        'title': 'Дом',
        'recipient_name': 'Демо Пользователь',
        'phone': '+7 (999) 123-45-67',
        'city': 'Астана',
        'street': 'Цветочная',
        'house': '12',
        'apartment': '45',
        'entrance': '2',
        'floor': '5',
        'comment': 'Позвонить за 10 минут',
        'is_default': true,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
    ];

    await prefs.setString(key, jsonEncode(addresses));
  }

  Future<void> _ensureOrders(SharedPreferences prefs) async {
    final int userId = 1;
    final String key = '$_ordersPrefix$userId';

    final String? raw = prefs.getString(key);

    if (raw != null && raw.isNotEmpty && raw != '[]') {
      return;
    }

    final DateTime now = DateTime.now();

    final List<Map<String, dynamic>> orders = [
      {
        'id': 101,
        'user_id': userId,
        'total': 5700.0,
        'items_total': 5400.0,
        'delivery_cost': 300.0,
        'bonus_applied': 0,
        'bonus_earned': 285,
        'payment_method': 'Система быстрых платежей',
        'payment_status': 'Оплачено',
        'card_mask': '',
        'delivery_method': 'delivery',
        'delivery_address': 'г. Астана, ул. Цветочная, 12, кв. 45',
        'recipient_comment': 'Позвонить за 10 минут',
        'promo_code': '',
        'status': 'Собирается',
        'created_at': now.subtract(const Duration(days: 1)).toIso8601String(),
        'items': [
          {
            'product_id': 1,
            'quantity': 1,
            'price': 1800.0,
            'name': 'Розовый рассвет',
            'image_url':
            'https://images.unsplash.com/photo-1519378058457-4c29a0a2efac',
          },
          {
            'product_id': 6,
            'quantity': 1,
            'price': 2900.0,
            'name': 'Гортензия pastel',
            'image_url':
            'https://images.unsplash.com/photo-1525310072745-f49212b5ac6d',
          },
          {
            'product_id': 10,
            'quantity': 1,
            'price': 700.0,
            'name': 'Открытка',
            'image_url':
            'https://images.unsplash.com/photo-1525310072745-f49212b5ac6d',
          },
        ],
      },
      {
        'id': 102,
        'user_id': userId,
        'total': 3200.0,
        'items_total': 3200.0,
        'delivery_cost': 0.0,
        'bonus_applied': 200,
        'bonus_earned': 150,
        'payment_method': 'Наличный расчёт',
        'payment_status': 'Ожидает оплаты',
        'card_mask': '',
        'delivery_method': 'pickup',
        'delivery_address': 'Самовывоз',
        'recipient_comment': '',
        'promo_code': '',
        'status': 'Принят',
        'created_at': now.subtract(const Duration(days: 3)).toIso8601String(),
        'items': [
          {
            'product_id': 2,
            'quantity': 1,
            'price': 3200.0,
            'name': 'Пионы мечты',
            'image_url':
            'https://images.unsplash.com/photo-1527061011665-3652c757a4d4',
          },
        ],
      },
    ];

    await prefs.setString(key, jsonEncode(orders));
  }

  Map<String, dynamic> _historyItem(
      int productId,
      double oldPrice,
      double newPrice,
      DateTime changedAt,
      ) {
    return {
      'id': '${productId}_${changedAt.millisecondsSinceEpoch}',
      'product_id': productId,
      'old_price': oldPrice,
      'new_price': newPrice,
      'price': newPrice,
      'changed_at': changedAt.toIso8601String(),
      'changed_by': 2,
    };
  }

  Future<void> _addPriceHistory({
    required int productId,
    required double oldPrice,
    required double newPrice,
  }) async {
    final List<Map<String, dynamic>> history = await getAllPriceHistory();

    history.add(
      _historyItem(
        productId,
        oldPrice,
        newPrice,
        DateTime.now(),
      ),
    );

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_priceHistoryKey, jsonEncode(history));
  }

  Future<List<Map<String, dynamic>>> _getUsers() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String raw = prefs.getString(_usersKey) ?? '[]';

    return _decodeList(raw);
  }

  Future<void> _saveUsers(List<Map<String, dynamic>> users) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_usersKey, jsonEncode(users));
  }

  Future<void> _saveProducts(List<Map<String, dynamic>> products) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_productsKey, jsonEncode(products));
  }

  Future<List<Map<String, dynamic>>> _getOrdersForUserId(int userId) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String raw = prefs.getString('$_ordersPrefix$userId') ?? '[]';

    return _decodeList(raw);
  }

  Future<void> _saveOrders(
      int userId,
      List<Map<String, dynamic>> orders,
      ) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_ordersPrefix$userId', jsonEncode(orders));
  }

  Future<void> _saveAddresses(
      int userId,
      List<Map<String, dynamic>> addresses,
      ) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_addressesPrefix$userId', jsonEncode(addresses));
  }

  Map<String, dynamic> _publicUser(Map<String, dynamic> user) {
    final int roleId = _toInt(user['role_id']);

    return {
      'id': user['id'],
      'name': user['name'],
      'email': user['email'],
      'phone': user['phone'],
      'address': user['address'],
      'role_id': roleId,
      'role': user['role'] ?? _roleById(roleId),
      'loyalty_points': user['loyalty_points'],
      'total_spent': user['total_spent'],
      'loyalty_level': user['loyalty_level'],
      'loyalty_color': user['loyalty_color'],
    };
  }

  String _roleById(int roleId) {
    switch (roleId) {
      case 2:
        return 'admin';
      case 3:
        return 'courier';
      case 1:
      default:
        return 'customer';
    }
  }

  int _nextId(List<Map<String, dynamic>> items) {
    if (items.isEmpty) {
      return 1;
    }

    return items
        .map((Map<String, dynamic> item) => _toInt(item['id']))
        .reduce((int a, int b) => a > b ? a : b) +
        1;
  }

  int? _readUserIdFromToken(String token) {
    if (!token.startsWith('demo-token-')) {
      return null;
    }

    final String part = token.replaceFirst('demo-token-', '').trim();
    return int.tryParse(part);
  }

  String _makeToken(int userId) {
    return 'demo-token-$userId';
  }

  List<Map<String, dynamic>> _decodeList(String raw) {
    final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;

    return decoded
        .map((dynamic item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  int _toInt(dynamic value) {
    if (value == null) {
      return 0;
    }

    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value.toString()) ?? 0;
  }

  double _toDouble(dynamic value) {
    if (value == null) {
      return 0.0;
    }

    if (value is double) {
      return value;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString().replaceAll(',', '.')) ?? 0.0;
  }
}
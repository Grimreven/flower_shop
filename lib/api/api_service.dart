import '../config/app_config.dart';
import '../models/product.dart';
import '../models/user.dart';
import 'local_demo_service.dart';
import 'server_api_service.dart';

class ApiService {
  static final LocalDemoService _localDemoService = LocalDemoService.instance;

  static Future<List<Product>> fetchAllProducts() async {
    final List<dynamic> data = AppConfig.useBackend
        ? await ServerApiService.getProducts()
        : await _localDemoService.getProducts();

    return data
        .map((dynamic item) => Product.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  static Future<List<Product>> fetchPopularProducts() async {
    final List<dynamic> data = AppConfig.useBackend
        ? await ServerApiService.getPopularProducts()
        : await _localDemoService.getPopularProducts();

    return data
        .map((dynamic item) => Product.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  static Future<User?> getProfile(String token) async {
    final Map<String, dynamic>? data = await _localDemoService.getProfile(token);

    if (data == null || data['authError'] == true) {
      return null;
    }

    return User.fromJson(data);
  }

  static Future<User?> updateProfile(String token, User user) async {
    final Map<String, dynamic>? data = await _localDemoService.updateProfile(
      token,
      user.toJson(),
    );

    if (data == null || data['authError'] == true) {
      return null;
    }

    return User.fromJson(data);
  }

  static Future<List<Map<String, dynamic>>> getCart(String token) async {
    return _localDemoService.getCart(token);
  }

  static Future<void> addToCart(
      int productId,
      int quantity,
      String token,
      ) async {
    await _localDemoService.addToCart(token, productId, quantity);
  }

  static Future<void> updateCart(
      int productId,
      int quantity,
      String token,
      ) async {
    await _localDemoService.updateCart(token, productId, quantity);
  }

  static Future<void> removeFromCart(
      int productId,
      String token,
      ) async {
    await _localDemoService.removeFromCart(token, productId);
  }

  static Future<void> clearCart(String token) async {
    await _localDemoService.clearCart(token);
  }
}
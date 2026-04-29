import '../config/app_config.dart';
import '../controllers/auth_controller.dart';
import '../models/product.dart';
import 'local_demo_service.dart';
import 'server_api_service.dart';

class CartService {
  final AuthController authController;
  final LocalDemoService _localDemoService = LocalDemoService.instance;

  CartService({required this.authController});

  String get _token => authController.token.value;

  Future<List<CartItemModel>> fetchCart() async {
    final List<Map<String, dynamic>> data = AppConfig.useBackend
        ? await ServerApiService.getCart()
        : await _localDemoService.getCart(_token);

    return data.map((Map<String, dynamic> e) => CartItemModel.fromJson(e)).toList();
  }

  Future<void> addToCart(int productId, int quantity) async {
    if (AppConfig.useBackend) {
      await ServerApiService.addToCart(productId, quantity);
      return;
    }

    await _localDemoService.addToCart(_token, productId, quantity);
  }

  Future<void> updateQuantity(int productId, int quantity) async {
    if (AppConfig.useBackend) {
      await ServerApiService.updateCart(productId, quantity);
      return;
    }

    await _localDemoService.updateCart(_token, productId, quantity);
  }

  Future<void> removeItem(int productId) async {
    if (AppConfig.useBackend) {
      await ServerApiService.removeFromCart(productId);
      return;
    }

    await _localDemoService.removeFromCart(_token, productId);
  }

  Future<void> clearCart() async {
    if (AppConfig.useBackend) {
      await ServerApiService.clearCart();
      return;
    }

    await _localDemoService.clearCart(_token);
  }
}

class CartItemModel {
  final int id;
  final Product product;
  final int quantity;

  CartItemModel({
    required this.id,
    required this.product,
    required this.quantity,
  });

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    return CartItemModel(
      id: _parseInt(json['id']),
      quantity: _parseInt(json['quantity']),
      product: Product.fromJson({
        'id': json['product_id'] ?? json['id'],
        'name': json['name'],
        'description': json['description'],
        'price': json['price'],
        'image_url': json['image_url'],
        'category_id': json['category_id'],
        'category_name': json['category_name'],
        'in_stock': json['in_stock'],
        'rating': json['rating'],
        'review_count': json['review_count'],
        'care': json['care'],
      }),
    );
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }
}
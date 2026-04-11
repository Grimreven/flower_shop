import '../controllers/auth_controller.dart';
import '../models/product.dart';
import 'local_demo_service.dart';

class CartService {
  final AuthController authController;
  final LocalDemoService _localDemoService = LocalDemoService.instance;

  CartService({required this.authController});

  String get _token => authController.token.value;

  Future<List<CartItemModel>> fetchCart() async {
    final List<Map<String, dynamic>> data = await _localDemoService.getCart(_token);

    return data
        .map((e) => CartItemModel.fromJson(e))
        .toList();
  }

  Future<void> addToCart(int productId, int quantity) async {
    await _localDemoService.addToCart(_token, productId, quantity);
  }

  Future<void> updateQuantity(int productId, int quantity) async {
    await _localDemoService.updateCart(_token, productId, quantity);
  }

  Future<void> removeItem(int productId) async {
    await _localDemoService.removeFromCart(_token, productId);
  }

  Future<void> clearCart() async {
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
    double parseDouble(dynamic v) {
      if (v == null) return 0.0;
      if (v is num) return v.toDouble();
      if (v is String) {
        final cleaned = v.replaceAll(',', '.');
        return double.tryParse(cleaned) ?? 0.0;
      }
      return 0.0;
    }

    int parseInt(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    final product = Product(
      id: parseInt(json['product_id'] ?? json['id']),
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      price: parseDouble(json['price']),
      imageUrl: json['image_url']?.toString() ?? '',
      categoryId: parseInt(json['category_id']),
      categoryName: json['category_name']?.toString() ?? '',
      inStock: json['in_stock'] == null
          ? true
          : (json['in_stock'] == true || json['in_stock'] == 1),
      rating: parseDouble(json['rating']),
      care: (json['care'] is List) ? List<String>.from(json['care']) : null,
    );

    return CartItemModel(
      id: parseInt(json['id']),
      quantity: parseInt(json['quantity']),
      product: product,
    );
  }
}
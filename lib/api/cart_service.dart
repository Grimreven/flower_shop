import 'dart:convert';
import 'package:http/http.dart' as http;
import '../controllers/auth_controller.dart';
import '../models/product.dart';

class CartService {
  final AuthController authController;
  final String baseUrl = 'http://10.0.2.2:3000'; // 👈 порт backend-а

  CartService({required this.authController});

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer ${authController.token.value}',
  };

  Future<List<CartItemModel>> fetchCart() async {
    final response = await http.get(Uri.parse('$baseUrl/cart'), headers: _headers);
    if (response.statusCode != 200) {
      throw Exception('Ошибка загрузки корзины: ${response.body}');
    }
    final data = jsonDecode(response.body) as List;
    return data.map((e) => CartItemModel.fromJson(e)).toList();
  }

  Future<void> addToCart(int productId, int quantity) async {
    final response = await http.post(Uri.parse('$baseUrl/cart'),
        headers: _headers,
        body: jsonEncode({'product_id': productId, 'quantity': quantity}));
    if (response.statusCode != 200) {
      throw Exception('Ошибка добавления: ${response.body}');
    }
  }

  Future<void> updateQuantity(int productId, int quantity) async {
    final response = await http.put(Uri.parse('$baseUrl/cart/$productId'),
        headers: _headers, body: jsonEncode({'quantity': quantity}));
    if (response.statusCode != 200) {
      throw Exception('Ошибка обновления: ${response.body}');
    }
  }

  Future<void> removeItem(int productId) async {
    final response =
    await http.delete(Uri.parse('$baseUrl/cart/$productId'), headers: _headers);
    if (response.statusCode != 200) {
      throw Exception('Ошибка удаления: ${response.body}');
    }
  }

  Future<void> clearCart() async {
    final response =
    await http.delete(Uri.parse('$baseUrl/cart'), headers: _headers);
    if (response.statusCode != 200) {
      throw Exception('Ошибка очистки корзины: ${response.body}');
    }
  }
}

class CartItemModel {
  final int id;
  final Product product;
  final int quantity;

  CartItemModel({required this.id, required this.product, required this.quantity});

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    return CartItemModel(
      id: json['id'],
      quantity: json['quantity'],
      product: Product(
        id: json['product_id'],
        name: json['name'],
        description: json['description'] ?? '',
        price: (json['price'] as num).toDouble(),
        imageUrl: json['image_url'] ?? '',
        categoryId: json['category_id'] ?? 0,
        categoryName: json['category_name'] ?? '',
        inStock: json['in_stock'] ?? true,
        rating:
        json['rating'] != null ? (json['rating'] as num).toDouble() : 0.0,
      ),
    );
  }
}

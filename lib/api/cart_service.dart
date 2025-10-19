import 'dart:convert';
import 'package:http/http.dart' as http;
import '../controllers/auth_controller.dart';
import '../models/product.dart';

class CartService {
  final AuthController authController;
  final String baseUrl = 'http://10.0.2.2:3000'; // для эмулятора Android

  CartService({required this.authController});

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer ${authController.token.value}',
  };

  Future<List<CartItemModel>> fetchCart() async {
    final response = await http.get(Uri.parse('$baseUrl/cart'), headers: _headers);
    if (response.statusCode != 200) {
      throw Exception('Ошибка загрузки корзины: ${response.statusCode} ${response.body}');
    }
    final data = jsonDecode(response.body) as List;
    return data.map((e) => CartItemModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> addToCart(int productId, int quantity) async {
    final response = await http.post(Uri.parse('$baseUrl/cart'),
        headers: _headers, body: jsonEncode({'product_id': productId, 'quantity': quantity}));
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Ошибка добавления: ${response.statusCode} ${response.body}');
    }
  }

  Future<void> updateQuantity(int productId, int quantity) async {
    final response = await http.put(Uri.parse('$baseUrl/cart/$productId'),
        headers: _headers, body: jsonEncode({'quantity': quantity}));
    if (response.statusCode != 200) {
      throw Exception('Ошибка обновления: ${response.statusCode} ${response.body}');
    }
  }

  Future<void> removeItem(int productId) async {
    final response = await http.delete(Uri.parse('$baseUrl/cart/$productId'), headers: _headers);
    if (response.statusCode != 200) {
      throw Exception('Ошибка удаления: ${response.statusCode} ${response.body}');
    }
  }

  Future<void> clearCart() async {
    final response = await http.delete(Uri.parse('$baseUrl/cart'), headers: _headers);
    if (response.statusCode != 200) {
      throw Exception('Ошибка очистки корзины: ${response.statusCode} ${response.body}');
    }
  }
}

class CartItemModel {
  final int id;
  final Product product;
  final int quantity;

  CartItemModel({required this.id, required this.product, required this.quantity});

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    // robust parsing for numbers that sometimes come as strings
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
      id: json['product_id'] ?? json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: parseDouble(json['price']),
      imageUrl: json['image_url'] ?? '',
      categoryId: json['category_id'] ?? 0,
      categoryName: json['category_name'] ?? '',
      inStock: json['in_stock'] == null ? true : (json['in_stock'] == true || json['in_stock'] == 1),
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

// lib/api/order_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/cart_item.dart';
import '../models/order_model.dart';

class OrderService {
  final String baseUrl = 'http://10.0.2.2:3000';
  final String token;

  OrderService({required this.token});

  /// itemsMaps — список картинок { 'product_id': ..., 'quantity': ... }
  Future<void> createOrder({required List<Map<String, dynamic>> itemsMaps}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/orders'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'items': itemsMaps}),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Ошибка создания заказа: ${response.statusCode} ${response.body}');
    }
  }

  Future<List<OrderModel>> getUserOrders() async {
    final response = await http.get(
      Uri.parse('$baseUrl/orders'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Ошибка получения заказов: ${response.statusCode} ${response.body}');
    }

    final data = jsonDecode(response.body) as List<dynamic>? ?? [];
    return data.map((e) {
      final m = (e is Map<String, dynamic>) ? e : Map<String, dynamic>.from(e);
      return OrderModel.fromJson(m);
    }).toList();
  }
}

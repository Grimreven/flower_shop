import 'package:get/get.dart';
import '../models/cart_item.dart' as model;
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../controllers/auth_controller.dart';

class OrderService {
  final String baseUrl = 'http://10.0.2.2:3000';

  Future<void> createOrder({
    required int userId,
    required double total,
    required List<model.CartItem> items,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/orders'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': userId,
        'total': total,
        'items': items.map((e) => e.toJson()).toList(),
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Ошибка создания заказа: ${response.body}');
    }
  }

  Future<List<Map<String, dynamic>>> getUserOrders(int userId) async {
    final response = await http.get(Uri.parse('$baseUrl/orders/user/$userId'));

    if (response.statusCode != 200) {
      throw Exception('Ошибка получения заказов: ${response.body}');
    }

    final data = jsonDecode(response.body) as List<dynamic>;
    return data.cast<Map<String, dynamic>>();
  }
}

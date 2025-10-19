import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/cart_item.dart';

class OrderService {
  final String baseUrl = 'http://10.0.2.2:3000';
  final String token;

  OrderService({required this.token});

  Future<void> createOrder({required List<CartItem> items}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/orders'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'items': items.map((e) => e.toJson()).toList(),
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Ошибка создания заказа: ${response.body}');
    }
  }

  Future<List<Map<String, dynamic>>> getUserOrders() async {
    final response = await http.get(
      Uri.parse('$baseUrl/orders'), // убираем /user/$userId
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Ошибка получения заказов: ${response.body}');
    }

    final data = jsonDecode(response.body) as List<dynamic>;
    return data.cast<Map<String, dynamic>>();
  }

}

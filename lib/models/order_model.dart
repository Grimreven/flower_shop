import 'cart_item.dart';

class OrderModel {
  final int id;
  final double total;
  final String status;
  final DateTime createdAt;
  final List<CartItem> items;

  OrderModel({
    required this.id,
    required this.total,
    required this.status,
    required this.createdAt,
    required this.items,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final itemsJson = (json['items'] as List<dynamic>? ?? []);
    return OrderModel(
      id: json['id'],
      total: (json['total'] ?? 0).toDouble(),
      status: json['status'] ?? '',
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      items: itemsJson.map((e) => CartItem.fromJson(e)).toList(),
    );
  }
}

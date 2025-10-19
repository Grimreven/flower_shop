// lib/models/order_model.dart
import 'order_item.dart';

class OrderModel {
  final int id;
  final double total;
  final String status;
  final List<OrderItem> items;
  final String createdAt;

  OrderModel({
    required this.id,
    required this.total,
    required this.status,
    required this.items,
    required this.createdAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final itemsJson = (json['items'] as List<dynamic>?) ?? [];
    final itemsList = itemsJson.map((e) {
      if (e is Map<String, dynamic>) return OrderItem.fromJson(e);
      return OrderItem.fromJson(Map<String, dynamic>.from(e));
    }).toList();

    double parseDouble(dynamic v) {
      if (v == null) return 0.0;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0.0;
    }

    return OrderModel(
      id: (json['id'] is int) ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      total: parseDouble(json['total']),
      status: json['status'] ?? '',
      items: itemsList,
      createdAt: json['created_at']?.toString() ?? '',
    );
  }
}

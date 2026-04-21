import 'order_item.dart';

class OrderModel {
  final int id;
  final double total;
  final double itemsTotal;
  final double deliveryCost;
  final int bonusApplied;
  final int bonusEarned;
  final String paymentMethod;
  final String paymentStatus;
  final String cardMask;
  final String deliveryAddress;
  final String status;
  final List<OrderItem> items;
  final String createdAt;

  OrderModel({
    required this.id,
    required this.total,
    required this.itemsTotal,
    required this.deliveryCost,
    required this.bonusApplied,
    required this.bonusEarned,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.cardMask,
    required this.deliveryAddress,
    required this.status,
    required this.items,
    required this.createdAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final List<dynamic> itemsJson = (json['items'] as List<dynamic>?) ?? [];
    final List<OrderItem> itemsList = itemsJson.map((dynamic e) {
      if (e is Map<String, dynamic>) {
        return OrderItem.fromJson(e);
      }
      return OrderItem.fromJson(Map<String, dynamic>.from(e));
    }).toList();

    double parseDouble(dynamic v) {
      if (v == null) return 0.0;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0.0;
    }

    int parseInt(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString()) ?? 0;
    }

    return OrderModel(
      id: parseInt(json['id']),
      total: parseDouble(json['total']),
      itemsTotal: parseDouble(json['items_total'] ?? json['subtotal']),
      deliveryCost: parseDouble(json['delivery_cost']),
      bonusApplied: parseInt(json['bonus_applied']),
      bonusEarned: parseInt(json['bonus_earned']),
      paymentMethod: json['payment_method']?.toString() ?? '',
      paymentStatus: json['payment_status']?.toString() ?? '',
      cardMask: json['card_mask']?.toString() ?? '',
      deliveryAddress: json['delivery_address']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      items: itemsList,
      createdAt: json['created_at']?.toString() ?? '',
    );
  }
}
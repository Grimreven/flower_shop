// lib/models/order_item.dart
class OrderItem {
  final int id;
  final int orderId;
  final int productId;
  final String name;
  final String imageUrl;
  final int quantity;
  final double price;

  OrderItem({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.name,
    required this.imageUrl,
    required this.quantity,
    required this.price,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
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

    return OrderItem(
      id: parseInt(json['id'] ?? json['order_item_id']),
      orderId: parseInt(json['order_id']),
      productId: parseInt(json['product_id']),
      name: json['name'] ?? json['product_name'] ?? '',
      imageUrl: json['image_url'] ?? json['product_image'] ?? '',
      quantity: parseInt(json['quantity']),
      price: parseDouble(json['price']),
    );
  }
}

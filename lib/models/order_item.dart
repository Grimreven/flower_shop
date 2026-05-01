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
    return OrderItem(
      id: _toInt(json['id'] ?? json['order_item_id']),
      orderId: _toInt(json['order_id']),
      productId: _toInt(json['product_id']),
      name: (json['name'] ?? json['product_name'] ?? '').toString(),
      imageUrl: (json['image_url'] ?? json['product_image'] ?? '').toString(),
      quantity: _toInt(json['quantity']),
      price: _toDouble(json['price']),
    );
  }

  double get total => price * quantity;

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();

    return int.tryParse(value.toString()) ?? 0;
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();

    return double.tryParse(value.toString().replaceAll(',', '.')) ?? 0.0;
  }
}
// lib/models/cart_item.dart
import 'product.dart';

class CartItem {
  final Product product;
  final int quantity;

  CartItem({required this.product, required this.quantity});

  double get total => product.price * quantity;

  Map<String, dynamic> toJson() => {
    'product_id': product.id,
    'quantity': quantity,
  };

  factory CartItem.fromJson(Map<String, dynamic> json) {
    // json expected to contain product fields or product_* fields
    final productJson = <String, dynamic>{
      'id': json['product_id'] ?? json['id'],
      'name': json['name'] ?? json['product_name'],
      'description': json['description'] ?? '',
      'price': json['price'] ?? json['product_price'] ?? 0,
      'image_url': json['image_url'] ?? json['product_image'] ?? '',
      'category_id': json['category_id'] ?? 0,
      'category_name': json['category_name'] ?? '',
      'in_stock': json['in_stock'] ?? true,
      'rating': json['rating'] ?? 0,
      'care': json['care'],
    };

    return CartItem(
      product: Product.fromJson(productJson),
      quantity: (json['quantity'] ?? json['qty'] ?? 1) is int
          ? (json['quantity'] ?? json['qty'] ?? 1)
          : int.tryParse((json['quantity'] ?? json['qty'] ?? '1').toString()) ?? 1,
    );
  }
}

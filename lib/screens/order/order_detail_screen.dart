import 'package:flutter/material.dart';
import 'package:flower_shop/models/order_model.dart';

class OrderDetailScreen extends StatelessWidget {
  final OrderModel order;

  const OrderDetailScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Заказ #${order.id}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Статус: ${order.status}', style: const TextStyle(fontSize: 18)),
          Text('Итого: ${order.total.toStringAsFixed(0)} ₽', style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 16),
          const Text('Товары:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...order.items.map((item) => ListTile(
            leading: Image.network(item.product.imageUrl, width: 50, height: 50, fit: BoxFit.cover),
            title: Text(item.product.name),
            subtitle: Text('Количество: ${item.quantity}'),
            trailing: Text('${(item.product.price * item.quantity).toStringAsFixed(0)} ₽'),
          )),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/order_controller.dart';
import '../../utils/app_colors.dart';

class OrdersScreen extends StatelessWidget {
  OrdersScreen({Key? key}) : super(key: key);
  final OrderController orderController = Get.put(OrderController(authController: Get.find()));

  @override
  Widget build(BuildContext context) {
    orderController.fetchUserOrders();

    return Scaffold(
      appBar: AppBar(title: const Text('Мои заказы'), backgroundColor: AppColors.primary),
      body: Obx(() {
        if (orderController.orders.isEmpty) {
          return const Center(child: Text('Нет заказов'));
        }

        return ListView.builder(
          itemCount: orderController.orders.length,
          itemBuilder: (_, index) {
            final order = orderController.orders[index];
            return ListTile(
              title: Text('Заказ #${order.id} — ${order.status}'),
              subtitle: Text('Сумма: ${order.total.toStringAsFixed(0)} ₽\nДата: ${order.createdAt}'),
              onTap: () {
                Get.to(() => OrderDetailsScreen(order: order));
              },
            );
          },
        );
      }),
    );
  }
}

class OrderDetailsScreen extends StatelessWidget {
  final order;
  const OrderDetailsScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Детали заказа #${order.id}'), backgroundColor: AppColors.primary),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Сумма: ${order.total.toStringAsFixed(0)} ₽', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Text('Статус: ${order.status}', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Text('Дата: ${order.createdAt}', style: const TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }
}

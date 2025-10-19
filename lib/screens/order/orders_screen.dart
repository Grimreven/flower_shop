import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/order_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../utils/app_colors.dart';
import 'order_detail_screen.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  late final OrderController orderController;
  final AuthController authController = Get.find<AuthController>();

  @override
  void initState() {
    super.initState();
    orderController = Get.put(OrderController(authController: authController));
    orderController.fetchUserOrders();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        title: const Text('Мои заказы'),
        backgroundColor: AppColors.primary,
        elevation: 1,
      ),
      body: Obx(() {
        final orders = orderController.orders;
        if (orders.isEmpty) {
          return const Center(
            child: Text(
              'У вас пока нет заказов 💐',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => await orderController.fetchUserOrders(),
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: orders.length,
            itemBuilder: (context, i) {
              final order = orders[i];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  leading: const Icon(Icons.receipt_long, color: AppColors.primary, size: 30),
                  title: Text('Заказ #${order.id}'),
                  subtitle: Text(
                    '${order.status}\nИтого: ${order.total.toStringAsFixed(0)} ₽',
                  ),
                  isThreeLine: true,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Get.to(() => OrderDetailScreen(order: order)),
                ),
              );
            },
          ),
        );
      }),
    );
  }
}

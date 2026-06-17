import 'package:flutter/material.dart';
import '../../api/server_api_service.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  bool isLoading = true;
  List<Map<String, dynamic>> orders = [];

  final List<String> statuses = [
    'Новый',
    'Принят',
    'Собирается',
    'Передан курьеру',
    'Доставлен',
    'Отменён',
  ];

  @override
  void initState() {
    super.initState();
    loadOrders();
  }

  Future<void> loadOrders() async {
    try {
      final data = await ServerApiService.getAdminOrders();

      if (!mounted) return;

      setState(() {
        orders = data;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка загрузки заказов: $e'),
        ),
      );

      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> updateStatus(
      int orderId,
      String status,
      ) async {
    try {
      await ServerApiService.updateAdminOrderStatus(
        orderId: orderId,
        status: status,
      );

      await loadOrders();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Статус обновлён'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Заказы'),
      ),
      body: RefreshIndicator(
        onRefresh: loadOrders,
        child: ListView.builder(
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index];

            return Card(
              margin: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Заказ №${order['id']}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      'Клиент: ${order['customer_name'] ?? ''}',
                    ),

                    Text(
                      'Телефон: ${order['customer_phone'] ?? ''}',
                    ),

                    Text(
                      'Сумма: ${order['total']} ₽',
                    ),

                    Text(
                      'Оплата: ${order['payment_method'] ?? ''}',
                    ),

                    const SizedBox(height: 10),

                    DropdownButtonFormField<String>(
                      value: statuses.contains(order['status'])
                          ? order['status']
                          : statuses.first,
                      items: statuses.map((status) {
                        return DropdownMenuItem(
                          value: status,
                          child: Text(status),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value == null) return;

                        updateStatus(
                          order['id'],
                          value,
                        );
                      },
                      decoration: const InputDecoration(
                        labelText: 'Статус заказа',
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/cart_controller.dart';
import '../../utils/app_colors.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final CartController cartController = Get.find<CartController>();

    // Локальные состояния
    String paymentMethod = 'card';
    String address = 'ул. Цветочная, д. 5';
    double availableBonuses = 120;
    double usedBonuses = 0;
    TextEditingController promoController = TextEditingController();

    // Загрузка корзины при открытии экрана
    cartController.loadCartFromServer();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Корзина'),
        backgroundColor: AppColors.primary,
      ),
      body: Obx(() {
        if (cartController.items.isEmpty) {
          return const Center(
            child: Text('Ваша корзина пуста 😕', style: TextStyle(fontSize: 18)),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Товары
              ...cartController.items.map((item) {
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    leading: Image.network(item.product.imageUrl,
                        width: 50, height: 50, fit: BoxFit.cover),
                    title: Text(item.product.name),
                    subtitle: Text('${item.product.price.toStringAsFixed(0)} ₽'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: () => cartController.decrement(item.product),
                        ),
                        Obx(() => Text('${item.quantity.value}',
                            style: const TextStyle(fontWeight: FontWeight.bold))),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: () => cartController.increment(item.product),
                        ),
                      ],
                    ),
                  ),
                );
              }),

              const SizedBox(height: 24),

              // Итог
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Итого:',
                      style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Obx(() => Text(
                    '${cartController.totalPrice.toStringAsFixed(0)} ₽',
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary),
                  )),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Get.snackbar(
                    'Заказ оформлен!',
                    'Ожидайте подтверждения 😊',
                    snackPosition: SnackPosition.BOTTOM,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: const Text('Оформить заказ'),
              ),
            ],
          ),
        );
      }),
    );
  }
}

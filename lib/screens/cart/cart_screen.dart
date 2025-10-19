import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/cart_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../utils/app_colors.dart';
import 'package:flower_shop/widgets/product_detail.dart';
import '../order/order_checkout_screen.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final CartController cartController = Get.find<CartController>();
    final AuthController authController = Get.find<AuthController>();

    // Загружаем корзину при открытии экрана
    cartController.loadCartFromServer();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Корзина'),
        backgroundColor: AppColors.primary,
      ),
      body: Obx(() {
        // Пока идёт загрузка
        if (cartController.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        // Если корзина пуста
        if (cartController.items.isEmpty) {
          return const Center(
            child: Text(
              'Ваша корзина пуста 😕',
              style: TextStyle(fontSize: 18),
            ),
          );
        }

        // Содержимое корзины
        return Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Список товаров
                    ...cartController.items.map((item) {
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          leading: Image.network(
                            item.product.imageUrl,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(Icons.image),
                          ),
                          title: Text(item.product.name),
                          subtitle: Text(
                            '${item.product.price.toStringAsFixed(0)} ₽',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline),
                                onPressed: () =>
                                    cartController.decrement(item.product),
                              ),
                              Obx(() => Text(
                                '${item.quantity.value}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              )),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline),
                                onPressed: () =>
                                    cartController.increment(item.product),
                              ),
                            ],
                          ),

                          // 👇 Переход к экрану описания товара
                          onTap: () {
                            Get.to(() => ProductDetail(
                              product: item.product,
                              cartController: cartController,
                              authController: authController,
                            ));
                          },
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),

            // --- Блок с итогом и кнопкой оформления заказа ---
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    offset: const Offset(0, -2),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Сумма
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Итого:',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Obx(() => Text(
                        '${cartController.totalPrice.toStringAsFixed(0)} ₽',
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary),
                      )),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Кнопка оформления заказа
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        if (!authController.isLoggedIn) {
                          Get.snackbar(
                            'Вход',
                            'Пожалуйста, войдите в аккаунт перед оформлением заказа',
                            snackPosition: SnackPosition.BOTTOM,
                          );
                          return;
                        }

                        Get.to(() => const OrderCheckoutScreen());
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Перейти к оформлению заказа',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }
}

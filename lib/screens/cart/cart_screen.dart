import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/cart_controller.dart';
import '../../utils/app_colors.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final CartController cartController = Get.find<CartController>();

    // Локальные состояния (в будущем заменятся на данные из БД)
    String paymentMethod = 'card';
    String address = 'ул. Цветочная, д. 5';
    double availableBonuses = 120;
    double usedBonuses = 0;
    TextEditingController promoController = TextEditingController();

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
                        Text('${item.quantity}',
                            style: const TextStyle(fontWeight: FontWeight.bold)),
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

              // -------- Адрес --------
              ListTile(
                title: const Text('Адрес доставки'),
                subtitle: Text(address),
                trailing: IconButton(
                  icon: const Icon(Icons.edit_location_alt_outlined),
                  onPressed: () {
                    // TODO: выбор адреса из профиля
                  },
                ),
              ),
              const Divider(),

              // -------- Способ оплаты --------
              const SizedBox(height: 8),
              const Text('Способ оплаты',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              RadioListTile(
                title: const Text('Картой при получении'),
                value: 'card',
                groupValue: paymentMethod,
                onChanged: (_) {},
              ),
              RadioListTile(
                title: const Text('Наличными'),
                value: 'cash',
                groupValue: paymentMethod,
                onChanged: (_) {},
              ),
              const Divider(),

              // -------- Бонусы --------
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Использовать бонусы',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('${usedBonuses.toStringAsFixed(0)} из $availableBonuses'),
                ],
              ),
              Slider(
                min: 0,
                max: availableBonuses,
                divisions: availableBonuses.toInt(),
                value: usedBonuses,
                onChanged: (v) {
                  usedBonuses = v;
                },
              ),
              const Divider(),

              // -------- Промокод --------
              const SizedBox(height: 8),
              TextField(
                controller: promoController,
                decoration: InputDecoration(
                  labelText: 'Промокод',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.check_circle_outline),
                    onPressed: () {
                      // TODO: применить промокод
                    },
                  ),
                ),
              ),
              const Divider(),

              // -------- Время доставки --------
              ListTile(
                title: const Text('Выбрать время доставки'),
                trailing: const Icon(Icons.access_time),
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                  if (time != null) {
                    Get.snackbar(
                      'Время выбрано',
                      'Доставка к ${time.format(context)}',
                      snackPosition: SnackPosition.BOTTOM,
                    );
                  }
                },
              ),
              const Divider(),

              // -------- Итог --------
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Итого:',
                      style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(
                    '${cartController.totalPrice.toStringAsFixed(0)} ₽',
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              ElevatedButton(
                onPressed: () {
                  // TODO: отправить заказ в backend
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

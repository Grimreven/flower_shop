import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/cart_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/order_controller.dart';
import '../../utils/app_colors.dart';
import 'package:flower_shop/models/cart_item.dart' as model;

class OrderCheckoutScreen extends StatefulWidget {
  const OrderCheckoutScreen({super.key});

  @override
  State<OrderCheckoutScreen> createState() => _OrderCheckoutScreenState();
}

class _OrderCheckoutScreenState extends State<OrderCheckoutScreen> {
  final CartController cartController = Get.find<CartController>();
  final AuthController authController = Get.find<AuthController>();
  final OrderController orderController = Get.put(
    OrderController(authController: Get.find<AuthController>()),
  );

  String paymentMethod = 'Наличный расчёт';
  String address = '';
  String promoCode = '';
  int bonusToUse = 0;
  bool canUseBonus = false;

  @override
  void initState() {
    super.initState();
    address = authController.user.value?.address ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final total = cartController.totalPrice;
    final bonusPoints = authController.user.value?.loyaltyPoints ?? 0;

    canUseBonus = total >= 750 && bonusPoints > 0;

    return Scaffold(
      appBar: AppBar(title: const Text('Оформление заказа'), backgroundColor: AppColors.primary),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Ваш заказ', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...cartController.items.map((item) => ListTile(
              leading: Image.network(item.product.imageUrl, width: 50, height: 50, fit: BoxFit.cover),
              title: Text(item.product.name),
              subtitle: Text('${item.product.price.toStringAsFixed(0)} ₽ × ${item.quantity.value}'),
              trailing: Text('${(item.product.price * item.quantity.value).toStringAsFixed(0)} ₽'),
            )),
            const Divider(height: 30),
            const Text('Адрес доставки', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: address,
              decoration: InputDecoration(
                hintText: 'Введите адрес доставки',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.location_on),
              ),
              onChanged: (v) => address = v,
            ),
            const SizedBox(height: 20),
            const Text('Способ оплаты', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: paymentMethod,
              items: const [
                DropdownMenuItem(value: 'Наличный расчёт', child: Text('Наличный расчёт')),
                DropdownMenuItem(value: 'Безналичный расчёт', child: Text('Безналичный расчёт')),
              ],
              onChanged: (v) => setState(() => paymentMethod = v!),
              decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
            ),
            const SizedBox(height: 20),
            const Text('Оплата бонусами', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (!canUseBonus)
              Text('Бонусами можно оплатить заказ от 750 ₽', style: TextStyle(color: Colors.grey[600])),
            if (canUseBonus)
              Row(
                children: [
                  Expanded(
                    child: Slider(
                      value: bonusToUse.toDouble(),
                      min: 0,
                      max: bonusPoints.toDouble(),
                      divisions: bonusPoints > 0 ? bonusPoints : 1,
                      label: '$bonusToUse',
                      onChanged: (v) => setState(() => bonusToUse = v.toInt()),
                    ),
                  ),
                  Text('$bonusToUse / $bonusPoints')
                ],
              ),
            const SizedBox(height: 20),
            const Text('Промокод', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              decoration: InputDecoration(
                hintText: 'Введите промокод',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.discount),
              ),
              onChanged: (v) => promoCode = v,
            ),
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Итого:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  Obx(() => Text('${(cartController.totalPrice - bonusToUse).toStringAsFixed(0)} ₽',
                      style: const TextStyle(fontSize: 20, color: AppColors.primary, fontWeight: FontWeight.bold))),
                ],
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _confirmOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Оформить заказ', style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmOrder() async {
    if (cartController.items.isEmpty) {
      Get.snackbar('Ошибка', 'Корзина пуста');
      return;
    }
    if (address.isEmpty) {
      Get.snackbar('Ошибка', 'Введите адрес доставки');
      return;
    }

    try {
      // Преобразуем CartItem из контроллера в CartItem модели
      final itemsForOrder = cartController.items.map((item) => model.CartItem(
        product: item.product!,
        quantity: item.quantity!.value,
      )).toList();

      await orderController.createOrder(itemsForOrder);

      // Вычитаем бонусы
      if (bonusToUse > 0) {
        authController.updateLoyaltyPoints(-bonusToUse);
      }

      Get.snackbar('Успех', 'Ваш заказ оформлен!');
      Get.back();
    } catch (e) {
      Get.snackbar('Ошибка', 'Не удалось оформить заказ: $e');
    }
  }
}

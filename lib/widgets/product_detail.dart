import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/cart_controller.dart';
import '../controllers/auth_controller.dart';
import '../models/product.dart';
import '../utils/app_colors.dart';

class ProductDetail extends StatelessWidget {
  final Product product;
  final CartController cartController = Get.find<CartController>();
  final AuthController authController = Get.find<AuthController>();

  ProductDetail({super.key, required this.product});

  static const List<String> features = [
    'Доставка по всей стране',
    'Гарантия качества',
    'Возможность возврата',
  ];

  static const List<IconData> featureIcons = [
    Icons.local_shipping,
    Icons.shield,
    Icons.refresh,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(product.name),
        backgroundColor: AppColors.primary,
        centerTitle: true,
      ),
      body: Obx(() {
        final loggedIn = authController.token.isNotEmpty;
        final inCart = cartController.isInCart(product);
        final quantity = cartController.getQuantity(product);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Изображение
              Hero(
                tag: 'product_${product.id}',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    product.imageUrl,
                    width: double.infinity,
                    height: 280,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.image_not_supported, size: 80),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Название и цена
              Text(product.name, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text('${product.price.toStringAsFixed(2)} ₽',
                  style: const TextStyle(fontSize: 22, color: Colors.pinkAccent, fontWeight: FontWeight.w600)),
              const SizedBox(height: 20),

              // Описание
              const Text('Описание', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(product.description ?? 'Описание недоступно.', style: const TextStyle(fontSize: 16, height: 1.5)),
              const SizedBox(height: 24),

              // Особенности
              const Text('Особенности', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              SizedBox(
                height: 120,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: features.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    return Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 3,
                      child: Container(
                        width: 140,
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(featureIcons[index], color: AppColors.primary, size: 28),
                            const SizedBox(height: 8),
                            Text(features[index], textAlign: TextAlign.center, style: const TextStyle(fontSize: 14)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              // Уход за растением
              if (product.care != null && product.care!.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Уход за растением', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ...product.care!.map((instruction) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 12,
                            backgroundColor: AppColors.primary.withOpacity(0.1),
                            child: Text(
                              '${product.care!.indexOf(instruction) + 1}',
                              style: const TextStyle(fontSize: 12, color: AppColors.primary),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(child: Text(instruction, style: const TextStyle(fontSize: 15, height: 1.4))),
                        ],
                      ),
                    )),
                    const SizedBox(height: 24),
                  ],
                ),

              // Управление корзиной только для авторизованных
              Center(
                child: loggedIn
                    ? (inCart
                    ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline, size: 30),
                      onPressed: () => cartController.decrement(product),
                    ),
                    Text('$quantity', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline, size: 30),
                      onPressed: () => cartController.increment(product),
                    ),
                  ],
                )
                    : ElevatedButton.icon(
                  onPressed: () => cartController.addToCart(product),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
                  ),
                  icon: const Icon(Icons.shopping_cart),
                  label: const Text('Добавить в корзину', style: TextStyle(fontSize: 18)),
                ))
                    : SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      Get.snackbar(
                        'Вход',
                        'Пожалуйста, войдите, чтобы добавлять товары в корзину',
                        snackPosition: SnackPosition.BOTTOM,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('В корзину', style: TextStyle(fontSize: 18)),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      }),
    );
  }
}

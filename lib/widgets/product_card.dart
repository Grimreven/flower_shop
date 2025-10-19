import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/product.dart';
import '../controllers/cart_controller.dart';
import '../controllers/auth_controller.dart';
import '../utils/app_colors.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback? onViewDetails;
  final VoidCallback? onAddToCart;

  const ProductCard({
    super.key,
    required this.product,
    this.onViewDetails,
    this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    final cartController = Get.find<CartController>();
    final authController = Get.find<AuthController>();

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      elevation: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: InkWell(
              onTap: onViewDetails,
              child: Image.network(
                product.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    Container(color: Colors.grey[200], child: const Icon(Icons.image_not_supported, size: 48)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  '${product.price.toStringAsFixed(0)} ₽',
                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),

                Obx(() {
                  // Используем authController.token, чтобы Obx реагировал на изменения
                  final loggedIn = authController.token.isNotEmpty;

                  if (!loggedIn) {
                    return SizedBox(
                      width: double.infinity,
                      height: 36,
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
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('В корзину'),
                      ),
                    );
                  }

                  final inCart = cartController.isInCart(product);
                  final qty = cartController.getQuantity(product);

                  if (!inCart) {
                    return SizedBox(
                      width: double.infinity,
                      height: 36,
                      child: ElevatedButton(
                        onPressed: onAddToCart ??
                                () {
                              cartController.addToCart(product);
                              Get.snackbar(
                                'Добавлено',
                                '${product.name} добавлен в корзину',
                                snackPosition: SnackPosition.BOTTOM,
                              );
                            },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('В корзину'),
                      ),
                    );
                  } else {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: () => cartController.decrement(product),
                        ),
                        Text(qty.toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: () => cartController.increment(product),
                        ),
                      ],
                    );
                  }
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

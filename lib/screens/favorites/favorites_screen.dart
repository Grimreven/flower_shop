import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/auth_controller.dart';
import '../../../controllers/cart_controller.dart';
import '../../../controllers/favorites_controller.dart';
import '../../../models/product.dart';
import '../../../utils/app_colors.dart';
import '../../../widgets/product_card.dart';
import '../../../widgets/product_detail.dart';

class FavoritesScreen extends StatelessWidget {
  FavoritesScreen({super.key});

  final FavoritesController favoritesController = Get.find<FavoritesController>();
  final CartController cartController = Get.find<CartController>();
  final AuthController authController = Get.find<AuthController>();

  void _openProductDetail(BuildContext context, Product product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductDetail(
          product: product,
          cartController: cartController,
          authController: authController,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bg = Theme.of(context).scaffoldBackgroundColor;
    final Color surface = Theme.of(context).cardColor;
    final Color onSurface = Theme.of(context).colorScheme.onSurface;
    final Color muted =
    isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
    final Color borderColor = isDark ? AppColors.darkBorder : AppColors.border;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text('Избранное'),
        actions: [
          Obx(() {
            if (!authController.isLoggedIn ||
                favoritesController.favoriteProducts.isEmpty) {
              return const SizedBox.shrink();
            }

            return IconButton(
              tooltip: 'Очистить',
              onPressed: () async {
                await favoritesController.clearFavorites();
                Get.snackbar(
                  'Готово',
                  'Избранное очищено',
                  snackPosition: SnackPosition.BOTTOM,
                );
              },
              icon: const Icon(Icons.delete_outline_rounded),
            );
          }),
        ],
      ),
      body: Obx(() {
        if (!authController.isLoggedIn) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: isDark
                          ? AppColors.purple.withValues(alpha: 0.05)
                          : AppColors.shadow,
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.favorite_border_rounded,
                      size: 56,
                      color: isDark ? AppColors.purpleLight : AppColors.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Избранное доступно после входа',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: onSurface,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Авторизуйтесь, чтобы сохранять понравившиеся товары и быстро возвращаться к ним позже.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: muted,
                        fontSize: 14,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        if (favoritesController.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(
              color: AppColors.primary,
            ),
          );
        }

        if (favoritesController.favoriteProducts.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: isDark
                          ? AppColors.purple.withValues(alpha: 0.05)
                          : AppColors.shadow,
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.favorite_outline_rounded,
                      size: 56,
                      color: isDark ? AppColors.purpleLight : AppColors.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Пока ничего нет',
                      style: TextStyle(
                        color: onSurface,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Добавляй товары в избранное, чтобы не потерять понравившиеся букеты.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: muted,
                        fontSize: 14,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: favoritesController.loadFavorites,
          color: AppColors.primary,
          child: GridView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.64,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: favoritesController.favoriteProducts.length,
            itemBuilder: (context, index) {
              final product = favoritesController.favoriteProducts[index];

              return ProductCard(
                product: product,
                authController: authController,
                cartController: cartController,
                onViewDetails: () => _openProductDetail(context, product),
                onAddToCart: () async {
                  if (!authController.isLoggedIn) {
                    Get.snackbar(
                      'Ошибка',
                      'Сначала войдите в профиль',
                      snackPosition: SnackPosition.BOTTOM,
                    );
                    return;
                  }

                  await cartController.addToCart(product);
                  Get.snackbar(
                    'Добавлено',
                    '${product.name} добавлен в корзину',
                    snackPosition: SnackPosition.BOTTOM,
                  );
                },
              );
            },
          ),
        );
      }),
    );
  }
}
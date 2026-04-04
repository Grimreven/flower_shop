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
    required AuthController authController,
    required cartController,
  });

  @override
  Widget build(BuildContext context) {
    final cartController = Get.find<CartController>();
    final authController = Get.find<AuthController>();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).cardColor;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final borderColor =
    isDark ? AppColors.darkBorder : AppColors.border;

    final imageBackground =
    isDark ? AppColors.darkSurfaceSoft : const Color(0xFFF8EFF3);

    final quantityBackground =
    isDark ? AppColors.darkSurfaceElevated : AppColors.primaryLight;

    final ratingBackground =
    isDark ? AppColors.darkSurfaceElevated : Colors.white.withValues(alpha: 0.94);

    return Container(
      decoration: BoxDecoration(
        gradient: isDark ? AppColors.darkCardGradient : null,
        color: isDark ? null : cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? AppColors.purple.withValues(alpha: 0.06)
                : AppColors.shadow,
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onViewDetails,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Hero(
                      tag: 'product_${product.id}',
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(24),
                        ),
                        child: Container(
                          color: imageBackground,
                          child: Image.network(
                            product.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Center(
                              child: Icon(
                                Icons.image_not_supported_outlined,
                                size: 48,
                                color: isDark ? AppColors.purple : AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (!product.inStock)
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          'Нет в наличии',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: ratingBackground,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: borderColor),
                        boxShadow: isDark
                            ? [
                          BoxShadow(
                            color: AppColors.purple.withValues(alpha: 0.08),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ]
                            : null,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.star_rounded,
                            size: 14,
                            color: isDark ? AppColors.purpleLight : Colors.amber,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            product.rating.toStringAsFixed(1),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    product.categoryName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isDark
                          ? AppColors.darkMutedForeground
                          : AppColors.mutedForeground,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ShaderMask(
                    shaderCallback: (bounds) => (isDark
                        ? AppColors.darkBrandGradient
                        : AppColors.brandGradient)
                        .createShader(bounds),
                    child: Text(
                      '${product.price.toStringAsFixed(0)} ₽',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Obx(() {
                    if (!authController.isLoggedIn) {
                      return SizedBox(
                        width: double.infinity,
                        height: 42,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: isDark
                                ? AppColors.darkBrandGradient
                                : AppColors.brandGradient,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: (isDark ? AppColors.purple : AppColors.primary)
                                    .withValues(alpha: 0.18),
                                blurRadius: 14,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: () {
                              Get.snackbar(
                                'Вход',
                                'Пожалуйста, войдите, чтобы добавлять товары в корзину',
                                snackPosition: SnackPosition.BOTTOM,
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text('В корзину'),
                          ),
                        ),
                      );
                    }

                    final inCart = cartController.isInCart(product);
                    final qty = cartController.getQuantity(product);

                    if (!inCart) {
                      return SizedBox(
                        width: double.infinity,
                        height: 42,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: isDark
                                ? AppColors.darkBrandGradient
                                : AppColors.brandGradient,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: (isDark ? AppColors.purple : AppColors.primary)
                                    .withValues(alpha: 0.18),
                                blurRadius: 14,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: product.inStock
                                ? (onAddToCart ??
                                    () async {
                                  await cartController.addToCart(product);
                                  Get.snackbar(
                                    'Добавлено',
                                    '${product.name} добавлен в корзину',
                                    snackPosition: SnackPosition.BOTTOM,
                                  );
                                })
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: isDark
                                  ? AppColors.darkBorderSoft
                                  : Colors.grey.shade300,
                              disabledForegroundColor: isDark
                                  ? AppColors.darkMutedForeground
                                  : Colors.grey.shade600,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text('В корзину'),
                          ),
                        ),
                      );
                    }

                    return Container(
                      height: 42,
                      decoration: BoxDecoration(
                        color: quantityBackground,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderColor),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            splashRadius: 20,
                            icon: Icon(
                              Icons.remove_circle_outline,
                              color:
                              isDark ? AppColors.purpleLight : AppColors.primary,
                            ),
                            onPressed: () => cartController.decrement(product),
                          ),
                          Text(
                            qty.toString(),
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: onSurface,
                            ),
                          ),
                          IconButton(
                            splashRadius: 20,
                            icon: Icon(
                              Icons.add_circle_outline,
                              color:
                              isDark ? AppColors.purpleLight : AppColors.primary,
                            ),
                            onPressed: () => cartController.increment(product),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/auth_controller.dart';
import '../controllers/cart_controller.dart';
import '../models/product.dart';
import '../utils/app_colors.dart';

class ProductDetail extends StatelessWidget {
  final Product product;
  final CartController cartController;
  final AuthController authController;

  const ProductDetail({
    super.key,
    required this.product,
    required this.cartController,
    required this.authController,
  });

  Future<void> _handleAddToCart(BuildContext context) async {
    final bool isLoggedIn =
        authController.isLoggedIn || authController.token.isNotEmpty;

    if (!isLoggedIn) {
      final bool isDark = Theme.of(context).brightness == Brightness.dark;

      await showDialog<void>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
              side: BorderSide(
                color: isDark ? AppColors.darkBorder : AppColors.border,
              ),
            ),
            title: const Text('Требуется авторизация'),
            content: const Text(
              'Чтобы добавить товар в корзину, пожалуйста, войдите в аккаунт.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Понятно',
                  style: TextStyle(
                    color: isDark ? AppColors.purpleLight : AppColors.primary,
                  ),
                ),
              ),
            ],
          );
        },
      );

      return;
    }

    await cartController.addToCart(product);

    Get.snackbar(
      'Добавлено',
      '${product.name} добавлен в корзину',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  Widget _ratingStars(double rating, bool isDark) {
    final int fullStars = rating.floor();
    final bool hasHalfStar = (rating - fullStars) >= 0.5;

    return Row(
      children: [
        ...List.generate(
          fullStars,
              (_) => Icon(
            Icons.star_rounded,
            size: 20,
            color: isDark ? AppColors.purpleLight : Colors.amber,
          ),
        ),
        if (hasHalfStar)
          Icon(
            Icons.star_half_rounded,
            size: 20,
            color: isDark ? AppColors.purpleLight : Colors.amber,
          ),
      ],
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

    return Scaffold(
      backgroundColor: bg,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 360,
            pinned: true,
            backgroundColor: bg,
            foregroundColor: onSurface,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    product.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: isDark
                          ? AppColors.darkSurfaceElevated
                          : AppColors.primaryLight,
                      child: Icon(
                        Icons.local_florist_rounded,
                        size: 72,
                        color: isDark
                            ? AppColors.purpleLight
                            : AppColors.primary,
                      ),
                    ),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withValues(alpha: 0.10),
                          Colors.black.withValues(alpha: 0.45),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              transform: Matrix4.translationValues(0, -22, 0),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (product.categoryName.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkSurfaceElevated
                              : AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          product.categoryName,
                          style: TextStyle(
                            color: isDark
                                ? AppColors.purpleLight
                                : AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    const SizedBox(height: 14),
                    Text(
                      product.name,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: onSurface,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _ratingStars(product.rating, isDark),
                        const SizedBox(width: 10),
                        Text(
                          product.rating.toStringAsFixed(1),
                          style: TextStyle(
                            color: muted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        ShaderMask(
                          shaderCallback: (Rect bounds) => (isDark
                              ? AppColors.darkBrandGradient
                              : AppColors.brandGradient)
                              .createShader(bounds),
                          child: Text(
                            '${product.price.toStringAsFixed(0)} ₽',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: isDark ? AppColors.darkCardGradient : null,
                        color: isDark ? null : surface,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: isDark ? AppColors.darkBorder : AppColors.border,
                        ),
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Описание',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: onSurface,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            product.description,
                            style: TextStyle(
                              color: muted,
                              height: 1.55,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkSurfaceElevated
                            : AppColors.primaryLight.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            product.inStock
                                ? Icons.check_circle_rounded
                                : Icons.remove_circle_rounded,
                            color: product.inStock
                                ? AppColors.success
                                : AppColors.danger,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              product.inStock
                                  ? 'Товар в наличии'
                                  : 'Сейчас нет в наличии',
                              style: TextStyle(
                                color: onSurface,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 26),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: isDark
                            ? AppColors.darkBrandGradient
                            : AppColors.brandGradient,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: (isDark ? AppColors.purple : AppColors.primary)
                                .withValues(alpha: 0.18),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: product.inStock
                            ? () => _handleAddToCart(context)
                            : null,
                        icon: const Icon(Icons.shopping_bag_outlined),
                        label: const Text('Добавить в корзину'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.transparent,
                          disabledForegroundColor:
                          Colors.white.withValues(alpha: 0.6),
                          minimumSize: const Size.fromHeight(56),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
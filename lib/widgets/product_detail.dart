import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/auth_controller.dart';
import '../controllers/cart_controller.dart';
import '../controllers/favorites_controller.dart';
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

  Future<void> _showAuthDialog(BuildContext context) async {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    await showDialog(
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
  }

  Widget _ratingStars(double rating, bool isDark) {
    final int fullStars = rating.floor();
    final bool hasHalfStar = (rating - fullStars) >= 0.5;

    return Row(
      children: [
        ...List.generate(
          fullStars.clamp(0, 5),
              (_) => Icon(
            Icons.star_rounded,
            size: 18,
            color: isDark ? AppColors.purpleLight : Colors.amber,
          ),
        ),
        if (hasHalfStar)
          Icon(
            Icons.star_half_rounded,
            size: 18,
            color: isDark ? AppColors.purpleLight : Colors.amber,
          ),
      ],
    );
  }

  Widget _buildInfoCard({
    required BuildContext context,
    required Widget child,
    EdgeInsets padding = const EdgeInsets.all(18),
  }) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color surface = Theme.of(context).cardColor;
    final Color borderColor =
    isDark ? AppColors.darkBorder : AppColors.border;

    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        gradient: isDark ? AppColors.darkCardGradient : null,
        color: isDark ? null : surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? AppColors.purple.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildCircleButton({
    required BuildContext context,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDark
              ? AppColors.darkSurfaceElevated
              : AppColors.primaryLight.withValues(alpha: 0.55),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.border,
          ),
        ),
        child: Icon(
          icon,
          size: 20,
          color: isDark ? AppColors.purpleLight : AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildBulletItem({
    required BuildContext context,
    required String text,
    required IconData icon,
  }) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color onSurface = Theme.of(context).colorScheme.onSurface;
    final Color muted =
    isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            margin: const EdgeInsets.only(top: 1),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark
                  ? AppColors.darkSurfaceElevated
                  : AppColors.primaryLight.withValues(alpha: 0.55),
            ),
            child: Icon(
              icon,
              size: 14,
              color: isDark ? AppColors.purpleLight : AppColors.primary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: onSurface.withValues(alpha: 0.92),
                height: 1.45,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<String> _buildFlowerInfo() {
    if (product.care != null && product.care!.isNotEmpty) {
      return product.care!;
    }

    return <String>[
      'Свежая цветочная композиция в категории «${product.categoryName.isNotEmpty ? product.categoryName : 'букеты'}».',
      'Подходит для подарка, праздника и тёплого знака внимания.',
      'Рекомендуется менять воду каждые 1–2 дня и подрезать стебли.',
    ];
  }

  @override
  Widget build(BuildContext context) {
    final FavoritesController favoritesController =
    Get.find<FavoritesController>();

    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bg = Theme.of(context).scaffoldBackgroundColor;
    final Color onSurface = Theme.of(context).colorScheme.onSurface;
    final Color muted =
    isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
    final Color borderColor =
    isDark ? AppColors.darkBorder : AppColors.border;

    final List<String> flowerInfo = _buildFlowerInfo();

    return Scaffold(
      backgroundColor: bg,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 380,
            pinned: true,
            stretch: true,
            elevation: 0,
            backgroundColor: bg,
            foregroundColor: onSurface,
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: () => Get.back(),
                icon: const Icon(Icons.arrow_back),
              ),
            ),
            actions: [
              Obx(() {
                final bool isFavorite =
                favoritesController.isFavorite(product.id);

                return Container(
                  margin: const EdgeInsets.only(top: 8, right: 8, bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    tooltip: isFavorite
                        ? 'Удалить из избранного'
                        : 'Добавить в избранное',
                    onPressed: () async {
                      await favoritesController.toggleFavorite(product);
                    },
                    icon: AnimatedScale(
                      scale: isFavorite ? 1.08 : 1,
                      duration: const Duration(milliseconds: 180),
                      child: Icon(
                        isFavorite
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        color: isFavorite ? AppColors.danger : Colors.white,
                      ),
                    ),
                  ),
                );
              }),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: 'product_${product.id}',
                    child: Image.network(
                      product.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: isDark
                            ? AppColors.darkSurfaceElevated
                            : AppColors.primaryLight,
                        child: Icon(
                          Icons.local_florist_rounded,
                          size: 90,
                          color: isDark
                              ? AppColors.purpleLight
                              : AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withValues(alpha: 0.10),
                          Colors.black.withValues(alpha: 0.50),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.03),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Transform.translate(
              offset: const Offset(0, 18),
              child: Container(
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(30),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: TextStyle(
                          fontSize: 31,
                          fontWeight: FontWeight.w900,
                          color: onSurface,
                          height: 1.08,
                        ),
                      ),
                      const SizedBox(height: 14),

                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          if (product.categoryName.isNotEmpty)
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? AppColors.darkSurfaceElevated
                                      : AppColors.primaryLight,
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(color: borderColor),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.local_offer_outlined,
                                      size: 14,
                                      color: isDark
                                          ? AppColors.purpleLight
                                          : AppColors.primary,
                                    ),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        product.categoryName,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: isDark
                                              ? AppColors.purpleLight
                                              : AppColors.primary,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          const SizedBox(width: 10),
                          Text(
                            '${product.price.toStringAsFixed(0)} ₽',
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w900,
                              color: onSurface,
                              height: 1,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      Row(
                        children: [
                          _ratingStars(product.rating, isDark),
                          const SizedBox(width: 8),
                          Text(
                            product.rating.toStringAsFixed(1),
                            style: TextStyle(
                              color: muted,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Рейтинг покупателей',
                            style: TextStyle(
                              color: muted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      _buildInfoCard(
                        context: context,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.info_outline_rounded,
                                  size: 18,
                                  color: isDark
                                      ? AppColors.purpleLight
                                      : AppColors.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Описание товара',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: onSurface,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              product.description,
                              style: TextStyle(
                                color: muted,
                                height: 1.6,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 18),

                      _buildInfoCard(
                        context: context,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.format_list_bulleted_rounded,
                                  size: 18,
                                  color: isDark
                                      ? AppColors.purpleLight
                                      : AppColors.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Состав и особенности',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: onSurface,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            ...flowerInfo.asMap().entries.map((entry) {
                              final int index = entry.key;
                              final String item = entry.value;

                              final List<IconData> icons = <IconData>[
                                Icons.local_florist_rounded,
                                Icons.spa_outlined,
                                Icons.water_drop_outlined,
                                Icons.wb_sunny_outlined,
                                Icons.favorite_border_rounded,
                              ];

                              return _buildBulletItem(
                                context: context,
                                text: item,
                                icon: icons[index % icons.length],
                              );
                            }),
                          ],
                        ),
                      ),

                      const SizedBox(height: 18),

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: product.inStock
                              ? Colors.green.withValues(alpha: 0.08)
                              : Colors.red.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: product.inStock
                                ? Colors.green.withValues(alpha: 0.20)
                                : Colors.red.withValues(alpha: 0.20),
                          ),
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

                      const SizedBox(height: 18),

                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            await favoritesController.toggleFavorite(product);
                          },
                          icon: Obx(() {
                            final bool isFavorite =
                            favoritesController.isFavorite(product.id);

                            return AnimatedScale(
                              scale: isFavorite ? 1.08 : 1,
                              duration: const Duration(milliseconds: 180),
                              child: Icon(
                                isFavorite
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                                color: isFavorite
                                    ? AppColors.danger
                                    : (isDark
                                    ? AppColors.purpleLight
                                    : AppColors.primary),
                              ),
                            );
                          }),
                          label: Obx(() {
                            final bool isFavorite =
                            favoritesController.isFavorite(product.id);

                            return Text(
                              isFavorite
                                  ? 'Удалить из избранного'
                                  : 'Добавить в избранное',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            );
                          }),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: borderColor),
                            foregroundColor: isDark
                                ? AppColors.purpleLight
                                : AppColors.primary,
                            backgroundColor: isDark
                                ? AppColors.darkSurface.withValues(alpha: 0.35)
                                : Colors.white.withValues(alpha: 0.9),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 26),

                      Obx(() {
                        final bool isLoggedIn = authController.isLoggedIn;
                        final bool inCart = cartController.isInCart(product);
                        final int qty = cartController.getQuantity(product);

                        if (!isLoggedIn) {
                          return DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: isDark
                                  ? AppColors.darkBrandGradient
                                  : AppColors.brandGradient,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: (isDark
                                      ? AppColors.purple
                                      : AppColors.primary)
                                      .withValues(alpha: 0.20),
                                  blurRadius: 18,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: ElevatedButton.icon(
                              onPressed: () => _showAuthDialog(context),
                              icon: const Icon(Icons.shopping_bag_outlined),
                              label: const Text(
                                'Добавить в корзину',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                foregroundColor: Colors.white,
                                minimumSize: const Size.fromHeight(58),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                            ),
                          );
                        }

                        if (!inCart) {
                          return DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: isDark
                                  ? AppColors.darkBrandGradient
                                  : AppColors.brandGradient,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: (isDark
                                      ? AppColors.purple
                                      : AppColors.primary)
                                      .withValues(alpha: 0.20),
                                  blurRadius: 18,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: ElevatedButton.icon(
                              onPressed: product.inStock
                                  ? () async {
                                await cartController.addToCart(product);
                                Get.snackbar(
                                  'Добавлено',
                                  '${product.name} добавлен в корзину',
                                  snackPosition: SnackPosition.BOTTOM,
                                );
                              }
                                  : null,
                              icon: const Icon(Icons.shopping_bag_outlined),
                              label: const Text(
                                'Добавить в корзину',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: Colors.transparent,
                                disabledForegroundColor:
                                Colors.white.withValues(alpha: 0.6),
                                minimumSize: const Size.fromHeight(58),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                            ),
                          );
                        }

                        return Container(
                          height: 58,
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkSurface
                                : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: borderColor),
                            boxShadow: [
                              BoxShadow(
                                color: isDark
                                    ? AppColors.purple.withValues(alpha: 0.06)
                                    : Colors.black.withValues(alpha: 0.08),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildCircleButton(
                                context: context,
                                icon: Icons.remove,
                                onTap: () {
                                  cartController.decrement(product);
                                },
                              ),
                              Text(
                                qty.toString(),
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: onSurface,
                                ),
                              ),
                              _buildCircleButton(
                                context: context,
                                icon: Icons.add,
                                onTap: () {
                                  cartController.increment(product);
                                },
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
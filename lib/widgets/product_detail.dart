import 'package:flower_shop/controllers/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/cart_controller.dart';
import '../models/product.dart';
import '../utils/app_colors.dart';

class ProductDetail extends StatelessWidget {
  final Product product;
  final CartController cartController = Get.find<CartController>();

  ProductDetail({
    super.key,
    required this.product,
    required CartController cartController,
    required AuthController authController,
  });

  static const List<String> features = [
    'Быстрая доставка',
    'Свежие цветы',
    'Гарантия качества',
  ];

  static const List<IconData> featureIcons = [
    Icons.local_shipping_rounded,
    Icons.local_florist_rounded,
    Icons.verified_rounded,
  ];

  Widget _sectionTitle(BuildContext context, String title) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Text(
      title,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        color: onSurface,
      ),
    );
  }

  Widget _infoCard(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String subtitle,
      }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).cardColor;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final borderColor =
    isDark ? AppColors.darkBorder : AppColors.border;

    return Container(
      width: 160,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: isDark ? AppColors.darkCardGradient : null,
        color: isDark ? null : cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? AppColors.purple.withValues(alpha: 0.05)
                : AppColors.shadow,
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isDark ? AppColors.purpleLight : AppColors.primary,
            size: 30,
          ),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isDark
                  ? AppColors.darkMutedForeground
                  : AppColors.mutedForeground,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _bottomBar(BuildContext context, bool inCart, int quantity) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = Theme.of(context).colorScheme.surface;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final borderColor =
    isDark ? AppColors.darkBorder : AppColors.border;
    final quantityBg =
    isDark ? AppColors.darkSurfaceElevated : AppColors.primaryLight;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: borderColor),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? AppColors.purple.withValues(alpha: 0.06)
                : AppColors.shadow,
            blurRadius: 18,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: inCart
            ? Row(
          children: [
            Expanded(
              child: Container(
                height: 54,
                decoration: BoxDecoration(
                  color: quantityBg,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.remove_circle_outline,
                        color:
                        isDark ? AppColors.purpleLight : AppColors.primary,
                      ),
                      onPressed: () => cartController.decrement(product),
                    ),
                    Text(
                      '$quantity',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: onSurface,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.add_circle_outline,
                        color:
                        isDark ? AppColors.purpleLight : AppColors.primary,
                      ),
                      onPressed: () => cartController.increment(product),
                    ),
                  ],
                ),
              ),
            ),
          ],
        )
            : SizedBox(
          width: double.infinity,
          child: DecoratedBox(
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
                  ? () => cartController.addToCart(product)
                  : null,
              icon: const Icon(Icons.shopping_cart_outlined),
              label: Text(
                product.inStock
                    ? 'Добавить в корзину'
                    : 'Нет в наличии',
              ),
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
                minimumSize: const Size.fromHeight(54),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = Theme.of(context).scaffoldBackgroundColor;
    final cardColor = Theme.of(context).cardColor;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final borderColor =
    isDark ? AppColors.darkBorder : AppColors.border;
    final imageBg =
    isDark ? AppColors.darkSurfaceSoft : const Color(0xFFF6EBEF);
    final chipBg =
    isDark ? AppColors.darkSurfaceElevated : Colors.white.withValues(alpha: 0.9);

    return Scaffold(
      backgroundColor: bg,
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? const LinearGradient(
            colors: [
              AppColors.darkBackground,
              AppColors.darkBackgroundSecondary,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          )
              : null,
        ),
        child: Obx(() {
          final inCart = cartController.isInCart(product);
          final quantity = cartController.getQuantity(product);

          return Stack(
            children: [
              CustomScrollView(
                slivers: [
                  SliverAppBar(
                    expandedHeight: 360,
                    pinned: true,
                    backgroundColor: cardColor,
                    foregroundColor: onSurface,
                    elevation: 0,
                    flexibleSpace: FlexibleSpaceBar(
                      background: Stack(
                        fit: StackFit.expand,
                        children: [
                          Container(
                            color: imageBg,
                            child: Hero(
                              tag: 'product_${product.id}',
                              child: Image.network(
                                product.imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Center(
                                      child: Icon(
                                        Icons.image_not_supported_outlined,
                                        size: 90,
                                        color: isDark
                                            ? AppColors.purple
                                            : AppColors.primary,
                                      ),
                                    ),
                              ),
                            ),
                          ),
                          DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withValues(alpha: 0.05),
                                  Colors.black.withValues(alpha: 0.35),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            left: 16,
                            right: 16,
                            bottom: 20,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (product.categoryName.isNotEmpty)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: chipBg,
                                            borderRadius:
                                            BorderRadius.circular(999),
                                            border: Border.all(color: borderColor),
                                          ),
                                          child: Text(
                                            product.categoryName,
                                            style: TextStyle(
                                              color: isDark
                                                  ? Colors.white
                                                  : AppColors.foreground,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      const SizedBox(height: 10),
                                      Text(
                                        product.name,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 28,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(18),
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
                                  blurRadius: 14,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: ShaderMask(
                                    shaderCallback: (bounds) => (isDark
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
                                ),
                                Container(
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
                                    children: [
                                      Icon(
                                        Icons.star_rounded,
                                        size: 18,
                                        color: isDark
                                            ? AppColors.purpleLight
                                            : Colors.amber,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        product.rating.toStringAsFixed(1),
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: onSurface,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          _sectionTitle(context, 'Описание'),
                          const SizedBox(height: 10),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: borderColor),
                              boxShadow: [
                                BoxShadow(
                                  color: isDark
                                      ? AppColors.purple.withValues(alpha: 0.03)
                                      : Colors.transparent,
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Text(
                              product.description.isNotEmpty
                                  ? product.description
                                  : 'Описание товара пока отсутствует.',
                              style: TextStyle(
                                fontSize: 15,
                                height: 1.6,
                                color: onSurface,
                              ),
                            ),
                          ),
                          const SizedBox(height: 22),
                          _sectionTitle(context, 'Преимущества'),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 150,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: features.length,
                              separatorBuilder: (_, __) =>
                              const SizedBox(width: 12),
                              itemBuilder: (context, index) {
                                return _infoCard(
                                  context,
                                  icon: featureIcons[index],
                                  title: features[index],
                                  subtitle: index == 0
                                      ? 'В удобное для вас время'
                                      : index == 1
                                      ? 'От надежных поставщиков'
                                      : 'Проверенные композиции',
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 22),
                          if (product.care != null && product.care!.isNotEmpty) ...[
                            _sectionTitle(context, 'Рекомендации по уходу'),
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: cardColor,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: borderColor),
                              ),
                              child: Column(
                                children: product.care!
                                    .asMap()
                                    .entries
                                    .map(
                                      (entry) => Padding(
                                    padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                                    child: Row(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          width: 28,
                                          height: 28,
                                          decoration: BoxDecoration(
                                            gradient: isDark
                                                ? AppColors.darkBrandGradient
                                                : AppColors.brandGradient,
                                            borderRadius:
                                            BorderRadius.circular(999),
                                          ),
                                          child: Center(
                                            child: Text(
                                              '${entry.key + 1}',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w700,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            entry.value,
                                            style: TextStyle(
                                              fontSize: 15,
                                              height: 1.5,
                                              color: onSurface,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                                    .toList(),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _bottomBar(context, inCart, quantity),
              ),
            ],
          );
        }),
      ),
    );
  }
}
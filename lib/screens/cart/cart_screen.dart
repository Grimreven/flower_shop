import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/cart_controller.dart';
import '../../utils/app_colors.dart';
import '../../widgets/product_detail.dart';
import '../../widgets/product_image.dart';
import '../order/order_checkout_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  late final CartController cartController;
  late final AuthController authController;

  @override
  void initState() {
    super.initState();

    cartController = Get.find<CartController>();
    authController = Get.find<AuthController>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      cartController.loadCartFromServer();
    });
  }

  Widget _buildEmptyState(BuildContext context) {
    final Color onSurface = Theme.of(context).colorScheme.onSurface;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 72,
              color:
              isDark ? AppColors.purpleLight : AppColors.mutedForeground,
            ),
            const SizedBox(height: 16),
            Text(
              'Ваша корзина пуста',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Добавьте понравившиеся букеты, чтобы оформить заказ',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark
                    ? AppColors.darkMutedForeground
                    : AppColors.mutedForeground,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _qtyButton({
    required BuildContext context,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurfaceElevated : AppColors.primaryLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : Colors.transparent,
          ),
        ),
        child: Icon(
          icon,
          size: 18,
          color: isDark ? AppColors.purpleLight : AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildItemCard(BuildContext context, dynamic item) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color cardColor = Theme.of(context).cardColor;
    final Color onSurface = Theme.of(context).colorScheme.onSurface;
    final Color borderColor =
    isDark ? AppColors.darkBorder : AppColors.border;
    final Color imageBackground =
    isDark ? AppColors.darkSurfaceSoft : const Color(0xFFF8EFF3);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        gradient: isDark ? AppColors.darkCardGradient : null,
        color: isDark ? null : cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? AppColors.purple.withValues(alpha: 0.05)
                : AppColors.shadow,
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () {
          Get.to(
                () => ProductDetail(
              product: item.product,
              cartController: cartController,
              authController: authController,
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              ProductImage(
                imageUrl: item.product.imageUrl,
                width: 86,
                height: 86,
                fit: BoxFit.cover,
                backgroundColor: imageBackground,
                borderRadius: BorderRadius.circular(18),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ShaderMask(
                      shaderCallback: (Rect bounds) =>
                          (isDark
                              ? AppColors.darkBrandGradient
                              : AppColors.brandGradient)
                              .createShader(bounds),
                      child: Text(
                        '${item.product.price.toStringAsFixed(0)} ₽',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _qtyButton(
                          context: context,
                          icon: Icons.remove,
                          onTap: () {
                            cartController.decrement(item.product);
                          },
                        ),
                        const SizedBox(width: 10),
                        Obx(
                              () => Text(
                            '${item.quantity.value}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: onSurface,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        _qtyButton(
                          context: context,
                          icon: Icons.add,
                          onTap: () {
                            cartController.increment(item.product);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              IconButton(
                onPressed: () {
                  cartController.removeByProduct(item.product);
                },
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: AppColors.danger,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bottomSummary(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color surface = Theme.of(context).colorScheme.surface;
    final Color onSurface = Theme.of(context).colorScheme.onSurface;
    final Color borderColor =
    isDark ? AppColors.darkBorder : AppColors.border;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(28),
        ),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Итого',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: onSurface,
                ),
              ),
              Obx(
                    () => ShaderMask(
                  shaderCallback: (Rect bounds) =>
                      (isDark
                          ? AppColors.darkBrandGradient
                          : AppColors.brandGradient)
                          .createShader(bounds),
                  child: Text(
                    '${cartController.totalPrice.toStringAsFixed(0)} ₽',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient:
              isDark ? AppColors.darkBrandGradient : AppColors.brandGradient,
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
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(54),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: const Text('Перейти к оформлению заказа'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color bg = Theme.of(context).scaffoldBackgroundColor;
    final Color onSurface = Theme.of(context).colorScheme.onSurface;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Text(
          'Корзина',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: onSurface,
          ),
        ),
      ),
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
          if (cartController.isLoading.value) {
            return Center(
              child: CircularProgressIndicator(
                color: isDark ? AppColors.purple : AppColors.primary,
              ),
            );
          }

          if (cartController.items.isEmpty) {
            return _buildEmptyState(context);
          }

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: cartController.items
                      .map((dynamic item) => _buildItemCard(context, item))
                      .toList(),
                ),
              ),
              _bottomSummary(context),
            ],
          );
        }),
      ),
    );
  }
}
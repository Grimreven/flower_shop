import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/order_controller.dart';
import '../../utils/app_colors.dart';
import 'order_detail_screen.dart';

class OrderSuccessScreen extends StatelessWidget {
  const OrderSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final OrderController orderController = Get.find<OrderController>();

    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bg = Theme.of(context).scaffoldBackgroundColor;
    final Color surface = Theme.of(context).colorScheme.surface;
    final Color onSurface = Theme.of(context).colorScheme.onSurface;

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
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 138,
                  height: 138,
                  decoration: BoxDecoration(
                    gradient: isDark ? AppColors.darkCardGradient : null,
                    color: isDark ? null : surface,
                    borderRadius: BorderRadius.circular(36),
                    border: Border.all(color: Colors.transparent),
                    boxShadow: [
                      BoxShadow(
                        color: isDark
                            ? AppColors.purple.withValues(alpha: 0.10)
                            : AppColors.shadow,
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        gradient: isDark
                            ? AppColors.darkBrandGradient
                            : AppColors.brandGradient,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 54,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  'Ваш заказ успешно оформлен!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Мы уже начали собирать ваш букет',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: isDark
                        ? AppColors.darkMutedForeground
                        : AppColors.mutedForeground,
                  ),
                ),
                const SizedBox(height: 36),
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
                    onPressed: () async {
                      if (orderController.orders.isEmpty) {
                        await orderController.fetchUserOrders();
                      }

                      final latestOrder = orderController.getLatestOrder();

                      if (latestOrder != null) {
                        orderController.initializeTrackingForOrder(latestOrder);

                        Get.offAll(
                              () => OrderDetailScreen(order: latestOrder),
                        );
                      } else {
                        Get.offAllNamed('/main', arguments: {'tabIndex': 2});
                      }
                    },
                    icon: const Icon(Icons.local_shipping_rounded),
                    label: const Text('Отследить заказ'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(54),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                TextButton(
                  onPressed: () {
                    Get.offAllNamed('/main', arguments: {'tabIndex': 2});
                  },
                  child: Text(
                    'Перейти к списку заказов',
                    style: TextStyle(
                      color:
                      isDark ? AppColors.purpleLight : AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
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
    final Color muted =
    isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;

    final Map<String, dynamic>? args =
    Get.arguments is Map<String, dynamic> ? Get.arguments : null;

    final String paymentStatusLabel =
        args?['payment_status_label']?.toString() ?? 'Статус уточняется';
    final String paymentMethodTitle =
        args?['payment_method_title']?.toString() ?? 'Способ оплаты не указан';
    final String paymentMethodSubtitle =
        args?['payment_method_subtitle']?.toString() ?? '';

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
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
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
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.border,
                      ),
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
                      color: muted,
                    ),
                  ),
                  const SizedBox(height: 24),
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
                              ? AppColors.purple.withValues(alpha: 0.08)
                              : AppColors.shadow,
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _InfoRow(
                          title: 'Способ оплаты',
                          value: paymentMethodTitle,
                        ),
                        if (paymentMethodSubtitle.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          _InfoRow(
                            title: 'Детали',
                            value: paymentMethodSubtitle,
                          ),
                        ],
                        const SizedBox(height: 10),
                        _InfoRow(
                          title: 'Статус платежа',
                          value: paymentStatusLabel,
                          highlight: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
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
                        color: isDark ? AppColors.purpleLight : AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String title;
  final String value;
  final bool highlight;

  const _InfoRow({
    required this.title,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color onSurface = Theme.of(context).colorScheme.onSurface;
    final Color muted =
    isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: muted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: highlight
                  ? (isDark ? AppColors.purpleLight : AppColors.primary)
                  : onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
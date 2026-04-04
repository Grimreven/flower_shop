import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/order_controller.dart';
import '../../utils/app_colors.dart';
import 'order_detail_screen.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  late final OrderController orderController;

  @override
  void initState() {
    super.initState();
    orderController = Get.find<OrderController>();
    orderController.fetchUserOrders();
  }

  Widget _statusBadge(BuildContext context, String status) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    Color bg = isDark
        ? AppColors.darkSurfaceElevated
        : AppColors.primaryLight;
    Color fg = isDark ? AppColors.purpleLight : AppColors.primary;

    if (status.toLowerCase().contains('достав')) {
      bg = isDark ? const Color(0xFF1C2E24) : const Color(0xFFE9F7EC);
      fg = AppColors.success;
    } else if (status.toLowerCase().contains('собира')) {
      bg = isDark ? const Color(0xFF332914) : const Color(0xFFFFF6E5);
      fg = AppColors.warning;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : Colors.transparent,
        ),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: fg,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    final Color onSurface = Theme.of(context).colorScheme.onSurface;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 72,
              color: isDark ? AppColors.purpleLight : AppColors.mutedForeground,
            ),
            const SizedBox(height: 16),
            Text(
              'У вас пока нет заказов 💐',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Оформите первый заказ, и он появится в этом разделе',
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

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bg = Theme.of(context).scaffoldBackgroundColor;
    final Color cardColor = Theme.of(context).cardColor;
    final Color onSurface = Theme.of(context).colorScheme.onSurface;
    final Color borderColor = isDark ? AppColors.darkBorder : AppColors.border;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Text(
          'Мои заказы',
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
          final orders = orderController.orders;

          if (orders.isEmpty) {
            return _emptyState(context);
          }

          return RefreshIndicator(
            onRefresh: () async {
              await orderController.fetchUserOrders();
            },
            color: isDark ? AppColors.purple : AppColors.primary,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,
              itemBuilder: (BuildContext context, int i) {
                final order = orders[i];

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
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: isDark
                            ? AppColors.darkBrandGradient
                            : AppColors.brandGradient,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: (isDark ? AppColors.purple : AppColors.primary)
                                .withValues(alpha: 0.18),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.receipt_long_rounded,
                        color: Colors.white,
                      ),
                    ),
                    title: Text(
                      'Заказ #${order.id}',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: onSurface,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _statusBadge(context, order.status),
                          const SizedBox(height: 8),
                          Text(
                            'Итого:',
                            style: TextStyle(
                              color: isDark
                                  ? AppColors.darkMutedForeground
                                  : AppColors.mutedForeground,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          ShaderMask(
                            shaderCallback: (Rect bounds) => (isDark
                                ? AppColors.darkBrandGradient
                                : AppColors.brandGradient)
                                .createShader(bounds),
                            child: Text(
                              '${order.total.toStringAsFixed(0)} ₽',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    trailing: Icon(
                      Icons.chevron_right_rounded,
                      color: isDark
                          ? AppColors.purpleLight
                          : AppColors.mutedForeground,
                    ),
                    onTap: () {
                      orderController.initializeTrackingForOrder(order);
                      Get.to(() => OrderDetailScreen(order: order));
                    },
                  ),
                );
              },
            ),
          );
        }),
      ),
    );
  }
}
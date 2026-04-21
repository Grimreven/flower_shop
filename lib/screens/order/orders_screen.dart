import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/order_controller.dart';
import '../../controllers/payment_controller.dart';
import '../../models/order_model.dart';
import '../../models/payment_transaction_model.dart';
import '../../utils/app_colors.dart';
import 'order_detail_screen.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  late final OrderController orderController;
  late final PaymentController paymentController;

  @override
  void initState() {
    super.initState();
    orderController = Get.find<OrderController>();
    paymentController = Get.find<PaymentController>();

    orderController.fetchUserOrders();
    paymentController.loadPaymentTransactions();
  }

  Widget _statusBadge(BuildContext context, String status) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    Color bg = isDark ? AppColors.darkSurfaceElevated : AppColors.primaryLight;
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

  Widget _paymentBadge(
      BuildContext context,
      PaymentTransactionModel? transaction,
      OrderModel order,
      ) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final String status = transaction?.statusLabel ??
        ((order.paymentStatus ?? '').trim().isNotEmpty
            ? order.paymentStatus!
            : 'Статус неизвестен');

    Color bg = isDark ? AppColors.darkSurfaceElevated : AppColors.primaryLight;
    Color fg = isDark ? AppColors.purpleLight : AppColors.primary;

    final String lowered = status.toLowerCase();

    if (lowered.contains('оплачен')) {
      bg = isDark ? const Color(0xFF1C2E24) : const Color(0xFFE9F7EC);
      fg = AppColors.success;
    } else if (lowered.contains('ошибка') || lowered.contains('отмен')) {
      bg = isDark ? const Color(0xFF3A1F22) : const Color(0xFFFDEBEC);
      fg = Colors.redAccent;
    } else if (lowered.contains('ожида')) {
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
              color:
              isDark ? AppColors.purpleLight : AppColors.mutedForeground,
            ),
            const SizedBox(height: 16),
            Text(
              'У вас пока нет заказов',
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

  String _formatDate(dynamic raw) {
    final String value = raw?.toString() ?? '';

    if (value.trim().isEmpty) {
      return 'Дата неизвестна';
    }

    final DateTime? parsed = DateTime.tryParse(value);
    if (parsed == null) {
      return value;
    }

    const List<String> months = [
      'января',
      'февраля',
      'марта',
      'апреля',
      'мая',
      'июня',
      'июля',
      'августа',
      'сентября',
      'октября',
      'ноября',
      'декабря',
    ];

    final String day = parsed.day.toString().padLeft(2, '0');
    final String month = months[parsed.month - 1];
    final String year = parsed.year.toString();
    final String hour = parsed.hour.toString().padLeft(2, '0');
    final String minute = parsed.minute.toString().padLeft(2, '0');

    return '$day $month $year, $hour:$minute';
  }

  String _itemsCountText(OrderModel order) {
    final int count = order.items.fold(
      0,
          (sum, item) => sum + item.quantity,
    );
    return '$count шт.';
  }

  Widget _infoRow(
      BuildContext context,
      String title,
      String value, {
        bool accent = false,
      }) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color onSurface = Theme.of(context).colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: isDark
                    ? AppColors.darkMutedForeground
                    : AppColors.mutedForeground,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: accent
                    ? (isDark ? AppColors.purpleLight : AppColors.primary)
                    : onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  PaymentTransactionModel? _latestPaymentForOrder(int orderId) {
    try {
      final List<PaymentTransactionModel> items =
      paymentController.getPaymentsForOrderLocal(orderId).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      if (items.isEmpty) {
        return null;
      }

      return items.first;
    } catch (_) {
      return null;
    }
  }

  String _paymentMethodText(
      OrderModel order,
      PaymentTransactionModel? transaction,
      ) {
    if (transaction != null &&
        (transaction.paymentMethodTitle ?? '').trim().isNotEmpty) {
      return transaction.paymentMethodTitle!;
    }

    return order.paymentMethod.isEmpty ? 'Не указано' : order.paymentMethod;
  }

  Widget _orderCard(BuildContext context, OrderModel order) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color cardColor = Theme.of(context).cardColor;
    final Color onSurface = Theme.of(context).colorScheme.onSurface;
    final Color borderColor = isDark ? AppColors.darkBorder : AppColors.border;

    final PaymentTransactionModel? latestPayment =
    _latestPaymentForOrder(order.id);

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
          orderController.initializeTrackingForOrder(order);
          Get.to(() => OrderDetailScreen(order: order));
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: isDark
                          ? AppColors.darkBrandGradient
                          : AppColors.brandGradient,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color:
                          (isDark ? AppColors.purple : AppColors.primary)
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
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Заказ #${order.id}',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: onSurface,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDate(order.createdAt),
                          style: TextStyle(
                            color: isDark
                                ? AppColors.darkMutedForeground
                                : AppColors.mutedForeground,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: isDark
                        ? AppColors.purpleLight
                        : AppColors.mutedForeground,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _statusBadge(context, order.status),
                    _paymentBadge(context, latestPayment, order),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _infoRow(context, 'Товаров', _itemsCountText(order)),
              _infoRow(
                context,
                'Сумма товаров',
                '${order.itemsTotal.toStringAsFixed(0)} ₽',
              ),
              _infoRow(
                context,
                'Доставка',
                order.deliveryCost == 0
                    ? 'Бесплатно'
                    : '${order.deliveryCost.toStringAsFixed(0)} ₽',
              ),
              _infoRow(
                context,
                'Оплата',
                _paymentMethodText(order, latestPayment),
              ),
              _infoRow(
                context,
                'Адрес',
                order.deliveryAddress.isEmpty ? 'Не указан' : order.deliveryAddress,
              ),
              if (order.bonusApplied > 0)
                _infoRow(
                  context,
                  'Списано бонусов',
                  '-${order.bonusApplied}',
                  accent: true,
                ),
              _infoRow(
                context,
                'Начислено бонусов',
                '+${order.bonusEarned}',
                accent: true,
              ),
              const SizedBox(height: 6),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Итого',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: onSurface,
                      fontSize: 16,
                    ),
                  ),
                  ShaderMask(
                    shaderCallback: (Rect bounds) =>
                        (isDark
                            ? AppColors.darkBrandGradient
                            : AppColors.brandGradient)
                            .createShader(bounds),
                    child: Text(
                      '${order.total.toStringAsFixed(0)} ₽',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bg = Theme.of(context).scaffoldBackgroundColor;
    final Color onSurface = Theme.of(context).colorScheme.onSurface;

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
              await paymentController.loadPaymentTransactions();
            },
            color: isDark ? AppColors.purple : AppColors.primary,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,
              itemBuilder: (BuildContext context, int index) {
                final OrderModel order = orders[index];
                return _orderCard(context, order);
              },
            ),
          );
        }),
      ),
    );
  }
}
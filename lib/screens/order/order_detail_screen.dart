import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/order_controller.dart';
import '../../controllers/payment_controller.dart';
import '../../helpers/order_tracking_helper.dart';
import '../../models/order_item.dart';
import '../../models/order_model.dart';
import '../../models/payment_transaction_model.dart';
import '../../utils/app_colors.dart';

class OrderDetailScreen extends StatefulWidget {
  final OrderModel order;

  const OrderDetailScreen({
    super.key,
    required this.order,
  });

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  late final OrderController orderController;
  late final PaymentController paymentController;

  @override
  void initState() {
    super.initState();
    orderController = Get.find<OrderController>();
    paymentController = Get.find<PaymentController>();
    orderController.initializeTrackingForOrder(widget.order);
    paymentController.loadPaymentTransactions();
  }

  void _closeTracking() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }

    Get.offAllNamed('/main');
  }

  String _paymentStatusText(PaymentTransactionModel? transaction) {
    if (transaction != null) {
      return transaction.statusLabel;
    }

    if (widget.order.paymentStatus.trim().isNotEmpty) {
      return widget.order.paymentStatus;
    }

    return 'Статус платежа недоступен';
  }

  String _paymentMethodText(PaymentTransactionModel? transaction) {
    if (transaction != null &&
        transaction.paymentMethodTitle != null &&
        transaction.paymentMethodTitle!.trim().isNotEmpty) {
      return transaction.paymentMethodTitle!;
    }

    return widget.order.paymentMethod;
  }

  String _paymentMethodDetails(PaymentTransactionModel? transaction) {
    if (transaction != null &&
        transaction.paymentMethodSubtitle != null &&
        transaction.paymentMethodSubtitle!.trim().isNotEmpty) {
      return transaction.paymentMethodSubtitle!;
    }

    if (widget.order.cardMask.trim().isNotEmpty) {
      return widget.order.cardMask;
    }

    return '';
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }

  Widget _cardWrapper(BuildContext context, Widget child) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color cardColor = Theme.of(context).cardColor;
    final Color borderColor = isDark ? AppColors.darkBorder : AppColors.border;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: isDark ? AppColors.darkCardGradient : null,
        color: isDark ? null : cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? AppColors.purple.withOpacity(0.08)
                : AppColors.shadow,
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }

  String _formatDate(String raw) {
    if (raw.trim().isEmpty) {
      return '—';
    }

    try {
      final DateTime date = DateTime.parse(raw).toLocal();
      final String day = date.day.toString().padLeft(2, '0');
      final String month = date.month.toString().padLeft(2, '0');
      final String year = date.year.toString();
      final String hour = date.hour.toString().padLeft(2, '0');
      final String minute = date.minute.toString().padLeft(2, '0');

      return '$day.$month.$year $hour:$minute';
    } catch (_) {
      return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bg = Theme.of(context).scaffoldBackgroundColor;
    final Color cardColor = Theme.of(context).cardColor;
    final Color onSurface = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        leading: IconButton(
          onPressed: _closeTracking,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(
          'Заказ #${widget.order.id}',
          style: TextStyle(
            color: onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _closeTracking,
            icon: const Icon(Icons.close_rounded),
            tooltip: 'Закрыть',
          ),
        ],
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
          final int currentStepIndex =
          orderController.getTrackingStepIndex(widget.order.id);
          final String currentStatusTitle =
          orderController.getTrackingStatusTitle(widget.order.id);
          final String currentStatusMessage =
          orderController.getTrackingStatusMessage(widget.order.id);
          final bool isDelivered =
          orderController.isOrderDelivered(widget.order.id);
          final String etaText = isDelivered
              ? 'Доставлен'
              : 'До ${orderController.getTrackingEtaText(widget.order.id)}';

          PaymentTransactionModel? latestPayment;
          try {
            final List<PaymentTransactionModel> items =
            paymentController.getPaymentsForOrderLocal(widget.order.id)
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

            if (items.isNotEmpty) {
              latestPayment = items.first;
            }
          } catch (_) {
            latestPayment = null;
          }

          final List<OrderItem> orderItems =
          widget.order.items.whereType<OrderItem>().toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _OrderTrackingHeroCard(
                orderId: widget.order.id.toString(),
                currentStatusTitle: currentStatusTitle,
                currentStatusMessage: currentStatusMessage,
                etaText: etaText,
              ),
              const SizedBox(height: 18),
              _OrderShortInfoCard(
                currentStatus: currentStatusTitle,
                etaText: isDelivered
                    ? 'Заказ уже у получателя'
                    : 'Ориентировочно к ${orderController.getTrackingEtaText(widget.order.id)}',
              ),
              const SizedBox(height: 18),
              _cardWrapper(
                context,
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Оплата',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: onSurface,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _OrderInfoRow(
                      title: 'Способ оплаты',
                      value: _paymentMethodText(latestPayment),
                    ),
                    if (_paymentMethodDetails(latestPayment).isNotEmpty) ...[
                      const SizedBox(height: 10),
                      _OrderInfoRow(
                        title: 'Детали',
                        value: _paymentMethodDetails(latestPayment),
                      ),
                    ],
                    const SizedBox(height: 10),
                    _OrderInfoRow(
                      title: 'Статус платежа',
                      value: _paymentStatusText(latestPayment),
                      highlight: true,
                    ),
                    if (latestPayment?.failureReason != null &&
                        latestPayment!.failureReason!.trim().isNotEmpty) ...[
                      const SizedBox(height: 10),
                      _OrderInfoRow(
                        title: 'Причина',
                        value: latestPayment.failureReason!,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _sectionTitle(context, 'Отслеживание заказа'),
              const SizedBox(height: 14),
              _cardWrapper(
                context,
                Column(
                  children: List.generate(
                    OrderTrackingHelper.steps.length,
                        (int index) {
                      final bool isCompleted = index < currentStepIndex;
                      final bool isActive = index == currentStepIndex;
                      final bool isLast =
                          index == OrderTrackingHelper.steps.length - 1;
                      final step = OrderTrackingHelper.steps[index];

                      return _TimelineStepTile(
                        title: step.title,
                        subtitle: step.message,
                        icon: step.icon,
                        isCompleted: isCompleted,
                        isActive: isActive,
                        isLast: isLast,
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _sectionTitle(context, 'Информация о заказе'),
              const SizedBox(height: 14),
              _cardWrapper(
                context,
                Column(
                  children: [
                    _OrderInfoRow(
                      title: 'Статус заказа',
                      value: widget.order.status.isNotEmpty
                          ? widget.order.status
                          : currentStatusTitle,
                      highlight: true,
                    ),
                    const SizedBox(height: 10),
                    _OrderInfoRow(
                      title: 'Создан',
                      value: _formatDate(widget.order.createdAt),
                    ),
                    const SizedBox(height: 10),
                    _OrderInfoRow(
                      title: 'Адрес доставки',
                      value: widget.order.deliveryAddress.isNotEmpty
                          ? widget.order.deliveryAddress
                          : 'Не указан',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _sectionTitle(context, 'Состав заказа'),
              const SizedBox(height: 12),
              ...orderItems.map(
                    (OrderItem item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _OrderItemCard(item: item),
                ),
              ),
              const SizedBox(height: 10),
              _cardWrapper(
                context,
                Column(
                  children: [
                    _OrderInfoRow(
                      title: 'Товары',
                      value: '${widget.order.itemsTotal.toStringAsFixed(0)} ₽',
                    ),
                    const SizedBox(height: 10),
                    _OrderInfoRow(
                      title: 'Доставка',
                      value: widget.order.deliveryCost == 0
                          ? 'Бесплатно'
                          : '${widget.order.deliveryCost.toStringAsFixed(0)} ₽',
                    ),
                    if (widget.order.bonusApplied > 0) ...[
                      const SizedBox(height: 10),
                      _OrderInfoRow(
                        title: 'Списано бонусов',
                        value: '-${widget.order.bonusApplied}',
                        highlight: true,
                      ),
                    ],
                    if (widget.order.bonusEarned > 0) ...[
                      const SizedBox(height: 10),
                      _OrderInfoRow(
                        title: 'Начислено бонусов',
                        value: '+${widget.order.bonusEarned}',
                        highlight: true,
                      ),
                    ],
                    const Divider(height: 26),
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
                        ShaderMask(
                          shaderCallback: (Rect bounds) =>
                              (isDark
                                  ? AppColors.darkBrandGradient
                                  : AppColors.brandGradient)
                                  .createShader(bounds),
                          child: Text(
                            '${widget.order.total.toStringAsFixed(0)} ₽',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: isDark
                      ? AppColors.darkBrandGradient
                      : AppColors.brandGradient,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: ElevatedButton.icon(
                  onPressed: _closeTracking,
                  icon: const Icon(Icons.close_rounded),
                  label: const Text('Выйти из отслеживания'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 54),
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          );
        }),
      ),
    );
  }
}

class _OrderTrackingHeroCard extends StatelessWidget {
  final String orderId;
  final String currentStatusTitle;
  final String currentStatusMessage;
  final String etaText;

  const _OrderTrackingHeroCard({
    required this.orderId,
    required this.currentStatusTitle,
    required this.currentStatusMessage,
    required this.etaText,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: isDark
            ? AppColors.darkBrandGradient
            : AppColors.brandGradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: (isDark ? AppColors.purple : AppColors.primary)
                .withOpacity(0.20),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.local_shipping_rounded,
            color: Colors.white,
            size: 34,
          ),
          const SizedBox(height: 16),
          Text(
            'Заказ #$orderId',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            currentStatusTitle,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            currentStatusMessage,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.16),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              etaText,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderShortInfoCard extends StatelessWidget {
  final String currentStatus;
  final String etaText;

  const _OrderShortInfoCard({
    required this.currentStatus,
    required this.etaText,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color cardColor = Theme.of(context).cardColor;
    final Color borderColor = isDark ? AppColors.darkBorder : AppColors.border;

    Widget infoItem(String title, String value) {
      return Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? AppColors.darkMutedForeground
                    : AppColors.mutedForeground,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: isDark ? AppColors.darkCardGradient : null,
        color: isDark ? null : cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          infoItem('Статус', currentStatus),
          const SizedBox(width: 12),
          infoItem('Ожидаемое время', etaText),
        ],
      ),
    );
  }
}

class _OrderInfoRow extends StatelessWidget {
  final String title;
  final String value;
  final bool highlight;

  const _OrderInfoRow({
    required this.title,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color onSurface = Theme.of(context).colorScheme.onSurface;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: isDark
                  ? AppColors.darkMutedForeground
                  : AppColors.mutedForeground,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 14,
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

class _TimelineStepTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isCompleted;
  final bool isActive;
  final bool isLast;

  const _TimelineStepTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isCompleted,
    required this.isActive,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final Color activeColor =
    isDark ? AppColors.purpleLight : AppColors.primary;
    final Color lineColor = isCompleted || isActive
        ? activeColor
        : (isDark ? AppColors.darkBorder : AppColors.border);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                gradient: isCompleted || isActive
                    ? (isDark
                    ? AppColors.darkBrandGradient
                    : AppColors.brandGradient)
                    : null,
                color: isCompleted || isActive
                    ? null
                    : (isDark
                    ? AppColors.darkSurfaceSoft
                    : AppColors.primaryLight),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: isCompleted || isActive
                    ? Colors.white
                    : (isDark
                    ? AppColors.darkMutedForeground
                    : AppColors.mutedForeground),
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 42,
                margin: const EdgeInsets.symmetric(vertical: 6),
                color: lineColor,
              ),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.35,
                    color: isDark
                        ? AppColors.darkMutedForeground
                        : AppColors.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _OrderItemCard extends StatelessWidget {
  final OrderItem item;

  const _OrderItemCard({
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color cardColor = Theme.of(context).cardColor;
    final Color borderColor = isDark ? AppColors.darkBorder : AppColors.border;

    final double itemTotal = item.price * item.quantity;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: isDark ? AppColors.darkCardGradient : null,
        color: isDark ? null : cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkSurfaceElevated
                  : AppColors.primaryLight,
              borderRadius: BorderRadius.circular(16),
            ),
            child: item.imageUrl.trim().isNotEmpty
                ? ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                item.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Icon(
                  Icons.local_florist_rounded,
                  color: isDark
                      ? AppColors.purpleLight
                      : AppColors.primary,
                ),
              ),
            )
                : Icon(
              Icons.local_florist_rounded,
              color: isDark ? AppColors.purpleLight : AppColors.primary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${item.quantity} шт. • ${item.price.toStringAsFixed(0)} ₽',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? AppColors.darkMutedForeground
                        : AppColors.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${itemTotal.toStringAsFixed(0)} ₽',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/order_controller.dart';
import '../../controllers/payment_controller.dart';
import '../../helpers/order_tracking_helper.dart';
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

  String _paymentStatusText(PaymentTransactionModel? transaction) {
    if (transaction != null) {
      return transaction.statusLabel;
    }

    if ((widget.order.paymentStatus ?? '').trim().isNotEmpty) {
      return widget.order.paymentStatus!;
    }

    return 'Статус платежа недоступен';
  }

  String _paymentMethodText(PaymentTransactionModel? transaction) {
    if (transaction != null &&
        (transaction.paymentMethodTitle ?? '').trim().isNotEmpty) {
      return transaction.paymentMethodTitle!;
    }

    return widget.order.paymentMethod;
  }

  String _paymentMethodDetails(PaymentTransactionModel? transaction) {
    if (transaction != null &&
        (transaction.paymentMethodSubtitle ?? '').trim().isNotEmpty) {
      return transaction.paymentMethodSubtitle!;
    }

    if ((widget.order.cardMask ?? '').trim().isNotEmpty) {
      return widget.order.cardMask!;
    }

    return '';
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bg = Theme.of(context).scaffoldBackgroundColor;
    final Color cardColor = Theme.of(context).cardColor;
    final Color onSurface = Theme.of(context).colorScheme.onSurface;
    final Color muted =
    isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Text(
          'Заказ #${widget.order.id}',
          style: TextStyle(
            color: onSurface,
            fontWeight: FontWeight.w700,
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
                order: widget.order,
                currentStatus: currentStatusTitle,
                etaText: isDelivered
                    ? 'Заказ уже у получателя'
                    : 'Ориентировочно к ${orderController.getTrackingEtaText(widget.order.id)}',
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: isDark ? AppColors.darkCardGradient : null,
                  color: isDark ? null : cardColor,
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
              Text(
                'Отслеживание заказа',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: onSurface,
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: isDark ? AppColors.darkCardGradient : null,
                  color: isDark ? null : cardColor,
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
              Text(
                'Состав заказа',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: onSurface,
                ),
              ),
              const SizedBox(height: 12),
              ...widget.order.items.map((item) => _OrderItemCard(item: item)),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  gradient: isDark ? AppColors.darkCardGradient : null,
                  color: isDark ? null : cardColor,
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
                padding: const EdgeInsets.all(18),
                child: Column(
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
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkSurfaceElevated
                      : AppColors.primaryLight.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color:
                      isDark ? AppColors.purpleLight : AppColors.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Это демонстрационный экран отслеживания заказа. Он показывает жизненный цикл заказа и платёжной операции: способ оплаты, статус платежа и этапы доставки.',
                        style: TextStyle(
                          color: muted,
                          height: 1.45,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
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
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: Theme.of(context).brightness == Brightness.dark
            ? AppColors.darkBrandGradient
            : AppColors.brandGradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: ((Theme.of(context).brightness == Brightness.dark
                ? AppColors.purple
                : AppColors.primary))
                .withValues(alpha: 0.20),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.local_shipping_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Заказ #$orderId',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  currentStatusTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  currentStatusMessage,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.92),
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    etaText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderShortInfoCard extends StatelessWidget {
  final OrderModel order;
  final String currentStatus;
  final String etaText;

  const _OrderShortInfoCard({
    required this.order,
    required this.currentStatus,
    required this.etaText,
  });

  String _formatCreatedAt(dynamic value) {
    if (value == null) {
      return '—';
    }

    final DateTime? date = value is DateTime
        ? value
        : DateTime.tryParse(value.toString());

    if (date == null) {
      return value.toString();
    }

    final String day = date.day.toString().padLeft(2, '0');
    final String month = date.month.toString().padLeft(2, '0');
    final String year = date.year.toString();

    return '$day.$month.$year';
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color cardColor = Theme.of(context).cardColor;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: isDark ? AppColors.darkCardGradient : null,
        color: isDark ? null : cardColor,
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
          _OrderInfoRow(
            title: 'Статус заказа',
            value: currentStatus,
            highlight: true,
          ),
          const SizedBox(height: 10),
          _OrderInfoRow(
            title: 'Доставка',
            value: etaText,
          ),
          const SizedBox(height: 10),
          _OrderInfoRow(
            title: 'Адрес',
            value: order.deliveryAddress,
          ),
          const SizedBox(height: 10),
          _OrderInfoRow(
            title: 'Дата создания',
            value: _formatCreatedAt(order.createdAt),
          ),
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
    final Color muted =
    isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;

    final bool highlighted = isCompleted || isActive;
    final Color accent =
    isDark ? AppColors.purpleLight : AppColors.primary;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: highlighted
                      ? (isDark
                      ? AppColors.darkBrandGradient
                      : AppColors.brandGradient)
                      : null,
                  color: highlighted
                      ? null
                      : (isDark
                      ? AppColors.darkSurfaceSoft
                      : AppColors.primaryLight.withValues(alpha: 0.55)),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: highlighted
                      ? Colors.white
                      : (isDark
                      ? AppColors.purpleLight
                      : AppColors.primary),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    color: highlighted
                        ? accent.withValues(alpha: 0.55)
                        : muted.withValues(alpha: 0.25),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 6, bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: highlighted
                          ? Theme.of(context).colorScheme.onSurface
                          : muted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.35,
                      color: muted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderItemCard extends StatelessWidget {
  final dynamic item;

  const _OrderItemCard({
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color cardColor = Theme.of(context).cardColor;
    final Color onSurface = Theme.of(context).colorScheme.onSurface;
    final Color muted =
    isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;

    final String imageUrl = item.imageUrl?.toString() ?? '';
    final String title = item.name?.toString() ?? 'Товар';
    final int quantity = item.quantity is int ? item.quantity as int : 1;
    final double price =
    item.price is num ? (item.price as num).toDouble() : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: isDark ? AppColors.darkCardGradient : null,
        color: isDark ? null : cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.border,
        ),
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
          Container(
            width: 76,
            height: 76,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: isDark
                  ? AppColors.darkSurfaceElevated
                  : AppColors.primaryLight.withValues(alpha: 0.45),
            ),
            child: imageUrl.isNotEmpty
                ? Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Icon(
                Icons.local_florist_rounded,
                color: isDark
                    ? AppColors.purpleLight
                    : AppColors.primary,
                size: 34,
              ),
            )
                : Icon(
              Icons.local_florist_rounded,
              color: isDark
                  ? AppColors.purpleLight
                  : AppColors.primary,
              size: 34,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Количество: $quantity',
                  style: TextStyle(
                    color: muted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${price.toStringAsFixed(0)} ₽',
                  style: TextStyle(
                    color: isDark
                        ? AppColors.purpleLight
                        : AppColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
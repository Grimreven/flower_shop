import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/order_controller.dart';
import '../../helpers/order_tracking_helper.dart';
import '../../models/order_item.dart';
import '../../models/order_model.dart';
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

  @override
  void initState() {
    super.initState();
    orderController = Get.find<OrderController>();
    orderController.initializeTrackingForOrder(widget.order);
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

  Widget _infoRow(
      BuildContext context,
      String title,
      String value, {
        bool highlight = false,
      }) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color onSurface = Theme.of(context).colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
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
      ),
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

  String _statusLabelFromOrder(OrderModel order) {
    if (order.status.trim().isNotEmpty) {
      return order.status;
    }
    return orderController.getTrackingStatusTitle(order.id);
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
              const SizedBox(height: 20),
              _sectionTitle(context, 'Отслеживание заказа'),
              const SizedBox(height: 14),
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
                          ? AppColors.purple.withOpacity(0.08)
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
              _sectionTitle(context, 'Информация о заказе'),
              const SizedBox(height: 14),
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
                          ? AppColors.purple.withOpacity(0.08)
                          : AppColors.shadow,
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _infoRow(
                      context,
                      'Статус заказа',
                      _statusLabelFromOrder(widget.order),
                      highlight: true,
                    ),
                    _infoRow(
                      context,
                      'Создан',
                      _formatDate(widget.order.createdAt),
                    ),
                    _infoRow(
                      context,
                      'Способ оплаты',
                      widget.order.paymentMethod.isNotEmpty
                          ? widget.order.paymentMethod
                          : 'Не указан',
                    ),
                    if (widget.order.paymentStatus.isNotEmpty)
                      _infoRow(
                        context,
                        'Статус оплаты',
                        widget.order.paymentStatus,
                        highlight: widget.order.paymentStatus == 'Оплачено',
                      ),
                    if (widget.order.cardMask.isNotEmpty)
                      _infoRow(
                        context,
                        'Карта',
                        widget.order.cardMask,
                      ),
                    _infoRow(
                      context,
                      'Адрес доставки',
                      widget.order.deliveryAddress.isNotEmpty
                          ? widget.order.deliveryAddress
                          : 'Не указан',
                    ),
                    _infoRow(
                      context,
                      'Стоимость товаров',
                      '${widget.order.itemsTotal.toStringAsFixed(0)} ₽',
                    ),
                    _infoRow(
                      context,
                      'Доставка',
                      widget.order.deliveryCost == 0
                          ? 'Бесплатно'
                          : '${widget.order.deliveryCost.toStringAsFixed(0)} ₽',
                    ),
                    if (widget.order.bonusApplied > 0)
                      _infoRow(
                        context,
                        'Списано бонусов',
                        '-${widget.order.bonusApplied}',
                      ),
                    _infoRow(
                      context,
                      'Начислено бонусов',
                      '+${widget.order.bonusEarned}',
                    ),
                    _infoRow(
                      context,
                      'Итого',
                      '${widget.order.total.toStringAsFixed(0)} ₽',
                      highlight: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _sectionTitle(context, 'Состав заказа'),
              const SizedBox(height: 12),
              ...widget.order.items.map((item) => _OrderItemCard(item: item)),
              const SizedBox(height: 10),
              Container(
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
                padding: const EdgeInsets.all(18),
                child: Row(
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
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkSurfaceElevated
                      : AppColors.primaryLight.withOpacity(0.55),
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
                        'Это демонстрационный экран отслеживания заказа. '
                            'Он показывает статус, состав заказа, оплату и ориентировочное время доставки.',
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.4,
                          color: isDark
                              ? AppColors.darkMutedForeground
                              : AppColors.mutedForeground,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: isDark ? AppColors.darkBrandGradient : AppColors.brandGradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: (isDark ? AppColors.purple : AppColors.primary)
                .withOpacity(0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.14),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.local_shipping_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Заказ #$orderId',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  currentStatusTitle,
                  style: const TextStyle(
                    fontSize: 22,
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  currentStatusMessage,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.14),
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
  final String currentStatus;
  final String etaText;

  const _OrderShortInfoCard({
    required this.currentStatus,
    required this.etaText,
  });

  Widget _infoCell(
      BuildContext context, {
        required IconData icon,
        required String label,
        required String value,
      }) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color onSurface = Theme.of(context).colorScheme.onSurface;
    final Color muted =
    isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.darkSurfaceElevated
              : AppColors.primaryLight.withOpacity(0.5),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              size: 18,
              color: isDark ? AppColors.purpleLight : AppColors.primary,
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: muted,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: onSurface,
                fontWeight: FontWeight.w700,
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
      child: Row(
        children: [
          _infoCell(
            context,
            icon: Icons.flag_rounded,
            label: 'Статус',
            value: currentStatus,
          ),
          const SizedBox(width: 12),
          _infoCell(
            context,
            icon: Icons.schedule_rounded,
            label: 'Ожидание',
            value: etaText,
          ),
        ],
      ),
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
    final Color onSurface = Theme.of(context).colorScheme.onSurface;
    final Color muted =
    isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;

    final Color accentColor = isCompleted || isActive
        ? (isDark ? AppColors.purpleLight : AppColors.primary)
        : (isDark ? AppColors.darkBorderSoft : AppColors.border);

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 42,
            child: Column(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: isCompleted || isActive
                        ? accentColor.withOpacity(isDark ? 0.18 : 0.10)
                        : (isDark
                        ? AppColors.darkSurfaceElevated
                        : AppColors.primaryLight),
                    shape: BoxShape.circle,
                    border: Border.all(color: accentColor),
                  ),
                  child: Icon(
                    isCompleted ? Icons.check_rounded : icon,
                    color: accentColor,
                    size: 20,
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 34,
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    color: accentColor.withOpacity(0.5),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
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
  final OrderItem item;

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
    final Color borderColor = isDark ? AppColors.darkBorder : AppColors.border;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: isDark ? AppColors.darkCardGradient : null,
        color: isDark ? null : cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? AppColors.purple.withOpacity(0.08)
                : AppColors.shadow,
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: item.imageUrl.isNotEmpty
                ? Image.network(
              item.imageUrl,
              width: 82,
              height: 82,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 82,
                height: 82,
                color: isDark
                    ? AppColors.darkSurfaceSoft
                    : AppColors.primaryLight,
                alignment: Alignment.center,
                child: Icon(
                  Icons.image_not_supported_outlined,
                  color: isDark
                      ? AppColors.purpleLight
                      : AppColors.primary,
                ),
              ),
            )
                : Container(
              width: 82,
              height: 82,
              color: isDark
                  ? AppColors.darkSurfaceSoft
                  : AppColors.primaryLight,
              alignment: Alignment.center,
              child: Icon(
                Icons.local_florist_rounded,
                color:
                isDark ? AppColors.purpleLight : AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Количество: ${item.quantity}',
                  style: TextStyle(
                    fontSize: 13,
                    color: muted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${item.price.toStringAsFixed(0)} ₽',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: isDark ? AppColors.purpleLight : AppColors.primary,
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
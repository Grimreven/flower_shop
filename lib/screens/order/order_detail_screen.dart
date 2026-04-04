import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/order_controller.dart';
import '../../helpers/order_tracking_helper.dart';
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

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bg = Theme.of(context).scaffoldBackgroundColor;
    final Color cardColor = Theme.of(context).cardColor;
    final Color onSurface = Theme.of(context).colorScheme.onSurface;
    final Color muted = isDark
        ? AppColors.darkMutedForeground
        : AppColors.mutedForeground;

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
                order: widget.order,
                currentStatus: currentStatusTitle,
                etaText: isDelivered
                    ? 'Заказ уже у получателя'
                    : 'Ориентировочно к ${orderController.getTrackingEtaText(widget.order.id)}',
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
                  border: Border.all(color: Colors.transparent),
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
                  border: Border.all(color: Colors.transparent),
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
                      shaderCallback: (Rect bounds) => (isDark
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
                      : AppColors.primaryLight.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: isDark ? AppColors.purpleLight : AppColors.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Это демонстрационный экран отслеживания заказа. Статусы переключаются автоматически без backend.',
                        style: TextStyle(
                          color: muted,
                          fontSize: 14,
                          height: 1.45,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
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
                  onPressed: () {
                    Get.offAllNamed('/main', arguments: {'tabIndex': 2});
                  },
                  icon: const Icon(Icons.receipt_long_rounded),
                  label: const Text('Назад к заказам'),
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
              const SizedBox(height: 8),
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
                .withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              'Заказ #$orderId',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Текущий статус',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            currentStatusTitle,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              height: 1.1,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            currentStatusMessage,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              height: 1.45,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.schedule_rounded,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Ожидаемое время: $etaText',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
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

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color cardColor = Theme.of(context).cardColor;
    final Color onSurface = Theme.of(context).colorScheme.onSurface;
    final Color muted = isDark
        ? AppColors.darkMutedForeground
        : AppColors.mutedForeground;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: isDark ? AppColors.darkCardGradient : null,
        color: isDark ? null : cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.transparent),
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
            label: 'Номер заказа',
            value: '#${order.id}',
            onSurface: onSurface,
            muted: muted,
          ),
          const SizedBox(height: 14),
          _InfoRow(
            label: 'Текущий статус',
            value: currentStatus,
            onSurface: onSurface,
            muted: muted,
          ),
          const SizedBox(height: 14),
          _InfoRow(
            label: 'Доставка',
            value: etaText,
            onSurface: onSurface,
            muted: muted,
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color onSurface;
  final Color muted;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.onSurface,
    required this.muted,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: muted,
              fontSize: 14,
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
              color: onSurface,
              fontSize: 14,
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
    final Color onSurface = Theme.of(context).colorScheme.onSurface;
    final Color muted = isDark
        ? AppColors.darkMutedForeground
        : AppColors.mutedForeground;

    final Color inactiveCircle = isDark
        ? AppColors.darkSurfaceSoft
        : const Color(0xFFF3EDF8);

    final Color inactiveLine = isDark
        ? AppColors.darkBorderSoft
        : const Color(0xFFE7DEF3);

    final Gradient activeGradient =
    isDark ? AppColors.darkBrandGradient : AppColors.brandGradient;

    return IntrinsicHeight(
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
                    gradient: isActive ? activeGradient : null,
                    color: isCompleted
                        ? (isDark ? AppColors.purple : AppColors.primary)
                        : inactiveCircle,
                    shape: BoxShape.circle,
                    boxShadow: isActive
                        ? [
                      BoxShadow(
                        color: (isDark ? AppColors.purple : AppColors.primary)
                            .withValues(alpha: 0.25),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ]
                        : null,
                  ),
                  child: Icon(
                    isCompleted ? Icons.check_rounded : icon,
                    color: isCompleted || isActive
                        ? Colors.white
                        : (isDark ? AppColors.purpleLight : AppColors.primary),
                    size: 20,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 3,
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        gradient: isCompleted ? activeGradient : null,
                        color: isCompleted ? null : inactiveLine,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isActive
                      ? (isDark
                      ? AppColors.darkSurfaceElevated
                      : AppColors.primaryLight.withValues(alpha: 0.65))
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: muted,
                        fontSize: 14,
                        height: 1.45,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
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
    final Color muted = isDark
        ? AppColors.darkMutedForeground
        : AppColors.mutedForeground;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.transparent),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? AppColors.purple.withValues(alpha: 0.05)
                : AppColors.shadow.withValues(alpha: 0.7),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          vertical: 10,
          horizontal: 14,
        ),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Container(
            color: isDark
                ? AppColors.darkSurfaceSoft
                : const Color(0xFFF8EFF3),
            child: Image.network(
              item.imageUrl,
              width: 62,
              height: 62,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Icon(
                Icons.image_not_supported_outlined,
                color: isDark ? AppColors.purple : AppColors.primary,
              ),
            ),
          ),
        ),
        title: Text(
          item.name,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: onSurface,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            'Количество: ${item.quantity}',
            style: TextStyle(
              color: muted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        trailing: ShaderMask(
          shaderCallback: (Rect bounds) => (isDark
              ? AppColors.darkBrandGradient
              : AppColors.brandGradient)
              .createShader(bounds),
          child: Text(
            '${(item.price * item.quantity).toStringAsFixed(0)} ₽',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
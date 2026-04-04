import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/cart_controller.dart';
import '../../controllers/order_controller.dart';
import '../../models/cart_item.dart' as model;
import '../../utils/app_colors.dart';
import 'order_success_screen.dart';

class OrderCheckoutScreen extends StatefulWidget {
  const OrderCheckoutScreen({super.key});

  @override
  State<OrderCheckoutScreen> createState() => _OrderCheckoutScreenState();
}

class _OrderCheckoutScreenState extends State<OrderCheckoutScreen> {
  final CartController cartController = Get.find<CartController>();
  final AuthController authController = Get.find<AuthController>();
  final OrderController orderController = Get.find<OrderController>();

  String paymentMethod = 'Наличный расчёт';
  String address = '';
  String promoCode = '';
  int bonusToUse = 0;
  bool canUseBonus = false;

  @override
  void initState() {
    super.initState();
    address = authController.user.value?.address ?? '';
  }

  Widget _sectionTitle(BuildContext context, String title) {
    final Color onSurface = Theme.of(context).colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: onSurface,
        ),
      ),
    );
  }

  Widget _block(BuildContext context, {required Widget child}) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color cardColor = Theme.of(context).cardColor;
    final Color borderColor = isDark ? AppColors.darkBorder : AppColors.border;

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(16),
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
      child: child,
    );
  }

  Future<void> _confirmOrder() async {
    if (cartController.items.isEmpty) {
      Get.snackbar('Ошибка', 'Корзина пуста');
      return;
    }

    if (address.trim().isEmpty) {
      Get.snackbar('Ошибка', 'Введите адрес доставки');
      return;
    }

    try {
      final List<model.CartItem> items = cartController.items
          .map(
            (e) => model.CartItem(
          product: e.product,
          quantity: e.quantity.value,
        ),
      )
          .toList();

      await orderController.createOrder(
        items,
        bonusToUse: bonusToUse,
      );

      if (bonusToUse > 0) {
        authController.updateLoyaltyPoints(-bonusToUse);
      }

      Get.offAll(() => const OrderSuccessScreen());
    } catch (e) {
      Get.snackbar(
        'Ошибка',
        'Не удалось оформить заказ: $e',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bg = Theme.of(context).scaffoldBackgroundColor;
    final Color onSurface = Theme.of(context).colorScheme.onSurface;

    final double total = cartController.totalPrice;
    final int bonusPoints = authController.user.value?.loyaltyPoints ?? 0;
    canUseBonus = total >= 750 && bonusPoints > 0;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Text(
          'Оформление заказа',
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _block(
                context,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle(context, 'Ваш заказ'),
                    ...cartController.items.map(
                          (item) => Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkSurfaceElevated
                              : AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark
                                ? AppColors.darkBorder
                                : Colors.transparent,
                          ),
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                color: isDark
                                    ? AppColors.darkSurfaceSoft
                                    : const Color(0xFFF8EFF3),
                                child: Image.network(
                                  item.product.imageUrl,
                                  width: 56,
                                  height: 56,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Icon(
                                    Icons.image_not_supported_outlined,
                                    color: isDark
                                        ? AppColors.purple
                                        : AppColors.primary,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.product.name,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${item.product.price.toStringAsFixed(0)} ₽ × ${item.quantity.value}',
                                    style: TextStyle(
                                      color: isDark
                                          ? AppColors.darkMutedForeground
                                          : AppColors.mutedForeground,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ShaderMask(
                              shaderCallback: (Rect bounds) => (isDark
                                  ? AppColors.darkBrandGradient
                                  : AppColors.brandGradient)
                                  .createShader(bounds),
                              child: Text(
                                '${(item.product.price * item.quantity.value).toStringAsFixed(0)} ₽',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              _block(
                context,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle(context, 'Адрес доставки'),
                    TextFormField(
                      initialValue: address,
                      onChanged: (String v) => address = v,
                      decoration: InputDecoration(
                        hintText: 'Введите адрес доставки',
                        prefixIcon: Icon(
                          Icons.location_on_outlined,
                          color: isDark
                              ? AppColors.purpleLight
                              : AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              _block(
                context,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle(context, 'Способ оплаты'),
                    DropdownButtonFormField<String>(
                      value: paymentMethod,
                      items: const [
                        DropdownMenuItem(
                          value: 'Наличный расчёт',
                          child: Text('Наличный расчёт'),
                        ),
                        DropdownMenuItem(
                          value: 'Безналичный расчёт',
                          child: Text('Безналичный расчёт'),
                        ),
                      ],
                      onChanged: (String? v) {
                        if (v == null) {
                          return;
                        }

                        setState(() {
                          paymentMethod = v;
                        });
                      },
                      decoration: const InputDecoration(),
                    ),
                  ],
                ),
              ),
              _block(
                context,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle(context, 'Оплата бонусами'),
                    if (!canUseBonus)
                      Text(
                        'Бонусами можно оплатить заказ от 750 ₽',
                        style: TextStyle(
                          color: isDark
                              ? AppColors.darkMutedForeground
                              : AppColors.mutedForeground,
                        ),
                      )
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: isDark
                                  ? AppColors.purple
                                  : AppColors.primary,
                              thumbColor: isDark
                                  ? AppColors.purple
                                  : AppColors.primary,
                              inactiveTrackColor: isDark
                                  ? AppColors.darkBorderSoft
                                  : AppColors.primaryLight,
                              overlayColor: (isDark
                                  ? AppColors.purple
                                  : AppColors.primary)
                                  .withValues(alpha: 0.15),
                            ),
                            child: Slider(
                              value: bonusToUse.toDouble(),
                              min: 0,
                              max: bonusPoints.toDouble(),
                              divisions: bonusPoints > 0 ? bonusPoints : 1,
                              label: '$bonusToUse',
                              onChanged: (double v) {
                                setState(() {
                                  bonusToUse = v.toInt();
                                });
                              },
                            ),
                          ),
                          Text(
                            'Использовать: $bonusToUse / $bonusPoints бонусов',
                            style: TextStyle(
                              color: onSurface,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              _block(
                context,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle(context, 'Промокод'),
                    TextField(
                      onChanged: (String v) => promoCode = v,
                      decoration: InputDecoration(
                        hintText: 'Введите промокод',
                        prefixIcon: Icon(
                          Icons.discount_outlined,
                          color: isDark
                              ? AppColors.purpleLight
                              : AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: isDark
                      ? AppColors.darkBrandGradient
                      : AppColors.brandGradient,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: (isDark ? AppColors.purple : AppColors.primary)
                          .withValues(alpha: 0.18),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Итого',
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${(cartController.totalPrice - bonusToUse).toStringAsFixed(0)} ₽',
                      style: const TextStyle(
                        fontSize: 22,
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
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
                child: ElevatedButton(
                  onPressed: _confirmOrder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(54),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: const Text('Оформить заказ'),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
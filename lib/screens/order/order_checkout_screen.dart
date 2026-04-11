import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/address_book_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/cart_controller.dart';
import '../../controllers/order_controller.dart';
import '../../models/cart_item.dart' as model;
import '../../models/checkout_summary.dart';
import '../../models/delivery_method.dart';
import '../../models/user_address.dart';
import '../../utils/app_colors.dart';
import '../../utils/loyalty_rules.dart';
import 'order_success_screen.dart';

class OrderCheckoutScreen extends StatefulWidget {
  const OrderCheckoutScreen({super.key});

  @override
  State<OrderCheckoutScreen> createState() => _OrderCheckoutScreenState();
}

class _OrderCheckoutScreenState extends State<OrderCheckoutScreen> {
  final CartController cartController = Get.find();
  final AuthController authController = Get.find();
  final OrderController orderController = Get.find();
  final AddressBookController addressBookController = Get.find();

  String paymentMethod = 'Наличный расчёт';
  String promoCode = '';
  String recipientComment = '';
  int bonusToUse = 0;
  DeliveryMethod deliveryMethod = DeliveryMethod.delivery;

  static const String _pickupStoreAddress =
      'г. Москва, ул. Ленина, д. 15, Flowers Shop';

  @override
  void initState() {
    super.initState();
    addressBookController.syncPrimaryFromProfileIfNeeded();
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

  Widget _summaryRow(
      BuildContext context, {
        required String label,
        required String value,
        bool highlight = false,
        bool negative = false,
      }) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color onSurface = Theme.of(context).colorScheme.onSurface;
    final Color muted =
    isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: highlight ? onSurface : muted,
                fontWeight: highlight ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: negative
                  ? Colors.redAccent
                  : (highlight ? onSurface : muted),
              fontWeight: highlight ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmOrder(CheckoutSummary summary) async {
    if (cartController.items.isEmpty) {
      Get.snackbar('Ошибка', 'Корзина пуста');
      return;
    }

    String deliveryAddress = '';

    if (deliveryMethod == DeliveryMethod.delivery) {
      final UserAddress? selected = addressBookController.selectedAddress;
      if (selected == null) {
        Get.snackbar('Ошибка', 'Выберите адрес доставки');
        return;
      }
      deliveryAddress = selected.fullAddress;
    } else {
      deliveryAddress = _pickupStoreAddress;
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
        summary: summary,
        paymentMethod: paymentMethod,
        deliveryAddress: deliveryAddress,
        recipientComment: recipientComment.trim(),
        promoCode: promoCode.trim(),
      );

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

  Future<void> _showAddAddressSheet() async {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController addressController = TextEditingController();
    final TextEditingController entranceController = TextEditingController();
    final TextEditingController floorController = TextEditingController();
    final TextEditingController apartmentController = TextEditingController();
    final TextEditingController commentController = TextEditingController();
    bool isPrimary = false;

    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bg = Theme.of(context).scaffoldBackgroundColor;
    final Color onSurface = Theme.of(context).colorScheme.onSurface;
    final Color muted =
    isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter modalSetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Новый адрес',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: onSurface,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: titleController,
                      style: TextStyle(color: onSurface),
                      decoration: const InputDecoration(
                        labelText: 'Название адреса',
                        hintText: 'Дом, Работа, Для мамы',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: addressController,
                      style: TextStyle(color: onSurface),
                      decoration: const InputDecoration(
                        labelText: 'Адрес',
                        hintText: 'Улица, дом, корпус',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: entranceController,
                            style: TextStyle(color: onSurface),
                            decoration: const InputDecoration(
                              labelText: 'Подъезд',
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: floorController,
                            style: TextStyle(color: onSurface),
                            decoration: const InputDecoration(
                              labelText: 'Этаж',
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: apartmentController,
                            style: TextStyle(color: onSurface),
                            decoration: const InputDecoration(
                              labelText: 'Квартира',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: commentController,
                      style: TextStyle(color: onSurface),
                      decoration: const InputDecoration(
                        labelText: 'Комментарий',
                        hintText: 'Позвонить за 10 минут',
                      ),
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      value: isPrimary,
                      activeColor: isDark ? AppColors.purple : AppColors.primary,
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'Сделать основным',
                        style: TextStyle(
                          color: onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        'Будет подставляться по умолчанию',
                        style: TextStyle(color: muted),
                      ),
                      onChanged: (bool value) {
                        modalSetState(() {
                          isPrimary = value;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: isDark
                              ? AppColors.darkBrandGradient
                              : AppColors.brandGradient,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: ElevatedButton(
                          onPressed: () {
                            if (addressController.text.trim().isEmpty) {
                              Get.snackbar('Ошибка', 'Введите адрес');
                              return;
                            }

                            addressBookController.addAddress(
                              UserAddress(
                                id: 0,
                                title: titleController.text.trim().isEmpty
                                    ? 'Новый адрес'
                                    : titleController.text.trim(),
                                address: addressController.text.trim(),
                                entrance: entranceController.text.trim(),
                                floor: floorController.text.trim(),
                                apartment: apartmentController.text.trim(),
                                comment: commentController.text.trim(),
                                isPrimary: isPrimary,
                              ),
                            );

                            Navigator.of(context).pop();
                            setState(() {});
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            shadowColor: Colors.transparent,
                            minimumSize: const Size.fromHeight(52),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: const Text('Сохранить адрес'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDeliveryMethodSelector(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color onSurface = Theme.of(context).colorScheme.onSurface;
    final Color border = isDark ? AppColors.darkBorder : AppColors.border;

    Widget methodCard({
      required DeliveryMethod method,
      required IconData icon,
      required String title,
      required String subtitle,
    }) {
      final bool selected = deliveryMethod == method;

      return Expanded(
        child: GestureDetector(
          onTap: () {
            setState(() {
              deliveryMethod = method;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: selected
                  ? (isDark
                  ? AppColors.darkBrandGradient
                  : AppColors.brandGradient)
                  : null,
              color: selected
                  ? null
                  : (isDark ? AppColors.darkSurfaceElevated : Colors.white),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: selected ? Colors.transparent : border,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  icon,
                  color: selected
                      ? Colors.white
                      : (isDark ? AppColors.purpleLight : AppColors.primary),
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  style: TextStyle(
                    color: selected ? Colors.white : onSurface,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: selected
                        ? Colors.white.withValues(alpha: 0.88)
                        : (isDark
                        ? AppColors.darkMutedForeground
                        : AppColors.mutedForeground),
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return _block(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(context, 'Способ получения'),
          Row(
            children: [
              methodCard(
                method: DeliveryMethod.delivery,
                icon: Icons.local_shipping_outlined,
                title: 'Доставка',
                subtitle: 'Привезём по указанному адресу',
              ),
              const SizedBox(width: 12),
              methodCard(
                method: DeliveryMethod.pickup,
                icon: Icons.storefront_outlined,
                title: 'Самовывоз',
                subtitle: 'Забрать заказ из магазина',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddressesBlock(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color onSurface = Theme.of(context).colorScheme.onSurface;
    final Color muted =
    isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
    final Color border = isDark ? AppColors.darkBorder : AppColors.border;

    if (deliveryMethod == DeliveryMethod.pickup) {
      return _block(
        context,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle(context, 'Пункт самовывоза'),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurfaceElevated : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: border),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.store_mall_directory_outlined,
                    color: isDark ? AppColors.purpleLight : AppColors.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Flowers Shop',
                          style: TextStyle(
                            color: onSurface,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _pickupStoreAddress,
                          style: TextStyle(
                            color: muted,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Ежедневно: 09:00–21:00',
                          style: TextStyle(
                            color: muted,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Obx(() {
      final List<UserAddress> addresses = addressBookController.addresses;

      return _block(
        context,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle(context, 'Адрес доставки'),
            if (addresses.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurfaceElevated : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'У вас пока нет сохранённых адресов',
                      style: TextStyle(
                        color: onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Добавьте адрес доставки, чтобы продолжить оформление заказа.',
                      style: TextStyle(color: muted, height: 1.4),
                    ),
                    const SizedBox(height: 14),
                    OutlinedButton.icon(
                      onPressed: _showAddAddressSheet,
                      icon: const Icon(Icons.add_location_alt_outlined),
                      label: const Text('Добавить адрес'),
                    ),
                  ],
                ),
              )
            else ...[
              ...addresses.map((UserAddress address) {
                final bool selected =
                    addressBookController.selectedAddressId.value == address.id;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    gradient: selected
                        ? (isDark
                        ? AppColors.darkBrandGradient
                        : AppColors.brandGradient)
                        : null,
                    color: selected
                        ? null
                        : (isDark ? AppColors.darkSurfaceElevated : Colors.white),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: selected ? Colors.transparent : border,
                    ),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () {
                      addressBookController.selectAddress(address.id);
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Radio<int>(
                            value: address.id,
                            groupValue:
                            addressBookController.selectedAddressId.value,
                            activeColor:
                            isDark ? AppColors.purpleLight : AppColors.primary,
                            onChanged: (int? value) {
                              if (value == null) return;
                              addressBookController.selectAddress(value);
                            },
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Text(
                                      address.title,
                                      style: TextStyle(
                                        color: selected ? Colors.white : onSurface,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    if (address.isPrimary)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: selected
                                              ? Colors.white.withValues(alpha: 0.16)
                                              : (isDark
                                              ? AppColors.darkSurfaceSoft
                                              : AppColors.primaryLight),
                                          borderRadius:
                                          BorderRadius.circular(999),
                                        ),
                                        child: Text(
                                          'Основной',
                                          style: TextStyle(
                                            color: selected
                                                ? Colors.white
                                                : (isDark
                                                ? AppColors.purpleLight
                                                : AppColors.primary),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  address.fullAddress,
                                  style: TextStyle(
                                    color: selected
                                        ? Colors.white.withValues(alpha: 0.92)
                                        : muted,
                                    height: 1.4,
                                  ),
                                ),
                                if (address.comment.trim().isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    address.comment,
                                    style: TextStyle(
                                      color: selected
                                          ? Colors.white.withValues(alpha: 0.82)
                                          : muted,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    if (!address.isPrimary)
                                      TextButton(
                                        onPressed: () {
                                          addressBookController
                                              .setPrimary(address.id);
                                          setState(() {});
                                        },
                                        child: Text(
                                          'Сделать основным',
                                          style: TextStyle(
                                            color: selected
                                                ? Colors.white
                                                : (isDark
                                                ? AppColors.purpleLight
                                                : AppColors.primary),
                                          ),
                                        ),
                                      ),
                                    const Spacer(),
                                    IconButton(
                                      onPressed: () {
                                        addressBookController
                                            .removeAddress(address.id);
                                        setState(() {});
                                      },
                                      icon: Icon(
                                        Icons.delete_outline_rounded,
                                        color: selected
                                            ? Colors.white
                                            : Colors.redAccent,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 4),
              OutlinedButton.icon(
                onPressed: _showAddAddressSheet,
                icon: const Icon(Icons.add_location_alt_outlined),
                label: const Text('Добавить новый адрес'),
              ),
            ],
          ],
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bg = Theme.of(context).scaffoldBackgroundColor;
    final Color onSurface = Theme.of(context).colorScheme.onSurface;

    final double itemsTotal = cartController.totalPrice;
    final int bonusPoints = authController.user.value?.loyaltyPoints ?? 0;

    final CheckoutSummary summary = CheckoutSummary.calculate(
      itemsTotal: itemsTotal,
      availableBonuses: bonusPoints,
      requestedBonuses: bonusToUse,
      deliveryMethod: deliveryMethod,
    );

    if (bonusToUse > summary.allowedBonuses) {
      bonusToUse = summary.allowedBonuses;
    }

    final bool canUseBonus = summary.allowedBonuses > 0;
    final int maxBonus = summary.allowedBonuses;

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
              _buildDeliveryMethodSelector(context),
              _buildAddressesBlock(context),
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
                    _sectionTitle(context, 'Комментарий к заказу'),
                    TextField(
                      onChanged: (String value) {
                        recipientComment = value;
                      },
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: 'Например: позвонить за 10 минут',
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
                    _sectionTitle(context, 'Оплата бонусами'),
                    if (!canUseBonus) ...[
                      Text(
                        'Бонусы доступны для списания от '
                            '${LoyaltyRules.bonusActivationMinOrder.toStringAsFixed(0)} ₽ '
                            'и не более ${(LoyaltyRules.maxBonusPercent * 100).toInt()}% '
                            'от суммы товаров.',
                        style: TextStyle(
                          color: isDark
                              ? AppColors.darkMutedForeground
                              : AppColors.mutedForeground,
                        ),
                      ),
                    ] else ...[
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
                          value: summary.appliedBonuses.toDouble(),
                          min: 0,
                          max: maxBonus.toDouble(),
                          divisions: maxBonus > 0 ? maxBonus : 1,
                          label: '${summary.appliedBonuses}',
                          onChanged: (double v) {
                            setState(() {
                              bonusToUse = v.toInt();
                            });
                          },
                        ),
                      ),
                      Text(
                        'Использовать: ${summary.appliedBonuses} / ${summary.availableBonuses} бонусов',
                        style: TextStyle(
                          color: onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Максимум к списанию: $maxBonus бонусов',
                        style: TextStyle(
                          color: isDark
                              ? AppColors.darkMutedForeground
                              : AppColors.mutedForeground,
                        ),
                      ),
                    ],
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
              _block(
                context,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle(context, 'Расчёт заказа'),
                    _summaryRow(
                      context,
                      label: 'Товары',
                      value: '${summary.itemsTotal.toStringAsFixed(0)} ₽',
                    ),
                    _summaryRow(
                      context,
                      label: deliveryMethod == DeliveryMethod.pickup
                          ? 'Получение'
                          : (summary.hasFreeDelivery
                          ? 'Доставка'
                          : 'Доставка до адреса'),
                      value: deliveryMethod == DeliveryMethod.pickup
                          ? 'Самовывоз'
                          : (summary.hasFreeDelivery
                          ? 'Бесплатно'
                          : '${summary.deliveryCost.toStringAsFixed(0)} ₽'),
                    ),
                    _summaryRow(
                      context,
                      label: 'Списание бонусов',
                      value: '-${summary.appliedBonuses} ₽',
                      negative: summary.appliedBonuses > 0,
                    ),
                    const Divider(height: 24),
                    _summaryRow(
                      context,
                      label: 'К оплате',
                      value: '${summary.payableTotal.toStringAsFixed(0)} ₽',
                      highlight: true,
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkSurfaceElevated
                            : AppColors.primaryLight.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark
                              ? AppColors.darkBorder
                              : AppColors.border,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.stars_rounded,
                            color: isDark
                                ? AppColors.purpleLight
                                : AppColors.primary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Начислится бонусов: ${summary.earnedBonuses}',
                                  style: TextStyle(
                                    color: onSurface,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  summary.hasBonusUsage
                                      ? 'При списании бонусов действует ставка 2%'
                                      : 'Без списания бонусов действует ставка 5%',
                                  style: TextStyle(
                                    color: isDark
                                        ? AppColors.darkMutedForeground
                                        : AppColors.mutedForeground,
                                    fontSize: 13,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient:
                  isDark ? AppColors.darkBrandGradient : AppColors.brandGradient,
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${summary.payableTotal.toStringAsFixed(0)} ₽',
                          style: const TextStyle(
                            fontSize: 22,
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '+ ${summary.earnedBonuses} бонусов',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.9),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
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
                  onPressed: () => _confirmOrder(summary),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(54),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: Text(
                    deliveryMethod == DeliveryMethod.pickup
                        ? 'Оформить самовывоз'
                        : 'Оформить заказ',
                  ),
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
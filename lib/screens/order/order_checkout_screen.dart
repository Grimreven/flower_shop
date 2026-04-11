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
  final AddressBookController addressBookController =
  Get.find<AddressBookController>();

  final TextEditingController promoController = TextEditingController();
  final TextEditingController recipientCommentController =
  TextEditingController();

  String paymentMethod = 'Наличный расчёт';
  DeliveryMethod deliveryMethod = DeliveryMethod.delivery;
  int bonusToUse = 0;

  @override
  void initState() {
    super.initState();
    addressBookController.syncPrimaryFromProfileIfNeeded();
  }

  @override
  void dispose() {
    promoController.dispose();
    recipientCommentController.dispose();
    super.dispose();
  }

  CheckoutSummary _buildSummary() {
    final int bonusPoints = authController.user.value?.loyaltyPoints ?? 0;

    return CheckoutSummary.calculate(
      itemsTotal: cartController.totalPrice,
      availableBonuses: bonusPoints,
      requestedBonuses: bonusToUse,
      deliveryMethod: deliveryMethod,
    );
  }

  bool get _canCheckout => cartController.items.isNotEmpty;

  Future<void> _confirmOrder() async {
    if (!_canCheckout) {
      Get.snackbar('Ошибка', 'Корзина пуста');
      return;
    }

    if (!authController.isLoggedIn) {
      Get.snackbar(
        'Вход',
        'Пожалуйста, войдите в аккаунт для оформления заказа',
      );
      return;
    }

    final UserAddress? selectedAddress = addressBookController.selectedAddress;
    final String deliveryAddress =
    deliveryMethod == DeliveryMethod.pickup
        ? 'Самовывоз'
        : (selectedAddress?.fullAddress.trim() ?? '');

    if (deliveryMethod == DeliveryMethod.delivery &&
        deliveryAddress.trim().isEmpty) {
      Get.snackbar('Ошибка', 'Выберите адрес доставки');
      return;
    }

    final CheckoutSummary summary = _buildSummary();

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
        recipientComment: recipientCommentController.text.trim(),
        promoCode: promoController.text.trim(),
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

  Widget _buildAddressTile(
      BuildContext context,
      UserAddress address, {
        required bool selected,
      }) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color onSurface = Theme.of(context).colorScheme.onSurface;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        addressBookController.selectAddress(address.id);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? (isDark
              ? AppColors.purple.withValues(alpha: 0.14)
              : AppColors.primaryLight)
              : (isDark ? AppColors.darkSurfaceElevated : Colors.white),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? (isDark ? AppColors.purple : AppColors.primary)
                : (isDark ? AppColors.darkBorder : AppColors.border),
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color: selected
                  ? (isDark ? AppColors.purpleLight : AppColors.primary)
                  : (isDark
                  ? AppColors.darkMutedForeground
                  : AppColors.mutedForeground),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          address.title.isEmpty ? 'Адрес' : address.title,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: onSurface,
                          ),
                        ),
                      ),
                      if (address.isPrimary) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.purple.withValues(alpha: 0.16)
                                : AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            'По умолчанию',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? AppColors.purpleLight
                                  : AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    address.fullAddress,
                    style: TextStyle(
                      color: isDark
                          ? AppColors.darkMutedForeground
                          : AppColors.mutedForeground,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddAddressDialog() async {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController addressController = TextEditingController();
    final TextEditingController entranceController = TextEditingController();
    final TextEditingController floorController = TextEditingController();
    final TextEditingController apartmentController = TextEditingController();
    final TextEditingController commentController = TextEditingController();

    bool isPrimary = addressBookController.addresses.isEmpty;

    await Get.dialog(
      StatefulBuilder(
        builder: (context, setLocalState) {
          final bool isDark = Theme.of(context).brightness == Brightness.dark;
          final Color onSurface = Theme.of(context).colorScheme.onSurface;

          return AlertDialog(
            backgroundColor: Theme.of(context).cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            title: Text(
              'Новый адрес',
              style: TextStyle(
                color: onSurface,
                fontWeight: FontWeight.w800,
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Название адреса',
                      hintText: 'Дом / Работа / Для мамы',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: addressController,
                    decoration: const InputDecoration(
                      labelText: 'Адрес',
                      hintText: 'Город, улица, дом',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: apartmentController,
                    decoration: const InputDecoration(
                      labelText: 'Квартира',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: entranceController,
                    decoration: const InputDecoration(
                      labelText: 'Подъезд',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: floorController,
                    decoration: const InputDecoration(
                      labelText: 'Этаж',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: commentController,
                    decoration: const InputDecoration(
                      labelText: 'Комментарий для курьера',
                    ),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: isPrimary,
                    activeColor: isDark ? AppColors.purple : AppColors.primary,
                    title: Text(
                      'Сделать адресом по умолчанию',
                      style: TextStyle(color: onSurface),
                    ),
                    onChanged: (value) {
                      setLocalState(() {
                        isPrimary = value;
                      });
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: const Text('Отмена'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (addressController.text.trim().isEmpty) {
                    Get.snackbar('Ошибка', 'Введите адрес');
                    return;
                  }

                  await addressBookController.addAddress(
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

                  if (mounted) {
                    setState(() {});
                  }

                  Get.back();
                },
                child: const Text('Сохранить'),
              ),
            ],
          );
        },
      ),
    );

    titleController.dispose();
    addressController.dispose();
    entranceController.dispose();
    floorController.dispose();
    apartmentController.dispose();
    commentController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bg = Theme.of(context).scaffoldBackgroundColor;
    final Color onSurface = Theme.of(context).colorScheme.onSurface;

    final int bonusPoints = authController.user.value?.loyaltyPoints ?? 0;
    final CheckoutSummary summary = _buildSummary();

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
        child: Obx(() {
          final addresses = addressBookController.addresses;
          final UserAddress? selectedAddress =
              addressBookController.selectedAddress;

          return SingleChildScrollView(
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
                                shaderCallback: (Rect bounds) =>
                                    (isDark
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
                      _sectionTitle(context, 'Способ получения'),
                      Row(
                        children: [
                          Expanded(
                            child: RadioListTile<DeliveryMethod>(
                              value: DeliveryMethod.delivery,
                              groupValue: deliveryMethod,
                              title: const Text('Доставка'),
                              contentPadding: EdgeInsets.zero,
                              activeColor: isDark
                                  ? AppColors.purple
                                  : AppColors.primary,
                              onChanged: (value) {
                                if (value == null) return;
                                setState(() {
                                  deliveryMethod = value;
                                  bonusToUse = bonusToUse.clamp(
                                    0,
                                    CheckoutSummary.calculate(
                                      itemsTotal: cartController.totalPrice,
                                      availableBonuses: bonusPoints,
                                      requestedBonuses: bonusToUse,
                                      deliveryMethod: value,
                                    ).allowedBonuses,
                                  );
                                });
                              },
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<DeliveryMethod>(
                              value: DeliveryMethod.pickup,
                              groupValue: deliveryMethod,
                              title: const Text('Самовывоз'),
                              contentPadding: EdgeInsets.zero,
                              activeColor: isDark
                                  ? AppColors.purple
                                  : AppColors.primary,
                              onChanged: (value) {
                                if (value == null) return;
                                setState(() {
                                  deliveryMethod = value;
                                  bonusToUse = bonusToUse.clamp(
                                    0,
                                    CheckoutSummary.calculate(
                                      itemsTotal: cartController.totalPrice,
                                      availableBonuses: bonusPoints,
                                      requestedBonuses: bonusToUse,
                                      deliveryMethod: value,
                                    ).allowedBonuses,
                                  );
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                if (deliveryMethod == DeliveryMethod.delivery)
                  _block(
                    context,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _sectionTitle(context, 'Адрес доставки'),
                            ),
                            TextButton.icon(
                              onPressed: _showAddAddressDialog,
                              icon: const Icon(Icons.add_rounded),
                              label: const Text('Добавить'),
                            ),
                          ],
                        ),
                        if (addresses.isEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.darkSurfaceElevated
                                  : AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              'У вас пока нет сохранённых адресов. Добавьте новый адрес и при необходимости сделайте его адресом по умолчанию.',
                              style: TextStyle(
                                color: isDark
                                    ? AppColors.darkMutedForeground
                                    : AppColors.mutedForeground,
                                height: 1.35,
                              ),
                            ),
                          )
                        else
                          ...addresses.map(
                                (address) => _buildAddressTile(
                              context,
                              address,
                              selected:
                              selectedAddress?.id == address.id,
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
                        onChanged: (String? value) {
                          if (value == null) return;
                          setState(() {
                            paymentMethod = value;
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
                        controller: recipientCommentController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          hintText: 'Например: не звонить в домофон, оставить у двери',
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
                      _sectionTitle(context, 'Промокод'),
                      TextField(
                        controller: promoController,
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
                      _sectionTitle(context, 'Оплата бонусами'),
                      if (summary.allowedBonuses <= 0)
                        Text(
                          bonusPoints <= 0
                              ? 'У вас пока нет бонусов'
                              : 'Бонусами можно оплатить заказ от 1000 ₽',
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
                                max: summary.allowedBonuses.toDouble(),
                                divisions:
                                summary.allowedBonuses > 0
                                    ? summary.allowedBonuses
                                    : 1,
                                label: '$bonusToUse',
                                onChanged: (double value) {
                                  setState(() {
                                    bonusToUse = value.toInt();
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
                      _sectionTitle(context, 'Итоги заказа'),
                      _summaryRow(
                        context,
                        'Товары',
                        '${summary.itemsTotal.toStringAsFixed(0)} ₽',
                      ),
                      const SizedBox(height: 8),
                      _summaryRow(
                        context,
                        'Доставка',
                        summary.deliveryCost == 0
                            ? 'Бесплатно'
                            : '${summary.deliveryCost.toStringAsFixed(0)} ₽',
                      ),
                      if (summary.appliedBonuses > 0) ...[
                        const SizedBox(height: 8),
                        _summaryRow(
                          context,
                          'Списано бонусов',
                          '-${summary.appliedBonuses}',
                          highlight: true,
                        ),
                      ],
                      const SizedBox(height: 8),
                      _summaryRow(
                        context,
                        'Начислится бонусов',
                        '+${summary.earnedBonuses}',
                        highlight: true,
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
                        color: (isDark
                            ? AppColors.purple
                            : AppColors.primary)
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
                        '${summary.payableTotal.toStringAsFixed(0)} ₽',
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
                        color: (isDark
                            ? AppColors.purple
                            : AppColors.primary)
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
          );
        }),
      ),
    );
  }

  Widget _summaryRow(
      BuildContext context,
      String title,
      String value, {
        bool highlight = false,
      }) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color onSurface = Theme.of(context).colorScheme.onSurface;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            color: isDark
                ? AppColors.darkMutedForeground
                : AppColors.mutedForeground,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: highlight
                ? (isDark ? AppColors.purpleLight : AppColors.primary)
                : onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
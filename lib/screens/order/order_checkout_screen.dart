import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/address_book_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/cart_controller.dart';
import '../../controllers/order_controller.dart';
import '../../controllers/payment_controller.dart';
import '../../models/product.dart';
import '../../models/cart_item.dart' as model;
import '../../models/checkout_summary.dart';
import '../../models/delivery_method.dart';
import '../../models/payment_method_model.dart';
import '../../models/user_address.dart';
import '../../utils/app_colors.dart';
import 'order_success_screen.dart';

// Вспомогательный класс для локального хранения товара
class _LocalCartItem {
  final Product product;
  final int quantity;

  _LocalCartItem({
    required this.product,
    required this.quantity,
  });
}

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
  final PaymentController paymentController = Get.find<PaymentController>();

  final TextEditingController promoController = TextEditingController();
  final TextEditingController recipientCommentController =
  TextEditingController();

  DeliveryMethod deliveryMethod = DeliveryMethod.delivery;
  int bonusToUse = 0;

  // Локальное состояние для ВСЕХ данных
  List<UserAddress> _localAddresses = [];
  UserAddress? _localSelectedAddress;
  bool _isLoadingAddresses = true;

  List<PaymentMethodModel> _localPaymentMethods = [];
  PaymentMethodModel? _localSelectedPayment;
  bool _isLoadingPayments = true;

  double _cartTotalPrice = 0.0;
  List<_LocalCartItem> _cartItems = [];
  int _userBonusPoints = 0;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  @override
  void dispose() {
    promoController.dispose();
    recipientCommentController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    // Загружаем адреса
    await addressBookController.loadAddresses();

    // Загружаем способы оплаты
    await paymentController.loadPaymentMethods();

    // Получаем данные из контроллеров
    if (mounted) {
      setState(() {
        _localAddresses = List.from(addressBookController.addresses);
        _localSelectedAddress = addressBookController.selectedAddress;
        _isLoadingAddresses = false;

        _localPaymentMethods = List.from(paymentController.paymentMethods);
        _localSelectedPayment = paymentController.selectedPaymentMethod;
        _isLoadingPayments = false;

        _cartTotalPrice = cartController.totalPrice;
        _cartItems = cartController.items.map((item) => _LocalCartItem(
          product: item.product,
          quantity: item.quantity.value,
        )).toList();
        _userBonusPoints = authController.user.value?.loyaltyPoints ?? 0;
      });
    }
  }

  CheckoutSummary _buildSummary() {
    return CheckoutSummary.calculate(
      itemsTotal: _cartTotalPrice,
      availableBonuses: _userBonusPoints,
      requestedBonuses: bonusToUse,
      deliveryMethod: deliveryMethod,
    );
  }

  bool get _canCheckout => _cartItems.isNotEmpty;

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

    final UserAddress? selectedAddress = _localSelectedAddress;
    final PaymentMethodModel? selectedPayment = _localSelectedPayment;

    if (selectedPayment == null) {
      Get.snackbar('Ошибка', 'Выберите способ оплаты');
      return;
    }

    final String deliveryAddress = deliveryMethod == DeliveryMethod.pickup
        ? 'Самовывоз'
        : (selectedAddress?.fullAddress.trim() ?? '');

    if (deliveryMethod == DeliveryMethod.delivery &&
        deliveryAddress.trim().isEmpty) {
      Get.snackbar('Ошибка', 'Выберите адрес доставки');
      return;
    }

    final CheckoutSummary summary = _buildSummary();

    final String paymentMethod = selectedPayment.isCard
        ? 'card'
        : selectedPayment.isSbp
        ? 'sbp'
        : 'cash';

    final String paymentStatus = selectedPayment.isCash ? 'pending' : 'paid';

    final String cardMask =
    selectedPayment.isCard ? selectedPayment.maskedNumber : '';

    try {
      final List<model.CartItem> items = _cartItems
          .map(
            (e) => model.CartItem(
          product: e.product,
          quantity: e.quantity,
        ),
      )
          .toList();

      await orderController.createOrder(
        items,
        summary: summary,
        paymentMethod: paymentMethod,
        paymentStatus: paymentStatus,
        cardMask: cardMask,
        deliveryAddress: deliveryAddress,
        addressId: deliveryMethod == DeliveryMethod.delivery
            ? selectedAddress?.id
            : null,
        recipientName: authController.user.value?.name ?? '',
        recipientPhone:
        authController.user.value?.phone ?? selectedAddress?.phone ?? '',
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
        setState(() {
          _localSelectedAddress = address;
        });
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

  Widget _buildPaymentTile(
      BuildContext context,
      PaymentMethodModel method, {
        required bool selected,
      }) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color onSurface = Theme.of(context).colorScheme.onSurface;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        setState(() {
          _localSelectedPayment = method;
        });
        paymentController.selectPaymentMethod(method.id);
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
          children: [
            Icon(
              method.icon,
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
                  Text(
                    method.title,
                    style: TextStyle(
                      color: onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (method.subtitle.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      method.subtitle,
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

    bool isPrimary = _localAddresses.isEmpty;

    final result = await Get.dialog<bool>(
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
                      hintText: 'Москва, Авиаторов 10, 1',
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
                onPressed: () => Get.back(result: false),
                child: const Text('Отмена'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (addressController.text.trim().isEmpty) {
                    Get.snackbar('Ошибка', 'Введите адрес');
                    return;
                  }

                  final newAddress = UserAddress(
                    id: DateTime.now().millisecondsSinceEpoch,
                    title: titleController.text.trim().isEmpty
                        ? 'Новый адрес'
                        : titleController.text.trim(),
                    address: addressController.text.trim(),
                    entrance: entranceController.text.trim(),
                    floor: floorController.text.trim(),
                    apartment: apartmentController.text.trim(),
                    comment: commentController.text.trim(),
                    isPrimary: isPrimary,
                  );

                  titleController.dispose();
                  addressController.dispose();
                  entranceController.dispose();
                  floorController.dispose();
                  apartmentController.dispose();
                  commentController.dispose();

                  // Сохраняем адрес
                  await addressBookController.addAddress(newAddress);

                  // Закрываем диалог с результатом true
                  Get.back(result: true);
                },
                child: const Text('Сохранить'),
              ),
            ],
          );
        },
      ),
    );
    if (result == true) {
      await _loadAllData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bg = Theme.of(context).scaffoldBackgroundColor;
    final Color onSurface = Theme.of(context).colorScheme.onSurface;
    final CheckoutSummary summary = _buildSummary();

    if (_isLoadingAddresses || _isLoadingPayments) {
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
        body: const Center(child: CircularProgressIndicator()),
      );
    }

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
              // Блок 1: Ваш заказ
              _block(
                context,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle(context, 'Ваш заказ'),
                    ..._cartItems.map(
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
                                    '${item.product.price.toStringAsFixed(0)} ₽ × ${item.quantity}',
                                    style: TextStyle(
                                      color: isDark
                                          ? AppColors.darkMutedForeground
                                          : AppColors.mutedForeground,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${(item.product.price * item.quantity).toStringAsFixed(0)} ₽',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: isDark
                                    ? AppColors.purpleLight
                                    : AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Блок 2: Способ получения
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
                            activeColor:
                            isDark ? AppColors.purple : AppColors.primary,
                            onChanged: (value) {
                              if (value == null) return;
                              setState(() {
                                deliveryMethod = value;
                                bonusToUse = bonusToUse.clamp(
                                  0,
                                  CheckoutSummary.calculate(
                                    itemsTotal: _cartTotalPrice,
                                    availableBonuses: _userBonusPoints,
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
                            activeColor:
                            isDark ? AppColors.purple : AppColors.primary,
                            onChanged: (value) {
                              if (value == null) return;
                              setState(() {
                                deliveryMethod = value;
                                bonusToUse = bonusToUse.clamp(
                                  0,
                                  CheckoutSummary.calculate(
                                    itemsTotal: _cartTotalPrice,
                                    availableBonuses: _userBonusPoints,
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
              // Блок 3: Адрес доставки
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
                      if (_localAddresses.isEmpty)
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
                            'У вас пока нет сохранённых адресов.\nДобавьте новый адрес и при необходимости сделайте его адресом по умолчанию.',
                            style: TextStyle(
                              color: isDark
                                  ? AppColors.darkMutedForeground
                                  : AppColors.mutedForeground,
                              height: 1.35,
                            ),
                          ),
                        )
                      else
                        ..._localAddresses.map(
                              (address) => _buildAddressTile(
                            context,
                            address,
                            selected: _localSelectedAddress?.id == address.id,
                          ),
                        ),
                    ],
                  ),
                ),
              // Блок 4: Способ оплаты
              _block(
                context,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle(context, 'Способ оплаты'),
                    if (_localPaymentMethods.isEmpty)
                      const Text('Способы оплаты не найдены')
                    else
                      ..._localPaymentMethods.map(
                            (method) => _buildPaymentTile(
                          context,
                          method,
                          selected: _localSelectedPayment?.id == method.id,
                        ),
                      ),
                  ],
                ),
              ),
              // Блок 5: Комментарий к заказу
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
                        hintText:
                        'Например: не звонить в домофон, оставить у двери',
                      ),
                    ),
                  ],
                ),
              ),
              // Блок 6: Промокод
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
              // Блок 7: Оплата бонусами
              _block(
                context,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle(context, 'Оплата бонусами'),
                    if (summary.allowedBonuses <= 0)
                      Text(
                        _userBonusPoints <= 0
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
                              divisions: summary.allowedBonuses > 0
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
                            'Использовать: $bonusToUse / $_userBonusPoints бонусов',
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
              // Блок 8: Итоги заказа
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
              // Итоговая сумма
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
              // Кнопка оформления заказа
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
                  child: Text(
                    _localSelectedPayment?.isSbp == true
                        ? 'Оплатить через СБП'
                        : _localSelectedPayment?.isCard == true
                        ? 'Оплатить картой'
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
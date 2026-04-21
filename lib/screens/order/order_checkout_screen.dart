import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/address_book_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/cart_controller.dart';
import '../../controllers/order_controller.dart';
import '../../controllers/payment_controller.dart';
import '../../models/cart_item.dart' as model;
import '../../models/checkout_summary.dart';
import '../../models/delivery_method.dart';
import '../../models/payment_method_model.dart';
import '../../models/payment_transaction_model.dart';
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
  final PaymentController paymentController = Get.find<PaymentController>();
  final AddressBookController addressBookController =
  Get.find<AddressBookController>();

  final TextEditingController promoController = TextEditingController();
  final TextEditingController recipientCommentController =
  TextEditingController();
  final TextEditingController cvvController = TextEditingController();

  DeliveryMethod deliveryMethod = DeliveryMethod.delivery;
  int bonusToUse = 0;

  @override
  void initState() {
    super.initState();
    addressBookController.syncPrimaryFromProfileIfNeeded();
    paymentController.loadPaymentMethods();
    paymentController.loadPaymentTransactions();
  }

  @override
  void dispose() {
    FocusManager.instance.primaryFocus?.unfocus();
    promoController.dispose();
    recipientCommentController.dispose();
    cvvController.dispose();
    super.dispose();
  }

  void _unfocusEverything() {
    final FocusScopeNode scope = FocusScope.of(context);
    if (!scope.hasPrimaryFocus) {
      scope.unfocus();
    }
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

  PaymentMethodModel? get _selectedMethod => paymentController.selectedMethod.value;

  bool get _selectedMethodRequiresCvv =>
      _selectedMethod != null && _selectedMethod!.type == PaymentMethodType.bankCard;

  String get _selectedMethodLabel {
    final PaymentMethodModel? method = _selectedMethod;
    if (method == null) {
      return 'Не выбран';
    }
    return method.title;
  }

  String get _predictedPaymentStatusLabel {
    final PaymentMethodModel? method = _selectedMethod;
    if (method == null) {
      return 'Не выбран';
    }

    if (method.type == PaymentMethodType.cash) {
      return 'Ожидает оплаты при получении';
    }

    return 'Ожидает подтверждения';
  }

  String _transactionStatusLabel(PaymentTransactionModel transaction) {
    return transaction.statusLabel;
  }

  bool _validateCheckoutData() {
    if (!_canCheckout) {
      Get.snackbar('Ошибка', 'Корзина пуста');
      return false;
    }

    if (!authController.isLoggedIn) {
      Get.snackbar(
        'Вход',
        'Пожалуйста, войдите в аккаунт для оформления заказа',
      );
      return false;
    }

    if (_selectedMethod == null) {
      Get.snackbar(
        'Оплата',
        'Выберите способ оплаты',
      );
      return false;
    }

    if (deliveryMethod == DeliveryMethod.delivery &&
        addressBookController.selectedAddress == null) {
      Get.snackbar(
        'Адрес',
        'Выберите адрес доставки',
      );
      return false;
    }

    if (_selectedMethodRequiresCvv) {
      final String cvv = cvvController.text.trim();
      if (cvv.length != 3 || int.tryParse(cvv) == null) {
        Get.snackbar(
          'Оплата',
          'Введите корректный CVV из 3 цифр',
        );
        return false;
      }
    }

    return true;
  }

  Future<void> _confirmOrder() async {
    _unfocusEverything();

    if (!_validateCheckoutData()) {
      return;
    }

    final PaymentMethodModel method = _selectedMethod!;
    final CheckoutSummary summary = _buildSummary();

    final UserAddress? selectedAddress = addressBookController.selectedAddress;
    final String deliveryAddress = deliveryMethod == DeliveryMethod.pickup
        ? 'Самовывоз'
        : (selectedAddress?.fullAddress.trim() ?? '');

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
        paymentMethod: method.title,
        paymentStatus: _predictedPaymentStatusLabel,
        cardMask: method.maskedNumber ?? '',
        deliveryAddress: deliveryAddress,
        recipientComment: recipientCommentController.text.trim(),
        promoCode: promoController.text.trim(),
      );

      final latestOrder = orderController.getLatestOrder();
      if (latestOrder == null) {
        throw Exception('Не удалось создать заказ');
      }

      final PaymentTransactionModel transaction =
      await paymentController.processOrderPayment(
        orderId: latestOrder.id,
        amount: latestOrder.total,
        method: method,
        cvv: _selectedMethodRequiresCvv ? cvvController.text.trim() : null,
      );

      if (!mounted) return;

      if (transaction.status == PaymentTransactionStatus.failed) {
        Get.snackbar(
          'Оплата не прошла',
          transaction.failureReason ?? 'Не удалось выполнить платёж',
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
        );
        return;
      }

      final String paymentText = _transactionStatusLabel(transaction);

      Get.offAll(
            () => const OrderSuccessScreen(),
        arguments: <String, dynamic>{
          'payment_status_label': paymentText,
          'payment_method_title': method.title,
          'payment_method_subtitle': method.subtitle,
        },
      );
    } catch (e) {
      if (!mounted) return;

      Get.snackbar(
        'Ошибка',
        'Не удалось оформить заказ: $e',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    }
  }

  Widget _sectionTitle(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }

  Widget _block(BuildContext context, {required Widget child}) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color cardColor = Theme.of(context).cardColor;
    final Color borderColor = isDark ? AppColors.darkBorder : AppColors.border;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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

  Widget _buildAddressTile(
      BuildContext context,
      UserAddress address, {
        required bool selected,
      }) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color onSurface = Theme.of(context).colorScheme.onSurface;
    final Color muted = isDark
        ? AppColors.darkMutedForeground
        : AppColors.mutedForeground;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          _unfocusEverything();
          addressBookController.selectAddress(address.id);
          setState(() {});
        },
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: selected
                ? (isDark ? AppColors.darkSurfaceElevated : AppColors.primaryLight)
                : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? (isDark ? AppColors.purpleLight : AppColors.primary)
                  : (isDark ? AppColors.darkBorder : AppColors.border),
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Row(
            children: [
              Radio<int>(
                value: address.id,
                groupValue: addressBookController.selectedAddress?.id,
                onChanged: (_) {
                  _unfocusEverything();
                  addressBookController.selectAddress(address.id);
                  setState(() {});
                },
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          address.title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: onSurface,
                          ),
                        ),
                        if (address.isPrimary) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.purple.withOpacity(0.18)
                                  : AppColors.primary.withOpacity(0.10),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              'Основной',
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
                        fontSize: 13,
                        height: 1.35,
                        color: muted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentMethodTile(
      BuildContext context,
      PaymentMethodModel method, {
        required bool selected,
      }) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color onSurface = Theme.of(context).colorScheme.onSurface;

    return InkWell(
      onTap: () {
        _unfocusEverything();
        paymentController.selectMethod(method);
        setState(() {});
      },
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected
              ? (isDark ? AppColors.darkSurfaceElevated : AppColors.primaryLight)
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? (isDark ? AppColors.purpleLight : AppColors.primary)
                : (isDark ? AppColors.darkBorder : AppColors.border),
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Row(
          children: [
            Radio<String>(
              value: method.id,
              groupValue: _selectedMethod?.id,
              onChanged: (_) {
                _unfocusEverything();
                paymentController.selectMethod(method);
                setState(() {});
              },
            ),
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: selected
                    ? (isDark
                    ? AppColors.purple.withOpacity(0.18)
                    : AppColors.primary.withOpacity(0.10))
                    : (isDark
                    ? AppColors.darkSurfaceSoft
                    : AppColors.primaryLight),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                method.icon,
                color: selected
                    ? (isDark ? AppColors.purpleLight : AppColors.primary)
                    : (isDark
                    ? AppColors.darkMutedForeground
                    : AppColors.mutedForeground),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          method.title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: onSurface,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkSurfaceSoft
                              : Colors.white,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          method.displayBadge,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppColors.purpleLight
                                : AppColors.primary,
                          ),
                        ),
                      ),
                      if (method.isDefault) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkSurfaceSoft
                                : Colors.white,
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
                    method.subtitle,
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
          ],
        ),
      ),
    );
  }

  Future<void> _showAddAddressDialog() async {
    _unfocusEverything();

    final UserAddress? createdAddress = await Get.dialog<UserAddress>(
      const _CheckoutAddAddressDialog(
        initialIsPrimary: false,
      ),
      barrierDismissible: true,
    );

    if (!mounted || createdAddress == null) {
      return;
    }

    await addressBookController.addAddress(createdAddress);

    if (!mounted) return;

    setState(() {});
  }

  Widget _buildPaymentSection(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Obx(() {
      final List<PaymentMethodModel> methods =
      paymentController.paymentMethods.toList();

      return _block(
        context,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle(context, 'Способ оплаты'),
            if (methods.isEmpty) ...[
              Text(
                'У вас нет сохранённых способов оплаты. Добавьте карту в профиле или используйте системные методы после загрузки.',
                style: TextStyle(
                  color: isDark
                      ? AppColors.darkMutedForeground
                      : AppColors.mutedForeground,
                  height: 1.4,
                ),
              ),
            ] else ...[
              ...methods.map(
                    (PaymentMethodModel method) => _buildPaymentMethodTile(
                  context,
                  method,
                  selected: _selectedMethod?.id == method.id,
                ),
              ),
              if (_selectedMethodRequiresCvv) ...[
                const SizedBox(height: 6),
                TextField(
                  controller: cvvController,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _confirmOrder(),
                  decoration: const InputDecoration(
                    labelText: 'CVV/CVC',
                    hintText: 'Введите 3 цифры',
                    helperText: 'CVV не сохраняется и используется только для демо-оплаты',
                  ),
                ),
              ],
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 18,
                    color: isDark
                        ? AppColors.darkMutedForeground
                        : AppColors.mutedForeground,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Полные реквизиты карты и CVV не хранятся. Для сохранённых карт используется только маска и локальный токен.',
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        color: isDark
                            ? AppColors.darkMutedForeground
                            : AppColors.mutedForeground,
                      ),
                    ),
                  ),
                ],
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
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
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
                        onChanged: (value) {
                          if (value == null) return;
                          _unfocusEverything();
                          setState(() {
                            deliveryMethod = value;
                          });
                        },
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<DeliveryMethod>(
                        value: DeliveryMethod.pickup,
                        groupValue: deliveryMethod,
                        title: const Text('Самовывоз'),
                        onChanged: (value) {
                          if (value == null) return;
                          _unfocusEverything();
                          setState(() {
                            deliveryMethod = value;
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
            Obx(() {
              final List<UserAddress> addresses =
              addressBookController.addresses.toList();
              final UserAddress? selectedAddress =
                  addressBookController.selectedAddress;

              return _block(
                context,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: _sectionTitle(context, 'Адрес доставки')),
                        TextButton.icon(
                          onPressed: _showAddAddressDialog,
                          icon: const Icon(Icons.add),
                          label: const Text('Добавить'),
                        ),
                      ],
                    ),
                    if (addresses.isEmpty)
                      Text(
                        'Добавьте новый адрес и при необходимости сделайте его адресом по умолчанию.',
                        style: TextStyle(
                          color: isDark
                              ? AppColors.darkMutedForeground
                              : AppColors.mutedForeground,
                          height: 1.35,
                        ),
                      )
                    else
                      ...addresses.map(
                            (address) => _buildAddressTile(
                          context,
                          address,
                          selected: selectedAddress?.id == address.id,
                        ),
                      ),
                  ],
                ),
              );
            }),
          _buildPaymentSection(context),
          _block(
            context,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionTitle(context, 'Комментарий к заказу'),
                TextField(
                  controller: recipientCommentController,
                  maxLines: 3,
                  textInputAction: TextInputAction.done,
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
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    hintText: 'Введите промокод',
                    prefixIcon: Icon(
                      Icons.discount_outlined,
                      color: isDark ? AppColors.purpleLight : AppColors.primary,
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
                      Slider(
                        value: bonusToUse.toDouble(),
                        min: 0,
                        max: summary.allowedBonuses.toDouble(),
                        divisions: summary.allowedBonuses > 0
                            ? summary.allowedBonuses
                            : 1,
                        label: '$bonusToUse',
                        onChanged: (double value) {
                          _unfocusEverything();
                          setState(() {
                            bonusToUse = value.toInt();
                          });
                        },
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
                const SizedBox(height: 8),
                _summaryRow(
                  context,
                  'Способ оплаты',
                  _selectedMethodLabel,
                ),
                const SizedBox(height: 8),
                _summaryRow(
                  context,
                  'Ожидаемый статус оплаты',
                  _predictedPaymentStatusLabel,
                  highlight: _selectedMethod?.type != PaymentMethodType.cash,
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
                      .withOpacity(0.18),
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
          Obx(() {
            final bool processing = paymentController.isProcessingPayment.value;

            return DecoratedBox(
              decoration: BoxDecoration(
                gradient: isDark
                    ? AppColors.darkBrandGradient
                    : AppColors.brandGradient,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: (isDark ? AppColors.purple : AppColors.primary)
                        .withOpacity(0.18),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: processing ? null : _confirmOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: processing
                    ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    valueColor:
                    AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                    : const Text('Оформить заказ'),
              ),
            );
          }),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _CheckoutAddAddressDialog extends StatefulWidget {
  final bool initialIsPrimary;

  const _CheckoutAddAddressDialog({
    required this.initialIsPrimary,
  });

  @override
  State<_CheckoutAddAddressDialog> createState() =>
      _CheckoutAddAddressDialogState();
}

class _CheckoutAddAddressDialogState extends State<_CheckoutAddAddressDialog> {
  late final TextEditingController titleController;
  late final TextEditingController addressController;
  late final TextEditingController entranceController;
  late final TextEditingController floorController;
  late final TextEditingController apartmentController;
  late final TextEditingController commentController;

  bool isPrimary = false;

  @override
  void initState() {
    super.initState();

    isPrimary = widget.initialIsPrimary;
    titleController = TextEditingController();
    addressController = TextEditingController();
    entranceController = TextEditingController();
    floorController = TextEditingController();
    apartmentController = TextEditingController();
    commentController = TextEditingController();
  }

  @override
  void dispose() {
    FocusManager.instance.primaryFocus?.unfocus();

    titleController.dispose();
    addressController.dispose();
    entranceController.dispose();
    floorController.dispose();
    apartmentController.dispose();
    commentController.dispose();

    super.dispose();
  }

  void _close() {
    FocusScope.of(context).unfocus();

    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  void _save() {
    final String address = addressController.text.trim();

    if (address.isEmpty) {
      Get.snackbar('Ошибка', 'Введите адрес');
      return;
    }

    FocusScope.of(context).unfocus();

    Navigator.of(context).pop(
      UserAddress(
        id: 0,
        title: titleController.text.trim().isEmpty
            ? 'Адрес'
            : titleController.text.trim(),
        address: address,
        entrance: entranceController.text.trim(),
        floor: floorController.text.trim(),
        apartment: apartmentController.text.trim(),
        comment: commentController.text.trim(),
        isPrimary: isPrimary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Новый адрес'),
      content: SingleChildScrollView(
        child: Column(
          children: [
            TextField(
              controller: titleController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Название адреса',
                hintText: 'Дом, Работа',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: addressController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Адрес',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: entranceController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Подъезд',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: floorController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Этаж',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: apartmentController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Квартира',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: commentController,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _save(),
              decoration: const InputDecoration(
                labelText: 'Комментарий',
              ),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Сделать адресом по умолчанию'),
              value: isPrimary,
              onChanged: (bool value) {
                FocusScope.of(context).unfocus();
                setState(() {
                  isPrimary = value;
                });
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _close,
          child: const Text('Отмена'),
        ),
        ElevatedButton(
          onPressed: _save,
          child: const Text('Сохранить'),
        ),
      ],
    );
  }
}
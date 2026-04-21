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

enum CheckoutPaymentMethod {
  cash,
  sbp,
  cardOnline,
}

enum CheckoutPaymentStatus {
  pending,
  paid,
  failed,
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

  final TextEditingController promoController = TextEditingController();
  final TextEditingController recipientCommentController =
  TextEditingController();

  final TextEditingController cardHolderController = TextEditingController();
  final TextEditingController cardNumberController = TextEditingController();
  final TextEditingController cardExpiryController = TextEditingController();
  final TextEditingController cardCvvController = TextEditingController();

  CheckoutPaymentMethod paymentMethod = CheckoutPaymentMethod.cash;
  CheckoutPaymentStatus paymentStatus = CheckoutPaymentStatus.pending;
  DeliveryMethod deliveryMethod = DeliveryMethod.delivery;

  int bonusToUse = 0;
  bool isProcessingPayment = false;

  @override
  void initState() {
    super.initState();
    addressBookController.syncPrimaryFromProfileIfNeeded();
  }

  @override
  void dispose() {
    promoController.dispose();
    recipientCommentController.dispose();
    cardHolderController.dispose();
    cardNumberController.dispose();
    cardExpiryController.dispose();
    cardCvvController.dispose();
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

  String get _paymentMethodLabel {
    switch (paymentMethod) {
      case CheckoutPaymentMethod.cash:
        return 'Наличными при получении';
      case CheckoutPaymentMethod.sbp:
        return 'СБП';
      case CheckoutPaymentMethod.cardOnline:
        return 'Банковская карта';
    }
  }

  String get _paymentStatusLabel {
    switch (paymentStatus) {
      case CheckoutPaymentStatus.pending:
        return paymentMethod == CheckoutPaymentMethod.cash
            ? 'Ожидает оплаты при получении'
            : 'Ожидает подтверждения';
      case CheckoutPaymentStatus.paid:
        return 'Оплачено';
      case CheckoutPaymentStatus.failed:
        return 'Ошибка оплаты';
    }
  }

  bool get _requiresCardFields =>
      paymentMethod == CheckoutPaymentMethod.cardOnline ||
          paymentMethod == CheckoutPaymentMethod.sbp;

  String _digitsOnly(String value) => value.replaceAll(RegExp(r'[^0-9]'), '');

  String _formatCardNumber(String value) {
    final String digits = _digitsOnly(value);
    final List<String> chunks = <String>[];
    for (int i = 0; i < digits.length; i += 4) {
      final int end = (i + 4 < digits.length) ? i + 4 : digits.length;
      chunks.add(digits.substring(i, end));
    }
    return chunks.join(' ');
  }

  String _formatExpiry(String value) {
    final String digits = _digitsOnly(value);
    if (digits.length <= 2) return digits;
    final String month = digits.substring(0, 2);
    final String year = digits.substring(2, digits.length > 4 ? 4 : digits.length);
    return '$month/$year';
  }

  String _maskedCardNumber() {
    final String digits = _digitsOnly(cardNumberController.text);
    if (digits.length < 4) return '';
    return '**** **** **** ${digits.substring(digits.length - 4)}';
  }

  String? _validateCardHolder() {
    if (!_requiresCardFields) return null;

    final String value = cardHolderController.text.trim();
    if (value.isEmpty) return 'Введите имя держателя карты';
    if (value.length < 4) return 'Слишком короткое имя держателя';
    return null;
  }

  String? _validateCardNumber() {
    if (!_requiresCardFields) return null;

    final String digits = _digitsOnly(cardNumberController.text);
    if (digits.isEmpty) return 'Введите номер карты';
    if (digits.length < 16) return 'Номер карты должен содержать 16 цифр';
    return null;
  }

  String? _validateExpiry() {
    if (!_requiresCardFields) return null;

    final String digits = _digitsOnly(cardExpiryController.text);
    if (digits.length != 4) return 'Введите срок действия в формате ММ/ГГ';

    final int month = int.tryParse(digits.substring(0, 2)) ?? 0;
    final int year = int.tryParse(digits.substring(2, 4)) ?? 0;

    if (month < 1 || month > 12) {
      return 'Некорректный месяц';
    }

    final DateTime now = DateTime.now();
    final int currentYear = now.year % 100;
    final int currentMonth = now.month;

    if (year < currentYear || (year == currentYear && month < currentMonth)) {
      return 'Срок действия карты истёк';
    }

    return null;
  }

  String? _validateCvv() {
    if (!_requiresCardFields) return null;

    final String digits = _digitsOnly(cardCvvController.text);
    if (digits.length != 3) return 'CVV должен содержать 3 цифры';
    return null;
  }

  bool _validatePaymentForm() {
    final String? holderError = _validateCardHolder();
    final String? numberError = _validateCardNumber();
    final String? expiryError = _validateExpiry();
    final String? cvvError = _validateCvv();

    final String? firstError =
        holderError ?? numberError ?? expiryError ?? cvvError;

    if (firstError != null) {
      Get.snackbar('Ошибка', firstError);
      return false;
    }

    return true;
  }

  Future<bool> _simulatePayment() async {
    if (paymentMethod == CheckoutPaymentMethod.cash) {
      setState(() {
        paymentStatus = CheckoutPaymentStatus.pending;
      });
      return true;
    }

    if (!_validatePaymentForm()) {
      setState(() {
        paymentStatus = CheckoutPaymentStatus.failed;
      });
      return false;
    }

    setState(() {
      isProcessingPayment = true;
      paymentStatus = CheckoutPaymentStatus.pending;
    });

    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      isProcessingPayment = false;
      paymentStatus = CheckoutPaymentStatus.paid;
    });

    return true;
  }

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

    final String deliveryAddress = deliveryMethod == DeliveryMethod.pickup
        ? 'Самовывоз'
        : (selectedAddress?.fullAddress.trim() ?? '');

    if (deliveryMethod == DeliveryMethod.delivery &&
        deliveryAddress.trim().isEmpty) {
      Get.snackbar('Ошибка', 'Выберите адрес доставки');
      return;
    }

    final bool paymentOk = await _simulatePayment();
    if (!paymentOk) {
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
        paymentMethod: _paymentMethodLabel,
        paymentStatus: _paymentStatusLabel,
        cardMask: _maskedCardNumber(),
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

  Widget _paymentMethodTile({
    required BuildContext context,
    required CheckoutPaymentMethod value,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color onSurface = Theme.of(context).colorScheme.onSurface;
    final bool selected = paymentMethod == value;

    return InkWell(
      onTap: () {
        setState(() {
          paymentMethod = value;
          if (paymentMethod == CheckoutPaymentMethod.cash) {
            paymentStatus = CheckoutPaymentStatus.pending;
          }
        });
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
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: selected
                    ? (isDark
                    ? AppColors.purple.withOpacity(0.18)
                    : AppColors.primary.withOpacity(0.10))
                    : (isDark ? AppColors.darkSurfaceSoft : AppColors.primaryLight),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
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
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
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
            Radio<CheckoutPaymentMethod>(
              value: value,
              groupValue: paymentMethod,
              onChanged: (CheckoutPaymentMethod? newValue) {
                if (newValue == null) return;
                setState(() {
                  paymentMethod = newValue;
                  if (paymentMethod == CheckoutPaymentMethod.cash) {
                    paymentStatus = CheckoutPaymentStatus.pending;
                  }
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardFields(BuildContext context) {
    if (!_requiresCardFields) {
      return const SizedBox.shrink();
    }

    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color muted = isDark
        ? AppColors.darkMutedForeground
        : AppColors.mutedForeground;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        TextField(
          controller: cardHolderController,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(
            labelText: 'Имя держателя карты',
            hintText: 'IVAN IVANOV',
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: cardNumberController,
          keyboardType: TextInputType.number,
          onChanged: (value) {
            final String formatted = _formatCardNumber(value);
            if (formatted != value) {
              cardNumberController.value = TextEditingValue(
                text: formatted,
                selection: TextSelection.collapsed(offset: formatted.length),
              );
            }
          },
          decoration: const InputDecoration(
            labelText: 'Номер карты',
            hintText: '0000 0000 0000 0000',
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: cardExpiryController,
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  final String formatted = _formatExpiry(value);
                  if (formatted != value) {
                    cardExpiryController.value = TextEditingValue(
                      text: formatted,
                      selection: TextSelection.collapsed(offset: formatted.length),
                    );
                  }
                },
                decoration: const InputDecoration(
                  labelText: 'Срок',
                  hintText: 'MM/ГГ',
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: cardCvvController,
                keyboardType: TextInputType.number,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'CVV',
                  hintText: '123',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Icon(
              paymentStatus == CheckoutPaymentStatus.paid
                  ? Icons.check_circle_rounded
                  : paymentStatus == CheckoutPaymentStatus.failed
                  ? Icons.error_rounded
                  : Icons.schedule_rounded,
              size: 18,
              color: paymentStatus == CheckoutPaymentStatus.paid
                  ? Colors.green
                  : paymentStatus == CheckoutPaymentStatus.failed
                  ? Colors.redAccent
                  : muted,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _paymentStatusLabel,
                style: TextStyle(
                  color: muted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
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
    final Color muted =
    isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
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

  Future<void> _showAddAddressDialog() async {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController addressController = TextEditingController();
    final TextEditingController entranceController = TextEditingController();
    final TextEditingController floorController = TextEditingController();
    final TextEditingController apartmentController = TextEditingController();
    final TextEditingController commentController = TextEditingController();

    bool isPrimary = false;

    await Get.dialog(
      StatefulBuilder(
        builder: (context, setLocalState) {
          return AlertDialog(
            title: const Text('Новый адрес'),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Название адреса',
                      hintText: 'Дом, Работа',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: addressController,
                    decoration: const InputDecoration(
                      labelText: 'Адрес',
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
                    controller: apartmentController,
                    decoration: const InputDecoration(
                      labelText: 'Квартира',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: commentController,
                    decoration: const InputDecoration(
                      labelText: 'Комментарий',
                    ),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Сделать адресом по умолчанию'),
                    value: isPrimary,
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
                onPressed: Get.back,
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
                          ? 'Адрес'
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
          _block(
            context,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionTitle(context, 'Способ оплаты'),
                _paymentMethodTile(
                  context: context,
                  value: CheckoutPaymentMethod.cash,
                  title: 'Наличными при получении',
                  subtitle: 'Оплата курьеру или в точке самовывоза',
                  icon: Icons.payments_outlined,
                ),
                const SizedBox(height: 12),
                _paymentMethodTile(
                  context: context,
                  value: CheckoutPaymentMethod.sbp,
                  title: 'СБП',
                  subtitle: 'Имитация онлайн-оплаты через банковское приложение',
                  icon: Icons.qr_code_rounded,
                ),
                const SizedBox(height: 12),
                _paymentMethodTile(
                  context: context,
                  value: CheckoutPaymentMethod.cardOnline,
                  title: 'Банковская карта',
                  subtitle: 'Онлайн-оплата картой с валидацией данных',
                  icon: Icons.credit_card_rounded,
                ),
                _buildCardFields(context),
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
                  _paymentMethodLabel,
                ),
                const SizedBox(height: 8),
                _summaryRow(
                  context,
                  'Статус оплаты',
                  _paymentStatusLabel,
                  highlight: paymentStatus == CheckoutPaymentStatus.paid,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: isDark ? AppColors.darkBrandGradient : AppColors.brandGradient,
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
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: isDark ? AppColors.darkBrandGradient : AppColors.brandGradient,
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
              onPressed: isProcessingPayment ? null : _confirmOrder,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(54),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: isProcessingPayment
                  ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
                  : const Text('Оформить заказ'),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
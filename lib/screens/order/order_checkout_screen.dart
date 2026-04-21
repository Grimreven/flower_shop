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
  final PaymentController paymentController = Get.find<PaymentController>();

  final TextEditingController promoController = TextEditingController();
  final TextEditingController recipientCommentController =
  TextEditingController();
  final TextEditingController cardHolderController = TextEditingController();
  final TextEditingController cardNumberController = TextEditingController();
  final TextEditingController cardExpiryController = TextEditingController();
  final TextEditingController cardCvvController = TextEditingController();

  DeliveryMethod deliveryMethod = DeliveryMethod.delivery;
  int bonusToUse = 0;
  bool isProcessingPayment = false;
  bool isPaymentMethodsLoading = true;

  String? selectedPaymentMethodId;
  String? selectedSbpBank;

  final List<String> sbpBanks = const [
    'СберБанк',
    'Т-Банк',
    'Альфа-Банк',
    'ВТБ',
    'Газпромбанк',
    'Россельхозбанк',
    'Райффайзен Банк',
    'Открытие',
    'Совкомбанк',
    'ПСБ',
    'МТС Банк',
    'ЮMoney',
    'OZON Банк',
    'Уралсиб',
    'АК Барс Банк',
    'Росбанк',
    'Банк Санкт-Петербург',
    'Почта Банк',
    'Русский Стандарт',
    'Абсолют Банк',
    'МКБ',
    'Синара',
    'Локо-Банк',
    'Банк ДОМ.РФ',
    'Сургутнефтегазбанк',
  ];

  @override
  void initState() {
    super.initState();
    addressBookController.syncPrimaryFromProfileIfNeeded();
    _initCheckout();
  }

  Future<void> _initCheckout() async {
    await paymentController.loadPaymentMethods();

    if (!mounted) return;

    final PaymentMethodModel? defaultMethod =
        paymentController.selectedMethod.value;

    setState(() {
      selectedPaymentMethodId =
          defaultMethod?.id ??
              (paymentController.paymentMethods.isNotEmpty
                  ? paymentController.paymentMethods.first.id
                  : null);
      isPaymentMethodsLoading = false;
    });
  }

  @override
  void dispose() {
    FocusManager.instance.primaryFocus?.unfocus();
    promoController.dispose();
    recipientCommentController.dispose();
    cardHolderController.dispose();
    cardNumberController.dispose();
    cardExpiryController.dispose();
    cardCvvController.dispose();
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

  PaymentMethodModel? get _selectedPaymentMethod {
    if (selectedPaymentMethodId == null) return null;

    try {
      return paymentController.paymentMethods.firstWhere(
            (PaymentMethodModel item) => item.id == selectedPaymentMethodId,
      );
    } catch (_) {
      return null;
    }
  }

  bool get _isSbpSelected => _selectedPaymentMethod?.isSbp == true;
  bool get _isCashSelected => _selectedPaymentMethod?.isCash == true;
  bool get _isSavedCardSelected => _selectedPaymentMethod?.isCard == true;

  bool get _requiresManualCardFields => false;

  String get _paymentMethodLabel {
    final PaymentMethodModel? method = _selectedPaymentMethod;
    if (method == null) return 'Способ оплаты';

    if (method.isSbp) {
      return selectedSbpBank == null ? method.title : 'СБП • $selectedSbpBank';
    }

    return method.title;
  }

  String get _paymentStatusLabel {
    if (_isCashSelected) {
      return 'Ожидает оплаты при получении';
    }

    if (_isSbpSelected) {
      return 'Оплачено через СБП';
    }

    if (_isSavedCardSelected) {
      return 'Оплачено картой';
    }

    return 'Ожидает подтверждения';
  }

  String get _bottomButtonLabel {
    final CheckoutSummary summary = _buildSummary();
    final String amount = '${summary.payableTotal.toStringAsFixed(0)} ₽';

    if (_isSbpSelected) {
      return 'Оплатить по СБП • $amount';
    }

    if (_isSavedCardSelected) {
      return 'Оплатить картой • $amount';
    }

    return 'Подтвердить заказ • $amount';
  }

  String _digitsOnly(String value) => value.replaceAll(RegExp(r'[^0-9]'), '');

  String _maskedCardNumberForOrder() {
    final PaymentMethodModel? method = _selectedPaymentMethod;
    if (method == null) return '';

    if (method.isCard) {
      return method.maskedNumber ?? '';
    }

    final String digits = _digitsOnly(cardNumberController.text);
    if (digits.length < 4) return '';
    return '**** **** **** ${digits.substring(digits.length - 4)}';
  }

  Future<String?> _showSbpBanksBottomSheet() async {
    _unfocusEverything();

    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? AppColors.darkSurface
          : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (BuildContext context) {
        return _SbpBankPickerBottomSheet(
          banks: sbpBanks,
          selectedBank: selectedSbpBank,
        );
      },
    );
  }

  Future<void> _completeOrderFlow() async {
    final PaymentMethodModel? selectedMethod = _selectedPaymentMethod;

    if (selectedMethod == null) {
      Get.snackbar('Ошибка', 'Выберите способ оплаты');
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

    if (_isSbpSelected && (selectedSbpBank == null || selectedSbpBank!.isEmpty)) {
      Get.snackbar('СБП', 'Выберите банк для оплаты');
      return;
    }

    setState(() {
      isProcessingPayment = true;
    });

    try {
      await Future.delayed(const Duration(seconds: 2));

      final CheckoutSummary summary = _buildSummary();

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
        cardMask: _maskedCardNumberForOrder(),
        deliveryAddress: deliveryAddress,
        recipientComment: recipientCommentController.text.trim(),
        promoCode: promoController.text.trim(),
      );

      if (!mounted) return;
      Get.offAll(() => const OrderSuccessScreen());
    } catch (e) {
      Get.snackbar(
        'Ошибка',
        'Не удалось оформить заказ: $e',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    } finally {
      if (mounted) {
        setState(() {
          isProcessingPayment = false;
        });
      }
    }
  }

  Future<void> _confirmOrder() async {
    _unfocusEverything();

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

    final PaymentMethodModel? selectedMethod = _selectedPaymentMethod;
    if (selectedMethod == null) {
      Get.snackbar('Ошибка', 'Выберите способ оплаты');
      return;
    }

    if (selectedMethod.isSbp) {
      final String? bank = await _showSbpBanksBottomSheet();
      if (!mounted || bank == null) return;

      setState(() {
        selectedSbpBank = bank;
      });
    }

    await _completeOrderFlow();
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
      crossAxisAlignment: CrossAxisAlignment.start,
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
          textAlign: TextAlign.right,
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
                ? (isDark
                ? AppColors.darkSurfaceElevated
                : AppColors.primaryLight)
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Radio<dynamic>(
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
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          address.title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: onSurface,
                          ),
                        ),
                        if (address.isPrimary)
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

  Widget _paymentMethodTile({
    required BuildContext context,
    required PaymentMethodModel method,
    required bool selected,
  }) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color onSurface = Theme.of(context).colorScheme.onSurface;

    final String subtitle;
    if (method.isSbp && selectedSbpBank != null) {
      subtitle = 'Выбран банк: $selectedSbpBank';
    } else {
      subtitle = method.subtitle;
    }

    return InkWell(
      onTap: () {
        _unfocusEverything();
        setState(() {
          selectedPaymentMethodId = method.id;
          if (!method.isSbp) {
            selectedSbpBank = null;
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Radio<String>(
              value: method.id,
              groupValue: selectedPaymentMethodId,
              onChanged: (String? newValue) {
                if (newValue == null) return;
                _unfocusEverything();
                setState(() {
                  selectedPaymentMethodId = newValue;
                  if (!method.isSbp) {
                    selectedSbpBank = null;
                  }
                });
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
                  Text(
                    method.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: onSurface,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurfaceSoft : Colors.white,
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
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurfaceSoft : Colors.white,
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
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentSection(BuildContext context) {
    return Obx(() {
      final List<PaymentMethodModel> methods = paymentController.paymentMethods
          .where((PaymentMethodModel item) => item.isActive)
          .toList();

      if (selectedPaymentMethodId == null && methods.isNotEmpty) {
        final PaymentMethodModel? defaultMethod =
            paymentController.selectedMethod.value;
        selectedPaymentMethodId = defaultMethod?.id ?? methods.first.id;
      }

      return _block(
        context,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle(context, 'Способ оплаты'),
            if (isPaymentMethodsLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (methods.isEmpty)
              Text(
                'Нет доступных способов оплаты. Добавьте карту в профиле.',
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.darkMutedForeground
                      : AppColors.mutedForeground,
                ),
              )
            else
              ...List.generate(methods.length, (int index) {
                final PaymentMethodModel method = methods[index];
                return Padding(
                  padding: EdgeInsets.only(bottom: index == methods.length - 1 ? 0 : 12),
                  child: _paymentMethodTile(
                    context: context,
                    method: method,
                    selected: selectedPaymentMethodId == method.id,
                  ),
                );
              }),
          ],
        ),
      );
    });
  }

  Future<void> _showAddAddressDialog() async {
    _unfocusEverything();

    final UserAddress? createdAddress = await Get.dialog<UserAddress>(
      const _CheckoutAddAddressDialog(initialIsPrimary: false),
      barrierDismissible: true,
    );

    if (!mounted || createdAddress == null) return;

    await addressBookController.addAddress(createdAddress);

    if (!mounted) return;
    setState(() {});
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
                        contentPadding: EdgeInsets.zero,
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
                        contentPadding: EdgeInsets.zero,
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
                        Expanded(
                          child: _sectionTitle(context, 'Адрес доставки'),
                        ),
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
                      color:
                      isDark ? AppColors.purpleLight : AppColors.primary,
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
                      height: 1.35,
                    ),
                  )
                else ...[
                  Text(
                    'Доступно бонусов: $bonusPoints',
                    style: TextStyle(
                      color: isDark
                          ? AppColors.darkMutedForeground
                          : AppColors.mutedForeground,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Slider(
                    value: bonusToUse.toDouble(),
                    min: 0,
                    max: summary.allowedBonuses.toDouble(),
                    divisions: summary.allowedBonuses <= 0
                        ? null
                        : summary.allowedBonuses,
                    label: '$bonusToUse',
                    onChanged: (double value) {
                      _unfocusEverything();
                      setState(() {
                        bonusToUse = value.round();
                      });
                    },
                  ),
                  Text(
                    'Списать: $bonusToUse бонусов',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: onSurface,
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
                _sectionTitle(context, 'Итого'),
                _summaryRow(
                  context,
                  'Товары',
                  '${summary.itemsTotal.toStringAsFixed(0)} ₽',
                ),
                const SizedBox(height: 10),
                _summaryRow(
                  context,
                  'Доставка',
                  summary.deliveryCost == 0
                      ? 'Бесплатно'
                      : '${summary.deliveryCost.toStringAsFixed(0)} ₽',
                ),
                const SizedBox(height: 10),
                _summaryRow(
                  context,
                  'Скидка бонусами',
                  summary.appliedBonuses > 0
                      ? '-${summary.appliedBonuses.toStringAsFixed(0)} ₽'
                      : '0 ₽',
                  highlight: summary.appliedBonuses > 0,
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Divider(height: 1),
                ),
                _summaryRow(
                  context,
                  'К оплате',
                  '${summary.payableTotal.toStringAsFixed(0)} ₽',
                  highlight: true,
                ),
              ],
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient:
              isDark ? AppColors.darkBrandGradient : AppColors.brandGradient,
              borderRadius: BorderRadius.circular(22),
            ),
            child: ElevatedButton(
              onPressed: isProcessingPayment ? null : _confirmOrder,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
              ),
              child: isProcessingPayment
                  ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: Colors.white,
                ),
              )
                  : Text(
                _bottomButtonLabel,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _SbpBankPickerBottomSheet extends StatefulWidget {
  final List<String> banks;
  final String? selectedBank;

  const _SbpBankPickerBottomSheet({
    required this.banks,
    this.selectedBank,
  });

  @override
  State<_SbpBankPickerBottomSheet> createState() =>
      _SbpBankPickerBottomSheetState();
}

class _SbpBankPickerBottomSheetState extends State<_SbpBankPickerBottomSheet> {
  late final TextEditingController searchController;
  late List<String> filteredBanks;

  @override
  void initState() {
    super.initState();
    searchController = TextEditingController();
    filteredBanks = List<String>.from(widget.banks);
    searchController.addListener(_handleSearch);
  }

  @override
  void dispose() {
    searchController.removeListener(_handleSearch);
    searchController.dispose();
    super.dispose();
  }

  void _handleSearch() {
    final String query = searchController.text.trim().toLowerCase();

    setState(() {
      if (query.isEmpty) {
        filteredBanks = List<String>.from(widget.banks);
      } else {
        filteredBanks = widget.banks
            .where((bank) => bank.toLowerCase().contains(query))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.72,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 46,
                height: 5,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkMutedForeground.withOpacity(0.35)
                      : AppColors.mutedForeground.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Выберите банк',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Для оплаты через СБП выберите ваш банк из списка ниже',
              style: TextStyle(
                fontSize: 13,
                height: 1.35,
                color: isDark
                    ? AppColors.darkMutedForeground
                    : AppColors.mutedForeground,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: searchController,
              decoration: const InputDecoration(
                hintText: 'Поиск банка',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: filteredBanks.isEmpty
                  ? Center(
                child: Text(
                  'Банк не найден',
                  style: TextStyle(
                    color: isDark
                        ? AppColors.darkMutedForeground
                        : AppColors.mutedForeground,
                  ),
                ),
              )
                  : ListView.separated(
                itemCount: filteredBanks.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (BuildContext context, int index) {
                  final String bank = filteredBanks[index];
                  final bool selected = widget.selectedBank == bank;

                  return InkWell(
                    onTap: () => Navigator.of(context).pop(bank),
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: selected
                            ? (isDark
                            ? AppColors.darkSurfaceElevated
                            : AppColors.primaryLight)
                            : (isDark
                            ? AppColors.darkSurfaceSoft
                            : const Color(0xFFF8F5F6)),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: selected
                              ? (isDark
                              ? AppColors.purpleLight
                              : AppColors.primary)
                              : (isDark
                              ? AppColors.darkBorder
                              : AppColors.border),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              gradient: selected
                                  ? (isDark
                                  ? AppColors.darkBrandGradient
                                  : AppColors.brandGradient)
                                  : null,
                              color: selected
                                  ? null
                                  : (isDark
                                  ? AppColors.darkSurfaceElevated
                                  : Colors.white),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              Icons.account_balance_rounded,
                              color: selected
                                  ? Colors.white
                                  : (isDark
                                  ? AppColors.purpleLight
                                  : AppColors.primary),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              bank,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: isDark
                                ? AppColors.purpleLight
                                : AppColors.primary,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
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

  late bool isPrimary;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController();
    addressController = TextEditingController();
    entranceController = TextEditingController();
    floorController = TextEditingController();
    apartmentController = TextEditingController();
    commentController = TextEditingController();
    isPrimary = widget.initialIsPrimary;
  }

  @override
  void dispose() {
    titleController.dispose();
    addressController.dispose();
    entranceController.dispose();
    floorController.dispose();
    apartmentController.dispose();
    commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      title: const Text('Новый адрес'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Название',
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
          onPressed: Get.back,
          child: const Text('Отмена'),
        ),
        ElevatedButton(
          onPressed: () {
            if (addressController.text.trim().isEmpty) {
              Get.snackbar('Ошибка', 'Введите адрес');
              return;
            }

            Navigator.of(context).pop(
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
          },
          child: const Text('Сохранить'),
        ),
      ],
    );
  }
}
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
import '../../models/product.dart';
import '../../models/user_address.dart';
import '../../utils/app_colors.dart';
import '../../widgets/address_form_sheet.dart';
import 'order_success_screen.dart';

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

  List<UserAddress> _localAddresses = <UserAddress>[];
  UserAddress? _localSelectedAddress;
  bool _isLoadingAddresses = true;

  List<PaymentMethodModel> _localPaymentMethods = <PaymentMethodModel>[];
  PaymentMethodModel? _localSelectedPayment;
  bool _isLoadingPayments = true;

  double _cartTotalPrice = 0.0;
  List<_LocalCartItem> _cartItems = <_LocalCartItem>[];
  int _userBonusPoints = 0;

  bool _isSubmitting = false;

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
    try {
      await addressBookController.loadAddresses();
      await paymentController.loadPaymentMethods();

      if (!mounted) {
        return;
      }

      setState(() {
        _localAddresses = List<UserAddress>.from(addressBookController.addresses);
        _localSelectedAddress = addressBookController.selectedAddress;

        _isLoadingAddresses = false;

        _localPaymentMethods =
        List<PaymentMethodModel>.from(paymentController.paymentMethods);
        _localSelectedPayment = paymentController.selectedPaymentMethod;

        _isLoadingPayments = false;

        _cartTotalPrice = cartController.totalPrice;
        _cartItems = cartController.items
            .map(
              (item) => _LocalCartItem(
            product: item.product,
            quantity: item.quantity.value,
          ),
        )
            .toList();

        _userBonusPoints = authController.user.value?.loyaltyPoints ?? 0;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoadingAddresses = false;
        _isLoadingPayments = false;
      });

      _showCheckoutError('Не удалось загрузить данные оформления заказа: $e');
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

  void _showCheckoutWarning(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
  }

  void _showCheckoutSuccess(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
          backgroundColor: AppColors.success,
        ),
      );
  }

  void _showCheckoutError(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
          backgroundColor: AppColors.danger,
        ),
      );
  }

  Future<void> _confirmOrder() async {
    if (_isSubmitting) {
      return;
    }

    if (_isLoadingAddresses || _isLoadingPayments) {
      _showCheckoutWarning(
        'Данные заказа ещё загружаются. Подождите несколько секунд и попробуйте снова.',
      );
      return;
    }

    if (!_canCheckout) {
      _showCheckoutWarning(
        'Корзина пуста. Добавьте товары перед оформлением заказа.',
      );
      return;
    }

    if (!authController.isLoggedIn) {
      _showCheckoutWarning(
        'Для оформления заказа необходимо войти в аккаунт.',
      );
      return;
    }

    final UserAddress? selectedAddress = _localSelectedAddress;
    final PaymentMethodModel? selectedPayment = _localSelectedPayment;

    if (deliveryMethod == DeliveryMethod.delivery) {
      if (_localAddresses.isEmpty) {
        _showCheckoutWarning(
          'У вас нет сохранённых адресов. Добавьте адрес доставки перед оформлением заказа.',
        );
        return;
      }

      if (selectedAddress == null) {
        _showCheckoutWarning(
          'Выберите адрес доставки перед оформлением заказа.',
        );
        return;
      }

      final bool addressExists = _localAddresses.any(
            (UserAddress address) => address.id == selectedAddress.id,
      );

      if (!addressExists) {
        _showCheckoutWarning(
          'Выбранный адрес больше не найден. Выберите другой адрес или добавьте новый.',
        );
        return;
      }

      if (selectedAddress.fullAddress.trim().isEmpty ||
          selectedAddress.city.trim().isEmpty ||
          selectedAddress.street.trim().isEmpty ||
          selectedAddress.house.trim().isEmpty) {
        _showCheckoutWarning(
          'Адрес доставки заполнен не полностью. Проверьте город, улицу и дом.',
        );
        return;
      }
    }

    if (selectedPayment == null) {
      _showCheckoutWarning(
        'Выберите способ оплаты заказа.',
      );
      return;
    }

    final CheckoutSummary summary = _buildSummary();

    if (bonusToUse > summary.allowedBonuses) {
      setState(() {
        bonusToUse = summary.allowedBonuses;
      });

      _showCheckoutWarning(
        'Количество бонусов было скорректировано под сумму заказа.',
      );
      return;
    }

    final String deliveryAddress = deliveryMethod == DeliveryMethod.pickup
        ? 'Самовывоз'
        : selectedAddress!.fullAddress.trim();

    final String paymentMethod = selectedPayment.isCard
        ? 'card'
        : selectedPayment.isSbp
        ? 'sbp'
        : 'cash';

    final String paymentStatus = selectedPayment.isCash ? 'pending' : 'paid';

    final String cardMask =
    selectedPayment.isCard ? selectedPayment.maskedNumber : '';

    try {
      setState(() {
        _isSubmitting = true;
      });

      final List<model.CartItem> items = _cartItems
          .map(
            (item) => model.CartItem(
          product: item.product,
          quantity: item.quantity,
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
        recipientPhone: selectedAddress?.phone ??
            authController.user.value?.phone ??
            '',
        recipientComment: recipientCommentController.text.trim(),
        promoCode: promoController.text.trim(),
      );

      if (!mounted) {
        return;
      }

      Get.offAll(() => const OrderSuccessScreen());
    } catch (e) {
      _showCheckoutError('Не удалось оформить заказ: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _showAddAddressSheet() async {
    final UserAddress? result = await AddressFormSheet.show(
      context,
      isFirstAddress: _localAddresses.isEmpty,
    );

    if (result == null) {
      return;
    }

    try {
      await addressBookController.addAddress(result);

      if (!mounted) {
        return;
      }

      setState(() {
        _localAddresses = List<UserAddress>.from(addressBookController.addresses);
        _localSelectedAddress = addressBookController.selectedAddress;
        _isLoadingAddresses = false;
      });

      _showCheckoutSuccess('Новый адрес выбран для доставки.');
    } catch (e) {
      _showCheckoutError('Не удалось сохранить адрес: $e');
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

  Widget _block(
      BuildContext context, {
        required Widget child,
      }) {
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
                ? AppColors.purple.withOpacity(0.05)
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
              ? AppColors.purple.withOpacity(0.14)
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
                                ? AppColors.purple.withOpacity(0.16)
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
                  if (address.comment.trim().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      address.comment,
                      style: TextStyle(
                        color: isDark
                            ? AppColors.darkMutedForeground
                            : AppColors.mutedForeground,
                        fontSize: 12,
                      ),
                    ),
                  ],
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
              ? AppColors.purple.withOpacity(0.14)
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

  Widget _buildCartItem(
      BuildContext context,
      _LocalCartItem item,
      ) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color onSurface = Theme.of(context).colorScheme.onSurface;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceElevated : AppColors.primaryLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : Colors.transparent,
        ),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: item.product.imageUrl.trim().isEmpty
                ? Container(
              width: 56,
              height: 56,
              color: isDark
                  ? AppColors.darkSurfaceSoft
                  : const Color(0xFFF8EFF3),
              child: Icon(
                Icons.local_florist_outlined,
                color: isDark ? AppColors.purple : AppColors.primary,
              ),
            )
                : Image.network(
              item.product.imageUrl,
              width: 56,
              height: 56,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) {
                return Container(
                  width: 56,
                  height: 56,
                  color: isDark
                      ? AppColors.darkSurfaceSoft
                      : const Color(0xFFF8EFF3),
                  child: Icon(
                    Icons.image_not_supported_outlined,
                    color:
                    isDark ? AppColors.purple : AppColors.primary,
                  ),
                );
              },
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
              color: isDark ? AppColors.purpleLight : AppColors.primary,
            ),
          ),
        ],
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

  Widget _buildSubmitButton(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    String buttonText = 'Оформить заказ';

    if (_localSelectedPayment?.isSbp == true) {
      buttonText = 'Оплатить по СБП';
    } else if (_localSelectedPayment?.isCard == true) {
      buttonText = 'Оплатить картой';
    }

    return DecoratedBox(
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
        onPressed: _isSubmitting ? null : _confirmOrder,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          disabledBackgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: Colors.white,
          disabledForegroundColor: Colors.white.withOpacity(0.85),
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: _isSubmitting
            ? const SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2.4,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        )
            : Text(
          buttonText,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
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
        body: const Center(
          child: CircularProgressIndicator(),
        ),
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
              _block(
                context,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle(context, 'Ваш заказ'),
                    if (_cartItems.isEmpty)
                      Text(
                        'Корзина пуста',
                        style: TextStyle(
                          color: isDark
                              ? AppColors.darkMutedForeground
                              : AppColors.mutedForeground,
                        ),
                      )
                    else
                      ..._cartItems.map(
                            (item) => _buildCartItem(context, item),
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
                            activeColor:
                            isDark ? AppColors.purple : AppColors.primary,
                            onChanged: (DeliveryMethod? value) {
                              if (value == null) {
                                return;
                              }

                              setState(() {
                                deliveryMethod = value;
                                final CheckoutSummary fixedSummary =
                                CheckoutSummary.calculate(
                                  itemsTotal: _cartTotalPrice,
                                  availableBonuses: _userBonusPoints,
                                  requestedBonuses: bonusToUse,
                                  deliveryMethod: value,
                                );

                                bonusToUse = bonusToUse.clamp(
                                  0,
                                  fixedSummary.allowedBonuses,
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
                            onChanged: (DeliveryMethod? value) {
                              if (value == null) {
                                return;
                              }

                              setState(() {
                                deliveryMethod = value;
                                final CheckoutSummary fixedSummary =
                                CheckoutSummary.calculate(
                                  itemsTotal: _cartTotalPrice,
                                  availableBonuses: _userBonusPoints,
                                  requestedBonuses: bonusToUse,
                                  deliveryMethod: value,
                                );

                                bonusToUse = bonusToUse.clamp(
                                  0,
                                  fixedSummary.allowedBonuses,
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
                            onPressed: _showAddAddressSheet,
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
                            'У вас пока нет сохранённых адресов.\nДобавьте новый адрес перед оформлением доставки.',
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
              _block(
                context,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle(context, 'Способ оплаты'),
                    if (_localPaymentMethods.isEmpty)
                      Text(
                        'Способы оплаты не найдены',
                        style: TextStyle(
                          color: isDark
                              ? AppColors.darkMutedForeground
                              : AppColors.mutedForeground,
                        ),
                      )
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
                              activeTrackColor:
                              isDark ? AppColors.purple : AppColors.primary,
                              thumbColor:
                              isDark ? AppColors.purple : AppColors.primary,
                              inactiveTrackColor: isDark
                                  ? AppColors.darkBorderSoft
                                  : AppColors.primaryLight,
                              overlayColor:
                              (isDark ? AppColors.purple : AppColors.primary)
                                  .withOpacity(0.15),
                            ),
                            child: Slider(
                              value: bonusToUse.toDouble(),
                              min: 0,
                              max: summary.allowedBonuses.toDouble(),
                              divisions: summary.allowedBonuses,
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
                  gradient:
                  isDark ? AppColors.darkBrandGradient : AppColors.brandGradient,
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
              _buildSubmitButton(context),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
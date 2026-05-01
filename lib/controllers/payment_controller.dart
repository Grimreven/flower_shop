import 'dart:convert';

import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../controllers/auth_controller.dart';
import '../models/payment_method_model.dart';
import '../models/payment_transaction_model.dart';

class PaymentController extends GetxController {
  final GetStorage _storage = GetStorage();

  final RxList<PaymentMethodModel> paymentMethods = <PaymentMethodModel>[].obs;
  final RxnString selectedPaymentMethodId = RxnString();
  final RxBool isLoading = false.obs;

  AuthController get authController => Get.find<AuthController>();

  String get _storageKey {
    final int userId = authController.user.value?.id ?? 0;
    return 'payment_methods_user_$userId';
  }

  List<PaymentMethodModel> get methods => paymentMethods;

  PaymentMethodModel? get selectedMethod => selectedPaymentMethod;

  PaymentMethodModel? get selectedPaymentMethod {
    final String? id = selectedPaymentMethodId.value;

    if (id == null) {
      return defaultPaymentMethod;
    }

    return paymentMethods.firstWhereOrNull((item) => item.id == id) ??
        defaultPaymentMethod;
  }

  PaymentMethodModel? get defaultPaymentMethod {
    return paymentMethods.firstWhereOrNull((item) => item.isDefault) ??
        paymentMethods.firstOrNull;
  }

  @override
  void onInit() {
    super.onInit();
    loadPaymentMethods();
  }

  Future<void> loadPaymentMethods() async {
    isLoading.value = true;

    final result = <PaymentMethodModel>[
      PaymentMethodModel.cash(),
      PaymentMethodModel.sbp(),
    ];

    final raw = _storage.read<List<dynamic>>(_storageKey);

    if (raw != null) {
      result.addAll(
        raw.map((item) {
          if (item is String) {
            return PaymentMethodModel.fromJson(
              Map<String, dynamic>.from(jsonDecode(item) as Map),
            );
          }

          return PaymentMethodModel.fromJson(
            Map<String, dynamic>.from(item as Map),
          );
        }),
      );
    }

    if (!result.any((item) => item.isDefault)) {
      result[0] = result[0].copyWith(isDefault: true);
    }

    paymentMethods.assignAll(result);
    selectedPaymentMethodId.value = defaultPaymentMethod?.id ?? result.first.id;

    isLoading.value = false;
  }

  Future<void> addCardMethod({
    required String cardNumber,
    String holderName = '',
    required dynamic expiryMonth,
    required dynamic expiryYear,
    String bankName = 'Банковская карта',
    bool setAsDefault = false,
  }) async {
    final digits = cardNumber.replaceAll(RegExp(r'[^0-9]'), '');

    if (digits.length < 12) {
      throw Exception('Введите корректный номер карты');
    }

    final last4 = digits.substring(digits.length - 4);

    final card = PaymentMethodModel.card(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: authController.user.value?.id,
      last4: last4,
      bankName: bankName,
      maskedNumber: '•••• •••• •••• $last4',
      expiryMonth: expiryMonth.toString(),
      expiryYear: expiryYear.toString(),
      isDefault: setAsDefault || !paymentMethods.any((item) => item.isCard),
    );

    if (card.isDefault) {
      paymentMethods.assignAll(
        paymentMethods.map((item) => item.copyWith(isDefault: false)).toList(),
      );
    }

    paymentMethods.add(card);
    selectedPaymentMethodId.value = card.id;

    await _saveCards();
  }

  Future<void> addCard({
    required String cardNumber,
    required String holderName,
    required String expiryDate,
    String bankName = 'Банковская карта',
  }) async {
    final parts = expiryDate.split('/');

    await addCardMethod(
      cardNumber: cardNumber,
      holderName: holderName,
      expiryMonth: parts.isNotEmpty ? parts[0] : '12',
      expiryYear: parts.length > 1 ? '20${parts[1]}' : '2030',
      bankName: bankName,
    );
  }

  Future<void> updateCardMethod({
    required String id,
    String? cardNumber,
    String holderName = '',
    dynamic expiryMonth,
    dynamic expiryYear,
    String bankName = 'Банковская карта',
    bool? isDefault,
  }) async {
    final index = paymentMethods.indexWhere((item) => item.id == id);

    if (index == -1) {
      return;
    }

    final old = paymentMethods[index];

    String last4 = old.cardLast4;
    String masked = old.maskedNumber;

    if (cardNumber != null && cardNumber.isNotEmpty) {
      final digits = cardNumber.replaceAll(RegExp(r'[^0-9]'), '');

      if (digits.length < 12) {
        throw Exception('Введите корректный номер карты');
      }

      last4 = digits.substring(digits.length - 4);
      masked = '•••• •••• •••• $last4';
    }

    if (isDefault == true) {
      paymentMethods.assignAll(
        paymentMethods.map((item) => item.copyWith(isDefault: false)).toList(),
      );
    }

    paymentMethods[index] = old.copyWith(
      title: 'Карта •••• $last4',
      subtitle: bankName,
      cardLast4: last4,
      bankName: bankName,
      maskedNumber: masked,
      expiryMonth: expiryMonth?.toString() ?? old.expiryMonth,
      expiryYear: expiryYear?.toString() ?? old.expiryYear,
      isDefault: isDefault ?? old.isDefault,
      updatedAt: DateTime.now(),
    );

    await _saveCards();
  }

  Future<void> setDefaultMethod(String id) async {
    paymentMethods.assignAll(
      paymentMethods.map((item) {
        return item.copyWith(
          isDefault: item.id == id,
          updatedAt: DateTime.now(),
        );
      }).toList(),
    );

    selectedPaymentMethodId.value = id;

    await _saveCards();
  }

  Future<void> setDefaultPaymentMethod(String id) async {
    await setDefaultMethod(id);
  }

  Future<void> deleteMethod(String id) async {
    final method = paymentMethods.firstWhereOrNull((item) => item.id == id);

    if (method == null || method.isSystem) {
      return;
    }

    paymentMethods.removeWhere((item) => item.id == id);

    if (selectedPaymentMethodId.value == id) {
      selectedPaymentMethodId.value =
          defaultPaymentMethod?.id ?? paymentMethods.first.id;
    }

    await _saveCards();
  }

  Future<void> deleteCard(String id) async {
    await deleteMethod(id);
  }

  Future<void> removePaymentMethod(String id) async {
    await deleteMethod(id);
  }

  Future<void> selectPaymentMethod(String id) async {
    selectedPaymentMethodId.value = id;
  }

  Future<void> loadPaymentTransactions() async {}

  List<PaymentTransactionModel> getPaymentsForOrderLocal(int orderId) {
    return <PaymentTransactionModel>[];
  }

  Future<void> _saveCards() async {
    final cards = paymentMethods
        .where((item) => item.isCard)
        .map((item) => item.toJson())
        .toList();

    await _storage.write(_storageKey, cards);
  }

  void clear() {
    paymentMethods.clear();
    selectedPaymentMethodId.value = null;
  }
}
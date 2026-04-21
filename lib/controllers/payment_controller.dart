import 'package:get/get.dart';

import '../api/demo_payment_gateway.dart';
import '../api/payment_service.dart';
import '../models/payment_method_model.dart';
import '../models/payment_transaction_model.dart';
import 'auth_controller.dart';

class PaymentController extends GetxController {
  final AuthController authController;

  late PaymentService _paymentService;

  final RxList<PaymentMethodModel> paymentMethods = <PaymentMethodModel>[].obs;
  final RxList<PaymentTransactionModel> paymentTransactions =
      <PaymentTransactionModel>[].obs;

  final Rxn<PaymentMethodModel> selectedMethod = Rxn<PaymentMethodModel>();
  final RxBool isLoading = false.obs;
  final RxBool isProcessingPayment = false.obs;
  final Rxn<PaymentTransactionModel> lastTransaction =
  Rxn<PaymentTransactionModel>();

  PaymentController({
    required this.authController,
  });

  @override
  void onInit() {
    super.onInit();
    _paymentService = PaymentService(token: authController.token.value);

    ever<String?>(authController.token, (String? newToken) async {
      if (newToken != null && newToken.isNotEmpty) {
        _paymentService = PaymentService(token: newToken);
        await loadPaymentMethods();
        await loadPaymentTransactions();
      } else {
        paymentMethods.clear();
        paymentTransactions.clear();
        selectedMethod.value = null;
        lastTransaction.value = null;
      }
    });
  }

  Future<void> loadPaymentMethods() async {
    if (authController.token.isEmpty) {
      return;
    }

    isLoading.value = true;

    try {
      final List<PaymentMethodModel> items =
      await _paymentService.getPaymentMethods();

      paymentMethods.assignAll(items);

      PaymentMethodModel? defaultMethod;
      try {
        defaultMethod =
            items.firstWhere((PaymentMethodModel item) => item.isDefault);
      } catch (_) {
        defaultMethod = items.isNotEmpty ? items.first : null;
      }

      selectedMethod.value = defaultMethod;
    } catch (e) {
      Get.snackbar('Ошибка', 'Не удалось загрузить способы оплаты: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadPaymentTransactions() async {
    if (authController.token.isEmpty) {
      return;
    }

    try {
      final List<PaymentTransactionModel> items =
      await _paymentService.getPaymentTransactions();
      paymentTransactions.assignAll(items);
    } catch (e) {
      Get.snackbar('Ошибка', 'Не удалось загрузить историю платежей: $e');
    }
  }

  void selectMethod(PaymentMethodModel method) {
    selectedMethod.value = method;
  }

  Future<void> addCardMethod({
    required String cardNumber,
    required String expiryMonth,
    required String expiryYear,
    bool setAsDefault = false,
  }) async {
    final int userId = authController.user.value?.id ?? 0;
    if (userId == 0) {
      throw Exception('Пользователь не найден');
    }

    final DemoPaymentGateway gateway = DemoPaymentGateway.instance;
    final DateTime now = DateTime.now();
    final String masked = gateway.maskCardNumber(cardNumber);
    final String brand = gateway.detectCardBrand(cardNumber);

    final PaymentMethodModel method = PaymentMethodModel(
      id: 'card_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      type: PaymentMethodType.bankCard,
      title: '$brand $masked',
      holderName: null,
      maskedNumber: masked,
      bankName: null,
      cardBrand: brand,
      expiryMonth: expiryMonth,
      expiryYear: expiryYear,
      token: gateway.makeLocalToken(),
      isDefault: setAsDefault || paymentMethods.isEmpty,
      isActive: true,
      isSystem: false,
      createdAt: now,
      updatedAt: now,
    );

    await _paymentService.addPaymentMethod(method);
    await loadPaymentMethods();
  }

  Future<void> updateCardMethod({
    required String id,
    required String expiryMonth,
    required String expiryYear,
    required bool isDefault,
  }) async {
    final PaymentMethodModel existing = paymentMethods.firstWhere(
          (PaymentMethodModel item) => item.id == id,
    );

    final String brand = existing.cardBrand ?? 'Карта';
    final String masked = existing.maskedNumber ?? '****';

    final PaymentMethodModel updated = existing.copyWith(
      title: '$brand $masked',
      expiryMonth: expiryMonth,
      expiryYear: expiryYear,
      isDefault: isDefault,
      updatedAt: DateTime.now(),
    );

    await _paymentService.updatePaymentMethod(updated);
    await loadPaymentMethods();
  }

  Future<void> deleteMethod(String id) async {
    await _paymentService.deletePaymentMethod(id);
    await loadPaymentMethods();
  }

  Future<void> setDefaultMethod(String id) async {
    await _paymentService.setDefaultPaymentMethod(id);
    await loadPaymentMethods();
  }

  Future<PaymentTransactionModel> processOrderPayment({
    required int orderId,
    required double amount,
    required PaymentMethodModel method,
    String? cardNumber,
    String? cvv,
  }) async {
    final int userId = authController.user.value?.id ?? 0;
    if (userId == 0) {
      throw Exception('Пользователь не найден');
    }

    isProcessingPayment.value = true;

    try {
      final DemoPaymentResult result =
      await DemoPaymentGateway.instance.processPayment(
        userId: userId,
        orderId: orderId,
        amount: amount,
        method: method,
        cardNumber: cardNumber,
        cvv: cvv,
      );

      await _paymentService.savePaymentTransaction(result.transaction);
      await loadPaymentTransactions();

      lastTransaction.value = result.transaction;
      return result.transaction;
    } finally {
      isProcessingPayment.value = false;
    }
  }

  Future<PaymentTransactionModel?> getLatestPaymentForOrder(int orderId) async {
    return _paymentService.getLatestPaymentForOrder(orderId);
  }

  List<PaymentTransactionModel> getPaymentsForOrderLocal(int orderId) {
    return paymentTransactions
        .where((PaymentTransactionModel e) => e.orderId == orderId)
        .toList();
  }
}
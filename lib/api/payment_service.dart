import '../models/payment_method_model.dart';
import '../models/payment_transaction_model.dart';
import 'local_demo_service.dart';

class PaymentService {
  final String token;
  final LocalDemoService _localDemoService = LocalDemoService.instance;

  PaymentService({
    required this.token,
  });

  Future<List<PaymentMethodModel>> getPaymentMethods() async {
    return _localDemoService.getPaymentMethods(token);
  }

  Future<void> addPaymentMethod(PaymentMethodModel method) async {
    await _localDemoService.addPaymentMethod(token, method);
  }

  Future<void> updatePaymentMethod(PaymentMethodModel method) async {
    await _localDemoService.updatePaymentMethod(token, method);
  }

  Future<void> deletePaymentMethod(String methodId) async {
    await _localDemoService.deletePaymentMethod(token, methodId);
  }

  Future<void> setDefaultPaymentMethod(String methodId) async {
    await _localDemoService.setDefaultPaymentMethod(token, methodId);
  }

  Future<List<PaymentTransactionModel>> getPaymentTransactions() async {
    return _localDemoService.getPaymentTransactions(token);
  }

  Future<List<PaymentTransactionModel>> getPaymentsForOrder(int orderId) async {
    return _localDemoService.getPaymentsForOrder(token, orderId);
  }

  Future<PaymentTransactionModel?> getLatestPaymentForOrder(int orderId) async {
    return _localDemoService.getLatestPaymentForOrder(token, orderId);
  }

  Future<void> savePaymentTransaction(PaymentTransactionModel transaction) async {
    await _localDemoService.savePaymentTransaction(token, transaction);
  }
}
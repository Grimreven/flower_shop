import 'dart:async';
import 'dart:math';

import '../models/payment_method_model.dart';
import '../models/payment_transaction_model.dart';

class DemoPaymentResult {
  final PaymentTransactionModel transaction;
  final bool success;

  const DemoPaymentResult({
    required this.transaction,
    required this.success,
  });
}

class DemoPaymentGateway {
  DemoPaymentGateway._();

  static final DemoPaymentGateway instance = DemoPaymentGateway._();

  Future<DemoPaymentResult> processPayment({
    required int userId,
    required int orderId,
    required double amount,
    required PaymentMethodModel method,
    String? cardNumber,
    String? cvv,
  }) async {
    await Future<void>.delayed(const Duration(seconds: 2));

    if (method.type == PaymentMethodType.cash) {
      return DemoPaymentResult(
        success: true,
        transaction: PaymentTransactionModel(
          id: 'pay_${DateTime.now().millisecondsSinceEpoch}',
          userId: userId,
          orderId: orderId,
          paymentMethodId: method.id,
          provider: 'demo_gateway',
          amount: amount,
          status: PaymentTransactionStatus.pendingCash,
          externalTransactionId: 'cash_$orderId',
          paymentMethodTitle: method.title,
          paymentMethodSubtitle: method.subtitle,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
    }

    final String normalizedCard = (cardNumber ?? '').replaceAll(' ', '');
    final String normalizedCvv = (cvv ?? '').trim();

    if (method.type == PaymentMethodType.bankCard) {
      if (normalizedCvv == '000') {
        return DemoPaymentResult(
          success: false,
          transaction: PaymentTransactionModel(
            id: 'pay_${DateTime.now().millisecondsSinceEpoch}',
            userId: userId,
            orderId: orderId,
            paymentMethodId: method.id,
            provider: 'demo_gateway',
            amount: amount,
            status: PaymentTransactionStatus.failed,
            externalTransactionId: 'fail_$orderId',
            failureReason: 'Неверный CVV/CVC код',
            paymentMethodTitle: method.title,
            paymentMethodSubtitle: method.subtitle,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
      }

      if (normalizedCard.endsWith('0002')) {
        return DemoPaymentResult(
          success: false,
          transaction: PaymentTransactionModel(
            id: 'pay_${DateTime.now().millisecondsSinceEpoch}',
            userId: userId,
            orderId: orderId,
            paymentMethodId: method.id,
            provider: 'demo_gateway',
            amount: amount,
            status: PaymentTransactionStatus.failed,
            externalTransactionId: 'declined_$orderId',
            failureReason: 'Платёж отклонён банком-эмитентом',
            paymentMethodTitle: method.title,
            paymentMethodSubtitle: method.subtitle,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
      }
    }

    if (method.type == PaymentMethodType.sbp) {
      final bool success = Random().nextInt(100) >= 10;
      return DemoPaymentResult(
        success: success,
        transaction: PaymentTransactionModel(
          id: 'pay_${DateTime.now().millisecondsSinceEpoch}',
          userId: userId,
          orderId: orderId,
          paymentMethodId: method.id,
          provider: 'demo_gateway',
          amount: amount,
          status: success
              ? PaymentTransactionStatus.paid
              : PaymentTransactionStatus.failed,
          externalTransactionId: 'sbp_${DateTime.now().millisecondsSinceEpoch}',
          failureReason: success ? null : 'Пользователь не подтвердил оплату',
          paymentMethodTitle: method.title,
          paymentMethodSubtitle: method.subtitle,
          createdAt: DateTime.now(),
          confirmedAt: success ? DateTime.now() : null,
          updatedAt: DateTime.now(),
        ),
      );
    }

    return DemoPaymentResult(
      success: true,
      transaction: PaymentTransactionModel(
        id: 'pay_${DateTime.now().millisecondsSinceEpoch}',
        userId: userId,
        orderId: orderId,
        paymentMethodId: method.id,
        provider: 'demo_gateway',
        amount: amount,
        status: PaymentTransactionStatus.paid,
        externalTransactionId: 'txn_${DateTime.now().millisecondsSinceEpoch}',
        paymentMethodTitle: method.title,
        paymentMethodSubtitle: method.subtitle,
        createdAt: DateTime.now(),
        confirmedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
  }

  String detectCardBrand(String cardNumber) {
    final String digits = cardNumber.replaceAll(RegExp(r'[^0-9]'), '');

    if (digits.startsWith('4')) {
      return 'Visa';
    }

    if (digits.startsWith('2200') ||
        digits.startsWith('2201') ||
        digits.startsWith('2202') ||
        digits.startsWith('2203') ||
        digits.startsWith('2204') ||
        digits.startsWith('2')) {
      return 'Мир';
    }

    if (digits.startsWith('5')) {
      return 'Mastercard';
    }

    return 'Банковская карта';
  }

  String maskCardNumber(String cardNumber) {
    final String digits = cardNumber.replaceAll(RegExp(r'[^0-9]'), '');

    if (digits.length < 4) {
      return '****';
    }

    final String last4 = digits.substring(digits.length - 4);
    return '**** **** **** $last4';
  }

  String makeLocalToken() {
    return 'demo_token_${DateTime.now().millisecondsSinceEpoch}';
  }
}
enum PaymentTransactionStatus {
  created,
  pending,
  paid,
  failed,
  cancelled,
  refunded,
  pendingCash,
}

class PaymentTransactionModel {
  final String id;
  final int userId;
  final int orderId;
  final String paymentMethodId;
  final String provider;
  final double amount;
  final PaymentTransactionStatus status;
  final String? externalTransactionId;
  final String? failureReason;
  final String? paymentMethodTitle;
  final String? paymentMethodSubtitle;
  final DateTime createdAt;
  final DateTime? confirmedAt;
  final DateTime? updatedAt;

  const PaymentTransactionModel({
    required this.id,
    required this.userId,
    required this.orderId,
    required this.paymentMethodId,
    required this.provider,
    required this.amount,
    required this.status,
    this.externalTransactionId,
    this.failureReason,
    this.paymentMethodTitle,
    this.paymentMethodSubtitle,
    required this.createdAt,
    this.confirmedAt,
    this.updatedAt,
  });

  PaymentTransactionModel copyWith({
    String? id,
    int? userId,
    int? orderId,
    String? paymentMethodId,
    String? provider,
    double? amount,
    PaymentTransactionStatus? status,
    String? externalTransactionId,
    String? failureReason,
    String? paymentMethodTitle,
    String? paymentMethodSubtitle,
    DateTime? createdAt,
    DateTime? confirmedAt,
    DateTime? updatedAt,
  }) {
    return PaymentTransactionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      orderId: orderId ?? this.orderId,
      paymentMethodId: paymentMethodId ?? this.paymentMethodId,
      provider: provider ?? this.provider,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      externalTransactionId:
      externalTransactionId ?? this.externalTransactionId,
      failureReason: failureReason ?? this.failureReason,
      paymentMethodTitle: paymentMethodTitle ?? this.paymentMethodTitle,
      paymentMethodSubtitle:
      paymentMethodSubtitle ?? this.paymentMethodSubtitle,
      createdAt: createdAt ?? this.createdAt,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get statusLabel {
    switch (status) {
      case PaymentTransactionStatus.created:
        return 'Создан';
      case PaymentTransactionStatus.pending:
        return 'Ожидает подтверждения';
      case PaymentTransactionStatus.paid:
        return 'Оплачено';
      case PaymentTransactionStatus.failed:
        return 'Ошибка оплаты';
      case PaymentTransactionStatus.cancelled:
        return 'Отменён';
      case PaymentTransactionStatus.refunded:
        return 'Возврат';
      case PaymentTransactionStatus.pendingCash:
        return 'Оплата при получении';
    }
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'user_id': userId,
      'order_id': orderId,
      'payment_method_id': paymentMethodId,
      'provider': provider,
      'amount': amount,
      'status': status.name,
      'external_transaction_id': externalTransactionId,
      'failure_reason': failureReason,
      'payment_method_title': paymentMethodTitle,
      'payment_method_subtitle': paymentMethodSubtitle,
      'created_at': createdAt.toIso8601String(),
      'confirmed_at': confirmedAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory PaymentTransactionModel.fromJson(Map<String, dynamic> json) {
    return PaymentTransactionModel(
      id: json['id']?.toString() ?? '',
      userId: (json['user_id'] as num?)?.toInt() ?? 0,
      orderId: (json['order_id'] as num?)?.toInt() ?? 0,
      paymentMethodId: json['payment_method_id']?.toString() ?? '',
      provider: json['provider']?.toString() ?? 'demo_gateway',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      status: _parseStatus(json['status']?.toString()),
      externalTransactionId: json['external_transaction_id']?.toString(),
      failureReason: json['failure_reason']?.toString(),
      paymentMethodTitle: json['payment_method_title']?.toString(),
      paymentMethodSubtitle: json['payment_method_subtitle']?.toString(),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      confirmedAt: DateTime.tryParse(json['confirmed_at']?.toString() ?? ''),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? ''),
    );
  }

  static PaymentTransactionStatus _parseStatus(String? raw) {
    switch (raw) {
      case 'created':
        return PaymentTransactionStatus.created;
      case 'pending':
        return PaymentTransactionStatus.pending;
      case 'paid':
        return PaymentTransactionStatus.paid;
      case 'failed':
        return PaymentTransactionStatus.failed;
      case 'cancelled':
        return PaymentTransactionStatus.cancelled;
      case 'refunded':
        return PaymentTransactionStatus.refunded;
      case 'pendingCash':
      case 'pending_cash':
        return PaymentTransactionStatus.pendingCash;
      default:
        return PaymentTransactionStatus.created;
    }
  }
}
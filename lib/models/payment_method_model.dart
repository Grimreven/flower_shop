import 'package:flutter/material.dart';

enum PaymentMethodType {
  bankCard,
  card,
  sbp,
  cash,
}

class PaymentMethodModel {
  final String id;
  final int? userId;
  final PaymentMethodType type;
  final String title;
  final String subtitle;
  final String cardLast4;
  final String bankName;
  final String maskedNumber;
  final String? expiryMonth;
  final String? expiryYear;
  final bool isDefault;
  final bool isActive;
  final bool isSystem;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const PaymentMethodModel({
    required this.id,
    this.userId,
    required this.type,
    required this.title,
    this.subtitle = '',
    this.cardLast4 = '',
    this.bankName = '',
    this.maskedNumber = '',
    this.expiryMonth,
    this.expiryYear,
    this.isDefault = false,
    this.isActive = true,
    this.isSystem = false,
    this.createdAt,
    this.updatedAt,
  });

  factory PaymentMethodModel.cash() {
    return PaymentMethodModel(
      id: 'cash',
      type: PaymentMethodType.cash,
      title: 'Наличными',
      subtitle: 'Оплата курьеру при получении',
      isDefault: true,
      isSystem: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  factory PaymentMethodModel.sbp() {
    return PaymentMethodModel(
      id: 'sbp',
      type: PaymentMethodType.sbp,
      title: 'СБП',
      subtitle: 'Оплата через Систему быстрых платежей',
      isSystem: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  factory PaymentMethodModel.card({
    required String id,
    int? userId,
    required String last4,
    String bankName = 'Банковская карта',
    String maskedNumber = '',
    String? expiryMonth,
    String? expiryYear,
    bool isDefault = false,
  }) {
    return PaymentMethodModel(
      id: id,
      userId: userId,
      type: PaymentMethodType.bankCard,
      title: 'Карта •••• $last4',
      subtitle: bankName,
      cardLast4: last4,
      bankName: bankName,
      maskedNumber: maskedNumber.isNotEmpty ? maskedNumber : '•••• •••• •••• $last4',
      expiryMonth: expiryMonth,
      expiryYear: expiryYear,
      isDefault: isDefault,
      isSystem: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  bool get isCard => type == PaymentMethodType.bankCard || type == PaymentMethodType.card;
  bool get isSbp => type == PaymentMethodType.sbp;
  bool get isCash => type == PaymentMethodType.cash;

  IconData get icon {
    if (isCard) return Icons.credit_card;
    if (isSbp) return Icons.bolt;
    return Icons.payments_outlined;
  }

  String get displayBadge {
    if (isDefault) return 'По умолчанию';
    if (isSystem) return 'Системный';
    return '';
  }

  String get apiType {
    if (isCard) return 'card';
    if (isSbp) return 'sbp';
    return 'cash';
  }

  factory PaymentMethodModel.fromJson(Map<String, dynamic> json) {
    return PaymentMethodModel(
      id: json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      userId: _toNullableInt(json['userId'] ?? json['user_id']),
      type: _typeFromString(json['type']?.toString() ?? 'card'),
      title: json['title']?.toString() ?? '',
      subtitle: json['subtitle']?.toString() ?? '',
      cardLast4: json['cardLast4']?.toString() ?? json['card_last4']?.toString() ?? '',
      bankName: json['bankName']?.toString() ?? json['bank_name']?.toString() ?? '',
      maskedNumber: json['maskedNumber']?.toString() ?? json['masked_number']?.toString() ?? '',
      expiryMonth: json['expiryMonth']?.toString() ?? json['expiry_month']?.toString(),
      expiryYear: json['expiryYear']?.toString() ?? json['expiry_year']?.toString(),
      isDefault: _toBool(json['isDefault'] ?? json['is_default']),
      isActive: _toBool(json['isActive'] ?? json['is_active'] ?? true),
      isSystem: _toBool(json['isSystem'] ?? json['is_system']),
      createdAt: _toDate(json['createdAt'] ?? json['created_at']),
      updatedAt: _toDate(json['updatedAt'] ?? json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'type': apiType,
      'title': title,
      'subtitle': subtitle,
      'cardLast4': cardLast4,
      'bankName': bankName,
      'maskedNumber': maskedNumber,
      'expiryMonth': expiryMonth,
      'expiryYear': expiryYear,
      'isDefault': isDefault,
      'isActive': isActive,
      'isSystem': isSystem,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  PaymentMethodModel copyWith({
    String? id,
    int? userId,
    PaymentMethodType? type,
    String? title,
    String? subtitle,
    String? cardLast4,
    String? bankName,
    String? maskedNumber,
    String? expiryMonth,
    String? expiryYear,
    bool? isDefault,
    bool? isActive,
    bool? isSystem,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PaymentMethodModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      cardLast4: cardLast4 ?? this.cardLast4,
      bankName: bankName ?? this.bankName,
      maskedNumber: maskedNumber ?? this.maskedNumber,
      expiryMonth: expiryMonth ?? this.expiryMonth,
      expiryYear: expiryYear ?? this.expiryYear,
      isDefault: isDefault ?? this.isDefault,
      isActive: isActive ?? this.isActive,
      isSystem: isSystem ?? this.isSystem,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static PaymentMethodType _typeFromString(String value) {
    switch (value) {
      case 'bankCard':
      case 'bank_card':
      case 'card':
        return PaymentMethodType.bankCard;
      case 'sbp':
        return PaymentMethodType.sbp;
      case 'cash':
        return PaymentMethodType.cash;
      default:
        return PaymentMethodType.bankCard;
    }
  }

  static int? _toNullableInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  static bool _toBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is int) return value == 1;
    return value.toString().toLowerCase() == 'true';
  }

  static DateTime? _toDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}
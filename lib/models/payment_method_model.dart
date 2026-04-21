import 'package:flutter/material.dart';

enum PaymentMethodType {
  cash,
  sbp,
  bankCard,
}

class PaymentMethodModel {
  final String id;
  final int userId;
  final PaymentMethodType type;
  final String title;
  final String? holderName;
  final String? maskedNumber;
  final String? bankName;
  final String? cardBrand;
  final String? expiryMonth;
  final String? expiryYear;
  final String? token;
  final bool isDefault;
  final bool isActive;
  final bool isSystem;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PaymentMethodModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    this.holderName,
    this.maskedNumber,
    this.bankName,
    this.cardBrand,
    this.expiryMonth,
    this.expiryYear,
    this.token,
    required this.isDefault,
    required this.isActive,
    required this.isSystem,
    required this.createdAt,
    required this.updatedAt,
  });

  PaymentMethodModel copyWith({
    String? id,
    int? userId,
    PaymentMethodType? type,
    String? title,
    String? holderName,
    String? maskedNumber,
    String? bankName,
    String? cardBrand,
    String? expiryMonth,
    String? expiryYear,
    String? token,
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
      holderName: holderName ?? this.holderName,
      maskedNumber: maskedNumber ?? this.maskedNumber,
      bankName: bankName ?? this.bankName,
      cardBrand: cardBrand ?? this.cardBrand,
      expiryMonth: expiryMonth ?? this.expiryMonth,
      expiryYear: expiryYear ?? this.expiryYear,
      token: token ?? this.token,
      isDefault: isDefault ?? this.isDefault,
      isActive: isActive ?? this.isActive,
      isSystem: isSystem ?? this.isSystem,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isCard => type == PaymentMethodType.bankCard;
  bool get isCash => type == PaymentMethodType.cash;
  bool get isSbp => type == PaymentMethodType.sbp;

  String get subtitle {
    if (isCash) {
      return 'Оплата при получении';
    }

    if (isSbp) {
      return 'Быстрый перевод через СБП';
    }

    final List<String> parts = <String>[];

    if ((cardBrand ?? '').trim().isNotEmpty) {
      parts.add(cardBrand!.trim());
    }

    if ((maskedNumber ?? '').trim().isNotEmpty) {
      parts.add(maskedNumber!.trim());
    }

    if ((expiryMonth ?? '').trim().isNotEmpty &&
        (expiryYear ?? '').trim().isNotEmpty) {
      parts.add('$expiryMonth/$expiryYear');
    }

    return parts.join(' • ');
  }

  IconData get icon {
    switch (type) {
      case PaymentMethodType.cash:
        return Icons.payments_rounded;
      case PaymentMethodType.sbp:
        return Icons.qr_code_rounded;
      case PaymentMethodType.bankCard:
        return Icons.credit_card_rounded;
    }
  }

  String get displayBadge {
    if (isCash) return 'Наличные';
    if (isSbp) return 'СБП';
    return cardBrand ?? 'Карта';
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'user_id': userId,
      'type': type.name,
      'title': title,
      'holder_name': holderName,
      'masked_number': maskedNumber,
      'bank_name': bankName,
      'card_brand': cardBrand,
      'expiry_month': expiryMonth,
      'expiry_year': expiryYear,
      'token': token,
      'is_default': isDefault,
      'is_active': isActive,
      'is_system': isSystem,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory PaymentMethodModel.fromJson(Map<String, dynamic> json) {
    return PaymentMethodModel(
      id: json['id']?.toString() ?? '',
      userId: (json['user_id'] as num?)?.toInt() ?? 0,
      type: _parseType(json['type']?.toString()),
      title: json['title']?.toString() ?? '',
      holderName: json['holder_name']?.toString(),
      maskedNumber: json['masked_number']?.toString(),
      bankName: json['bank_name']?.toString(),
      cardBrand: json['card_brand']?.toString(),
      expiryMonth: json['expiry_month']?.toString(),
      expiryYear: json['expiry_year']?.toString(),
      token: json['token']?.toString(),
      isDefault: json['is_default'] == true,
      isActive: json['is_active'] != false,
      isSystem: json['is_system'] == true,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  static PaymentMethodType _parseType(String? raw) {
    switch (raw) {
      case 'cash':
        return PaymentMethodType.cash;
      case 'sbp':
        return PaymentMethodType.sbp;
      case 'bankCard':
      case 'bank_card':
        return PaymentMethodType.bankCard;
      default:
        return PaymentMethodType.cash;
    }
  }
}
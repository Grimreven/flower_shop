import 'order_item.dart';

class OrderModel {
  final int id;
  final double total;
  final double itemsTotal;
  final double deliveryCost;
  final int bonusApplied;
  final int bonusEarned;
  final String paymentMethod;
  final String paymentStatus;
  final String cardMask;
  final String deliveryAddress;
  final String status;
  final List<OrderItem> items;
  final String createdAt;
  final OrderDeliveryDetails? delivery;
  final OrderPaymentDetails? payment;

  OrderModel({
    required this.id,
    required this.total,
    required this.itemsTotal,
    required this.deliveryCost,
    required this.bonusApplied,
    required this.bonusEarned,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.cardMask,
    required this.deliveryAddress,
    required this.status,
    required this.items,
    required this.createdAt,
    this.delivery,
    this.payment,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final List<dynamic> itemsJson = (json['items'] as List<dynamic>?) ?? [];

    final List<OrderItem> itemsList = itemsJson.map((dynamic e) {
      if (e is Map<String, dynamic>) {
        return OrderItem.fromJson(e);
      }

      return OrderItem.fromJson(Map<String, dynamic>.from(e as Map));
    }).toList();

    final OrderDeliveryDetails? delivery = json['delivery'] == null
        ? null
        : OrderDeliveryDetails.fromJson(
      Map<String, dynamic>.from(json['delivery'] as Map),
    );

    final OrderPaymentDetails? payment = json['payment'] == null
        ? null
        : OrderPaymentDetails.fromJson(
      Map<String, dynamic>.from(json['payment'] as Map),
    );

    final double deliveryCost = _toDouble(
      json['delivery_cost'] ?? delivery?.deliveryPrice,
    );

    final String deliveryAddress = (json['delivery_address'] ??
        delivery?.fullAddress ??
        json['full_address'] ??
        '')
        .toString();

    final String paymentMethod =
    (json['payment_method'] ?? payment?.paymentMethod ?? '').toString();

    final String paymentStatus =
    (json['payment_status'] ?? payment?.paymentStatus ?? '').toString();

    return OrderModel(
      id: _toInt(json['id']),
      total: _toDouble(json['total']),
      itemsTotal: _toDouble(json['items_total'] ?? json['subtotal']),
      deliveryCost: deliveryCost,
      bonusApplied: _toInt(json['bonus_applied']),
      bonusEarned: _toInt(json['bonus_earned']),
      paymentMethod: paymentMethod,
      paymentStatus: paymentStatus,
      cardMask: json['card_mask']?.toString() ?? '',
      deliveryAddress: deliveryAddress,
      status: json['status']?.toString() ?? '',
      items: itemsList,
      createdAt: json['created_at']?.toString() ?? '',
      delivery: delivery,
      payment: payment,
    );
  }

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();

    return int.tryParse(value.toString()) ?? 0;
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();

    return double.tryParse(value.toString().replaceAll(',', '.')) ?? 0.0;
  }
}

class OrderDeliveryDetails {
  final int id;
  final int orderId;
  final int addressId;
  final String recipientName;
  final String phone;
  final String fullAddress;
  final String deliveryMethod;
  final String deliveryDate;
  final String deliveryTimeFrom;
  final String deliveryTimeTo;
  final String comment;
  final double deliveryPrice;

  OrderDeliveryDetails({
    required this.id,
    required this.orderId,
    required this.addressId,
    required this.recipientName,
    required this.phone,
    required this.fullAddress,
    required this.deliveryMethod,
    required this.deliveryDate,
    required this.deliveryTimeFrom,
    required this.deliveryTimeTo,
    required this.comment,
    required this.deliveryPrice,
  });

  factory OrderDeliveryDetails.fromJson(Map<String, dynamic> json) {
    return OrderDeliveryDetails(
      id: OrderModel._toInt(json['id']),
      orderId: OrderModel._toInt(json['order_id']),
      addressId: OrderModel._toInt(json['address_id']),
      recipientName: json['recipient_name']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      fullAddress: json['full_address']?.toString() ?? '',
      deliveryMethod: json['delivery_method']?.toString() ?? '',
      deliveryDate: json['delivery_date']?.toString() ?? '',
      deliveryTimeFrom: json['delivery_time_from']?.toString() ?? '',
      deliveryTimeTo: json['delivery_time_to']?.toString() ?? '',
      comment: json['comment']?.toString() ?? '',
      deliveryPrice: OrderModel._toDouble(json['delivery_price']),
    );
  }
}

class OrderPaymentDetails {
  final int id;
  final int orderId;
  final String paymentMethod;
  final String paymentStatus;
  final double paymentAmount;
  final String createdAt;

  OrderPaymentDetails({
    required this.id,
    required this.orderId,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.paymentAmount,
    required this.createdAt,
  });

  factory OrderPaymentDetails.fromJson(Map<String, dynamic> json) {
    return OrderPaymentDetails(
      id: OrderModel._toInt(json['id']),
      orderId: OrderModel._toInt(json['order_id']),
      paymentMethod: json['payment_method']?.toString() ?? '',
      paymentStatus: json['payment_status']?.toString() ?? '',
      paymentAmount: OrderModel._toDouble(json['payment_amount']),
      createdAt: json['created_at']?.toString() ?? '',
    );
  }
}
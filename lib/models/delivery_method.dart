enum DeliveryMethod {
  delivery,
  pickup,
}

extension DeliveryMethodX on DeliveryMethod {
  String get code {
    switch (this) {
      case DeliveryMethod.delivery:
        return 'delivery';
      case DeliveryMethod.pickup:
        return 'pickup';
    }
  }

  String get title {
    switch (this) {
      case DeliveryMethod.delivery:
        return 'Доставка';
      case DeliveryMethod.pickup:
        return 'Самовывоз';
    }
  }

  static DeliveryMethod fromCode(String? code) {
    switch (code) {
      case 'pickup':
        return DeliveryMethod.pickup;
      case 'delivery':
      default:
        return DeliveryMethod.delivery;
    }
  }
}
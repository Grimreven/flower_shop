class UserAddress {
  final int id;
  final String title;
  final String address;
  final String city;
  final String street;
  final String house;
  final String entrance;
  final String floor;
  final String apartment;
  final String comment;
  final String recipientName;
  final String phone;
  final bool isPrimary;

  const UserAddress({
    required this.id,
    required this.title,
    this.address = '',
    this.city = '',
    this.street = '',
    this.house = '',
    this.entrance = '',
    this.floor = '',
    this.apartment = '',
    this.comment = '',
    this.recipientName = '',
    this.phone = '',
    this.isPrimary = false,
  });

  factory UserAddress.fromJson(Map<String, dynamic> json) {
    final String city = json['city']?.toString() ?? '';
    final String street = json['street']?.toString() ?? '';
    final String house = json['house']?.toString() ?? '';
    final String rawAddress = json['address']?.toString() ?? '';

    return UserAddress(
      id: _toInt(json['id']),
      title: json['title']?.toString() ?? 'Адрес',
      address: rawAddress,
      city: city,
      street: street,
      house: house,
      entrance: json['entrance']?.toString() ?? '',
      floor: json['floor']?.toString() ?? '',
      apartment: json['apartment']?.toString() ?? '',
      comment: json['comment']?.toString() ?? '',
      recipientName:
      (json['recipient_name'] ?? json['recipientName'])?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      isPrimary: _toBool(json['is_default'] ?? json['is_primary']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'address': address,
      'city': city,
      'street': street,
      'house': house,
      'entrance': entrance,
      'floor': floor,
      'apartment': apartment,
      'comment': comment,
      'recipient_name': recipientName,
      'phone': phone,
      'is_primary': isPrimary,
      'is_default': isPrimary,
    };
  }

  Map<String, dynamic> toApiJson() {
    final ParsedAddress parsed = ParsedAddress.fromAddress(this);

    return {
      'title': title,
      'recipient_name': recipientName,
      'phone': phone,
      'city': parsed.city,
      'street': parsed.street,
      'house': parsed.house,
      'apartment': apartment,
      'entrance': entrance,
      'floor': floor,
      'comment': comment,
      'is_default': isPrimary,
    };
  }

  UserAddress copyWith({
    int? id,
    String? title,
    String? address,
    String? city,
    String? street,
    String? house,
    String? entrance,
    String? floor,
    String? apartment,
    String? comment,
    String? recipientName,
    String? phone,
    bool? isPrimary,
  }) {
    return UserAddress(
      id: id ?? this.id,
      title: title ?? this.title,
      address: address ?? this.address,
      city: city ?? this.city,
      street: street ?? this.street,
      house: house ?? this.house,
      entrance: entrance ?? this.entrance,
      floor: floor ?? this.floor,
      apartment: apartment ?? this.apartment,
      comment: comment ?? this.comment,
      recipientName: recipientName ?? this.recipientName,
      phone: phone ?? this.phone,
      isPrimary: isPrimary ?? this.isPrimary,
    );
  }

  String get fullAddress {
    final ParsedAddress parsed = ParsedAddress.fromAddress(this);

    final List<String> parts = [
      parsed.city,
      parsed.street.isNotEmpty ? 'ул. ${parsed.street}' : '',
      parsed.house.isNotEmpty ? 'д. ${parsed.house}' : '',
      apartment.trim().isNotEmpty ? 'кв. $apartment' : '',
      entrance.trim().isNotEmpty ? 'подъезд $entrance' : '',
      floor.trim().isNotEmpty ? 'этаж $floor' : '',
    ].where((String item) => item.trim().isNotEmpty).toList();

    return parts.join(', ');
  }

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();

    return int.tryParse(value.toString()) ?? 0;
  }

  static bool _toBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is int) return value == 1;

    return value.toString().toLowerCase() == 'true';
  }
}

class ParsedAddress {
  final String city;
  final String street;
  final String house;

  const ParsedAddress({
    required this.city,
    required this.street,
    required this.house,
  });

  factory ParsedAddress.fromAddress(UserAddress address) {
    if (address.city.trim().isNotEmpty ||
        address.street.trim().isNotEmpty ||
        address.house.trim().isNotEmpty) {
      return ParsedAddress(
        city: address.city.trim().isNotEmpty ? address.city.trim() : 'Москва',
        street: address.street.trim().isNotEmpty
            ? address.street.trim()
            : address.address.trim(),
        house: address.house.trim().isNotEmpty ? address.house.trim() : '1',
      );
    }

    final String raw = address.address.trim();

    if (raw.isEmpty) {
      return const ParsedAddress(
        city: 'Москва',
        street: 'Не указана',
        house: '1',
      );
    }

    final List<String> parts = raw
        .split(',')
        .map((String e) => e.trim())
        .where((String e) => e.isNotEmpty)
        .toList();

    if (parts.length >= 3) {
      return ParsedAddress(
        city: parts[0],
        street: _clearStreet(parts[1]),
        house: _clearHouse(parts[2]),
      );
    }

    if (parts.length == 2) {
      return ParsedAddress(
        city: 'Москва',
        street: _clearStreet(parts[0]),
        house: _clearHouse(parts[1]),
      );
    }

    return ParsedAddress(
      city: 'Москва',
      street: _clearStreet(raw),
      house: '1',
    );
  }

  static String _clearStreet(String value) {
    return value
        .replaceAll('ул.', '')
        .replaceAll('улица', '')
        .replaceAll('Улица', '')
        .trim();
  }

  static String _clearHouse(String value) {
    return value
        .replaceAll('д.', '')
        .replaceAll('дом', '')
        .replaceAll('Дом', '')
        .trim();
  }
}
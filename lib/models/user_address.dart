class UserAddress {
  final int id;
  final String title;
  final String address;
  final String entrance;
  final String floor;
  final String apartment;
  final String comment;
  final bool isPrimary;

  const UserAddress({
    required this.id,
    required this.title,
    required this.address,
    this.entrance = '',
    this.floor = '',
    this.apartment = '',
    this.comment = '',
    this.isPrimary = false,
  });

  factory UserAddress.fromJson(Map<String, dynamic> json) {
    return UserAddress(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: json['title']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      entrance: json['entrance']?.toString() ?? '',
      floor: json['floor']?.toString() ?? '',
      apartment: json['apartment']?.toString() ?? '',
      comment: json['comment']?.toString() ?? '',
      isPrimary: json['is_primary'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'address': address,
      'entrance': entrance,
      'floor': floor,
      'apartment': apartment,
      'comment': comment,
      'is_primary': isPrimary,
    };
  }

  UserAddress copyWith({
    int? id,
    String? title,
    String? address,
    String? entrance,
    String? floor,
    String? apartment,
    String? comment,
    bool? isPrimary,
  }) {
    return UserAddress(
      id: id ?? this.id,
      title: title ?? this.title,
      address: address ?? this.address,
      entrance: entrance ?? this.entrance,
      floor: floor ?? this.floor,
      apartment: apartment ?? this.apartment,
      comment: comment ?? this.comment,
      isPrimary: isPrimary ?? this.isPrimary,
    );
  }

  String get fullAddress {
    final List<String> parts = [
      address,
      if (apartment.trim().isNotEmpty) 'кв. $apartment',
      if (entrance.trim().isNotEmpty) 'подъезд $entrance',
      if (floor.trim().isNotEmpty) 'этаж $floor',
    ];

    return parts.join(', ');
  }
}
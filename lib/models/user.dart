class User {
  final int id;
  final String name;
  final String email;
  final String phone;
  final String address;
  final int loyaltyPoints;
  final double totalSpent;
  final String loyaltyLevel;
  final String loyaltyColor;
  final String? role;

  const User({
    required this.id,
    required this.name,
    required this.email,
    this.phone = '',
    this.address = '',
    this.loyaltyPoints = 0,
    this.totalSpent = 0,
    this.loyaltyLevel = 'Bronze',
    this.loyaltyColor = '#CD7F32',
    this.role,

  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: _toInt(json['id']),
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      role: json['role'],
      loyaltyPoints: _toInt(json['loyalty_points'] ?? json['loyaltyPoints']),
      totalSpent: _toDouble(json['total_spent'] ?? json['totalSpent']),
      loyaltyLevel: json['loyalty_level']?.toString() ??
          json['loyaltyLevel']?.toString() ??
          'Bronze',
      loyaltyColor: json['loyalty_color']?.toString() ??
          json['loyaltyColor']?.toString() ??
          '#CD7F32',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'role': role,
      'loyalty_points': loyaltyPoints,
      'total_spent': totalSpent,
      'loyalty_level': loyaltyLevel,
      'loyalty_color': loyaltyColor,
    };
  }

  User copyWith({
    int? id,
    String? name,
    String? email,
    String? phone,
    String? address,
    String? role,
    int? loyaltyPoints,
    double? totalSpent,
    String? loyaltyLevel,
    String? loyaltyColor,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      role: role ?? this.role,
      loyaltyPoints: loyaltyPoints ?? this.loyaltyPoints,
      totalSpent: totalSpent ?? this.totalSpent,
      loyaltyLevel: loyaltyLevel ?? this.loyaltyLevel,
      loyaltyColor: loyaltyColor ?? this.loyaltyColor,
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
    if (value is num) return value.toDouble();

    return double.tryParse(value.toString().replaceAll(',', '.')) ?? 0.0;
  }
}
class User {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final String? address;

  // Данные лояльности
  int loyaltyPoints;
  final String loyaltyLevel;
  final double totalSpent;
  final String loyaltyColor; // hex цвет карты

  User({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.address,
    required this.loyaltyPoints,
    required this.loyaltyLevel,
    required this.totalSpent,
    required this.loyaltyColor,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      address: json['address'],
      loyaltyPoints: json['loyalty_points'] ?? 0,
      loyaltyLevel: json['loyalty_level'] ?? 'Bronze',
      totalSpent: double.tryParse(json['total_spent'].toString()) ?? 0.0,
      loyaltyColor: json['loyalty_color'] ?? '#CD7F32', // бронзовый цвет по умолчанию
    );
  }

  User copyWith({
    String? name,
    String? email,
    String? phone,
    String? address,
    int? loyaltyPoints,
    String? loyaltyLevel,
    double? totalSpent,
    String? loyaltyColor,
  }) {
    return User(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      loyaltyPoints: loyaltyPoints ?? this.loyaltyPoints,
      loyaltyLevel: loyaltyLevel ?? this.loyaltyLevel,
      totalSpent: totalSpent ?? this.totalSpent,
      loyaltyColor: loyaltyColor ?? this.loyaltyColor,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'loyalty_points': loyaltyPoints,
      'loyalty_level': loyaltyLevel,
      'total_spent': totalSpent,
      'loyalty_color': loyaltyColor,
    };
  }
}

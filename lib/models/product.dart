class Product {
  final int id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final int categoryId;
  final String categoryName;
  final bool inStock;
  final double rating;
  final int reviewCount;
  final List<String>? care;
  final List<dynamic>? priceHistory;
  final bool isFavorite;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.categoryId,
    required this.categoryName,
    required this.inStock,
    required this.rating,
    this.reviewCount = 0,
    this.care,
    this.priceHistory,
    this.isFavorite = false,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: _toInt(json['id']),
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      price: _toDouble(json['price']),
      imageUrl: (json['imageUrl'] ?? json['image_url'] ?? '').toString(),
      categoryId: _toInt(json['categoryId'] ?? json['category_id']),
      categoryName:
      (json['categoryName'] ?? json['category_name'] ?? '').toString(),
      inStock: _toBool(json['inStock'] ?? json['in_stock']),
      rating: _toDouble(json['rating']),
      reviewCount: _toInt(json['reviewCount'] ?? json['review_count']),
      care: _toStringList(json['care']),
      priceHistory: json['priceHistory'] ?? json['price_history'],
      isFavorite: _toBool(json['isFavorite'] ?? json['is_favorite']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'image_url': imageUrl,
      'category_id': categoryId,
      'category_name': categoryName,
      'in_stock': inStock,
      'rating': rating,
      'review_count': reviewCount,
      'care': care,
      'price_history': priceHistory,
      'is_favorite': isFavorite,
    };
  }

  Product copyWith({
    int? id,
    String? name,
    String? description,
    double? price,
    String? imageUrl,
    int? categoryId,
    String? categoryName,
    bool? inStock,
    double? rating,
    int? reviewCount,
    List<String>? care,
    List<dynamic>? priceHistory,
    bool? isFavorite,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      inStock: inStock ?? this.inStock,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      care: care ?? this.care,
      priceHistory: priceHistory ?? this.priceHistory,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString().replaceAll(',', '.')) ?? 0.0;
  }

  static bool _toBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is int) return value == 1;
    return value.toString().toLowerCase() == 'true';
  }

  static List<String>? _toStringList(dynamic value) {
    if (value == null) return null;
    if (value is List) {
      return value.map((item) => item.toString()).toList();
    }
    return null;
  }
}

class PriceHistory {
  final double price;
  final DateTime changedAt;

  PriceHistory({
    required this.price,
    required this.changedAt,
  });
}
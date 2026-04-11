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
  final List<String>? care;
  final List<PriceHistory>? priceHistory;
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
    this.care,
    this.priceHistory,
    this.isFavorite = false,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    List<String>? careList;

    if (json['care'] != null) {
      careList = List<String>.from(json['care']);
    }

    return Product(
      id: json['id'],
      name: json['name'],
      description: json['description'] ?? '',
      price: double.tryParse(json['price'].toString()) ?? 0.0,
      imageUrl: json['image_url'],
      categoryId: json['category_id'],
      categoryName: json['category_name'] ?? '',
      inStock: json['in_stock'] ?? true,
      rating: double.tryParse(json['rating'].toString()) ?? 0.0,
      care: careList,
      isFavorite: json['is_favorite'] ?? false,
    );
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
    List<String>? care,
    List<PriceHistory>? priceHistory,
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
      care: care ?? this.care,
      priceHistory: priceHistory ?? this.priceHistory,
      isFavorite: isFavorite ?? this.isFavorite,
    );
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
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
    );
  }
}

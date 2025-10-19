import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/product.dart';
import '../../widgets/product_card.dart';
import '../../widgets/product_detail.dart';
import '../../utils/app_colors.dart';
import '../../api/api_service.dart';
import '../auth/auth_screen.dart';
import '../../controllers/cart_controller.dart';

class SearchFilters {
  List<String> categories;
  RangeValues priceRange;
  bool inStockOnly;

  SearchFilters({
    required this.categories,
    required this.priceRange,
    required this.inStockOnly,
  });
}

class SearchScreen extends StatefulWidget {
  final List<String> categories;

  const SearchScreen({Key? key, required this.categories}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  bool showFilters = false;
  String searchQuery = '';
  SearchFilters filters = SearchFilters(
    categories: [],
    priceRange: const RangeValues(0, 10000),
    inStockOnly: false,
  );

  List<Product> allProducts = [];
  List<Product> filteredProducts = [];
  bool isLoading = true;

  final CartController cartController = Get.find<CartController>();

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    try {
      final products = await ApiService.fetchAllProducts();
      setState(() {
        allProducts = products;
        filteredProducts = products;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      print('Ошибка загрузки товаров: $e');
    }
  }

  Future<bool> _checkAuth() async {
    final loggedIn = await ApiService.isLoggedIn();
    if (!loggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Пожалуйста, войдите, чтобы добавить товар в корзину'),
        ),
      );
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const AuthScreen()),
      );
      return false;
    }
    return true;
  }

  void _applySearchAndFilters() {
    List<Product> temp = allProducts;

    if (searchQuery.isNotEmpty) {
      temp = temp
          .where((p) =>
      p.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
          p.description.toLowerCase().contains(searchQuery.toLowerCase()))
          .toList();
    }

    if (filters.categories.isNotEmpty) {
      temp = temp.where((p) => filters.categories.contains(p.categoryName)).toList();
    }

    temp = temp
        .where((p) => p.price >= filters.priceRange.start && p.price <= filters.priceRange.end)
        .toList();

    if (filters.inStockOnly) {
      temp = temp.where((p) => p.inStock).toList();
    }

    setState(() {
      filteredProducts = temp;
    });
  }

  void handleSearch(String query) {
    setState(() => searchQuery = query);
    _applySearchAndFilters();
  }

  void toggleCategory(String category) {
    final newCategories = filters.categories.contains(category)
        ? filters.categories.where((c) => c != category).toList()
        : [...filters.categories, category];
    setState(() {
      filters.categories = newCategories;
    });
    _applySearchAndFilters();
  }

  void clearFilters() {
    setState(() {
      filters = SearchFilters(
        categories: [],
        priceRange: const RangeValues(0, 10000),
        inStockOnly: false,
      );
    });
    _applySearchAndFilters();
  }

  int get activeFiltersCount {
    int count = filters.categories.length;
    if (filters.inStockOnly) count++;
    if (filters.priceRange.start > 0 || filters.priceRange.end < 10000) count++;
    return count;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: TextField(
          onChanged: handleSearch,
          decoration: InputDecoration(
            hintText: 'Поиск цветов...',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.grey[200],
            contentPadding: const EdgeInsets.symmetric(vertical: 0),
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (activeFiltersCount > 0)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ...filters.categories.map((c) => FilterChip(
                    label: Text(c),
                    selected: true,
                    onSelected: (_) => toggleCategory(c),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () => toggleCategory(c),
                  )),
                  if (filters.inStockOnly)
                    FilterChip(
                      label: const Text('В наличии'),
                      selected: true,
                      onSelected: (_) {},
                      onDeleted: () => setState(() {
                        filters.inStockOnly = false;
                        _applySearchAndFilters();
                      }),
                      deleteIcon: const Icon(Icons.close, size: 16),
                    ),
                  TextButton(
                    onPressed: clearFilters,
                    child: const Text('Очистить все'),
                  ),
                ],
              ),
            const SizedBox(height: 16),
            filteredProducts.isEmpty
                ? const Center(child: Text('Товары не найдены'))
                : GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.72,
              ),
              itemCount: filteredProducts.length,
              itemBuilder: (context, index) {
                final product = filteredProducts[index];
                return ProductCard(
                  product: product,
                  onAddToCart: () {
                    cartController.addToCart(product);
                    Get.snackbar('Добавлено', '${product.name} в корзину',
                        snackPosition: SnackPosition.BOTTOM);
                  },
                  onViewDetails: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProductDetail(product: product),
                      ),
                    );
                  },
                );
              },
            ),

          ],
        ),
      ),
    );
  }
}

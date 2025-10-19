import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/product.dart';
import '../../api/api_service.dart';
import '../../controllers/cart_controller.dart';
import '../../widgets/product_card.dart';
import '../../widgets/product_detail.dart';
import '../../utils/app_colors.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final CartController cartController = Get.find<CartController>();

  List<Product> allProducts = [];
  List<Product> popularProducts = [];
  List<Product> newProducts = [];
  List<Product> filteredProducts = [];

  String searchQuery = '';
  List<String> selectedCategories = [];
  RangeValues priceRange = const RangeValues(0, 10000);
  bool inStockOnly = false;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => isLoading = true);
    try {
      final all = await ApiService.fetchAllProducts();
      final popular = await ApiService.fetchPopularProducts();
      final newItems = all.length >= 4
          ? all.sublist(all.length - 4).reversed.toList()
          : all.reversed.toList();

      setState(() {
        allProducts = all;
        popularProducts = popular;
        newProducts = newItems;
        filteredProducts = all;
        isLoading = false;
      });
    } catch (e) {
      print('Ошибка загрузки товаров: $e');
      setState(() => isLoading = false);
    }
  }

  void _applyFilters() {
    List<Product> temp = allProducts;

    // Поиск
    if (searchQuery.isNotEmpty) {
      temp = temp
          .where((p) =>
      p.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
          (p.description != null &&
              p.description!
                  .toLowerCase()
                  .contains(searchQuery.toLowerCase())))
          .toList();
    }

    // Категории
    if (selectedCategories.isNotEmpty) {
      temp = temp
          .where((p) => selectedCategories.contains(p.categoryName))
          .toList();
    }

    // Цена
    temp = temp
        .where((p) => p.price >= priceRange.start && p.price <= priceRange.end)
        .toList();

    // Только в наличии
    if (inStockOnly) {
      temp = temp.where((p) => p.inStock).toList();
    }

    setState(() {
      filteredProducts = temp;
    });
  }

  void _toggleCategory(String category) {
    setState(() {
      if (selectedCategories.contains(category)) {
        selectedCategories.remove(category);
      } else {
        selectedCategories.add(category);
      }
    });
    _applyFilters();
  }

  void _clearFilters() {
    setState(() {
      selectedCategories.clear();
      priceRange = const RangeValues(0, 10000);
      inStockOnly = false;
    });
    _applyFilters();
  }

  void _openProductDetail(Product product) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProductDetail(product: product)),
    );
  }

  Widget _buildFilters() {
    final categories = allProducts.map((p) => p.categoryName).toSet().toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...categories.map(
                  (c) => FilterChip(
                label: Text(c),
                selected: selectedCategories.contains(c),
                onSelected: (_) => _toggleCategory(c),
              ),
            ),
            FilterChip(
              label: const Text('В наличии'),
              selected: inStockOnly,
              onSelected: (_) {
                setState(() {
                  inStockOnly = !inStockOnly;
                  _applyFilters();
                });
              },
            ),
            TextButton(
              onPressed: _clearFilters,
              child: const Text('Очистить фильтры'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Text('Цена:'),
            Expanded(
              child: RangeSlider(
                min: 0,
                max: 10000,
                divisions: 100,
                labels: RangeLabels(
                  priceRange.start.toStringAsFixed(0),
                  priceRange.end.toStringAsFixed(0),
                ),
                values: priceRange,
                onChanged: (range) {
                  setState(() => priceRange = range);
                  _applyFilters();
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSection(String title, List<Product> products) {
    final displayProducts = filteredProducts.isEmpty && searchQuery.isNotEmpty
        ? []
        : products.where((p) => filteredProducts.contains(p)).toList();

    if (displayProducts.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding:
          const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
          child: Text(
            title,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ),
        GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.68,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: displayProducts.length,
          itemBuilder: (context, index) {
            final product = displayProducts[index];
            return ProductCard(
              product: product,
              onViewDetails: () => _openProductDetail(product),
              onAddToCart: () {
                cartController.addToCart(product);
                Get.snackbar(
                  'Добавлено',
                  '${product.name} в корзину',
                  snackPosition: SnackPosition.BOTTOM,
                );
              },
            );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: TextField(
          onChanged: (value) {
            setState(() => searchQuery = value);
            _applyFilters();
          },
          decoration: InputDecoration(
            hintText: 'Поиск цветов...',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
        backgroundColor: AppColors.primary,
        toolbarHeight: 70,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: _buildFilters(),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSection('Популярное', popularProducts),
                  _buildSection('Новинки', newProducts),
                  _buildSection('Все товары', allProducts),
                  if (filteredProducts.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(
                          child: Text('Товары не найдены')),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

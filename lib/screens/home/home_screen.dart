import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../api/api_service.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/cart_controller.dart';
import '../../models/product.dart';
import '../../utils/app_colors.dart';
import '../../widgets/product_card.dart';
import '../../widgets/product_detail.dart';
import '../../widgets/smart_bouquet_entry_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final CartController cartController = Get.find<CartController>();
  final AuthController authController = Get.find<AuthController>();

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
      final List<Product> all = await ApiService.fetchAllProducts();
      final List<Product> popular = await ApiService.fetchPopularProducts();
      final List<Product> newItems = all.length >= 4
          ? all.sublist(all.length - 4).reversed.toList()
          : all.reversed.toList();

      setState(() {
        allProducts = all;
        popularProducts = popular;
        newProducts = newItems;
        filteredProducts = all;
        isLoading = false;
      });
    } catch (_) {
      setState(() => isLoading = false);
    }
  }

  void _applyFilters() {
    List<Product> temp = allProducts;

    if (searchQuery.isNotEmpty) {
      temp = temp
          .where(
            (Product p) =>
        p.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
            p.description.toLowerCase().contains(searchQuery.toLowerCase()),
      )
          .toList();
    }

    if (selectedCategories.isNotEmpty) {
      temp = temp
          .where((Product p) => selectedCategories.contains(p.categoryName))
          .toList();
    }

    temp = temp
        .where(
          (Product p) =>
      p.price >= priceRange.start && p.price <= priceRange.end,
    )
        .toList();

    if (inStockOnly) {
      temp = temp.where((Product p) => p.inStock).toList();
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
      searchQuery = '';
      filteredProducts = allProducts;
    });
  }

  void _openProductDetail(Product product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductDetail(
          product: product,
          cartController: cartController,
          authController: authController,
        ),
      ),
    );
  }

  void _handleSmartBouquetResult(dynamic selectedProduct) {
    if (selectedProduct is Product) {
      _openProductDetail(selectedProduct);
      return;
    }

    try {
      _openProductDetail(selectedProduct as Product);
    } catch (_) {
      Get.snackbar(
        'Умный букет',
        'Букет подобран, но не удалось открыть карточку товара',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFEEF2), Color(0xFFFFF8FA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Подберите идеальный букет',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.foreground,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Свежие цветы, стильные композиции и быстрая доставка',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.local_florist_rounded,
              color: AppColors.primary,
              size: 32,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmartBouquetBlock() {
    if (allProducts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: SmartBouquetEntryCard(
        products: allProducts,
        onProductSelected: _handleSmartBouquetResult,
      ),
    );
  }

  Widget _buildFilters() {
    final List<String> categories =
    allProducts.map((Product p) => p.categoryName).toSet().toList();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Фильтры',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.foreground,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...categories.map(
                    (String c) => FilterChip(
                  label: Text(c),
                  selected: selectedCategories.contains(c),
                  selectedColor: AppColors.primaryLight,
                  side: const BorderSide(color: AppColors.border),
                  checkmarkColor: AppColors.primary,
                  onSelected: (_) => _toggleCategory(c),
                ),
              ),
              FilterChip(
                label: const Text('В наличии'),
                selected: inStockOnly,
                selectedColor: AppColors.primaryLight,
                side: const BorderSide(color: AppColors.border),
                onSelected: (_) {
                  setState(() {
                    inStockOnly = !inStockOnly;
                    _applyFilters();
                  });
                },
              ),
              TextButton(
                onPressed: _clearFilters,
                child: const Text('Очистить'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Цена',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.foreground,
            ),
          ),
          RangeSlider(
            min: 0,
            max: 10000,
            divisions: 100,
            values: priceRange,
            activeColor: AppColors.primary,
            inactiveColor: AppColors.primaryLight,
            labels: RangeLabels(
              '${priceRange.start.toStringAsFixed(0)} ₽',
              '${priceRange.end.toStringAsFixed(0)} ₽',
            ),
            onChanged: (RangeValues range) {
              setState(() => priceRange = range);
              _applyFilters();
            },
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.foreground,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Product> products) {
    final List<Product> displayProducts =
    filteredProducts.isEmpty && searchQuery.isNotEmpty
        ? []
        : products.where((Product p) => filteredProducts.contains(p)).toList();

    if (displayProducts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(title),
        GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.66,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: displayProducts.length,
          itemBuilder: (BuildContext context, int index) {
            final Product product = displayProducts[index];

            return ProductCard(
              product: product,
              cartController: cartController,
              authController: authController,
              onViewDetails: () => _openProductDetail(product),
              onAddToCart: () async {
                if (!authController.isLoggedIn) {
                  Get.snackbar(
                    'Ошибка',
                    'Сначала войдите в профиль',
                    snackPosition: SnackPosition.BOTTOM,
                  );
                  return;
                }

                await cartController.addToCart(product);

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

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: TextField(
        onChanged: (String value) {
          setState(() => searchQuery = value);
          _applyFilters();
        },
        decoration: InputDecoration(
          hintText: 'Поиск цветов...',
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: searchQuery.isNotEmpty
              ? IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () {
              setState(() => searchQuery = '');
              _applyFilters();
            },
          )
              : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: isLoading
            ? const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        )
            : RefreshIndicator(
          onRefresh: _loadProducts,
          color: AppColors.primary,
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                _buildSmartBouquetBlock(),
                _buildSearchBar(),
                _buildFilters(),
                _buildSection('Популярное', popularProducts),
                _buildSection('Новинки', newProducts),
                _buildSection('Все товары', allProducts),
                if (filteredProducts.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                        'Товары не найдены',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.mutedForeground,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
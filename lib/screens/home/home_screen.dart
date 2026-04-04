import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/product.dart';
import '../../api/api_service.dart';
import '../../controllers/cart_controller.dart';
import '../../widgets/product_card.dart';
import '../../widgets/product_detail.dart';
import '../../utils/app_colors.dart';
import 'package:flower_shop/controllers/auth_controller.dart';

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
    } catch (_) {
      setState(() => isLoading = false);
    }
  }

  void _applyFilters() {
    List<Product> temp = allProducts;

    if (searchQuery.isNotEmpty) {
      temp = temp
          .where((p) =>
      p.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
          p.description.toLowerCase().contains(searchQuery.toLowerCase()))
          .toList();
    }

    if (selectedCategories.isNotEmpty) {
      temp =
          temp.where((p) => selectedCategories.contains(p.categoryName)).toList();
    }

    temp = temp
        .where((p) => p.price >= priceRange.start && p.price <= priceRange.end)
        .toList();

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
          authController: Get.find(),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final borderColor =
    isDark ? AppColors.darkBorder : AppColors.border;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: isDark
            ? const LinearGradient(
          colors: [Color(0xFF1D1D2D), Color(0xFF28283E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        )
            : const LinearGradient(
          colors: [Color(0xFFFFEEF2), Color(0xFFFFF8FA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? AppColors.purple.withValues(alpha: 0.08)
                : AppColors.shadow,
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Подберите идеальный букет',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: onSurface,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Свежие цветы, стильные композиции и быстрая доставка',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark
                        ? AppColors.darkMutedForeground
                        : AppColors.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 66,
            height: 66,
            decoration: BoxDecoration(
              gradient: isDark ? AppColors.darkBrandGradient : AppColors.brandGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: (isDark ? AppColors.purple : AppColors.primary)
                      .withValues(alpha: 0.18),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.local_florist_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(BuildContext context) {
    final categories = allProducts.map((p) => p.categoryName).toSet().toList();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).cardColor;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final borderColor =
    isDark ? AppColors.darkBorder : AppColors.border;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? AppColors.purple.withValues(alpha: 0.04)
                : AppColors.shadow,
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Фильтры',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...categories.map(
                    (c) => FilterChip(
                  label: Text(c),
                  selected: selectedCategories.contains(c),
                  selectedColor: isDark
                      ? AppColors.purple.withValues(alpha: 0.18)
                      : AppColors.primaryLight,
                  side: BorderSide(color: borderColor),
                  checkmarkColor: isDark ? AppColors.purpleLight : AppColors.primary,
                  onSelected: (_) => _toggleCategory(c),
                ),
              ),
              FilterChip(
                label: const Text('В наличии'),
                selected: inStockOnly,
                selectedColor: isDark
                    ? AppColors.purple.withValues(alpha: 0.18)
                    : AppColors.primaryLight,
                side: BorderSide(color: borderColor),
                checkmarkColor: isDark ? AppColors.purpleLight : AppColors.primary,
                onSelected: (_) {
                  setState(() {
                    inStockOnly = !inStockOnly;
                    _applyFilters();
                  });
                },
              ),
              TextButton(
                onPressed: _clearFilters,
                child: Text(
                  'Очистить',
                  style: TextStyle(
                    color: isDark ? AppColors.purpleLight : AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Цена',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: onSurface,
            ),
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: isDark ? AppColors.purple : AppColors.primary,
              thumbColor: isDark ? AppColors.purple : AppColors.primary,
              overlayColor: (isDark ? AppColors.purple : AppColors.primary)
                  .withValues(alpha: 0.15),
              inactiveTrackColor: isDark
                  ? AppColors.darkBorderSoft
                  : AppColors.primaryLight,
            ),
            child: RangeSlider(
              min: 0,
              max: 10000,
              divisions: 100,
              values: priceRange,
              labels: RangeLabels(
                '${priceRange.start.toStringAsFixed(0)} ₽',
                '${priceRange.end.toStringAsFixed(0)} ₽',
              ),
              onChanged: (range) {
                setState(() => priceRange = range);
                _applyFilters();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: onSurface,
        ),
      ),
    );
  }

  Widget _buildSection(
      BuildContext context,
      String title,
      List<Product> products,
      ) {
    final displayProducts = filteredProducts.isEmpty && searchQuery.isNotEmpty
        ? []
        : products.where((p) => filteredProducts.contains(p)).toList();

    if (displayProducts.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(context, title),
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
          itemBuilder: (context, index) {
            final product = displayProducts[index];
            return ProductCard(
              product: product,
              cartController: cartController,
              authController: Get.find(),
              onViewDetails: () => _openProductDetail(product),
              onAddToCart: () async {
                if (!Get.find<AuthController>().isLoggedIn) {
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

  Widget _buildSearchBar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: TextField(
        onChanged: (value) {
          setState(() => searchQuery = value);
          _applyFilters();
        },
        decoration: InputDecoration(
          hintText: 'Поиск цветов...',
          prefixIcon: Icon(
            Icons.search_rounded,
            color: isDark ? AppColors.purpleLight : AppColors.primary,
          ),
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
    final bg = Theme.of(context).scaffoldBackgroundColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      backgroundColor: bg,
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? const LinearGradient(
            colors: [
              AppColors.darkBackground,
              AppColors.darkBackgroundSecondary,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          )
              : null,
        ),
        child: SafeArea(
          child: isLoading
              ? Center(
            child: CircularProgressIndicator(
              color: isDark ? AppColors.purple : AppColors.primary,
            ),
          )
              : RefreshIndicator(
            onRefresh: _loadProducts,
            color: isDark ? AppColors.purple : AppColors.primary,
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context),
                  _buildSearchBar(context),
                  _buildFilters(context),
                  _buildSection(context, 'Популярное', popularProducts),
                  _buildSection(context, 'Новинки', newProducts),
                  _buildSection(context, 'Все товары', allProducts),
                  if (filteredProducts.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Text(
                          'Товары не найдены',
                          style: TextStyle(
                            fontSize: 16,
                            color: isDark
                                ? AppColors.darkMutedForeground
                                : onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
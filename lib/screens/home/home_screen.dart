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
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color onSurface = Theme.of(context).colorScheme.onSurface;
    final Color muted = isDark
        ? AppColors.darkMutedForeground
        : AppColors.mutedForeground;
    final Color border = isDark ? AppColors.darkBorder : AppColors.border;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: isDark
            ? AppColors.darkCardGradient
            : const LinearGradient(
          colors: [Color(0xFFFFEEF2), Color(0xFFFFF8FA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? AppColors.purple.withValues(alpha: 0.08)
                : AppColors.shadow,
            blurRadius: 16,
            offset: const Offset(0, 6),
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
                    fontWeight: FontWeight.w700,
                    color: onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Свежие цветы, стильные композиции и быстрая доставка',
                  style: TextStyle(
                    fontSize: 14,
                    color: muted,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurfaceElevated : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : Colors.transparent,
              ),
            ),
            child: Icon(
              Icons.local_florist_rounded,
              color: isDark ? AppColors.purpleLight : AppColors.primary,
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
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color cardColor = Theme.of(context).cardColor;
    final Color onSurface = Theme.of(context).colorScheme.onSurface;
    final Color muted = isDark
        ? AppColors.darkMutedForeground
        : AppColors.mutedForeground;
    final Color border = isDark ? AppColors.darkBorder : AppColors.border;

    final List<String> categories =
    allProducts.map((Product p) => p.categoryName).toSet().toList();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: isDark ? AppColors.darkCardGradient : null,
        color: isDark ? null : cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? AppColors.purple.withValues(alpha: 0.08)
                : AppColors.shadow,
            blurRadius: 16,
            offset: const Offset(0, 6),
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
                    (String c) => FilterChip(
                  label: Text(
                    c,
                    style: TextStyle(
                      color: selectedCategories.contains(c)
                          ? Colors.white
                          : onSurface,
                    ),
                  ),
                  selected: selectedCategories.contains(c),
                  selectedColor:
                  isDark ? AppColors.purple : AppColors.primary,
                  backgroundColor:
                  isDark ? AppColors.darkSurfaceElevated : Colors.white,
                  side: BorderSide(color: border),
                  checkmarkColor: Colors.white,
                  onSelected: (_) => _toggleCategory(c),
                ),
              ),
              FilterChip(
                label: Text(
                  'В наличии',
                  style: TextStyle(
                    color: inStockOnly ? Colors.white : onSurface,
                  ),
                ),
                selected: inStockOnly,
                selectedColor: isDark ? AppColors.purple : AppColors.primary,
                backgroundColor:
                isDark ? AppColors.darkSurfaceElevated : Colors.white,
                side: BorderSide(color: border),
                checkmarkColor: Colors.white,
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
                    fontWeight: FontWeight.w600,
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
          RangeSlider(
            min: 0,
            max: 10000,
            divisions: 100,
            values: priceRange,
            activeColor: isDark ? AppColors.purple : AppColors.primary,
            inactiveColor:
            isDark ? AppColors.darkBorderSoft : AppColors.primaryLight,
            labels: RangeLabels(
              '${priceRange.start.toStringAsFixed(0)} ₽',
              '${priceRange.end.toStringAsFixed(0)} ₽',
            ),
            onChanged: (RangeValues range) {
              setState(() => priceRange = range);
              _applyFilters();
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${priceRange.start.toStringAsFixed(0)} ₽',
                style: TextStyle(
                  color: muted,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${priceRange.end.toStringAsFixed(0)} ₽',
                style: TextStyle(
                  color: muted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    final Color onSurface = Theme.of(context).colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: onSurface,
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
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color border = isDark ? AppColors.darkBorder : AppColors.border;
    final Color fillColor =
    isDark ? AppColors.darkSurfaceElevated : Theme.of(context).cardColor;
    final Color hintColor = isDark
        ? AppColors.darkMutedForeground
        : AppColors.mutedForeground;
    final Color iconColor =
    isDark ? AppColors.purpleLight : AppColors.primary;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: TextField(
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
        ),
        onChanged: (String value) {
          setState(() => searchQuery = value);
          _applyFilters();
        },
        decoration: InputDecoration(
          hintText: 'Поиск цветов...',
          hintStyle: TextStyle(color: hintColor),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: iconColor,
          ),
          suffixIcon: searchQuery.isNotEmpty
              ? IconButton(
            icon: Icon(
              Icons.close_rounded,
              color: hintColor,
            ),
            onPressed: () {
              setState(() => searchQuery = '');
              _applyFilters();
            },
          )
              : null,
          filled: true,
          fillColor: fillColor,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(color: border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(color: border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(
              color: isDark ? AppColors.purple : AppColors.primary,
              width: 1.4,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bg = Theme.of(context).scaffoldBackgroundColor;
    final Color muted = isDark
        ? AppColors.darkMutedForeground
        : AppColors.mutedForeground;

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
                  _buildHeader(),
                  _buildSmartBouquetBlock(),
                  _buildSearchBar(),
                  _buildFilters(),
                  _buildSection('Популярное', popularProducts),
                  _buildSection('Новинки', newProducts),
                  _buildSection('Все товары', allProducts),
                  if (filteredProducts.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Text(
                          'Товары не найдены',
                          style: TextStyle(
                            fontSize: 16,
                            color: muted,
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
import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../widgets/product_card.dart';
import '../../models/product.dart';
import '../../api/api_service.dart';
import '../auth/auth_screen.dart';
import '../../widgets/product_detail.dart'; // <-- импорт экрана деталей

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Product> popularProducts = [];
  List<Product> newProducts = [];
  List<Product> allProducts = [];
  bool isLoading = true;
  bool isError = false;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    try {
      final fetchedAll = await ApiService.fetchAllProducts();
      final fetchedPopular = await ApiService.fetchPopularProducts();
      final fetchedNew = fetchedAll.length >= 4
          ? fetchedAll.sublist(fetchedAll.length - 4).reversed.toList()
          : fetchedAll.reversed.toList();

      if (!mounted) return;
      setState(() {
        allProducts = fetchedAll;
        popularProducts = fetchedPopular;
        newProducts = fetchedNew;
        isLoading = false;
        isError = false;
      });
    } catch (e) {
      print("Ошибка загрузки товаров: $e");
      setState(() {
        isLoading = false;
        isError = true;
      });
    }
  }

  void _handleAddToCart(Product product) async {
    final loggedIn = await ApiService.isLoggedIn();
    if (!loggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Пожалуйста, войдите или зарегистрируйтесь, чтобы добавить товар в корзину'),
        ),
      );
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const AuthScreen()),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${product.name} добавлен в корзину')),
    );
  }

  Widget _buildProductList(List<Product> products) {
    return SizedBox(
      height: 260,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: products.length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final product = products[index];
          return SizedBox(
            width: 180,
            child: ProductCard(
              product: product,
              onAddToCart: () => _handleAddToCart(product),
              onViewDetails: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProductDetail(
                      product: product,
                      onAddToCart: () => _handleAddToCart(product),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    if (isError) {
      return Scaffold(
        body: Center(
          child: Text(
            'Ошибка загрузки товаров',
            style: TextStyle(color: Colors.red.shade700, fontSize: 18),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Image.asset('assets/flowerLogo2.png', width: 36),
            const SizedBox(width: 8),
            const Text(
              'Цветочный магазин',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadProducts,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Популярное', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _buildProductList(popularProducts),
              const SizedBox(height: 32),
              const Text('Новинки', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _buildProductList(newProducts),
              const SizedBox(height: 32),
              const Text('Все товары', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.72,
                ),
                itemCount: allProducts.length,
                itemBuilder: (context, index) {
                  final product = allProducts[index];
                  return ProductCard(
                    product: product,
                    onAddToCart: () => _handleAddToCart(product),
                    onViewDetails: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProductDetail(
                            product: product,
                            onAddToCart: () => _handleAddToCart(product),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

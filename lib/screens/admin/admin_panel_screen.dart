import 'package:flutter/material.dart';

import '../../api/server_api_service.dart';
import '../../utils/app_colors.dart';
import '../auth/auth_screen.dart';
import 'admin_orders_screen.dart';
import 'admin_users_screen.dart';
import 'create_product_screen.dart';
import 'edit_product_screen.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  List<Map<String, dynamic>> products = <Map<String, dynamic>>[];
  Map<String, dynamic>? stats;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadProducts();
  }

  Future<void> loadProducts() async {
    try {
      final List<Map<String, dynamic>> data =
      await ServerApiService.getProducts();
      final Map<String, dynamic> statsData =
      await ServerApiService.getAdminStats();

      if (!mounted) {
        return;
      }

      setState(() {
        products = data;
        stats = statsData;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        isLoading = false;
      });

      _showMessage('Ошибка: $e');
    }
  }

  Future<void> deleteProduct(int id) async {
    try {
      await ServerApiService.deleteProduct(id);

      if (!mounted) return;

      setState(() {
        products.removeWhere((Map<String, dynamic> item) {
          return _toInt(item['id']) == id;
        });
      });

      try {
        stats = await ServerApiService.getAdminStats();
        if (mounted) {
          setState(() {});
        }
      } catch (_) {}

      _showMessage('Товар удалён');
    } catch (e) {
      if (!mounted) return;
      _showMessage('Ошибка удаления товара: $e');
    }
  }

  Future<void> logout() async {
    await ServerApiService.logout();

    if (!mounted) {
      return;
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthScreen()),
          (route) => false,
    );
  }

  Future<void> openOrders() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AdminOrdersScreen()),
    );

    await loadProducts();
  }

  Future<void> openUsers() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AdminUsersScreen()),
    );

    await loadProducts();
  }

  Future<void> openCreateProduct() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CreateProductScreen()),
    );

    if (result == true) {
      await loadProducts();
      if (!mounted) return;
      _showMessage('Товар добавлен');
    }
  }

  Future<void> openEditProduct(Map<String, dynamic> product) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EditProductScreen(product: product),
      ),
    );

    if (result == true) {
      await loadProducts();
      if (!mounted) return;
      _showMessage('Товар обновлён');
    }
  }

  Future<void> confirmDeleteProduct(Map<String, dynamic> product) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final bool isDark =
            Theme.of(dialogContext).brightness == Brightness.dark;

        return AlertDialog(
          backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
          title: const Text('Удалить товар?'),
          content: Text(
            'Товар "${product['name'] ?? ''}" будет удалён из списка товаров.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text(
                'Удалить',
                style: TextStyle(color: AppColors.danger),
              ),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await deleteProduct(_toInt(product['id']));
    }
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  int _toInt(dynamic value) {
    if (value == null) {
      return 0;
    }

    if (value is int) {
      return value;
    }

    return int.tryParse(value.toString()) ?? 0;
  }

  double _toDouble(dynamic value) {
    if (value == null) {
      return 0;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString()) ?? 0;
  }

  Color _accentColor(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? AppColors.purpleLight : AppColors.primary;
  }

  Color _cardColor(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? AppColors.darkSurface : Colors.white;
  }

  Color _borderColor(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? AppColors.darkBorder : const Color(0xFFE9E3EA);
  }

  Color _textColor(BuildContext context) {
    return Theme.of(context).colorScheme.onSurface;
  }

  Color _mutedColor(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
  }

  BoxDecoration _adminCardDecoration(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return BoxDecoration(
      gradient: isDark ? AppColors.darkCardGradient : null,
      color: isDark ? null : Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: _borderColor(context)),
      boxShadow: [
        BoxShadow(
          color: isDark
              ? Colors.black.withOpacity(0.20)
              : Colors.black.withOpacity(0.055),
          blurRadius: 16,
          offset: const Offset(0, 7),
        ),
      ],
    );
  }

  Widget _statCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: _adminCardDecoration(context),
        child: Column(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withOpacity(isDark ? 0.18 : 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: color,
                size: 22,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: value.length > 7 ? 14 : 18,
                fontWeight: FontWeight.w800,
                color: _textColor(context),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: _mutedColor(context),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statsBlock(BuildContext context) {
    final Map<String, dynamic>? data = stats;

    if (data == null) {
      return const SizedBox.shrink();
    }

    final double revenue = _toDouble(data['revenue']);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final Color pink = isDark ? AppColors.purpleLight : AppColors.primary;
    final Color violet = isDark ? AppColors.purple : const Color(0xFF7C5CFF);
    final Color blue = isDark ? const Color(0xFF7DD3FC) : const Color(0xFF2E9AFE);
    final Color green = isDark ? const Color(0xFF86EFAC) : const Color(0xFF18A558);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
      child: Column(
        children: [
          Row(
            children: [
              _statCard(
                context: context,
                icon: Icons.local_florist,
                title: 'Товары',
                value: '${data['products_count'] ?? 0}',
                color: pink,
              ),
              const SizedBox(width: 10),
              _statCard(
                context: context,
                icon: Icons.receipt_long,
                title: 'Заказы',
                value: '${data['orders_count'] ?? 0}',
                color: violet,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _statCard(
                context: context,
                icon: Icons.people,
                title: 'Пользователи',
                value: '${data['customers_count'] ?? 0}',
                color: blue,
              ),
              const SizedBox(width: 10),
              _statCard(
                context: context,
                icon: Icons.payments,
                title: 'Выручка',
                value: '${revenue.toStringAsFixed(0)} ₽',
                color: green,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _adminActions(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                gradient:
                isDark ? AppColors.darkBrandGradient : AppColors.brandGradient,
                borderRadius: BorderRadius.circular(17),
                boxShadow: [
                  BoxShadow(
                    color: _accentColor(context).withOpacity(0.18),
                    blurRadius: 16,
                    offset: const Offset(0, 7),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: openOrders,
                icon: const Icon(Icons.receipt_long),
                label: const Text(
                  'Заказы',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(17),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color: _cardColor(context),
                borderRadius: BorderRadius.circular(17),
                border: Border.all(
                  color: _borderColor(context),
                ),
              ),
              child: OutlinedButton.icon(
                onPressed: openUsers,
                icon: Icon(
                  Icons.people_alt_rounded,
                  color: _accentColor(context),
                ),
                label: Text(
                  'Пользователи',
                  style: TextStyle(
                    color: _accentColor(context),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(17),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _productCard(BuildContext context, Map<String, dynamic> product) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final bool inStock = product['in_stock'] == true;
    final Color accent = _accentColor(context);
    final Color muted = _mutedColor(context);
    final Color text = _textColor(context);

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      decoration: _adminCardDecoration(context),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.network(
                product['image_url']?.toString() ?? '',
                width: 72,
                height: 72,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkSurfaceElevated
                          : const Color(0xFFF1EEF2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.image_not_supported_outlined,
                      color: muted,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product['name']?.toString() ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: text,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Цена: ${product['price']} ₽',
                    style: TextStyle(
                      color: text,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: inStock
                          ? AppColors.success.withOpacity(isDark ? 0.18 : 0.12)
                          : AppColors.danger.withOpacity(isDark ? 0.18 : 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      inStock ? 'В наличии' : 'Нет в наличии',
                      style: TextStyle(
                        color: inStock ? AppColors.success : AppColors.danger,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                IconButton(
                  icon: Icon(
                    Icons.edit_rounded,
                    color: accent,
                  ),
                  onPressed: () {
                    openEditProduct(product);
                  },
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete_rounded,
                    color: AppColors.danger,
                  ),
                  onPressed: () {
                    confirmDeleteProduct(product);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _productsList(BuildContext context) {
    if (products.isEmpty) {
      return Center(
        child: Text(
          'Товары не найдены',
          style: TextStyle(
            color: _mutedColor(context),
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: loadProducts,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 90),
        itemCount: products.length,
        itemBuilder: (context, index) {
          final Map<String, dynamic> product = products[index];
          return _productCard(context, product);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bg = Theme.of(context).scaffoldBackgroundColor;
    final Color text = _textColor(context);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Text(
          'Админ панель',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: text,
          ),
        ),
        centerTitle: true,
        backgroundColor: bg,
        foregroundColor: text,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              Icons.logout_rounded,
              color: text,
            ),
            onPressed: logout,
          ),
        ],
      ),
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
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
          children: [
            _statsBlock(context),
            _adminActions(context),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
              child: Row(
                children: [
                  Text(
                    'Товары',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                      color: text,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _productsList(context),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: openCreateProduct,
        backgroundColor: _accentColor(context),
        foregroundColor: Colors.white,
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}
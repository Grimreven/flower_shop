import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'controllers/auth_controller.dart';
import 'screens/auth/auth_screen.dart';
import 'screens/cart/cart_screen.dart';
import 'screens/favorites/favorites_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/order/orders_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'utils/app_colors.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _currentIndex;
  final AuthController authController = Get.find<AuthController>();
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();

    _pages = [
      const HomeScreen(),
      FavoritesScreen(),
      const CartScreen(),
      const OrdersScreen(),
      const ProfileScreen(),
    ];

    final args = Get.arguments;
    _currentIndex =
    (args is Map && args['tabIndex'] is int) ? args['tabIndex'] as int : 0;
  }

  Future<void> _onTabTapped(int index) async {
    final restrictedTabs = [1, 2, 3, 4];

    if (restrictedTabs.contains(index) && authController.token.isEmpty) {
      _showAuthDialog();
      return;
    }

    setState(() => _currentIndex = index);
  }

  void _showAuthDialog() {
    Get.defaultDialog(
      title: "Требуется вход",
      titleStyle: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 20,
        color: AppColors.primary,
      ),
      middleText:
      "Чтобы открыть этот раздел, пожалуйста, авторизуйтесь или зарегистрируйтесь.",
      textConfirm: "Войти",
      textCancel: "Отмена",
      confirmTextColor: Colors.white,
      buttonColor: AppColors.primary,
      cancelTextColor: AppColors.mutedForeground,
      radius: 20,
      onConfirm: () {
        Get.back();
        Get.to(() => const AuthScreen());
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color surface = Theme.of(context).colorScheme.surface;
    final Color borderColor = isDark ? AppColors.darkBorder : AppColors.border;

    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: _pages[_currentIndex],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: surface,
          border: Border(
            top: BorderSide(color: borderColor),
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? AppColors.purple.withValues(alpha: 0.05)
                  : AppColors.shadow,
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
          selectedItemColor: isDark ? AppColors.purple : AppColors.primary,
          unselectedItemColor:
          isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground,
          type: BottomNavigationBarType.fixed,
          backgroundColor: surface,
          elevation: 0,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              label: 'Главная',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.favorite_border_rounded),
              activeIcon: Icon(Icons.favorite_rounded),
              label: 'Избранное',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart_rounded),
              label: 'Корзина',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_rounded),
              label: 'Заказы',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded),
              label: 'Профиль',
            ),
          ],
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'controllers/auth_controller.dart';
import 'screens/home/home_screen.dart';
import 'screens/cart/cart_screen.dart';
import 'screens/order/orders_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/auth/auth_screen.dart';
import 'utils/app_colors.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final AuthController authController = Get.find<AuthController>();

  final List<Widget> _pages = const [
    HomeScreen(),
    CartScreen(),
    OrdersScreen(),
    ProfileScreen(),
  ];

  /// Проверяем авторизацию перед переходом
  Future<void> _onTabTapped(int index) async {
    // вкладки, где нужна авторизация
    final restrictedTabs = [1, 2, 3]; // корзина, заказы, профиль

    if (restrictedTabs.contains(index) && authController.token.isEmpty) {
      // пользователь не авторизован
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
      "Чтобы просмотреть эту страницу, пожалуйста, авторизуйтесь или зарегистрируйтесь.",
      textConfirm: "Войти",
      textCancel: "Отмена",
      confirmTextColor: Colors.white,
      buttonColor: AppColors.primary,
      cancelTextColor: AppColors.mutedForeground,
      onConfirm: () {
        Get.back(); // закрыть диалог
        Get.to(() => const AuthScreen());
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Главная'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Корзина'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Заказы'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Профиль'),
        ],
      ),
    );
  }
}

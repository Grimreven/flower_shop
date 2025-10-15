import 'package:flutter/material.dart';
import 'package:flower_shop/screens/profile/profile_screen.dart';
import 'package:flower_shop/screens/home/home_screen.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flower_shop/screens/auth/auth_screen.dart';
import 'screens/search/search_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  bool _isLoggedIn = false;

  // Список категорий (можно подгружать из API)
  final List<String> categories = ['Орхидеи', 'Розы', 'Лилии', 'Тюльпаны'];

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    setState(() {
      _isLoggedIn = token != null && token.isNotEmpty;
    });
  }

  void _handleSearch(String query) {
    // Логика поиска по товарам
    print('Поиск: $query');
  }

  void _handleFilter(SearchFilters filters) {
    // Логика фильтров
    print('Фильтры: ${filters.categories}, '
        '${filters.priceRange.start}-${filters.priceRange.end}, '
        'В наличии: ${filters.inStockOnly}');
  }

  Future<void> _onTabTapped(int index) async {
    // Проверяем авторизацию для ограниченных вкладок
    if ((index == 2 || index == 3 || index == 4) && !_isLoggedIn) {
      _showAuthDialog();
      return;
    }

    setState(() => _currentIndex = index);
  }

  void _showAuthDialog() {
    Get.defaultDialog(
      title: 'Требуется авторизация',
      titleStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      middleText:
      'Чтобы использовать корзину, заказы и профиль, пожалуйста, войдите или зарегистрируйтесь.',
      middleTextStyle: const TextStyle(fontSize: 15),
      barrierDismissible: true,
      radius: 15,
      confirm: ElevatedButton.icon(
        onPressed: () {
          Get.back();
          Get.to(() => const AuthScreen(initialTab: AuthTab.login));
        },
        icon: const Icon(Icons.login),
        label: const Text('Войти'),
        style: ElevatedButton.styleFrom(backgroundColor: Colors.pinkAccent),
      ),
      cancel: OutlinedButton.icon(
        onPressed: () {
          Get.back();
          Get.to(() => const AuthScreen(initialTab: AuthTab.register));
        },
        icon: const Icon(Icons.person_add),
        label: const Text('Регистрация'),
        style: OutlinedButton.styleFrom(foregroundColor: Colors.pinkAccent),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      const HomeScreen(),
      SearchScreen(
        categories: categories,
      ),
      const Center(child: Text('Корзина', style: TextStyle(fontSize: 24))),
      const Center(child: Text('Заказы', style: TextStyle(fontSize: 24))),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.pinkAccent,
        unselectedItemColor: Colors.grey,
        onTap: _onTabTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Главная'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Поиск'),
          BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart), label: 'Корзина'),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Заказы'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Профиль'),
        ],
      ),
    );
  }
}

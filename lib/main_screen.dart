import 'package:flutter/material.dart';
import 'package:flower_shop/api/api_service.dart';
import 'package:flower_shop/screens/home/home_screen.dart';
import 'package:flower_shop/screens/cart/cart_screen.dart';
import 'package:flower_shop/screens/orders/orders_screen.dart';
import 'package:flower_shop/screens/profile/profile_screen.dart';
import 'package:flower_shop/screens/auth/auth_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  final List<Widget> _screens = [
    const HomeScreen(),
    const CartScreen(),
    OrdersScreen(),
    const ProfileScreen(),
  ];

  Future<void> _onItemTapped(int index) async {
    bool isLoggedIn = await ApiService.isLoggedIn();

    // Проверяем, если выбрана корзина, заказы или профиль — и не авторизован
    if ((index == 1 || index == 2 || index == 3) && !isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Пожалуйста, войдите или зарегистрируйтесь'),
          backgroundColor: Colors.pinkAccent,
        ),
      );
      // Переход на экран авторизации
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const AuthScreen()),
      );
      return;
    }

    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.pinkAccent,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Главная',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart_outlined),
            label: 'Корзина',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            label: 'Заказы',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Профиль',
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'controllers/auth_controller.dart';
import 'controllers/cart_controller.dart';
import 'main_screen.dart';
import 'screens/order/order_success_screen.dart';
import 'screens/order/orders_screen.dart';
import 'screens/order/order_detail_screen.dart';
import 'utils/app_colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Регистрируем контроллеры
  final authController = Get.put(AuthController(), permanent: true);
  Get.put(CartController(authController: authController), permanent: true);

  runApp(const FlowerShopApp());
}

class FlowerShopApp extends StatelessWidget {
  const FlowerShopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Цветочный магазин',
      theme: ThemeData(
        primarySwatch: Colors.pink,
        scaffoldBackgroundColor: AppColors.background,
        fontFamily: 'Montserrat',
      ),

      // ✅ теперь у нас маршрутизация GetX
      initialRoute: '/splash',
      getPages: [
        GetPage(name: '/splash', page: () => const SplashScreen()),
        GetPage(name: '/main', page: () => const MainScreen()),
        GetPage(name: '/orders', page: () => const OrdersScreen()),
        GetPage(name: '/order_success', page: () => const OrderSuccessScreen()),
        GetPage(name: '/order_details', page: () => const OrderDetailScreenPlaceholder()),
      ],
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _controller.forward();

    Future.delayed(const Duration(seconds: 3), () {
      Get.offNamed('/main');
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: FadeTransition(
        opacity: _animation,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/flowerLogo2.png', width: 150),
              const SizedBox(height: 24),
              const Text(
                'Цветочный магазин',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Добро пожаловать!',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Откройте для себя мир прекрасных цветов',
                style: TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Временный заглушечный экран
class OrderDetailScreenPlaceholder extends StatelessWidget {
  const OrderDetailScreenPlaceholder({super.key});
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Экран деталей заказа')),
    );
  }
}

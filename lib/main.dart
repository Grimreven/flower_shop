import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'bindings/app_bindings.dart';
import 'controllers/settings_controller.dart';
import 'main_screen.dart';
import 'screens/auth/auth_screen.dart';
import 'screens/cart/cart_screen.dart';
import 'screens/favorites/favorites_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/order/orders_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'utils/app_colors.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await GetStorage.init();

  AppBindings().dependencies();

  runApp(const FlowerShopApp());
}

class FlowerShopApp extends StatelessWidget {
  const FlowerShopApp({super.key});

  @override
  Widget build(BuildContext context) {
    final SettingsController settingsController =
    Get.find<SettingsController>();

    return Obx(
          () => GetMaterialApp(
        title: 'Flower Shop',
        debugShowCheckedModeBanner: false,
        theme: _lightTheme(),
        darkTheme: _darkTheme(),
        themeMode: settingsController.darkTheme.value
            ? ThemeMode.dark
            : ThemeMode.light,
        initialRoute: '/main',
        getPages: [
          GetPage(
            name: '/main',
            page: () => const MainScreen(),
          ),
          GetPage(
            name: '/auth',
            page: () => AuthScreen(),
          ),
          GetPage(
            name: '/home',
            page: () => const HomeScreen(),
          ),
          GetPage(
            name: '/favorites',
            page: () => FavoritesScreen(),
          ),
          GetPage(
            name: '/cart',
            page: () => const CartScreen(),
          ),
          GetPage(
            name: '/orders',
            page: () => const OrdersScreen(),
          ),
          GetPage(
            name: '/profile',
            page: () => const ProfileScreen(),
          ),
        ],
      ),
    );
  }

  ThemeData _lightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.primary,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
        primary: AppColors.primary,
        surface: AppColors.surface,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.foreground,
        titleTextStyle: TextStyle(
          color: AppColors.foreground,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
      ),
      cardColor: AppColors.surface,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: AppColors.border,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: AppColors.border,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: AppColors.primary,
            width: 1.4,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.mutedForeground,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
    );
  }

  ThemeData _darkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkBackground,
      primaryColor: AppColors.purple,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.purple,
        brightness: Brightness.dark,
        primary: AppColors.purple,
        surface: AppColors.darkSurface,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppColors.darkBackground,
        foregroundColor: AppColors.darkForeground,
        titleTextStyle: TextStyle(
          color: AppColors.darkForeground,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
      ),
      cardColor: AppColors.darkSurface,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurfaceElevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: AppColors.darkBorder,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: AppColors.darkBorder,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: AppColors.purple,
            width: 1.4,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.purple,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.darkSurface,
        selectedItemColor: AppColors.purple,
        unselectedItemColor: AppColors.darkMutedForeground,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
    );
  }
}
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/auth_service.dart';
import 'cart_controller.dart';
import 'package:flower_shop/api/cart_service.dart';

class AuthController extends GetxController {
  final AuthService _authService = AuthService();

  var token = ''.obs;

  bool get isLoggedIn => token.isNotEmpty;

  @override
  void onInit() {
    super.onInit();
    _loadToken();
  }

  // ------------------- Загрузка токена и корзины -------------------
  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    token.value = prefs.getString('token') ?? '';

    // Если пользователь уже авторизован, подгружаем корзину
    if (isLoggedIn && Get.isRegistered<CartController>()) {
      final cartController = Get.find<CartController>();
      try {
        await cartController.loadCartFromServer();
      } catch (e) {
        Get.snackbar('Ошибка', 'Не удалось загрузить корзину: $e',
            snackPosition: SnackPosition.BOTTOM);
      }
    }
  }

  Future<void> _saveToken(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', value);
    token.value = value;
  }

  // ------------------- Логин -------------------
  Future<bool> login(String email, String password) async {
    try {
      final result = await _authService.login(email, password);
      if (result.containsKey('token')) {
        await _saveToken(result['token']);

        // Загрузка корзины после успешного входа
        if (Get.isRegistered<CartController>()) {
          final cartController = Get.find<CartController>();
          try {
            await cartController.loadCartFromServer();
          } catch (e) {
            Get.snackbar('Ошибка', 'Не удалось загрузить корзину: $e',
                snackPosition: SnackPosition.BOTTOM);
          }
        }

        return true;
      } else {
        Get.snackbar('Ошибка', result['message'] ?? 'Неизвестная ошибка',
            snackPosition: SnackPosition.BOTTOM);
        return false;
      }
    } catch (e) {
      Get.snackbar('Ошибка', e.toString(), snackPosition: SnackPosition.BOTTOM);
      return false;
    }
  }

  // ------------------- Регистрация -------------------
  Future<bool> register(String name, String email, String password) async {
    try {
      final result = await _authService.register(name, email, password);
      if (result.containsKey('token')) {
        await _saveToken(result['token']);

        // Подгружаем корзину для нового пользователя (пустая)
        if (Get.isRegistered<CartController>()) {
          final cartController = Get.find<CartController>();
          cartController.items.clear();
        }

        return true;
      } else {
        Get.snackbar('Ошибка', result['message'] ?? 'Неизвестная ошибка',
            snackPosition: SnackPosition.BOTTOM);
        return false;
      }
    } catch (e) {
      Get.snackbar('Ошибка', e.toString(), snackPosition: SnackPosition.BOTTOM);
      return false;
    }
  }

  // ------------------- Выход -------------------
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    token.value = '';

    // Очистка локальной корзины
    if (Get.isRegistered<CartController>()) {
      final cartController = Get.find<CartController>();
      await cartController.clear();
    }

    Get.snackbar('Выход', 'Вы успешно вышли', snackPosition: SnackPosition.BOTTOM);
  }
}

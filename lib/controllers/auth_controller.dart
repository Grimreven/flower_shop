import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/auth_service.dart';

class AuthController extends GetxController {
  final AuthService _authService = AuthService();

  var token = ''.obs;

  bool get isLoggedIn => token.isNotEmpty;

  @override
  void onInit() {
    super.onInit();
    _loadToken();
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    token.value = prefs.getString('token') ?? '';
  }

  Future<void> _saveToken(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', value);
    token.value = value;
  }

  Future<bool> login(String email, String password) async {
    try {
      final result = await _authService.login(email, password);
      if (result.containsKey('token')) {
        await _saveToken(result['token']);
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

  Future<bool> register(String name, String email, String password) async {
    try {
      final result = await _authService.register(name, email, password);
      if (result.containsKey('token')) {
        await _saveToken(result['token']);
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

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    token.value = '';
    Get.snackbar('Выход', 'Вы успешно вышли',
        snackPosition: SnackPosition.BOTTOM);
  }
}

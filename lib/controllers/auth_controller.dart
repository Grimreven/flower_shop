// lib/controllers/auth_controller.dart
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/auth_service.dart';
import '../models/user.dart';

class AuthController extends GetxController {
  final AuthService _authService = AuthService();

  var token = ''.obs;
  var user = Rxn<User>();

  bool get isLoggedIn => token.isNotEmpty;

  @override
  void onInit() {
    super.onInit();
    _loadToken();
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    token.value = prefs.getString('token') ?? '';
    if (token.isNotEmpty) {
      await getProfile();
    }
  }

  Future<void> _saveToken(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', value);
    token.value = value;
  }

  Future<bool> login(String email, String password) async {
    try {
      final result = await _authService.login(email, password);
      if (result != null && result['token'] != null) {
        await _saveToken(result['token']);
        await getProfile();
        return true;
      } else {
        Get.snackbar('Ошибка', result?['message'] ?? 'Неизвестная ошибка',
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
      if (result != null && result['token'] != null) {
        await _saveToken(result['token']);
        await getProfile();
        return true;
      } else {
        Get.snackbar('Ошибка', result?['message'] ?? 'Неизвестная ошибка',
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
    user.value = null;
    Get.snackbar('Выход', 'Вы успешно вышли', snackPosition: SnackPosition.BOTTOM);
  }

  Future<User?> getProfile() async {
    if (token.isEmpty) return null;
    try {
      final data = await _authService.getProfile(token.value);
      if (data != null) {
        user.value = User.fromJson(data);
      }
      return user.value;
    } catch (e) {
      Get.snackbar('Ошибка', 'Не удалось загрузить профиль',
          snackPosition: SnackPosition.BOTTOM);
      return null;
    }
  }

  Future<User?> updateProfile(User updatedUser) async {
    if (token.isEmpty) return null;
    try {
      final data = await _authService.updateProfile(token.value, updatedUser);
      if (data != null) {
        user.value = User.fromJson(data);
      }
      return user.value;
    } catch (e) {
      Get.snackbar('Ошибка', 'Не удалось обновить профиль',
          snackPosition: SnackPosition.BOTTOM);
      return null;
    }
  }

  // ✅ Новый метод для изменения бонусов — через copyWith (User.loyaltyPoints остаётся final)
  void updateLoyaltyPoints(int delta) {
    final currentUser = user.value;
    if (currentUser != null) {
      final newPoints = (currentUser.loyaltyPoints + delta).clamp(0, 1 << 30);
      user.value = currentUser.copyWith(loyaltyPoints: newPoints.toInt());
    }
  }
}

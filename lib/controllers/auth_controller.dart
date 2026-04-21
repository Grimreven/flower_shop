import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/auth_service.dart';
import '../api/local_demo_service.dart';
import '../models/user.dart';
import 'favorites_controller.dart';

class AuthController extends GetxController {
  final AuthService _authService = AuthService();

  final RxString token = ''.obs;
  final Rxn<User> user = Rxn<User>();

  bool get isLoggedIn => token.value.isNotEmpty;

  @override
  void onInit() {
    super.onInit();
    LocalDemoService.instance.ensureSeeded();
  }

  FavoritesController? _favoritesOrNull() {
    try {
      return Get.find<FavoritesController>();
    } catch (_) {
      return null;
    }
  }

  Future<void> loadToken() async {
    await LocalDemoService.instance.ensureSeeded();

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    token.value = prefs.getString('token') ?? '';

    if (token.value.isNotEmpty) {
      await getProfile();
      await _favoritesOrNull()?.loadFavorites();
    } else {
      _favoritesOrNull()?.clearLocalState();
    }
  }

  Future<void> _saveToken(String value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', value);
    token.value = value;
  }

  Future<void> _clearTokenSilently() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    token.value = '';
    user.value = null;
    _favoritesOrNull()?.clearLocalState();
  }

  Future<bool> login(String email, String password) async {
    try {
      final Map<String, dynamic>? result = await _authService.login(
        email,
        password,
      );

      if (result != null && result['token'] != null) {
        await _saveToken(result['token'].toString());
        await getProfile();
        await _favoritesOrNull()?.loadFavorites();
        return true;
      }

      Get.snackbar(
        'Ошибка входа',
        result?['message']?.toString() ?? 'Неизвестная ошибка',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } catch (e) {
      Get.snackbar(
        'Ошибка',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }
  }

  Future<bool> register(String name, String email, String password) async {
    try {
      final Map<String, dynamic>? result = await _authService.register(
        name,
        email,
        password,
      );

      if (result != null && result['token'] != null) {
        await _saveToken(result['token'].toString());
        await getProfile();
        await _favoritesOrNull()?.loadFavorites();
        return true;
      }

      Get.snackbar(
        'Ошибка регистрации',
        result?['message']?.toString() ?? 'Неизвестная ошибка',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } catch (e) {
      Get.snackbar(
        'Ошибка',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }
  }

  Future<void> logout() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');

    token.value = '';
    user.value = null;

    _favoritesOrNull()?.clearLocalState();

    Get.snackbar(
      'Выход',
      'Вы успешно вышли',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  Future<User?> getProfile() async {
    if (token.value.isEmpty) {
      return null;
    }

    try {
      final Map<String, dynamic>? data = await _authService.getProfile(
        token.value,
      );

      if (data == null) {
        Get.snackbar(
          'Ошибка',
          'Не удалось загрузить профиль',
          snackPosition: SnackPosition.BOTTOM,
        );
        return null;
      }

      if (data['authError'] == true) {
        await _clearTokenSilently();
        Get.snackbar(
          'Сессия истекла',
          data['message']?.toString() ?? 'Войдите снова',
          snackPosition: SnackPosition.BOTTOM,
        );
        return null;
      }

      if (data['id'] != null) {
        user.value = User.fromJson(data);
        return user.value;
      }

      Get.snackbar(
        'Ошибка',
        data['message']?.toString() ?? 'Не удалось загрузить профиль',
        snackPosition: SnackPosition.BOTTOM,
      );
      return null;
    } catch (e) {
      Get.snackbar(
        'Ошибка',
        'Не удалось загрузить профиль',
        snackPosition: SnackPosition.BOTTOM,
      );
      return null;
    }
  }

  Future<User?> updateProfile(User updatedUser) async {
    if (token.value.isEmpty) {
      return null;
    }

    try {
      final Map<String, dynamic>? data = await _authService.updateProfile(
        token.value,
        updatedUser,
      );

      if (data == null) {
        Get.snackbar(
          'Ошибка',
          'Не удалось обновить профиль',
          snackPosition: SnackPosition.BOTTOM,
        );
        return null;
      }

      if (data['authError'] == true) {
        await _clearTokenSilently();
        Get.snackbar(
          'Сессия истекла',
          data['message']?.toString() ?? 'Войдите снова',
          snackPosition: SnackPosition.BOTTOM,
        );
        return null;
      }

      if (data['id'] != null) {
        user.value = User.fromJson(data);
        return user.value;
      }

      Get.snackbar(
        'Ошибка',
        data['message']?.toString() ?? 'Не удалось обновить профиль',
        snackPosition: SnackPosition.BOTTOM,
      );
      return null;
    } catch (e) {
      Get.snackbar(
        'Ошибка',
        'Не удалось обновить профиль',
        snackPosition: SnackPosition.BOTTOM,
      );
      return null;
    }
  }

  void updateLoyaltyPoints(int delta) {
    final User? currentUser = user.value;

    if (currentUser != null) {
      final int newPoints = (currentUser.loyaltyPoints + delta).clamp(
        0,
        1 << 30,
      );

      user.value = currentUser.copyWith(
        loyaltyPoints: newPoints.toInt(),
      );
    }
  }
}
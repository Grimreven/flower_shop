import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/auth_service.dart';
import '../api/auth_storage.dart';
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
    final String? savedToken = await AuthStorage.getToken();

    token.value = savedToken ?? prefs.getString('token') ?? '';

    if (token.value.isNotEmpty) {
      await AuthStorage.saveToken(token.value);
      await getProfile();
      await _favoritesOrNull()?.loadFavorites();
    } else {
      _favoritesOrNull()?.clearLocalState();
    }
  }

  Future<void> _saveToken(String value) async {
    await AuthStorage.saveToken(value);
    token.value = value;
  }

  Future<void> _clearTokenSilently() async {
    await AuthStorage.clear();
    token.value = '';
    user.value = null;
    _favoritesOrNull()?.clearLocalState();
  }

  void _safeSnackbar(String title, String message) {
    Future.delayed(Duration.zero, () {
      if (Get.context != null) {
        Get.snackbar(
          title,
          message,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    });
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

      _safeSnackbar(
        'Ошибка входа',
        result?['message']?.toString() ?? 'Неизвестная ошибка',
      );

      return false;
    } catch (e) {
      _safeSnackbar(
        'Ошибка',
        e.toString(),
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

      _safeSnackbar(
        'Ошибка регистрации',
        result?['message']?.toString() ?? 'Неизвестная ошибка',
      );

      return false;
    } catch (e) {
      _safeSnackbar(
        'Ошибка',
        e.toString(),
      );

      return false;
    }
  }

  Future<void> logout() async {
    await AuthStorage.clear();

    token.value = '';
    user.value = null;
    _favoritesOrNull()?.clearLocalState();

    _safeSnackbar(
      'Выход',
      'Вы успешно вышли',
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
        return null;
      }

      if (data['authError'] == true) {
        await _clearTokenSilently();

        _safeSnackbar(
          'Сессия истекла',
          data['message']?.toString() ?? 'Войдите снова',
        );

        return null;
      }

      if (data['id'] != null) {
        user.value = User.fromJson(data);

        return user.value;
      }

      return null;
    } catch (_) {
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
        return null;
      }

      if (data['authError'] == true) {
        await _clearTokenSilently();

        _safeSnackbar(
          'Сессия истекла',
          data['message']?.toString() ?? 'Войдите снова',
        );

        return null;
      }

      if (data['id'] != null) {
        user.value = User.fromJson(data);

        return user.value;
      }

      return null;
    } catch (_) {
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
        loyaltyPoints: newPoints,
      );
    }
  }
}
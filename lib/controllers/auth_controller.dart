import 'package:get/get.dart';

import '../api/auth_storage.dart';
import '../api/server_api_service.dart';
import '../models/user.dart';

class AuthController extends GetxController {
  final Rxn<User> user = Rxn<User>();
  final RxString token = ''.obs;
  final RxBool isLoading = false.obs;

  bool get isLoggedIn => token.value.isNotEmpty && user.value != null;

  @override
  void onInit() {
    super.onInit();
    loadToken();
  }

  Future<void> loadToken() async {
    final String? savedToken = await AuthStorage.getToken();
    final Map<String, dynamic>? savedUser = await AuthStorage.getUser();

    if (savedToken != null && savedToken.isNotEmpty) {
      token.value = savedToken;
    }

    if (savedUser != null) {
      user.value = User.fromJson(savedUser);
    }

    if (token.value.isNotEmpty) {
      try {
        await getProfile();
      } catch (_) {}
    }
  }

  Future<bool> login(String email, String password) async {
    try {
      isLoading.value = true;

      final Map<String, dynamic> data = await ServerApiService.login(
        email: email,
        password: password,
      );

      token.value = data['token']?.toString() ?? '';

      user.value = User.fromJson(
        Map<String, dynamic>.from(data['user'] as Map),
      );

      await AuthStorage.saveAuth(
        token: token.value,
        user: user.value!.toJson(),
      );

      await getProfile();

      return true;
    } catch (e) {
      Get.snackbar(
        'Ошибка',
        e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> register(String name, String email, String password) async {
    try {
      isLoading.value = true;

      final Map<String, dynamic> data = await ServerApiService.register(
        name: name,
        email: email,
        password: password,
      );

      token.value = data['token']?.toString() ?? '';

      user.value = User.fromJson(
        Map<String, dynamic>.from(data['user'] as Map),
      );

      await AuthStorage.saveAuth(
        token: token.value,
        user: user.value!.toJson(),
      );

      await getProfile();

      return true;
    } catch (e) {
      Get.snackbar(
        'Ошибка',
        e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<User?> getProfile() async {
    if (token.value.isEmpty) {
      return user.value;
    }

    final Map<String, dynamic> data = await ServerApiService.getProfile();

    final String oldAddress = user.value?.address ?? '';

    user.value = User.fromJson({
      ...data,
      'address': data['address'] ?? oldAddress,
    });

    await AuthStorage.saveUser(user.value!.toJson());

    return user.value;
  }

  Future<User?> updateProfile(
      User? updatedUser, {
        String? name,
        String? email,
        String? phone,
        String? address,
      }) async {
    try {
      isLoading.value = true;

      final User? current = user.value;

      if (current == null) {
        throw Exception('Пользователь не найден');
      }

      final String newName = updatedUser?.name ?? name ?? current.name;
      final String newEmail = updatedUser?.email ?? email ?? current.email;
      final String newPhone = updatedUser?.phone ?? phone ?? current.phone;
      final String newAddress =
          updatedUser?.address ?? address ?? current.address;

      final Map<String, dynamic> data = await ServerApiService.updateProfile(
        name: newName,
        email: newEmail,
        phone: newPhone,
      );

      user.value = current.copyWith(
        name: data['name']?.toString() ?? newName,
        email: data['email']?.toString() ?? newEmail,
        phone: data['phone']?.toString() ?? newPhone,
        address: newAddress,
      );

      await AuthStorage.saveUser(user.value!.toJson());

      return user.value;
    } catch (e) {
      Get.snackbar(
        'Ошибка',
        e.toString().replaceAll('Exception: ', ''),
      );
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    await ServerApiService.logout();

    token.value = '';
    user.value = null;
  }
}
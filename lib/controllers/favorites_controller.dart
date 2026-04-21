import 'package:get/get.dart';

import '../api/api_service.dart';
import '../api/favorites_service.dart';
import '../controllers/auth_controller.dart';
import '../models/product.dart';

class FavoritesController extends GetxController {
  final AuthController authController = Get.find<AuthController>();
  final FavoritesService _favoritesService = FavoritesService.instance;

  final RxList<int> favoriteIds = <int>[].obs;
  final RxList<Product> favoriteProducts = <Product>[].obs;
  final RxBool isLoading = false.obs;

  bool get isAuthorized => authController.token.value.isNotEmpty;

  bool isFavorite(int productId) => favoriteIds.contains(productId);

  @override
  void onInit() {
    super.onInit();

    ever<String>(authController.token, (_) async {
      await loadFavorites();
    });

    loadFavorites();
  }

  Future<void> loadFavorites() async {
    isLoading.value = true;

    try {
      if (!isAuthorized) {
        favoriteIds.clear();
        favoriteProducts.clear();
        return;
      }

      final List<int> ids =
      await _favoritesService.getFavorites(authController.token.value);

      favoriteIds.assignAll(ids);

      final List<Product> allProducts = await ApiService.fetchAllProducts();

      favoriteProducts.assignAll(
        allProducts.where((product) => ids.contains(product.id)).toList(),
      );
    } catch (e) {
      favoriteIds.clear();
      favoriteProducts.clear();

      Get.snackbar(
        'Ошибка',
        'Не удалось загрузить избранное',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> toggleFavorite(Product product) async {
    if (!isAuthorized) {
      Get.snackbar(
        'Требуется вход',
        'Авторизуйтесь, чтобы добавлять товары в избранное',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final bool wasFavorite = isFavorite(product.id);

    try {
      await _favoritesService.toggleFavorite(
        authController.token.value,
        product.id,
      );

      if (wasFavorite) {
        favoriteIds.remove(product.id);
        favoriteProducts.removeWhere((item) => item.id == product.id);
      } else {
        favoriteIds.add(product.id);

        final bool alreadyExists = favoriteProducts.any(
              (item) => item.id == product.id,
        );

        if (!alreadyExists) {
          favoriteProducts.add(product);
        }
      }

      favoriteIds.refresh();
      favoriteProducts.refresh();

      Get.snackbar(
        wasFavorite ? 'Удалено' : 'Добавлено',
        wasFavorite
            ? '${product.name} удалён из избранного'
            : '${product.name} добавлен в избранное',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Ошибка',
        'Не удалось изменить избранное',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> removeFavorite(Product product) async {
    if (!isAuthorized) {
      return;
    }

    try {
      await _favoritesService.removeFavorite(
        authController.token.value,
        product.id,
      );

      favoriteIds.remove(product.id);
      favoriteProducts.removeWhere((item) => item.id == product.id);

      favoriteIds.refresh();
      favoriteProducts.refresh();

      Get.snackbar(
        'Удалено',
        '${product.name} удалён из избранного',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Ошибка',
        'Не удалось удалить из избранного',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> clearFavorites() async {
    if (!isAuthorized) {
      favoriteIds.clear();
      favoriteProducts.clear();
      return;
    }

    try {
      await _favoritesService.clearFavorites(authController.token.value);

      favoriteIds.clear();
      favoriteProducts.clear();

      favoriteIds.refresh();
      favoriteProducts.refresh();

      Get.snackbar(
        'Готово',
        'Избранное очищено',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Ошибка',
        'Не удалось очистить избранное',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void clearLocalState() {
    favoriteIds.clear();
    favoriteProducts.clear();
    favoriteIds.refresh();
    favoriteProducts.refresh();
  }
}
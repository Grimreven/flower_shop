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

  bool isFavorite(int productId) => favoriteIds.contains(productId);

  @override
  void onInit() {
    super.onInit();

    ever<String>(authController.token, (_) {
      loadFavorites();
    });

    loadFavorites();
  }

  Future<void> loadFavorites() async {
    if (!authController.isLoggedIn || authController.token.value.isEmpty) {
      favoriteIds.clear();
      favoriteProducts.clear();
      return;
    }

    isLoading.value = true;

    try {
      final ids =
      await _favoritesService.getFavorites(authController.token.value);
      favoriteIds.assignAll(ids);

      final allProducts = await ApiService.fetchAllProducts();
      favoriteProducts.assignAll(
        allProducts.where((product) => ids.contains(product.id)).toList(),
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> toggleFavorite(Product product) async {
    if (!authController.isLoggedIn || authController.token.value.isEmpty) {
      Get.snackbar(
        'Требуется вход',
        'Авторизуйтесь, чтобы добавлять товары в избранное',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final bool wasFavorite = isFavorite(product.id);

    await _favoritesService.toggleFavorite(authController.token.value, product.id);
    await loadFavorites();

    Get.snackbar(
      wasFavorite ? 'Удалено' : 'Добавлено',
      wasFavorite
          ? '${product.name} удалён из избранного'
          : '${product.name} добавлен в избранное',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  Future<void> removeFavorite(Product product) async {
    if (!authController.isLoggedIn || authController.token.value.isEmpty) {
      return;
    }

    await _favoritesService.removeFavorite(
      authController.token.value,
      product.id,
    );
    await loadFavorites();
  }

  Future<void> clearFavorites() async {
    if (!authController.isLoggedIn || authController.token.value.isEmpty) {
      return;
    }

    await _favoritesService.clearFavorites(authController.token.value);
    await loadFavorites();
  }
}
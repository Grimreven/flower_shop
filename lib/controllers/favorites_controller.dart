import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/api_service.dart';
import '../models/product.dart';

class FavoritesController extends GetxController {
  static const String _favoritesKey = 'favorite_product_ids';

  final RxList<int> favoriteIds = <int>[].obs;
  final RxList<Product> favoriteProducts = <Product>[].obs;
  final RxBool isLoading = false.obs;

  bool isFavorite(int productId) => favoriteIds.contains(productId);

  @override
  void onInit() {
    super.onInit();
    loadFavorites();
  }

  Future<void> loadFavorites() async {
    isLoading.value = true;

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final List<String> storedIds =
          prefs.getStringList(_favoritesKey) ?? <String>[];

      final List<int> ids = storedIds
          .map(int.tryParse)
          .whereType<int>()
          .toList();

      favoriteIds.assignAll(ids);

      final List<Product> allProducts = await ApiService.fetchAllProducts();

      favoriteProducts.assignAll(
        allProducts.where((product) => ids.contains(product.id)).toList(),
      );
    } catch (e) {
      Get.snackbar(
        'Ошибка',
        'Не удалось загрузить избранное',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _saveFavoriteIds() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _favoritesKey,
      favoriteIds.map((id) => id.toString()).toList(),
    );
  }

  Future<void> toggleFavorite(Product product) async {
    final bool wasFavorite = isFavorite(product.id);

    try {
      if (wasFavorite) {
        favoriteIds.remove(product.id);
        favoriteProducts.removeWhere((item) => item.id == product.id);
      } else {
        favoriteIds.add(product.id);

        final bool alreadyExists =
        favoriteProducts.any((item) => item.id == product.id);

        if (!alreadyExists) {
          favoriteProducts.add(product);
        }
      }

      favoriteIds.refresh();
      favoriteProducts.refresh();

      await _saveFavoriteIds();

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
    try {
      favoriteIds.remove(product.id);
      favoriteProducts.removeWhere((item) => item.id == product.id);

      favoriteIds.refresh();
      favoriteProducts.refresh();

      await _saveFavoriteIds();

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
    try {
      favoriteIds.clear();
      favoriteProducts.clear();

      favoriteIds.refresh();
      favoriteProducts.refresh();

      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove(_favoritesKey);

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
}
import 'package:get/get.dart';
import '../models/product.dart';
import '../api/cart_service.dart';
import 'auth_controller.dart';

class CartItem {
  final Product product;
  RxInt quantity = 1.obs;
  CartItem(this.product, {int initial = 1}) {
    quantity.value = initial;
  }
}

class CartController extends GetxController {
  final AuthController authController;
  late final CartService cartService;

  var items = <CartItem>[].obs;
  var isLoading = false.obs;

  CartController({required this.authController}) {
    cartService = CartService(authController: authController);
  }

  @override
  void onInit() {
    super.onInit();
    // Подписываемся на изменения токена — если появился токен, подгружаем корзину,
    // если токен очистили — очищаем локальную корзину.
    ever(authController.token, (String? token) {
      if (token != null && token.isNotEmpty) {
        loadCartFromServer();
      } else {
        // при выходе очищаем локально (чтобы UI сразу обновился)
        items.clear();
      }
    });

    // Если controller создаётся уже после того как токен загружен — сразу подгружаем
    if (authController.isLoggedIn) {
      loadCartFromServer();
    }
  }

  Future<void> loadCartFromServer() async {
    if (!authController.isLoggedIn) return;
    try {
      isLoading.value = true;
      final cartItems = await cartService.fetchCart();
      items.assignAll(cartItems.map((ci) => CartItem(ci.product, initial: ci.quantity)).toList());
    } catch (e) {
      // Показываем подробную ошибку для дебага
      Get.snackbar('Ошибка', 'Не удалось загрузить корзину: $e', snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addToCart(Product product, {int qty = 1}) async {
    if (!authController.isLoggedIn) {
      Get.snackbar('Вход', 'Пожалуйста, войдите, чтобы добавить товар в корзину', snackPosition: SnackPosition.BOTTOM);
      return;
    }

    final index = items.indexWhere((i) => i.product.id == product.id);
    if (index != -1) {
      items[index].quantity.value += qty;
      try {
        await cartService.updateQuantity(product.id, items[index].quantity.value);
      } catch (e) {
        Get.snackbar('Ошибка', 'Не удалось обновить количество: $e');
      }
    } else {
      // оптимистичное добавление локально
      items.add(CartItem(product, initial: qty));
      try {
        await cartService.addToCart(product.id, qty);
        // при успехе можно перезагрузить корзину чтобы синхронизовать id элементов
        await loadCartFromServer();
      } catch (e) {
        Get.snackbar('Ошибка', 'Не удалось добавить товар: $e');
        // при ошибке откатываем локально
        items.removeWhere((i) => i.product.id == product.id);
      }
    }
  }

  Future<void> increment(Product product) async {
    if (!authController.isLoggedIn) {
      Get.snackbar('Вход', 'Пожалуйста, войдите', snackPosition: SnackPosition.BOTTOM);
      return;
    }
    final index = items.indexWhere((i) => i.product.id == product.id);
    if (index != -1) {
      items[index].quantity.value++;
      try {
        await cartService.updateQuantity(product.id, items[index].quantity.value);
      } catch (e) {
        Get.snackbar('Ошибка', 'Не удалось обновить количество: $e');
      }
    }
  }

  Future<void> decrement(Product product) async {
    if (!authController.isLoggedIn) {
      Get.snackbar('Вход', 'Пожалуйста, войдите', snackPosition: SnackPosition.BOTTOM);
      return;
    }
    final index = items.indexWhere((i) => i.product.id == product.id);
    if (index == -1) return;
    if (items[index].quantity.value > 1) {
      items[index].quantity.value--;
      try {
        await cartService.updateQuantity(product.id, items[index].quantity.value);
      } catch (e) {
        Get.snackbar('Ошибка', 'Не удалось обновить количество: $e');
      }
    } else {
      await removeByProduct(product);
    }
  }

  Future<void> removeByProduct(Product product) async {
    final existed = items.firstWhereOrNull((i) => i.product.id == product.id);
    items.removeWhere((i) => i.product.id == product.id);
    try {
      await cartService.removeItem(product.id);
    } catch (e) {
      Get.snackbar('Ошибка', 'Не удалось удалить товар: $e');
      // При ошибке можно вернуть элемент обратно (восстановление)
      if (existed != null) items.add(existed);
    }
  }

  Future<void> clearLocalOnly() async {
    items.clear();
  }

  Future<void> clear() async {
    items.clear();
    try {
      await cartService.clearCart();
    } catch (e) {
      Get.snackbar('Ошибка', 'Не удалось очистить корзину: $e');
    }
  }

  bool isInCart(Product product) => items.any((i) => i.product.id == product.id);

  int getQuantity(Product product) {
    final index = items.indexWhere((i) => i.product.id == product.id);
    return index != -1 ? items[index].quantity.value : 0;
  }

  double get totalPrice => items.fold(0.0, (sum, it) => sum + it.product.price * it.quantity.value);

  int get totalCount => items.fold(0, (s, it) => s + it.quantity.value);
}

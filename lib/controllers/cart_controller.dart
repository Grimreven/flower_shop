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

  CartController({required this.authController}) {
    cartService = CartService(authController: authController);
  }

  var items = <CartItem>[].obs;

  Future<void> loadCartFromServer() async {
    if (!authController.isLoggedIn) return;

    try {
      final cartItems = await cartService.fetchCart();
      items.clear();
      for (var ci in cartItems) {
        items.add(CartItem(ci.product, initial: ci.quantity));
      }
    } catch (e) {
      Get.snackbar('Ошибка', 'Не удалось загрузить корзину');
    }
  }

  Future<void> addToCart(Product product, {int qty = 1}) async {
    final index = items.indexWhere((i) => i.product.id == product.id);
    if (index != -1) {
      items[index].quantity.value += qty;
      await cartService.updateQuantity(product.id, items[index].quantity.value);
    } else {
      items.add(CartItem(product, initial: qty));
      await cartService.addToCart(product.id, qty);
    }
  }

  Future<void> increment(Product product) async {
    final index = items.indexWhere((i) => i.product.id == product.id);
    if (index != -1) {
      items[index].quantity.value++;
      await cartService.updateQuantity(product.id, items[index].quantity.value);
    }
  }

  Future<void> decrement(Product product) async {
    final index = items.indexWhere((i) => i.product.id == product.id);
    if (index == -1) return;

    if (items[index].quantity.value > 1) {
      items[index].quantity.value--;
      await cartService.updateQuantity(product.id, items[index].quantity.value);
    } else {
      await removeByProduct(product);
    }
  }

  Future<void> removeByProduct(Product product) async {
    items.removeWhere((i) => i.product.id == product.id);
    await cartService.removeItem(product.id);
  }

  Future<void> clear() async {
    items.clear();
    await cartService.clearCart();
  }

  bool isInCart(Product product) =>
      items.any((i) => i.product.id == product.id);

  int getQuantity(Product product) {
    final index = items.indexWhere((i) => i.product.id == product.id);
    return index != -1 ? items[index].quantity.value : 0;
  }

  double get totalPrice =>
      items.fold(0.0, (sum, it) => sum + it.product.price * it.quantity.value);

  int get totalCount => items.fold(0, (s, it) => s + it.quantity.value);
}

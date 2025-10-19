import 'package:get/get.dart';
import '../controllers/cart_controller.dart' as ctrl;
import '../controllers/auth_controller.dart';
import '../models/cart_item.dart' as model;
import '../models/order_model.dart';
import '../api/order_service.dart';

class OrderController extends GetxController {
  final AuthController authController;
  late OrderService _orderService;

  var orders = <OrderModel>[].obs;

  OrderController({required this.authController});

  @override
  void onInit() {
    super.onInit();

    // создаём сервис сразу при запуске
    _orderService = OrderService(token: authController.token.value);

    // подписываемся на изменение токена
    ever(authController.token, (String? newToken) {
      if (newToken != null && newToken.isNotEmpty) {
        _orderService = OrderService(token: newToken);
      }
    });
  }

  /// Создание заказа
  Future<void> createOrder(List<model.CartItem> items, {int bonusToUse = 0}) async {
    if (authController.token.isEmpty) {
      throw Exception('Нет токена! Пользователь не авторизован.');
    }

    try {
      final itemsMaps = items.map((e) => e.toJson()).toList();
      await _orderService.createOrder(itemsMaps: itemsMaps);

      final cartController = Get.find<ctrl.CartController>();
      await cartController.clear();

      await fetchUserOrders();
    } catch (e) {
      Get.snackbar('Ошибка', 'Не удалось оформить заказ: $e');
      rethrow;
    }
  }

  /// Получение заказов пользователя
  Future<void> fetchUserOrders() async {
    if (authController.token.isEmpty) return;

    try {
      final fetched = await _orderService.getUserOrders();
      orders.assignAll(fetched);
    } catch (e) {
      Get.snackbar('Ошибка', 'Не удалось загрузить заказы: $e');
    }
  }

  /// Подсчёт итога с учётом бонусов
  double calculateTotal(List<model.CartItem> items, {int bonusToUse = 0}) {
    final total = items.fold<double>(0.0, (sum, it) => sum + it.total);
    final res = total - bonusToUse;
    return res < 0 ? 0.0 : res;
  }
}

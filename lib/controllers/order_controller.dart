import 'package:get/get.dart';
import '../controllers/cart_controller.dart';
import '../controllers/auth_controller.dart';
import '../models/cart_item.dart' as model;
import '../models/order_model.dart';
import '../api/order_service.dart';

class OrderController extends GetxController {
  final AuthController authController;
  late final OrderService _orderService;

  var orders = <OrderModel>[].obs;

  OrderController({required this.authController}) {
    _orderService = OrderService(token: authController.token.value);
  }

  // Теперь метод принимает только список CartItem
  Future<void> createOrder(List<model.CartItem> items) async {
    if (authController.token.isEmpty) {
      throw Exception('Нет токена! Пользователь не авторизован.');
    }

    // Создаём заказ через OrderService
    await _orderService.createOrder(items: items);

    // Очищаем корзину
    final CartController cartController = Get.find<CartController>();
    await cartController.clear();

    // Обновляем список заказов
    await fetchUserOrders();
  }

  Future<void> fetchUserOrders() async {
    final data = await _orderService.getUserOrders();
    orders.assignAll(data.map((e) => OrderModel.fromJson(e)).toList());
  }
}

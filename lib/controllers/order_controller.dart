import 'package:get/get.dart';
import '../controllers/cart_controller.dart';
import '../controllers/auth_controller.dart';
import '../api/order_service.dart';
import '../models/cart_item.dart' as model;
import '../models/order_model.dart';

class OrderController extends GetxController {
  final AuthController authController;
  final OrderService _orderService = OrderService();

  var orders = <OrderModel>[].obs;

  OrderController({required this.authController});

  // Исправлено: принимаем List<CartItem> из модели
  Future<void> createOrder(List<model.CartItem> items) async {
    final userId = authController.user.value!.id;
    final total = items.fold(0.0, (sum, item) => sum + item.product.price * item.quantity);

    await _orderService.createOrder(userId: userId, total: total, items: items);

    // Очистка корзины
    final CartController cartController = Get.find<CartController>();
    await cartController.clear();

    // Обновляем список заказов
    await fetchUserOrders();
  }

  Future<void> fetchUserOrders() async {
    final userId = authController.user.value!.id;
    final data = await _orderService.getUserOrders(userId);
    orders.assignAll(data.map((e) => OrderModel.fromJson(e)).toList());
  }
}

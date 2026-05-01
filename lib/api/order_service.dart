import '../api/local_demo_service.dart';
import '../api/server_api_service.dart';
import '../config/app_config.dart';
import '../models/order_model.dart';

class OrderService {
  final String token;
  final LocalDemoService _localDemoService = LocalDemoService.instance;

  OrderService({
    required this.token,
  });

  Future<OrderModel> createOrder({
    required List<Map<String, dynamic>> itemsMaps,
    required Map<String, dynamic> checkoutData,
  }) async {
    final Map<String, dynamic> rawOrder = AppConfig.useBackend
        ? await ServerApiService.createOrder(
      itemsMaps: itemsMaps,
      checkoutData: checkoutData,
    )
        : await _localDemoService.createOrder(
      token,
      itemsMaps,
      checkoutData,
    );

    return OrderModel.fromJson(rawOrder);
  }

  Future<List<OrderModel>> getUserOrders() async {
    final List<Map<String, dynamic>> rawOrders = AppConfig.useBackend
        ? await ServerApiService.getOrders()
        : await _localDemoService.getOrdersRaw(token);

    return rawOrders.map(OrderModel.fromJson).toList();
  }

  Future<void> updateOrderStatus(
      int orderId,
      String status,
      ) async {
    if (AppConfig.useBackend) {
      await ServerApiService.updateOrderStatus(orderId, status);
      return;
    }

    await _localDemoService.updateOrderStatus(
      token,
      orderId,
      status,
    );
  }
}
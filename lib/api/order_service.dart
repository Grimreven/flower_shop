import '../config/app_config.dart';
import '../api/local_demo_service.dart';
import '../api/server_api_service.dart';
import '../models/order_model.dart';

class OrderService {
  final String token;
  final LocalDemoService _localDemoService = LocalDemoService.instance;

  OrderService({
    required this.token,
  });

  Future<Map<String, dynamic>> createOrder({
    required List<Map<String, dynamic>> itemsMaps,
    required Map<String, dynamic> checkoutData,
  }) async {
    if (AppConfig.useBackend) {
      return ServerApiService.createOrder(
        itemsMaps: itemsMaps,
        checkoutData: checkoutData,
      );
    }

    return _localDemoService.createOrder(
      token,
      itemsMaps,
      checkoutData,
    );
  }

  Future<List<OrderModel>> getUserOrders() async {
    final List<Map<String, dynamic>> rawOrders = AppConfig.useBackend
        ? await ServerApiService.getOrders()
        : await _localDemoService.getOrdersRaw(token);

    return rawOrders.map((Map<String, dynamic> e) {
      return OrderModel.fromJson(e);
    }).toList();
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
import '../api/local_demo_service.dart';
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
    return _localDemoService.createOrder(
      token,
      itemsMaps,
      checkoutData,
    );
  }

  Future<List<OrderModel>> getUserOrders() async {
    final List<Map<String, dynamic>> rawOrders =
    await _localDemoService.getOrdersRaw(token);

    return rawOrders.map((e) => OrderModel.fromJson(e)).toList();
  }
}
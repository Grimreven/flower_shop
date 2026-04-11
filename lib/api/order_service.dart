import '../models/order_model.dart';
import '../api/local_demo_service.dart';

class OrderService {
  final String token;
  final LocalDemoService _localDemoService = LocalDemoService.instance;

  OrderService({
    required this.token,
  });

  Future<void> createOrder({
    required List<Map<String, dynamic>> itemsMaps,
  }) async {
    await _localDemoService.createOrder(token, itemsMaps);
  }

  Future<List<OrderModel>> getUserOrders() async {
    final List<Map<String, dynamic>> rawOrders =
    await _localDemoService.getOrdersRaw(token);

    return rawOrders.map((e) => OrderModel.fromJson(e)).toList();
  }
}
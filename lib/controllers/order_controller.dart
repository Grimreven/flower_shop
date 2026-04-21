import 'dart:async';

import 'package:get/get.dart';

import '../api/notification_service.dart';
import '../api/order_service.dart';
import '../controllers/auth_controller.dart';
import '../controllers/cart_controller.dart' as ctrl;
import '../controllers/settings_controller.dart';
import '../helpers/order_tracking_helper.dart';
import '../models/cart_item.dart' as model;
import '../models/checkout_summary.dart';
import '../models/order_model.dart';

class OrderController extends GetxController {
  final AuthController authController;
  late OrderService _orderService;

  final RxList<OrderModel> orders = <OrderModel>[].obs;
  final RxMap<int, int> trackingStepByOrderId = <int, int>{}.obs;
  final RxMap<int, DateTime> trackingEtaByOrderId = <int, DateTime>{}.obs;
  final Rxn<OrderModel> lastCreatedOrder = Rxn<OrderModel>();
  final Map<int, Timer> _trackingTimers = <int, Timer>{};

  OrderController({
    required this.authController,
  });

  SettingsController get _settingsController => Get.find<SettingsController>();

  @override
  void onInit() {
    super.onInit();
    _orderService = OrderService(token: authController.token.value);

    ever<String?>(authController.token, (String? newToken) {
      if (newToken != null && newToken.isNotEmpty) {
        _orderService = OrderService(token: newToken);
      }
    });
  }

  Future<void> createOrder(
      List<model.CartItem> items, {
        required CheckoutSummary summary,
        required String paymentMethod,
        required String paymentStatus,
        required String cardMask,
        required String deliveryAddress,
        required String recipientComment,
        String promoCode = '',
      }) async {
    if (authController.token.isEmpty) {
      throw Exception('Нет токена! Пользователь не авторизован.');
    }

    try {
      final List<Map<String, dynamic>> itemsMaps =
      items.map((e) => e.toJson()).toList();

      await _orderService.createOrder(
        itemsMaps: itemsMaps,
        checkoutData: {
          ...summary.toJson(),
          'payment_method': paymentMethod,
          'payment_status': paymentStatus,
          'card_mask': cardMask,
          'delivery_address': deliveryAddress,
          'recipient_comment': recipientComment,
          'promo_code': promoCode,
        },
      );

      final ctrl.CartController cartController = Get.find<ctrl.CartController>();
      await cartController.clearLocalOnly();
      await authController.getProfile();
      await fetchUserOrders();

      if (orders.isNotEmpty) {
        lastCreatedOrder.value = orders.first;
        initializeTrackingForOrder(orders.first);
      }
    } catch (e) {
      Get.snackbar('Ошибка', 'Не удалось оформить заказ: $e');
      rethrow;
    }
  }

  Future<void> fetchUserOrders() async {
    if (authController.token.isEmpty) {
      return;
    }

    try {
      final List<OrderModel> fetched = await _orderService.getUserOrders();
      orders.assignAll(fetched);

      for (final OrderModel order in fetched) {
        _ensureTrackingInitialized(order);
      }
    } catch (e) {
      Get.snackbar('Ошибка', 'Не удалось загрузить заказы: $e');
    }
  }

  OrderModel? findOrderById(int orderId) {
    try {
      return orders.firstWhere((order) => order.id == orderId);
    } catch (_) {
      return null;
    }
  }

  OrderModel? getLatestOrder() {
    if (lastCreatedOrder.value != null) {
      return lastCreatedOrder.value;
    }

    if (orders.isNotEmpty) {
      return orders.first;
    }

    return null;
  }

  void initializeTrackingForOrder(OrderModel order) {
    _ensureTrackingInitialized(order);
    _startTrackingIfNeeded(order);
  }

  void _ensureTrackingInitialized(OrderModel order) {
    if (trackingStepByOrderId.containsKey(order.id) &&
        trackingEtaByOrderId.containsKey(order.id)) {
      return;
    }

    final OrderTrackingStage initialStage =
    OrderTrackingHelper.resolveInitialStage(order.status);
    final int initialIndex = OrderTrackingHelper.stageToIndex(initialStage);

    trackingStepByOrderId[order.id] = initialIndex;
    trackingEtaByOrderId[order.id] = _buildEstimatedDeliveryTime(initialStage);
  }

  void _startTrackingIfNeeded(OrderModel order) {
    final int currentIndex = trackingStepByOrderId[order.id] ?? 0;

    if (currentIndex >= OrderTrackingHelper.steps.length - 1) {
      _trackingTimers[order.id]?.cancel();
      _trackingTimers.remove(order.id);
      return;
    }

    if (_trackingTimers.containsKey(order.id)) {
      return;
    }

    _trackingTimers[order.id] =
        Timer.periodic(const Duration(seconds: 4), (Timer timer) async {
          final int index = trackingStepByOrderId[order.id] ?? 0;

          if (index < OrderTrackingHelper.steps.length - 1) {
            final int nextIndex = index + 1;
            trackingStepByOrderId[order.id] = nextIndex;

            if (nextIndex == 1) {
              trackingEtaByOrderId[order.id] =
                  DateTime.now().add(const Duration(minutes: 30));
            } else if (nextIndex == 2) {
              trackingEtaByOrderId[order.id] =
                  DateTime.now().add(const Duration(minutes: 15));
            } else if (nextIndex == 3) {
              trackingEtaByOrderId[order.id] = DateTime.now();
              timer.cancel();
              _trackingTimers.remove(order.id);
            }

            trackingStepByOrderId.refresh();
            trackingEtaByOrderId.refresh();
            await _notifyAboutStatusChange(order.id, nextIndex);
          } else {
            timer.cancel();
            _trackingTimers.remove(order.id);
          }
        });
  }

  Future<void> _notifyAboutStatusChange(int orderId, int stepIndex) async {
    final bool notificationsEnabled =
        _settingsController.orderNotifications.value ||
            _settingsController.promoNotifications.value ||
            _settingsController.loyaltyNotifications.value;

    if (!notificationsEnabled) {
      return;
    }

    final String title = 'Статус заказа #$orderId обновлён';
    final String body = OrderTrackingHelper.messageByIndex(stepIndex);

    await NotificationService.instance.showOrderStatusNotification(
      orderId: orderId,
      title: title,
      body: body,
    );
  }

  DateTime _buildEstimatedDeliveryTime(OrderTrackingStage stage) {
    switch (stage) {
      case OrderTrackingStage.accepted:
        return DateTime.now().add(const Duration(minutes: 45));
      case OrderTrackingStage.preparing:
        return DateTime.now().add(const Duration(minutes: 30));
      case OrderTrackingStage.courier:
        return DateTime.now().add(const Duration(minutes: 15));
      case OrderTrackingStage.delivered:
        return DateTime.now();
    }
  }

  int getTrackingStepIndex(int orderId) {
    return trackingStepByOrderId[orderId] ?? 0;
  }

  String getTrackingStatusTitle(int orderId) {
    final int index = getTrackingStepIndex(orderId);
    return OrderTrackingHelper.titleByIndex(index);
  }

  String getTrackingStatusMessage(int orderId) {
    final int index = getTrackingStepIndex(orderId);
    return OrderTrackingHelper.messageByIndex(index);
  }

  DateTime? getTrackingEta(int orderId) {
    return trackingEtaByOrderId[orderId];
  }

  String getTrackingEtaText(int orderId) {
    final DateTime? eta = getTrackingEta(orderId);
    if (eta == null) {
      return '--:--';
    }

    final String hour = eta.hour.toString().padLeft(2, '0');
    final String minute = eta.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  bool isOrderDelivered(int orderId) {
    final int index = getTrackingStepIndex(orderId);
    return index >= OrderTrackingHelper.steps.length - 1;
  }

  @override
  void onClose() {
    for (final Timer timer in _trackingTimers.values) {
      timer.cancel();
    }
    _trackingTimers.clear();
    super.onClose();
  }
}
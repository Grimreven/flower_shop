import 'package:get/get.dart';

import '../api/auth_storage.dart';
import '../api/local_demo_service.dart';
import '../config/app_config.dart';
import 'address_book_controller.dart';
import 'auth_controller.dart';
import 'cart_controller.dart';
import 'favorites_controller.dart';
import 'order_controller.dart';
import 'payment_controller.dart';

class AppModeController extends GetxController {
  final Rx<AppRunMode> mode = AppConfig.mode.obs;
  final RxBool isSwitching = false.obs;

  bool get isDemoMode => mode.value == AppRunMode.demo;

  bool get isServerMode => mode.value == AppRunMode.server;

  String get title => AppConfig.modeLabel;

  Future<void> setMode(AppRunMode newMode) async {
    if (mode.value == newMode) {
      return;
    }

    try {
      isSwitching.value = true;

      await AppConfig.setMode(newMode);
      mode.value = newMode;

      await AuthStorage.clear();

      if (newMode == AppRunMode.demo) {
        await LocalDemoService.instance.ensureSeeded();
      }

      await _clearRuntimeState();

      Get.snackbar(
        'Режим изменён',
        newMode == AppRunMode.demo
            ? 'Приложение работает локально без базы данных'
            : 'Приложение работает через сервер и PostgreSQL',
        snackPosition: SnackPosition.BOTTOM,
      );

      Get.offAllNamed('/splash');
    } catch (e) {
      Get.snackbar(
        'Ошибка',
        'Не удалось переключить режим: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isSwitching.value = false;
    }
  }

  Future<void> _clearRuntimeState() async {
    try {
      final AuthController authController = Get.find<AuthController>();
      authController.token.value = '';
      authController.user.value = null;
    } catch (_) {}

    try {
      final CartController cartController = Get.find<CartController>();
      await cartController.clearLocalOnly();
    } catch (_) {}

    try {
      final FavoritesController favoritesController =
      Get.find<FavoritesController>();
      favoritesController.clearLocalState();
    } catch (_) {}

    try {
      final OrderController orderController = Get.find<OrderController>();
      orderController.orders.clear();
      orderController.trackingStepByOrderId.clear();
      orderController.trackingEtaByOrderId.clear();
      orderController.lastCreatedOrder.value = null;
    } catch (_) {}

    try {
      final PaymentController paymentController =
      Get.find<PaymentController>();
      paymentController.clear();
    } catch (_) {}

    try {
      final AddressBookController addressBookController =
      Get.find<AddressBookController>();
      addressBookController.clear();
    } catch (_) {}
  }
}
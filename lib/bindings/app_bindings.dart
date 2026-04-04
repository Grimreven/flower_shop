import 'package:get/get.dart';

import '../controllers/auth_controller.dart';
import '../controllers/cart_controller.dart';
import '../controllers/order_controller.dart';
import '../controllers/settings_controller.dart';

class AppBindings extends Bindings {
  @override
  void dependencies() {
    final AuthController authController = Get.put<AuthController>(
      AuthController(),
      permanent: true,
    );

    Get.put<SettingsController>(
      SettingsController(),
      permanent: true,
    );

    Get.put<CartController>(
      CartController(authController: authController),
      permanent: true,
    );

    Get.put<OrderController>(
      OrderController(authController: authController),
      permanent: true,
    );
  }
}
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../controllers/cart_controller.dart';
import '../controllers/favorites_controller.dart';
import '../controllers/order_controller.dart';
import '../controllers/settings_controller.dart';

class AppBindings extends Bindings {
  @override
  void dependencies() {
    final AuthController authController = Get.put(
      AuthController(),
      permanent: true,
    );

    Get.put(
      SettingsController(),
      permanent: true,
    );

    Get.put(
      FavoritesController(),
      permanent: true,
    );

    Get.put(
      CartController(authController: authController),
      permanent: true,
    );

    Get.put(
      OrderController(authController: authController),
      permanent: true,
    );
  }
}
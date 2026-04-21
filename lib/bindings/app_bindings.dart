import 'package:get/get.dart';

import '../controllers/address_book_controller.dart';
import '../controllers/auth_controller.dart';
import '../controllers/cart_controller.dart';
import '../controllers/favorites_controller.dart';
import '../controllers/order_controller.dart';
import '../controllers/payment_controller.dart';
import '../controllers/settings_controller.dart';

class AppBindings extends Bindings {
  @override
  void dependencies() {
    Get.put<SettingsController>(
      SettingsController(),
      permanent: true,
    );

    Get.put<AuthController>(
      AuthController(),
      permanent: true,
    );

    final AuthController authController = Get.find<AuthController>();

    Get.put<CartController>(
      CartController(authController: authController),
      permanent: true,
    );

    Get.put<FavoritesController>(
      FavoritesController(),
      permanent: true,
    );

    Get.put<OrderController>(
      OrderController(authController: authController),
      permanent: true,
    );

    Get.put<PaymentController>(
      PaymentController(authController: authController),
      permanent: true,
    );

    Get.put<AddressBookController>(
      AddressBookController(),
      permanent: true,
    );
  }
}
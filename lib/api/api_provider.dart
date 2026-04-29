import '../config/app_config.dart';
import 'local_demo_service.dart';
import 'server_api_service.dart';

class ApiProvider {
  static final _local = LocalDemoService.instance;

  static Future<List<dynamic>> getProducts() {
    if (AppConfig.useBackend) {
      return ServerApiService.getProducts();
    }

    return _local.getProducts();
  }

  static Future<List<dynamic>> getPopularProducts() {
    if (AppConfig.useBackend) {
      return ServerApiService.getPopularProducts();
    }

    return _local.getPopularProducts();
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) {
    if (AppConfig.useBackend) {
      return ServerApiService.login(
        email: email,
        password: password,
      );
    }

    return Future.value({
      'user': {
        'id': 1,
        'name': 'Демо пользователь',
        'email': email,
      },
      'token': 'demo_token',
    });
  }

  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
  }) {
    if (AppConfig.useBackend) {
      return ServerApiService.register(
        name: name,
        email: email,
        password: password,
      );
    }

    return Future.value({
      'user': {
        'id': 1,
        'name': name,
        'email': email,
      },
      'token': 'demo_token',
    });
  }

  static Future<Map<String, dynamic>> getProfile() {
    if (AppConfig.useBackend) {
      return ServerApiService.getProfile();
    }

    return Future.value({
      'id': 1,
      'name': 'Демо пользователь',
      'email': 'demo@mail.ru',
      'phone': '+7 999 999-99-99',
      'address': 'Демо адрес',
      'loyalty_points': 120,
      'total_spent': 3500,
      'loyalty_level': 'Bronze',
      'loyalty_color': '#CD7F32',
    });
  }

  static Future<void> logout() {
    if (AppConfig.useBackend) {
      return ServerApiService.logout();
    }

    return Future.value();
  }
}
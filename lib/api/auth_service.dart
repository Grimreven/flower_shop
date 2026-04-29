import '../config/app_config.dart';
import '../models/user.dart';
import 'local_demo_service.dart';
import 'server_api_service.dart';

class AuthService {
  final LocalDemoService _localDemoService = LocalDemoService.instance;

  Future<Map<String, dynamic>?> login(String email, String password) async {
    if (AppConfig.useBackend) {
      return ServerApiService.login(
        email: email,
        password: password,
      );
    }

    return _localDemoService.login(email, password);
  }

  Future<Map<String, dynamic>?> register(
      String name,
      String email,
      String password,
      ) async {
    if (AppConfig.useBackend) {
      return ServerApiService.register(
        name: name,
        email: email,
        password: password,
      );
    }

    return _localDemoService.register(name, email, password);
  }

  Future<Map<String, dynamic>?> getProfile(String token) async {
    if (AppConfig.useBackend) {
      return ServerApiService.getProfile();
    }

    return _localDemoService.getProfile(token);
  }

  Future<Map<String, dynamic>?> updateProfile(String token, User user) async {
    if (AppConfig.useBackend) {
      return _localDemoService.updateProfile(token, user.toJson());
    }

    return _localDemoService.updateProfile(token, user.toJson());
  }
}
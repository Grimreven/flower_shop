import '../models/user.dart';
import 'local_demo_service.dart';

class AuthService {
  final LocalDemoService _localDemoService = LocalDemoService.instance;

  Future<Map<String, dynamic>?> login(String email, String password) async {
    return _localDemoService.login(email, password);
  }

  Future<Map<String, dynamic>?> register(
      String name,
      String email,
      String password,
      ) async {
    return _localDemoService.register(name, email, password);
  }

  Future<Map<String, dynamic>?> getProfile(String token) async {
    return _localDemoService.getProfile(token);
  }

  Future<Map<String, dynamic>?> updateProfile(String token, User user) async {
    return _localDemoService.updateProfile(token, user.toJson());
  }
}
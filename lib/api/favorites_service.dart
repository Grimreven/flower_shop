import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';
import 'server_api_service.dart';

class FavoritesService {
  FavoritesService._();

  static final FavoritesService instance = FavoritesService._();

  static const String _favoritesPrefix = 'demo_favorites_user_';

  int? _readUserIdFromToken(String token) {
    if (token.isEmpty) return null;

    final List<String> parts = token.split('_');

    if (parts.length < 3) return null;

    return int.tryParse(parts[1]);
  }

  Future<List<int>> getFavorites(String token) async {
    if (AppConfig.useBackend) {
      return ServerApiService.getFavorites();
    }

    final int? userId = _readUserIdFromToken(token);

    if (userId == null) return <int>[];

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String> ids =
        prefs.getStringList('$_favoritesPrefix$userId') ?? <String>[];

    return ids
        .map((String e) => int.tryParse(e) ?? 0)
        .where((int e) => e > 0)
        .toList();
  }

  Future<void> toggleFavorite(String token, int productId) async {
    if (AppConfig.useBackend) {
      final List<int> current = await ServerApiService.getFavorites();

      if (current.contains(productId)) {
        await ServerApiService.removeFavorite(productId);
      } else {
        await ServerApiService.addFavorite(productId);
      }

      return;
    }

    final int? userId = _readUserIdFromToken(token);

    if (userId == null) return;

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String key = '$_favoritesPrefix$userId';
    final List<String> current =
    (prefs.getStringList(key) ?? <String>[]).toList();

    final String id = productId.toString();

    if (current.contains(id)) {
      current.remove(id);
    } else {
      current.add(id);
    }

    await prefs.setStringList(key, current);
  }

  Future<void> removeFavorite(String token, int productId) async {
    if (AppConfig.useBackend) {
      await ServerApiService.removeFavorite(productId);
      return;
    }

    final int? userId = _readUserIdFromToken(token);

    if (userId == null) return;

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String key = '$_favoritesPrefix$userId';
    final List<String> current =
    (prefs.getStringList(key) ?? <String>[]).toList();

    current.remove(productId.toString());

    await prefs.setStringList(key, current);
  }

  Future<void> clearFavorites(String token) async {
    if (AppConfig.useBackend) {
      await ServerApiService.clearFavorites();
      return;
    }

    final int? userId = _readUserIdFromToken(token);

    if (userId == null) return;

    final SharedPreferences prefs = await SharedPreferences.getInstance();

    await prefs.remove('$_favoritesPrefix$userId');
  }
}
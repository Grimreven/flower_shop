import 'package:shared_preferences/shared_preferences.dart';

class FavoritesService {
  FavoritesService._();

  static final FavoritesService instance = FavoritesService._();

  static const String _favoritesPrefix = 'demo_favorites_user_';

  int? _readUserIdFromToken(String token) {
    if (token.isEmpty) return null;

    final parts = token.split('_');
    if (parts.length < 3) return null;

    return int.tryParse(parts[1]);
  }

  Future<List<int>> getFavorites(String token) async {
    final int? userId = _readUserIdFromToken(token);
    if (userId == null) return <int>[];

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String> ids =
        prefs.getStringList('$_favoritesPrefix$userId') ?? <String>[];

    return ids.map((e) => int.tryParse(e) ?? 0).where((e) => e > 0).toList();
  }

  Future<void> toggleFavorite(String token, int productId) async {
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
    final int? userId = _readUserIdFromToken(token);
    if (userId == null) return;

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_favoritesPrefix$userId');
  }
}
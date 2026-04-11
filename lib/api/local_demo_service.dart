import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class LocalDemoService {
  LocalDemoService._();

  static final LocalDemoService instance = LocalDemoService._();

  static const String _usersKey = 'demo_users_v1';
  static const String _productsKey = 'demo_products_v1';
  static const String _ordersPrefix = 'demo_orders_user_';
  static const String _cartPrefix = 'demo_cart_user_';
  static const String _seededKey = 'demo_seeded_v1';
  static const String _tokenKey = 'token';

  Future<void> ensureSeeded() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final bool seeded = prefs.getBool(_seededKey) ?? false;

    if (seeded) {
      return;
    }

    await _seedInitialData();
  }

  Future<void> resetDemoData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    final List<Map<String, dynamic>> users = await _getUsersSafe();
    for (final Map<String, dynamic> user in users) {
      final int userId = (user['id'] as num).toInt();
      await prefs.remove('$_ordersPrefix$userId');
      await prefs.remove('$_cartPrefix$userId');
    }

    await prefs.remove(_usersKey);
    await prefs.remove(_productsKey);
    await prefs.remove(_seededKey);
    await prefs.remove(_tokenKey);

    await _seedInitialData();
  }

  Future<void> _seedInitialData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    final List<Map<String, dynamic>> users = [
      {
        'id': 1,
        'name': 'Демо Пользователь',
        'email': 'demo@flowershop.ru',
        'password': '123456',
        'phone': '+7 (999) 123-45-67',
        'address': 'г. Астана, ул. Цветочная, 12',
        'loyalty_points': 1200,
        'total_spent': 1200.0,
        'loyalty_level': 'Bronze',
        'loyalty_color': '#CD7F32',
      },
    ];

    final List<Map<String, dynamic>> products = _demoProducts();

    await prefs.setString(_usersKey, jsonEncode(users));
    await prefs.setString(_productsKey, jsonEncode(products));
    await prefs.setBool(_seededKey, true);
  }

  Future<Map<String, dynamic>?> login(
      String email,
      String password,
      ) async {
    await ensureSeeded();

    final List<Map<String, dynamic>> users = await _getUsers();

    try {
      final Map<String, dynamic> user = users.firstWhere(
            (u) =>
        u['email'].toString().trim().toLowerCase() ==
            email.trim().toLowerCase() &&
            u['password'].toString() == password,
      );

      final String token = _makeToken(user['id'] as int);

      return {
        'user': _publicUser(user),
        'token': token,
      };
    } catch (_) {
      final bool userExists = users.any(
            (u) =>
        u['email'].toString().trim().toLowerCase() ==
            email.trim().toLowerCase(),
      );

      if (!userExists) {
        return {'message': 'Пользователь не найден'};
      }

      return {'message': 'Неверный пароль'};
    }
  }

  Future<Map<String, dynamic>?> register(
      String name,
      String email,
      String password,
      ) async {
    await ensureSeeded();

    final List<Map<String, dynamic>> users = await _getUsers();

    final bool exists = users.any(
          (u) =>
      u['email'].toString().trim().toLowerCase() ==
          email.trim().toLowerCase(),
    );

    if (exists) {
      return {'message': 'Пользователь с таким email уже существует'};
    }

    final int newId = users.isEmpty
        ? 1
        : users
        .map((u) => (u['id'] as num).toInt())
        .reduce((a, b) => a > b ? a : b) +
        1;

    final Map<String, dynamic> newUser = {
      'id': newId,
      'name': name.trim(),
      'email': email.trim(),
      'password': password,
      'phone': '',
      'address': '',
      'loyalty_points': 0,
      'total_spent': 0.0,
      'loyalty_level': 'Bronze',
      'loyalty_color': '#CD7F32',
    };

    users.add(newUser);
    await _saveUsers(users);

    return {
      'user': _publicUser(newUser),
      'token': _makeToken(newId),
    };
  }

  Future<Map<String, dynamic>?> getProfile(String token) async {
    await ensureSeeded();

    final int? userId = _readUserIdFromToken(token);
    if (userId == null) {
      return {
        'authError': true,
        'message': 'Сессия истекла. Войдите снова.',
      };
    }

    final List<Map<String, dynamic>> users = await _getUsers();

    try {
      final Map<String, dynamic> user =
      users.firstWhere((u) => (u['id'] as num).toInt() == userId);

      return _publicUser(user);
    } catch (_) {
      return {
        'authError': true,
        'message': 'Пользователь не найден',
      };
    }
  }

  Future<Map<String, dynamic>?> updateProfile(
      String token,
      Map<String, dynamic> updatedUser,
      ) async {
    await ensureSeeded();

    final int? userId = _readUserIdFromToken(token);
    if (userId == null) {
      return {
        'authError': true,
        'message': 'Сессия истекла. Войдите снова.',
      };
    }

    final List<Map<String, dynamic>> users = await _getUsers();
    final int index = users.indexWhere(
          (u) => (u['id'] as num).toInt() == userId,
    );

    if (index == -1) {
      return {
        'authError': true,
        'message': 'Пользователь не найден',
      };
    }

    final Map<String, dynamic> oldUser = users[index];

    users[index] = {
      ...oldUser,
      'name': updatedUser['name'] ?? oldUser['name'],
      'email': updatedUser['email'] ?? oldUser['email'],
      'phone': updatedUser['phone'] ?? oldUser['phone'],
      'address': updatedUser['address'] ?? oldUser['address'],
    };

    await _saveUsers(users);

    return _publicUser(users[index]);
  }

  Future<List<Map<String, dynamic>>> getProducts() async {
    await ensureSeeded();
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String raw = prefs.getString(_productsKey) ?? '[]';
    return _decodeList(raw);
  }

  Future<List<Map<String, dynamic>>> getPopularProducts() async {
    final List<Map<String, dynamic>> products = await getProducts();
    final List<Map<String, dynamic>> sorted = [...products];

    sorted.sort((a, b) {
      final double ratingA = _numToDouble(a['rating']);
      final double ratingB = _numToDouble(b['rating']);
      return ratingB.compareTo(ratingA);
    });

    return sorted.take(6).toList();
  }

  Future<List<Map<String, dynamic>>> getCart(String token) async {
    await ensureSeeded();

    final int? userId = _readUserIdFromToken(token);
    if (userId == null) {
      return [];
    }

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String raw = prefs.getString('$_cartPrefix$userId') ?? '[]';

    return _decodeList(raw);
  }

  Future<void> addToCart(
      String token,
      int productId,
      int quantity,
      ) async {
    await ensureSeeded();

    final int? userId = _readUserIdFromToken(token);
    if (userId == null) {
      return;
    }

    final List<Map<String, dynamic>> cart = await getCart(token);
    final List<Map<String, dynamic>> products = await getProducts();

    Map<String, dynamic>? product;
    for (final Map<String, dynamic> p in products) {
      if ((p['id'] as num).toInt() == productId) {
        product = p;
        break;
      }
    }

    if (product == null) {
      return;
    }

    final int index =
    cart.indexWhere((item) => (item['product_id'] as num).toInt() == productId);

    if (index >= 0) {
      final int currentQty = (cart[index]['quantity'] as num).toInt();
      cart[index]['quantity'] = currentQty + quantity;
    } else {
      cart.add({
        'id': DateTime.now().millisecondsSinceEpoch,
        'product_id': productId,
        'quantity': quantity,
        'name': product['name'],
        'price': product['price'],
        'image_url': product['image_url'],
        'description': product['description'],
        'category_id': product['category_id'],
        'category_name': product['category_name'],
        'rating': product['rating'],
        'in_stock': product['in_stock'],
      });
    }

    await _saveCart(userId, cart);
  }

  Future<void> updateCart(
      String token,
      int productId,
      int quantity,
      ) async {
    await ensureSeeded();

    final int? userId = _readUserIdFromToken(token);
    if (userId == null) {
      return;
    }

    final List<Map<String, dynamic>> cart = await getCart(token);
    final int index =
    cart.indexWhere((item) => (item['product_id'] as num).toInt() == productId);

    if (index >= 0) {
      cart[index]['quantity'] = quantity;
      await _saveCart(userId, cart);
    }
  }

  Future<void> removeFromCart(
      String token,
      int productId,
      ) async {
    await ensureSeeded();

    final int? userId = _readUserIdFromToken(token);
    if (userId == null) {
      return;
    }

    final List<Map<String, dynamic>> cart = await getCart(token);
    cart.removeWhere(
          (item) => (item['product_id'] as num).toInt() == productId,
    );
    await _saveCart(userId, cart);
  }

  Future<void> clearCart(String token) async {
    await ensureSeeded();

    final int? userId = _readUserIdFromToken(token);
    if (userId == null) {
      return;
    }

    await _saveCart(userId, []);
  }

  Future<Map<String, dynamic>> createOrder(
      String token,
      List<Map<String, dynamic>> itemsMaps,
      Map<String, dynamic> checkoutData,
      ) async {
    await ensureSeeded();

    final int? userId = _readUserIdFromToken(token);
    if (userId == null) {
      throw Exception('Нет пользователя');
    }

    final List<Map<String, dynamic>> products = await getProducts();
    final List<Map<String, dynamic>> orders = await getOrdersRaw(token);

    final int newOrderId = orders.isEmpty
        ? 1
        : orders
        .map((o) => (o['id'] as num).toInt())
        .reduce((a, b) => a > b ? a : b) +
        1;

    final List<Map<String, dynamic>> orderItems = [];
    double itemsTotal = 0;

    for (final Map<String, dynamic> item in itemsMaps) {
      final int productId = _readProductId(item);
      final int quantity = _readQuantity(item);

      Map<String, dynamic>? product;
      for (final Map<String, dynamic> p in products) {
        if ((p['id'] as num).toInt() == productId) {
          product = p;
          break;
        }
      }

      if (product == null) {
        continue;
      }

      final double price = _numToDouble(product['price']);
      itemsTotal += price * quantity;

      orderItems.add({
        'product_id': productId,
        'quantity': quantity,
        'price': price,
        'name': product['name'],
        'image_url': product['image_url'],
      });
    }

    final int bonusApplied =
        ((checkoutData['applied_bonuses'] ?? checkoutData['bonus_applied']) as num?)
            ?.toInt() ??
            0;

    final int bonusEarned =
        ((checkoutData['earned_bonuses'] ?? checkoutData['bonus_earned']) as num?)
            ?.toInt() ??
            0;

    final double deliveryCost = _numToDouble(checkoutData['delivery_cost']);
    final double payableTotal = _numToDouble(checkoutData['payable_total']);

    final String paymentMethod =
        checkoutData['payment_method']?.toString() ?? 'Наличный расчёт';

    final String deliveryMethod =
        checkoutData['delivery_method']?.toString() ?? 'delivery';

    final String deliveryAddress =
        checkoutData['delivery_address']?.toString() ?? '';

    final String recipientComment =
        checkoutData['recipient_comment']?.toString() ?? '';

    final String promoCode =
        checkoutData['promo_code']?.toString() ?? '';

    final Map<String, dynamic> newOrder = {
      'id': newOrderId,
      'user_id': userId,
      'total': payableTotal,
      'items_total': itemsTotal,
      'delivery_cost': deliveryCost,
      'bonus_applied': bonusApplied,
      'bonus_earned': bonusEarned,
      'payment_method': paymentMethod,
      'delivery_method': deliveryMethod,
      'delivery_address': deliveryAddress,
      'recipient_comment': recipientComment,
      'promo_code': promoCode,
      'status': 'Принят',
      'created_at': DateTime.now().toIso8601String(),
      'items': orderItems,
    };

    orders.insert(0, newOrder);
    await _saveOrders(userId, orders);
    await clearCart(token);

    await _updateLoyaltyAfterOrder(
      userId,
      payableTotal: payableTotal,
      bonusApplied: bonusApplied,
      bonusEarned: bonusEarned,
    );

    return newOrder;
  }

  Future<List<Map<String, dynamic>>> getOrdersRaw(String token) async {
    await ensureSeeded();

    final int? userId = _readUserIdFromToken(token);
    if (userId == null) {
      return [];
    }

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String raw = prefs.getString('$_ordersPrefix$userId') ?? '[]';
    return _decodeList(raw);
  }

  Future<void> _updateLoyaltyAfterOrder(
      int userId, {
        required double payableTotal,
        required int bonusApplied,
        required int bonusEarned,
      }) async {
    final List<Map<String, dynamic>> users = await _getUsers();
    final int index =
    users.indexWhere((u) => (u['id'] as num).toInt() == userId);

    if (index == -1) {
      return;
    }

    final double currentTotal = _numToDouble(users[index]['total_spent']);
    final int currentPoints =
    ((users[index]['loyalty_points'] ?? 0) as num).toInt();

    final double updatedTotal = currentTotal + payableTotal;
    final int updatedPoints =
    (currentPoints - bonusApplied + bonusEarned).clamp(0, 1 << 30);

    final Map<String, dynamic> loyalty = _resolveLoyalty(updatedTotal);

    users[index] = {
      ...users[index],
      'total_spent': updatedTotal,
      'loyalty_points': updatedPoints,
      'loyalty_level': loyalty['level'],
      'loyalty_color': loyalty['color'],
    };

    await _saveUsers(users);
  }

  Map<String, dynamic> _resolveLoyalty(double totalSpent) {
    if (totalSpent >= 15000) {
      return {
        'level': 'Gold',
        'color': '#E0B94A',
      };
    }

    if (totalSpent >= 5000) {
      return {
        'level': 'Silver',
        'color': '#AAB7C7',
      };
    }

    return {
      'level': 'Bronze',
      'color': '#CD7F32',
    };
  }

  Future<List<Map<String, dynamic>>> _getUsers() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String raw = prefs.getString(_usersKey) ?? '[]';
    return _decodeList(raw);
  }

  Future<List<Map<String, dynamic>>> _getUsersSafe() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String raw = prefs.getString(_usersKey) ?? '[]';
    try {
      return _decodeList(raw);
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveUsers(List<Map<String, dynamic>> users) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_usersKey, jsonEncode(users));
  }

  Future<void> _saveCart(
      int userId,
      List<Map<String, dynamic>> cart,
      ) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_cartPrefix$userId', jsonEncode(cart));
  }

  Future<void> _saveOrders(
      int userId,
      List<Map<String, dynamic>> orders,
      ) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_ordersPrefix$userId', jsonEncode(orders));
  }

  List<Map<String, dynamic>> _decodeList(String raw) {
    final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  Map<String, dynamic> _publicUser(Map<String, dynamic> user) {
    return {
      'id': user['id'],
      'name': user['name'],
      'email': user['email'],
      'phone': user['phone'] ?? '',
      'address': user['address'] ?? '',
      'loyalty_points': user['loyalty_points'] ?? 0,
      'total_spent': user['total_spent'] ?? 0,
      'loyalty_level': user['loyalty_level'] ?? 'Bronze',
      'loyalty_color': user['loyalty_color'] ?? '#CD7F32',
    };
  }

  String _makeToken(int userId) => 'demo-token-$userId';

  int? _readUserIdFromToken(String token) {
    if (!token.startsWith('demo-token-')) {
      return null;
    }

    return int.tryParse(token.replaceFirst('demo-token-', ''));
  }

  int _readProductId(Map<String, dynamic> item) {
    if (item['product_id'] != null) {
      return (item['product_id'] as num).toInt();
    }

    if (item['product'] is Map<String, dynamic>) {
      return ((item['product'] as Map<String, dynamic>)['id'] as num).toInt();
    }

    return 0;
  }

  int _readQuantity(Map<String, dynamic> item) {
    if (item['quantity'] != null) {
      return (item['quantity'] as num).toInt();
    }

    return 1;
  }

  double _numToDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString()) ?? 0;
  }

  List<Map<String, dynamic>> _demoProducts() {
    return [
      {
        'id': 1,
        'name': 'Нежные розы',
        'description': 'Классический букет из пастельных роз.',
        'price': 1800.0,
        'image_url':
        'https://images.unsplash.com/photo-1519378058457-4c29a0a2efac',
        'category_id': 1,
        'category_name': 'Розы',
        'rating': 4.9,
        'in_stock': true,
      },
      {
        'id': 2,
        'name': 'Пионы мечты',
        'description': 'Пышные пионы для особенного случая.',
        'price': 3200.0,
        'image_url':
        'https://images.unsplash.com/photo-1527061011665-3652c757a4d4',
        'category_id': 2,
        'category_name': 'Пионы',
        'rating': 4.8,
        'in_stock': true,
      },
      {
        'id': 3,
        'name': 'Яркий микс',
        'description': 'Сочный букет для праздника.',
        'price': 2700.0,
        'image_url':
        'https://images.unsplash.com/photo-1468327768560-75b778cbb551',
        'category_id': 3,
        'category_name': 'Микс',
        'rating': 4.7,
        'in_stock': true,
      },
      {
        'id': 4,
        'name': 'Минималистичный white',
        'description': 'Лаконичный букет в светлой палитре.',
        'price': 2400.0,
        'image_url':
        'https://images.unsplash.com/photo-1494336934272-f6d541ade6f2',
        'category_id': 4,
        'category_name': 'Минимализм',
        'rating': 4.6,
        'in_stock': true,
      },
      {
        'id': 5,
        'name': 'Романтика love',
        'description': 'Роскошный букет для романтического признания.',
        'price': 5100.0,
        'image_url':
        'https://images.unsplash.com/photo-1518895949257-7621c3c786d7',
        'category_id': 1,
        'category_name': 'Романтика',
        'rating': 5.0,
        'in_stock': true,
      },
      {
        'id': 6,
        'name': 'Гортензия pastel',
        'description': 'Мягкий и очень нежный букет.',
        'price': 2900.0,
        'image_url':
        'https://images.unsplash.com/photo-1525310072745-f49212b5ac6d',
        'category_id': 5,
        'category_name': 'Гортензии',
        'rating': 4.8,
        'in_stock': true,
      },
      {
        'id': 7,
        'name': 'Герберы fire',
        'description': 'Яркий букет для хорошего настроения.',
        'price': 2100.0,
        'image_url':
        'https://images.unsplash.com/photo-1561181286-d3fee7d55364',
        'category_id': 6,
        'category_name': 'Герберы',
        'rating': 4.5,
        'in_stock': true,
      },
      {
        'id': 8,
        'name': 'Эвкалипт mono',
        'description': 'Стильная композиция в минималистичном стиле.',
        'price': 2600.0,
        'image_url':
        'https://images.unsplash.com/photo-1512428813834-c702c7702b78',
        'category_id': 4,
        'category_name': 'Минимализм',
        'rating': 4.4,
        'in_stock': true,
      },
      {
        'id': 9,
        'name': 'Праздничный день рождения',
        'description': 'Праздничный букет для дня рождения.',
        'price': 3500.0,
        'image_url':
        'https://images.unsplash.com/photo-1508610048659-a06b669e3321',
        'category_id': 3,
        'category_name': 'Подарочные',
        'rating': 4.9,
        'in_stock': true,
      },
      {
        'id': 10,
        'name': 'Спасибо нежность',
        'description': 'Идеальный букет, чтобы сказать спасибо.',
        'price': 1900.0,
        'image_url':
        'https://images.unsplash.com/photo-1455659817273-f96807779a8a',
        'category_id': 7,
        'category_name': 'Универсальные',
        'rating': 4.7,
        'in_stock': true,
      },
    ];
  }
}
class BouquetRecommendationResult {
  final List<dynamic> products;
  final String title;
  final String subtitle;
  final String moodEmoji;

  const BouquetRecommendationResult({
    required this.products,
    required this.title,
    required this.subtitle,
    required this.moodEmoji,
  });
}

class BouquetRecommender {
  static BouquetRecommendationResult recommend({
    required List<dynamic> products,
    required String recipient,
    required String occasion,
    required String budget,
    required String style,
  }) {
    final List<dynamic> filtered = products.where((dynamic product) {
      final String name = _readName(product).toLowerCase();
      final String category = _readCategory(product).toLowerCase();
      final double price = _readPrice(product);

      if (!_matchesBudget(price, budget)) {
        return false;
      }

      int score = 0;

      if (_matchesRecipient(name, category, recipient)) {
        score += 2;
      }

      if (_matchesOccasion(name, category, occasion)) {
        score += 2;
      }

      if (_matchesStyle(name, category, style)) {
        score += 3;
      }

      if (score > 0) {
        return true;
      }

      if (style == 'Нежный' &&
          (name.contains('роз') ||
              name.contains('пион') ||
              name.contains('тюльпан') ||
              name.contains('гортенз'))) {
        return true;
      }

      if (style == 'Яркий' &&
          (name.contains('гербер') ||
              name.contains('микс') ||
              name.contains('ярк') ||
              name.contains('экзот'))) {
        return true;
      }

      if (style == 'Минимализм' &&
          (name.contains('моно') ||
              name.contains('эвкалипт') ||
              name.contains('white') ||
              name.contains('бел'))) {
        return true;
      }

      return false;
    }).toList();

    filtered.sort((dynamic a, dynamic b) {
      final int scoreB = _scoreProduct(
        product: b,
        recipient: recipient,
        occasion: occasion,
        style: style,
      );
      final int scoreA = _scoreProduct(
        product: a,
        recipient: recipient,
        occasion: occasion,
        style: style,
      );

      if (scoreA != scoreB) {
        return scoreB.compareTo(scoreA);
      }

      final double priceA = _readPrice(a);
      final double priceB = _readPrice(b);

      return priceA.compareTo(priceB);
    });

    final List<dynamic> result = filtered.isNotEmpty
        ? filtered.take(6).toList()
        : _fallbackByBudget(products, budget);

    return BouquetRecommendationResult(
      products: result,
      title: _buildTitle(recipient, occasion),
      subtitle: _buildSubtitle(style, budget),
      moodEmoji: _buildEmoji(occasion, style),
    );
  }

  static int _scoreProduct({
    required dynamic product,
    required String recipient,
    required String occasion,
    required String style,
  }) {
    final String name = _readName(product).toLowerCase();
    final String category = _readCategory(product).toLowerCase();

    int score = 0;

    if (_matchesRecipient(name, category, recipient)) {
      score += 2;
    }

    if (_matchesOccasion(name, category, occasion)) {
      score += 2;
    }

    if (_matchesStyle(name, category, style)) {
      score += 3;
    }

    return score;
  }

  static bool _matchesBudget(double price, String budget) {
    switch (budget) {
      case 'до 2000 ₽':
        return price <= 2000;
      case '2000–5000 ₽':
        return price >= 2000 && price <= 5000;
      case '5000+ ₽':
        return price >= 5000;
      default:
        return true;
    }
  }

  static bool _matchesRecipient(
      String name,
      String category,
      String recipient,
      ) {
    switch (recipient) {
      case 'Девушке':
        return name.contains('роз') ||
            name.contains('пион') ||
            name.contains('роман') ||
            category.contains('романт');
      case 'Маме':
        return name.contains('неж') ||
            name.contains('тюльпан') ||
            name.contains('лилия') ||
            name.contains('гортенз') ||
            category.contains('класс');
      case 'Коллеге':
        return name.contains('миним') ||
            name.contains('эвкалипт') ||
            name.contains('бел') ||
            category.contains('бизнес');
      default:
        return false;
    }
  }

  static bool _matchesOccasion(
      String name,
      String category,
      String occasion,
      ) {
    switch (occasion) {
      case 'День рождения':
        return name.contains('микс') ||
            name.contains('празд') ||
            name.contains('ярк') ||
            category.contains('подар');
      case 'Романтика':
        return name.contains('роз') ||
            name.contains('серд') ||
            name.contains('love') ||
            category.contains('романт');
      case 'Спасибо':
        return name.contains('неж') ||
            name.contains('свет') ||
            name.contains('крем') ||
            category.contains('универс');
      default:
        return false;
    }
  }

  static bool _matchesStyle(
      String name,
      String category,
      String style,
      ) {
    switch (style) {
      case 'Нежный':
        return name.contains('неж') ||
            name.contains('роз') ||
            name.contains('пион') ||
            name.contains('пастел') ||
            name.contains('крем');
      case 'Яркий':
        return name.contains('ярк') ||
            name.contains('микс') ||
            name.contains('гербер') ||
            name.contains('экзот') ||
            name.contains('сочн');
      case 'Минимализм':
        return name.contains('моно') ||
            name.contains('бел') ||
            name.contains('эвкалипт') ||
            name.contains('лакон') ||
            category.contains('миним');
      default:
        return false;
    }
  }

  static List<dynamic> _fallbackByBudget(List<dynamic> products, String budget) {
    final List<dynamic> sorted = [...products];

    sorted.sort((dynamic a, dynamic b) {
      return _readPrice(a).compareTo(_readPrice(b));
    });

    if (budget == 'до 2000 ₽') {
      return sorted.where((dynamic p) => _readPrice(p) <= 2000).take(6).toList();
    }

    if (budget == '2000–5000 ₽') {
      return sorted
          .where((dynamic p) => _readPrice(p) >= 2000 && _readPrice(p) <= 5000)
          .take(6)
          .toList();
    }

    return sorted.where((dynamic p) => _readPrice(p) >= 5000).take(6).toList();
  }

  static String _buildTitle(String recipient, String occasion) {
    return 'Идеальный букет для: $recipient';
  }

  static String _buildSubtitle(String style, String budget) {
    return '$style стиль • бюджет $budget';
  }

  static String _buildEmoji(String occasion, String style) {
    if (occasion == 'Романтика') {
      return '💖';
    }
    if (occasion == 'День рождения') {
      return '🎉';
    }
    if (style == 'Нежный') {
      return '🌸';
    }
    if (style == 'Яркий') {
      return '🔥';
    }
    return '✨';
  }

  static String _readName(dynamic product) {
    try {
      return (product.name ?? '').toString();
    } catch (_) {
      return '';
    }
  }

  static String _readCategory(dynamic product) {
    try {
      return (product.categoryName ?? '').toString();
    } catch (_) {
      return '';
    }
  }

  static double _readPrice(dynamic product) {
    try {
      final dynamic value = product.price;
      if (value is num) {
        return value.toDouble();
      }
      return double.tryParse(value.toString()) ?? 0;
    } catch (_) {
      return 0;
    }
  }
}
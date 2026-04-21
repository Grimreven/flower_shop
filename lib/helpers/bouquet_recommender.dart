import '../models/product.dart';

class BouquetRecommendationResult {
  final List<dynamic> products;
  final List<dynamic> alternativeProducts;
  final String title;
  final String subtitle;
  final String moodEmoji;
  final List<String> summaryChips;
  final String explanation;

  const BouquetRecommendationResult({
    required this.products,
    required this.alternativeProducts,
    required this.title,
    required this.subtitle,
    required this.moodEmoji,
    required this.summaryChips,
    required this.explanation,
  });
}

class BouquetRecommender {
  static BouquetRecommendationResult recommend({
    required List<dynamic> products,
    required String recipient,
    required String recipientAge,
    required String favoriteFlowers,
    required String occasion,
    required String budget,
    required String mood,
    required String palette,
    required String size,
  }) {
    final List<_ScoredProduct> scored = products
        .where((product) => _isAvailable(product))
        .map(
          (product) => _ScoredProduct(
        product: product,
        score: _calculateScore(
          product: product,
          recipient: recipient,
          recipientAge: recipientAge,
          favoriteFlowers: favoriteFlowers,
          occasion: occasion,
          budget: budget,
          mood: mood,
          palette: palette,
          size: size,
        ),
      ),
    )
        .where((item) => item.score > -999)
        .toList();

    scored.sort((a, b) {
      final int byScore = b.score.compareTo(a.score);
      if (byScore != 0) {
        return byScore;
      }

      final double ratingA = _readRating(a.product);
      final double ratingB = _readRating(b.product);
      return ratingB.compareTo(ratingA);
    });

    final List<dynamic> selected = scored.take(5).map((e) => e.product).toList();
    final List<dynamic> alternatives =
    scored.skip(1).take(4).map((e) => e.product).toList();

    return BouquetRecommendationResult(
      products: selected,
      alternativeProducts: alternatives,
      title: _buildTitle(
        recipient: recipient,
        occasion: occasion,
        favoriteFlowers: favoriteFlowers,
      ),
      subtitle: _buildSubtitle(
        recipientAge: recipientAge,
        mood: mood,
      ),
      moodEmoji: _moodBadge(mood),
      summaryChips: <String>[
        recipient,
        recipientAge,
        favoriteFlowers,
        occasion,
        budget,
        mood,
        palette,
        size,
      ],
      explanation: _buildExplanation(
        recipient: recipient,
        recipientAge: recipientAge,
        favoriteFlowers: favoriteFlowers,
        occasion: occasion,
        budget: budget,
        mood: mood,
        palette: palette,
        size: size,
      ),
    );
  }

  static int _calculateScore({
    required dynamic product,
    required String recipient,
    required String recipientAge,
    required String favoriteFlowers,
    required String occasion,
    required String budget,
    required String mood,
    required String palette,
    required String size,
  }) {
    final String name = _readName(product).toLowerCase();
    final String category = _readCategory(product).toLowerCase();
    final String description = _readDescription(product).toLowerCase();
    final String text = '$name $category $description';
    final double price = _readPrice(product);

    int score = 0;

    score += _scoreRecipient(text, recipient);
    score += _scoreRecipientAge(text, recipientAge);
    score += _scoreFavoriteFlowers(text, favoriteFlowers);
    score += _scoreOccasion(text, occasion);
    score += _scoreBudget(price, budget);
    score += _scoreMood(text, mood);
    score += _scorePalette(text, palette);
    score += _scoreSize(text, size);

    if (_containsAny(text, <String>['авторск', 'премиум', 'элегант', 'стиль'])) {
      score += 2;
    }

    if (_containsAny(text, <String>['нежн', 'романт', 'воздуш', 'легк']) &&
        mood == 'Нежность') {
      score += 3;
    }

    if (_containsAny(text, <String>['ярк', 'сочн', 'контраст', 'энерг']) &&
        mood == 'Яркость') {
      score += 3;
    }

    if (_containsAny(text, <String>['класс', 'статус', 'благород', 'преми']) &&
        mood == 'Статус') {
      score += 3;
    }

    score += _readRating(product).round();

    return score;
  }

  static int _scoreRecipient(String text, String recipient) {
    switch (recipient) {
      case 'Девушке':
        if (_containsAny(text, <String>['нежн', 'романт', 'роз', 'пион', 'пастел'])) {
          return 8;
        }
        return 2;
      case 'Жене':
        if (_containsAny(text, <String>['элег', 'роза', 'пион', 'премиум'])) {
          return 9;
        }
        return 3;
      case 'Маме':
        if (_containsAny(text, <String>['тепл', 'класс', 'хризант', 'лили'])) {
          return 8;
        }
        return 3;
      case 'Подруге':
        if (_containsAny(text, <String>['ярк', 'гербер', 'тюльпан', 'микс'])) {
          return 8;
        }
        return 3;
      case 'Коллеге':
        if (_containsAny(text, <String>['сдерж', 'стиль', 'миним', 'лакон'])) {
          return 8;
        }
        return 3;
      case 'Учителю':
        if (_containsAny(text, <String>['уваж', 'класс', 'сдерж', 'благород'])) {
          return 8;
        }
        return 3;
      case 'Бабушке':
        if (_containsAny(text, <String>['тепл', 'душевн', 'хризант', 'класс'])) {
          return 8;
        }
        return 3;
      case 'Мужчине':
        if (_containsAny(text, <String>['строг', 'контраст', 'моно', 'лакон'])) {
          return 9;
        }
        return 2;
      default:
        return 0;
    }
  }

  static int _scoreRecipientAge(String text, String age) {
    switch (age) {
      case 'До 18':
        if (_containsAny(text, <String>['нежн', 'легк', 'воздуш', 'мини'])) {
          return 6;
        }
        return 2;
      case '18–25':
        if (_containsAny(text, <String>['ярк', 'стиль', 'тренд', 'свеж'])) {
          return 7;
        }
        return 2;
      case '26–35':
        if (_containsAny(text, <String>['элег', 'стиль', 'авторск', 'выраз'])) {
          return 7;
        }
        return 3;
      case '36–50':
        if (_containsAny(text, <String>['класс', 'элег', 'преми', 'благород'])) {
          return 8;
        }
        return 3;
      case '51+':
        if (_containsAny(text, <String>['спокой', 'класс', 'тепл', 'традиц'])) {
          return 8;
        }
        return 3;
      default:
        return 0;
    }
  }

  static int _scoreFavoriteFlowers(String text, String flowers) {
    switch (flowers) {
      case 'Розы':
        return _containsAny(text, <String>['роза', 'роз']) ? 12 : 1;
      case 'Пионы':
        return _containsAny(text, <String>['пион']) ? 12 : 1;
      case 'Тюльпаны':
        return _containsAny(text, <String>['тюльпан']) ? 12 : 1;
      case 'Лилии':
        return _containsAny(text, <String>['лили']) ? 12 : 1;
      case 'Хризантемы':
        return _containsAny(text, <String>['хризант']) ? 12 : 1;
      case 'Герберы':
        return _containsAny(text, <String>['гербер']) ? 12 : 1;
      case 'Смешанный букет':
        return _containsAny(text, <String>['микс', 'смешан', 'ассорти']) ? 8 : 3;
      default:
        return 0;
    }
  }

  static int _scoreOccasion(String text, String occasion) {
    switch (occasion) {
      case 'День рождения':
        if (_containsAny(text, <String>['ярк', 'праздн', 'эффект', 'пышн'])) {
          return 8;
        }
        return 3;
      case '8 Марта':
        if (_containsAny(text, <String>['весен', 'тюльпан', 'нежн', 'свеж'])) {
          return 8;
        }
        return 3;
      case 'Свидание':
        if (_containsAny(text, <String>['романт', 'роз', 'пион', 'воздуш'])) {
          return 9;
        }
        return 2;
      case 'Юбилей':
        if (_containsAny(text, <String>['статус', 'премиум', 'больш', 'роскош'])) {
          return 9;
        }
        return 3;
      case 'Извинение':
        if (_containsAny(text, <String>['нежн', 'деликат', 'спокой', 'мягк'])) {
          return 8;
        }
        return 3;
      case 'Без повода':
        if (_containsAny(text, <String>['свеж', 'универс', 'мил', 'аккурат'])) {
          return 8;
        }
        return 3;
      default:
        return 0;
    }
  }

  static int _scoreBudget(double price, String budget) {
    switch (budget) {
      case 'До 2000 ₽':
        if (price <= 2000) return 10;
        if (price <= 2400) return 6;
        return 0;
      case '2000–3500 ₽':
        if (price >= 2000 && price <= 3500) return 10;
        if (price >= 1800 && price <= 3800) return 6;
        return 1;
      case '3500–5000 ₽':
        if (price >= 3500 && price <= 5000) return 10;
        if (price >= 3200 && price <= 5500) return 6;
        return 1;
      case '5000+ ₽':
        if (price >= 5000) return 10;
        if (price >= 4500) return 6;
        return 1;
      default:
        return 0;
    }
  }

  static int _scoreMood(String text, String mood) {
    switch (mood) {
      case 'Нежность':
        return _containsAny(text, <String>['нежн', 'пастел', 'воздуш', 'мягк']) ? 8 : 2;
      case 'Романтика':
        return _containsAny(text, <String>['романт', 'роз', 'пион', 'серд']) ? 8 : 2;
      case 'Яркость':
        return _containsAny(text, <String>['ярк', 'сочн', 'контраст', 'насыщ']) ? 8 : 2;
      case 'Спокойствие':
        return _containsAny(text, <String>['спокой', 'гармон', 'сдерж', 'мягк']) ? 8 : 2;
      case 'Статус':
        return _containsAny(text, <String>['статус', 'премиум', 'элег', 'благород']) ? 8 : 2;
      default:
        return 0;
    }
  }

  static int _scorePalette(String text, String palette) {
    switch (palette) {
      case 'Пастельная':
        return _containsAny(text, <String>['пастел', 'крем', 'нежн', 'светл']) ? 8 : 2;
      case 'Яркая':
        return _containsAny(text, <String>['ярк', 'контраст', 'цветн', 'сочн']) ? 8 : 2;
      case 'Красно-бордовая':
        return _containsAny(text, <String>['красн', 'бордов', 'винн']) ? 8 : 2;
      case 'Белая/кремовая':
        return _containsAny(text, <String>['бел', 'крем', 'молоч']) ? 8 : 2;
      case 'Микс':
        return _containsAny(text, <String>['микс', 'разноцвет', 'ассорти']) ? 8 : 3;
      default:
        return 0;
    }
  }

  static int _scoreSize(String text, String size) {
    switch (size) {
      case 'Небольшой':
        return _containsAny(text, <String>['мини', 'компакт', 'небольш']) ? 7 : 2;
      case 'Средний':
        return _containsAny(text, <String>['средн', 'универс']) ? 7 : 3;
      case 'Большой':
        return _containsAny(text, <String>['больш', 'пышн', 'объем', 'роскош']) ? 7 : 2;
      default:
        return 0;
    }
  }

  static String _buildTitle({
    required String recipient,
    required String occasion,
    required String favoriteFlowers,
  }) {
    return 'Подбор для "$recipient" на "$occasion"';
  }

  static String _buildSubtitle({
    required String recipientAge,
    required String mood,
  }) {
    return 'С учётом возраста "$recipientAge" и настроения "$mood"';
  }

  static String _buildExplanation({
    required String recipient,
    required String recipientAge,
    required String favoriteFlowers,
    required String occasion,
    required String budget,
    required String mood,
    required String palette,
    required String size,
  }) {
    return 'Мы подобрали букет не случайно. '
        'В рекомендации учтены получатель "$recipient", возраст "$recipientAge", '
        'любимые цветы "$favoriteFlowers", повод "$occasion", бюджет "$budget", '
        'настроение "$mood", палитра "$palette" и размер "$size". '
        'Поэтому в подбор попали варианты, которые ближе по составу, характеру и цене, '
        'а также подходят как аналоги для защиты диплома и объяснения логики выбора.';
  }

  static String _moodBadge(String mood) {
    switch (mood) {
      case 'Нежность':
        return 'Нежный стиль';
      case 'Романтика':
        return 'Романтичный стиль';
      case 'Яркость':
        return 'Яркий стиль';
      case 'Спокойствие':
        return 'Спокойный стиль';
      case 'Статус':
        return 'Статусный стиль';
      default:
        return 'Подходящий стиль';
    }
  }

  static bool _containsAny(String source, List<String> needles) {
    for (final String needle in needles) {
      if (source.contains(needle)) {
        return true;
      }
    }
    return false;
  }

  static bool _isAvailable(dynamic product) {
    if (product is Product) {
      return product.inStock;
    }
    try {
      return product.inStock == true;
    } catch (_) {
      return true;
    }
  }

  static String _readName(dynamic product) {
    if (product is Product) return product.name;
    try {
      return (product.name ?? '').toString();
    } catch (_) {
      return '';
    }
  }

  static String _readCategory(dynamic product) {
    if (product is Product) return product.categoryName;
    try {
      return (product.categoryName ?? product.category ?? '').toString();
    } catch (_) {
      return '';
    }
  }

  static String _readDescription(dynamic product) {
    if (product is Product) return product.description;
    try {
      return (product.description ?? '').toString();
    } catch (_) {
      return '';
    }
  }

  static double _readPrice(dynamic product) {
    if (product is Product) return product.price;
    try {
      final dynamic value = product.price;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString()) ?? 0;
    } catch (_) {
      return 0;
    }
  }

  static double _readRating(dynamic product) {
    if (product is Product) return product.rating;
    try {
      final dynamic value = product.rating;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString()) ?? 0;
    } catch (_) {
      return 0;
    }
  }
}

class _ScoredProduct {
  final dynamic product;
  final int score;

  const _ScoredProduct({
    required this.product,
    required this.score,
  });
}
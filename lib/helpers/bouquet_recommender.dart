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
      if (byScore != 0) return byScore;

      final double priceA = _readPrice(a.product);
      final double priceB = _readPrice(b.product);

      final double targetBudgetPrice = _budgetCenter(budget);
      final double diffA = (priceA - targetBudgetPrice).abs();
      final double diffB = (priceB - targetBudgetPrice).abs();

      return diffA.compareTo(diffB);
    });

    final List<dynamic> mainProducts =
    scored.take(3).map((e) => e.product).toList();

    List<dynamic> alternativeProducts = scored
        .skip(3)
        .map((e) => e.product)
        .where((product) => !mainProducts.contains(product))
        .take(2)
        .toList();

    if (mainProducts.isEmpty) {
      final fallback = products
          .where((product) => _isAvailable(product))
          .where((product) => _matchesBudget(_readPrice(product), budget))
          .toList();

      fallback.sort((a, b) {
        final double targetBudgetPrice = _budgetCenter(budget);
        final double diffA = (_readPrice(a) - targetBudgetPrice).abs();
        final double diffB = (_readPrice(b) - targetBudgetPrice).abs();
        return diffA.compareTo(diffB);
      });

      return BouquetRecommendationResult(
        products: fallback.take(3).toList(),
        alternativeProducts: fallback.skip(3).take(2).toList(),
        title: 'Подобрали универсальные варианты',
        subtitle:
        'По вашему бюджету лучше всего подходят эти букеты — они будут смотреться уместно практически для любого случая.',
        moodEmoji: '💐',
        summaryChips: [recipient, occasion, budget, mood, palette, size],
        explanation:
        'Точных совпадений по всем параметрам не нашлось, поэтому мы выбрали самые удачные и безопасные варианты по бюджету и общему стилю.',
      );
    }

    if (alternativeProducts.isEmpty) {
      alternativeProducts = mainProducts.skip(1).take(2).toList();
    }

    return BouquetRecommendationResult(
      products: mainProducts,
      alternativeProducts: alternativeProducts,
      title: _buildTitle(recipient, occasion, mood),
      subtitle: _buildSubtitle(recipient, occasion, palette, size),
      moodEmoji: _buildMoodEmoji(occasion, mood),
      summaryChips: [recipient, occasion, budget, mood, palette, size],
      explanation: _buildExplanation(
        recipient: recipient,
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
    required String occasion,
    required String budget,
    required String mood,
    required String palette,
    required String size,
  }) {
    final String name = _readName(product).toLowerCase();
    final String category = _readCategory(product).toLowerCase();
    final String description = _readDescription(product).toLowerCase();
    final double price = _readPrice(product);

    if (!_matchesBudget(price, budget)) {
      return -1000;
    }

    final String haystack = '$name $category $description';

    int score = 0;

    score += _scoreRecipient(recipient, haystack);
    score += _scoreOccasion(occasion, haystack);
    score += _scoreMood(mood, haystack);
    score += _scorePalette(palette, haystack);
    score += _scoreSize(size, haystack);
    score += _scoreBudgetFit(price, budget);

    if (category.contains('подар') || category.contains('букет')) {
      score += 2;
    }

    if (_readRating(product) >= 4.7) {
      score += 2;
    } else if (_readRating(product) >= 4.3) {
      score += 1;
    }

    return score;
  }

  static int _scoreRecipient(String recipient, String haystack) {
    switch (recipient) {
      case 'Девушке':
      case 'Жене':
        return _keywordScore(
          haystack,
          ['роман', 'роз', 'пион', 'нежн', 'love', 'сердц'],
          4,
        );
      case 'Маме':
        return _keywordScore(
          haystack,
          ['нежн', 'тепл', 'класс', 'гортенз', 'лилия', 'хризант'],
          4,
        );
      case 'Подруге':
        return _keywordScore(
          haystack,
          ['ярк', 'микс', 'гербер', 'тюльпан', 'цветн'],
          4,
        );
      case 'Коллеге':
        return _keywordScore(
          haystack,
          ['миним', 'стиль', 'моно', 'эвкалипт', 'бел', 'строг'],
          4,
        );
      case 'Учителю':
        return _keywordScore(
          haystack,
          ['класс', 'элег', 'сдерж', 'хризант', 'лилия'],
          4,
        );
      case 'Бабушке':
        return _keywordScore(
          haystack,
          ['тепл', 'класс', 'нежн', 'хризант', 'гвоздик'],
          4,
        );
      case 'Мужчине':
        return _keywordScore(
          haystack,
          ['строг', 'контраст', 'моно', 'миним', 'брут'],
          5,
        );
      default:
        return 0;
    }
  }

  static int _scoreOccasion(String occasion, String haystack) {
    switch (occasion) {
      case 'День рождения':
        return _keywordScore(
          haystack,
          ['празд', 'ярк', 'микс', 'торж', 'больш'],
          5,
        );
      case 'Романтика':
        return _keywordScore(
          haystack,
          ['роман', 'роз', 'пион', 'нежн', 'love', 'сердц'],
          6,
        );
      case 'Благодарность':
        return _keywordScore(
          haystack,
          ['нежн', 'стиль', 'элег', 'спокойн'],
          4,
        );
      case 'Извинение':
        return _keywordScore(
          haystack,
          ['нежн', 'пастел', 'роз', 'бел', 'воздуш'],
          5,
        );
      case 'Юбилей':
        return _keywordScore(
          haystack,
          ['больш', 'премиум', 'торж', 'роскош', 'композ'],
          6,
        );
      case 'Без повода':
        return _keywordScore(
          haystack,
          ['легк', 'свеж', 'нежн', 'компакт'],
          4,
        );
      default:
        return 0;
    }
  }

  static int _scoreMood(String mood, String haystack) {
    switch (mood) {
      case 'Нежный':
        return _keywordScore(
          haystack,
          ['нежн', 'пастел', 'роз', 'пион', 'тюльпан', 'воздуш'],
          6,
        );
      case 'Романтичный':
        return _keywordScore(
          haystack,
          ['роман', 'роз', 'пион', 'love', 'сердц'],
          6,
        );
      case 'Яркий':
        return _keywordScore(
          haystack,
          ['ярк', 'микс', 'гербер', 'экзот', 'солнеч'],
          6,
        );
      case 'Элегантный':
        return _keywordScore(
          haystack,
          ['элег', 'стиль', 'моно', 'бел', 'эвкалипт'],
          6,
        );
      case 'Строгий':
        return _keywordScore(
          haystack,
          ['строг', 'контраст', 'миним', 'моно', 'стиль'],
          6,
        );
      default:
        return 0;
    }
  }

  static int _scorePalette(String palette, String haystack) {
    switch (palette) {
      case 'Пастельная':
        return _keywordScore(
          haystack,
          ['пастел', 'беж', 'крем', 'нежн', 'пудров'],
          5,
        );
      case 'Белая':
        return _keywordScore(
          haystack,
          ['бел', 'white', 'молоч', 'крем'],
          5,
        );
      case 'Розовая':
        return _keywordScore(
          haystack,
          ['роз', 'pink', 'пудров'],
          5,
        );
      case 'Красная':
        return _keywordScore(
          haystack,
          ['крас', 'бордо', 'wine'],
          5,
        );
      case 'Яркий микс':
        return _keywordScore(
          haystack,
          ['микс', 'ярк', 'цветн', 'радуг', 'гербер'],
          5,
        );
      default:
        return 0;
    }
  }

  static int _scoreSize(String size, String haystack) {
    switch (size) {
      case 'Компактный':
        return _keywordScore(
          haystack,
          ['мини', 'компакт', 'маленьк', 'аккурат'],
          4,
        );
      case 'Средний':
        return _keywordScore(
          haystack,
          ['средн', 'баланс', 'универс'],
          3,
        );
      case 'Большой':
        return _keywordScore(
          haystack,
          ['больш', 'пышн', 'объём', 'роскош', 'grand'],
          5,
        );
      default:
        return 0;
    }
  }

  static int _scoreBudgetFit(double price, String budget) {
    final double center = _budgetCenter(budget);
    final double diff = (price - center).abs();

    if (diff <= 400) return 5;
    if (diff <= 900) return 3;
    if (diff <= 1500) return 1;
    return 0;
  }

  static int _keywordScore(
      String haystack,
      List<String> keywords,
      int pointsPerMatch,
      ) {
    int score = 0;
    for (final keyword in keywords) {
      if (haystack.contains(keyword)) {
        score += pointsPerMatch;
      }
    }
    return score;
  }

  static bool _matchesBudget(double price, String budget) {
    switch (budget) {
      case 'До 2500 ₽':
        return price <= 2500;
      case '2500–4000 ₽':
        return price >= 2500 && price <= 4000;
      case '4000–6000 ₽':
        return price >= 4000 && price <= 6000;
      case '6000+ ₽':
        return price >= 6000;
      default:
        return true;
    }
  }

  static double _budgetCenter(String budget) {
    switch (budget) {
      case 'До 2500 ₽':
        return 2000;
      case '2500–4000 ₽':
        return 3250;
      case '4000–6000 ₽':
        return 5000;
      case '6000+ ₽':
        return 7000;
      default:
        return 3500;
    }
  }

  static String _buildTitle(String recipient, String occasion, String mood) {
    if (occasion == 'Романтика') {
      return 'Идеальный букет для романтичного момента';
    }
    if (occasion == 'Юбилей') {
      return 'Торжественный букет для важного события';
    }
    if (recipient == 'Маме') {
      return 'Нежный и тёплый букет для мамы';
    }
    if (recipient == 'Коллеге') {
      return 'Стильный вариант с уместной подачей';
    }
    if (mood == 'Яркий') {
      return 'Яркий букет с эффектной подачей';
    }
    if (mood == 'Элегантный' || mood == 'Строгий') {
      return 'Элегантный букет в выдержанном стиле';
    }
    return 'Мы подобрали букет под ваш запрос';
  }

  static String _buildSubtitle(
      String recipient,
      String occasion,
      String palette,
      String size,
      ) {
    return 'С учётом повода "$occasion", получателя "$recipient", палитры "$palette" и формата "$size" лучше всего подходят эти варианты.';
  }

  static String _buildMoodEmoji(String occasion, String mood) {
    if (occasion == 'Романтика') return '❤️';
    if (occasion == 'День рождения') return '🎉';
    if (occasion == 'Юбилей') return '✨';
    if (mood == 'Нежный') return '🌷';
    if (mood == 'Яркий') return '🌺';
    if (mood == 'Элегантный' || mood == 'Строгий') return '🤍';
    return '💐';
  }

  static String _buildExplanation({
    required String recipient,
    required String occasion,
    required String budget,
    required String mood,
    required String palette,
    required String size,
  }) {
    return 'Мы учли, что букет нужен $recipient, повод — "$occasion", комфортный бюджет — "$budget". Поэтому в подбор попали варианты с настроением "$mood", палитрой "$palette" и форматом "$size".';
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
      return (product.categoryName ?? '').toString();
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
      final value = product.price;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString()) ?? 0;
    } catch (_) {
      return 0;
    }
  }

  static double _readRating(dynamic product) {
    if (product is Product) return product.rating;
    try {
      final value = product.rating;
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
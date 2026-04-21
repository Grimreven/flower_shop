import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/cart_controller.dart';
import '../../helpers/bouquet_recommender.dart';
import '../../models/product.dart';
import '../../utils/app_colors.dart';
import '../../widgets/product_detail.dart';

class BouquetQuizScreen extends StatefulWidget {
  final List<dynamic> products;

  const BouquetQuizScreen({
    super.key,
    required this.products,
  });

  @override
  State<BouquetQuizScreen> createState() => _BouquetQuizScreenState();
}

class _BouquetQuizScreenState extends State<BouquetQuizScreen> {
  final CartController cartController = Get.find<CartController>();
  final AuthController authController = Get.find<AuthController>();

  int currentStep = 0;
  bool isPreparing = false;

  String? selectedRecipient;
  String? selectedRecipientAge;
  String? selectedFavoriteFlowers;
  String? selectedOccasion;
  String? selectedBudget;
  String? selectedMood;
  String? selectedPalette;
  String? selectedSize;

  BouquetRecommendationResult? recommendation;

  late final List<_QuizStepConfig> steps = [
    _QuizStepConfig(
      title: 'Кому вы выбираете букет?',
      subtitle: 'Это поможет подобрать подходящий характер композиции.',
      icon: Icons.favorite_border_rounded,
      options: const [
        _QuizOption('Девушке', 'Нежно и романтично', Icons.favorite_rounded),
        _QuizOption('Жене', 'Элегантно и с теплом', Icons.workspace_premium),
        _QuizOption('Маме', 'Тёпло, заботливо, красиво', Icons.local_florist),
        _QuizOption('Подруге', 'Живо, свежо, ярко', Icons.emoji_emotions),
        _QuizOption('Коллеге', 'Уместно и стильно', Icons.work_outline),
        _QuizOption('Учителю', 'Сдержанно и уважительно', Icons.school_outlined),
        _QuizOption('Бабушке', 'Душевно и тепло', Icons.volunteer_activism),
        _QuizOption('Мужчине', 'Строго и выразительно', Icons.auto_awesome),
      ],
    ),
    _QuizStepConfig(
      title: 'Сколько лет получателю?',
      subtitle: 'Возраст поможет точнее подобрать стиль и аналог букета.',
      icon: Icons.cake_outlined,
      options: const [
        _QuizOption('До 18', 'Лёгкие и нежные композиции', Icons.looks_one_rounded),
        _QuizOption('18–25', 'Свежие и трендовые букеты', Icons.auto_awesome_rounded),
        _QuizOption('26–35', 'Стильные и выразительные композиции', Icons.favorite_outline_rounded),
        _QuizOption('36–50', 'Элегантные классические решения', Icons.workspace_premium_outlined),
        _QuizOption('51+', 'Тёплые и благородные букеты', Icons.local_florist_outlined),
      ],
    ),
    _QuizStepConfig(
      title: 'Какие цветы нравятся больше всего?',
      subtitle: 'Это позволит предложить похожие букеты и аналоги по составу.',
      icon: Icons.filter_vintage_outlined,
      options: const [
        _QuizOption('Розы', 'Классика и универсальность', Icons.local_florist),
        _QuizOption('Пионы', 'Пышно и романтично', Icons.spa_outlined),
        _QuizOption('Тюльпаны', 'Свежо и легко', Icons.eco_outlined),
        _QuizOption('Лилии', 'Выразительно и торжественно', Icons.auto_fix_high_outlined),
        _QuizOption('Хризантемы', 'Практично и стойко', Icons.blur_on_outlined),
        _QuizOption('Герберы', 'Ярко и позитивно', Icons.wb_sunny_outlined),
        _QuizOption('Смешанный букет', 'Подойдут разные варианты', Icons.apps_rounded),
      ],
    ),
    _QuizStepConfig(
      title: 'По какому поводу нужен букет?',
      subtitle: 'Повод влияет на настроение и подачу композиции.',
      icon: Icons.celebration_outlined,
      options: const [
        _QuizOption('День рождения', 'Ярко и празднично', Icons.cake_outlined),
        _QuizOption('8 Марта', 'Нежно и весенне', Icons.local_florist_outlined),
        _QuizOption('Свидание', 'Романтично и воздушно', Icons.favorite_outline_rounded),
        _QuizOption('Юбилей', 'Статусно и выразительно', Icons.workspace_premium_outlined),
        _QuizOption('Извинение', 'Мягко и деликатно', Icons.volunteer_activism_outlined),
        _QuizOption('Без повода', 'Просто порадовать', Icons.sentiment_satisfied_alt_outlined),
      ],
    ),
    _QuizStepConfig(
      title: 'Какой бюджет вам подходит?',
      subtitle: 'Так мы предложим лучший вариант в нужной ценовой категории.',
      icon: Icons.payments_outlined,
      options: const [
        _QuizOption('До 2000 ₽', 'Компактно и красиво', Icons.currency_ruble),
        _QuizOption('2000–3500 ₽', 'Оптимальный выбор', Icons.account_balance_wallet_outlined),
        _QuizOption('3500–5000 ₽', 'Более выразительные композиции', Icons.savings_outlined),
        _QuizOption('5000+ ₽', 'Премиальный сегмент', Icons.diamond_outlined),
      ],
    ),
    _QuizStepConfig(
      title: 'Какое настроение должен передавать букет?',
      subtitle: 'Это влияет на форму, насыщенность и характер композиции.',
      icon: Icons.palette_outlined,
      options: const [
        _QuizOption('Нежность', 'Мягкие оттенки и воздушность', Icons.cloud_outlined),
        _QuizOption('Романтика', 'Тепло и внимание', Icons.favorite_border_rounded),
        _QuizOption('Яркость', 'Смело и энергично', Icons.wb_sunny_outlined),
        _QuizOption('Спокойствие', 'Сдержанно и гармонично', Icons.self_improvement_outlined),
        _QuizOption('Статус', 'Дорого и выразительно', Icons.workspace_premium_outlined),
      ],
    ),
    _QuizStepConfig(
      title: 'Какая цветовая гамма вам ближе?',
      subtitle: 'Подберём композиции в нужном визуальном стиле.',
      icon: Icons.color_lens_outlined,
      options: const [
        _QuizOption('Пастельная', 'Нежные спокойные оттенки', Icons.blur_on_outlined),
        _QuizOption('Яркая', 'Контрастно и заметно', Icons.colorize_outlined),
        _QuizOption('Красно-бордовая', 'Глубоко и страстно', Icons.favorite_rounded),
        _QuizOption('Белая/кремовая', 'Чисто и элегантно', Icons.brightness_7_outlined),
        _QuizOption('Микс', 'Разноцветные решения', Icons.gradient_outlined),
      ],
    ),
    _QuizStepConfig(
      title: 'Какой размер букета нужен?',
      subtitle: 'От этого зависит объём и формат композиции.',
      icon: Icons.photo_size_select_small_outlined,
      options: const [
        _QuizOption('Небольшой', 'Лаконичный вариант', Icons.looks_one_outlined),
        _QuizOption('Средний', 'Универсальный размер', Icons.looks_two_outlined),
        _QuizOption('Большой', 'Эффектная композиция', Icons.looks_3_outlined),
      ],
    ),
  ];

  bool _isStepCompleted(int step) {
    switch (step) {
      case 0:
        return selectedRecipient != null;
      case 1:
        return selectedRecipientAge != null;
      case 2:
        return selectedFavoriteFlowers != null;
      case 3:
        return selectedOccasion != null;
      case 4:
        return selectedBudget != null;
      case 5:
        return selectedMood != null;
      case 6:
        return selectedPalette != null;
      case 7:
        return selectedSize != null;
      default:
        return false;
    }
  }

  String? _selectedValueForStep(int step) {
    switch (step) {
      case 0:
        return selectedRecipient;
      case 1:
        return selectedRecipientAge;
      case 2:
        return selectedFavoriteFlowers;
      case 3:
        return selectedOccasion;
      case 4:
        return selectedBudget;
      case 5:
        return selectedMood;
      case 6:
        return selectedPalette;
      case 7:
        return selectedSize;
      default:
        return null;
    }
  }

  void _selectValueForStep(int step, String value) {
    setState(() {
      switch (step) {
        case 0:
          selectedRecipient = value;
          break;
        case 1:
          selectedRecipientAge = value;
          break;
        case 2:
          selectedFavoriteFlowers = value;
          break;
        case 3:
          selectedOccasion = value;
          break;
        case 4:
          selectedBudget = value;
          break;
        case 5:
          selectedMood = value;
          break;
        case 6:
          selectedPalette = value;
          break;
        case 7:
          selectedSize = value;
          break;
      }
    });
  }

  Future<void> _buildRecommendation() async {
    setState(() {
      isPreparing = true;
    });

    await Future.delayed(const Duration(milliseconds: 250));

    final BouquetRecommendationResult result = BouquetRecommender.recommend(
      products: widget.products,
      recipient: selectedRecipient!,
      recipientAge: selectedRecipientAge!,
      favoriteFlowers: selectedFavoriteFlowers!,
      occasion: selectedOccasion!,
      budget: selectedBudget!,
      mood: selectedMood!,
      palette: selectedPalette!,
      size: selectedSize!,
    );

    setState(() {
      recommendation = result;
      isPreparing = false;
    });
  }

  void _restartQuiz() {
    setState(() {
      currentStep = 0;
      selectedRecipient = null;
      selectedRecipientAge = null;
      selectedFavoriteFlowers = null;
      selectedOccasion = null;
      selectedBudget = null;
      selectedMood = null;
      selectedPalette = null;
      selectedSize = null;
      recommendation = null;
      isPreparing = false;
    });
  }

  void _nextStep() {
    if (!_isStepCompleted(currentStep)) {
      Get.snackbar('Выбор', 'Пожалуйста, выберите один из вариантов');
      return;
    }

    if (currentStep == steps.length - 1) {
      _buildRecommendation();
      return;
    }

    setState(() {
      currentStep += 1;
    });
  }

  void _prevStep() {
    if (currentStep == 0) return;
    setState(() {
      currentStep -= 1;
    });
  }

  void _goToHome() {
    Get.offAllNamed('/main', arguments: {'tabIndex': 0});
  }

  Product? _castProduct(dynamic product) {
    if (product is Product) {
      return product;
    }
    return null;
  }

  Widget _buildStepCard(BuildContext context, _QuizStepConfig step) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final String? selectedValue = _selectedValueForStep(currentStep);
    final Color cardColor = Theme.of(context).cardColor;
    final Color onSurface = Theme.of(context).colorScheme.onSurface;
    final Color muted =
    isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
    final Color borderColor = isDark ? AppColors.darkBorder : AppColors.border;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: isDark ? AppColors.darkCardGradient : null,
        color: isDark ? null : cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? AppColors.purple.withOpacity(0.08)
                : AppColors.shadow,
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: isDark
                    ? AppColors.purple.withOpacity(0.18)
                    : AppColors.primaryLight,
                child: Icon(
                  step.icon,
                  color: isDark ? AppColors.purpleLight : AppColors.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      step.title,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: onSurface,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      step.subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.35,
                        color: muted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ...step.options.map((option) {
            final bool selected = selectedValue == option.title;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () => _selectValueForStep(currentStep, option.title),
                borderRadius: BorderRadius.circular(18),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: selected
                        ? (isDark
                        ? AppColors.darkSurfaceElevated
                        : AppColors.primaryLight)
                        : (isDark ? AppColors.darkSurfaceSoft : Colors.white),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: selected
                          ? (isDark ? AppColors.purpleLight : AppColors.primary)
                          : borderColor,
                      width: selected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: selected
                              ? (isDark
                              ? AppColors.purple.withOpacity(0.18)
                              : AppColors.primary.withOpacity(0.10))
                              : (isDark
                              ? AppColors.darkBackgroundSecondary
                              : AppColors.primaryLight),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          option.icon,
                          color: selected
                              ? (isDark
                              ? AppColors.purpleLight
                              : AppColors.primary)
                              : muted,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              option.title,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: onSurface,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              option.subtitle,
                              style: TextStyle(
                                fontSize: 13,
                                color: muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Radio<String>(
                        value: option.title,
                        groupValue: selectedValue,
                        onChanged: (value) {
                          if (value == null) return;
                          _selectValueForStep(currentStep, value);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, dynamic item) {
    final Product? product = _castProduct(item);
    if (product == null) {
      return const SizedBox.shrink();
    }

    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color cardColor = Theme.of(context).cardColor;
    final Color onSurface = Theme.of(context).colorScheme.onSurface;
    final Color muted =
    isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
    final Color borderColor = isDark ? AppColors.darkBorder : AppColors.border;

    return Container(
      width: 250,
      margin: const EdgeInsets.only(right: 14),
      decoration: BoxDecoration(
        gradient: isDark ? AppColors.darkCardGradient : null,
        color: isDark ? null : cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? AppColors.purple.withOpacity(0.08)
                : AppColors.shadow,
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () {
          Get.to(
                () => ProductDetail(
              product: product,
              cartController: cartController,
              authController: authController,
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Image.network(
                  product.imageUrl,
                  height: 170,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 170,
                    color: isDark
                        ? AppColors.darkSurfaceSoft
                        : AppColors.primaryLight,
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.image_not_supported_outlined,
                      color: isDark ? AppColors.purpleLight : AppColors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                product.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                product.description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.35,
                  color: muted,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '${product.price.toStringAsFixed(0)} ₽',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.purpleLight : AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecommendationView(BuildContext context) {
    final BouquetRecommendationResult result = recommendation!;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color onSurface = Theme.of(context).colorScheme.onSurface;
    final Color muted =
    isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
    final Color borderColor = isDark ? AppColors.darkBorder : AppColors.border;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: isDark ? AppColors.darkCardGradient : null,
            color: isDark ? null : Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                result.title,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                result.subtitle,
                style: TextStyle(
                  fontSize: 15,
                  color: muted,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                result.moodEmoji,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.purpleLight : AppColors.primary,
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: result.summaryChips
                    .map(
                      (chip) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkSurfaceElevated
                          : AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      chip,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.purpleLight
                            : AppColors.primary,
                      ),
                    ),
                  ),
                )
                    .toList(),
              ),
              const SizedBox(height: 16),
              Text(
                result.explanation,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.45,
                  color: muted,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Лучшие варианты',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: onSurface,
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 330,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: result.products
                .map((item) => _buildProductCard(context, item))
                .toList(),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 56,
                child: OutlinedButton(
                  onPressed: _restartQuiz,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: borderColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: const Text(
                    'Пройти заново',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _goToHome,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: const Text(
                    'На главную',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bg = Theme.of(context).scaffoldBackgroundColor;
    final Color onSurface = Theme.of(context).colorScheme.onSurface;

    if (recommendation != null) {
      return Scaffold(
        backgroundColor: bg,
        appBar: AppBar(
          title: Text(
            'Результат подбора',
            style: TextStyle(
              color: onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        body: _buildRecommendationView(context),
      );
    }

    final _QuizStepConfig step = steps[currentStep];

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Text(
          'Подбор букета',
          style: TextStyle(
            color: onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Column(
              children: [
                LinearProgressIndicator(
                  value: (currentStep + 1) / steps.length,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(999),
                  backgroundColor:
                  isDark ? AppColors.darkBorderSoft : AppColors.primaryLight,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isDark ? AppColors.purpleLight : AppColors.primary,
                  ),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Шаг ${currentStep + 1} из ${steps.length}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.darkMutedForeground
                          : AppColors.mutedForeground,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: isPreparing
                ? const Center(child: CircularProgressIndicator())
                : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildStepCard(context, step),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                children: [
                  if (currentStep > 0)
                    Expanded(
                      child: SizedBox(
                        height: 54,
                        child: OutlinedButton(
                          onPressed: _prevStep,
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: const Text('Назад'),
                        ),
                      ),
                    ),
                  if (currentStep > 0) const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _nextStep,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: Text(
                          currentStep == steps.length - 1
                              ? 'Показать рекомендации'
                              : 'Далее',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuizStepConfig {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<_QuizOption> options;

  const _QuizStepConfig({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.options,
  });
}

class _QuizOption {
  final String title;
  final String subtitle;
  final IconData icon;

  const _QuizOption(
      this.title,
      this.subtitle,
      this.icon,
      );
}
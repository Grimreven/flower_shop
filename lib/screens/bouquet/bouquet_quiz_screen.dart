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
      title: 'По какому поводу нужен букет?',
      subtitle: 'Повод влияет на настроение и подачу композиции.',
      icon: Icons.celebration_outlined,
      options: const [
        _QuizOption(
          'День рождения',
          'Праздничный и заметный',
          Icons.cake_outlined,
        ),
        _QuizOption(
          'Романтика',
          'Для свидания или признания',
          Icons.favorite_outline,
        ),
        _QuizOption(
          'Благодарность',
          'Аккуратный жест внимания',
          Icons.handshake_outlined,
        ),
        _QuizOption(
          'Извинение',
          'Мягкий и деликатный вариант',
          Icons.mark_email_read_outlined,
        ),
        _QuizOption('Юбилей', 'Торжественно и статусно', Icons.stars_rounded),
        _QuizOption('Без повода', 'Просто порадовать', Icons.wb_sunny_outlined),
      ],
    ),
    _QuizStepConfig(
      title: 'Какой бюджет вам комфортен?',
      subtitle:
      'Подберём варианты, которые красиво смотрятся в вашем диапазоне.',
      icon: Icons.payments_outlined,
      options: const [
        _QuizOption('До 2500 ₽', 'Компактно и со вкусом', Icons.wallet_giftcard),
        _QuizOption(
          '2500–4000 ₽',
          'Оптимальный баланс',
          Icons.account_balance_wallet_outlined,
        ),
        _QuizOption(
          '4000–6000 ₽',
          'Более выразительный вариант',
          Icons.diamond_outlined,
        ),
        _QuizOption(
          '6000+ ₽',
          'Премиальный уровень',
          Icons.workspace_premium_outlined,
        ),
      ],
    ),
    _QuizStepConfig(
      title: 'Какое настроение должен передавать букет?',
      subtitle: 'Так подбор станет более точным и живым.',
      icon: Icons.auto_awesome_outlined,
      options: const [
        _QuizOption('Нежный', 'Лёгкий, мягкий, воздушный', Icons.spa_outlined),
        _QuizOption(
          'Романтичный',
          'Чувственный и тёплый',
          Icons.favorite_border,
        ),
        _QuizOption('Яркий', 'Эффектный и эмоциональный', Icons.flash_on_outlined),
        _QuizOption(
          'Элегантный',
          'Аккуратный и стильный',
          Icons.emoji_events_outlined,
        ),
        _QuizOption('Строгий', 'Сдержанный и собранный', Icons.checkroom_outlined),
      ],
    ),
    _QuizStepConfig(
      title: 'Какая палитра вам ближе?',
      subtitle: 'Даже общий цветовой ориентир сильно улучшает рекомендацию.',
      icon: Icons.palette_outlined,
      options: const [
        _QuizOption(
          'Пастельная',
          'Пудровые и спокойные оттенки',
          Icons.cloud_outlined,
        ),
        _QuizOption('Белая', 'Чисто и элегантно', Icons.circle_outlined),
        _QuizOption(
          'Розовая',
          'Нежно и романтично',
          Icons.local_florist_outlined,
        ),
        _QuizOption(
          'Красная',
          'Страстно и выразительно',
          Icons.favorite_rounded,
        ),
        _QuizOption(
          'Яркий микс',
          'Сочно и празднично',
          Icons.color_lens_outlined,
        ),
      ],
    ),
    _QuizStepConfig(
      title: 'Какой формат букета нужен?',
      subtitle: 'Финальный штрих для точного подбора.',
      icon: Icons.view_in_ar_outlined,
      options: const [
        _QuizOption(
          'Компактный',
          'Аккуратный знак внимания',
          Icons.crop_square_outlined,
        ),
        _QuizOption('Средний', 'Универсальный формат', Icons.crop_5_4_outlined),
        _QuizOption(
          'Большой',
          'Чтобы произвести впечатление',
          Icons.crop_din_outlined,
        ),
      ],
    ),
  ];

  bool get _isResultStep => recommendation != null;

  void _nextStep() async {
    if (!_canMoveNext()) return;

    if (currentStep == steps.length - 1) {
      await _buildRecommendation();
      return;
    }

    setState(() {
      currentStep++;
    });
  }

  void _prevStep() {
    if (_isResultStep) {
      setState(() {
        recommendation = null;
        currentStep = steps.length - 1;
      });
      return;
    }

    if (currentStep == 0) {
      Get.back();
      return;
    }

    setState(() {
      currentStep--;
    });
  }

  void _goToHome() {
    Get.until((route) => route.isFirst);
  }

  bool _canMoveNext() {
    switch (currentStep) {
      case 0:
        return selectedRecipient != null;
      case 1:
        return selectedOccasion != null;
      case 2:
        return selectedBudget != null;
      case 3:
        return selectedMood != null;
      case 4:
        return selectedPalette != null;
      case 5:
        return selectedSize != null;
      default:
        return false;
    }
  }

  Future<void> _buildRecommendation() async {
    setState(() {
      isPreparing = true;
    });

    await Future.delayed(const Duration(milliseconds: 250));

    final result = BouquetRecommender.recommend(
      products: widget.products,
      recipient: selectedRecipient!,
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
      selectedOccasion = null;
      selectedBudget = null;
      selectedMood = null;
      selectedPalette = null;
      selectedSize = null;
      recommendation = null;
      isPreparing = false;
    });
  }

  String? _selectedValueForStep(int step) {
    switch (step) {
      case 0:
        return selectedRecipient;
      case 1:
        return selectedOccasion;
      case 2:
        return selectedBudget;
      case 3:
        return selectedMood;
      case 4:
        return selectedPalette;
      case 5:
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
          selectedOccasion = value;
          break;
        case 2:
          selectedBudget = value;
          break;
        case 3:
          selectedMood = value;
          break;
        case 4:
          selectedPalette = value;
          break;
        case 5:
          selectedSize = value;
          break;
      }
    });
  }

  void _openProductDetail(Product product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductDetail(
          product: product,
          cartController: cartController,
          authController: authController,
        ),
      ),
    );
  }

  Future<void> _handleAddToCart(Product product) async {
    if (!authController.isLoggedIn) {
      Get.snackbar(
        'Требуется вход',
        'Сначала войдите в аккаунт, чтобы добавить товар в корзину',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    await cartController.addToCart(product);

    Get.snackbar(
      'Добавлено',
      '${product.name} добавлен в корзину',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    final Color backgroundColor =
    isDark ? const Color(0xFF0F1115) : const Color(0xFFF7F7FB);
    final Color cardColor = isDark ? const Color(0xFF171A20) : Colors.white;
    final Color borderColor =
    isDark ? Colors.white.withOpacity(0.07) : Colors.black.withOpacity(0.06);
    final Color mutedText =
    isDark ? Colors.white70 : Colors.black.withOpacity(0.62);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: backgroundColor,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          onPressed: _prevStep,
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
        title: Text(
          _isResultStep ? 'Ваш подбор букета' : 'Подбор букета',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        actions: [
          if (_isResultStep || currentStep > 0)
            IconButton(
              onPressed: _restartQuiz,
              icon: const Icon(Icons.refresh_rounded),
            ),
        ],
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: _isResultStep
              ? _buildResultView(
            context: context,
            cardColor: cardColor,
            borderColor: borderColor,
            mutedText: mutedText,
          )
              : _buildQuizView(
            context: context,
            cardColor: cardColor,
            borderColor: borderColor,
            mutedText: mutedText,
          ),
        ),
      ),
      bottomNavigationBar: _isResultStep
          ? null
          : SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          decoration: BoxDecoration(
            color: backgroundColor,
            border: Border(
              top: BorderSide(color: borderColor),
            ),
          ),
          child: SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: isPreparing || !_canMoveNext() ? null : _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor:
                AppColors.primary.withOpacity(0.4),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: isPreparing
                  ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  valueColor:
                  AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
                  : Text(
                currentStep == steps.length - 1
                    ? 'Показать подбор'
                    : 'Далее',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuizView({
    required BuildContext context,
    required Color cardColor,
    required Color borderColor,
    required Color mutedText,
  }) {
    final step = steps[currentStep];
    final selectedValue = _selectedValueForStep(currentStep);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: _buildProgressSection(
            cardColor: cardColor,
            borderColor: borderColor,
            mutedText: mutedText,
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(step.icon, color: AppColors.primary),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      step.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      step.subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: mutedText,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              ...step.options.map(
                    (option) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _OptionCard(
                    title: option.title,
                    subtitle: option.subtitle,
                    icon: option.icon,
                    isSelected: selectedValue == option.title,
                    onTap: () => _selectValueForStep(currentStep, option.title),
                    cardColor: cardColor,
                    borderColor: borderColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProgressSection({
    required Color cardColor,
    required Color borderColor,
    required Color mutedText,
  }) {
    final double progress = (currentStep + 1) / steps.length;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Шаг ${currentStep + 1} из ${steps.length}',
            style: TextStyle(
              color: mutedText,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AppColors.primary.withOpacity(0.12),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultView({
    required BuildContext context,
    required Color cardColor,
    required Color borderColor,
    required Color mutedText,
  }) {
    final BouquetRecommendationResult result = recommendation!;
    final List<dynamic> mainProducts = result.products;
    final List<dynamic> alternatives = result.alternativeProducts;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(result.moodEmoji, style: const TextStyle(fontSize: 34)),
              const SizedBox(height: 14),
              Text(
                result.title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                result.subtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: mutedText,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 16),
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
                      color: AppColors.primary.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      chip,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                )
                    .toList(),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white.withOpacity(0.03)
                      : Colors.black.withOpacity(0.025),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.tips_and_updates_outlined,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        result.explanation,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          height: 1.45,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Лучшее совпадение',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        ...mainProducts.map(
              (product) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _ProductResultCard(
              product: product,
              cardColor: cardColor,
              borderColor: borderColor,
              mutedText: mutedText,
              cartController: cartController,
              authController: authController,
              onOpenDetails: _openProductDetail,
              onAddToCart: _handleAddToCart,
            ),
          ),
        ),
        if (alternatives.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            'Альтернативные варианты',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          ...alternatives.map(
                (product) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ProductResultCard(
                product: product,
                cardColor: cardColor,
                borderColor: borderColor,
                mutedText: mutedText,
                compact: true,
                cartController: cartController,
                authController: authController,
                onOpenDetails: _openProductDetail,
                onAddToCart: _handleAddToCart,
              ),
            ),
          ),
        ],
        const SizedBox(height: 8),
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

  const _QuizOption(this.title, this.subtitle, this.icon);
}

class _OptionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final Color cardColor;
  final Color borderColor;

  const _OptionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    required this.cardColor,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary.withOpacity(0.10) : cardColor,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isSelected ? AppColors.primary : borderColor,
              width: isSelected ? 1.4 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withOpacity(0.14)
                      : AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: AppColors.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  border: Border.all(
                    color: isSelected ? AppColors.primary : borderColor,
                  ),
                ),
                child: isSelected
                    ? const Icon(
                  Icons.check_rounded,
                  size: 16,
                  color: Colors.white,
                )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductResultCard extends StatelessWidget {
  final dynamic product;
  final Color cardColor;
  final Color borderColor;
  final Color mutedText;
  final bool compact;
  final CartController cartController;
  final AuthController authController;
  final void Function(Product product) onOpenDetails;
  final Future<void> Function(Product product) onAddToCart;

  const _ProductResultCard({
    required this.product,
    required this.cardColor,
    required this.borderColor,
    required this.mutedText,
    required this.cartController,
    required this.authController,
    required this.onOpenDetails,
    required this.onAddToCart,
    this.compact = false,
  });

  Product? _asProduct() {
    if (product is Product) return product as Product;
    return null;
  }

  String _readName() {
    try {
      if (product is Product) return product.name;
      return (product.name ?? '').toString();
    } catch (_) {
      return '';
    }
  }

  String _readDescription() {
    try {
      if (product is Product) return product.description;
      return (product.description ?? '').toString();
    } catch (_) {
      return '';
    }
  }

  String _readCategory() {
    try {
      if (product is Product) return product.categoryName;
      return (product.categoryName ?? '').toString();
    } catch (_) {
      return '';
    }
  }

  String _readImageUrl() {
    try {
      if (product is Product) return product.imageUrl;
      return (product.imageUrl ?? '').toString();
    } catch (_) {
      return '';
    }
  }

  double _readPrice() {
    try {
      if (product is Product) return product.price;
      final value = product.price;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString()) ?? 0;
    } catch (_) {
      return 0;
    }
  }

  double _readRating() {
    try {
      if (product is Product) return product.rating;
      final value = product.rating;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString()) ?? 0;
    } catch (_) {
      return 0;
    }
  }

  bool _readInStock() {
    try {
      if (product is Product) return product.inStock;
      return product.inStock == true;
    } catch (_) {
      return true;
    }
  }

  bool _canUseCart(Product? product) {
    if (product == null) return false;
    try {
      return product.id != null;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final Product? typedProduct = _asProduct();
    final bool canUseCart = _canUseCart(typedProduct);
    final String imageUrl = _readImageUrl();
    final String description = _readDescription();
    final String category = _readCategory();
    final bool inStock = _readInStock();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: typedProduct == null ? null : () => onOpenDetails(typedProduct),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: SizedBox(
                      width: compact ? 92 : 104,
                      height: compact ? 92 : 104,
                      child: imageUrl.isNotEmpty
                          ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: AppColors.primary.withOpacity(0.08),
                          child: const Icon(
                            Icons.local_florist,
                            color: AppColors.primary,
                            size: 34,
                          ),
                        ),
                      )
                          : Container(
                        color: AppColors.primary.withOpacity(0.08),
                        child: const Icon(
                          Icons.local_florist,
                          color: AppColors.primary,
                          size: 34,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (category.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.10),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              category,
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        if (category.isNotEmpty) const SizedBox(height: 10),
                        Text(
                          _readName().isEmpty ? 'Букет' : _readName(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          description.isEmpty
                              ? 'Красивый вариант для вашего запроса.'
                              : description,
                          maxLines: compact ? 2 : 3,
                          overflow: TextOverflow.ellipsis,
                          style:
                          Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: mutedText,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Text(
                              '${_readPrice().toStringAsFixed(0)} ₽',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                              ),
                            ),
                            const Spacer(),
                            const Icon(
                              Icons.star_rounded,
                              size: 18,
                              color: Colors.amber,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _readRating().toStringAsFixed(1),
                              style:
                              const TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SizedBox(
                      width: canUseCart ? 150 : double.infinity,
                      height: 44,
                      child: OutlinedButton(
                        onPressed: typedProduct == null
                            ? null
                            : () => onOpenDetails(typedProduct),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: borderColor),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Подробнее',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    if (typedProduct != null && canUseCart)
                      _CartActionBlock(
                        product: typedProduct,
                        inStock: inStock,
                        cartController: cartController,
                        onAddToCart: onAddToCart,
                        borderColor: borderColor,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CartActionBlock extends StatelessWidget {
  final Product product;
  final bool inStock;
  final CartController cartController;
  final Future<void> Function(Product product) onAddToCart;
  final Color borderColor;

  const _CartActionBlock({
    required this.product,
    required this.inStock,
    required this.cartController,
    required this.onAddToCart,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      bool inCart = false;
      int qty = 0;

      try {
        inCart = cartController.isInCart(product);
        qty = cartController.getQuantity(product);
      } catch (_) {
        inCart = false;
        qty = 0;
      }

      if (!inCart) {
        return SizedBox(
          width: 140,
          height: 44,
          child: ElevatedButton(
            onPressed: !inStock ? null : () => onAddToCart(product),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.primary.withOpacity(0.35),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              'В корзину',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        );
      }

      return Container(
        width: 140,
        height: 44,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _QtyButton(
              icon: Icons.remove,
              onTap: () {
                try {
                  cartController.decrement(product);
                } catch (_) {}
              },
            ),
            Text(
              '$qty',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
            _QtyButton(
              icon: Icons.add,
              onTap: () {
                try {
                  cartController.increment(product);
                } catch (_) {}
              },
            ),
          ],
        ),
      );
    });
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _QtyButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: SizedBox(
        width: 32,
        height: 44,
        child: Icon(
          icon,
          size: 18,
          color: AppColors.primary,
        ),
      ),
    );
  }
}
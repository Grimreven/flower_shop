import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../helpers/bouquet_recommender.dart';
import '../../utils/app_colors.dart';

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
  int currentStep = 0;
  bool isPreparing = false;

  String? selectedRecipient;
  String? selectedOccasion;
  String? selectedBudget;
  String? selectedStyle;

  BouquetRecommendationResult? recommendation;

  final List<String> recipients = const [
    'Девушке',
    'Маме',
    'Коллеге',
  ];

  final List<String> occasions = const [
    'День рождения',
    'Романтика',
    'Спасибо',
  ];

  final List<String> budgets = const [
    'до 2000 ₽',
    '2000–5000 ₽',
    '5000+ ₽',
  ];

  final List<String> styles = const [
    'Нежный',
    'Яркий',
    'Минимализм',
  ];

  void _nextStep() {
    if (!_canMoveNext()) {
      return;
    }

    if (currentStep < 3) {
      setState(() {
        currentStep++;
      });
      return;
    }

    _buildRecommendation();
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
        return selectedStyle != null;
      default:
        return false;
    }
  }

  void _previousStep() {
    if (isPreparing) {
      return;
    }

    if (recommendation != null) {
      setState(() {
        recommendation = null;
        currentStep = 0;
      });
      return;
    }

    if (currentStep > 0) {
      setState(() {
        currentStep--;
      });
    } else {
      Get.back();
    }
  }

  Future<void> _buildRecommendation() async {
    setState(() {
      isPreparing = true;
    });

    await Future<void>.delayed(const Duration(milliseconds: 1300));

    final BouquetRecommendationResult result = BouquetRecommender.recommend(
      products: widget.products,
      recipient: selectedRecipient!,
      occasion: selectedOccasion!,
      budget: selectedBudget!,
      style: selectedStyle!,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      recommendation = result;
      isPreparing = false;
    });
  }

  void _resetQuiz() {
    setState(() {
      currentStep = 0;
      selectedRecipient = null;
      selectedOccasion = null;
      selectedBudget = null;
      selectedStyle = null;
      recommendation = null;
      isPreparing = false;
    });
  }

  String _titleForStep() {
    switch (currentStep) {
      case 0:
        return 'Кому подбираем букет?';
      case 1:
        return 'По какому поводу?';
      case 2:
        return 'Какой бюджет?';
      case 3:
        return 'Какой стиль вам ближе?';
      default:
        return 'Подбор букета';
    }
  }

  String _subtitleForStep() {
    switch (currentStep) {
      case 0:
        return 'Выберите получателя, чтобы точнее определить настроение композиции.';
      case 1:
        return 'Повод влияет на цветовую палитру и характер букета.';
      case 2:
        return 'Мы подберём варианты под ваш диапазон цены.';
      case 3:
        return 'Последний шаг — визуальное настроение букета.';
      default:
        return '';
    }
  }

  List<String> _optionsForStep() {
    switch (currentStep) {
      case 0:
        return recipients;
      case 1:
        return occasions;
      case 2:
        return budgets;
      case 3:
        return styles;
      default:
        return const [];
    }
  }

  String? _selectedValueForStep() {
    switch (currentStep) {
      case 0:
        return selectedRecipient;
      case 1:
        return selectedOccasion;
      case 2:
        return selectedBudget;
      case 3:
        return selectedStyle;
      default:
        return null;
    }
  }

  void _selectValue(String value) {
    setState(() {
      switch (currentStep) {
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
          selectedStyle = value;
          break;
      }
    });
  }

  String _productName(dynamic product) {
    try {
      return (product.name ?? '').toString();
    } catch (_) {
      return 'Букет';
    }
  }

  String _productImage(dynamic product) {
    try {
      return (product.imageUrl ?? '').toString();
    } catch (_) {
      return '';
    }
  }

  double _productPrice(dynamic product) {
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

  String _productCategory(dynamic product) {
    try {
      return (product.categoryName ?? '').toString();
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bg = Theme.of(context).scaffoldBackgroundColor;
    final Color cardColor = Theme.of(context).cardColor;
    final Color onSurface = Theme.of(context).colorScheme.onSurface;
    final Color muted = isDark
        ? AppColors.darkMutedForeground
        : AppColors.mutedForeground;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Text(
          recommendation == null ? 'Умный букет' : 'Ваш идеальный букет',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: onSurface,
          ),
        ),
        leading: IconButton(
          onPressed: _previousStep,
          icon: Icon(
            Icons.arrow_back_rounded,
            color: onSurface,
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? const LinearGradient(
            colors: [
              AppColors.darkBackground,
              AppColors.darkBackgroundSecondary,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          )
              : null,
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          child: isPreparing
              ? _PreparingView(isDark: isDark)
              : recommendation == null
              ? SingleChildScrollView(
            key: const ValueKey('quiz'),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HeroCard(
                  title: 'Подберём букет за 30 секунд',
                  subtitle:
                  'Ответьте на 4 вопроса, и приложение предложит лучшие варианты именно под ваш запрос.',
                  badge: 'AI-подбор 💐',
                  isDark: isDark,
                ),
                const SizedBox(height: 16),
                _ProgressCard(
                  currentStep: currentStep,
                  isDark: isDark,
                ),
                const SizedBox(height: 18),
                _QuestionCard(
                  title: _titleForStep(),
                  subtitle: _subtitleForStep(),
                  options: _optionsForStep(),
                  selectedValue: _selectedValueForStep(),
                  onSelect: _selectValue,
                  isDark: isDark,
                  cardColor: cardColor,
                  onSurface: onSurface,
                  muted: muted,
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _resetQuiz,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: isDark
                              ? AppColors.purpleLight
                              : AppColors.primary,
                          side: BorderSide(
                            color: isDark
                                ? AppColors.darkBorder
                                : AppColors.border,
                          ),
                          minimumSize: const Size.fromHeight(54),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: const Text('Сбросить'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: isDark
                              ? AppColors.darkBrandGradient
                              : AppColors.brandGradient,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: (isDark
                                  ? AppColors.purple
                                  : AppColors.primary)
                                  .withValues(alpha: 0.18),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _canMoveNext() ? _nextStep : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: Colors.transparent,
                            disabledForegroundColor:
                            Colors.white.withValues(alpha: 0.65),
                            minimumSize: const Size.fromHeight(54),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                              BorderRadius.circular(18),
                            ),
                          ),
                          child: Text(
                            currentStep == 3
                                ? 'Подобрать букет'
                                : 'Далее',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          )
              : SingleChildScrollView(
            key: const ValueKey('result'),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ResultHeroCard(
                  result: recommendation!,
                  recipient: selectedRecipient!,
                  occasion: selectedOccasion!,
                  style: selectedStyle!,
                  budget: selectedBudget!,
                  isDark: isDark,
                ),
                const SizedBox(height: 18),
                if (recommendation!.products.isEmpty)
                  _EmptyResultCard(
                    isDark: isDark,
                    onReset: _resetQuiz,
                  )
                else
                  Column(
                    children: recommendation!.products.map((product) {
                      return _RecommendedProductCard(
                        product: product,
                        name: _productName(product),
                        imageUrl: _productImage(product),
                        price: _productPrice(product),
                        category: _productCategory(product),
                        isDark: isDark,
                        onPick: () {
                          Get.back(result: product);
                        },
                      );
                    }).toList(),
                  ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _resetQuiz,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: isDark
                              ? AppColors.purpleLight
                              : AppColors.primary,
                          side: BorderSide(
                            color: isDark
                                ? AppColors.darkBorder
                                : AppColors.border,
                          ),
                          minimumSize: const Size.fromHeight(54),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: const Text('Собрать заново'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: isDark
                              ? AppColors.darkBrandGradient
                              : AppColors.brandGradient,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: ElevatedButton(
                          onPressed: () {
                            if (recommendation!.products.isNotEmpty) {
                              Get.back(
                                result: recommendation!.products.first,
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(54),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                              BorderRadius.circular(18),
                            ),
                          ),
                          child: const Text('Выбрать лучший'),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String badge;
  final bool isDark;

  const _HeroCard({
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: isDark ? AppColors.darkBrandGradient : AppColors.brandGradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: (isDark ? AppColors.purple : AppColors.primary)
                .withValues(alpha: 0.25),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              badge,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 26,
              height: 1.15,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 15,
              height: 1.45,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  final int currentStep;
  final bool isDark;

  const _ProgressCard({
    required this.currentStep,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final double progress = (currentStep + 1) / 4;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: isDark ? AppColors.darkCardGradient : null,
        color: isDark ? null : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Шаг ${currentStep + 1} из 4',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: isDark
                  ? AppColors.darkBorderSoft
                  : AppColors.primaryLight.withValues(alpha: 0.45),
              valueColor: AlwaysStoppedAnimation<Color>(
                isDark ? AppColors.purpleLight : AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<String> options;
  final String? selectedValue;
  final void Function(String value) onSelect;
  final bool isDark;
  final Color cardColor;
  final Color onSurface;
  final Color muted;

  const _QuestionCard({
    required this.title,
    required this.subtitle,
    required this.options,
    required this.selectedValue,
    required this.onSelect,
    required this.isDark,
    required this.cardColor,
    required this.onSurface,
    required this.muted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: isDark ? AppColors.darkCardGradient : null,
        color: isDark ? null : cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? AppColors.purple.withValues(alpha: 0.05)
                : AppColors.shadow,
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              color: muted,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          ...options.map((option) {
            final bool selected = selectedValue == option;

            return GestureDetector(
              onTap: () => onSelect(option),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: selected
                      ? (isDark
                      ? AppColors.darkBrandGradient
                      : AppColors.brandGradient)
                      : null,
                  color: selected
                      ? null
                      : (isDark
                      ? AppColors.darkSurfaceElevated
                      : AppColors.primaryLight.withValues(alpha: 0.30)),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: selected
                        ? Colors.transparent
                        : (isDark ? AppColors.darkBorder : AppColors.border),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        option,
                        style: TextStyle(
                          color: selected ? Colors.white : onSurface,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    Icon(
                      selected
                          ? Icons.check_circle_rounded
                          : Icons.circle_outlined,
                      color: selected
                          ? Colors.white
                          : (isDark
                          ? AppColors.purpleLight
                          : AppColors.primary),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _PreparingView extends StatelessWidget {
  final bool isDark;

  const _PreparingView({
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(26),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: isDark ? AppColors.darkCardGradient : null,
            color: isDark ? null : Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.border,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 86,
                height: 86,
                decoration: BoxDecoration(
                  gradient:
                  isDark ? AppColors.darkBrandGradient : AppColors.brandGradient,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.local_florist_rounded,
                  color: Colors.white,
                  size: 42,
                ),
              ),
              const SizedBox(height: 22),
              Text(
                'Собираем для вас идеальный букет...',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Учитываем настроение, повод и ваш бюджет',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark
                      ? AppColors.darkMutedForeground
                      : AppColors.mutedForeground,
                ),
              ),
              const SizedBox(height: 18),
              CircularProgressIndicator(
                color: isDark ? AppColors.purple : AppColors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultHeroCard extends StatelessWidget {
  final BouquetRecommendationResult result;
  final String recipient;
  final String occasion;
  final String style;
  final String budget;
  final bool isDark;

  const _ResultHeroCard({
    required this.result,
    required this.recipient,
    required this.occasion,
    required this.style,
    required this.budget,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: isDark ? AppColors.darkBrandGradient : AppColors.brandGradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: (isDark ? AppColors.purple : AppColors.primary)
                .withValues(alpha: 0.25),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${result.moodEmoji} Мы подобрали идеальный букет',
            style: const TextStyle(
              fontSize: 26,
              height: 1.15,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            result.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$occasion • $style • $budget',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ResultTag(label: recipient),
              _ResultTag(label: occasion),
              _ResultTag(label: style),
            ],
          ),
        ],
      ),
    );
  }
}

class _ResultTag extends StatelessWidget {
  final String label;

  const _ResultTag({
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _RecommendedProductCard extends StatelessWidget {
  final dynamic product;
  final String name;
  final String imageUrl;
  final double price;
  final String category;
  final bool isDark;
  final VoidCallback onPick;

  const _RecommendedProductCard({
    required this.product,
    required this.name,
    required this.imageUrl,
    required this.price,
    required this.category,
    required this.isDark,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final Color onSurface = Theme.of(context).colorScheme.onSurface;
    final Color muted = isDark
        ? AppColors.darkMutedForeground
        : AppColors.mutedForeground;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: isDark ? AppColors.darkCardGradient : null,
        color: isDark ? null : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? AppColors.purple.withValues(alpha: 0.05)
                : AppColors.shadow,
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(24),
            ),
            child: AspectRatio(
              aspectRatio: 16 / 10,
              child: imageUrl.isNotEmpty
                  ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _ImagePlaceholder(
                  isDark: isDark,
                ),
              )
                  : _ImagePlaceholder(isDark: isDark),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
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
                      color: isDark
                          ? AppColors.darkSurfaceElevated
                          : AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      category,
                      style: TextStyle(
                        color: isDark
                            ? AppColors.purpleLight
                            : AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                if (category.isNotEmpty) const SizedBox(height: 12),
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Подходит под выбранный стиль и повод',
                  style: TextStyle(
                    color: muted,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    ShaderMask(
                      shaderCallback: (Rect bounds) => (isDark
                          ? AppColors.darkBrandGradient
                          : AppColors.brandGradient)
                          .createShader(bounds),
                      child: Text(
                        '${price.toStringAsFixed(0)} ₽',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const Spacer(),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: isDark
                            ? AppColors.darkBrandGradient
                            : AppColors.brandGradient,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ElevatedButton(
                        onPressed: onPick,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text('Выбрать'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  final bool isDark;

  const _ImagePlaceholder({
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: isDark ? AppColors.darkSurfaceElevated : AppColors.primaryLight,
      child: Center(
        child: Icon(
          Icons.local_florist_rounded,
          size: 48,
          color: isDark ? AppColors.purpleLight : AppColors.primary,
        ),
      ),
    );
  }
}

class _EmptyResultCard extends StatelessWidget {
  final bool isDark;
  final VoidCallback onReset;

  const _EmptyResultCard({
    required this.isDark,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final Color onSurface = Theme.of(context).colorScheme.onSurface;
    final Color muted = isDark
        ? AppColors.darkMutedForeground
        : AppColors.mutedForeground;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: isDark ? AppColors.darkCardGradient : null,
        color: isDark ? null : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.border,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 56,
            color: isDark ? AppColors.purpleLight : AppColors.primary,
          ),
          const SizedBox(height: 12),
          Text(
            'Подходящие букеты не найдены',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Попробуйте изменить бюджет или стиль — тогда мы покажем больше вариантов.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: muted,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: onReset,
            style: OutlinedButton.styleFrom(
              foregroundColor:
              isDark ? AppColors.purpleLight : AppColors.primary,
              side: BorderSide(
                color: isDark ? AppColors.darkBorder : AppColors.border,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text('Изменить ответы'),
          ),
        ],
      ),
    );
  }
}
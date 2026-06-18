import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../api/server_api_service.dart';
import '../controllers/auth_controller.dart';
import '../controllers/cart_controller.dart';
import '../models/product.dart';
import '../utils/app_colors.dart';
import 'app_auth_required_dialog.dart';

class ProductDetail extends StatefulWidget {
  final Product product;
  final CartController cartController;
  final AuthController authController;

  const ProductDetail({
    super.key,
    required this.product,
    required this.cartController,
    required this.authController,
  });

  @override
  State<ProductDetail> createState() => _ProductDetailState();
}

class _ProductDetailState extends State<ProductDetail> {
  bool isLoadingPriceHistory = true;
  List<Map<String, dynamic>> priceHistory = [];

  @override
  void initState() {
    super.initState();
    loadPriceHistory();
  }

  Future<void> loadPriceHistory() async {
    try {
      final List<Map<String, dynamic>> data =
      await ServerApiService.getPriceHistory(widget.product.id);

      if (!mounted) {
        return;
      }

      setState(() {
        priceHistory = data;
        isLoadingPriceHistory = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        priceHistory = [];
        isLoadingPriceHistory = false;
      });
    }
  }

  Future<void> _handleAddToCart(BuildContext context) async {
    final bool isLoggedIn =
        widget.authController.isLoggedIn || widget.authController.token.isNotEmpty;

    if (!isLoggedIn) {
      await AppAuthRequiredDialog.show(
        context,
        title: 'Требуется вход',
        message:
        'Чтобы добавить товар в корзину, пожалуйста, авторизуйтесь или зарегистрируйтесь.',
        confirmText: 'Войти',
      );
      return;
    }

    await widget.cartController.addToCart(widget.product);

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${widget.product.name} добавлен в корзину'),
      ),
    );
  }

  Widget _ratingStars(double rating, bool isDark) {
    final int fullStars = rating.floor().clamp(0, 5);
    final bool hasHalfStar = (rating - fullStars) >= 0.5;

    return Row(
      children: [
        ...List.generate(
          fullStars,
              (_) => Icon(
            Icons.star_rounded,
            size: 20,
            color: isDark ? AppColors.purpleLight : Colors.amber,
          ),
        ),
        if (hasHalfStar)
          Icon(
            Icons.star_half_rounded,
            size: 20,
            color: isDark ? AppColors.purpleLight : Colors.amber,
          ),
      ],
    );
  }

  double _toDouble(dynamic value) {
    if (value == null) {
      return 0;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString()) ?? 0;
  }

  DateTime? _toDate(dynamic value) {
    if (value == null) {
      return null;
    }

    return DateTime.tryParse(value.toString());
  }

  String _formatDate(dynamic value) {
    final DateTime? date = _toDate(value);

    if (date == null) {
      return '';
    }

    final String day = date.day.toString().padLeft(2, '0');
    final String month = date.month.toString().padLeft(2, '0');

    return '$day.$month.${date.year}';
  }

  List<Map<String, dynamic>> get _preparedHistory {
    final List<Map<String, dynamic>> result = priceHistory.map((item) {
      final double price = _toDouble(
        item['price'] ?? item['new_price'] ?? item['newPrice'],
      );

      return {
        ...item,
        'price': price,
      };
    }).where((item) {
      return _toDouble(item['price']) > 0;
    }).toList();

    if (result.isEmpty) {
      return result;
    }

    final double lastPrice = _toDouble(result.last['price']);

    if (lastPrice != widget.product.price) {
      result.add({
        'old_price': lastPrice,
        'new_price': widget.product.price,
        'price': widget.product.price,
        'changed_at': DateTime.now().toIso8601String(),
      });
    }

    return result;
  }

  Widget _card({
    required BuildContext context,
    required Widget child,
    EdgeInsets padding = const EdgeInsets.all(18),
  }) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color surface = Theme.of(context).cardColor;

    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        gradient: isDark ? AppColors.darkCardGradient : null,
        color: isDark ? null : surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.border,
        ),
        boxShadow: [
          BoxShadow(
            color:
            isDark ? AppColors.purple.withValues(alpha: 0.05) : AppColors.shadow,
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _infoPill({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color onSurface = Theme.of(context).colorScheme.onSurface;
    final Color muted =
    isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.darkSurfaceElevated
              : AppColors.primaryLight.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : Colors.transparent,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isDark ? AppColors.purpleLight : AppColors.primary,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: onSurface,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: muted,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _priceHistoryCard(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color onSurface = Theme.of(context).colorScheme.onSurface;
    final Color muted =
    isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
    final Color primary = isDark ? AppColors.purpleLight : AppColors.primary;

    if (isLoadingPriceHistory) {
      return _card(
        context: context,
        child: const SizedBox(
          height: 130,
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    final List<Map<String, dynamic>> history = _preparedHistory;

    if (history.isEmpty) {
      return _card(
        context: context,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.show_chart_rounded,
                  color: primary,
                ),
                const SizedBox(width: 10),
                Text(
                  'Динамика цены',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              'История изменения цены пока отсутствует.\n'
                  'Она появится после изменения стоимости товара в админ-панели.',
              style: TextStyle(
                color: muted,
                height: 1.45,
              ),
            ),
          ],
        ),
      );
    }

    final List<FlSpot> spots = List.generate(
      history.length,
          (int index) {
        return FlSpot(
          index.toDouble(),
          _toDouble(history[index]['price']),
        );
      },
    );

    final List<double> prices = history
        .map((Map<String, dynamic> item) => _toDouble(item['price']))
        .toList();

    final double minPrice = prices.reduce((a, b) => a < b ? a : b);
    final double maxPrice = prices.reduce((a, b) => a > b ? a : b);
    final double diff = (maxPrice - minPrice).abs();
    final double padding = diff == 0 ? maxPrice * 0.08 : diff * 0.25;
    final double minY = (minPrice - padding).clamp(0, double.infinity);
    final double maxY = maxPrice + padding;

    final double firstPrice = prices.first;
    final double lastPrice = prices.last;
    final double change = lastPrice - firstPrice;

    final bool isIncrease = change > 0;
    final bool isDecrease = change < 0;

    String changeText;

    if (isIncrease) {
      changeText = '+${change.toStringAsFixed(0)} ₽';
    } else if (isDecrease) {
      changeText = '${change.toStringAsFixed(0)} ₽';
    } else {
      changeText = 'без изменений';
    }

    return _card(
      context: context,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient:
                  isDark ? AppColors.darkBrandGradient : AppColors.brandGradient,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.trending_up_rounded,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Динамика цены',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'История изменений из админ-панели',
                      style: TextStyle(
                        color: muted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: isIncrease
                      ? AppColors.danger.withValues(alpha: 0.12)
                      : isDecrease
                      ? AppColors.success.withValues(alpha: 0.12)
                      : primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  changeText,
                  style: TextStyle(
                    color: isIncrease
                        ? AppColors.danger
                        : isDecrease
                        ? AppColors.success
                        : primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 210,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: spots.length > 1 ? (spots.length - 1).toDouble() : 1,
                minY: minY,
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (double value) {
                    return FlLine(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : Colors.black.withValues(alpha: 0.06),
                      strokeWidth: 1,
                    );
                  },
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 52,
                      interval: ((maxY - minY) / 3).clamp(100, double.infinity),
                      getTitlesWidget: (double value, TitleMeta meta) {
                        if (value == minY || value == maxY) {
                          return const SizedBox.shrink();
                        }

                        return Text(
                          value.toInt().toString(),
                          style: TextStyle(
                            color: muted,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 34,
                      interval: 1,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        final int index = value.toInt();

                        if (index < 0 || index >= history.length) {
                          return const SizedBox.shrink();
                        }

                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            _formatDate(history[index]['changed_at']),
                            style: TextStyle(
                              color: muted,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    barWidth: 4,
                    isStrokeCapRound: true,
                    color: primary,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (
                          FlSpot spot,
                          double percent,
                          LineChartBarData barData,
                          int index,
                          ) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: primary,
                          strokeWidth: 3,
                          strokeColor: isDark ? AppColors.darkSurface : Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          primary.withValues(alpha: 0.22),
                          primary.withValues(alpha: 0.02),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    tooltipRoundedRadius: 14,
                    getTooltipItems: (List<LineBarSpot> touchedSpots) {
                      return touchedSpots.map((LineBarSpot spot) {
                        final int index = spot.x.toInt();
                        final String date = index >= 0 && index < history.length
                            ? _formatDate(history[index]['changed_at'])
                            : '';

                        return LineTooltipItem(
                          '${spot.y.toStringAsFixed(0)} ₽\n$date',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Divider(
            color: isDark ? AppColors.darkBorder : AppColors.border,
          ),
          const SizedBox(height: 8),
          ...history.reversed.take(3).map(
                (Map<String, dynamic> item) {
              final double oldPrice = _toDouble(item['old_price']);
              final double newPrice = _toDouble(item['new_price'] ?? item['price']);

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.history_rounded,
                      size: 18,
                      color: muted,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _formatDate(item['changed_at']),
                        style: TextStyle(
                          color: muted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (oldPrice > 0) ...[
                      Text(
                        '${oldPrice.toStringAsFixed(0)} ₽',
                        style: TextStyle(
                          color: muted,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      '${newPrice.toStringAsFixed(0)} ₽',
                      style: TextStyle(
                        color: primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStockCard(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color onSurface = Theme.of(context).colorScheme.onSurface;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkSurfaceElevated
            : AppColors.primaryLight.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : Colors.transparent,
        ),
      ),
      child: Row(
        children: [
          Icon(
            widget.product.inStock
                ? Icons.check_circle_rounded
                : Icons.remove_circle_rounded,
            color: widget.product.inStock ? AppColors.success : AppColors.danger,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              widget.product.inStock
                  ? 'Товар в наличии и доступен для заказа'
                  : 'Сейчас нет в наличии',
              style: TextStyle(
                color: onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _addToCartButton(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: isDark ? AppColors.darkBrandGradient : AppColors.brandGradient,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: (isDark ? AppColors.purple : AppColors.primary)
                .withValues(alpha: 0.18),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: widget.product.inStock ? () => _handleAddToCart(context) : null,
        icon: const Icon(Icons.shopping_bag_outlined),
        label: const Text('Добавить в корзину'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.transparent,
          disabledForegroundColor: Colors.white.withValues(alpha: 0.6),
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bg = Theme.of(context).scaffoldBackgroundColor;
    final Color onSurface = Theme.of(context).colorScheme.onSurface;
    final Color muted =
    isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;

    return Scaffold(
      backgroundColor: bg,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 380,
            pinned: true,
            automaticallyImplyLeading: false,
            backgroundColor: bg,
            foregroundColor: onSurface,
            leading: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: CircleAvatar(
                backgroundColor: Colors.black.withValues(alpha: 0.35),
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    if (Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    } else {
                      Get.back();
                    }
                  },
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: 'product_${widget.product.id}',
                    child: Image.network(
                      widget.product.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: isDark
                            ? AppColors.darkSurfaceElevated
                            : AppColors.primaryLight,
                        child: Icon(
                          Icons.local_florist_rounded,
                          size: 72,
                          color: isDark ? AppColors.purpleLight : AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withValues(alpha: 0.05),
                          Colors.black.withValues(alpha: 0.25),
                          Colors.black.withValues(alpha: 0.65),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 18,
                    right: 18,
                    bottom: 34,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (widget.product.categoryName.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.22),
                              ),
                            ),
                            child: Text(
                              widget.product.categoryName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        const SizedBox(height: 12),
                        Text(
                          widget.product.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            height: 1.05,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              transform: Matrix4.translationValues(0, -24, 0),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(30),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 20, 18, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              _ratingStars(widget.product.rating, isDark),
                              const SizedBox(width: 10),
                              Text(
                                widget.product.rating.toStringAsFixed(1),
                                style: TextStyle(
                                  color: muted,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (widget.product.reviewCount > 0) ...[
                                const SizedBox(width: 8),
                                Text(
                                  '(${widget.product.reviewCount})',
                                  style: TextStyle(
                                    color: muted,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        ShaderMask(
                          shaderCallback: (Rect bounds) =>
                              (isDark
                                  ? AppColors.darkBrandGradient
                                  : AppColors.brandGradient)
                                  .createShader(bounds),
                          child: Text(
                            '${widget.product.price.toStringAsFixed(0)} ₽',
                            style: const TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        _infoPill(
                          context: context,
                          icon: Icons.local_florist_rounded,
                          title: 'Свежие',
                          subtitle: 'букеты',
                        ),
                        const SizedBox(width: 10),
                        _infoPill(
                          context: context,
                          icon: Icons.delivery_dining_rounded,
                          title: 'Доставка',
                          subtitle: 'по городу',
                        ),
                        const SizedBox(width: 10),
                        _infoPill(
                          context: context,
                          icon: Icons.card_giftcard_rounded,
                          title: 'Бонусы',
                          subtitle: 'за заказ',
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _card(
                      context: context,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Описание',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: onSurface,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            widget.product.description,
                            style: TextStyle(
                              color: muted,
                              height: 1.55,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    _priceHistoryCard(context),
                    const SizedBox(height: 18),
                    _buildStockCard(context),
                    const SizedBox(height: 26),
                    _addToCartButton(context),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
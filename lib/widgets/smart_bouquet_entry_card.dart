import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../screens/bouquet/bouquet_quiz_screen.dart';
import '../utils/app_colors.dart';

class SmartBouquetEntryCard extends StatelessWidget {
  final List<dynamic> products;
  final void Function(dynamic selectedProduct)? onProductSelected;

  const SmartBouquetEntryCard({
    super.key,
    required this.products,
    this.onProductSelected,
  });

  Future<void> _openQuiz() async {
    final dynamic selected = await Get.to<dynamic>(
          () => BouquetQuizScreen(products: products),
    );

    if (selected != null && onProductSelected != null) {
      onProductSelected!(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: _openQuiz,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: isDark ? AppColors.darkBrandGradient : AppColors.brandGradient,
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: (isDark ? AppColors.purple : AppColors.primary)
                  .withValues(alpha: 0.22),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Умный букет',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Ответьте на 4 вопроса и получите идеальный букет под ваш запрос',
                    style: TextStyle(
                      color: Colors.white,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            const Icon(
              Icons.chevron_right_rounded,
              color: Colors.white,
              size: 30,
            ),
          ],
        ),
      ),
    );
  }
}
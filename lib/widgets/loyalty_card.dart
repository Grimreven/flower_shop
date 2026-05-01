import 'package:flutter/material.dart';

class LoyaltyCard extends StatelessWidget {
  final String level;
  final int points;
  final double totalSpent;
  final int nextLevelPoints;
  final String colorHex;
  final String nextLevelLabel;

  const LoyaltyCard({
    super.key,
    required this.level,
    required this.points,
    required this.totalSpent,
    required this.nextLevelPoints,
    required this.colorHex,
    this.nextLevelLabel = '',
  });

  Color _fallbackColor() {
    final String normalizedLevel = level.toLowerCase();

    if (normalizedLevel.contains('gold')) {
      return const Color(0xFFD4AF37);
    }

    if (normalizedLevel.contains('silver')) {
      return const Color(0xFFC0C0C0);
    }

    return const Color(0xFFCD7F32);
  }

  Color getColor(String hexColor) {
    String hex = hexColor.replaceAll('#', '').trim();

    if (hex.isEmpty) {
      return _fallbackColor();
    }

    if (hex.length == 6) {
      hex = 'FF$hex';
    }

    if (hex.length != 8) {
      return _fallbackColor();
    }

    return Color(int.tryParse(hex, radix: 16) ?? _fallbackColor().value);
  }

  String _cardTitle() {
    final String normalizedLevel = level.toLowerCase();

    if (normalizedLevel.contains('gold')) {
      return 'Gold карта';
    }

    if (normalizedLevel.contains('silver')) {
      return 'Silver карта';
    }

    return 'Bronze карта';
  }

  double _progressValue() {
    final String normalizedLevel = level.toLowerCase();

    if (normalizedLevel.contains('gold')) {
      return 1;
    }

    if (normalizedLevel.contains('silver')) {
      final double progress = (totalSpent - 5000) / (15000 - 5000);
      return progress.clamp(0.0, 1.0);
    }

    final double progress = totalSpent / 5000;
    return progress.clamp(0.0, 1.0);
  }

  String _nextLevelText() {
    final String normalizedLevel = level.toLowerCase();

    if (normalizedLevel.contains('gold')) {
      return 'Максимальный уровень программы лояльности достигнут';
    }

    final int remaining = (nextLevelPoints - totalSpent).ceil().clamp(
      0,
      1 << 30,
    );

    if (nextLevelLabel.trim().isNotEmpty) {
      return 'До уровня $nextLevelLabel: $remaining ₽ покупок';
    }

    return 'До следующего уровня: $remaining ₽ покупок';
  }

  String _earnPercentText() {
    final String normalizedLevel = level.toLowerCase();

    if (normalizedLevel.contains('gold')) {
      return 'Кэшбэк бонусами: 10%';
    }

    if (normalizedLevel.contains('silver')) {
      return 'Кэшбэк бонусами: 7%';
    }

    return 'Кэшбэк бонусами: 5%';
  }

  @override
  Widget build(BuildContext context) {
    final Color baseColor = getColor(colorHex);
    final double progress = _progressValue();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            baseColor,
            baseColor.withValues(alpha: 0.82),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: baseColor.withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _cardTitle(),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Доступно: $points бонусов',
            style: const TextStyle(
              fontSize: 17,
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _earnPercentText(),
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              color: Colors.white,
              backgroundColor: Colors.white30,
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _nextLevelText(),
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Всего покупок: ${totalSpent.toStringAsFixed(0)} ₽',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            '1 бонус = 1 ₽. Бонусами можно оплатить до 30% суммы товаров.',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white70,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}
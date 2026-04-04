import 'package:flutter/material.dart';

class LoyaltyCard extends StatelessWidget {
  final String level;
  final int points;
  final double totalSpent;
  final int nextLevelPoints;
  final String colorHex;

  const LoyaltyCard({
    super.key,
    required this.level,
    required this.points,
    required this.totalSpent,
    required this.nextLevelPoints,
    required this.colorHex,
  });

  Color getColor(String hexColor) {
    String hex = hexColor.replaceAll('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }

  String get medal {
    switch (level.toLowerCase()) {
      case 'silver':
        return '🥈';
      case 'gold':
        return '🥇';
      default:
        return '🥉';
    }
  }

  @override
  Widget build(BuildContext context) {
    double progress = nextLevelPoints > 0 ? points / nextLevelPoints : 0;
    if (progress > 1) progress = 1;

    final baseColor = getColor(colorHex);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            baseColor,
            baseColor.withOpacity(0.82),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: baseColor.withOpacity(0.28),
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
            '$medal $level карта',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '$points баллов',
            style: const TextStyle(
              fontSize: 16,
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
            'До следующего уровня: ${(nextLevelPoints - points).clamp(0, 1 << 30)} баллов',
            style: const TextStyle(fontSize: 14, color: Colors.white70),
          ),
          const SizedBox(height: 10),
          Text(
            'Всего потрачено: ${totalSpent.toStringAsFixed(0)} ₽',
            style: const TextStyle(fontSize: 14, color: Colors.white70),
          ),
        ],
      ),
    );
  }
}
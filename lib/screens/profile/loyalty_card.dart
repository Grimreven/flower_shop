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
    if (hex.length == 6) hex = 'FF$hex'; // добавляем альфу
    return Color(int.parse(hex, radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    double progress = points / nextLevelPoints;
    if (progress > 1) progress = 1;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: getColor(colorHex),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "$level карта",
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              "$points баллов",
              style: const TextStyle(fontSize: 16, color: Colors.white70),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress,
              color: Colors.white,
              backgroundColor: Colors.white30,
              minHeight: 8,
            ),
            const SizedBox(height: 8),
            Text(
              "До следующего уровня: ${nextLevelPoints - points} баллов",
              style: const TextStyle(fontSize: 14, color: Colors.white70),
            ),
            const SizedBox(height: 8),
            Text(
              "Всего потрачено: \$${totalSpent.toStringAsFixed(2)}",
              style: const TextStyle(fontSize: 14, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}

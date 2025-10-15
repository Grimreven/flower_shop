import 'package:flutter/material.dart';

class LoyaltyCard extends StatelessWidget {
  final int points;
  final String level;
  final int nextLevelPoints;
  final double totalSpent;

  const LoyaltyCard({
    Key? key,
    required this.points,
    required this.level,
    required this.nextLevelPoints,
    required this.totalSpent,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double progress = points / nextLevelPoints;
    if (progress > 1.0) progress = 1.0;

    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Программа лояльности',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text('Уровень: $level'),
            const SizedBox(height: 6),
            Text('Баллы: $points / $nextLevelPoints'),
            const SizedBox(height: 6),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[300],
              color: Colors.pink,
              minHeight: 8,
            ),
            const SizedBox(height: 12),
            Text('Сумма покупок: \$${totalSpent.toStringAsFixed(2)}'),
          ],
        ),
      ),
    );
  }
}

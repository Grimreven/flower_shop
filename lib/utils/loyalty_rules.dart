import '../models/delivery_method.dart';

class LoyaltyRules {
  static const double bonusActivationMinOrder = 1000.0;
  static const double maxBonusPercent = 0.30;
  static const double freeDeliveryThreshold = 3000.0;
  static const double standardDeliveryCost = 300.0;

  static const double bronzeEarnPercent = 0.05;
  static const double silverEarnPercent = 0.07;
  static const double goldEarnPercent = 0.10;

  static double resolveDeliveryCost(
      double itemsTotal, {
        required DeliveryMethod deliveryMethod,
      }) {
    if (deliveryMethod == DeliveryMethod.pickup) {
      return 0.0;
    }

    if (itemsTotal >= freeDeliveryThreshold) {
      return 0.0;
    }

    return standardDeliveryCost;
  }

  static int resolveMaxBonusUsage({
    required double itemsTotal,
    required int availableBonuses,
  }) {
    if (itemsTotal < bonusActivationMinOrder || availableBonuses <= 0) {
      return 0;
    }

    final int percentLimited = (itemsTotal * maxBonusPercent).floor();

    if (availableBonuses < percentLimited) {
      return availableBonuses;
    }

    return percentLimited;
  }

  static int resolveBonusEarned({
    required double itemsTotal,
    required int bonusApplied,
    String loyaltyLevel = 'Bronze',
  }) {
    final double base = (itemsTotal - bonusApplied).clamp(
      0.0,
      double.infinity,
    );

    return (base * resolveEarnPercent(loyaltyLevel)).floor();
  }

  static double resolveEarnPercent(String loyaltyLevel) {
    final String normalized = loyaltyLevel.toLowerCase();

    if (normalized.contains('gold')) {
      return goldEarnPercent;
    }

    if (normalized.contains('silver')) {
      return silverEarnPercent;
    }

    return bronzeEarnPercent;
  }

  static String resolveLevelByTotalSpent(double totalSpent) {
    if (totalSpent >= 15000) {
      return 'Gold';
    }

    if (totalSpent >= 5000) {
      return 'Silver';
    }

    return 'Bronze';
  }

  static String resolveColorByLevel(String loyaltyLevel) {
    final String normalized = loyaltyLevel.toLowerCase();

    if (normalized.contains('gold')) {
      return '#d4af37';
    }

    if (normalized.contains('silver')) {
      return '#c0c0c0';
    }

    return '#cd7f32';
  }
}
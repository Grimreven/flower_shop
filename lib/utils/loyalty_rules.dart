import '../models/delivery_method.dart';

class LoyaltyRules {
  static const double bonusActivationMinOrder = 1000.0;
  static const double maxBonusPercent = 0.30;

  static const double freeDeliveryThreshold = 3000.0;
  static const double standardDeliveryCost = 300.0;

  static const double earnPercentWithoutBonus = 0.05;
  static const double earnPercentWithBonus = 0.02;

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
    return availableBonuses < percentLimited
        ? availableBonuses
        : percentLimited;
  }

  static int resolveBonusEarned({
    required double itemsTotal,
    required int bonusApplied,
  }) {
    final double base = (itemsTotal - bonusApplied).clamp(0.0, double.infinity);
    final double percent = bonusApplied > 0
        ? earnPercentWithBonus
        : earnPercentWithoutBonus;

    return (base * percent).floor();
  }
}
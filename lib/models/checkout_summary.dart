import '../models/delivery_method.dart';
import '../utils/loyalty_rules.dart';

class CheckoutSummary {
  final double itemsTotal;
  final double deliveryCost;
  final DeliveryMethod deliveryMethod;
  final int availableBonuses;
  final int allowedBonuses;
  final int appliedBonuses;
  final int earnedBonuses;
  final double payableTotal;

  const CheckoutSummary({
    required this.itemsTotal,
    required this.deliveryCost,
    required this.deliveryMethod,
    required this.availableBonuses,
    required this.allowedBonuses,
    required this.appliedBonuses,
    required this.earnedBonuses,
    required this.payableTotal,
  });

  bool get hasBonusUsage => appliedBonuses > 0;
  bool get hasFreeDelivery => deliveryCost == 0;
  bool get isPickup => deliveryMethod == DeliveryMethod.pickup;

  factory CheckoutSummary.calculate({
    required double itemsTotal,
    required int availableBonuses,
    required int requestedBonuses,
    required DeliveryMethod deliveryMethod,
  }) {
    final double deliveryCost = LoyaltyRules.resolveDeliveryCost(
      itemsTotal,
      deliveryMethod: deliveryMethod,
    );

    final int allowedBonuses = LoyaltyRules.resolveMaxBonusUsage(
      itemsTotal: itemsTotal,
      availableBonuses: availableBonuses,
    );

    int appliedBonuses = requestedBonuses;
    if (appliedBonuses < 0) {
      appliedBonuses = 0;
    }
    if (appliedBonuses > allowedBonuses) {
      appliedBonuses = allowedBonuses;
    }
    if (appliedBonuses > itemsTotal.floor()) {
      appliedBonuses = itemsTotal.floor();
    }

    final double payableTotal =
    (itemsTotal - appliedBonuses + deliveryCost).clamp(0.0, double.infinity);

    final int earnedBonuses = LoyaltyRules.resolveBonusEarned(
      itemsTotal: itemsTotal,
      bonusApplied: appliedBonuses,
    );

    return CheckoutSummary(
      itemsTotal: itemsTotal,
      deliveryCost: deliveryCost,
      deliveryMethod: deliveryMethod,
      availableBonuses: availableBonuses,
      allowedBonuses: allowedBonuses,
      appliedBonuses: appliedBonuses,
      earnedBonuses: earnedBonuses,
      payableTotal: payableTotal,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'items_total': itemsTotal,
      'delivery_cost': deliveryCost,
      'delivery_method': deliveryMethod.code,
      'available_bonuses': availableBonuses,
      'allowed_bonuses': allowedBonuses,
      'applied_bonuses': appliedBonuses,
      'earned_bonuses': earnedBonuses,
      'payable_total': payableTotal,
    };
  }
}
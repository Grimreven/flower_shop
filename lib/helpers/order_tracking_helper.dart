import 'package:flutter/material.dart';

enum OrderTrackingStage {
  accepted,
  preparing,
  courier,
  delivered,
}

class OrderTrackingStep {
  final OrderTrackingStage stage;
  final String title;
  final String message;
  final IconData icon;

  const OrderTrackingStep({
    required this.stage,
    required this.title,
    required this.message,
    required this.icon,
  });
}

class OrderTrackingHelper {
  static const List<OrderTrackingStep> steps = [
    OrderTrackingStep(
      stage: OrderTrackingStage.accepted,
      title: 'Принят',
      message: 'Мы приняли ваш заказ',
      icon: Icons.receipt_long_rounded,
    ),
    OrderTrackingStep(
      stage: OrderTrackingStage.preparing,
      title: 'Собирается',
      message: 'Собираем букет 💐',
      icon: Icons.local_florist_rounded,
    ),
    OrderTrackingStep(
      stage: OrderTrackingStage.courier,
      title: 'Передан курьеру',
      message: 'Курьер уже в пути 🚗',
      icon: Icons.delivery_dining_rounded,
    ),
    OrderTrackingStep(
      stage: OrderTrackingStage.delivered,
      title: 'Доставлен',
      message: 'Заказ доставлен 🎉',
      icon: Icons.check_circle_rounded,
    ),
  ];

  static int stageToIndex(OrderTrackingStage stage) {
    return steps.indexWhere((item) => item.stage == stage);
  }

  static OrderTrackingStage indexToStage(int index) {
    return steps[index].stage;
  }

  static String titleByIndex(int index) {
    return steps[index].title;
  }

  static String messageByIndex(int index) {
    return steps[index].message;
  }

  static IconData iconByIndex(int index) {
    return steps[index].icon;
  }

  static String estimatedTimeText(DateTime dateTime) {
    final String hour = dateTime.hour.toString().padLeft(2, '0');
    final String minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  static OrderTrackingStage resolveInitialStage(String status) {
    final String normalized = status.toLowerCase();

    if (normalized.contains('достав')) {
      return OrderTrackingStage.delivered;
    }

    if (normalized.contains('курьер') || normalized.contains('пути')) {
      return OrderTrackingStage.courier;
    }

    if (normalized.contains('собира')) {
      return OrderTrackingStage.preparing;
    }

    return OrderTrackingStage.accepted;
  }
}
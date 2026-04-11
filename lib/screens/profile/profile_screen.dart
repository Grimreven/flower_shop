import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/order_controller.dart';
import '../../controllers/settings_controller.dart';
import '../../models/user.dart';
import '../../api/local_demo_service.dart';
import '../../api/notification_service.dart';
import '../../utils/app_colors.dart';
import 'loyalty_card.dart';

class ProfilePaymentMethod {
  final String id;
  final String title;
  final String details;
  final IconData icon;
  final bool isDefault;

  const ProfilePaymentMethod({
    required this.id,
    required this.title,
    required this.details,
    required this.icon,
    required this.isDefault,
  });

  ProfilePaymentMethod copyWith({
    String? id,
    String? title,
    String? details,
    IconData? icon,
    bool? isDefault,
  }) {
    return ProfilePaymentMethod(
      id: id ?? this.id,
      title: title ?? this.title,
      details: details ?? this.details,
      icon: icon ?? this.icon,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}

class LoyaltyPreviewData {
  final String level;
  final int points;
  final double totalSpent;
  final int nextLevelPoints;
  final String colorHex;
  final String nextLevelLabel;

  const LoyaltyPreviewData({
    required this.level,
    required this.points,
    required this.totalSpent,
    required this.nextLevelPoints,
    required this.colorHex,
    required this.nextLevelLabel,
  });
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthController authController = Get.find<AuthController>();
  final SettingsController settingsController = Get.find<SettingsController>();
  final OrderController orderController = Get.find<OrderController>();

  User? editedUser;
  bool isLoading = true;
  bool isEditing = false;
  String activeSection = 'info';

  late TextEditingController nameController;
  late TextEditingController emailController;
  late TextEditingController phoneController;
  late TextEditingController addressController;

  List<ProfilePaymentMethod> paymentMethods = const [
    ProfilePaymentMethod(
      id: 'card_1',
      title: 'Visa',
      details: '**** 4587',
      icon: Icons.credit_card_rounded,
      isDefault: true,
    ),
    ProfilePaymentMethod(
      id: 'cash_1',
      title: 'Наличный расчёт',
      details: 'Оплата при получении',
      icon: Icons.payments_rounded,
      isDefault: false,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    if (!isLoading) {
      nameController.dispose();
      emailController.dispose();
      phoneController.dispose();
      addressController.dispose();
    }
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => isLoading = true);

    final User? profile = await authController.getProfile();
    await orderController.fetchUserOrders();

    if (!mounted) {
      return;
    }

    if (profile == null) {
      setState(() => isLoading = false);
      return;
    }

    setState(() {
      editedUser = profile;
      nameController = TextEditingController(text: profile.name);
      emailController = TextEditingController(text: profile.email);
      phoneController = TextEditingController(text: profile.phone ?? '');
      addressController = TextEditingController(text: profile.address ?? '');
      isLoading = false;
    });
  }

  void _showMessage(String msg) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  Future<void> handleSave() async {
    if (editedUser == null) {
      return;
    }

    setState(() => isLoading = true);

    final User? updated = await authController.updateProfile(editedUser!);

    if (!mounted) {
      return;
    }

    if (updated != null) {
      setState(() {
        editedUser = updated;
        isEditing = false;
        isLoading = false;
        nameController.text = updated.name;
        emailController.text = updated.email;
        phoneController.text = updated.phone ?? '';
        addressController.text = updated.address ?? '';
      });
      _showMessage('Профиль успешно обновлён');
    } else {
      setState(() => isLoading = false);
      _showMessage('Ошибка при обновлении профиля');
    }
  }

  void handleCancel() {
    setState(() {
      isEditing = false;
      if (editedUser != null) {
        nameController.text = editedUser!.name;
        emailController.text = editedUser!.email;
        phoneController.text = editedUser!.phone ?? '';
        addressController.text = editedUser!.address ?? '';
      }
    });
  }

  Future<void> handleLogout() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        final bool isDark = Theme.of(context).brightness == Brightness.dark;

        return AlertDialog(
          backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: isDark ? AppColors.darkBorder : AppColors.border,
            ),
          ),
          title: const Text('Выход из аккаунта'),
          content: const Text('Вы уверены, что хотите выйти?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Отмена',
                style: TextStyle(
                  color: isDark ? AppColors.purpleLight : AppColors.primary,
                ),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: isDark
                    ? AppColors.darkBrandGradient
                    : AppColors.brandGradient,
                borderRadius: BorderRadius.circular(14),
              ),
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('Выйти'),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await authController.logout();
      if (!mounted) {
        return;
      }
      Get.offAllNamed('/main');
    }
  }

  Future<void> _resetDemoData() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        final bool isDark = Theme.of(context).brightness == Brightness.dark;

        return AlertDialog(
          backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: isDark ? AppColors.darkBorder : AppColors.border,
            ),
          ),
          title: const Text('Сбросить демо-данные'),
          content: const Text(
            'Это вернёт приложение к начальному состоянию: очистятся корзина, заказы, текущая сессия и восстановятся демо-данные.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Отмена',
                style: TextStyle(
                  color: isDark ? AppColors.purpleLight : AppColors.primary,
                ),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: isDark
                    ? AppColors.darkBrandGradient
                    : AppColors.brandGradient,
                borderRadius: BorderRadius.circular(14),
              ),
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('Сбросить'),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await LocalDemoService.instance.resetDemoData();
    await authController.logout();

    if (!mounted) {
      return;
    }

    _showMessage('Демо-данные успешно сброшены');
    Get.offAllNamed('/main');
  }

  bool _notificationsEnabled() {
    return settingsController.orderNotifications.value ||
        settingsController.promoNotifications.value ||
        settingsController.loyaltyNotifications.value;
  }

  Future<void> _toggleAllNotifications(bool value) async {
    if (value) {
      await NotificationService.instance.init();
      await NotificationService.instance.requestPermissions();
    }

    await settingsController.setOrderNotifications(value);
    await settingsController.setPromoNotifications(value);
    await settingsController.setLoyaltyNotifications(value);

    _showMessage(
      value ? 'Уведомления включены' : 'Уведомления выключены',
    );
  }

  Future<void> _sendTestNotification() async {
    if (!_notificationsEnabled()) {
      _showMessage('Сначала включите уведомления');
      return;
    }

    await NotificationService.instance.showSimpleNotification(
      id: 999001,
      title: 'Тестовое уведомление',
      body: 'Системные уведомления работают корректно',
    );
  }

  LoyaltyPreviewData _buildLoyaltyPreview(User user) {
    final double ordersSpent = orderController.orders.fold<double>(
      0,
          (double sum, order) => sum + order.total,
    );

    final double totalSpent = ordersSpent > user.totalSpent
        ? ordersSpent
        : user.totalSpent;

    final int points = totalSpent.round();

    if (totalSpent >= 15000) {
      return LoyaltyPreviewData(
        level: 'Gold',
        points: points,
        totalSpent: totalSpent,
        nextLevelPoints: points,
        colorHex: '#E0B94A',
        nextLevelLabel: 'Gold',
      );
    }

    if (totalSpent >= 5000) {
      return LoyaltyPreviewData(
        level: 'Silver',
        points: points,
        totalSpent: totalSpent,
        nextLevelPoints: 15000,
        colorHex: '#AAB7C7',
        nextLevelLabel: 'Gold',
      );
    }

    return LoyaltyPreviewData(
      level: 'Bronze',
      points: points,
      totalSpent: totalSpent,
      nextLevelPoints: 5000,
      colorHex: '#CD7F32',
      nextLevelLabel: 'Silver',
    );
  }

  Future<void> _showPaymentMethodDialog({
    ProfilePaymentMethod? method,
  }) async {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final TextEditingController titleController = TextEditingController(
      text: method?.title ?? '',
    );
    final TextEditingController detailsController = TextEditingController(
      text: method?.details ?? '',
    );

    IconData selectedIcon = method?.icon ?? Icons.credit_card_rounded;

    final List<Map<String, dynamic>> icons = [
      {'icon': Icons.credit_card_rounded, 'label': 'Карта'},
      {'icon': Icons.payments_rounded, 'label': 'Наличные'},
      {'icon': Icons.account_balance_wallet_rounded, 'label': 'Кошелёк'},
      {'icon': Icons.phone_android_rounded, 'label': 'Телефон'},
    ];

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, void Function(void Function()) setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    method == null
                        ? 'Добавить способ оплаты'
                        : 'Редактировать способ оплаты',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Название',
                      hintText: 'Например, Visa',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: detailsController,
                    decoration: const InputDecoration(
                      labelText: 'Описание',
                      hintText: 'Например, **** 4587',
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Иконка',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: icons.map((item) {
                      final bool isSelected = selectedIcon == item['icon'];

                      return GestureDetector(
                        onTap: () {
                          setModalState(() {
                            selectedIcon = item['icon'] as IconData;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            gradient: isSelected
                                ? (isDark
                                ? AppColors.darkBrandGradient
                                : AppColors.brandGradient)
                                : null,
                            color: isSelected
                                ? null
                                : (isDark
                                ? AppColors.darkSurfaceElevated
                                : AppColors.primaryLight.withValues(alpha: 0.45)),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                item['icon'] as IconData,
                                color: isSelected
                                    ? Colors.white
                                    : (isDark
                                    ? AppColors.purpleLight
                                    : AppColors.primary),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                item['label'] as String,
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : Theme.of(context).colorScheme.onSurface,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: isDark
                            ? AppColors.darkBrandGradient
                            : AppColors.brandGradient,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          final String title = titleController.text.trim();
                          final String details = detailsController.text.trim();

                          if (title.isEmpty || details.isEmpty) {
                            _showMessage('Заполните все поля');
                            return;
                          }

                          setState(() {
                            if (method == null) {
                              paymentMethods = [
                                ...paymentMethods,
                                ProfilePaymentMethod(
                                  id: DateTime.now()
                                      .millisecondsSinceEpoch
                                      .toString(),
                                  title: title,
                                  details: details,
                                  icon: selectedIcon,
                                  isDefault: paymentMethods.isEmpty,
                                ),
                              ];
                            } else {
                              paymentMethods = paymentMethods.map((item) {
                                if (item.id == method.id) {
                                  return item.copyWith(
                                    title: title,
                                    details: details,
                                    icon: selectedIcon,
                                  );
                                }
                                return item;
                              }).toList();
                            }
                          });

                          Navigator.of(context).pop();
                          _showMessage(
                            method == null
                                ? 'Способ оплаты добавлен'
                                : 'Способ оплаты обновлён',
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(54),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: Text(
                          method == null ? 'Добавить' : 'Сохранить',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    titleController.dispose();
    detailsController.dispose();
  }

  void _setDefaultPaymentMethod(String id) {
    setState(() {
      paymentMethods = paymentMethods
          .map((item) => item.copyWith(isDefault: item.id == id))
          .toList();
    });

    _showMessage('Способ оплаты по умолчанию обновлён');
  }

  void _deletePaymentMethod(String id) {
    final bool wasDefault =
    paymentMethods.any((item) => item.id == id && item.isDefault);

    setState(() {
      paymentMethods = paymentMethods.where((item) => item.id != id).toList();

      if (wasDefault && paymentMethods.isNotEmpty) {
        paymentMethods = paymentMethods.asMap().entries.map((entry) {
          if (entry.key == 0) {
            return entry.value.copyWith(isDefault: true);
          }
          return entry.value.copyWith(isDefault: false);
        }).toList();
      }
    });

    _showMessage('Способ оплаты удалён');
  }

  Widget _sectionButton(
      BuildContext context,
      String id,
      String label,
      IconData icon,
      ) {
    final bool isActive = activeSection == id;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => activeSection = id),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.all(4),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: isActive
                ? (isDark
                ? AppColors.darkBrandGradient
                : AppColors.brandGradient)
                : null,
            color: isActive ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isActive
                    ? Colors.white
                    : (isDark
                    ? AppColors.darkMutedForeground
                    : AppColors.mutedForeground),
                size: 20,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: isActive
                      ? Colors.white
                      : (isDark
                      ? AppColors.darkMutedForeground
                      : AppColors.mutedForeground),
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _inputField(
      BuildContext context,
      String label,
      TextEditingController controller,
      Function(String) onChange,
      ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        enabled: isEditing,
        controller: controller,
        onChanged: onChange,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }

  Widget _card(
      BuildContext context, {
        required Widget child,
        EdgeInsets? padding,
      }) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color borderColor = isDark ? AppColors.darkBorder : AppColors.border;

    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: isDark ? AppColors.darkCardGradient : null,
        color: isDark ? null : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? AppColors.purple.withValues(alpha: 0.05)
                : AppColors.shadow,
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildSettingsSection(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Obx(
          () {
        final bool notificationsEnabled = _notificationsEnabled();

        return Column(
          children: [
            _card(
              context,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Настройки приложения',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Уведомления'),
                    subtitle: Text(
                      notificationsEnabled
                          ? 'Все уведомления включены'
                          : 'Все уведомления выключены',
                      style: TextStyle(
                        color: isDark
                            ? AppColors.darkMutedForeground
                            : AppColors.mutedForeground,
                      ),
                    ),
                    value: notificationsEnabled,
                    activeThumbColor:
                    isDark ? AppColors.purple : AppColors.primary,
                    onChanged: _toggleAllNotifications,
                  ),
                  const Divider(),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        gradient: isDark
                            ? AppColors.darkBrandGradient
                            : AppColors.brandGradient,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.notifications_active_rounded,
                        color: Colors.white,
                      ),
                    ),
                    title: const Text('Проверить уведомления'),
                    subtitle: Text(
                      'Показать системное тестовое уведомление',
                      style: TextStyle(
                        color: isDark
                            ? AppColors.darkMutedForeground
                            : AppColors.mutedForeground,
                      ),
                    ),
                    trailing: Icon(
                      Icons.chevron_right_rounded,
                      color: isDark
                          ? AppColors.purpleLight
                          : AppColors.mutedForeground,
                    ),
                    onTap: _sendTestNotification,
                  ),
                  const Divider(),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Тёмная тема'),
                    subtitle: Text(
                      settingsController.darkTheme.value
                          ? 'Тёмное оформление включено'
                          : 'Светлое оформление включено',
                      style: TextStyle(
                        color: isDark
                            ? AppColors.darkMutedForeground
                            : AppColors.mutedForeground,
                      ),
                    ),
                    value: settingsController.darkTheme.value,
                    activeThumbColor:
                    isDark ? AppColors.purple : AppColors.primary,
                    onChanged: (bool val) => settingsController.setDarkTheme(val),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _card(
              context,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Демо-режим',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Сброс вернёт приложение к начальному состоянию для показа на защите.',
                    style: TextStyle(
                      color: isDark
                          ? AppColors.darkMutedForeground
                          : AppColors.mutedForeground,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: isDark
                            ? AppColors.darkBrandGradient
                            : AppColors.brandGradient,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: ElevatedButton.icon(
                        onPressed: _resetDemoData,
                        icon: const Icon(Icons.restart_alt_rounded),
                        label: const Text('Сбросить демо-данные'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(54),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _card(
              context,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Способы оплаты',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => _showPaymentMethodDialog(),
                        icon: Icon(
                          Icons.add_rounded,
                          color: isDark
                              ? AppColors.purpleLight
                              : AppColors.primary,
                        ),
                        label: Text(
                          'Добавить',
                          style: TextStyle(
                            color: isDark
                                ? AppColors.purpleLight
                                : AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (paymentMethods.isEmpty)
                    Text(
                      'У вас пока нет способов оплаты',
                      style: TextStyle(
                        color: isDark
                            ? AppColors.darkMutedForeground
                            : AppColors.mutedForeground,
                      ),
                    )
                  else
                    ...paymentMethods.map((method) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkSurfaceElevated
                              : AppColors.primaryLight.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isDark
                                ? AppColors.darkBorder
                                : Colors.transparent,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                gradient: isDark
                                    ? AppColors.darkBrandGradient
                                    : AppColors.brandGradient,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(
                                method.icon,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          method.title,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface,
                                          ),
                                        ),
                                      ),
                                      if (method.isDefault) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isDark
                                                ? AppColors.darkSurfaceSoft
                                                : Colors.white,
                                            borderRadius:
                                            BorderRadius.circular(999),
                                          ),
                                          child: Text(
                                            'По умолчанию',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: isDark
                                                  ? AppColors.purpleLight
                                                  : AppColors.primary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    method.details,
                                    style: TextStyle(
                                      color: isDark
                                          ? AppColors.darkMutedForeground
                                          : AppColors.mutedForeground,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            PopupMenuButton<String>(
                              onSelected: (String value) {
                                if (value == 'default') {
                                  _setDefaultPaymentMethod(method.id);
                                } else if (value == 'edit') {
                                  _showPaymentMethodDialog(method: method);
                                } else if (value == 'delete') {
                                  _deletePaymentMethod(method.id);
                                }
                              },
                              itemBuilder: (BuildContext context) => [
                                const PopupMenuItem(
                                  value: 'default',
                                  child: Text('Сделать основным'),
                                ),
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Text('Редактировать'),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Text('Удалить'),
                                ),
                              ],
                              icon: Icon(
                                Icons.more_vert_rounded,
                                color: isDark
                                    ? AppColors.purpleLight
                                    : AppColors.mutedForeground,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInfoSection(BuildContext context, User user) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return _card(
      context,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Личные данные',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
              !isEditing
                  ? TextButton.icon(
                onPressed: () => setState(() => isEditing = true),
                icon: Icon(
                  Icons.edit_outlined,
                  size: 16,
                  color: isDark
                      ? AppColors.purpleLight
                      : AppColors.primary,
                ),
                label: Text(
                  'Редактировать',
                  style: TextStyle(
                    color: isDark
                        ? AppColors.purpleLight
                        : AppColors.primary,
                  ),
                ),
              )
                  : Row(
                children: [
                  OutlinedButton(
                    onPressed: handleCancel,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isDark
                          ? AppColors.purpleLight
                          : AppColors.primary,
                      side: BorderSide(
                        color: isDark
                            ? AppColors.darkBorder
                            : AppColors.border,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text('Отмена'),
                  ),
                  const SizedBox(width: 8),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: isDark
                          ? AppColors.darkBrandGradient
                          : AppColors.brandGradient,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: ElevatedButton(
                      onPressed: handleSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text('Сохранить'),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          _inputField(
            context,
            'Имя',
            nameController,
                (String val) => editedUser = editedUser!.copyWith(name: val),
          ),
          _inputField(
            context,
            'Email',
            emailController,
                (String val) => editedUser = editedUser!.copyWith(email: val),
          ),
          _inputField(
            context,
            'Телефон',
            phoneController,
                (String val) => editedUser = editedUser!.copyWith(phone: val),
          ),
          _inputField(
            context,
            'Адрес доставки',
            addressController,
                (String val) => editedUser = editedUser!.copyWith(address: val),
          ),
        ],
      ),
    );
  }

  Widget _buildLoyaltySection(User user) {
    final LoyaltyPreviewData loyalty = _buildLoyaltyPreview(user);

    return Column(
      children: [
        LoyaltyCard(
          level: loyalty.level,
          points: loyalty.points,
          totalSpent: loyalty.totalSpent,
          nextLevelPoints: loyalty.nextLevelPoints,
          colorHex: loyalty.colorHex,
          nextLevelLabel: loyalty.nextLevelLabel,
        ),
        const SizedBox(height: 12),
        _card(
          context,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Как работает статус',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              const _LoyaltyRuleRow(
                title: 'Bronze',
                subtitle: 'до 4 999 ₽ покупок',
                color: '#CD7F32',
              ),
              const SizedBox(height: 10),
              const _LoyaltyRuleRow(
                title: 'Silver',
                subtitle: 'от 5 000 ₽ до 14 999 ₽',
                color: '#AAB7C7',
              ),
              const SizedBox(height: 10),
              const _LoyaltyRuleRow(
                title: 'Gold',
                subtitle: 'от 15 000 ₽ и выше',
                color: '#E0B94A',
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color bg = Theme.of(context).scaffoldBackgroundColor;
    final Color onSurface = Theme.of(context).colorScheme.onSurface;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    if (isLoading) {
      return Scaffold(
        backgroundColor: bg,
        body: Center(
          child: CircularProgressIndicator(
            color: isDark ? AppColors.purple : AppColors.primary,
          ),
        ),
      );
    }

    if (editedUser == null) {
      return Scaffold(
        backgroundColor: bg,
        body: const Center(
          child: Text('Нет данных профиля'),
        ),
      );
    }

    final User user = editedUser!;
    final LoyaltyPreviewData loyaltyPreview = _buildLoyaltyPreview(user);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Text(
          'Профиль',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: onSurface,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _loadProfile,
            icon: Icon(
              Icons.refresh_rounded,
              color: isDark ? AppColors.purpleLight : AppColors.primary,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: handleLogout,
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: isDark
                      ? AppColors.darkBrandGradient
                      : AppColors.brandGradient,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? const LinearGradient(
            colors: [
              AppColors.darkBackground,
              AppColors.darkBackgroundSecondary,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          )
              : null,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _card(
                context,
                child: Row(
                  children: [
                    Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        gradient: isDark
                            ? AppColors.darkBrandGradient
                            : AppColors.brandGradient,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: (isDark ? AppColors.purple : AppColors.primary)
                                .withValues(alpha: 0.18),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          user.name.isNotEmpty
                              ? user.name
                              .split(' ')
                              .map((String n) => n[0])
                              .join()
                              .toUpperCase()
                              : 'U',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.name,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user.email,
                            style: TextStyle(
                              color: isDark
                                  ? AppColors.darkMutedForeground
                                  : AppColors.mutedForeground,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.darkSurfaceElevated
                                  : AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: isDark
                                    ? AppColors.darkBorder
                                    : Colors.transparent,
                              ),
                            ),
                            child: Text(
                              '${loyaltyPreview.level} • ${loyaltyPreview.points} баллов',
                              style: TextStyle(
                                color: isDark
                                    ? AppColors.purpleLight
                                    : AppColors.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _card(
                context,
                padding: const EdgeInsets.all(6),
                child: Row(
                  children: [
                    _sectionButton(
                      context,
                      'info',
                      'Данные',
                      Icons.person_outline_rounded,
                    ),
                    _sectionButton(
                      context,
                      'loyalty',
                      'Лояльность',
                      Icons.card_giftcard_rounded,
                    ),
                    _sectionButton(
                      context,
                      'settings',
                      'Настройки',
                      Icons.settings_outlined,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              if (activeSection == 'info') _buildInfoSection(context, user),
              if (activeSection == 'loyalty') _buildLoyaltySection(user),
              if (activeSection == 'settings') _buildSettingsSection(context),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoyaltyRuleRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final String color;

  const _LoyaltyRuleRow({
    required this.title,
    required this.subtitle,
    required this.color,
  });

  Color _parseColor(String hexColor) {
    String hex = hexColor.replaceAll('#', '');
    if (hex.length == 6) {
      hex = 'FF$hex';
    }
    return Color(int.parse(hex, radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final Color badgeColor = _parseColor(color);

    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: badgeColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            '$title — $subtitle',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
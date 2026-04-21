import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../api/local_demo_service.dart';
import '../../api/notification_service.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/order_controller.dart';
import '../../controllers/payment_controller.dart';
import '../../controllers/settings_controller.dart';
import '../../models/payment_method_model.dart';
import '../../models/user.dart';
import '../../utils/app_colors.dart';
import 'loyalty_card.dart';

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
  final PaymentController paymentController = Get.find<PaymentController>();

  User? editedUser;
  User? _savedUserSnapshot;

  bool isLoading = true;
  bool isEditing = false;
  String activeSection = 'info';

  late final TextEditingController nameController;
  late final TextEditingController emailController;
  late final TextEditingController phoneController;
  late final TextEditingController addressController;

  @override
  void initState() {
    super.initState();

    nameController = TextEditingController();
    emailController = TextEditingController();
    phoneController = TextEditingController();
    addressController = TextEditingController();

    _loadProfile();
  }

  @override
  void dispose() {
    FocusManager.instance.primaryFocus?.unfocus();

    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    addressController.dispose();

    super.dispose();
  }

  void _unfocusEverything() {
    final FocusScopeNode scope = FocusScope.of(context);
    if (!scope.hasPrimaryFocus) {
      scope.unfocus();
    }
  }

  Future<void> _loadProfile() async {
    if (!mounted) return;

    setState(() => isLoading = true);

    final User? profile = await authController.getProfile();
    await orderController.fetchUserOrders();
    await paymentController.loadPaymentMethods();
    await paymentController.loadPaymentTransactions();

    if (!mounted) return;

    if (profile == null) {
      setState(() => isLoading = false);
      return;
    }

    editedUser = profile;
    _savedUserSnapshot = profile;

    nameController.text = profile.name;
    emailController.text = profile.email;
    phoneController.text = profile.phone ?? '';
    addressController.text = profile.address ?? '';

    setState(() {
      isEditing = false;
      isLoading = false;
    });
  }

  void _showMessage(String msg) {
    if (!mounted) return;

    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.hideCurrentSnackBar();
    messenger?.showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  void _startEditing() {
    _unfocusEverything();

    final User? user = editedUser;
    if (user == null) return;

    _savedUserSnapshot = user;

    nameController.text = user.name;
    emailController.text = user.email;
    phoneController.text = user.phone ?? '';
    addressController.text = user.address ?? '';

    setState(() {
      isEditing = true;
      activeSection = 'info';
    });
  }

  Future<void> handleSave() async {
    final User? currentUser = editedUser;
    if (currentUser == null) return;

    _unfocusEverything();

    setState(() => isLoading = true);

    final User? updated = await authController.updateProfile(currentUser);

    if (!mounted) return;

    if (updated != null) {
      editedUser = updated;
      _savedUserSnapshot = updated;

      nameController.text = updated.name;
      emailController.text = updated.email;
      phoneController.text = updated.phone ?? '';
      addressController.text = updated.address ?? '';

      setState(() {
        isEditing = false;
        isLoading = false;
      });

      _showMessage('Профиль успешно обновлён');
    } else {
      setState(() => isLoading = false);
      _showMessage('Ошибка при обновлении профиля');
    }
  }

  void handleCancel() {
    _unfocusEverything();

    final User? snapshot = _savedUserSnapshot ?? editedUser;
    if (snapshot == null) return;

    editedUser = snapshot;

    nameController.text = snapshot.name;
    emailController.text = snapshot.email;
    phoneController.text = snapshot.phone ?? '';
    addressController.text = snapshot.address ?? '';

    setState(() {
      isEditing = false;
    });
  }

  void _changeSection(String id) {
    _unfocusEverything();

    if (activeSection == id) return;

    if (isEditing && id != 'info') {
      handleCancel();
    }

    if (!mounted) return;

    setState(() {
      activeSection = id;
    });
  }

  Future<void> handleLogout() async {
    _unfocusEverything();

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
      if (!mounted) return;
      Get.offAllNamed('/main');
    }
  }

  Future<void> _resetDemoData() async {
    _unfocusEverything();

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

    if (confirmed != true) return;

    await LocalDemoService.instance.resetDemoData();
    await authController.logout();

    if (!mounted) return;

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

    final double totalSpent =
    ordersSpent > user.totalSpent ? ordersSpent : user.totalSpent;

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

  Future<void> _showAddCardDialog() async {
    _unfocusEverything();

    final PaymentCardFormResult? result =
    await showModalBottomSheet<PaymentCardFormResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? AppColors.darkSurface
          : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (BuildContext context) {
        return const _PaymentCardBottomSheet();
      },
    );

    if (result == null) return;

    try {
      await paymentController.addCardMethod(
        cardNumber: result.cardNumber,
        expiryMonth: result.expiryMonth,
        expiryYear: result.expiryYear,
        setAsDefault: result.setAsDefault,
      );
      _showMessage('Карта успешно добавлена');
    } catch (e) {
      _showMessage('Ошибка при добавлении карты: $e');
    }
  }


  Future<void> _setDefaultPaymentMethod(String id) async {
    _unfocusEverything();

    try {
      await paymentController.setDefaultMethod(id);
      _showMessage('Способ оплаты по умолчанию обновлён');
    } catch (e) {
      _showMessage('Ошибка: $e');
    }
  }

  Future<void> _deletePaymentMethod(String id) async {
    _unfocusEverything();

    try {
      await paymentController.deleteMethod(id);
      _showMessage('Способ оплаты удалён');
    } catch (e) {
      _showMessage('Ошибка: $e');
    }
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
        onTap: () => _changeSection(id),
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

  Widget _buildPaymentMethodTile(
      BuildContext context,
      PaymentMethodModel method,
      ) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkSurfaceElevated
            : AppColors.primaryLight.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : Colors.transparent,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                Text(
                  method.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkSurfaceSoft
                            : Colors.white,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        method.displayBadge,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppColors.purpleLight
                              : AppColors.primary,
                        ),
                      ),
                    ),
                    if (method.isDefault)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkSurfaceSoft
                              : Colors.white,
                          borderRadius: BorderRadius.circular(999),
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
                ),
                const SizedBox(height: 8),
                Text(
                  method.subtitle,
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
                _showEditCardDialog(method);
              } else if (value == 'delete') {
                _deletePaymentMethod(method.id);
              }
            },
            itemBuilder: (BuildContext context) {
              final List<PopupMenuEntry<String>> items = [
                const PopupMenuItem(
                  value: 'default',
                  child: Text('Сделать основным'),
                ),
              ];

              if (method.isCard && !method.isSystem) {
                items.add(
                  const PopupMenuItem(
                    value: 'edit',
                    child: Text('Редактировать'),
                  ),
                );
                items.add(
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('Удалить'),
                  ),
                );
              }

              return items;
            },
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
  }

  Widget _buildSettingsSection(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Obx(() {
      final bool notificationsEnabled = _notificationsEnabled();
      final List<PaymentMethodModel> methods = paymentController.paymentMethods;

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
                      onPressed: _showAddCardDialog,
                      icon: Icon(
                        Icons.add_rounded,
                        color: isDark
                            ? AppColors.purpleLight
                            : AppColors.primary,
                      ),
                      label: Text(
                        'Добавить карту',
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
                Text(
                  'Сохранённые методы оплаты используются при оформлении заказа. Полные реквизиты карты и CVV не хранятся.',
                  style: TextStyle(
                    color: isDark
                        ? AppColors.darkMutedForeground
                        : AppColors.mutedForeground,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                if (methods.isEmpty)
                  Text(
                    'У вас пока нет способов оплаты',
                    style: TextStyle(
                      color: isDark
                          ? AppColors.darkMutedForeground
                          : AppColors.mutedForeground,
                    ),
                  )
                else
                  ...methods.map((method) => _buildPaymentMethodTile(context, method)),
              ],
            ),
          ),
        ],
      );
    });
  }

  Widget _buildProfileActions(BuildContext context, bool isDark) {
    if (!isEditing) {
      return Align(
        alignment: Alignment.centerRight,
        child: TextButton.icon(
          onPressed: _startEditing,
          icon: Icon(
            Icons.edit_outlined,
            size: 18,
            color: isDark ? AppColors.purpleLight : AppColors.primary,
          ),
          label: Text(
            'Редактировать',
            style: TextStyle(
              color: isDark ? AppColors.purpleLight : AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: handleCancel,
            style: OutlinedButton.styleFrom(
              foregroundColor:
              isDark ? AppColors.purpleLight : AppColors.primary,
              side: BorderSide(
                color: isDark ? AppColors.darkBorder : AppColors.border,
              ),
              minimumSize: const Size.fromHeight(46),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text('Отмена'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: DecoratedBox(
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
                minimumSize: const Size.fromHeight(46),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text('Сохранить'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoSection(BuildContext context, User user) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return _card(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Личные данные',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Редактируйте основные данные профиля',
            style: TextStyle(
              fontSize: 13,
              color: isDark
                  ? AppColors.darkMutedForeground
                  : AppColors.mutedForeground,
            ),
          ),
          const SizedBox(height: 14),
          _buildProfileActions(context, isDark),
          const SizedBox(height: 16),
          _inputField(
            context,
            'Имя',
            nameController,
                (String val) => editedUser = editedUser?.copyWith(name: val),
          ),
          _inputField(
            context,
            'Email',
            emailController,
                (String val) => editedUser = editedUser?.copyWith(email: val),
          ),
          _inputField(
            context,
            'Телефон',
            phoneController,
                (String val) => editedUser = editedUser?.copyWith(phone: val),
          ),
          _inputField(
            context,
            'Адрес доставки',
            addressController,
                (String val) => editedUser = editedUser?.copyWith(address: val),
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
                            color:
                            (isDark ? AppColors.purple : AppColors.primary)
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
                              .where((String n) => n.isNotEmpty)
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

class PaymentCardFormResult {
  final String cardNumber;
  final String expiryMonth;
  final String expiryYear;
  final String cvv;
  final bool setAsDefault;

  const PaymentCardFormResult({
    required this.cardNumber,
    required this.expiryMonth,
    required this.expiryYear,
    required this.cvv,
    required this.setAsDefault,
  });
}

class _PaymentCardBottomSheet extends StatefulWidget {
  final PaymentMethodModel? method;

  const _PaymentCardBottomSheet({
    this.method,
  });

  @override
  State<_PaymentCardBottomSheet> createState() => _PaymentCardBottomSheetState();
}

class _PaymentCardBottomSheetState extends State<_PaymentCardBottomSheet> {
  late final TextEditingController cardNumberController;
  late final TextEditingController monthController;
  late final TextEditingController yearController;
  late final TextEditingController cvvController;

  bool setAsDefault = false;

  bool get isEdit => widget.method != null;

  @override
  void initState() {
    super.initState();

    cardNumberController =
        TextEditingController(text: widget.method?.maskedNumber ?? '');
    monthController =
        TextEditingController(text: widget.method?.expiryMonth ?? '');
    yearController =
        TextEditingController(text: widget.method?.expiryYear ?? '');
    cvvController = TextEditingController();
    setAsDefault = widget.method?.isDefault ?? false;
  }

  @override
  void dispose() {
    FocusManager.instance.primaryFocus?.unfocus();
    cardNumberController.dispose();
    monthController.dispose();
    yearController.dispose();
    cvvController.dispose();
    super.dispose();
  }

  String _digitsOnly(String value) => value.replaceAll(RegExp(r'[^0-9]'), '');

  String _formatCardNumber(String value) {
    final String digits = _digitsOnly(value);
    final String limited = digits.length > 16 ? digits.substring(0, 16) : digits;

    final List<String> chunks = <String>[];
    for (int i = 0; i < limited.length; i += 4) {
      final int end = (i + 4 < limited.length) ? i + 4 : limited.length;
      chunks.add(limited.substring(i, end));
    }

    return chunks.join(' ');
  }

  void _submit() {
    final String cardNumber = cardNumberController.text.trim();
    final String expiryMonth = monthController.text.trim();
    final String expiryYear = yearController.text.trim();
    final String cvv = cvvController.text.trim();

    if (!isEdit) {
      final String digits = _digitsOnly(cardNumber);
      if (digits.length != 16) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          const SnackBar(content: Text('Номер карты должен содержать 16 цифр')),
        );
        return;
      }
    }

    final int? month = int.tryParse(expiryMonth);
    if (month == null || month < 1 || month > 12) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(content: Text('Введите корректный месяц')),
      );
      return;
    }

    final String normalizedYear = _digitsOnly(expiryYear);
    if (normalizedYear.length != 2) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(content: Text('Введите год в формате ГГ')),
      );
      return;
    }

    if (cvv.length != 3 || int.tryParse(cvv) == null) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(content: Text('CVV должен содержать 3 цифры')),
      );
      return;
    }

    FocusScope.of(context).unfocus();

    Navigator.of(context).pop(
      PaymentCardFormResult(
        cardNumber: cardNumber,
        expiryMonth: expiryMonth.padLeft(2, '0'),
        expiryYear: normalizedYear,
        cvv: cvv,
        setAsDefault: setAsDefault,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isEdit ? 'Редактировать карту' : 'Добавить карту',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: cardNumberController,
              enabled: !isEdit,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              onChanged: isEdit
                  ? null
                  : (String value) {
                final String formatted = _formatCardNumber(value);
                if (formatted != value) {
                  cardNumberController.value = TextEditingValue(
                    text: formatted,
                    selection: TextSelection.collapsed(
                      offset: formatted.length,
                    ),
                  );
                }
              },
              decoration: InputDecoration(
                labelText: 'Номер карты',
                hintText: '0000 0000 0000 0000',
                helperText: isEdit
                    ? 'Полный номер карты повторно не хранится'
                    : 'Сохраняется только маска карты',
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: monthController,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Месяц',
                      hintText: 'MM',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: yearController,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Год',
                      hintText: 'ГГ',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: cvvController,
              keyboardType: TextInputType.number,
              obscureText: true,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              decoration: const InputDecoration(
                labelText: 'CVV/CVC',
                hintText: '123',
              ),
            ),
            const SizedBox(height: 10),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Сделать способом по умолчанию'),
              value: setAsDefault,
              activeThumbColor: isDark ? AppColors.purple : AppColors.primary,
              onChanged: (bool value) {
                FocusScope.of(context).unfocus();
                setState(() {
                  setAsDefault = value;
                });
              },
            ),
            const SizedBox(height: 12),
            Text(
              'CVV не сохраняется. После добавления карты в приложении хранится только маска карты, срок действия и локальный токен.',
              style: TextStyle(
                fontSize: 12,
                height: 1.4,
                color: isDark
                    ? AppColors.darkMutedForeground
                    : AppColors.mutedForeground,
              ),
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
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(54),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: Text(isEdit ? 'Сохранить' : 'Добавить'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentCardBottomSheetState extends State<_PaymentCardBottomSheet> {
  late final TextEditingController titleController;
  late final TextEditingController holderController;
  late final TextEditingController cardNumberController;
  late final TextEditingController monthController;
  late final TextEditingController yearController;
  late final TextEditingController bankController;

  bool setAsDefault = false;

  bool get isEdit => widget.method != null;

  @override
  void initState() {
    super.initState();

    titleController = TextEditingController(text: widget.method?.title ?? '');
    holderController =
        TextEditingController(text: widget.method?.holderName ?? '');
    cardNumberController =
        TextEditingController(text: widget.method?.maskedNumber ?? '');
    monthController =
        TextEditingController(text: widget.method?.expiryMonth ?? '');
    yearController = TextEditingController(text: widget.method?.expiryYear ?? '');
    bankController = TextEditingController(text: widget.method?.bankName ?? '');
    setAsDefault = widget.method?.isDefault ?? false;
  }

  @override
  void dispose() {
    FocusManager.instance.primaryFocus?.unfocus();
    titleController.dispose();
    holderController.dispose();
    cardNumberController.dispose();
    monthController.dispose();
    yearController.dispose();
    bankController.dispose();
    super.dispose();
  }

  String _digitsOnly(String value) => value.replaceAll(RegExp(r'[^0-9]'), '');

  String _formatCardNumber(String value) {
    final String digits = _digitsOnly(value);
    final String limited = digits.length > 16 ? digits.substring(0, 16) : digits;

    final List<String> chunks = <String>[];
    for (int i = 0; i < limited.length; i += 4) {
      final int end = (i + 4 < limited.length) ? i + 4 : limited.length;
      chunks.add(limited.substring(i, end));
    }

    return chunks.join(' ');
  }

  void _submit() {
    final String title = titleController.text.trim();
    final String holderName = holderController.text.trim();
    final String cardNumber = cardNumberController.text.trim();
    final String expiryMonth = monthController.text.trim();
    final String expiryYear = yearController.text.trim();
    final String bankName = bankController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(content: Text('Введите название карты')),
      );
      return;
    }

    if (holderName.isEmpty) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(content: Text('Введите имя держателя карты')),
      );
      return;
    }

    if (!isEdit) {
      final String digits = _digitsOnly(cardNumber);
      if (digits.length != 16) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          const SnackBar(content: Text('Номер карты должен содержать 16 цифр')),
        );
        return;
      }
    }

    final int? month = int.tryParse(expiryMonth);
    if (month == null || month < 1 || month > 12) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(content: Text('Введите корректный месяц')),
      );
      return;
    }

    final String normalizedYear = _digitsOnly(expiryYear);
    if (normalizedYear.length != 2) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(content: Text('Введите год в формате ГГ')),
      );
      return;
    }

    FocusScope.of(context).unfocus();

    Navigator.of(context).pop(
      PaymentCardFormResult(
        title: title,
        holderName: holderName,
        cardNumber: cardNumber,
        expiryMonth: expiryMonth.padLeft(2, '0'),
        expiryYear: normalizedYear,
        bankName: bankName.isEmpty ? null : bankName,
        setAsDefault: setAsDefault,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isEdit ? 'Редактировать карту' : 'Добавить карту',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: titleController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Название',
                hintText: 'Например, Личная карта',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: holderController,
              textCapitalization: TextCapitalization.characters,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Держатель карты',
                hintText: 'IVAN IVANOV',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: cardNumberController,
              enabled: !isEdit,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              onChanged: isEdit
                  ? null
                  : (String value) {
                final String formatted = _formatCardNumber(value);
                if (formatted != value) {
                  cardNumberController.value = TextEditingValue(
                    text: formatted,
                    selection: TextSelection.collapsed(
                      offset: formatted.length,
                    ),
                  );
                }
              },
              decoration: InputDecoration(
                labelText: 'Номер карты',
                hintText: '0000 0000 0000 0000',
                helperText: isEdit
                    ? 'Полный номер карты повторно не хранится'
                    : 'Сохраняется только маска и токен',
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: monthController,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Месяц',
                      hintText: 'MM',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: yearController,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Год',
                      hintText: 'ГГ',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: bankController,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              decoration: const InputDecoration(
                labelText: 'Банк',
                hintText: 'Например, Kaspi / Halyk',
              ),
            ),
            const SizedBox(height: 10),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Сделать способом по умолчанию'),
              value: setAsDefault,
              activeThumbColor: isDark ? AppColors.purple : AppColors.primary,
              onChanged: (bool value) {
                FocusScope.of(context).unfocus();
                setState(() {
                  setAsDefault = value;
                });
              },
            ),
            const SizedBox(height: 12),
            Text(
              'CVV и полный номер карты не сохраняются. Для демонстрации хранится только маска карты и локальный токен.',
              style: TextStyle(
                fontSize: 12,
                height: 1.4,
                color: isDark
                    ? AppColors.darkMutedForeground
                    : AppColors.mutedForeground,
              ),
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
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(54),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: Text(isEdit ? 'Сохранить' : 'Добавить'),
                ),
              ),
            ),
          ],
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
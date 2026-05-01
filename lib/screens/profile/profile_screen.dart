import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../api/local_demo_service.dart';
import '../../api/notification_service.dart';
import '../../controllers/address_book_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/order_controller.dart';
import '../../controllers/payment_controller.dart';
import '../../controllers/settings_controller.dart';
import '../../models/payment_method_model.dart';
import '../../models/user.dart';
import '../../utils/app_colors.dart';
import '../../utils/phone_input_formatter.dart';
import 'profile_address_section.dart';

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
  final AddressBookController addressBookController =
  Get.find<AddressBookController>();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  User? editedUser;
  User? savedUserSnapshot;

  bool isLoading = true;
  bool isEditing = false;
  String activeSection = 'info';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() {
      isLoading = true;
    });

    final User? profile = await authController.getProfile();

    await orderController.fetchUserOrders();
    await paymentController.loadPaymentMethods();
    await paymentController.loadPaymentTransactions();
    await addressBookController.loadAddresses();

    if (!mounted) {
      return;
    }

    if (profile != null) {
      editedUser = profile;
      savedUserSnapshot = profile;

      nameController.text = profile.name;
      emailController.text = profile.email;
      phoneController.text = profile.phone;
    }

    setState(() {
      isEditing = false;
      isLoading = false;
    });
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _startEditing() {
    final User? user = editedUser;

    if (user == null) {
      return;
    }

    savedUserSnapshot = user;

    nameController.text = user.name;
    emailController.text = user.email;
    phoneController.text = user.phone;

    setState(() {
      isEditing = true;
      activeSection = 'info';
    });
  }

  void _cancelEditing() {
    final User? user = savedUserSnapshot ?? editedUser;

    if (user == null) {
      return;
    }

    editedUser = user;

    nameController.text = user.name;
    emailController.text = user.email;
    phoneController.text = user.phone;

    FocusManager.instance.primaryFocus?.unfocus();

    setState(() {
      isEditing = false;
    });
  }

  Future<void> _saveProfile() async {
    final User? current = editedUser;

    if (current == null) {
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();

    final User updatedUser = current.copyWith(
      name: nameController.text.trim(),
      email: emailController.text.trim(),
      phone: phoneController.text.trim(),
    );

    setState(() {
      isLoading = true;
    });

    final User? updated = await authController.updateProfile(updatedUser);

    if (!mounted) {
      return;
    }

    if (updated != null) {
      editedUser = updated;
      savedUserSnapshot = updated;

      nameController.text = updated.name;
      emailController.text = updated.email;
      phoneController.text = updated.phone;

      _showMessage('Профиль успешно обновлён');
    } else {
      _showMessage('Не удалось сохранить профиль');
    }

    setState(() {
      isEditing = false;
      isLoading = false;
    });
  }

  void _changeSection(String section) {
    if (isEditing && section != 'info') {
      _cancelEditing();
    }

    setState(() {
      activeSection = section;
    });
  }

  Future<void> _logout() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Выход из аккаунта'),
          content: const Text('Вы уверены, что хотите выйти?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Выйти'),
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
        return AlertDialog(
          title: const Text('Сбросить демо-данные'),
          content: const Text(
            'Это очистит текущую демо-сессию и вернёт приложение к начальному состоянию.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Сбросить'),
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

    _showMessage('Демо-данные сброшены');
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
      body: 'Уведомления работают корректно',
    );
  }

  Future<void> _showAddCardDialog() async {
    final PaymentCardFormResult? result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (BuildContext context) {
        return const _PaymentCardBottomSheet();
      },
    );

    if (result == null) {
      return;
    }

    try {
      await paymentController.addCardMethod(
        cardNumber: result.cardNumber,
        holderName: result.holderName,
        expiryMonth: result.expiryMonth,
        expiryYear: result.expiryYear,
        setAsDefault: result.setAsDefault,
      );

      _showMessage('Карта добавлена');
    } catch (e) {
      _showMessage('Ошибка при добавлении карты: $e');
    }
  }

  Future<void> _showEditCardDialog(PaymentMethodModel method) async {
    final PaymentCardFormResult? result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (BuildContext context) {
        return _PaymentCardBottomSheet(method: method);
      },
    );

    if (result == null) {
      return;
    }

    try {
      await paymentController.updateCardMethod(
        id: method.id,
        cardNumber: result.cardNumber,
        holderName: result.holderName,
        expiryMonth: result.expiryMonth,
        expiryYear: result.expiryYear,
        isDefault: result.setAsDefault,
      );

      _showMessage('Карта обновлена');
    } catch (e) {
      _showMessage('Ошибка при обновлении карты: $e');
    }
  }

  Future<void> _setDefaultPaymentMethod(String id) async {
    await paymentController.setDefaultMethod(id);
    _showMessage('Способ оплаты по умолчанию обновлён');
  }

  Future<void> _deletePaymentMethod(String id) async {
    await paymentController.deleteMethod(id);
    _showMessage('Способ оплаты удалён');
  }

  Widget _sectionButton({
    required String id,
    required String title,
    required IconData icon,
  }) {
    final bool selected = activeSection == id;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final Color inactiveColor =
    isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _changeSection(id),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: selected
                ? (isDark
                ? AppColors.darkBrandGradient
                : AppColors.brandGradient)
                : null,
            borderRadius: BorderRadius.circular(18),
            boxShadow: selected
                ? [
              BoxShadow(
                color: (isDark ? AppColors.purple : AppColors.primary)
                    .withValues(alpha: 0.18),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ]
                : [],
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: selected ? Colors.white : inactiveColor,
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  color: selected ? Colors.white : inactiveColor,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navigation() {
    return _card(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          _sectionButton(
            id: 'info',
            title: 'Данные',
            icon: Icons.person_outline_rounded,
          ),
          _sectionButton(
            id: 'loyalty',
            title: 'Лояльность',
            icon: Icons.card_giftcard_rounded,
          ),
          _sectionButton(
            id: 'settings',
            title: 'Настройки',
            icon: Icons.settings_outlined,
          ),
        ],
      ),
    );
  }

  Widget _card({
    required Widget child,
    EdgeInsets padding = const EdgeInsets.all(16),
  }) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        gradient: isDark ? AppColors.darkCardGradient : null,
        color: isDark ? null : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.border,
        ),
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

  Widget _inputField(
      String label,
      TextEditingController controller,
      void Function(String value) onChanged, {
        TextInputType? keyboardType,
        List<TextInputFormatter>? inputFormatters,
      }) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        enabled: isEditing,
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: isDark ? AppColors.darkSurfaceElevated : Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: isDark ? AppColors.darkBorder : AppColors.border,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: isDark ? AppColors.darkBorder : AppColors.border,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: isDark ? AppColors.purple : AppColors.primary,
              width: 1.4,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection() {
    final User? user = editedUser;

    if (user == null) {
      return _card(
        child: const Text('Профиль не загружен'),
      );
    }

    return Column(
      children: [
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Личные данные',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (!isEditing)
                    IconButton(
                      onPressed: _startEditing,
                      icon: const Icon(Icons.edit_outlined),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              _inputField(
                'Имя',
                nameController,
                    (String value) {
                  editedUser = editedUser?.copyWith(name: value);
                },
              ),
              _inputField(
                'Телефон',
                phoneController,
                    (String value) {
                  editedUser = editedUser?.copyWith(phone: value);
                },
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  PhoneInputFormatter(),
                ],
              ),
              _inputField(
                'Почта',
                emailController,
                    (String value) {
                  editedUser = editedUser?.copyWith(email: value);
                },
                keyboardType: TextInputType.emailAddress,
              ),
              if (isEditing) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _cancelEditing,
                        child: const Text('Отмена'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: Theme.of(context).brightness ==
                              Brightness.dark
                              ? AppColors.darkBrandGradient
                              : AppColors.brandGradient,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: ElevatedButton(
                          onPressed: _saveProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: const Text('Сохранить'),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        ProfileAddressSection(
          controller: addressBookController,
          onMessage: _showMessage,
        ),
      ],
    );
  }

  Widget _buildLoyaltySection() {
    final User? user = editedUser;

    if (user == null) {
      return _card(
        child: const Text('Данные лояльности не загружены'),
      );
    }

    final double spentFromOrders = orderController.orders.fold(
      0,
          (double sum, order) => sum + order.total,
    );

    final double totalSpent =
    spentFromOrders > user.totalSpent ? spentFromOrders : user.totalSpent;

    String level = 'Bronze';
    int nextLevel = 5000;

    if (totalSpent >= 15000) {
      level = 'Gold';
      nextLevel = totalSpent.round();
    } else if (totalSpent >= 5000) {
      level = 'Silver';
      nextLevel = 15000;
    }

    final int points = totalSpent.round();
    final int remaining = (nextLevel - totalSpent).clamp(0, nextLevel).round();

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Программа лояльности',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.darkBrandGradient
                  : AppColors.brandGradient,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: (Theme.of(context).brightness == Brightness.dark
                      ? AppColors.purple
                      : AppColors.primary)
                      .withValues(alpha: 0.18),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  level,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$points бонусов',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Покупок на ${totalSpent.toStringAsFixed(0)} ₽',
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (level != 'Gold')
            Text(
              'До следующего уровня осталось $remaining ₽',
              style: const TextStyle(fontWeight: FontWeight.w600),
            )
          else
            const Text(
              'Максимальный уровень достигнут',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
        ],
      ),
    );
  }

  Widget _paymentMethodTile(PaymentMethodModel method) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceElevated : AppColors.primaryLight,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : Colors.transparent,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient:
              isDark ? AppColors.darkBrandGradient : AppColors.brandGradient,
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
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (method.subtitle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    method.subtitle,
                    style: TextStyle(
                      color: isDark
                          ? AppColors.darkMutedForeground
                          : AppColors.mutedForeground,
                    ),
                  ),
                ],
                if (method.isDefault) ...[
                  const SizedBox(height: 6),
                  Text(
                    'По умолчанию',
                    style: TextStyle(
                      color: isDark ? AppColors.purpleLight : AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
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
              return [
                const PopupMenuItem(
                  value: 'default',
                  child: Text('Сделать основным'),
                ),
                if (method.isCard && !method.isSystem)
                  const PopupMenuItem(
                    value: 'edit',
                    child: Text('Изменить'),
                  ),
                if (method.isCard && !method.isSystem)
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('Удалить'),
                  ),
              ];
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection() {
    return Obx(() {
      final bool notificationsEnabled = _notificationsEnabled();
      final List<PaymentMethodModel> methods = paymentController.paymentMethods;

      return Column(
        children: [
          _card(
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
                        ? 'Уведомления включены'
                        : 'Уведомления выключены',
                  ),
                  value: notificationsEnabled,
                  activeColor: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.purple
                      : AppColors.primary,
                  onChanged: _toggleAllNotifications,
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    Icons.notifications_active_outlined,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.purpleLight
                        : AppColors.primary,
                  ),
                  title: const Text('Проверить уведомления'),
                  subtitle: const Text('Показать тестовое уведомление'),
                  onTap: _sendTestNotification,
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Тёмная тема'),
                  value: settingsController.darkTheme.value,
                  activeColor: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.purple
                      : AppColors.primary,
                  onChanged: settingsController.setDarkTheme,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _card(
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
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Добавить карту'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (methods.isEmpty)
                  const Text('Способы оплаты пока не добавлены')
                else
                  ...methods.map(_paymentMethodTile),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _card(
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
                const Text(
                  'Сброс вернёт приложение к начальному состоянию для показа на защите.',
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: Theme.of(context).brightness == Brightness.dark
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
                        minimumSize: const Size.fromHeight(48),
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
        ],
      );
    });
  }

  Widget _activeSection() {
    if (activeSection == 'loyalty') {
      return _buildLoyaltySection();
    }

    if (activeSection == 'settings') {
      return _buildSettingsSection();
    }

    return _buildInfoSection();
  }

  @override
  Widget build(BuildContext context) {
    final User? user = editedUser;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Профиль'),
        actions: [
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout_rounded),
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
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : user == null
            ? const Center(child: Text('Пользователь не найден'))
            : RefreshIndicator(
          onRefresh: _loadProfile,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _card(
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
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        user.name.isNotEmpty
                            ? user.name[0].toUpperCase()
                            : 'U',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
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
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
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
                          if (user.phone.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              user.phone,
                              style: TextStyle(
                                color: isDark
                                    ? AppColors.darkMutedForeground
                                    : AppColors.mutedForeground,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _navigation(),
              const SizedBox(height: 12),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 240),
                child: KeyedSubtree(
                  key: ValueKey(activeSection),
                  child: _activeSection(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PaymentCardFormResult {
  final String cardNumber;
  final String holderName;
  final String expiryMonth;
  final String expiryYear;
  final bool setAsDefault;

  const PaymentCardFormResult({
    required this.cardNumber,
    required this.holderName,
    required this.expiryMonth,
    required this.expiryYear,
    required this.setAsDefault,
  });
}

class _PaymentCardBottomSheet extends StatefulWidget {
  final PaymentMethodModel? method;

  const _PaymentCardBottomSheet({
    this.method,
  });

  @override
  State<_PaymentCardBottomSheet> createState() =>
      _PaymentCardBottomSheetState();
}

class _PaymentCardBottomSheetState extends State<_PaymentCardBottomSheet> {
  final TextEditingController cardNumberController = TextEditingController();
  final TextEditingController holderNameController = TextEditingController();
  final TextEditingController expiryMonthController = TextEditingController();
  final TextEditingController expiryYearController = TextEditingController();

  bool setAsDefault = false;

  @override
  void initState() {
    super.initState();

    final PaymentMethodModel? method = widget.method;

    if (method != null) {
      cardNumberController.text = method.maskedNumber;
      expiryMonthController.text = method.expiryMonth?.toString() ?? '';
      expiryYearController.text = method.expiryYear?.toString() ?? '';
      setAsDefault = method.isDefault;
    }
  }

  @override
  void dispose() {
    cardNumberController.dispose();
    holderNameController.dispose();
    expiryMonthController.dispose();
    expiryYearController.dispose();
    super.dispose();
  }

  void _submit() {
    final String cardNumber = cardNumberController.text.trim();
    final String month = expiryMonthController.text.trim();
    final String year = expiryYearController.text.trim();

    if (cardNumber.isEmpty || month.isEmpty || year.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Заполните данные карты')),
      );
      return;
    }

    Navigator.of(context).pop(
      PaymentCardFormResult(
        cardNumber: cardNumber,
        holderName: holderNameController.text.trim(),
        expiryMonth: month,
        expiryYear: year,
        setAsDefault: setAsDefault,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isEdit = widget.method != null;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: isDark ? AppColors.darkCardGradient : null,
        color: isDark ? null : Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: 18,
          right: 18,
          top: 18,
          bottom: MediaQuery.of(context).viewInsets.bottom + 18,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBorder : AppColors.border,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 18),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  isEdit ? 'Изменить карту' : 'Добавить карту',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: cardNumberController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Номер карты',
                  hintText: '2202 2022 2022 2022',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: holderNameController,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Имя владельца',
                  hintText: 'IVAN IVANOV',
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: expiryMonthController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Месяц',
                        hintText: '12',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: expiryYearController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Год',
                        hintText: '2030',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: setAsDefault,
                activeColor: isDark ? AppColors.purple : AppColors.primary,
                title: const Text('Сделать картой по умолчанию'),
                onChanged: (bool value) {
                  setState(() {
                    setAsDefault = value;
                  });
                },
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient:
                    isDark ? AppColors.darkBrandGradient : AppColors.brandGradient,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: const Text('Сохранить'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
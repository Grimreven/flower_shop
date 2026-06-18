import 'package:flutter/material.dart';

import '../../api/server_api_service.dart';
import '../../utils/app_colors.dart';
import 'admin_user_orders_screen.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  bool isLoading = true;
  List<Map<String, dynamic>> users = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> roles = <Map<String, dynamic>>[];

  @override
  void initState() {
    super.initState();
    loadUsers();
  }

  Future<void> loadUsers() async {
    try {
      final List<Map<String, dynamic>> usersData =
      await ServerApiService.getAdminUsers();
      final List<Map<String, dynamic>> rolesData =
      await ServerApiService.getAdminRoles();

      if (!mounted) {
        return;
      }

      setState(() {
        users = usersData;
        roles = rolesData;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        isLoading = false;
      });

      _showMessage('Ошибка: $e');
    }
  }

  int _toInt(dynamic value) {
    if (value == null) {
      return 0;
    }

    if (value is int) {
      return value;
    }

    return int.tryParse(value.toString()) ?? 0;
  }

  double _toDouble(dynamic value) {
    if (value == null) {
      return 0;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString()) ?? 0;
  }

  String _formatMoney(dynamic value) {
    return '${_toDouble(value).toStringAsFixed(0)} ₽';
  }

  String _roleText(String role) {
    switch (role) {
      case 'admin':
        return 'Администратор';
      case 'courier':
        return 'Курьер';
      case 'customer':
        return 'Клиент';
      default:
        return role;
    }
  }

  String _formatDate(dynamic value) {
    if (value == null) {
      return 'Заказов не было';
    }

    final DateTime? date = DateTime.tryParse(value.toString());

    if (date == null) {
      return value.toString();
    }

    final String day = date.day.toString().padLeft(2, '0');
    final String month = date.month.toString().padLeft(2, '0');
    final String year = date.year.toString();

    return '$day.$month.$year';
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Color _accentColor(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? AppColors.purpleLight : AppColors.primary;
  }

  Color _mutedColor(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
  }

  Color _borderColor(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? AppColors.darkBorder : AppColors.border;
  }

  BoxDecoration _cardDecoration(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return BoxDecoration(
      gradient: isDark ? AppColors.darkCardGradient : null,
      color: isDark ? null : Colors.white,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(
        color: _borderColor(context),
      ),
      boxShadow: [
        BoxShadow(
          color: isDark
              ? Colors.black.withOpacity(0.20)
              : Colors.black.withOpacity(0.055),
          blurRadius: 16,
          offset: const Offset(0, 7),
        ),
      ],
    );
  }

  Future<void> _openUserOrders(Map<String, dynamic> user) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AdminUserOrdersScreen(user: user),
      ),
    );
  }

  Future<void> _changeRole(Map<String, dynamic> user) async {
    final int currentRoleId = _toInt(user['role_id']);
    int selectedRoleId = currentRoleId;

    final int? result = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext sheetContext) {
        final bool isDark = Theme.of(sheetContext).brightness == Brightness.dark;
        final Color textColor = Theme.of(sheetContext).colorScheme.onSurface;

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                gradient: isDark ? AppColors.darkCardGradient : null,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
                border: Border(
                  top: BorderSide(
                    color: isDark ? AppColors.darkBorder : AppColors.border,
                  ),
                ),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color:
                        isDark ? AppColors.darkBorder : AppColors.border,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Назначить роль',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      user['email']?.toString() ?? '',
                      style: TextStyle(
                        color: _mutedColor(sheetContext),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 14),
                    ...roles.map((Map<String, dynamic> role) {
                      final int roleId = _toInt(role['id']);
                      final String roleName = role['name']?.toString() ?? '';
                      final bool selected = selectedRoleId == roleId;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: selected
                              ? _accentColor(sheetContext).withOpacity(0.12)
                              : isDark
                              ? AppColors.darkSurfaceElevated
                              : const Color(0xFFF8F4F7),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: selected
                                ? _accentColor(sheetContext)
                                : _borderColor(sheetContext),
                          ),
                        ),
                        child: RadioListTile<int>(
                          value: roleId,
                          groupValue: selectedRoleId,
                          activeColor: _accentColor(sheetContext),
                          title: Text(
                            _roleText(roleName),
                            style: TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          subtitle: Text(
                            roleName,
                            style: TextStyle(
                              color: _mutedColor(sheetContext),
                            ),
                          ),
                          onChanged: (int? value) {
                            if (value == null) {
                              return;
                            }

                            setModalState(() {
                              selectedRoleId = value;
                            });
                          },
                        ),
                      );
                    }),
                    const SizedBox(height: 12),
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
                            Navigator.of(sheetContext).pop(selectedRoleId);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(52),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: const Text(
                            'Сохранить роль',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (result == null || result == currentRoleId) {
      return;
    }

    try {
      await ServerApiService.updateAdminUserRole(
        userId: _toInt(user['id']),
        roleId: result,
      );

      await loadUsers();

      if (!mounted) {
        return;
      }

      _showMessage('Роль пользователя обновлена');
    } catch (e) {
      _showMessage('Ошибка изменения роли: $e');
    }
  }

  Widget _userCard(BuildContext context, Map<String, dynamic> user) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = Theme.of(context).colorScheme.onSurface;
    final String role = user['role']?.toString() ?? 'customer';

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 7, 14, 7),
      padding: const EdgeInsets.all(15),
      decoration: _cardDecoration(context),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: isDark
                      ? AppColors.darkBrandGradient
                      : AppColors.brandGradient,
                  borderRadius: BorderRadius.circular(17),
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: Colors.white,
                  size: 29,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user['name']?.toString() ?? 'Пользователь',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user['email']?.toString() ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _mutedColor(context),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if ((user['phone']?.toString() ?? '').isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        user['phone'].toString(),
                        style: TextStyle(
                          color: _mutedColor(context),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: _accentColor(context).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _roleText(role),
                  style: TextStyle(
                    color: _accentColor(context),
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          Row(
            children: [
              Expanded(
                child: _miniInfo(
                  context,
                  icon: Icons.receipt_long_rounded,
                  title: 'Заказы',
                  value: '${user['orders_count'] ?? 0}',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _miniInfo(
                  context,
                  icon: Icons.payments_rounded,
                  title: 'Сумма',
                  value: _formatMoney(user['orders_total']),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _miniInfo(
                  context,
                  icon: Icons.calendar_month_rounded,
                  title: 'Последний',
                  value: _formatDate(user['last_order_at']),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _openUserOrders(user),
                  icon: const Icon(Icons.receipt_long_rounded),
                  label: const Text('Заказы'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _changeRole(user),
                  icon: const Icon(Icons.manage_accounts_rounded),
                  label: const Text('Роль'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accentColor(context),
                    foregroundColor: Colors.white,
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniInfo(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String value,
      }) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceElevated : const Color(0xFFF8F4F7),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: _borderColor(context),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: _accentColor(context),
            size: 20,
          ),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: _mutedColor(context),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryHeader(BuildContext context) {
    final Color textColor = Theme.of(context).colorScheme.onSurface;

    final int admins = users.where((u) => u['role']?.toString() == 'admin').length;
    final int couriers =
        users.where((u) => u['role']?.toString() == 'courier').length;
    final int customers =
        users.where((u) => u['role']?.toString() == 'customer').length;

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 12, 14, 8),
      padding: const EdgeInsets.all(15),
      decoration: _cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Пользователи системы',
            style: TextStyle(
              color: textColor,
              fontSize: 19,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _miniInfo(
                  context,
                  icon: Icons.people_rounded,
                  title: 'Всего',
                  value: '${users.length}',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _miniInfo(
                  context,
                  icon: Icons.admin_panel_settings_rounded,
                  title: 'Админы',
                  value: '$admins',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _miniInfo(
                  context,
                  icon: Icons.delivery_dining_rounded,
                  title: 'Курьеры',
                  value: '$couriers',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _miniInfo(
                  context,
                  icon: Icons.person_rounded,
                  title: 'Клиенты',
                  value: '$customers',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bg = Theme.of(context).scaffoldBackgroundColor;
    final Color textColor = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Text(
          'Пользователи',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w900,
          ),
        ),
        backgroundColor: bg,
        foregroundColor: textColor,
        elevation: 0,
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
            : RefreshIndicator(
          onRefresh: loadUsers,
          child: ListView(
            padding: const EdgeInsets.only(bottom: 16),
            children: [
              _summaryHeader(context),
              if (users.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      'Пользователи не найдены',
                      style: TextStyle(
                        color: _mutedColor(context),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                )
              else
                ...users.map(
                      (Map<String, dynamic> user) =>
                      _userCard(context, user),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';

import '../../api/server_api_service.dart';
import '../../utils/app_colors.dart';

class AdminUserOrdersScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const AdminUserOrdersScreen({
    super.key,
    required this.user,
  });

  @override
  State<AdminUserOrdersScreen> createState() => _AdminUserOrdersScreenState();
}

class _AdminUserOrdersScreenState extends State<AdminUserOrdersScreen> {
  bool isLoading = true;
  Map<String, dynamic>? userData;
  List<Map<String, dynamic>> orders = <Map<String, dynamic>>[];

  @override
  void initState() {
    super.initState();
    loadOrders();
  }

  Future<void> loadOrders() async {
    try {
      final int userId = _toInt(widget.user['id']);
      final Map<String, dynamic> data =
      await ServerApiService.getAdminUserOrders(userId);

      final List<dynamic> rawOrders = data['orders'] as List<dynamic>? ?? [];

      if (!mounted) {
        return;
      }

      setState(() {
        userData = Map<String, dynamic>.from(
          data['user'] as Map? ?? widget.user,
        );
        orders = rawOrders
            .map((dynamic item) => Map<String, dynamic>.from(item as Map))
            .toList();
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

  String _formatDate(dynamic value) {
    if (value == null) {
      return 'Дата не указана';
    }

    final DateTime? date = DateTime.tryParse(value.toString());

    if (date == null) {
      return value.toString();
    }

    final String day = date.day.toString().padLeft(2, '0');
    final String month = date.month.toString().padLeft(2, '0');
    final String year = date.year.toString();
    final String hour = date.hour.toString().padLeft(2, '0');
    final String minute = date.minute.toString().padLeft(2, '0');

    return '$day.$month.$year $hour:$minute';
  }

  String _statusText(dynamic status) {
    switch (status?.toString()) {
      case 'new':
        return 'Новый';
      case 'accepted':
        return 'Принят';
      case 'assembling':
        return 'Собирается';
      case 'courier':
        return 'У курьера';
      case 'delivered':
        return 'Доставлен';
      case 'cancelled':
        return 'Отменён';
      default:
        return status?.toString() ?? 'Неизвестно';
    }
  }

  String _paymentText(dynamic method) {
    switch (method?.toString()) {
      case 'cash':
        return 'Наличными';
      case 'card':
        return 'Картой';
      case 'sbp':
        return 'СБП';
      default:
        return method?.toString() ?? 'Не указан';
    }
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

  Widget _userHeader(BuildContext context) {
    final Map<String, dynamic> user = userData ?? widget.user;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = Theme.of(context).colorScheme.onSurface;

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 12, 14, 8),
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(context),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              gradient:
              isDark ? AppColors.darkBrandGradient : AppColors.brandGradient,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.person_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user['name']?.toString() ?? 'Пользователь',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user['email']?.toString() ?? '',
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
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _extractItems(Map<String, dynamic> order) {
    final dynamic raw = order['items'];

    if (raw is List) {
      return raw
          .map((dynamic item) => Map<String, dynamic>.from(item as Map))
          .toList();
    }

    return <Map<String, dynamic>>[];
  }

  Widget _orderCard(BuildContext context, Map<String, dynamic> order) {
    final Color textColor = Theme.of(context).colorScheme.onSurface;
    final List<Map<String, dynamic>> items = _extractItems(order);

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 7, 14, 7),
      padding: const EdgeInsets.all(15),
      decoration: _cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Заказ #${order['id']}',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
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
                  _statusText(order['status']),
                  style: TextStyle(
                    color: _accentColor(context),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _formatDate(order['created_at']),
            style: TextStyle(
              color: _mutedColor(context),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            Text(
              'Состав заказа не найден',
              style: TextStyle(
                color: _mutedColor(context),
              ),
            )
          else
            ...items.map((Map<String, dynamic> item) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 7),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        item['name']?.toString() ?? 'Товар',
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      '${item['quantity']} × ${_formatMoney(item['price'])}',
                      style: TextStyle(
                        color: _mutedColor(context),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }),
          const Divider(height: 22),
          _infoRow(
            context,
            'Товары',
            _formatMoney(order['items_total']),
          ),
          const SizedBox(height: 6),
          _infoRow(
            context,
            'Доставка',
            _formatMoney(order['delivery_cost']),
          ),
          const SizedBox(height: 6),
          _infoRow(
            context,
            'Оплата',
            _paymentText(order['payment_method']),
          ),
          const SizedBox(height: 6),
          _infoRow(
            context,
            'Итого',
            _formatMoney(order['total']),
            bold: true,
          ),
          if ((order['full_address']?.toString() ?? '').isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Адрес: ${order['full_address']}',
              style: TextStyle(
                color: _mutedColor(context),
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoRow(
      BuildContext context,
      String title,
      String value, {
        bool bold = false,
      }) {
    final Color textColor = Theme.of(context).colorScheme.onSurface;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            color: _mutedColor(context),
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: bold ? _accentColor(context) : textColor,
            fontWeight: bold ? FontWeight.w900 : FontWeight.w700,
          ),
        ),
      ],
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
          'Заказы клиента',
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
          onRefresh: loadOrders,
          child: ListView(
            padding: const EdgeInsets.only(bottom: 18),
            children: [
              _userHeader(context),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
                child: Text(
                  'История заказов: ${orders.length}',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (orders.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      'У клиента пока нет заказов',
                      style: TextStyle(
                        color: _mutedColor(context),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                )
              else
                ...orders.map(
                      (Map<String, dynamic> order) =>
                      _orderCard(context, order),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
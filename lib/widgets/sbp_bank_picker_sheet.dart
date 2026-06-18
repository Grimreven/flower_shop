import 'package:flutter/material.dart';

import '../utils/app_colors.dart';

class SbpBank {
  final String name;
  final String subtitle;
  final IconData icon;

  const SbpBank({
    required this.name,
    required this.subtitle,
    required this.icon,
  });
}

class SbpBankPickerSheet extends StatefulWidget {
  const SbpBankPickerSheet({
    super.key,
  });

  @override
  State<SbpBankPickerSheet> createState() => _SbpBankPickerSheetState();
}

class _SbpBankPickerSheetState extends State<SbpBankPickerSheet> {
  final TextEditingController _searchController = TextEditingController();

  final List<SbpBank> _banks = const [
    SbpBank(
      name: 'СберБанк',
      subtitle: 'Оплата через приложение СберБанк Онлайн',
      icon: Icons.account_balance_rounded,
    ),
    SbpBank(
      name: 'Т-Банк',
      subtitle: 'Оплата через приложение Т-Банка',
      icon: Icons.account_balance_wallet_rounded,
    ),
    SbpBank(
      name: 'Альфа-Банк',
      subtitle: 'Оплата через приложение Альфа-Банка',
      icon: Icons.account_balance_rounded,
    ),
    SbpBank(
      name: 'ВТБ',
      subtitle: 'Оплата через приложение ВТБ Онлайн',
      icon: Icons.account_balance_rounded,
    ),
    SbpBank(
      name: 'Газпромбанк',
      subtitle: 'Оплата через мобильный банк',
      icon: Icons.account_balance_rounded,
    ),
    SbpBank(
      name: 'Райффайзен Банк',
      subtitle: 'Оплата через мобильное приложение',
      icon: Icons.account_balance_rounded,
    ),
    SbpBank(
      name: 'Открытие',
      subtitle: 'Оплата через приложение банка',
      icon: Icons.account_balance_rounded,
    ),
    SbpBank(
      name: 'Россельхозбанк',
      subtitle: 'Оплата через мобильный банк',
      icon: Icons.account_balance_rounded,
    ),
    SbpBank(
      name: 'Промсвязьбанк',
      subtitle: 'Оплата через приложение ПСБ',
      icon: Icons.account_balance_rounded,
    ),
    SbpBank(
      name: 'Совкомбанк',
      subtitle: 'Оплата через Халва — Совкомбанк',
      icon: Icons.account_balance_rounded,
    ),
    SbpBank(
      name: 'МТС Банк',
      subtitle: 'Оплата через приложение МТС Банка',
      icon: Icons.account_balance_rounded,
    ),
    SbpBank(
      name: 'Почта Банк',
      subtitle: 'Оплата через мобильное приложение',
      icon: Icons.account_balance_rounded,
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<SbpBank> get _filteredBanks {
    final String query = _searchController.text.trim().toLowerCase();

    if (query.isEmpty) {
      return _banks;
    }

    return _banks.where((SbpBank bank) {
      return bank.name.toLowerCase().contains(query) ||
          bank.subtitle.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color cardColor =
    isDark ? AppColors.darkSurface : Theme.of(context).cardColor;
    final Color onSurface = Theme.of(context).colorScheme.onSurface;

    return DraggableScrollableSheet(
      initialChildSize: 0.78,
      minChildSize: 0.48,
      maxChildSize: 0.92,
      builder: (
          BuildContext context,
          ScrollController scrollController,
          ) {
        final List<SbpBank> filteredBanks = _filteredBanks;

        return Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(28),
            ),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.border,
            ),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 46,
                height: 5,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBorderSoft : AppColors.border,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        gradient: isDark
                            ? AppColors.darkBrandGradient
                            : AppColors.brandGradient,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.bolt_rounded,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Выберите банк',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'После выбора банка заказ будет оформлен',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark
                                  ? AppColors.darkMutedForeground
                                  : AppColors.mutedForeground,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  onChanged: (_) {
                    setState(() {});
                  },
                  decoration: InputDecoration(
                    hintText: 'Поиск банка',
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: isDark ? AppColors.purpleLight : AppColors.primary,
                    ),
                    suffixIcon: _searchController.text.isEmpty
                        ? null
                        : IconButton(
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: filteredBanks.isEmpty
                    ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Банк не найден',
                      style: TextStyle(
                        color: isDark
                            ? AppColors.darkMutedForeground
                            : AppColors.mutedForeground,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                )
                    : ListView.separated(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
                  itemCount: filteredBanks.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (
                      BuildContext context,
                      int index,
                      ) {
                    final SbpBank bank = filteredBanks[index];

                    return InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () {
                        FocusScope.of(context).unfocus();
                        Navigator.of(context).pop(bank);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkSurfaceElevated
                              : Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isDark
                                ? AppColors.darkBorder
                                : AppColors.border,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.purple
                                    .withValues(alpha: 0.14)
                                    : AppColors.primaryLight,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(
                                bank.icon,
                                color: isDark
                                    ? AppColors.purpleLight
                                    : AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    bank.name,
                                    style: TextStyle(
                                      color: onSurface,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    bank.subtitle,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark
                                          ? AppColors.darkMutedForeground
                                          : AppColors.mutedForeground,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.chevron_right_rounded,
                              color: isDark
                                  ? AppColors.darkMutedForeground
                                  : AppColors.mutedForeground,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/address_book_controller.dart';
import '../../models/user_address.dart';
import '../../utils/app_colors.dart';
import '../../widgets/address_form_sheet.dart';
import '../../widgets/app_confirm_dialog.dart';

class ProfileAddressSection extends StatelessWidget {
  final AddressBookController controller;
  final void Function(String message) onMessage;

  const ProfileAddressSection({
    super.key,
    required this.controller,
    required this.onMessage,
  });

  Future<void> _showAddressDialog(
      BuildContext context, {
        UserAddress? address,
      }) async {
    final UserAddress? result = await AddressFormSheet.show(
      context,
      address: address,
      isFirstAddress: controller.addresses.isEmpty,
    );

    if (result == null) {
      return;
    }

    try {
      if (address == null) {
        await controller.addAddress(result);
        onMessage('Новый адрес сохранён в профиле.');
      } else {
        await controller.updateAddress(result);
        onMessage('Изменения адреса успешно сохранены.');
      }
    } catch (e) {
      onMessage('Не удалось сохранить адрес: $e');
    }
  }

  Future<void> _deleteAddress(
      BuildContext context,
      UserAddress address,
      ) async {
    final bool confirmed = await AppConfirmDialog.show(
      context,
      title: 'Удалить адрес',
      message: 'Удалить адрес “${address.title}”?',
      confirmText: 'Удалить',
      cancelText: 'Отмена',
      icon: Icons.delete_outline_rounded,
      danger: true,
    );

    if (!confirmed) {
      return;
    }

    try {
      await controller.removeAddress(address.id);
      onMessage('Адрес “${address.title}” удалён из профиля.');
    } catch (e) {
      onMessage('Не удалось удалить адрес: $e');
    }
  }

  Widget _addressTile(BuildContext context, UserAddress address) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkSurfaceElevated
            : AppColors.primaryLight.withOpacity(0.35),
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
              gradient:
              isDark ? AppColors.darkBrandGradient : AppColors.brandGradient,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.location_on_outlined,
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
                        address.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (address.isPrimary) ...[
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
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'Основной',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: isDark
                                ? AppColors.purpleLight
                                : AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  address.fullAddress,
                  style: TextStyle(
                    color: isDark
                        ? AppColors.darkMutedForeground
                        : AppColors.mutedForeground,
                    height: 1.35,
                  ),
                ),
                if (address.comment.trim().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    address.comment,
                    style: TextStyle(
                      color: isDark
                          ? AppColors.darkMutedForeground
                          : AppColors.mutedForeground,
                      fontSize: 12,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (!address.isPrimary)
                      OutlinedButton(
                        onPressed: () async {
                          try {
                            await controller.setPrimaryAddress(address.id);
                            onMessage(
                              'Теперь “${address.title}” используется по умолчанию.',
                            );
                          } catch (e) {
                            onMessage(
                              'Не удалось обновить основной адрес: $e',
                            );
                          }
                        },
                        child: const Text('Сделать основным'),
                      ),
                    OutlinedButton(
                      onPressed: () => _showAddressDialog(
                        context,
                        address: address,
                      ),
                      child: const Text('Изменить'),
                    ),
                    OutlinedButton(
                      onPressed: () => _deleteAddress(context, address),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.danger,
                      ),
                      child: const Text('Удалить'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Obx(() {
      final List<UserAddress> addresses = controller.addresses;

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
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
                  ? AppColors.purple.withOpacity(0.05)
                  : AppColors.shadow,
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Адреса доставки',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _showAddressDialog(context),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Добавить'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (controller.isLoading.value)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 18),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (addresses.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkSurfaceElevated
                      : AppColors.primaryLight.withOpacity(0.35),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  'Адреса доставки пока не добавлены.\nДобавьте дом, работу или другой адрес для быстрого оформления заказа.',
                  style: TextStyle(
                    color: isDark
                        ? AppColors.darkMutedForeground
                        : AppColors.mutedForeground,
                    height: 1.4,
                  ),
                ),
              )
            else
              ...addresses.map(
                    (UserAddress address) => _addressTile(context, address),
              ),
          ],
        ),
      );
    });
  }
}
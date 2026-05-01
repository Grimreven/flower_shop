import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/address_book_controller.dart';
import '../../models/user_address.dart';
import '../../utils/app_colors.dart';

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
    final TextEditingController titleController = TextEditingController(
      text: address?.title ?? '',
    );
    final TextEditingController cityController = TextEditingController(
      text: address?.city ?? '',
    );
    final TextEditingController streetController = TextEditingController(
      text: address?.street ?? '',
    );
    final TextEditingController houseController = TextEditingController(
      text: address?.house ?? '',
    );
    final TextEditingController apartmentController = TextEditingController(
      text: address?.apartment ?? '',
    );
    final TextEditingController entranceController = TextEditingController(
      text: address?.entrance ?? '',
    );
    final TextEditingController floorController = TextEditingController(
      text: address?.floor ?? '',
    );
    final TextEditingController commentController = TextEditingController(
      text: address?.comment ?? '',
    );

    bool isPrimary = address?.isPrimary ?? controller.addresses.isEmpty;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (BuildContext context) {
        final bool isDark = Theme.of(context).brightness == Brightness.dark;

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setLocalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 18,
                right: 18,
                top: 18,
                bottom: MediaQuery.of(context).viewInsets.bottom + 18,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 5,
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkBorder
                              : AppColors.border,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      address == null ? 'Добавить адрес' : 'Изменить адрес',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 18),
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Название',
                        hintText: 'Дом, работа, для мамы',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: cityController,
                      decoration: const InputDecoration(
                        labelText: 'Город',
                        hintText: 'Москва',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: streetController,
                      decoration: const InputDecoration(
                        labelText: 'Улица',
                        hintText: 'Авиаторов',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: houseController,
                            decoration: const InputDecoration(
                              labelText: 'Дом',
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: apartmentController,
                            decoration: const InputDecoration(
                              labelText: 'Квартира',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: entranceController,
                            decoration: const InputDecoration(
                              labelText: 'Подъезд',
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: floorController,
                            decoration: const InputDecoration(
                              labelText: 'Этаж',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: commentController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Комментарий',
                        hintText: 'Например: домофон не работает',
                      ),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: isPrimary,
                      activeColor: isDark ? AppColors.purple : AppColors.primary,
                      title: const Text('Сделать адресом по умолчанию'),
                      onChanged: (bool value) {
                        setLocalState(() {
                          isPrimary = value;
                        });
                      },
                    ),
                    const SizedBox(height: 18),
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
                          onPressed: () async {
                            if (cityController.text.trim().isEmpty ||
                                streetController.text.trim().isEmpty ||
                                houseController.text.trim().isEmpty) {
                              onMessage('Заполните город, улицу и дом');
                              return;
                            }

                            final UserAddress result = UserAddress(
                              id: address?.id ?? 0,
                              title: titleController.text.trim().isEmpty
                                  ? 'Адрес'
                                  : titleController.text.trim(),
                              city: cityController.text.trim(),
                              street: streetController.text.trim(),
                              house: houseController.text.trim(),
                              apartment: apartmentController.text.trim(),
                              entrance: entranceController.text.trim(),
                              floor: floorController.text.trim(),
                              comment: commentController.text.trim(),
                              isPrimary: isPrimary,
                            );

                            if (address == null) {
                              await controller.addAddress(result);
                              onMessage('Адрес добавлен');
                            } else {
                              await controller.updateAddress(result);
                              onMessage('Адрес обновлён');
                            }

                            if (context.mounted) {
                              Navigator.of(context).pop();
                            }
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
                          child: const Text('Сохранить'),
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

    titleController.dispose();
    cityController.dispose();
    streetController.dispose();
    houseController.dispose();
    apartmentController.dispose();
    entranceController.dispose();
    floorController.dispose();
    commentController.dispose();
  }

  Future<void> _deleteAddress(
      BuildContext context,
      UserAddress address,
      ) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Удалить адрес'),
          content: Text('Удалить адрес “${address.title}”?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Удалить'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await controller.removeAddress(address.id);
      onMessage('Адрес удалён');
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
                          await controller.setPrimaryAddress(address.id);
                          onMessage('Основной адрес обновлён');
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
                  ? AppColors.purple.withValues(alpha: 0.05)
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
                      : AppColors.primaryLight.withValues(alpha: 0.35),
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
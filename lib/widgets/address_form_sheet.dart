import 'package:flutter/material.dart';

import '../models/user_address.dart';
import '../utils/app_colors.dart';

class AddressFormSheet extends StatefulWidget {
  final UserAddress? address;
  final bool isFirstAddress;

  const AddressFormSheet({
    super.key,
    this.address,
    required this.isFirstAddress,
  });

  static Future<UserAddress?> show(
      BuildContext context, {
        UserAddress? address,
        required bool isFirstAddress,
      }) {
    return showModalBottomSheet<UserAddress>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return AddressFormSheet(
          address: address,
          isFirstAddress: isFirstAddress,
        );
      },
    );
  }

  @override
  State<AddressFormSheet> createState() => _AddressFormSheetState();
}

class _AddressFormSheetState extends State<AddressFormSheet> {
  late final TextEditingController titleController;
  late final TextEditingController cityController;
  late final TextEditingController streetController;
  late final TextEditingController houseController;
  late final TextEditingController apartmentController;
  late final TextEditingController entranceController;
  late final TextEditingController floorController;
  late final TextEditingController commentController;

  late bool isPrimary;

  @override
  void initState() {
    super.initState();

    final UserAddress? address = widget.address;

    titleController = TextEditingController(text: address?.title ?? '');
    cityController = TextEditingController(text: address?.city ?? '');
    streetController = TextEditingController(text: address?.street ?? '');
    houseController = TextEditingController(text: address?.house ?? '');
    apartmentController = TextEditingController(text: address?.apartment ?? '');
    entranceController = TextEditingController(text: address?.entrance ?? '');
    floorController = TextEditingController(text: address?.floor ?? '');
    commentController = TextEditingController(text: address?.comment ?? '');

    isPrimary = address?.isPrimary ?? widget.isFirstAddress;
  }

  @override
  void dispose() {
    titleController.dispose();
    cityController.dispose();
    streetController.dispose();
    houseController.dispose();
    apartmentController.dispose();
    entranceController.dispose();
    floorController.dispose();
    commentController.dispose();
    super.dispose();
  }

  void _showFormWarning(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
  }

  void _submit() {
    FocusManager.instance.primaryFocus?.unfocus();

    final String title = titleController.text.trim();
    final String city = cityController.text.trim();
    final String street = streetController.text.trim();
    final String house = houseController.text.trim();

    if (title.isEmpty) {
      _showFormWarning(
        'Введите название адреса, например “Дом” или “Работа”.',
      );
      return;
    }

    if (city.isEmpty) {
      _showFormWarning('Введите город доставки.');
      return;
    }

    if (street.isEmpty) {
      _showFormWarning('Введите улицу доставки.');
      return;
    }

    if (house.isEmpty) {
      _showFormWarning('Введите номер дома.');
      return;
    }

    final UserAddress result = UserAddress(
      id: widget.address?.id ?? 0,
      title: title,
      address: '$city, $street, $house',
      city: city,
      street: street,
      house: house,
      apartment: apartmentController.text.trim(),
      entrance: entranceController.text.trim(),
      floor: floorController.text.trim(),
      comment: commentController.text.trim(),
      recipientName: widget.address?.recipientName ?? '',
      phone: widget.address?.phone ?? '',
      isPrimary: isPrimary,
    );

    Navigator.of(context).pop(result);
  }

  Widget _inputField({
    required TextEditingController controller,
    required String label,
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      textInputAction:
      maxLines > 1 ? TextInputAction.newline : TextInputAction.next,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final Color backgroundColor =
    isDark ? AppColors.darkSurface : Theme.of(context).cardColor;

    final Color borderColor = isDark ? AppColors.darkBorder : AppColors.border;

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        gradient: isDark ? AppColors.darkCardGradient : null,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(28),
        ),
        border: Border(
          top: BorderSide(color: borderColor),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: 18,
          right: 18,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 18,
        ),
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkBorder : AppColors.border,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                widget.address == null ? 'Добавить адрес' : 'Изменить адрес',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 18),
              _inputField(
                controller: titleController,
                label: 'Название',
                hint: 'Дом, работа, для мамы',
              ),
              const SizedBox(height: 12),
              _inputField(
                controller: cityController,
                label: 'Город',
                hint: 'Москва',
              ),
              const SizedBox(height: 12),
              _inputField(
                controller: streetController,
                label: 'Улица',
                hint: 'Авиаторов',
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _inputField(
                      controller: houseController,
                      label: 'Дом',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _inputField(
                      controller: apartmentController,
                      label: 'Квартира',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _inputField(
                      controller: entranceController,
                      label: 'Подъезд',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _inputField(
                      controller: floorController,
                      label: 'Этаж',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _inputField(
                controller: commentController,
                label: 'Комментарий',
                hint: 'Например: домофон не работает',
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: isPrimary,
                activeColor: isDark ? AppColors.purple : AppColors.primary,
                title: const Text('Сделать адресом по умолчанию'),
                onChanged: (bool value) {
                  setState(() {
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
                    child: const Text(
                      'Сохранить',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
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
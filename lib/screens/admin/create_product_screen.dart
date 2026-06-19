import 'package:flutter/material.dart';

import '../../api/server_api_service.dart';
import '../../utils/app_colors.dart';

class CreateProductScreen extends StatefulWidget {
  const CreateProductScreen({super.key});

  @override
  State<CreateProductScreen> createState() => _CreateProductScreenState();
}

class _CreateProductScreenState extends State<CreateProductScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController imageController = TextEditingController();
  final TextEditingController careController = TextEditingController();

  List<Map<String, dynamic>> categories = <Map<String, dynamic>>[];
  int? selectedCategoryId;
  bool inStock = true;
  bool isLoading = false;
  bool isCategoriesLoading = true;

  @override
  void initState() {
    super.initState();
    loadCategories();
  }

  Future<void> loadCategories() async {
    try {
      final List<Map<String, dynamic>> data =
      await ServerApiService.getCategories();

      if (!mounted) return;

      setState(() {
        categories = data;
        if (categories.isNotEmpty) {
          selectedCategoryId = _toInt(categories.first['id']);
        }
        isCategoriesLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isCategoriesLoading = false;
      });

      _showMessage('Не удалось загрузить категории: $e');
    }
  }

  Future<void> createProduct() async {
    if (isLoading) return;

    final bool isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    final double? price = double.tryParse(
      priceController.text.trim().replaceAll(',', '.'),
    );

    if (price == null || price <= 0) {
      _showMessage('Введите корректную цену');
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      await ServerApiService.createProduct(
        name: nameController.text.trim(),
        description: descriptionController.text.trim(),
        price: price,
        imageUrl: imageController.text.trim(),
        categoryId: selectedCategoryId,
        inStock: inStock,
        care: careController.text
            .split('\n')
            .map((String item) => item.trim())
            .where((String item) => item.isNotEmpty)
            .toList(),
      );

      if (!mounted) return;

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;

      _showMessage('Ошибка добавления товара: $e');
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? 0;
  }

  Color _accentColor(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? AppColors.purpleLight : AppColors.primary;
  }

  Color _textColor(BuildContext context) {
    return Theme.of(context).colorScheme.onSurface;
  }

  Color _mutedColor(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
  }

  Color _cardColor(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? AppColors.darkSurface : Colors.white;
  }

  Color _borderColor(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? AppColors.darkBorder : AppColors.border;
  }

  InputDecoration _inputDecoration(
      BuildContext context,
      String label, {
        String? hint,
        IconData? icon,
      }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: icon == null ? null : Icon(icon),
      filled: true,
      fillColor: _cardColor(context),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: _borderColor(context)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: _borderColor(context)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: _accentColor(context), width: 1.5),
      ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    priceController.dispose();
    descriptionController.dispose();
    imageController.dispose();
    careController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bg = Theme.of(context).scaffoldBackgroundColor;
    final Color text = _textColor(context);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Text(
          'Добавить товар',
          style: TextStyle(
            color: text,
            fontWeight: FontWeight.w900,
          ),
        ),
        backgroundColor: bg,
        foregroundColor: text,
        elevation: 0,
        centerTitle: true,
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
        child: isCategoriesLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Основная информация',
                  style: TextStyle(
                    color: text,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 14),

                TextFormField(
                  controller: nameController,
                  decoration: _inputDecoration(
                    context,
                    'Название товара',
                    hint: 'Например: Нежный букет',
                    icon: Icons.local_florist_rounded,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Введите название товара';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: priceController,
                  decoration: _inputDecoration(
                    context,
                    'Цена',
                    hint: 'Например: 3500',
                    icon: Icons.payments_rounded,
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Введите цену';
                    }

                    final double? price = double.tryParse(
                      value.trim().replaceAll(',', '.'),
                    );

                    if (price == null || price <= 0) {
                      return 'Введите корректную цену';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: descriptionController,
                  decoration: _inputDecoration(
                    context,
                    'Описание',
                    hint: 'Краткое описание букета',
                    icon: Icons.description_rounded,
                  ),
                  maxLines: 4,
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: imageController,
                  decoration: _inputDecoration(
                    context,
                    'Ссылка на изображение',
                    hint: 'https://...',
                    icon: Icons.image_rounded,
                  ),
                ),
                const SizedBox(height: 12),

                DropdownButtonFormField<int>(
                  value: selectedCategoryId,
                  decoration: _inputDecoration(
                    context,
                    'Категория',
                    icon: Icons.category_rounded,
                  ),
                  items: categories.map((Map<String, dynamic> category) {
                    return DropdownMenuItem<int>(
                      value: _toInt(category['id']),
                      child: Text(category['name']?.toString() ?? ''),
                    );
                  }).toList(),
                  onChanged: (int? value) {
                    setState(() {
                      selectedCategoryId = value;
                    });
                  },
                ),
                const SizedBox(height: 12),

                Container(
                  decoration: BoxDecoration(
                    color: _cardColor(context),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _borderColor(context)),
                  ),
                  child: SwitchListTile(
                    title: Text(
                      'Товар в наличии',
                      style: TextStyle(
                        color: text,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: Text(
                      inStock
                          ? 'Будет отображаться как доступный'
                          : 'Будет отображаться как недоступный',
                      style: TextStyle(
                        color: _mutedColor(context),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    value: inStock,
                    activeColor: _accentColor(context),
                    onChanged: (bool value) {
                      setState(() {
                        inStock = value;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 18),

                Text(
                  'Уход за товаром',
                  style: TextStyle(
                    color: text,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),

                TextFormField(
                  controller: careController,
                  decoration: _inputDecoration(
                    context,
                    'Правила ухода',
                    hint:
                    'Каждое правило с новой строки\nНапример:\nМенять воду ежедневно\nНе ставить на солнце',
                    icon: Icons.spa_rounded,
                  ),
                  minLines: 4,
                  maxLines: 6,
                ),
                const SizedBox(height: 22),

                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: isDark
                          ? AppColors.darkBrandGradient
                          : AppColors.brandGradient,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: ElevatedButton.icon(
                      onPressed: isLoading ? null : createProduct,
                      icon: isLoading
                          ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                          : const Icon(Icons.add_rounded),
                      label: Text(
                        isLoading ? 'Добавление...' : 'Добавить товар',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        disabledBackgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        foregroundColor: Colors.white,
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
        ),
      ),
    );
  }
}
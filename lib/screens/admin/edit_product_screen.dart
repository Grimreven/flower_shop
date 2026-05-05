import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../api/server_api_service.dart';

class EditProductScreen extends StatefulWidget {
  final Map<String, dynamic> product;

  const EditProductScreen({super.key, required this.product});

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  late TextEditingController nameController;
  late TextEditingController priceController;
  late TextEditingController descriptionController;
  late TextEditingController imageController;
  late TextEditingController careController;

  bool inStock = true;

  // 🔥 категории
  List<Map<String, dynamic>> categories = [];
  int? selectedCategoryId;

  @override
  void initState() {
    super.initState();

    nameController =
        TextEditingController(text: widget.product['name'] ?? '');

    priceController =
        TextEditingController(text: widget.product['price'].toString());

    descriptionController =
        TextEditingController(text: widget.product['description'] ?? '');

    imageController =
        TextEditingController(text: widget.product['image_url'] ?? '');

    inStock = widget.product['in_stock'] ?? true;

    careController = TextEditingController(
      text: (widget.product['care'] is List)
          ? (widget.product['care'] as List).join(', ')
          : '',
    );

    selectedCategoryId = widget.product['category_id'];

    loadCategories();
  }

  // 🔥 загрузка категорий
  Future<void> loadCategories() async {
    try {
      final data = await ServerApiService.getCategories();
      setState(() {
        categories = data;
      });
    } catch (e) {
      Get.snackbar('Ошибка', 'Не удалось загрузить категории');
    }
  }

  Future<void> updateProduct() async {
    try {
      await ServerApiService.updateProduct(
        productId: widget.product['id'],
        name: nameController.text,
        description: descriptionController.text,
        price: double.tryParse(priceController.text),
        imageUrl: imageController.text,
        categoryId: selectedCategoryId,
        inStock: inStock,
        care: careController.text
            .split(',')
            .map((e) => e.trim())
            .toList(),
      );

      Get.snackbar('Успех', 'Товар обновлён');
      Get.back(result: true);
    } catch (e) {
      Get.snackbar('Ошибка', e.toString());
    }
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Редактировать товар'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            /// 🔹 Название
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Название'),
            ),
            const SizedBox(height: 12),

            /// 🔹 Цена
            TextField(
              controller: priceController,
              decoration: const InputDecoration(labelText: 'Цена'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),

            /// 🔹 Описание
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(labelText: 'Описание'),
              maxLines: 3,
            ),
            const SizedBox(height: 12),

            /// 🔹 Картинка
            TextField(
              controller: imageController,
              decoration:
              const InputDecoration(labelText: 'Ссылка на изображение'),
            ),
            const SizedBox(height: 12),

            /// 🔥 ВЫПАДАЮЩИЙ СПИСОК КАТЕГОРИЙ
            DropdownButtonFormField<int>(
              value: selectedCategoryId,
              items: categories.map((cat) {
                return DropdownMenuItem<int>(
                  value: cat['id'],
                  child: Text(cat['name']),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedCategoryId = value;
                });
              },
              decoration: const InputDecoration(
                labelText: 'Категория',
              ),
            ),
            const SizedBox(height: 12),

            /// 🔹 В наличии
            SwitchListTile(
              title: const Text('В наличии'),
              value: inStock,
              onChanged: (value) {
                setState(() {
                  inStock = value;
                });
              },
            ),

            /// 🔹 Уход
            TextField(
              controller: careController,
              decoration: const InputDecoration(
                labelText: 'Уход (через запятую)',
              ),
              maxLines: 2,
            ),

            const SizedBox(height: 20),

            /// 🔥 КНОПКА СОХРАНИТЬ
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: updateProduct,
                child: const Text('Сохранить'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
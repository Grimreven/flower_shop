import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../api/server_api_service.dart';

class CreateProductScreen extends StatefulWidget {
  const CreateProductScreen({super.key});

  @override
  State<CreateProductScreen> createState() => _CreateProductScreenState();
}

class _CreateProductScreenState extends State<CreateProductScreen> {
  final nameController = TextEditingController();
  final priceController = TextEditingController();
  final descriptionController = TextEditingController();

  Future<void> createProduct() async {
    try {
      await ServerApiService.createProduct(
        name: nameController.text,
        description: descriptionController.text,
        price: double.tryParse(priceController.text),
      );

      Get.snackbar('Успех', 'Товар создан');
      Get.back(result: true); // важно!
    } catch (e) {
      Get.snackbar('Ошибка', e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Создать товар')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Название'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: priceController,
              decoration: const InputDecoration(labelText: 'Цена'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(labelText: 'Описание'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: createProduct,
              child: const Text('Создать'),
            ),
          ],
        ),
      ),
    );
  }
}
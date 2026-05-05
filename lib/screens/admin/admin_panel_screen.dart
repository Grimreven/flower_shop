import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../api/server_api_service.dart';
import 'edit_product_screen.dart';
import 'create_product_screen.dart';
import '../auth/auth_screen.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  List<Map<String, dynamic>> products = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadProducts();
  }

  Future<void> loadProducts() async {
    try {
      final data = await ServerApiService.getProducts();
      setState(() {
        products = data;
      });
    } catch (e) {
      Get.snackbar('Ошибка', e.toString());
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> deleteProduct(int id) async {
    try {
      await ServerApiService.deleteProduct(id);
      loadProducts();
      Get.snackbar('Успех', 'Товар удалён');
    } catch (e) {
      Get.snackbar('Ошибка', e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Админ панель'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ServerApiService.logout();

              Get.offAll(() => const AuthScreen());
            },
          ),
        ],
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  // 🖼 КАРТИНКА
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      product['image_url'] ?? '',
                      width: 70,
                      height: 70,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 70,
                          height: 70,
                          color: Colors.grey[300],
                          child: const Icon(Icons.image_not_supported),
                        );
                      },
                    ),
                  ),

                  const SizedBox(width: 12),

                  // 📄 ИНФА
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product['name'] ?? '',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text('Цена: ${product['price']}'),
                      ],
                    ),
                  ),

                  // ✏️ 🗑 КНОПКИ
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () async {
                          final result = await Get.to(
                                () => EditProductScreen(product: product),
                          );

                          if (result == true) {
                            loadProducts();
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          final confirm = await Get.dialog(
                            AlertDialog(
                              title: const Text('Удалить товар?'),
                              content: const Text('Это действие нельзя отменить'),
                              actions: [
                                TextButton(
                                  onPressed: () => Get.back(result: false),
                                  child: const Text('Отмена'),
                                ),
                                TextButton(
                                  onPressed: () => Get.back(result: true),
                                  child: const Text('Удалить'),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            await ServerApiService.deleteProduct(product['id']);
                            loadProducts();
                            Get.snackbar('Успех', 'Товар удалён');
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Get.to(() => const CreateProductScreen());

          if (result == true) {
            loadProducts();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

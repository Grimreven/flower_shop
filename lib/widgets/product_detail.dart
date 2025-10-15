import 'package:flutter/material.dart';
import '../models/product.dart';
import '../utils/app_colors.dart';

class ProductDetail extends StatelessWidget {
  final Product product;
  final VoidCallback onAddToCart;

  const ProductDetail({
    Key? key,
    required this.product,
    required this.onAddToCart,
  }) : super(key: key);

  // Особенности одинаковы для всех товаров
  static const List<String> features = [
    'Доставка по всей стране',
    'Гарантия качества',
    'Возможность возврата',
  ];

  static const List<IconData> featureIcons = [
    Icons.local_shipping,
    Icons.shield,
    Icons.refresh,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ---------- Header ----------
            Stack(
              children: [
                Container(
                  width: double.infinity,
                  height: 300,
                  color: Colors.grey[200],
                  child: Image.network(
                    product.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                    const Icon(Icons.image_not_supported, size: 60),
                  ),
                ),
                Positioned(
                  left: 16,
                  top: 16,
                  child: CircleAvatar(
                    backgroundColor: Colors.white70,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.black),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),
              ],
            ),

            // ---------- Content ----------
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Название и цена
                    Text(
                      product.name,
                      style:
                      const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${product.price.toStringAsFixed(0)} ₽',
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary),
                    ),
                    const SizedBox(height: 16),

                    // Описание
                    if (product.description != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Описание',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text(
                            product.description!,
                            style: const TextStyle(fontSize: 14, height: 1.5),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),

                    // Особенности (горизонтальные карточки)
                    const Text('Особенности',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 120, // фиксированная высота, чтобы избежать overflow
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: features.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          return Card(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            elevation: 2,
                            child: Container(
                              width: 140,
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    featureIcons[index],
                                    color: AppColors.primary,
                                    size: 28,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    features[index],
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Уход за цветком (если есть)
                    if (product.care != null && product.care!.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Уход',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          ...product.care!.map((instruction) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 12,
                                  backgroundColor: AppColors.primary.withOpacity(0.1),
                                  child: Text(
                                    '${product.care!.indexOf(instruction) + 1}',
                                    style: const TextStyle(
                                        fontSize: 12, color: AppColors.primary),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                    child: Text(
                                      instruction,
                                      style: const TextStyle(fontSize: 14),
                                    )),
                              ],
                            ),
                          )),
                          const SizedBox(height: 16),
                        ],
                      ),

                    // Кнопка "Добавить в корзину"
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: onAddToCart,
                        icon: const Icon(Icons.shopping_cart_outlined),
                        label: const Text('Добавить в корзину'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

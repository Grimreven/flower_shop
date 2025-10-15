import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../widgets/flower_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Row(
          children: [
            Image.asset('assets/flowerLogo2.png', width: 36),
            const SizedBox(width: 8),
            const Text(
              'Цветочный магазин',
              style: TextStyle(color: AppColors.primary),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Популярное',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: 5,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: FlowerCard(
                      title: 'Цветок ${index + 1}',
                      color: Colors.pink[200]!,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            const Text('Новинки',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: 5,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: FlowerCard(
                      title: 'Новинка ${index + 1}',
                      color: Colors.green[200]!,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            const Text('Все товары',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 3 / 4,
              ),
              itemCount: 8,
              itemBuilder: (context, index) {
                return FlowerCard(
                  title: 'Товар ${index + 1}',
                  color: Colors.yellow[700]!,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
